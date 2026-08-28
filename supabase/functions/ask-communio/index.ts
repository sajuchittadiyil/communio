import { createClient, SupabaseClient } from "jsr:@supabase/supabase-js@2";
import type {
  AskCommunioContext,
  AskCommunioIntent,
  AskCommunioInterpretation,
} from "./intent_interpreter.ts";
import { interpretAskCommunioQuestion } from "./intent_interpreter.ts";
import { memberAllowedIntent } from "./access_policy.ts";
import { memberScopedRows } from "./query_guards.ts";
import {
  countCanonicalMemberCategory,
  filterMinistryTypeRows,
  filterPastOfficeTerms,
  matchingDirectoryRows,
  resolveCommunityReference,
} from "./wave1_query_logic.ts";
import {
  durationLabel,
  historicalAssignmentEmptyMessage,
  overlapsYear,
  startsOrEndsInYear,
  uniqueMemberRows,
} from "./wave2_query_logic.ts";
import {
  canonicalRole,
  currentAppointmentCompliance,
  eligibilityStatus,
  isRestrictedProfileQuestion,
  qualificationMatches,
  roleOf,
} from "./wave3_query_logic.ts";
import { ageSummary, distinctActiveCounts } from "./wave4_query_logic.ts";
import {
  governanceLeaders,
  orderGovernanceMembers,
  resolveGovernanceBody,
} from "./governance_query_logic.ts";
import {
  lifecycleAnswer,
  lifecycleEvidenceLabel,
} from "./community_lifecycle_query_logic.ts";
import {
  formalTransferAnswer,
  memberFormalTransferAnswer,
} from "./formal_transfer_query_logic.ts";
import { applySemanticContext } from "./semantic_context.ts";
import type { SemanticContext, SemanticEntity } from "./semantic_context.ts";
import {
  ageInInclusiveRange,
  birthdayMatchesMonth,
  ordinalNumber,
  professionYearForAnniversary,
} from "./natural_language_analytics.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
};

type Intent = AskCommunioIntent;
type Interpretation = AskCommunioInterpretation;

type Row = Record<string, unknown>;

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  const started = performance.now();
  let intent: Intent = "unknown";
  let sourceCount = 0;
  try {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed." }, 405);
    }
    const authorization = request.headers.get("Authorization");
    if (!authorization?.startsWith("Bearer ")) {
      return json({ error: "Authentication is required." }, 401);
    }
    const url = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!url || !anonKey) {
      return json(
        { error: "Ask Communio server configuration is incomplete." },
        503,
      );
    }
    const client = createClient(url, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: auth, error: authError } = await client.auth.getUser();
    if (authError || !auth.user) {
      return json({ error: "Your session is not valid." }, 401);
    }

    const { data: access, error: accessError } = await client
      .from("app_user_access")
      .select("access_role,member_id")
      .eq("auth_user_id", auth.user.id)
      .eq("active", true)
      .single();
    if (accessError || !access) {
      return json({ error: "Your Communio access is not configured." }, 403);
    }

    const body = await request.json().catch(() => null);
    const question = typeof body?.question === "string"
      ? body.question.trim()
      : "";
    if (question.length < 3 || question.length > 500) {
      return json(
        { error: "Enter a question between 3 and 500 characters." },
        400,
      );
    }

    const priorContext = safeContext(body?.context);
    let interpretation = interpretAskCommunioQuestion(question, priorContext);
    intent = interpretation.intent;
    const memberLike = access.access_role === "member" ||
      access.access_role === "community_superior";
    if (isRestrictedProfileQuestion(question)) {
      return json({
        error:
          "That information is restricted and is not available through your current Communio access.",
      }, 403);
    }
    if (
      memberLike &&
      /\b(?:parents?|father|mother|siblings?|family|emergency|testament|vault|digital safe|confidential|personnel file|private document|eligibility|financial|province-wide movement|provincial movement)\b/i
        .test(question)
    ) {
      return json({
        error: "That information isn't available with your current access.",
      }, 403);
    }
    if (memberLike && !memberAllowedIntent(intent)) {
      return json({
        error: "That information isn't available with your current access.",
      }, 403);
    }
    if (
      access.access_role === "community_superior" &&
      /\b(?:my|our) community\b/i.test(question)
    ) {
      const { data: context, error: contextError } = await client.rpc(
        "get_community_superior_context",
      );
      if (contextError || !context?.community_name) {
        return json({
          error: "That information isn't available with your current access.",
        }, 403);
      }
      interpretation = { ...interpretation, entity: context.community_name };
    }
    const result = await executeAllowedQuery(
      client,
      interpretation,
      access.access_role,
    );
    if (!result) {
      throw new Error(
        `Ask Communio handler returned no result for ${interpretation.intent}`,
      );
    }
    sourceCount = result.sources.length;
    console.log(JSON.stringify({
      event: "ask_communio",
      user_id: auth.user.id,
      intent,
      success: true,
      response_ms: Math.round(performance.now() - started),
      source_count: sourceCount,
      question_length: question.length,
    }));
    const { semantic_context: semanticContext, ...publicResult } = result;
    const nextContext = result.reliability === "grounded"
      ? responseContext(interpretation, result, semanticContext)
      : undefined;
    if (Deno.env.get("ASK_COMMUNIO_CONTEXT_DEBUG") === "true" && nextContext) {
      console.debug(JSON.stringify({
        event: "ask_communio_context",
        intent: interpretation.intent,
        focus_type: nextContext.focus_entity_type,
        last_answer_type: nextContext.last_answer_entity_type,
        entity_set_type: nextContext.entity_set_type,
        entity_set_size: nextContext.entity_set_size,
        ambiguous_type: nextContext.ambiguous_entity_type,
      }));
    }
    return json({
      ...publicResult,
      generated_at: new Date().toISOString(),
      interpretation,
      ...(nextContext ? { context: nextContext } : {}),
    });
  } catch (error) {
    console.error(JSON.stringify({
      event: "ask_communio",
      intent,
      success: false,
      response_ms: Math.round(performance.now() - started),
      source_count: sourceCount,
      error: error instanceof Error ? error.message : "unknown",
    }));
    return json({
      error:
        "I couldn't retrieve Communio records right now. Please try again.",
    }, 500);
  }
});

async function executeAllowedQuery(
  client: SupabaseClient,
  input: Interpretation,
  accessRole?: string,
) {
  switch (input.intent) {
    case "profession_cohort":
      return vocationCohort(
        client,
        "FIRST_PROFESSION",
        input.year,
        input.yearTo,
        "First profession",
        input.outputType,
        input.timeRelation,
      );
    case "ordination_cohort":
      return vocationCohort(
        client,
        "ORDINATION",
        input.year,
        input.yearTo,
        "Ordination",
        input.outputType,
        input.timeRelation,
      );
    case "vocation_cohort":
      return vocationCohort(
        client,
        input.topic ?? "JOINING",
        input.year,
        input.yearTo,
        label(input.topic ?? "joining"),
        input.outputType,
        input.timeRelation,
      );
    case "member_history":
      return accessRole !== "provincial"
        ? memberSafeProfileFact(client, input)
        : memberHistory(client, input.entity, input.topic, input.entityId);
    case "member_profile":
      return accessRole !== "provincial"
        ? memberSafeProfileFact(client, input)
        : memberProfileFacts(client, input.entity, input.topic);
    case "member_languages":
      return memberLanguages(client, input);
    case "community_directory":
      return communityDirectory(
        client,
        input.outputType,
        accessRole,
        input.topic,
      );
    case "community_profile":
      return communityProfile(client, input.entity, accessRole);
    case "ministry_directory":
      return ministryDirectory(
        client,
        input.topic,
        input.outputType,
        accessRole,
      );
    case "ministry_profile":
      return ministryProfile(client, input.entity, accessRole);
    case "ministry_establishment":
      return ministryEstablishment(client, input.entity);
    case "leadership_history":
      return leadershipHistory(client, input.role ?? "provincial");
    case "community_history":
      return communityHistory(client, input.entity);
    case "community_lifecycle":
      return communityLifecycle(client, input);
    case "community_movement":
      return communityMovement(client, input);
    case "formal_transfer":
      return formalTransferSearch(client, input);
    case "historical_community_ranking":
      return historicalCommunityRanking(client, input.year);
    case "ministry_type_staffing":
      return ministryTypeStaffing(
        client,
        input.topic ?? "school",
        input.outputType,
      );
    case "leadership_successor":
      return leadershipSuccessor(
        client,
        input.entity,
        input.role ?? "provincial",
      );
    case "member_office_tenure":
      return memberOfficeTenure(
        client,
        input.entity,
        input.role ?? "provincial",
      );
    case "previous_assignment":
      return previousAssignment(client, input.entity);
    case "appointment_period_search":
      return appointmentPeriodSearch(client, input.year, input.timeRelation);
    case "member_appointment_comparison":
      return memberAppointmentComparison(client, input.entity);
    case "present_state":
      return presentStateSearch(client, input.topic, input.entity);
    case "location_entity_search":
      return locationEntitySearch(
        client,
        input.topic,
        input.entity,
        input.role,
      );
    case "decision_boundary":
      return decisionBoundaryResponse();
    case "member_safe_factual":
      return memberSafeFactual(client, input);
    case "member_appointment_history":
      return memberAppointmentHistory(client, input.entity, input.entityId);
    case "member_current_location":
      return memberLocation(client, input.entity, undefined, input.entityId);
    case "member_historical_location":
      return memberLocation(client, input.entity, input.year, input.entityId);
    case "community_size_ranking":
      return communitySizeRanking(client, input.topic ?? "largest");
    case "member_age_extreme":
      return memberAgeExtreme(client, input.topic ?? "oldest");
    case "member_analytics":
      return memberAnalytics(client, input.topic ?? "average_age");
    case "community_size_threshold":
      return communitySizeThreshold(client, input.age ?? 5);
    case "ministry_size_ranking":
      return ministrySizeRanking(client);
    case "clarification_needed":
      return clarificationResponse(
        input.topic === "member_reference"
          ? "I have several members in the previous result. Which member do you mean?"
          : input.topic === "community_reference"
          ? "I have several communities in the previous result. Which community do you mean?"
          : input.topic === "ministry_reference"
          ? "Which ministry do you mean?"
          : input.topic === "member_follow_up"
          ? "What would you like to know about that member?"
          : input.topic === "community_follow_up"
          ? "What would you like to know about that community?"
          : input.topic === "governance_reference"
          ? "Which governance body do you mean?"
          : input.topic === "historical_community_ranking"
          ? "Historical community-size ranking is not supported yet. I can rank current communities or show a named community's membership in that year."
          : input.topic === "bare_entity"
          ? "St Antony may refer to a member, community, ministry, or the congregation. Which one do you mean?"
          : input.topic === "community"
          ? "Which community do you mean, or what would you like to know about communities?"
          : input.topic === "member"
          ? "Which member do you mean, or what would you like to know about members?"
          : "What would you like me to count—current members, active communities, ministries, appointments, or something else?",
        [],
      );
    case "composed_community_query":
      return composedCommunityQuery(client, input);
    case "age_search":
      return ageSearch(
        client,
        input.age ?? 70,
        input.ageComparison ?? "above",
        input.ageTo,
        input.outputType,
      );
    case "birthday_month":
      return birthdayMonthSearch(client, input.month, input.outputType);
    case "vocation_anniversary":
      return vocationAnniversarySearch(
        client,
        input.anniversary,
        input.year,
        input.outputType,
      );
    case "eligibility_search":
      return eligibilitySearch(client, input.role ?? "principal", input.entity);
    case "appointment_compliance":
      return appointmentCompliance(
        client,
        input.topic ?? "summary",
        input.outputType,
      );
    case "appointment_expiry":
      return appointmentExpiry(client);
    case "appointment_search":
      return appointmentSearch(client, input.entity);
    case "historical_office_holder":
      return historicalOfficeHolder(client, input);
    case "governance_body_membership":
      return governanceBodyMembership(client, input);
    case "governance_directory":
      return governanceDirectory(client);
    case "governance_body_profile":
      return governanceBodyProfile(client, input);
    case "governance_body_members":
      return governanceBodyMembers(client, input);
    case "governance_body_leader":
      return governanceBodyLeader(client, input);
    case "organization_identity":
      return organizationIdentity(client, input.entity);
    case "community_superior_history":
      return assignmentSearch(client, "community", input, true, false);
    case "community_membership_history":
      return assignmentSearch(client, "community", input, false);
    case "ministry_assignment_history":
      return assignmentSearch(client, "ministry", input, false, false);
    case "ministry_experience_search":
      return formationExperienceSearch(client);
    case "member_origin_search":
      return memberOriginSearch(client, input.entity, input.originField);
    case "current_location_search":
      return currentLocationSearch(
        client,
        input.entity,
        input.topic === "outside",
      );
    case "ministry_leadership_history":
      return assignmentSearch(client, "ministry", input, false, true);
    case "current_assignment":
      return currentAssignment(client, input.entity);
    case "education_qualification_search":
      return qualificationSearch(client, input.entity);
    case "person_search":
      return personSearch(client, input.entity);
    default:
      return noReliableAnswer(
        "I couldn't answer that from the Communio records yet. Try asking about a member, community, ministry, appointment, vocation milestone, qualification or leadership history.",
      );
  }
}

async function memberSafeProfileFact(
  client: SupabaseClient,
  input: Interpretation,
) {
  const needle = normalizeMemberName(cleanEntity(input.entity));
  if (!needle) return noReliableAnswer("Please include a member name.");
  const { data: directory, error: directoryError } = await client.from(
    "v_member_directory_safe",
  ).select("member_id,display_name,religious_id");
  if (directoryError) throw directoryError;
  const matches = (directory ?? []).filter((row) =>
    normalizeMemberName(nameOf(row)).includes(needle)
  );
  if (matches.length !== 1) return noReliableAnswer();
  const member = matches[0];
  const { data, error } = await client.rpc("get_other_member_profile_safe", {
    target_member_id: text(member, "member_id"),
  });
  if (error) throw error;
  if (!data) return noReliableAnswer();
  const row = data as Row;
  const topic = input.topic;
  if (topic === "profile") {
    const facts = [
      text(row, "religious_id"),
      label(text(row, "member_status_code") ?? ""),
      text(row, "community_name"),
      text(row, "ministry_name"),
    ].filter(Boolean);
    return response(`${nameOf(row)}: ${facts.join(" · ")}.`, [row], [
      source("Member-safe religious profile", "member", text(row, "member_id")),
    ], [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }]);
  }
  if (topic === "status") {
    const status = text(row, "member_status_code", "canonical_status_code");
    if (!status) return noReliableAnswer();
    return response(`${nameOf(row)}'s recorded status is ${label(status)}.`, [
      row,
    ], [
      source("Member-safe religious profile", "member", text(row, "member_id")),
    ], [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }]);
  }
  if (topic === "date_of_birth" || topic === "age") {
    return noReliableAnswer(
      "Date of birth is not available with your current access.",
    );
  }
  if (topic === "email" || topic === "phone" || topic === "address") {
    const value = topic === "email"
      ? text(row, "official_email")
      : topic === "phone"
      ? text(row, "mobile")
      : [
        text(row, "address"),
        text(row, "city"),
        text(row, "district"),
        text(row, "state"),
        text(row, "country"),
      ].filter(Boolean).join(", ");
    if (!value) {
      return groundedEmpty(
        `No authorized ${topic} is recorded for ${nameOf(row)}.`,
      );
    }
    const item = {
      member_id: text(row, "member_id"),
      display_name: nameOf(row),
      contact_type: topic,
      contact_value: value,
    };
    return response(`${nameOf(row)}'s recorded ${topic} is ${value}.`, [item], [
      source(
        "Authorized member profile",
        "member",
        text(row, "member_id"),
        topic,
      ),
    ], [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }]);
  }
  if (topic === "current_assignment") {
    const facts = [text(row, "community_name"), text(row, "ministry_name")]
      .filter(Boolean);
    if (!facts.length) return noReliableAnswer();
    return response(
      `${nameOf(row)} is currently assigned to ${facts.join(" and ")}.`,
      [row],
      [source(
        "Member-safe religious profile",
        "member",
        text(row, "member_id"),
      )],
      [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }],
    );
  }
  const values = topic === "qualifications"
    ? row.qualifications
    : topic === "community"
    ? row.community_assignments
    : topic === "ministry"
    ? row.ministry_assignments
    : topic
    ? row.vocation_events
    : [
      ...(Array.isArray(row.vocation_events) ? row.vocation_events : []),
      ...(Array.isArray(row.community_assignments)
        ? row.community_assignments
        : []),
      ...(Array.isArray(row.ministry_assignments)
        ? row.ministry_assignments
        : []),
    ];
  if (!Array.isArray(values) || !values.length) return noReliableAnswer();
  return response(
    `Found ${values.length} safe ${label(topic ?? "life and ministry")} record${
      values.length === 1 ? "" : "s"
    } for ${nameOf(row)}.`,
    values as Row[],
    [source("Member-safe religious profile", "member", text(row, "member_id"))],
    [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }],
  );
}

async function memberSafeFactual(
  client: SupabaseClient,
  input: Interpretation,
) {
  const needle = normalizeFact(cleanEntity(input.entity));
  if (!needle) return noReliableAnswer();
  if (input.topic === "community_members") {
    const { data: communities, error: communityError } = await client
      .from("v_member_communities_safe").select("community_id,name");
    if (communityError) throw communityError;
    const community = (communities ?? []).find((row) =>
      normalizeFact(nameOf(row)).includes(needle)
    );
    if (!community) return noReliableAnswer();
    const { data, error } = await client.from(
      "v_member_community_residents_safe",
    )
      .select(
        "member_id,display_name,religious_id,community_responsibility_code",
      )
      .eq("community_id", text(community, "community_id"));
    if (error) throw error;
    if (!data?.length) return noReliableAnswer();
    return response(
      `The current members of ${nameOf(community)} are ${
        data.map(nameOf).join(", ")
      }.`,
      data,
      [source(
        "Member-safe community directory",
        "community",
        text(community, "community_id"),
      )],
      memberEntities(data),
    );
  }
  if (input.topic === "community_superior") {
    const { data, error } = await client.from("v_member_communities_safe")
      .select("*");
    if (error) throw error;
    const row = (data ?? []).find((item) =>
      normalizeFact(nameOf(item)).includes(needle)
    );
    const superior = row && text(row, "current_superior_display_name");
    if (!row || !superior) return noReliableAnswer();
    return response(
      `The current Community Superior of ${nameOf(row)} is ${superior}.`,
      [row],
      [source(
        "Member-safe community directory",
        "community",
        text(row, "community_id"),
      )],
      text(row, "current_superior_member_id")
        ? [{
          id: text(row, "current_superior_member_id"),
          type: "member",
          label: superior,
        }]
        : [],
    );
  }
  const { data, error } = await client.from("v_member_ministries_safe").select(
    "*",
  );
  if (error) throw error;
  const matches = (data ?? []).filter((row) => {
    const haystack = normalizeFact(
      `${text(row, "ministry_name") ?? ""} ${text(row, "ministry_code") ?? ""}`,
    );
    return haystack.includes(needle) ||
      needle.includes(normalizeFact(text(row, "ministry_name") ?? ""));
  });
  if (!matches.length) return noReliableAnswer();
  const row = matches[0];
  if (input.topic === "ministry_location") {
    const location = [
      text(row, "city"),
      text(row, "district"),
      text(row, "state"),
      text(row, "country"),
    ].filter(Boolean).join(", ");
    if (!location) return noReliableAnswer();
    return response(`${text(row, "ministry_name")} is in ${location}.`, [row], [
      source(
        "Member-safe ministry directory",
        "ministry",
        text(row, "ministry_id"),
      ),
    ], []);
  }
  const actualRole = (text(row, "head_role") ?? "").toLowerCase();
  const requestedRole = input.role ?? "director";
  const acceptable = requestedRole === "director"
    ? ["director", "head", "manager", "administrator", "coordinator"].some((
      role,
    ) => actualRole.includes(role))
    : requestedRole === "parish_priest"
    ? actualRole.includes("parish_priest") || actualRole.includes("pastor")
    : actualRole.includes(requestedRole);
  const head = text(row, "head_display_name");
  if (!head || !acceptable) return noReliableAnswer();
  const roleLabel = label(actualRole);
  const association = text(row, "community_name");
  const suffix = association
    ? ` ${text(row, "ministry_name")} is associated with ${association}.`
    : "";
  return response(
    `The current ${roleLabel} of ${
      text(row, "ministry_name")
    } is ${head}.${suffix}`,
    [row],
    [source(
      "Member-safe ministry directory",
      "ministry",
      text(row, "ministry_id"),
    )],
    text(row, "head_member_id")
      ? [{ id: text(row, "head_member_id"), type: "member", label: head }]
      : [],
  );
}

function decisionBoundaryResponse() {
  return response(
    "Communio can show recorded eligibility and experience, but it does not recommend appointments or make leadership decisions.",
    [],
    [source("Communio decision boundary", "policy")],
    [],
  );
}

async function memberHistory(
  client: SupabaseClient,
  entity?: string,
  topic?: string,
  entityId?: string,
) {
  const resolved = await resolveMember(client, entity, entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const memberId = idOf(member);
  const [
    vocation,
    communities,
    ministries,
    offices,
    attention,
    communityNames,
    ministryNames,
    provinces,
    congregations,
  ] = await Promise.all([
    client.from("member_vocation_events").select("*").eq("member_id", memberId),
    client.from("member_community_assignments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("member_ministry_assignments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("member_office_appointments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("v_demo_member_attention_events").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("communities").select("id,name"),
    client.from("ministries").select("id,name"),
    client.from("provinces").select("id,name"),
    client.from("congregations").select("id,name"),
  ]);
  for (
    const query of [
      vocation,
      communities,
      ministries,
      offices,
      attention,
      communityNames,
      ministryNames,
      provinces,
      congregations,
    ]
  ) {
    if (query.error) throw query.error;
  }
  const communityLookup = rowLookup(communityNames.data ?? []);
  const ministryLookup = rowLookup(ministryNames.data ?? []);
  const provinceLookup = rowLookup(provinces.data ?? []);
  const congregationLookup = rowLookup(congregations.data ?? []);
  const events: Row[] = [
    ...(vocation.data ?? []).map((row) => ({
      ...row,
      event_category: "vocation",
      event_title: label(
        text(row, "event_type_code", "event_type") ?? "Vocation event",
      ),
      start_date: text(row, "event_date", "date"),
      location: text(row, "place", "location"),
      evidence_label: "Vocation Event",
      evidence_type: "vocation_event",
    })),
    ...(communities.data ?? []).map((row) => ({
      ...row,
      event_category: "community",
      event_title: label(
        text(row, "responsibility_code", "role_code") ?? "Community assignment",
      ),
      context: nameOf(
        communityLookup.get(text(row, "community_id") ?? "") ?? {},
      ),
      start_date: text(row, "from_date", "start_date"),
      end_date: text(row, "to_date", "end_date"),
      evidence_label: "Community Assignment",
      evidence_type: "community_assignment",
    })),
    ...(ministries.data ?? []).map((row) => ({
      ...row,
      event_category: "ministry",
      event_title: label(
        text(row, "responsibility_code", "role_code") ?? "Ministry assignment",
      ),
      context: nameOf(ministryLookup.get(text(row, "ministry_id") ?? "") ?? {}),
      start_date: text(row, "from_date", "start_date"),
      end_date: text(row, "to_date", "end_date"),
      evidence_label: "Ministry Assignment",
      evidence_type: "ministry_assignment",
    })),
    ...(offices.data ?? []).map((row) => {
      const context = officeContext(
        row,
        ministryLookup,
        communityLookup,
        provinceLookup,
        congregationLookup,
      );
      return {
        ...row,
        event_category: "office",
        event_title: label(
          text(row, "office_type_code", "office_code", "office") ??
            "Office appointment",
        ),
        context: context?.name,
        related_entity_type: context?.type,
        related_entity_id: context?.id,
        start_date: text(row, "from_date", "start_date"),
        end_date: text(row, "to_date", "end_date"),
        evidence_label: "Office Appointment",
        evidence_type: "office_appointment",
      };
    }),
    ...(attention.data ?? []).filter(isRecognizedLeave).map((row) => ({
      ...row,
      event_category: "leave",
      event_title: label(text(row, "event_type", "event_type_code") ?? "Leave"),
      context: text(row, "purpose", "reason", "title"),
      start_date: text(row, "from_date", "start_date"),
      end_date: text(row, "to_date", "end_date"),
      location: text(row, "location", "place"),
      evidence_label: "Leave Record",
      evidence_type: "leave_record",
    })),
  ].filter((row) => historyTopicMatches(row, topic));
  events.sort((a, b) =>
    (text(b, "start_date", "end_date") ?? "").localeCompare(
      text(a, "start_date", "end_date") ?? "",
    )
  );
  const milestoneLabel = topic === "first_profession"
    ? "first profession"
    : topic === "final_profession"
    ? "final profession"
    : topic === "ordination"
    ? "ordination"
    : undefined;
  if (!events.length && milestoneLabel) {
    return groundedEmpty(
      `No ${milestoneLabel} date is recorded for ${nameOf(member)}.`,
    );
  }
  if (!events.length) return noReliableAnswer();
  if (milestoneLabel) {
    return response(
      `${nameOf(member)}'s recorded ${milestoneLabel} date${
        events.length === 1 ? " is" : "s are"
      } ${
        events.map((row) => formatDate(text(row, "start_date")!)).join(" and ")
      }.`,
      events,
      events.map((row) =>
        source(
          "Vocation Event",
          "vocation_event",
          idOf(row),
          historyDetail(row),
        )
      ),
      [{ id: memberId, type: "member", label: nameOf(member) }],
      {
        focus: semanticEntity("member", memberId, nameOf(member)),
        lastAnswer: semanticEntity("member", memberId, nameOf(member)),
      },
    );
  }
  return response(
    `Found ${events.length} recorded life and ministry event${
      events.length === 1 ? "" : "s"
    } for ${nameOf(member)}.`,
    events,
    events.map((row) =>
      source(
        text(row, "evidence_label") ?? "Member History",
        text(row, "evidence_type") ?? "member_history",
        idOf(row),
        historyDetail(row),
      )
    ),
    [{ id: memberId, type: "member", label: nameOf(member) }],
    {
      focus: semanticEntity("member", memberId, nameOf(member)),
      lastAnswer: semanticEntity("member", memberId, nameOf(member)),
    },
  );
}

async function memberProfileFacts(
  client: SupabaseClient,
  entity?: string,
  topic?: string,
  entityId?: string,
) {
  const resolved = await resolveMember(client, entity, entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const memberId = idOf(member);
  if (["profile", "date_of_birth", "age", "status"].includes(topic ?? "")) {
    const { data, error } = await client.rpc(
      "get_provincial_member_profile_safe",
      { p_member_id: memberId },
    );
    if (error) throw error;
    const row = data as Row;
    if (topic === "date_of_birth" || topic === "age") {
      const dateOfBirth = text(row, "date_of_birth");
      if (!dateOfBirth) {
        return groundedEmpty(
          `No date of birth is recorded for ${nameOf(row)}.`,
        );
      }
      const answer = topic === "age"
        ? `${nameOf(row)} is ${
          ageOnDate(dateOfBirth, new Date())
        } years old based on the recorded date of birth.`
        : `${nameOf(row)}'s recorded date of birth is ${
          formatDate(dateOfBirth)
        }.`;
      return response(answer, [row], [
        source("Provincial member profile", "member", memberId, dateOfBirth),
      ], [{ id: memberId, type: "member", label: nameOf(row) }]);
    }
    if (topic === "status") {
      const status = text(row, "member_status_code", "canonical_status_code");
      if (!status) {
        return groundedEmpty(
          `No membership status is recorded for ${nameOf(row)}.`,
        );
      }
      return response(
        `${nameOf(row)}'s recorded status is ${label(status)}.`,
        [row],
        [source("Provincial member profile", "member", memberId, status)],
        [{ id: memberId, type: "member", label: nameOf(row) }],
      );
    }
    const facts = [
      text(row, "religious_id"),
      label(text(row, "member_status_code") ?? ""),
      text(row, "nationality"),
    ].filter(Boolean);
    return response(`${nameOf(row)}: ${facts.join(" · ")}.`, [row], [
      source("Provincial member profile", "member", memberId),
    ], [{ id: memberId, type: "member", label: nameOf(row) }]);
  }
  if (topic === "religious_id") {
    return response(
      `${nameOf(member)}'s Religious ID is ${text(member, "religious_id")}.`,
      [member],
      [source(
        "Member Profile",
        "member",
        memberId,
        text(member, "religious_id"),
      )],
      [{ id: memberId, type: "member", label: nameOf(member) }],
    );
  }
  if (topic === "email" || topic === "phone" || topic === "address") {
    const { data, error } = await client.rpc(
      "get_provincial_member_profile_safe",
      { p_member_id: memberId },
    );
    if (error) throw error;
    const profile = data as Row;
    const native =
      profile.native_details && typeof profile.native_details === "object"
        ? profile.native_details as Row
        : {};
    const contacts = Array.isArray(profile.home_contacts)
      ? profile.home_contacts as Row[]
      : [];
    const contact = contacts[0] ?? {};
    const value = topic === "email"
      ? text(profile, "official_email") ??
        text(contact, "official_email", "email")
      : topic === "phone"
      ? text(profile, "mobile") ?? text(contact, "mobile", "phone")
      : [
        text(native, "address", "home_address", "postal_address"),
        text(native, "city", "native_place"),
        text(native, "district"),
        text(native, "state"),
        text(native, "country"),
      ].filter(Boolean).join(", ");
    if (!value) {
      return groundedEmpty(
        `No authorized ${topic} is recorded for ${nameOf(member)}.`,
      );
    }
    const item = {
      member_id: memberId,
      display_name: nameOf(member),
      contact_type: topic,
      contact_value: value,
    };
    return response(
      `${nameOf(member)}'s recorded ${topic} is ${value}.`,
      [item],
      [source("Authorized member profile", "member", memberId, topic)],
      [{ id: memberId, type: "member", label: nameOf(member) }],
    );
  }
  if (topic === "qualifications") {
    let query = await client.from("v_member_qualifications_normalized").select(
      "*",
    ).eq("member_id", memberId);
    if (query.error) {
      query = await client.from("member_qualifications").select("*").eq(
        "member_id",
        memberId,
      );
    }
    if (query.error) throw query.error;
    const rows = query.data ?? [];
    if (!rows.length) {
      return groundedEmpty(
        `No qualification records are recorded for ${nameOf(member)}.`,
      );
    }
    const enriched = rows.map((row) => ({
      ...row,
      display_name: nameOf(member),
    }));
    return response(
      `${nameOf(member)} has ${rows.length} recorded qualification${
        rows.length === 1 ? "" : "s"
      }:\n• ${rows.map(qualificationDetail).join("\n• ")}`,
      enriched,
      rows.map((row) =>
        source(
          "Qualification record",
          "qualification",
          idOf(row),
          qualificationDetail(row),
        )
      ),
      [{ id: memberId, type: "member", label: nameOf(member) }],
    );
  }
  if (topic === "origin") {
    const { data, error } = await client.from("member_native_details").select(
      "*",
    ).eq("member_id", memberId);
    if (error) throw error;
    if (!data?.length) return noReliableAnswer();
    return response(
      `Origin details for ${nameOf(member)}: ${originDetail(data[0])}.`,
      data,
      data.map((row) =>
        source(
          "Member Origin Record",
          "member_origin",
          idOf(row),
          originDetail(row),
        )
      ),
      [{ id: memberId, type: "member", label: nameOf(member) }],
    );
  }
  if (topic === "parents") {
    const { data, error } = await client.from("member_family").select("*").eq(
      "member_id",
      memberId,
    );
    if (error) throw error;
    const rows = (data ?? []).filter((row) =>
      ["father", "mother"].includes(
        (text(row, "relationship") ?? "").toLowerCase(),
      )
    );
    if (!rows.length) return noReliableAnswer();
    return response(
      `${nameOf(member)}'s recorded parents: ${
        rows.map((row) =>
          `${label(text(row, "relationship") ?? "Parent")}: ${
            text(row, "name")
          }`
        ).join("; ")
      }.`,
      rows,
      rows.map((row) =>
        source(
          "Family Record",
          "member_family",
          idOf(row),
          label(text(row, "relationship") ?? "Parent"),
        )
      ),
      [{ id: memberId, type: "member", label: nameOf(member) }],
    );
  }
  if (topic === "current_assignment") {
    return currentAssignmentForMember(client, member);
  }
  return noReliableAnswer();
}

async function communityDirectory(
  client: SupabaseClient,
  outputType?: "records" | "count",
  accessRole?: string,
  topic = "active",
) {
  if (topic === "closed") {
    if (accessRole !== "provincial") {
      return noReliableAnswer(
        "Closed-community records are not available with your current access.",
      );
    }
    const { data, error } = await client.from("communities").select("*").eq(
      "active",
      false,
    ).order("name");
    if (error) throw error;
    const rows = data ?? [];
    if (!rows.length) {
      return groundedEmpty(
        "Communio records no closed communities available with your current access.",
      );
    }
    return response(
      `Communio records ${rows.length} closed communities: ${
        rows.map(nameOf).join(", ")
      }.`,
      rows,
      rows.map((row) =>
        source("Authorized community record", "community", idOf(row))
      ),
      rows.map((row) => ({
        id: idOf(row),
        type: "community",
        label: nameOf(row),
      })),
    );
  }
  const view = accessRole === "community_superior"
    ? "v_community_superior_community_safe"
    : "v_member_communities_safe";
  const { data, error } = await client.from(view).select("*").order("name");
  if (error) throw error;
  const rows: Row[] = (data ?? []).map((row) => ({ ...row }));
  if (outputType === "count") {
    return countResponse(
      `Communio currently records ${rows.length} active communities.`,
      rows.length,
      [aggregateSource(
        "Active community directory",
        "community_count",
        rows.length,
        "active community",
      )],
    );
  }
  if (!rows.length) {
    return groundedEmpty(
      "Communio records no active communities available with your current access.",
    );
  }
  return response(
    `Communio currently records ${rows.length} active communities${
      rows.length <= 10
        ? `:\n• ${rows.map((row) => communitySummary(row)).join("\n• ")}`
        : "."
    }`,
    rows,
    rows.map((row) =>
      source(
        "Authorized community directory",
        "community",
        text(row, "community_id"),
        communitySummary(row),
      )
    ),
    rows.map((row) => ({
      id: text(row, "community_id"),
      type: "community",
      label: nameOf(row),
    })),
    {
      entitySet: {
        type: "community",
        entities: rows.map((row) =>
          semanticEntity(
            "community",
            text(row, "community_id") ?? "",
            nameOf(row),
          )
        ),
      },
    },
  );
}

async function communityProfile(
  client: SupabaseClient,
  entity?: string,
  accessRole?: string,
) {
  const needle = normalizePlaceName(cleanEntity(entity), "community");
  if (!needle) return noReliableAnswer("Please include a community name.");
  const view = accessRole === "community_superior"
    ? "v_community_superior_community_safe"
    : "v_member_communities_safe";
  const { data, error } = await client.from(view).select("*");
  if (error) throw error;
  const matches = matchingDirectoryRows(
    data ?? [],
    cleanEntity(entity),
    "community",
  );
  if (!matches.length) {
    return groundedEmpty(
      `I found no active community matching ${cleanEntity(entity)}.`,
    );
  }
  if (matches.length > 1) {
    return clarificationResponse(
      `I found more than one matching community. Did you mean: ${
        matches.map(nameOf).join("; ")
      }?`,
      matches,
    );
  }
  const row = matches[0];
  const location = [
    text(row, "city"),
    text(row, "district"),
    text(row, "state"),
    text(row, "country"),
  ].filter(Boolean).join(", ");
  const facts = [
    location,
    `${Number(row.current_resident_count ?? 0)} current members`,
    text(row, "current_superior_display_name")
      ? `Superior: ${text(row, "current_superior_display_name")}`
      : undefined,
    text(row, "opened_on")
      ? `opened ${formatDate(text(row, "opened_on")!)}`
      : undefined,
  ].filter(Boolean);
  return response(
    `${nameOf(row)}${facts.length ? ` — ${facts.join(" · ")}` : ""}.`,
    [row],
    [source(
      "Authorized community directory",
      "community",
      text(row, "community_id"),
      facts.join(" · "),
    )],
    [{ id: text(row, "community_id"), type: "community", label: nameOf(row) }],
    {
      focus: semanticEntity(
        "community",
        text(row, "community_id") ?? "",
        nameOf(row),
      ),
      lastAnswer: semanticEntity(
        "community",
        text(row, "community_id") ?? "",
        nameOf(row),
      ),
    },
  );
}

async function ministryDirectory(
  client: SupabaseClient,
  topic?: string,
  outputType?: "records" | "count",
  accessRole?: string,
) {
  const view = accessRole === "community_superior"
    ? "v_community_superior_ministries_safe"
    : "v_member_ministries_safe";
  const { data, error } = await client.from(view).select("*").order(
    "ministry_name",
  );
  if (error) throw error;
  const requested = topic ?? "all";
  const rows = filterMinistryTypeRows(data ?? [], requested);
  const labelText = requested === "all"
    ? "active ministries"
    : `${label(requested)} ministries`;
  if (outputType === "count") {
    return countResponse(
      `Communio currently records ${rows.length} ${labelText}.`,
      rows.length,
      [aggregateSource(
        label(labelText),
        "ministry_count",
        rows.length,
        labelText.slice(0, -1),
      )],
    );
  }
  if (!rows.length) {
    return groundedEmpty(
      `Communio records no ${labelText} available with your current access.`,
    );
  }
  return response(
    `Communio currently records ${rows.length} ${labelText}${
      rows.length <= 10
        ? `:\n• ${rows.map((row) => ministrySummary(row)).join("\n• ")}`
        : "."
    }`,
    rows,
    rows.map((row) =>
      source(
        "Authorized ministry directory",
        "ministry",
        text(row, "ministry_id"),
        ministrySummary(row),
      )
    ),
    rows.map((row) => ({
      id: text(row, "ministry_id"),
      type: "ministry",
      label: text(row, "ministry_name"),
    })),
    {
      entitySet: {
        type: "ministry",
        entities: rows.map((row) =>
          semanticEntity(
            "ministry",
            text(row, "ministry_id") ?? "",
            text(row, "ministry_name") ?? "",
          )
        ),
      },
    },
  );
}

async function ministryProfile(
  client: SupabaseClient,
  entity?: string,
  accessRole?: string,
) {
  const needle = normalizePlaceName(cleanEntity(entity), "ministry");
  if (!needle) return noReliableAnswer("Please include a ministry name.");
  const view = accessRole === "community_superior"
    ? "v_community_superior_ministries_safe"
    : "v_member_ministries_safe";
  const { data, error } = await client.from(view).select("*");
  if (error) throw error;
  const matches = matchingDirectoryRows(
    data ?? [],
    cleanEntity(entity),
    "ministry",
  );
  if (!matches.length) {
    return groundedEmpty(
      `I found no active ministry matching ${cleanEntity(entity)}.`,
    );
  }
  if (matches.length > 1) {
    return clarificationResponse(
      `I found more than one matching ministry. Did you mean: ${
        matches.map((row) => text(row, "ministry_name")).join("; ")
      }?`,
      matches,
    );
  }
  const row = matches[0];
  const location = [
    text(row, "city"),
    text(row, "district"),
    text(row, "state"),
    text(row, "country"),
  ].filter(Boolean).join(", ");
  const facts = [
    label(text(row, "ministry_type") ?? "ministry"),
    location,
    text(row, "community_name")
      ? `Community: ${text(row, "community_name")}`
      : undefined,
    text(row, "head_display_name")
      ? `${label(text(row, "head_role") ?? "Head")}: ${
        text(row, "head_display_name")
      }`
      : undefined,
  ].filter(Boolean);
  const name = text(row, "ministry_name") ?? nameOf(row);
  return response(
    `${name}${facts.length ? ` — ${facts.join(" · ")}` : ""}.`,
    [row],
    [source(
      "Authorized ministry directory",
      "ministry",
      text(row, "ministry_id"),
      facts.join(" · "),
    )],
    [{ id: text(row, "ministry_id"), type: "ministry", label: name }],
    {
      focus: semanticEntity("ministry", text(row, "ministry_id") ?? "", name),
      lastAnswer: semanticEntity(
        "ministry",
        text(row, "ministry_id") ?? "",
        name,
      ),
    },
  );
}

async function ministryEstablishment(
  client: SupabaseClient,
  entity?: string,
) {
  const needle = normalizePlaceName(cleanEntity(entity), "ministry");
  if (!needle) return noReliableAnswer("Please include a ministry name.");
  const { data, error } = await client.from("ministries").select(
    "id,name,code",
  );
  if (error) throw error;
  const matches = matchingDirectoryRows(
    data ?? [],
    cleanEntity(entity),
    "ministry",
  );
  if (!matches.length) return noReliableAnswer();
  if (matches.length > 1) {
    return clarificationResponse(
      `I found more than one matching ministry. Did you mean: ${
        matches.map(placeLabel).join("; ")
      }?`,
      matches,
    );
  }
  return noReliableAnswer(
    `Communio has no recorded establishment date for ${
      nameOf(matches[0])
    }. I won't infer one from staffing or assignment history.`,
  );
}

async function leadershipHistory(client: SupabaseClient, role: string) {
  const [appointmentsResult, officeTypesResult] = await Promise.all([
    client.from("member_office_appointments").select("*"),
    client.from("office_types").select("*"),
  ]);
  if (appointmentsResult.error) throw appointmentsResult.error;
  if (officeTypesResult.error) throw officeTypesResult.error;
  const officeTypes = rowLookup(officeTypesResult.data ?? []);
  const today = new Date().toISOString().slice(0, 10);
  const rows = filterPastOfficeTerms(
    (appointmentsResult.data ?? []).map((row) => ({
      ...row,
      resolved_office_code: officeCode(row, officeTypes),
    })),
    role,
    today,
  );
  if (!rows.length) {
    return groundedEmpty(`No past ${label(role)} appointments are recorded.`);
  }
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
    office_name: label(role),
  }));
  return response(
    `Recorded ${label(role)} leadership:\n• ${
      enriched.map((row) => `${nameOf(row)} — ${naturalDateRange(row)}`).join(
        "\n• ",
      )
    }`,
    enriched,
    enriched.map((row) =>
      source(
        "Office appointment",
        "office_appointment",
        idOf(row),
        naturalDateRange(row),
      )
    ),
    memberEntities(enriched),
    {
      entitySet: {
        type: "member",
        entities: enriched.map((row) =>
          semanticEntity("member", text(row, "member_id") ?? "", nameOf(row))
        ),
      },
    },
  );
}

async function resolveCommunityRow(
  client: SupabaseClient,
  entity?: string,
  allowUniqueLocationFallback = false,
): Promise<{ row?: Row; result?: ReturnType<typeof response> }> {
  const { data, error } = await client.from("communities").select("*");
  if (error) throw error;
  const resolution = resolveCommunityReference(
    data ?? [],
    cleanEntity(entity),
    allowUniqueLocationFallback,
  );
  const matches = resolution.matches;
  if (resolution.conflict) {
    const requested = cleanEntity(entity);
    if (resolution.suggestions.length) {
      return {
        result: clarificationResponse(
          `I couldn't find a community matching ${requested}. Did you mean: ${
            resolution.suggestions.map(placeLabel).join("; ")
          }?`,
          resolution.suggestions,
        ),
      };
    }
  }
  if (!matches.length && resolution.suggestions.length > 1) {
    return {
      result: clarificationResponse(
        `I found more than one community matching ${
          cleanEntity(entity)
        }. Did you mean: ${resolution.suggestions.map(placeLabel).join("; ")}?`,
        resolution.suggestions,
      ),
    };
  }
  if (!matches.length) {
    return {
      result: groundedEmpty(
        `I found no community matching ${cleanEntity(entity)}.`,
      ),
    };
  }
  if (matches.length > 1) {
    return {
      result: clarificationResponse(
        `I found more than one matching community. Did you mean: ${
          matches.map(nameOf).join("; ")
        }?`,
        matches,
      ),
    };
  }
  return { row: matches[0] };
}

async function communityHistory(client: SupabaseClient, entity?: string) {
  const resolved = await resolveCommunityRow(client, entity);
  if (resolved.result) return resolved.result;
  const community = resolved.row!;
  const { data, error } = await client.from("member_community_assignments")
    .select("*").eq("community_id", idOf(community));
  if (error) throw error;
  if (!data?.length) {
    return groundedEmpty(
      `No membership history is recorded for ${nameOf(community)}.`,
    );
  }
  const members = await memberLookup(client);
  const rows = data.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  })).sort((a, b) =>
    (text(a, "from_date") ?? "").localeCompare(text(b, "from_date") ?? "")
  );
  return response(
    `Recorded community history for ${
      nameOf(community)
    }: ${rows.length} assignment period${rows.length === 1 ? "" : "s"}.`,
    rows,
    rows.map((row) =>
      source(
        "Community assignment",
        "community_assignment",
        idOf(row),
        naturalDateRange(row),
      )
    ),
    memberEntities(rows),
    { focus: semanticEntity("community", idOf(community), nameOf(community)) },
  );
}

async function communityLifecycle(
  client: SupabaseClient,
  input: Interpretation,
) {
  const kind = input.topic === "CLOSED" ? "CLOSED" : "OPENED";
  if (input.entity) {
    const resolved = await resolveCommunityRow(client, input.entity, true);
    if (resolved.result) return resolved.result;
    const community = resolved.row!;
    const { data, error } = await client.from("v_community_lifecycle").select(
      "lifecycle_event_id,community_id,community_code,community_name,event_type_code,effective_date,effective_year,date_precision_code,current_active",
    ).eq("event_type_code", kind).eq("community_id", idOf(community)).order(
      "effective_date",
    ).limit(1);
    if (error) throw error;
    const row = data?.[0];
    if (!row) {
      return groundedEmpty(
        `I found no recorded ${
          kind === "OPENED" ? "opening" : "closure"
        } lifecycle event for ${nameOf(community)}.`,
      );
    }
    const precision = text(row, "date_precision_code")?.toUpperCase();
    const date = precision === "YEAR"
      ? text(row, "effective_year")
      : text(row, "effective_date")
      ? formatDate(text(row, "effective_date")!)
      : text(row, "effective_year");
    const verb = kind === "OPENED" ? "opening" : "closing";
    const preposition = precision === "YEAR" ? "in" : "on";
    return response(
      `${nameOf(community)} is recorded as ${verb} ${preposition} ${date}.`,
      [row],
      [source(
        lifecycleEvidenceLabel(kind),
        "community_lifecycle",
        text(row, "lifecycle_event_id"),
        date,
      )],
      [{ id: idOf(community), type: "community", label: nameOf(community) }],
      {
        focus: semanticEntity("community", idOf(community), nameOf(community)),
      },
    );
  }
  if (!input.year) return noReliableAnswer("Please include a year.");
  const { data, error } = await client.from("v_community_lifecycle").select(
    "lifecycle_event_id,community_id,community_code,community_name,event_type_code,effective_date,effective_year,date_precision_code,current_active",
  ).eq("event_type_code", kind).eq("effective_year", input.year).order(
    "effective_date",
  ).order("community_name");
  if (error) throw error;
  const rows = data ?? [];
  const answer = lifecycleAnswer(
    kind,
    input.year,
    rows.map((row) => text(row, "community_name") ?? "Community"),
  );
  if (!rows.length) return groundedEmpty(answer);
  return response(
    answer,
    rows,
    rows.map((row) =>
      source(
        lifecycleEvidenceLabel(kind),
        "community_lifecycle",
        text(row, "lifecycle_event_id"),
        text(row, "effective_date"),
      )
    ),
    rows.map((row) => ({
      id: text(row, "community_id") ?? "",
      type: "community",
      label: text(row, "community_name") ?? "Community",
    })),
  );
}

async function communityMovement(
  client: SupabaseClient,
  input: Interpretation,
) {
  if (!input.year) return noReliableAnswer("Please include a year.");
  const resolved = await resolveCommunityRow(client, input.entity);
  if (resolved.result) return resolved.result;
  const community = resolved.row!;
  const { data, error } = await client.from("member_community_assignments")
    .select("*").eq("community_id", idOf(community));
  if (error) throw error;
  const boundary = input.topic === "left" ? "ended" : "started";
  const rows = uniqueMemberRows(
    (data ?? []).filter((row) =>
      startsOrEndsInYear(row, input.year!, boundary)
    ),
  );
  const verb = boundary === "started"
    ? "began assignments at"
    : "ended assignments at";
  if (!rows.length) {
    return groundedEmpty(
      `No members ${verb} ${nameOf(community)} in ${input.year}.`,
    );
  }
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  return response(
    `${enriched.length} member${enriched.length === 1 ? "" : "s"} ${verb} ${
      nameOf(community)
    } in ${input.year}: ${enriched.map(nameOf).join(", ")}.`,
    enriched,
    enriched.map((row) =>
      source(
        "Community assignment",
        "community_assignment",
        idOf(row),
        naturalDateRange(row),
      )
    ),
    memberEntities(enriched),
    { focus: semanticEntity("community", idOf(community), nameOf(community)) },
  );
}

async function formalTransferSearch(
  client: SupabaseClient,
  input: Interpretation,
) {
  if (input.topic !== "from_community") {
    return memberFormalTransferSearch(client, input);
  }
  if (!input.year) return noReliableAnswer("Please include a year.");
  const resolved = await resolveCommunityRow(client, input.entity);
  if (resolved.result) return resolved.result;
  const community = resolved.row!;
  const from = `${input.year}-01-01`;
  const to = `${input.year}-12-31`;
  const { data, error } = await client.from("v_member_transfers").select(
    "transfer_id,member_id,religious_id,display_name,from_community_id,from_community_name,to_community_id,to_community_name,effective_date,transfer_type_code,status_code",
  ).eq("from_community_id", idOf(community)).eq(
    "status_code",
    "CONFIRMED",
  ).gte("effective_date", from).lte("effective_date", to).order(
    "effective_date",
  ).order("display_name");
  if (error) throw error;
  const rows = data ?? [];
  const answer = formalTransferAnswer(nameOf(community), input.year, rows);
  if (!rows.length) return groundedEmpty(answer);
  return response(
    answer,
    rows,
    rows.map((row) =>
      source(
        "Formal transfer",
        "member_transfer",
        text(row, "transfer_id"),
        `${text(row, "from_community_name")} → ${
          text(row, "to_community_name")
        } · ${text(row, "effective_date")}`,
      )
    ),
    memberEntities(rows),
    { focus: semanticEntity("community", idOf(community), nameOf(community)) },
  );
}

async function memberFormalTransferSearch(
  client: SupabaseClient,
  input: Interpretation,
) {
  const resolved = await resolveMember(client, input.entity, input.entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const { data, error } = await client.from("v_member_transfers").select(
    "transfer_id,member_id,religious_id,display_name,from_community_id,from_community_name,to_community_id,to_community_name,effective_date,transfer_type_code,status_code",
  ).eq("member_id", idOf(member)).eq("status_code", "CONFIRMED").lte(
    "effective_date",
    new Date().toISOString().slice(0, 10),
  ).order("effective_date");
  if (error) throw error;
  const rows: Row[] = (data ?? []).map((row) => ({ ...row }));
  if (input.topic === "member_reason" && rows.length) {
    const ids = rows.map((row) => text(row, "transfer_id")!).filter(Boolean);
    const reasonResult = await client.from("member_transfers").select(
      "id,reason",
    )
      .in("id", ids);
    if (reasonResult.error) throw reasonResult.error;
    const reasons = new Map(
      (reasonResult.data ?? []).map((row) => [idOf(row), text(row, "reason")]),
    );
    for (const row of rows) {
      row.reason = reasons.get(text(row, "transfer_id") ?? "");
    }
  }
  const answer = memberFormalTransferAnswer(
    nameOf(member),
    rows,
    input.topic === "member_reason",
  );
  if (!rows.length) return groundedEmpty(answer);
  return response(
    answer,
    rows,
    rows.map((row) =>
      source(
        "Formal transfer",
        "member_transfer",
        text(row, "transfer_id"),
        `${text(row, "from_community_name")} → ${
          text(row, "to_community_name")
        } · ${text(row, "effective_date")}`,
      )
    ),
    [{ id: idOf(member), type: "member", label: nameOf(member) }],
    { focus: semanticEntity("member", idOf(member), nameOf(member)) },
  );
}

async function historicalCommunityRanking(
  client: SupabaseClient,
  year?: number,
) {
  if (!year) return noReliableAnswer("Please include a year.");
  const [communitiesResult, assignmentsResult] = await Promise.all([
    client.from("communities").select("id,name"),
    client.from("member_community_assignments").select("*"),
  ]);
  if (communitiesResult.error) throw communitiesResult.error;
  if (assignmentsResult.error) throw assignmentsResult.error;
  const counts = (communitiesResult.data ?? []).map((community) => ({
    ...community,
    member_count: uniqueMemberRows(
      (assignmentsResult.data ?? []).filter((row) =>
        text(row, "community_id") === idOf(community) &&
        overlapsYear(row, year)
      ),
    ).length,
  }));
  const maximum = Math.max(0, ...counts.map((row) => Number(row.member_count)));
  const rows = counts.filter((row) =>
    Number(row.member_count) === maximum && maximum > 0
  );
  if (!rows.length) {
    return groundedEmpty(`No community membership records cover ${year}.`);
  }
  return response(
    `${
      rows.length > 1 ? "The largest communities" : "The largest community"
    } in ${year} had ${maximum} recorded members: ${
      rows.map(nameOf).join(", ")
    }.`,
    rows,
    rows.map((row) =>
      source(
        "Community assignment aggregate",
        "community_count",
        idOf(row),
        `${maximum} unique members in ${year}`,
      )
    ),
    rows.map((row) => ({
      id: idOf(row),
      type: "community",
      label: nameOf(row),
    })),
    rows.length === 1
      ? { focus: semanticEntity("community", idOf(rows[0]), nameOf(rows[0])) }
      : {
        entitySet: {
          type: "community",
          entities: rows.map((row) =>
            semanticEntity("community", idOf(row), nameOf(row))
          ),
        },
      },
  );
}

async function ministryTypeStaffing(
  client: SupabaseClient,
  topic: string,
  outputType?: "records" | "count",
) {
  const { data: ministries, error: ministryError } = await client.from(
    "v_member_ministries_safe",
  ).select("*");
  if (ministryError) throw ministryError;
  const targets = filterMinistryTypeRows(ministries ?? [], topic);
  const targetIds = new Set(targets.map((row) => text(row, "ministry_id")));
  const { data, error } = await client.from("member_ministry_assignments")
    .select("*");
  if (error) throw error;
  const rows = uniqueMemberRows(
    (data ?? []).filter((row) =>
      targetIds.has(text(row, "ministry_id")) && activeOnDate(row, new Date())
    ),
  );
  if (outputType === "count") {
    return countResponse(
      `${rows.length} current member${
        rows.length === 1 ? "" : "s"
      } are assigned to ${label(topic)} ministries.`,
      rows.length,
      [aggregateSource(
        `${label(topic)} ministry staffing`,
        "ministry_assignment_count",
        rows.length,
        "current member",
      )],
    );
  }
  if (!rows.length) {
    return groundedEmpty(
      `No current members are recorded in ${label(topic)} ministries.`,
    );
  }
  return rowsWithMembers(
    client,
    rows,
    `Members currently serving in ${label(topic)} ministries`,
    "Ministry assignment",
    true,
  );
}

async function memberOfficeTerms(
  client: SupabaseClient,
  entity: string | undefined,
  role: string,
) {
  const resolved = await resolveMember(client, entity);
  if ("result" in resolved) return { result: resolved.result };
  const member = resolved.member;
  const [appointments, types] = await Promise.all([
    client.from("member_office_appointments").select("*").eq(
      "member_id",
      idOf(member),
    ),
    client.from("office_types").select("*"),
  ]);
  if (appointments.error) throw appointments.error;
  if (types.error) throw types.error;
  const lookup = rowLookup(types.data ?? []);
  const rows = (appointments.data ?? []).filter((row) =>
    normalizeFact(officeCode(row, lookup)) === normalizeFact(role)
  ).sort((a, b) =>
    (text(a, "from_date") ?? "").localeCompare(text(b, "from_date") ?? "")
  );
  return { member, rows };
}

async function memberOfficeTenure(
  client: SupabaseClient,
  entity?: string,
  role = "provincial",
) {
  const terms = await memberOfficeTerms(client, entity, role);
  if ("result" in terms) return terms.result;
  if (!terms.rows.length) {
    return groundedEmpty(
      `No ${label(role)} term is recorded for ${nameOf(terms.member)}.`,
    );
  }
  const details = terms.rows.map((row) =>
    `${naturalDateRange(row)} — ${durationLabel(row)}`
  );
  const only = terms.rows.length === 1 ? terms.rows[0] : undefined;
  const start = only ? text(only, "from_date", "start_date") : undefined;
  const end = only ? text(only, "to_date", "end_date") : undefined;
  const answer = only && start && end
    ? `${nameOf(terms.member)} served as ${label(role)} for ${
      durationLabel(only)
    }, from ${formatDate(start)} to ${formatDate(end)}.`
    : `${nameOf(terms.member)}'s recorded ${label(role)} tenure:\n• ${
      details.join("\n• ")
    }`;
  return response(
    answer,
    terms.rows,
    terms.rows.map((row) =>
      source(
        "Office appointment",
        "office_appointment",
        idOf(row),
        `${naturalDateRange(row)} · ${durationLabel(row)}`,
      )
    ),
    [{ id: idOf(terms.member), type: "member", label: nameOf(terms.member) }],
  );
}

async function leadershipSuccessor(
  client: SupabaseClient,
  entity?: string,
  role = "provincial",
) {
  const target = await memberOfficeTerms(client, entity, role);
  if ("result" in target) return target.result;
  const ended = target.rows.filter((row) => text(row, "to_date", "end_date"))
    .sort((a, b) =>
      (text(b, "to_date", "end_date") ?? "").localeCompare(
        text(a, "to_date", "end_date") ?? "",
      )
    );
  if (!ended.length) {
    return groundedEmpty(
      `No completed ${label(role)} term is recorded for ${
        nameOf(target.member)
      }.`,
    );
  }
  const [appointments, types] = await Promise.all([
    client.from("member_office_appointments").select("*"),
    client.from("office_types").select("*"),
  ]);
  if (appointments.error) throw appointments.error;
  if (types.error) throw types.error;
  const lookup = rowLookup(types.data ?? []);
  const end = text(ended[0], "to_date", "end_date")!;
  const candidates = (appointments.data ?? []).filter((row) =>
    normalizeFact(officeCode(row, lookup)) === normalizeFact(role) &&
    (text(row, "from_date", "start_date") ?? "") > end
  ).sort((a, b) =>
    (text(a, "from_date", "start_date") ?? "").localeCompare(
      text(b, "from_date", "start_date") ?? "",
    )
  );
  if (!candidates.length) {
    return groundedEmpty(
      `No later recorded ${label(role)} term follows ${
        nameOf(target.member)
      }'s completed term.`,
    );
  }
  const nextStart = text(candidates[0], "from_date", "start_date");
  const next = candidates.filter((row) =>
    text(row, "from_date", "start_date") === nextStart
  );
  if (next.length !== 1) {
    return clarificationResponse(
      "More than one recorded term begins next; succession cannot be determined safely.",
      next,
    );
  }
  const members = await memberLookup(client);
  const row = {
    ...next[0],
    display_name: members.get(text(next[0], "member_id") ?? "")?.display_name ??
      nameOf(next[0]),
  };
  return response(
    `The next recorded ${label(role)} term after ${nameOf(target.member)} was ${
      nameOf(row)
    }, beginning ${formatDate(nextStart!)}.`,
    [row],
    [source(
      "Office appointment",
      "office_appointment",
      idOf(row),
      naturalDateRange(row),
    )],
    [{ id: text(row, "member_id"), type: "member", label: nameOf(row) }],
  );
}

async function previousAssignment(client: SupabaseClient, entity?: string) {
  const resolved = await resolveMember(client, entity);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const [communities, ministries, communityNames, ministryNames] = await Promise
    .all([
      client.from("member_community_assignments").select("*").eq(
        "member_id",
        idOf(member),
      ),
      client.from("member_ministry_assignments").select("*").eq(
        "member_id",
        idOf(member),
      ),
      client.from("communities").select("id,name"),
      client.from("ministries").select("id,name"),
    ]);
  for (
    const query of [communities, ministries, communityNames, ministryNames]
  ) if (query.error) throw query.error;
  const c = rowLookup(communityNames.data ?? []),
    m = rowLookup(ministryNames.data ?? []);
  const rows = [
    ...(communities.data ?? []).map((row) => ({
      ...row,
      assignment_kind: "Community",
      assignment_name: nameOf(c.get(text(row, "community_id") ?? "") ?? {}),
    })),
    ...(ministries.data ?? []).map((row) => ({
      ...row,
      assignment_kind: "Ministry",
      assignment_name: nameOf(m.get(text(row, "ministry_id") ?? "") ?? {}),
    })),
  ].filter((row) => text(row, "to_date", "end_date")).sort((a, b) =>
    (text(b, "to_date", "end_date") ?? "").localeCompare(
      text(a, "to_date", "end_date") ?? "",
    )
  );
  if (!rows.length) {
    return groundedEmpty(
      `No previous assignment is recorded for ${nameOf(member)}.`,
    );
  }
  const latestEnd = text(rows[0], "to_date", "end_date");
  const latest = rows.filter((row) =>
    text(row, "to_date", "end_date") === latestEnd
  );
  return response(
    `${nameOf(member)}'s most recent completed assignment${
      latest.length === 1 ? " was" : "s were"
    }: ${
      latest.map((row) =>
        `${text(row, "assignment_kind")}: ${text(row, "assignment_name")} (${
          naturalDateRange(row)
        })`
      ).join("; ")
    }.`,
    latest,
    latest.map((row) =>
      source(
        `${text(row, "assignment_kind")} assignment`,
        `${
          (text(row, "assignment_kind") ?? "assignment").toLowerCase()
        }_assignment`,
        idOf(row),
        naturalDateRange(row),
      )
    ),
    [{ id: idOf(member), type: "member", label: nameOf(member) }],
  );
}

async function appointmentPeriodSearch(
  client: SupabaseClient,
  year?: number,
  relation?: string,
) {
  if (!year) return noReliableAnswer("Please include a year.");
  const { data, error } = await client.from("member_office_appointments")
    .select("*");
  if (error) throw error;
  const boundary = relation === "before" ? `${year}-01-01` : `${year}-12-31`;
  const rows = (data ?? []).filter((row) =>
    relation === "before"
      ? (text(row, "from_date", "start_date") ?? "") < boundary
      : (text(row, "from_date", "start_date") ?? "") > boundary
  );
  if (!rows.length) {
    return groundedEmpty(`No appointments are recorded ${relation} ${year}.`);
  }
  return rowsWithMembers(
    client,
    rows,
    `Appointments ${relation} ${year}`,
    "Office appointment",
  );
}

async function memberAppointmentComparison(
  client: SupabaseClient,
  entity?: string,
) {
  const [firstName, secondName] = (entity ?? "").split("|");
  const first = await resolveMember(client, firstName),
    second = await resolveMember(client, secondName);
  if ("result" in first) return first.result;
  if ("result" in second) return second.result;
  const { data, error } = await client.from("member_office_appointments")
    .select("*").in("member_id", [idOf(first.member), idOf(second.member)]);
  if (error) throw error;
  const rows = (data ?? []).filter((row) =>
    [idOf(first.member), idOf(second.member)].includes(
      text(row, "member_id") ?? "",
    )
  ).map((row) => ({
    ...row,
    display_name: text(row, "member_id") === idOf(first.member)
      ? nameOf(first.member)
      : nameOf(second.member),
  }));
  if (!rows.length) {
    return groundedEmpty(
      `No appointment records are available for ${nameOf(first.member)} or ${
        nameOf(second.member)
      }.`,
    );
  }
  return response(
    `Recorded appointments: ${nameOf(first.member)} — ${
      rows.filter((row) => text(row, "member_id") === idOf(first.member)).length
    }; ${nameOf(second.member)} — ${
      rows.filter((row) => text(row, "member_id") === idOf(second.member))
        .length
    }.`,
    rows,
    rows.map((row) =>
      source(
        "Office appointment",
        "office_appointment",
        idOf(row),
        naturalDateRange(row),
      )
    ),
    [{ id: idOf(first.member), type: "member", label: nameOf(first.member) }, {
      id: idOf(second.member),
      type: "member",
      label: nameOf(second.member),
    }],
  );
}

function communitySummary(row: Row): string {
  const location = [text(row, "city"), text(row, "state")].filter(Boolean).join(
    ", ",
  );
  return `${nameOf(row)}${location ? ` — ${location}` : ""} · ${
    Number(row.current_resident_count ?? 0)
  } current members`;
}

function ministrySummary(row: Row): string {
  const location = [text(row, "city"), text(row, "state")].filter(Boolean).join(
    ", ",
  );
  return `${text(row, "ministry_name")}${
    text(row, "ministry_type") ? ` — ${label(text(row, "ministry_type")!)}` : ""
  }${location ? ` · ${location}` : ""}`;
}

function qualificationDetail(row: Row): string {
  const degree = text(
    row,
    "qualification",
    "degree",
    "qualification_name",
    "qualification_code",
  ) ?? "Qualification";
  const specialization = text(
    row,
    "specialization",
    "field_of_study",
    "subject",
    "primary_subject",
  );
  const institution = text(row, "institution", "institution_name");
  const year = text(row, "year_of_passing", "completion_year", "year");
  return [degree, specialization, institution, year].filter(Boolean).join(
    " · ",
  );
}

async function memberAppointmentHistory(
  client: SupabaseClient,
  entity?: string,
  entityId?: string,
) {
  const resolved = await resolveMember(client, entity, entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const memberId = idOf(member);
  const [appointmentsResult, officeTypesResult] = await Promise.all([
    client.from("member_office_appointments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("office_types").select("*"),
  ]);
  if (appointmentsResult.error) throw appointmentsResult.error;
  if (officeTypesResult.error) throw officeTypesResult.error;
  const officeTypes = rowLookup(officeTypesResult.data ?? []);
  const rows = memberScopedRows(appointmentsResult.data ?? [], memberId)
    .map((row) => ({
      ...row,
      display_name: nameOf(member),
      office_name: label(officeCode(row, officeTypes)),
    }))
    .sort((a, b) =>
      (text(a, "from_date", "start_date") ?? "").localeCompare(
        text(b, "from_date", "start_date") ?? "",
      )
    );
  if (!rows.length) {
    return groundedEmpty(
      `No appointment history is recorded for ${nameOf(member)}.`,
    );
  }
  const details = rows.map((row) =>
    `${text(row, "office_name")} — ${naturalDateRange(row)}`
  );
  return response(
    rows.length <= 10
      ? `${rows.length} appointment${
        rows.length === 1 ? " is" : "s are"
      } recorded for ${nameOf(member)}:\n• ${details.join("\n• ")}`
      : `${rows.length} appointments are recorded for ${nameOf(member)}.`,
    rows,
    rows.map((row) =>
      source(
        "Office appointment",
        "office_appointment",
        idOf(row),
        `${text(row, "office_name")}: ${dateRange(row)}`,
      )
    ),
    [{ id: memberId, type: "member", label: nameOf(member) }],
    {
      focus: semanticEntity("member", memberId, nameOf(member)),
      lastAnswer: semanticEntity("member", memberId, nameOf(member)),
    },
  );
}

async function memberLocation(
  client: SupabaseClient,
  entity?: string,
  year?: number,
  entityId?: string,
) {
  const resolved = await resolveMember(client, entity, entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  const memberId = idOf(member);
  const [
    communityRows,
    ministryRows,
    officeRows,
    communities,
    ministries,
    officeTypes,
  ] = await Promise.all([
    client.from("member_community_assignments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("member_ministry_assignments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("member_office_appointments").select("*").eq(
      "member_id",
      memberId,
    ),
    client.from("communities").select("id,name,city,district,state,country"),
    client.from("ministries").select("id,name,city,district,state,country"),
    client.from("office_types").select("*"),
  ]);
  for (
    const query of [
      communityRows,
      ministryRows,
      officeRows,
      communities,
      ministries,
      officeTypes,
    ]
  ) if (query.error) throw query.error;
  const communityLookup = rowLookup(communities.data ?? []);
  const ministryLookup = rowLookup(ministries.data ?? []);
  const officeLookup = rowLookup(officeTypes.data ?? []);
  const effective = (row: Row) =>
    year ? activeInYear(row, year) : activeOnDate(row, new Date());
  const rows: Row[] = [
    ...(communityRows.data ?? []).filter(effective).map((row) => ({
      ...row,
      assignment_kind: "Community",
      assignment_name: placeLabel(
        communityLookup.get(text(row, "community_id") ?? "") ?? {},
      ),
    })),
    ...(ministryRows.data ?? []).filter(effective).map((row) => ({
      ...row,
      assignment_kind: "Ministry",
      assignment_name: placeLabel(
        ministryLookup.get(text(row, "ministry_id") ?? "") ?? {},
      ),
    })),
    ...(officeRows.data ?? []).filter(effective).map((row) => ({
      ...row,
      assignment_kind: "Office",
      assignment_name: label(officeCode(row, officeLookup)),
    })),
  ].filter((row) => text(row, "member_id") === memberId);
  if (!rows.length) {
    return groundedEmpty(
      year
        ? `I found ${
          nameOf(member)
        }, but no community, ministry or office assignment is recorded for ${year}.`
        : `I found ${
          nameOf(member)
        }, but no current community, ministry or office assignment is recorded.`,
    );
  }
  rows.sort((a, b) =>
    (text(a, "from_date", "start_date") ?? "").localeCompare(
      text(b, "from_date", "start_date") ?? "",
    )
  );
  const facts = rows.map((row) =>
    `${text(row, "assignment_kind")}: ${text(row, "assignment_name")} (${
      dateRange(row)
    })`
  );
  return response(
    year
      ? `In ${year}, ${nameOf(member)} had these recorded assignments: ${
        facts.join("; ")
      }.`
      : `${nameOf(member)} is currently assigned to ${
        rows.map((row) => text(row, "assignment_name")).join(" and ")
      }.`,
    rows,
    rows.map((row) =>
      source(
        `${text(row, "assignment_kind")} assignment`,
        `${
          (text(row, "assignment_kind") ?? "assignment").toLowerCase()
        }_assignment`,
        idOf(row),
        `${text(row, "assignment_name")} · ${dateRange(row)}`,
      )
    ),
    [{ id: memberId, type: "member", label: nameOf(member) }],
    {
      focus: semanticEntity("member", memberId, nameOf(member)),
      lastAnswer: semanticEntity("member", memberId, nameOf(member)),
    },
  );
}

async function organizationIdentity(client: SupabaseClient, topic?: string) {
  const { data: congregations, error: congregationError } = await client
    .from("congregations").select("*").eq("active", true).order("created_at")
    .limit(1);
  if (congregationError) throw congregationError;
  const congregation = congregations?.[0];
  if (!congregation) return noReliableAnswer();
  const congregationId = idOf(congregation);
  const { data: provinces, error: provinceError } = await client
    .from("provinces").select("*").eq("congregation_id", congregationId)
    .eq("active", true).order("created_at").limit(1);
  if (provinceError) throw provinceError;
  const province = provinces?.[0];
  const congregationEvidence = () =>
    source(
      "Congregation Profile",
      "congregation",
      congregationId,
      text(congregation, "name"),
    );
  const provinceEvidence = () =>
    source(
      "Province Profile",
      "province",
      province ? idOf(province) : undefined,
      province ? text(province, "name") : undefined,
    );
  const single = (answer: string, row: Row, evidence: Row) =>
    response(
      answer,
      [row],
      [evidence],
      [],
    );
  switch (topic) {
    case "congregation_name":
      return single(
        `This is ${text(congregation, "name")}.`,
        congregation,
        congregationEvidence(),
      );
    case "province_name":
      if (!province) return noReliableAnswer();
      return single(
        `Our Province is the ${text(province, "name")}.`,
        province,
        provinceEvidence(),
      );
    case "congregation_motto":
      return single(
        `The congregation motto is “${text(congregation, "motto")}”.`,
        congregation,
        congregationEvidence(),
      );
    case "province_motto":
      if (!province) return noReliableAnswer();
      return single(
        `The Province motto is “${text(province, "motto")}”.`,
        province,
        provinceEvidence(),
      );
    case "founder":
      return single(
        `${text(congregation, "founder")} founded the congregation.`,
        congregation,
        congregationEvidence(),
      );
    case "founded_year":
      return single(
        `The congregation was founded in ${
          text(congregation, "founded_year")
        }.`,
        congregation,
        congregationEvidence(),
      );
    case "general_administration": {
      const location = [
        text(congregation, "generalate_city"),
        text(congregation, "country"),
      ].filter(Boolean).join(", ");
      return single(
        `The General Administration is in ${location}.`,
        congregation,
        source(
          "Congregation Profile",
          "congregation",
          congregationId,
          text(congregation, "generalate_address"),
        ),
      );
    }
  }
  const { data: leaders, error: leadershipError } = await client
    .from("congregation_leadership").select("*")
    .eq("congregation_id", congregationId).eq("active", true).order(
      "display_order",
    );
  if (leadershipError) throw leadershipError;
  const rows = (leaders ?? []).filter((row) => {
    if (topic === "general_councillors") {
      return text(row, "role_code") === "general_councillor";
    }
    if (topic === "leadership_countries") return true;
    return text(row, "role_code") === topic;
  });
  if (!rows.length) return noReliableAnswer();
  const answer = topic === "leadership_countries"
    ? rows.map((row) => `${nameOf(row)} — ${text(row, "country_of_origin")}`)
      .join("\n")
    : topic === "general_councillors"
    ? `The General Councillors are ${rows.map(nameOf).join(" and ")}.`
    : `${nameOf(rows[0])} is the ${text(rows[0], "role_name")}.`;
  return response(
    answer,
    rows,
    rows.map((row) =>
      source(
        "Congregation Leadership",
        "congregation_leadership",
        idOf(row),
        text(row, "role_name"),
      )
    ),
    [],
  );
}

async function vocationCohort(
  client: SupabaseClient,
  code: string,
  year?: number,
  yearTo?: number,
  eventLabel = "Vocation event",
  outputType?: "records" | "count",
  timeRelation: "in" | "before" | "after" | "current" = "in",
) {
  if (!year) {
    return noReliableAnswer(
      `Please include a year for the ${eventLabel.toLowerCase()} search.`,
    );
  }
  const from = `${year}-01-01`;
  const to = `${yearTo ?? year}-12-31`;
  let query = client.from("member_vocation_events").select("*").ilike(
    "event_type_code",
    `%${code}%`,
  );
  query = timeRelation === "before"
    ? query.lt("event_date", from)
    : timeRelation === "after"
    ? query.gt("event_date", to)
    : query.gte("event_date", from).lte("event_date", to);
  const { data, error } = await query;
  if (error) throw error;
  const period = timeRelation === "before"
    ? `before ${year}`
    : timeRelation === "after"
    ? `after ${yearTo ?? year}`
    : yearTo
    ? `${year}–${yearTo}`
    : `${year}`;
  const periodPhrase = timeRelation === "before" || timeRelation === "after"
    ? period
    : `in ${period}`;
  const rows = data ?? [];
  const wording = vocationWording(code, eventLabel);
  const aggregateLabel = `${
    vocationAggregateLabel(code, eventLabel)
  } ${periodPhrase}`;
  if (!rows.length && outputType === "count") {
    return countResponse(
      `0 members are recorded as ${wording.countVerb} ${periodPhrase}.`,
      0,
      [aggregateSource(
        aggregateLabel,
        "vocation_count",
        0,
        "matching vocation",
      )],
    );
  }
  if (!rows.length) return groundedEmpty(`${wording.zero} ${periodPhrase}.`);
  if (outputType === "count") {
    return countResponse(
      `${rows.length} member${rows.length === 1 ? "" : "s"} ${
        rows.length === 1 ? wording.singularVerb : wording.pastVerb
      } ${periodPhrase}.`,
      rows.length,
      [aggregateSource(
        aggregateLabel,
        "vocation_count",
        rows.length,
        "matching vocation",
      )],
    );
  }
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  return response(
    `${enriched.length} member${enriched.length === 1 ? "" : "s"} ${
      enriched.length === 1 ? wording.singularVerb : wording.pastVerb
    } ${periodPhrase}: ${enriched.map(nameOf).join(", ")}.`,
    enriched,
    enriched.map((row) =>
      source("Vocation Event", "vocation_event", idOf(row))
    ),
    memberEntities(enriched),
  );
}

function vocationAggregateLabel(code: string, eventLabel: string): string {
  const normalized = normalizeFact(code);
  if (normalized.includes("ordination")) return "Ordinations";
  if (normalized.includes("first profession")) return "First professions";
  if (normalized.includes("final profession")) return "Final professions";
  return label(eventLabel);
}

function vocationWording(code: string, eventLabel: string) {
  const normalized = normalizeFact(code);
  if (normalized.includes("ordination")) {
    return {
      singularVerb: "was ordained",
      pastVerb: "were ordained",
      countVerb: "having been ordained",
      zero: "No members are recorded as having been ordained",
    };
  }
  if (normalized.includes("first profession")) {
    return {
      singularVerb: "made first profession",
      pastVerb: "made first profession",
      countVerb: "making first profession",
      zero: "No members are recorded as making first profession",
    };
  }
  if (normalized.includes("final profession")) {
    return {
      singularVerb: "made final profession",
      pastVerb: "made final profession",
      countVerb: "making final profession",
      zero: "No members are recorded as making final profession",
    };
  }
  const phrase = eventLabel.toLowerCase();
  return {
    singularVerb: `recorded ${phrase}`,
    pastVerb: `recorded ${phrase}`,
    countVerb: `recording ${phrase}`,
    zero: `No members are recorded for ${phrase}`,
  };
}

async function ageSearch(
  client: SupabaseClient,
  age: number,
  comparison: "above" | "below",
  ageTo?: number,
  outputType?: "records" | "count",
) {
  const { data, error } = await client.from("members")
    .select("id,display_name,date_of_birth,member_status_code").not(
      "date_of_birth",
      "is",
      null,
    ).eq("active", true).order("date_of_birth");
  if (error) throw error;
  const today = new Date();
  const rows = (data ?? []).filter((row) => {
    const dob = text(row, "date_of_birth");
    if (!dob) return false;
    const actualAge = ageOnDate(dob, today);
    if (ageTo != null) {
      return ageInInclusiveRange(actualAge, age, ageTo);
    }
    return comparison === "below" ? actualAge < age : actualAge > age;
  });
  const description = ageTo != null
    ? age === ageTo
      ? `exactly ${age} years old`
      : `between ${Math.min(age, ageTo)} and ${Math.max(age, ageTo)} years old`
    : `${comparison === "below" ? "under" : "above"} ${age}`;
  if (!rows.length && outputType === "count") {
    return countResponse(`0 members are recorded ${description}.`, 0, [
      aggregateSource(
        `Members ${description}`,
        "member_age_count",
        0,
        "matching member",
      ),
    ]);
  }
  if (!rows.length) {
    return groundedEmpty(
      `There are no recorded members ${description}${
        ageTo == null ? " years of age" : ""
      }.`,
    );
  }
  if (outputType === "count") {
    return countResponse(
      `${rows.length} member${
        rows.length === 1 ? " is" : "s are"
      } ${description}.`,
      rows.length,
      [aggregateSource(
        `Members ${description}`,
        "member_age_count",
        rows.length,
        "matching member",
      )],
    );
  }
  return response(
    rows.length > 10
      ? `${rows.length} members are ${description}.`
      : `${rows.length} member${
        rows.length === 1 ? " is" : "s are"
      } ${description}: ${rows.map(nameOf).join(", ")}.`,
    rows,
    rows.map((row) =>
      source(
        "Religious record",
        "member",
        idOf(row),
        dateDetail(row, "date_of_birth"),
      )
    ),
    memberEntities(rows),
    {
      entitySet: {
        type: "member",
        entities: rows.map((row) =>
          semanticEntity("member", idOf(row), nameOf(row))
        ),
      },
    },
  );
}

async function birthdayMonthSearch(
  client: SupabaseClient,
  month?: number,
  outputType?: "records" | "count",
) {
  if (!month || month < 1 || month > 12) {
    return noReliableAnswer("Please include a valid birthday month.");
  }
  const { data, error } = await client.from("members").select(
    "id,display_name,date_of_birth,member_status_code",
  ).eq("active", true).not("date_of_birth", "is", null).order(
    "date_of_birth",
  );
  if (error) throw error;
  const rows = (data ?? []).filter((row) => {
    const dob = text(row, "date_of_birth");
    return dob && birthdayMatchesMonth(dob, month);
  });
  const monthName = new Intl.DateTimeFormat("en", {
    month: "long",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(2000, month - 1, 1)));
  if (outputType === "count") {
    return countResponse(
      `${rows.length} current member${
        rows.length === 1 ? " has" : "s have"
      } a recorded birthday in ${monthName}.`,
      rows.length,
      [aggregateSource(
        `${monthName} birthdays`,
        "member_birthday_count",
        rows.length,
        "matching member",
      )],
    );
  }
  if (!rows.length) {
    return groundedEmpty(
      `No current members have a recorded birthday in ${monthName}.`,
    );
  }
  return response(
    `${rows.length} current member${
      rows.length === 1 ? " has" : "s have"
    } a recorded birthday in ${monthName}:\n• ${
      rows.map((row) =>
        `${nameOf(row)} — ${birthdayMonthDay(text(row, "date_of_birth")!)}`
      ).join("\n• ")
    }`,
    rows.map((row) => ({
      id: idOf(row),
      display_name: nameOf(row),
      birthday: birthdayMonthDay(text(row, "date_of_birth")!),
    })),
    rows.map((row) =>
      source(
        "Birthday",
        "member_birthday",
        idOf(row),
        birthdayMonthDay(text(row, "date_of_birth")!),
      )
    ),
    memberEntities(rows),
  );
}

async function vocationAnniversarySearch(
  client: SupabaseClient,
  anniversary?: number,
  targetYear?: number,
  outputType?: "records" | "count",
) {
  if (!anniversary || !targetYear) {
    return noReliableAnswer(
      "Please include an anniversary number and target year.",
    );
  }
  const professionYear = professionYearForAnniversary(
    targetYear,
    anniversary,
  );
  const [eventsResult, members] = await Promise.all([
    client.from("member_vocation_events").select("*").ilike(
      "event_type_code",
      "%FIRST_PROFESSION%",
    ).gte("event_date", `${professionYear}-01-01`).lte(
      "event_date",
      `${professionYear}-12-31`,
    ),
    activeMemberLookup(client),
  ]);
  if (eventsResult.error) throw eventsResult.error;
  const unique = new Map<string, Row>();
  for (const event of eventsResult.data ?? []) {
    const memberId = text(event, "member_id") ?? "";
    const member = members.get(memberId);
    if (member && !unique.has(memberId)) {
      unique.set(memberId, { ...event, display_name: nameOf(member) });
    }
  }
  const rows = [...unique.values()].sort((a, b) =>
    nameOf(a).localeCompare(nameOf(b))
  );
  const ordinal = ordinalNumber(anniversary);
  const answer = rows.length
    ? `${rows.length} current member${
      rows.length === 1 ? " will" : "s will"
    } celebrate the ${ordinal} anniversary of first profession in ${targetYear}${
      outputType === "count" ? "." : `:\n• ${rows.map(nameOf).join("\n• ")}`
    }`
    : `No current members are recorded as reaching the ${ordinal} anniversary of first profession in ${targetYear}.`;
  if (outputType === "count") {
    return countResponse(answer, rows.length, [aggregateSource(
      `${ordinal} first-profession anniversaries in ${targetYear}`,
      "vocation_anniversary_count",
      rows.length,
      "matching member",
    )]);
  }
  if (!rows.length) return groundedEmpty(answer);
  return response(
    answer,
    rows,
    rows.map((row) =>
      source(
        "First profession anniversary",
        "vocation_anniversary",
        idOf(row),
        `${ordinal} anniversary · ${targetYear}`,
      )
    ),
    memberEntities(rows),
  );
}

function birthdayMonthDay(value: string): string {
  const [, month, day] = value.slice(0, 10).split("-").map(Number);
  return new Intl.DateTimeFormat("en", {
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(2000, month - 1, day)));
}

async function memberAgeExtreme(client: SupabaseClient, direction: string) {
  const [{ data, error, count }, totalResult] = await Promise.all([
    client.from("members").select("id,display_name,date_of_birth", {
      count: "exact",
    }).eq("active", true).not("date_of_birth", "is", null).order(
      "date_of_birth",
      { ascending: direction === "oldest" },
    ),
    client.from("members").select("id", { count: "exact", head: true }).eq(
      "active",
      true,
    ),
  ]);
  if (error) throw error;
  if (totalResult.error) throw totalResult.error;
  const rows = data ?? [];
  if (!rows.length) {
    return groundedEmpty("No current member has a recorded date of birth.");
  }
  const selectedDob = text(rows[0], "date_of_birth");
  const tied = rows.filter((row) => text(row, "date_of_birth") === selectedDob);
  const age = ageOnDate(selectedDob!, new Date());
  const qualifier = (totalResult.count ?? 0) > (count ?? rows.length)
    ? "Among current members with a recorded date of birth, "
    : "";
  return response(
    `${qualifier}${tied.map(nameOf).join(" and ")} ${
      tied.length === 1 ? "is" : "are"
    } the ${direction} current member${
      tied.length === 1 ? "" : "s"
    }, aged ${age} (born ${formatDate(selectedDob!)}).`,
    tied,
    tied.map((row) =>
      source(
        "Religious record",
        "member",
        idOf(row),
        dateDetail(row, "date_of_birth"),
      )
    ),
    memberEntities(tied),
    tied.length === 1
      ? {
        focus: semanticEntity("member", idOf(tied[0]), nameOf(tied[0])),
        lastAnswer: semanticEntity("member", idOf(tied[0]), nameOf(tied[0])),
      }
      : {
        entitySet: {
          type: "member",
          entities: tied.map((row) =>
            semanticEntity("member", idOf(row), nameOf(row))
          ),
        },
      },
  );
}

async function communitySizeRanking(client: SupabaseClient, direction: string) {
  const today = new Date();
  const [communitiesResult, assignmentsResult] = await Promise.all([
    client.from("communities").select("id,name,city,district,state,country").eq(
      "active",
      true,
    ),
    client.from("member_community_assignments").select("*"),
  ]);
  if (communitiesResult.error) throw communitiesResult.error;
  if (assignmentsResult.error) throw assignmentsResult.error;
  const activeMembers = await activeMemberLookup(client);
  const counts = new Map<string, Row[]>();
  for (const community of communitiesResult.data ?? []) {
    counts.set(idOf(community), []);
  }
  for (const assignment of assignmentsResult.data ?? []) {
    const communityId = text(assignment, "community_id") ?? "";
    if (
      counts.has(communityId) &&
      activeMembers.has(text(assignment, "member_id") ?? "") &&
      activeOnDate(assignment, today)
    ) counts.get(communityId)!.push(assignment);
  }
  if (!counts.size) {
    return groundedEmpty("Communio has no active communities to rank.");
  }
  const extreme = direction === "smallest"
    ? Math.min(...[...counts.values()].map((rows) => rows.length))
    : Math.max(...[...counts.values()].map((rows) => rows.length));
  const communities = (communitiesResult.data ?? []).filter((row) =>
    counts.get(idOf(row))?.length === extreme
  );
  const adjective = direction === "smallest" ? "fewest" : "largest";
  const answer = communities.length === 1
    ? `${
      placeLabel(communities[0])
    } has the ${adjective} current membership with ${extreme} member${
      extreme === 1 ? "" : "s"
    }.`
    : `${
      communities.map(placeLabel).join(", ")
    } are tied for the ${adjective} current membership with ${extreme} member${
      extreme === 1 ? "" : "s"
    } each.`;
  const evidence = communities.flatMap((community) =>
    counts.get(idOf(community)) ?? []
  );
  const semanticCommunities = communities.map((community) =>
    semanticEntity("community", idOf(community), placeLabel(community))
  );
  return response(
    answer,
    communities.map((community) => ({ ...community, member_count: extreme })),
    evidence.map((row) =>
      source("Current community assignment", "community_assignment", idOf(row))
    ),
    [],
    semanticCommunities.length === 1
      ? { focus: semanticCommunities[0], lastAnswer: semanticCommunities[0] }
      : { entitySet: { type: "community", entities: semanticCommunities } },
  );
}

async function currentTargetCounts(
  client: SupabaseClient,
  kind: "community" | "ministry",
) {
  const targetTable = kind === "community" ? "communities" : "ministries";
  const assignmentTable = kind === "community"
    ? "member_community_assignments"
    : "member_ministry_assignments";
  const targetKey = `${kind}_id`;
  const [targetsResult, assignmentsResult, activeMembers] = await Promise.all([
    client.from(targetTable).select("*").eq("active", true),
    client.from(assignmentTable).select("*"),
    activeMemberLookup(client),
  ]);
  if (targetsResult.error) throw targetsResult.error;
  if (assignmentsResult.error) throw assignmentsResult.error;
  const targets = targetsResult.data ?? [];
  const counts = distinctActiveCounts(
    assignmentsResult.data ?? [],
    targetKey,
    new Set(targets.map(idOf)),
    new Set(activeMembers.keys()),
    (row) => activeOnDate(row, new Date()),
  );
  return { targets, assignments: assignmentsResult.data ?? [], counts };
}

async function communitySizeThreshold(
  client: SupabaseClient,
  threshold: number,
) {
  const { targets, counts } = await currentTargetCounts(client, "community");
  const rows = targets.filter((row) => (counts.get(idOf(row)) ?? 0) < threshold)
    .map((row) => ({ ...row, member_count: counts.get(idOf(row)) ?? 0 }));
  return response(
    `${rows.length} active communit${
      rows.length === 1 ? "y has" : "ies have"
    } fewer than ${threshold} current members${
      rows.length
        ? `: ${
          rows.map((row) => `${nameOf(row)} (${row.member_count})`).join(", ")
        }`
        : ""
    }.`,
    rows,
    [aggregateSource(
      `Active communities below ${threshold} members`,
      "community_assignment_aggregate",
      rows.length,
      "community",
    )],
    rows.map((row) => ({
      id: idOf(row),
      type: "community",
      label: nameOf(row),
    })),
  );
}

async function ministrySizeRanking(client: SupabaseClient) {
  const { targets, counts } = await currentTargetCounts(client, "ministry");
  if (!targets.length) {
    return groundedEmpty("Communio has no active ministries to rank.");
  }
  const maximum = Math.max(...targets.map((row) => counts.get(idOf(row)) ?? 0));
  const rows = targets.filter((row) => (counts.get(idOf(row)) ?? 0) === maximum)
    .map((row) => ({ ...row, member_count: maximum }));
  const names = rows.map(nameOf).join(", ");
  return response(
    rows.length === 1
      ? `${names} has the most current members with ${maximum}.`
      : `${names} are tied for the most current members with ${maximum} each.`,
    rows,
    [aggregateSource(
      "Current ministry membership ranking",
      "ministry_assignment_aggregate",
      maximum,
      "distinct member",
    )],
    rows.map((row) => ({
      id: idOf(row),
      type: "ministry",
      label: nameOf(row),
    })),
  );
}

async function memberAnalytics(client: SupabaseClient, topic: string) {
  if (topic === "members_by_state") {
    const [nativeResult, activeMembers] = await Promise.all([
      client.from("member_native_details").select("member_id,state"),
      activeMemberLookup(client),
    ]);
    if (nativeResult.error) throw nativeResult.error;
    const memberStates = new Map<string, string>();
    for (const row of nativeResult.data ?? []) {
      const memberId = text(row, "member_id") ?? "";
      const state = text(row, "state");
      if (activeMembers.has(memberId) && state) {
        memberStates.set(memberId, state);
      }
    }
    const grouped = new Map<string, number>();
    for (const state of memberStates.values()) {
      grouped.set(state, (grouped.get(state) ?? 0) + 1);
    }
    const rows = [...grouped].map(([state, count]) => ({ state, count })).sort((
      a,
      b,
    ) => b.count - a.count || a.state.localeCompare(b.state));
    if (!rows.length) {
      return groundedEmpty("No state is recorded for current members.");
    }
    return response(
      `Current members by recorded native state: ${
        rows.map((row) => `${row.state} (${row.count})`).join(", ")
      }.`,
      rows,
      [aggregateSource(
        "Member native-state distribution",
        "member_native_state_aggregate",
        memberStates.size,
        "current member",
      )],
      [],
    );
  }
  const [datedResult, totalResult] = await Promise.all([
    client.from("members").select("id,display_name,date_of_birth").eq(
      "active",
      true,
    ).not("date_of_birth", "is", null),
    client.from("members").select("id", { count: "exact", head: true }).eq(
      "active",
      true,
    ),
  ]);
  if (datedResult.error) throw datedResult.error;
  if (totalResult.error) throw totalResult.error;
  const data = datedResult.data;
  const rows = data ?? [];
  const summary = ageSummary(rows, new Date());
  if (!summary.ages.length) {
    return groundedEmpty("No current member has a recorded date of birth.");
  }
  const coverage = `${summary.ages.length} of ${
    totalResult.count ?? summary.ages.length
  } current members with a recorded date of birth`;
  if (topic === "age_distribution") {
    return response(
      `Age distribution among ${coverage}: ${
        summary.bands.map((row) => `${row.band}: ${row.count}`).join(", ")
      }.`,
      summary.bands,
      [aggregateSource(
        "Current member age distribution",
        "member_age_aggregate",
        summary.ages.length,
        "dated member",
      )],
      [],
    );
  }
  const statistic = topic === "median_age" ? summary.median! : summary.average!;
  const statisticLabel = topic === "median_age" ? "median" : "average";
  const item = {
    statistic: statisticLabel,
    age_years: Number(statistic.toFixed(1)),
    member_count: summary.ages.length,
  };
  return response(
    `The ${statisticLabel} age is ${
      Number(statistic.toFixed(1))
    } years among ${coverage}.`,
    [item],
    [aggregateSource(
      `Current member ${statisticLabel} age`,
      "member_age_aggregate",
      summary.ages.length,
      "dated member",
    )],
    [],
  );
}

async function composedCommunityQuery(
  client: SupabaseClient,
  input: Interpretation,
) {
  const ranking = await communitySizeRanking(client, input.role ?? "largest");
  const semantic = ranking.semantic_context;
  if (semantic?.entitySet && semantic.entitySet.entities.length > 1) {
    return clarificationResponse(
      `Several communities are tied for ${
        input.role === "smallest" ? "smallest" : "largest"
      }: ${
        semantic.entitySet.entities.map((entity) => entity.name).join("; ")
      }. Which community do you mean?`,
      [],
    );
  }
  const community = semantic?.focus;
  if (!community) return ranking;
  const superiorTopic = input.topic === "superior" ||
    input.topic === "superior_location" || input.topic === "superior_age";
  const nested: Interpretation = {
    intent: superiorTopic
      ? "community_superior_history"
      : "community_membership_history",
    entity: community.name,
    entityId: community.id,
    year: input.year,
    topic: input.year ? undefined : "current",
    outputType: input.outputType,
  };
  const nestedResult = await assignmentSearch(
    client,
    "community",
    nested,
    superiorTopic,
    false,
  );
  if (input.topic !== "superior_location" && input.topic !== "superior_age") {
    return nestedResult;
  }
  const superior = nestedResult.semantic_context?.lastAnswer ??
    nestedResult.semantic_context?.focus;
  if (!superior || superior.type !== "member") return nestedResult;
  return input.topic === "superior_location"
    ? memberLocation(client, superior.name, undefined, superior.id)
    : memberProfileFacts(client, superior.name, "age", superior.id);
}

async function historicalOfficeHolder(
  client: SupabaseClient,
  input: Interpretation,
) {
  if (!input.year) {
    return noReliableAnswer(
      "Please include a year for the leadership history search.",
    );
  }
  const [appointmentsResult, officeTypesResult] = await Promise.all([
    client.from("member_office_appointments").select("*"),
    client.from("office_types").select("*"),
  ]);
  if (appointmentsResult.error) throw appointmentsResult.error;
  if (officeTypesResult.error) throw officeTypesResult.error;
  const officeTypes = rowLookup(officeTypesResult.data ?? []);
  const requestedRole = input.role ?? "provincial";
  const rows = (appointmentsResult.data ?? []).filter((row) => {
    const actualRole = normalizeFact(officeCode(row, officeTypes));
    return actualRole === normalizeFact(requestedRole) &&
      activeInYear(row, input.year!);
  });
  const roleLabel = label(requestedRole);
  if (!rows.length) {
    return groundedEmpty(
      `I found no recorded ${roleLabel} appointment covering ${input.year}.`,
    );
  }
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  if (input.outputType === "count") {
    return countResponse(
      `${enriched.length} member${
        enriched.length === 1 ? "" : "s"
      } served as ${roleLabel} in ${input.year}.`,
      enriched.length,
    );
  }
  return response(
    `${enriched.map(nameOf).join(", ")} ${
      enriched.length === 1 ? "served" : "served"
    } as ${roleLabel} in ${input.year}.`,
    enriched,
    enriched.map((row) =>
      source("Office appointment", "appointment", idOf(row))
    ),
    memberEntities(enriched),
    enriched.length === 1
      ? {
        focus: semanticEntity(
          "member",
          text(enriched[0], "member_id") ?? "",
          nameOf(enriched[0]),
        ),
        lastAnswer: semanticEntity(
          "member",
          text(enriched[0], "member_id") ?? "",
          nameOf(enriched[0]),
        ),
      }
      : {
        entitySet: {
          type: "member",
          entities: enriched.map((row) =>
            semanticEntity("member", text(row, "member_id") ?? "", nameOf(row))
          ),
        },
      },
  );
}

async function governanceBodyMembership(
  client: SupabaseClient,
  input: Interpretation,
) {
  if (!input.year) {
    return noReliableAnswer(
      "Please include a year for the governance history search.",
    );
  }
  const [appointmentsResult, officeTypesResult] = await Promise.all([
    client.from("member_office_appointments").select("*"),
    client.from("office_types").select("*"),
  ]);
  if (appointmentsResult.error) throw appointmentsResult.error;
  if (officeTypesResult.error) throw officeTypesResult.error;
  const officeTypes = rowLookup(officeTypesResult.data ?? []);
  const provincialCouncilRoles = new Set([
    "provincial",
    "assistant provincial",
    "vice provincial",
    "provincial secretary",
    "provincial bursar",
    "provincial treasurer",
    "provincial councillor",
  ]);
  const rows = (appointmentsResult.data ?? []).filter((row) =>
    provincialCouncilRoles.has(normalizeFact(officeCode(row, officeTypes))) &&
    activeInYear(row, input.year!)
  );
  if (!rows.length) {
    return groundedEmpty(
      `I found no recorded Provincial Council appointments covering ${input.year}.`,
    );
  }
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
    office_name: label(officeCode(row, officeTypes)),
  }));
  if (input.outputType === "count") {
    return countResponse(
      `The Provincial Council in ${input.year} had ${enriched.length} recorded member${
        enriched.length === 1 ? "" : "s"
      }.`,
      enriched.length,
    );
  }
  return response(
    `The Provincial Council in ${input.year} consisted of: ${
      enriched.map((row) => `${nameOf(row)} — ${text(row, "office_name")}`)
        .join("; ")
    }.`,
    enriched,
    enriched.map((row) =>
      source(
        "Office appointment",
        "appointment",
        idOf(row),
        text(row, "office_name"),
      )
    ),
    memberEntities(enriched),
  );
}

async function governanceDirectory(client: SupabaseClient) {
  const { data, error } = await client.from("v_governance_body_directory")
    .select("*").eq("status_code", "ACTIVE").order("display_order").order(
      "name",
    );
  if (error) throw error;
  const rows = data ?? [];
  if (!rows.length) {
    return groundedEmpty(
      "No governance bodies are available with your current access.",
    );
  }
  return response(
    `${rows.length} active governance bodies are recorded:\n• ${
      rows.map(nameOf).join("\n• ")
    }`,
    rows,
    rows.map((row) =>
      source(
        "Governance body",
        "governance_body",
        text(row, "governance_body_id"),
        nameOf(row),
      )
    ),
    rows.map((row) => ({
      id: text(row, "governance_body_id"),
      type: "governance_body",
      label: nameOf(row),
    })),
    {
      entitySet: {
        type: "governance_body",
        entities: rows.map((row) =>
          semanticEntity(
            "governance_body",
            text(row, "governance_body_id") ?? "",
            nameOf(row),
          )
        ),
      },
    },
  );
}

async function resolveGovernanceBodyForQuery(
  client: SupabaseClient,
  input: Interpretation,
) {
  const { data, error } = await client.from("v_governance_body_directory")
    .select("*").order("display_order").order("name");
  if (error) throw error;
  const query = cleanEntity(input.entity);
  const resolution = resolveGovernanceBody(data ?? [], input.entityId ?? query);
  if (resolution.kind === "missing") {
    return {
      result: groundedEmpty(
        `I couldn't find a governance body matching '${query}'.`,
      ),
    };
  }
  if (resolution.kind === "ambiguous") {
    return {
      result: clarificationResponse(
        `I found more than one matching governance body. Did you mean: ${
          resolution.rows.map(nameOf).join("; ")
        }?`,
        resolution.rows,
      ),
    };
  }
  return { body: resolution.row };
}

function governanceBodyContext(body: Row): SemanticContext {
  const entity = semanticEntity(
    "governance_body",
    text(body, "governance_body_id") ?? "",
    nameOf(body),
  );
  return { focus: entity, lastAnswer: entity };
}

async function governanceBodyProfile(
  client: SupabaseClient,
  input: Interpretation,
) {
  const resolved = await resolveGovernanceBodyForQuery(client, input);
  if ("result" in resolved) return resolved.result;
  const body = resolved.body;
  const count = Number(body.current_member_count ?? 0);
  const facts = [
    `${nameOf(body)} is an ${
      String(body.status_code ?? "active").toLowerCase()
    } governance body with ${count} current member${count === 1 ? "" : "s"}.`,
    text(body, "chair_display_name")
      ? `Chair: ${text(body, "chair_display_name")}`
      : "No chair is currently recorded.",
    text(body, "purpose") ? `Purpose: ${text(body, "purpose")}` : undefined,
  ].filter(Boolean).join("\n");
  return response(facts, [body], [
    source(
      "Governance body",
      "governance_body",
      text(body, "governance_body_id"),
      facts,
    ),
  ], [{
    id: text(body, "governance_body_id"),
    type: "governance_body",
    label: nameOf(body),
  }], governanceBodyContext(body));
}

async function currentGovernanceMembers(
  client: SupabaseClient,
  bodyId: string,
) {
  const { data, error } = await client.from("v_governance_body_current_members")
    .select("*").eq("governance_body_id", bodyId);
  if (error) throw error;
  return orderGovernanceMembers(data ?? []);
}

async function governanceBodyMembers(
  client: SupabaseClient,
  input: Interpretation,
) {
  const resolved = await resolveGovernanceBodyForQuery(client, input);
  if ("result" in resolved) return resolved.result;
  const body = resolved.body;
  const rows = await currentGovernanceMembers(
    client,
    text(body, "governance_body_id") ?? "",
  );
  if (!rows.length) {
    return groundedEmpty(
      `No current members are recorded for ${nameOf(body)}.`,
    );
  }
  return response(
    `${nameOf(body)} has ${rows.length} current member${
      rows.length === 1 ? "" : "s"
    }:\n• ${
      rows.map((row) =>
        `${nameOf(row)} — ${
          text(row, "role_title") ?? label(text(row, "role_code") ?? "member")
        }`
      ).join("\n• ")
    }`,
    rows,
    rows.map((row) =>
      source(
        "Governance membership",
        "governance_membership",
        text(row, "membership_id"),
        `${nameOf(row)} · ${
          text(row, "role_title") ?? label(text(row, "role_code") ?? "member")
        }`,
      )
    ),
    memberEntities(rows),
    governanceBodyContext(body),
  );
}

async function governanceBodyLeader(
  client: SupabaseClient,
  input: Interpretation,
) {
  const resolved = await resolveGovernanceBodyForQuery(client, input);
  if ("result" in resolved) return resolved.result;
  const body = resolved.body;
  const leaders = governanceLeaders(
    await currentGovernanceMembers(
      client,
      text(body, "governance_body_id") ?? "",
    ),
  );
  if (!leaders.length) {
    return groundedEmpty(`No chair is currently recorded for ${nameOf(body)}.`);
  }
  const leader = leaders[0];
  const role = text(leader, "role_title") ??
    label(text(leader, "role_code") ?? "chair");
  return response(
    `${nameOf(leader)} is the current ${role} of the ${nameOf(body)}.`,
    [leader],
    [source(
      "Governance leadership",
      "governance_leadership",
      text(leader, "membership_id"),
      `${nameOf(leader)} · ${role}`,
    )],
    memberEntities([leader]),
    governanceBodyContext(body),
  );
}

function officeCode(row: Row, officeTypes: Map<string, Row>): string {
  const officeType = officeTypes.get(text(row, "office_type_id") ?? "");
  return text(row, "office_type_code", "office_code") ??
    text(officeType ?? {}, "code", "office_type_code") ?? "";
}

async function eligibilitySearch(
  client: SupabaseClient,
  role: string,
  entity?: string,
) {
  const requested = canonicalRole(cleanEntity(role) || "principal");
  const views = ["v_responsibility_eligibility", "v_office_eligibility"];
  const rows: Row[] = [];
  for (const view of views) {
    const { data, error } = await client.from(view).select("*");
    if (error) throw error;
    rows.push(
      ...(data ?? []).filter((row) =>
        roleOf(row) === requested ||
        (!roleOf(row) &&
          normalizeFact(JSON.stringify(row)).includes(
            requested.replaceAll("_", " "),
          ))
      ),
    );
  }
  const uniqueRows = [
    ...new Map(
      rows.map((row) => [`${text(row, "member_id")}:${requested}`, row]),
    ).values(),
  ];
  const members = await memberLookup(client);
  if (entity) {
    const resolved = await resolveMember(client, entity);
    if ("result" in resolved) return resolved.result;
    const memberId = idOf(resolved.member);
    const evaluation = uniqueRows.find((row) =>
      text(row, "member_id") === memberId
    );
    if (!evaluation) {
      return groundedEmpty(
        `${nameOf(resolved.member)} is NOT EVALUATED for ${
          label(requested)
        } in the authorized eligibility records.`,
      );
    }
    const status = eligibilityStatus(evaluation);
    const reason = text(
      evaluation,
      "eligibility_reason",
      "reason",
      "reason_text",
      "explanation",
    );
    const detail = reason
      ? ` ${reason}`
      : status === "NOT ELIGIBLE"
      ? " A detailed reason is not available in the authorized reporting data."
      : "";
    const item = {
      ...evaluation,
      display_name: nameOf(resolved.member),
      evaluated_role: requested,
      normalized_eligibility_status: status,
    };
    return response(
      `${nameOf(resolved.member)} is currently ${status} for ${
        label(requested)
      } according to the recorded criteria.${detail}`,
      [item],
      [source("Eligibility record", "eligibility", idOf(evaluation), reason)],
      [{ id: memberId, type: "member", label: nameOf(resolved.member) }],
    );
  }
  const eligible = uniqueRows.filter((row) =>
    eligibilityStatus(row) === "ELIGIBLE"
  ).map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  if (!eligible.length) {
    return groundedEmpty(
      `No members currently meet the recorded eligibility criteria for ${
        label(requested)
      }.`,
    );
  }
  return response(
    `According to the recorded eligibility rules, ${eligible.length} member${
      eligible.length === 1 ? "" : "s"
    } currently meet the criteria for ${label(requested)}: ${
      eligible.map(nameOf).join(", ")
    }.`,
    eligible,
    eligible.map((row) =>
      source(
        "Eligibility record",
        "eligibility",
        idOf(row),
        text(row, "eligibility_reason", "reason", "reason_text"),
      )
    ),
    memberEntities(eligible),
  );
}

async function appointmentCompliance(
  client: SupabaseClient,
  topic: string,
  outputType?: "records" | "count",
) {
  const [appointmentsResult, responsibilityResult, officeResult] = await Promise
    .all([
      client.from("v_demo_current_office_holders").select("*"),
      client.from("v_responsibility_eligibility").select("*"),
      client.from("v_office_eligibility").select("*"),
    ]);
  for (
    const query of [appointmentsResult, responsibilityResult, officeResult]
  ) if (query.error) throw query.error;
  const rows = currentAppointmentCompliance(appointmentsResult.data ?? [], [
    ...(responsibilityResult.data ?? []),
    ...(officeResult.data ?? []),
  ]);
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  const counts = new Map(
    ["COMPLIANT", "NOT EVALUATED", "CONDITIONAL", "NOT COMPLIANT"].map((
      status,
    ) => [
      status,
      enriched.filter((row) => text(row, "compliance_status") === status)
        .length,
    ]),
  );
  if (topic === "issues") {
    const issues = enriched.filter((row) =>
      text(row, "compliance_status") === "NOT COMPLIANT"
    );
    if (!issues.length) {
      return groundedEmpty(
        "No current appointments are recorded as NOT COMPLIANT.",
      );
    }
    if (outputType === "count") {
      return countResponse(
        `${issues.length} current appointment${
          issues.length === 1 ? " is" : "s are"
        } recorded as NOT COMPLIANT.`,
        issues.length,
        [aggregateSource(
          "Appointment compliance",
          "appointment_compliance_count",
          issues.length,
          "non-compliant appointment",
        )],
      );
    }
    return response(
      `Current appointment compliance issues:\n• ${
        issues.map((row) =>
          `${nameOf(row)} — ${label(roleOf(row) || "appointment")}${
            text(row, "compliance_reason")
              ? `: ${text(row, "compliance_reason")}`
              : ""
          }`
        ).join("\n• ")
      }`,
      issues,
      issues.map((row) =>
        source(
          "Appointment compliance",
          "appointment_compliance",
          idOf(row),
          [
            text(row, "compliance_status"),
            text(row, "compliance_reason"),
            text(row, "rule_code"),
          ].filter(Boolean).join(" · "),
        )
      ),
      memberEntities(issues),
    );
  }
  const summary = ["COMPLIANT", "NOT EVALUATED", "CONDITIONAL", "NOT COMPLIANT"]
    .map((status) => `• ${counts.get(status) ?? 0} ${status}`).join("\n");
  if (outputType === "count") {
    return countResponse(
      `${counts.get("COMPLIANT") ?? 0} current appointments are COMPLIANT.`,
      counts.get("COMPLIANT") ?? 0,
      [aggregateSource(
        "Appointment compliance",
        "appointment_compliance_count",
        enriched.length,
        "evaluated appointment",
      )],
    );
  }
  return response(
    `Current appointment compliance:\n${summary}`,
    enriched,
    enriched.map((row) =>
      source(
        "Appointment compliance",
        "appointment_compliance",
        idOf(row),
        text(row, "compliance_status"),
      )
    ),
    memberEntities(enriched),
  );
}

async function appointmentExpiry(client: SupabaseClient) {
  const today = new Date().toISOString().slice(0, 10);
  const future = new Date(Date.now() + 90 * 86400000).toISOString().slice(
    0,
    10,
  );
  const { data, error } = await client.from("member_office_appointments")
    .select("*")
    .not("to_date", "is", null).gte("to_date", today).lte("to_date", future)
    .order("to_date");
  if (error) throw error;
  return rowsWithMembers(
    client,
    data ?? [],
    "Appointments ending in the next 90 days",
    "Appointment",
  );
}

async function appointmentSearch(client: SupabaseClient, entity?: string) {
  const { data, error } = await client.from("v_demo_current_office_holders")
    .select("*");
  if (error) throw error;
  const needle = cleanEntity(entity).toLowerCase();
  const rows = (data ?? []).filter((row) => {
    if (!needle) return true;
    if (needle === "provincial_bursar") {
      const role = normalizeFact(
        text(row, "office_type_code", "office_name") ?? "",
      );
      return [
        "provincial bursar",
        "provincial treasurer",
        "bursar",
        "treasurer",
      ].includes(role);
    }
    if (needle.includes("provincial")) {
      return text(row, "office_type_code") === "provincial";
    }
    return JSON.stringify(row).toLowerCase().includes(needle);
  });
  if (!rows.length) return noReliableAnswer();
  return response(
    rows.map((row) =>
      `${label(text(row, "office_name", "office_type_code") ?? "Office")}: ${
        nameOf(row)
      }`
    ).join("\n"),
    rows,
    rows.map((row) => source("Current appointment", "appointment", idOf(row))),
    memberEntities(rows),
  );
}

async function assignmentSearch(
  client: SupabaseClient,
  kind: "community" | "ministry",
  input: Interpretation,
  superiorOnly: boolean,
  leadershipOnly = false,
) {
  const targetsTable = kind === "community" ? "communities" : "ministries";
  const assignmentsTable = kind === "community"
    ? "member_community_assignments"
    : "member_ministry_assignments";
  const targetField = `${kind}_id`;
  const { data: targets, error: targetError } = await client.from(targetsTable)
    .select("*");
  if (targetError) throw targetError;
  const needle = normalizePlaceName(cleanEntity(input.entity), kind);
  const targetMatches = input.entityId
    ? (targets ?? []).filter((row) => idOf(row) === input.entityId)
    : needle
    ? matchingDirectoryRows(targets ?? [], cleanEntity(input.entity), kind)
    : (targets ?? []);
  if (input.entityId && !targetMatches.length) {
    return noReliableAnswer(
      `That ${kind} is no longer available with your current access.`,
    );
  }
  if (needle && targetMatches.length > 1) {
    return clarificationResponse(
      `I found more than one matching ${kind}. Did you mean: ${
        targetMatches.map(placeLabel).join("; ")
      }?`,
      targetMatches,
    );
  }
  const matchingIds = new Set(targetMatches.map(idOf));
  const { data, error } = await client.from(assignmentsTable).select("*");
  if (error) throw error;
  const rows = (data ?? []).filter((row) => {
    if (
      needle &&
      !matchingIds.has(text(row, targetField) ?? "") &&
      !normalizeFact(JSON.stringify(row)).includes(needle)
    ) return false;
    if (
      superiorOnly &&
      !(text(row, "responsibility_code") ?? "").toLowerCase().includes(
        "superior",
      )
    ) return false;
    if (input.topic === "current" && !activeOnDate(row, new Date())) {
      return false;
    }
    if (leadershipOnly) {
      const role = (text(row, "responsibility_code") ?? "").toLowerCase();
      if (
        ![
          "head",
          "director",
          "principal",
          "manager",
          "administrator",
          "coordinator",
          "chaplain",
        ].some((value) => role.includes(value))
      ) return false;
      if (input.role && !role.includes(input.role.toLowerCase())) return false;
    }
    if (input.year && !overlapsYear(row, input.year)) return false;
    return true;
  });
  let scopedRows = rows;
  if (leadershipOnly && input.topic === "earliest") {
    scopedRows = [...rows].sort((a, b) =>
      (text(a, "from_date") ?? "9999-12-31").localeCompare(
        text(b, "from_date") ?? "9999-12-31",
      )
    ).slice(0, 1);
  } else if (leadershipOnly && input.topic === "previous") {
    scopedRows = rows.filter((row) => !activeOnDate(row, new Date())).sort(
      (a, b) =>
        (text(b, "to_date", "from_date") ?? "").localeCompare(
          text(a, "to_date", "from_date") ?? "",
        ),
    ).slice(0, 1);
  } else if (leadershipOnly && input.topic === "past") {
    scopedRows = rows.filter((row) => !activeOnDate(row, new Date()));
  }
  const resultRows = (input.outputType === "count" || input.year)
    ? uniqueMemberRows(scopedRows)
    : scopedRows;
  const targetName = targetMatches[0]
    ? placeLabel(targetMatches[0])
    : cleanEntity(input.entity);
  if (kind === "ministry" && leadershipOnly && input.topic === "earliest") {
    if (!resultRows.length) {
      return groundedEmpty(
        `I found no historical ${
          label(input.role ?? "leadership")
        } appointment recorded for ${targetName}.`,
      );
    }
    const members = await memberLookup(client);
    const row = {
      ...resultRows[0],
      display_name: members.get(text(resultRows[0], "member_id") ?? "")
        ?.display_name ?? nameOf(resultRows[0]),
    };
    return response(
      `Communio's earliest recorded ${
        label(input.role ?? "leader")
      } for ${targetName} was ${nameOf(row)}, serving from ${
        text(row, "from_date")
          ? formatDate(text(row, "from_date")!)
          : "an unrecorded start date"
      }.`,
      [row],
      [source(
        "Ministry leadership assignment",
        "ministry_assignment",
        idOf(row),
        naturalDateRange(row),
      )],
      memberEntities([row]),
      targetMatches[0]
        ? {
          focus: semanticEntity("ministry", idOf(targetMatches[0]), targetName),
        }
        : undefined,
    );
  }
  if (!resultRows.length && input.year) {
    return groundedEmpty(
      historicalAssignmentEmptyMessage(
        kind,
        targetMatches[0]
          ? placeLabel(targetMatches[0])
          : cleanEntity(input.entity),
        input.year,
        superiorOnly,
      ),
    );
  }
  if (kind === "community" && input.year && !superiorOnly) {
    const members = await memberLookup(client);
    const enriched = resultRows.map((row) => ({
      ...row,
      display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
        nameOf(row),
    }));
    const communityName = targetMatches[0]
      ? nameOf(targetMatches[0])
      : cleanEntity(input.entity);
    const focus = targetMatches[0]
      ? semanticEntity(
        "community",
        idOf(targetMatches[0]),
        placeLabel(targetMatches[0]),
      )
      : undefined;
    if (input.outputType === "count") {
      return countResponse(
        `In ${input.year}, ${communityName} had ${enriched.length} recorded member${
          enriched.length === 1 ? "" : "s"
        }.`,
        enriched.length,
        [],
        focus ? { focus } : undefined,
      );
    }
    return response(
      `In ${input.year}, ${communityName} had ${enriched.length} recorded member${
        enriched.length === 1 ? "" : "s"
      }: ${enriched.map(nameOf).join(", ")}.`,
      enriched,
      enriched.map((row) =>
        source("Community assignment", "community_assignment", idOf(row))
      ),
      memberEntities(enriched),
      {
        focus,
        entitySet: {
          type: "member",
          entities: enriched.map((row) =>
            semanticEntity("member", text(row, "member_id") ?? "", nameOf(row))
          ).filter((entity) => entity.id),
        },
      },
    );
  }
  const focus = targetMatches.length === 1
    ? semanticEntity(kind, idOf(targetMatches[0]), placeLabel(targetMatches[0]))
    : undefined;
  if (kind === "community" && input.outputType === "count" && !superiorOnly) {
    const communityName = targetMatches[0]
      ? placeLabel(targetMatches[0])
      : cleanEntity(input.entity);
    return countResponse(
      `${communityName} currently has ${resultRows.length} recorded member${
        resultRows.length === 1 ? "" : "s"
      }.`,
      resultRows.length,
      [],
      focus ? { focus } : undefined,
    );
  }
  if (kind === "ministry" && input.outputType === "count" && !leadershipOnly) {
    const members = await memberLookup(client);
    const names = resultRows.map((row) =>
      members.get(text(row, "member_id") ?? "")?.display_name ?? nameOf(row)
    );
    return countResponse(
      `${resultRows.length} current member${
        resultRows.length === 1 ? " is" : "s are"
      } assigned to ${targetName}${
        names.length ? `: ${names.join(", ")}` : ""
      }.`,
      resultRows.length,
      [],
      focus ? { focus } : undefined,
    );
  }
  return rowsWithMembers(
    client,
    resultRows,
    `${kind === "community" ? "Community" : "Ministry"} assignment records`,
    `${kind === "community" ? "Community" : "Ministry"} assignment`,
    false,
    focus ? { focus } : undefined,
  );
}

async function formationExperienceSearch(client: SupabaseClient) {
  const formationRoles = [
    "novice_master",
    "scholastic_master",
    "vocation_promoter",
    "formation_director",
  ];
  const [ministryResult, officeResult] = await Promise.all([
    client.from("member_ministry_assignments").select("*").in(
      "responsibility_code",
      formationRoles,
    ),
    client.from("member_office_appointments").select("*").in(
      "office_type_code",
      formationRoles,
    ),
  ]);
  if (ministryResult.error) throw ministryResult.error;
  if (officeResult.error) throw officeResult.error;
  const rows = [...(ministryResult.data ?? []), ...(officeResult.data ?? [])];
  return rowsWithMembers(
    client,
    rows,
    "Members with recorded formation experience",
    "Formation assignment",
    true,
  );
}

async function memberOriginSearch(
  client: SupabaseClient,
  entity?: string,
  originField?: Interpretation["originField"],
) {
  const needle = cleanEntity(entity).toLowerCase();
  if (!needle) {
    return noReliableAnswer(
      "Please include a home parish, diocese, district, state, or country.",
    );
  }
  const { data, error } = await client.from("member_native_details").select(
    "member_id,native_place,native_parish,native_diocese,district,state,country",
  );
  if (error) throw error;
  const members = await activeMemberLookup(client);
  const fields = originField
    ? [originField]
    : ["native_parish", "native_diocese", "district", "state", "country"];
  const rows = (data ?? []).filter((row) => {
    if (!members.has(text(row, "member_id") ?? "")) return false;
    return fields.some((field) =>
      (text(row, field) ?? "").toLowerCase().includes(needle)
    );
  }).map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name,
  }));
  if (!rows.length) return noReliableAnswer();
  const names = rows.map(nameOf);
  return response(
    `${rows.length} active member${
      rows.length === 1 ? " is" : "s are"
    } recorded as being from ${cleanEntity(entity)}: ${names.join(", ")}.`,
    rows,
    rows.map((row) =>
      source(
        "Member origin record / Home details",
        "member_origin",
        idOf(row),
        originDetail(row),
      )
    ),
    memberEntities(rows),
  );
}

async function currentLocationSearch(
  client: SupabaseClient,
  entity?: string,
  outside = false,
) {
  const needle = cleanEntity(entity).toLowerCase();
  if (!needle) {
    return noReliableAnswer("Please include a current service location.");
  }
  const today = new Date().toISOString().slice(0, 10);
  const [
    communitiesResult,
    ministriesResult,
    communityAssignments,
    ministryAssignments,
  ] = await Promise.all([
    client.from("communities").select("id,name,city,district,state,country"),
    client.from("ministries").select("id,name,city,district,state,country"),
    client.from("member_community_assignments").select("*").is("to_date", null)
      .lte("from_date", today),
    client.from("member_ministry_assignments").select("*").is("to_date", null)
      .lte("from_date", today),
  ]);
  for (
    const result of [
      communitiesResult,
      ministriesResult,
      communityAssignments,
      ministryAssignments,
    ]
  ) {
    if (result.error) throw result.error;
  }
  const locationMatches = (row: Row) =>
    outside
      ? (text(row, "country") ?? "").toLowerCase() !== needle
      : ["city", "district", "state", "country"].some((field) =>
        (text(row, field) ?? "").toLowerCase().includes(needle)
      );
  const communities = new Map(
    (communitiesResult.data ?? []).filter(locationMatches).map((
      row,
    ) => [idOf(row), row]),
  );
  const ministries = new Map(
    (ministriesResult.data ?? []).filter(locationMatches).map((
      row,
    ) => [idOf(row), row]),
  );
  const rows = [
    ...(communityAssignments.data ?? [])
      .filter((row) => communities.has(text(row, "community_id") ?? ""))
      .map((row) => ({
        ...row,
        location_kind: "Community",
        location_name: nameOf(
          communities.get(text(row, "community_id") ?? "") ?? {},
        ),
      })),
    ...(ministryAssignments.data ?? [])
      .filter((row) => ministries.has(text(row, "ministry_id") ?? ""))
      .map((row) => ({
        ...row,
        location_kind: "Ministry",
        location_name: nameOf(
          ministries.get(text(row, "ministry_id") ?? "") ?? {},
        ),
      })),
  ];
  if (!rows.length) return noReliableAnswer();
  const members = await activeMemberLookup(client);
  const enriched = rows.filter((row) =>
    members.has(text(row, "member_id") ?? "")
  )
    .map((row) => ({
      ...row,
      display_name: members.get(text(row, "member_id") ?? "")?.display_name,
    }));
  const names = [...new Set(enriched.map(nameOf))];
  return response(
    `${names.length} active member${
      names.length === 1 ? " is" : "s are"
    } currently serving ${outside ? "outside" : "in"} ${cleanEntity(entity)}: ${
      names.join(", ")
    }.`,
    enriched,
    enriched.map((row) =>
      source(
        `Current ${text(row, "location_kind") ?? "assignment"} location`,
        "current_assignment_location",
        idOf(row),
        text(row, "location_name"),
      )
    ),
    memberEntities(enriched),
  );
}

async function currentAssignment(client: SupabaseClient, entity?: string) {
  const input = { intent: "current_assignment" as Intent, entity };
  const community = await assignmentSearch(
    client,
    "community",
    input,
    false,
    false,
  );
  const ministry = await assignmentSearch(
    client,
    "ministry",
    input,
    false,
    false,
  );
  const rows = [...community.items, ...ministry.items].filter((row) =>
    !text(row, "to_date")
  );
  if (!rows.length) return noReliableAnswer();
  return response(
    `Found ${rows.length} current assignment record${
      rows.length === 1 ? "" : "s"
    }.`,
    rows,
    [...community.sources, ...ministry.sources],
    uniqueEntities([...community.entities, ...ministry.entities]),
  );
}

async function qualificationSearch(client: SupabaseClient, entity?: string) {
  let query = await client.from("v_member_qualifications_normalized").select(
    "*",
  );
  if (query.error) {
    query = await client.from("member_qualifications").select("*");
  }
  const { data, error } = query;
  if (error) throw error;
  const needle = cleanEntity(entity).toLowerCase();
  const rows = (data ?? []).filter((row) => {
    if (!needle) return true;
    if (needle === "outside_india") {
      const country = (text(row, "country", "country_name") ?? "")
        .toLowerCase();
      return country.length > 0 && country !== "india";
    }
    return qualificationMatches(row, needle);
  });
  if (!rows.length) {
    return groundedEmpty(
      `I found no matching qualification records for ${cleanEntity(entity)}.`,
    );
  }
  return rowsWithMembers(
    client,
    rows,
    `Members with recorded ${cleanEntity(entity)} qualifications`,
    "Qualification record",
    true,
  );
}

async function currentAssignmentForMember(client: SupabaseClient, member: Row) {
  const memberId = idOf(member);
  const today = new Date().toISOString().slice(0, 10);
  const [communityRows, ministryRows, communities, ministries] = await Promise
    .all([
      client.from("member_community_assignments").select("*").eq(
        "member_id",
        memberId,
      ).is("to_date", null).lte("from_date", today),
      client.from("member_ministry_assignments").select("*").eq(
        "member_id",
        memberId,
      ).is("to_date", null).lte("from_date", today),
      client.from("communities").select("id,name"),
      client.from("ministries").select("id,name"),
    ]);
  for (const query of [communityRows, ministryRows, communities, ministries]) {
    if (query.error) throw query.error;
  }
  const communityLookup = rowLookup(communities.data ?? []);
  const ministryLookup = rowLookup(ministries.data ?? []);
  const rows = [
    ...(communityRows.data ?? []).map((row) => ({
      ...row,
      assignment_kind: "Community",
      context: nameOf(
        communityLookup.get(text(row, "community_id") ?? "") ?? {},
      ),
    })),
    ...(ministryRows.data ?? []).map((row) => ({
      ...row,
      assignment_kind: "Ministry",
      context: nameOf(ministryLookup.get(text(row, "ministry_id") ?? "") ?? {}),
    })),
  ];
  if (!rows.length) return noReliableAnswer();
  return response(
    `${nameOf(member)} has ${rows.length} current assignment record${
      rows.length === 1 ? "" : "s"
    }.`,
    rows,
    rows.map((row) =>
      source(
        `${text(row, "assignment_kind")} Assignment`,
        `${
          (text(row, "assignment_kind") ?? "assignment").toLowerCase()
        }_assignment`,
        idOf(row),
        text(row, "context"),
      )
    ),
    [{ id: memberId, type: "member", label: nameOf(member) }],
  );
}

async function presentStateSearch(
  client: SupabaseClient,
  topic?: string,
  entity?: string,
) {
  if (topic === "active_members") {
    const { data, error, count } = await client.from("members").select(
      "id,display_name",
      { count: "exact" },
    ).eq("active", true);
    if (error) throw error;
    const total = count ?? data?.length ?? 0;
    return countResponse(
      `There are ${total} current members recorded in Communio.`,
      total,
      [aggregateSource(
        "Current membership",
        "member_count",
        total,
        "active member",
      )],
    );
  }
  if (topic === "active_communities" || topic === "active_ministries") {
    const table = topic === "active_communities" ? "communities" : "ministries";
    const { data, error, count } = await client.from(table).select("id,name", {
      count: "exact",
    }).eq("active", true);
    if (error) throw error;
    const total = count ?? data?.length ?? 0;
    const singular = table.slice(0, -1);
    return countResponse(
      `Communio currently records ${total} active ${table}.`,
      total,
      [aggregateSource(
        `Active ${table}`,
        `${singular}_count`,
        total,
        `active ${singular}`,
      )],
    );
  }
  if (topic === "priests" || topic === "brothers") {
    const { data, error } = await client.from("v_member_directory_safe").select(
      "member_id,ecclesiastical_title_code",
    );
    if (error) throw error;
    const category = topic === "priests" ? "priest" : "brother";
    const { count, covered } = countCanonicalMemberCategory(
      data ?? [],
      category,
    );
    const total = data?.length ?? 0;
    const coverage = covered < total
      ? ` Classification is available for ${covered} of ${total} current members.`
      : "";
    return countResponse(
      `Communio records ${count} current ${topic}.${coverage}`,
      count,
      [aggregateSource(
        `Current ${topic}`,
        `${category}_count`,
        count,
        `current ${category}`,
      )],
    );
  }
  if (["on_leave", "retired", "formation"].includes(topic ?? "")) {
    const status = topic === "on_leave" ? "on_leave" : topic;
    const { data, error } = await client.from("members").select(
      "id,religious_id,display_name,member_status_code",
    ).ilike("member_status_code", `%${status}%`);
    if (error) throw error;
    return rowsWithMembers(
      client,
      data ?? [],
      `Members currently ${label(status ?? "")}`,
      "Member Profile",
      true,
    );
  }
  if (topic === "community_superiors") {
    return assignmentSearch(
      client,
      "community",
      { intent: "community_superior_history", topic: "current" },
      true,
      false,
    );
  }
  if (topic === "principals") {
    return assignmentSearch(
      client,
      "ministry",
      {
        intent: "ministry_leadership_history",
        role: "principal",
        topic: "current",
      },
      false,
      true,
    );
  }
  if (topic === "named_office") return appointmentSearch(client, entity);
  return noReliableAnswer();
}

async function locationEntitySearch(
  client: SupabaseClient,
  topic?: string,
  entity?: string,
  direction?: string,
) {
  const table = topic === "ministries" ? "ministries" : "communities";
  const needle = cleanEntity(entity).toLowerCase();
  if (!needle) return noReliableAnswer("Please include a location.");
  const { data, error } = await client.from(table).select(
    "id,name,city,district,state,country",
  );
  if (error) throw error;
  const rows = (data ?? []).filter((row) =>
    direction === "outside"
      ? (text(row, "country") ?? "").toLowerCase() !== needle
      : ["city", "district", "state", "country"].some((field) =>
        (text(row, field) ?? "").toLowerCase().includes(needle)
      )
  );
  if (!rows.length) return noReliableAnswer();
  return response(
    `${rows.length} ${table} found ${
      direction === "outside" ? "outside" : "in"
    } ${cleanEntity(entity)}: ${rows.map(nameOf).join(", ")}.`,
    rows,
    rows.map((row) =>
      source(
        label(table.slice(0, -1)),
        table.slice(0, -1),
        idOf(row),
        [text(row, "city"), text(row, "state"), text(row, "country")].filter(
          Boolean,
        ).join(", "),
      )
    ),
    [],
  );
}

async function personSearch(client: SupabaseClient, entity?: string) {
  const needle = normalizeMemberName(cleanEntity(entity));
  if (!needle) return noReliableAnswer("Please include a member name.");
  const { data, error } = await client.from("v_demo_member_directory").select(
    "*",
  ).limit(200);
  if (error) throw error;
  const rows = (data ?? []).filter((row) =>
    normalizeMemberName(nameOf(row)).includes(needle)
  ).slice(0, 20);
  if (!rows.length) return noReliableAnswer();
  return response(
    `Found ${rows.length} matching member${rows.length === 1 ? "" : "s"}: ${
      rows.map(nameOf).join(", ")
    }.`,
    rows,
    rows.map((row) => source("Religious record", "member", idOf(row))),
    memberEntities(rows),
  );
}

async function memberLanguages(
  client: SupabaseClient,
  input: Interpretation,
) {
  const resolved = await resolveMember(client, input.entity, input.entityId);
  if ("result" in resolved) return resolved.result;
  const member = resolved.member;
  let query = client.from("v_member_languages").select(
    "member_id,religious_id,display_name,language_name,language_code,proficiency_level_code,can_speak,can_read,can_write,is_primary,is_native",
  ).eq("member_id", idOf(member));
  if (input.topic === "spoken") query = query.eq("can_speak", true);
  const { data, error } = await query.order("is_primary", {
    ascending: false,
  }).order("language_name");
  if (error) throw error;
  const rows = data ?? [];
  if (!rows.length) {
    return groundedEmpty(
      `I found no recorded language information for ${nameOf(member)}.`,
    );
  }
  const detail = (row: Row) =>
    [
      text(row, "proficiency_level_code")
        ? label(text(row, "proficiency_level_code")!)
        : undefined,
      row.can_speak === true ? "Speak" : undefined,
      row.can_read === true ? "Read" : undefined,
      row.can_write === true ? "Write" : undefined,
    ].filter(Boolean).join(", ");
  return response(
    `${nameOf(member)} has ${rows.length} recorded language${
      rows.length === 1 ? "" : "s"
    }:\n• ${
      rows.map((row) =>
        `${text(row, "language_name")}${detail(row) ? ` — ${detail(row)}` : ""}`
      ).join("\n• ")
    }`,
    rows,
    rows.map((row) =>
      source(
        "Member language",
        "member_language",
        idOf(member),
        text(row, "language_name"),
      )
    ),
    [{ id: idOf(member), type: "member", label: nameOf(member) }],
  );
}

async function resolveMember(
  client: SupabaseClient,
  entity?: string,
  entityId?: string,
): Promise<{ member: Row } | { result: ReturnType<typeof response> }> {
  const needle = normalizeMemberName(cleanEntity(entity));
  if (!needle) {
    return { result: noReliableAnswer("Please include a member name.") };
  }
  const { data, error } = await client.from("members").select(
    "id,religious_id,display_name,ecclesiastical_title_code,member_status_code",
  );
  if (error) throw error;
  if (entityId) {
    const authorized = (data ?? []).find((row) => idOf(row) === entityId);
    if (!authorized) {
      return {
        result: noReliableAnswer(
          "That member is no longer available with your current access.",
        ),
      };
    }
    if (needle && !normalizeMemberName(nameOf(authorized)).includes(needle)) {
      return {
        result: noReliableAnswer(
          "The previous member context no longer matches the authorized record.",
        ),
      };
    }
    return { member: authorized };
  }
  const matches = (data ?? []).filter((row) =>
    normalizeMemberName(nameOf(row)).includes(needle)
  );
  if (!matches.length) return { result: noReliableAnswer() };
  const exact = matches.filter((row) =>
    normalizeMemberName(nameOf(row)) === needle
  );
  if (exact.length === 1) return { member: exact[0] };
  if (matches.length === 1) return { member: matches[0] };
  const candidates = exact.length > 1 ? exact : matches.slice(0, 10);
  return {
    result: response(
      `I found multiple matching members. Please select the intended person: ${
        candidates.map((row) =>
          `${nameOf(row)} (${
            text(row, "religious_id") ?? "Religious ID not recorded"
          })`
        ).join(", ")
      }.`,
      candidates,
      candidates.map((row) =>
        source("Member Profile", "member", idOf(row), text(row, "religious_id"))
      ),
      candidates.map((row) => ({
        id: idOf(row),
        type: "member",
        label: nameOf(row),
      })),
    ),
  };
}

function rowsWithResolvedMember(
  rows: Row[],
  member: Row,
  heading: string,
  sourceLabel: string,
) {
  if (!rows.length) return noReliableAnswer();
  const enriched = rows.map((row) => ({
    ...row,
    display_name: nameOf(member),
  }));
  return response(
    `${heading} for ${nameOf(member)}: ${rows.length} record${
      rows.length === 1 ? "" : "s"
    }.`,
    enriched,
    rows.map((row) =>
      source(
        sourceLabel,
        sourceLabel.toLowerCase().replaceAll(" ", "_"),
        idOf(row),
      )
    ),
    [{ id: idOf(member), type: "member", label: nameOf(member) }],
  );
}

async function rowsWithMembers(
  client: SupabaseClient,
  rows: Row[],
  heading: string,
  sourceLabel: string,
  uniquePeople = false,
  semanticContext?: SemanticContext,
) {
  if (!rows.length) return noReliableAnswer();
  const members = await memberLookup(client);
  const enriched = rows.map((row) => ({
    ...row,
    display_name: members.get(text(row, "member_id") ?? "")?.display_name ??
      nameOf(row),
  }));
  const names = enriched.map(nameOf);
  const answerNames = uniquePeople ? [...new Set(names)] : names;
  const semanticMembers = enriched.map((row) =>
    semanticEntity("member", text(row, "member_id") ?? "", nameOf(row))
  ).filter((entity) => entity.id);
  return response(
    `${heading}: ${answerNames.join(", ")}.`,
    enriched,
    enriched.map((row) =>
      source(
        sourceLabel,
        sourceLabel.toLowerCase().replaceAll(" ", "_"),
        idOf(row),
      )
    ),
    memberEntities(enriched),
    semanticContext
      ? {
        ...semanticContext,
        lastAnswer: semanticMembers.length === 1
          ? semanticMembers[0]
          : undefined,
        entitySet: semanticMembers.length
          ? { type: "member", entities: semanticMembers }
          : undefined,
      }
      : undefined,
  );
}

async function memberLookup(client: SupabaseClient) {
  const { data, error } = await client.from("members").select(
    "id,display_name",
  );
  if (error) throw error;
  return new Map((data ?? []).map((row) => [idOf(row), row]));
}

async function activeMemberLookup(client: SupabaseClient) {
  const { data, error } = await client.from("members").select("id,display_name")
    .eq("active", true);
  if (error) throw error;
  return new Map((data ?? []).map((row) => [idOf(row), row]));
}

function response(
  answer: string,
  items: Row[],
  sources: Row[],
  entities: Row[],
  semanticContext?: SemanticContext,
) {
  return {
    answer,
    answer_type: items.length > 1 ? "list" : "record",
    reliability: "grounded",
    items: items.slice(0, 200),
    sources: sources.slice(0, 50),
    entities: uniqueEntities(entities).slice(0, 200),
    semantic_context: semanticContext,
  };
}

function countResponse(
  answer: string,
  count: number,
  sources: Row[] = [],
  semanticContext?: SemanticContext,
) {
  return {
    answer,
    answer_type: "count",
    reliability: "grounded",
    items: [{ count }],
    sources: sources.slice(0, 50),
    entities: [],
    semantic_context: semanticContext,
  };
}

function aggregateSource(
  label: string,
  sourceType: string,
  count: number,
  recordLabel: string,
): Row {
  return source(
    label,
    sourceType,
    undefined,
    `${count} ${recordLabel} record${count === 1 ? "" : "s"}`,
  );
}

function noReliableAnswer(warning?: string) {
  return {
    answer: warning ?? "I couldn't find a matching Communio record.",
    answer_type: "empty",
    reliability: "insufficient_evidence",
    items: [],
    sources: [],
    entities: [],
    semantic_context: undefined as SemanticContext | undefined,
  };
}

function clarificationResponse(answer: string, items: Row[]) {
  return {
    answer,
    answer_type: "clarification",
    reliability: "ambiguous",
    items,
    sources: [],
    entities: [],
    semantic_context: undefined as SemanticContext | undefined,
  };
}

function groundedEmpty(answer: string) {
  return {
    answer,
    answer_type: "empty",
    reliability: "grounded",
    items: [],
    sources: [],
    entities: [],
    semantic_context: undefined as SemanticContext | undefined,
  };
}

function ageOnDate(dateOfBirth: string, reference: Date): number {
  const [year, month, day] = dateOfBirth.slice(0, 10).split("-").map(Number);
  let age = reference.getUTCFullYear() - year;
  if (
    reference.getUTCMonth() + 1 < month ||
    (reference.getUTCMonth() + 1 === month && reference.getUTCDate() < day)
  ) age--;
  return age;
}

function normalizePlaceName(
  value: string,
  kind: "community" | "ministry",
): string {
  const normalized = normalizeFact(value).replace(/\bkolkota\b/g, "kolkata");
  return kind === "community"
    ? normalized.replace(/\bcommunity\b/g, "").replace(/\s+/g, " ").trim()
    : normalized;
}

function placeLabel(row: Row): string {
  return [
    nameOf(row),
    text(row, "city"),
    text(row, "district"),
    text(row, "state"),
  ].filter(Boolean).filter((value, index, values) =>
    values.indexOf(value) === index
  ).join(", ");
}

function source(
  label: string,
  sourceType: string,
  recordId?: string,
  detail?: string,
): Row {
  return {
    label,
    source_type: sourceType,
    record_id: recordId || undefined,
    detail,
  };
}

function memberEntities(rows: Row[]): Row[] {
  return rows.map((row) => ({
    id: text(row, "member_id", "id") ?? "",
    type: "member",
    label: nameOf(row),
  })).filter((row) => row.id);
}

function uniqueEntities(rows: Row[]): Row[] {
  const seen = new Set<string>();
  return rows.filter((row) => {
    const key = `${row.type}:${row.id}`;
    return row.id && !seen.has(key) && seen.add(key);
  });
}

function nameOf(row: Row): string {
  return text(
    row,
    "display_name",
    "member_name",
    "name",
    "community_name",
    "ministry_name",
  ) ?? "Communio record";
}

function idOf(row: Row): string {
  return text(row, "member_id", "id", "appointment_id") ?? "";
}

function text(row: Row, ...keys: string[]): string | undefined {
  for (const key of keys) {
    const value = row[key];
    if (value != null && String(value).trim()) return String(value).trim();
  }
  return undefined;
}

function dateDetail(row: Row, field: string): string | undefined {
  const value = text(row, field);
  return value ? `${field.replaceAll("_", " ")}: ${value}` : undefined;
}

function activeInYear(row: Row, year: number): boolean {
  const from = Number(
    (text(row, "from_date", "start_date") ?? "0001").slice(0, 4),
  );
  const toValue = text(row, "to_date", "end_date");
  const to = toValue ? Number(toValue.slice(0, 4)) : 9999;
  return from <= year && to >= year;
}

function activeOnDate(row: Row, date: Date): boolean {
  const day = date.toISOString().slice(0, 10);
  const from = text(row, "from_date", "start_date") ?? "0001-01-01";
  const to = text(row, "to_date", "end_date") ?? "9999-12-31";
  return from <= day && to >= day;
}

function dateRange(row: Row): string {
  const from = text(row, "from_date", "start_date") ??
    "start date not recorded";
  const to = text(row, "to_date", "end_date") ?? "present";
  return `${from} to ${to}`;
}

function naturalDateRange(row: Row): string {
  const from = text(row, "from_date", "start_date");
  const to = text(row, "to_date", "end_date");
  return `${from ? formatDate(from) : "start date not recorded"} – ${
    to ? formatDate(to) : "present"
  }`;
}

function formatDate(value: string): string {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  return new Intl.DateTimeFormat("en", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(year, month - 1, day)));
}

function normalizeMemberName(value: string): string {
  return value
    .toLowerCase()
    .replace(/\b(?:father|fr|brother|bro|deacon|dcn)\.?\s+/g, "")
    .replace(/,?\s+(?:msa)\b/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

function rowLookup(rows: Row[]): Map<string, Row> {
  return new Map(rows.map((row) => [idOf(row), row]));
}

function officeContext(
  row: Row,
  ministries: Map<string, Row>,
  communities: Map<string, Row>,
  provinces: Map<string, Row>,
  congregations: Map<string, Row>,
): { id: string; type: string; name: string } | undefined {
  const candidates: Array<[string, string | undefined, Map<string, Row>]> = [
    ["ministry", text(row, "ministry_id"), ministries],
    ["community", text(row, "community_id"), communities],
    ["province", text(row, "province_id"), provinces],
    ["congregation", text(row, "congregation_id"), congregations],
  ];
  for (const [type, id, lookup] of candidates) {
    if (!id || !lookup.has(id)) continue;
    return { id, type, name: nameOf(lookup.get(id) ?? {}) };
  }
  return undefined;
}

function isRecognizedLeave(row: Row): boolean {
  return new Set([
    "sabbatical",
    "study_leave",
    "home_leave",
    "medical_leave",
    "ministry_break",
    "leave",
    "leave_from_active_ministry",
    "temporary_absence",
    "study",
    "medical",
    "absence",
  ]).has((text(row, "event_type", "event_type_code") ?? "").toLowerCase());
}

function historyTopicMatches(row: Row, topic?: string): boolean {
  if (!topic) return true;
  const category = text(row, "event_category");
  const title = (text(row, "event_title") ?? "").toLowerCase().replaceAll(
    " ",
    "_",
  );
  if (topic === "ordination") {
    return category === "vocation" && title.includes("ordination");
  }
  if (topic === "first_profession") {
    return category === "vocation" && title.includes("first_profession");
  }
  if (topic === "final_profession") {
    return category === "vocation" &&
      (title.includes("final_profession") ||
        title.includes("perpetual_profession"));
  }
  if (topic === "principal") return title.includes("principal");
  return category === topic;
}

function historyDetail(row: Row): string | undefined {
  return [
    text(row, "event_title"),
    text(row, "context"),
    text(row, "start_date"),
    text(row, "end_date"),
    text(row, "location"),
  ].filter(Boolean).join(" · ") || undefined;
}

function originDetail(row: Row): string | undefined {
  const details = [
    ["Home Parish", text(row, "native_parish")],
    ["Diocese", text(row, "native_diocese")],
    ["District", text(row, "district")],
    ["State", text(row, "state")],
    ["Country", text(row, "country")],
  ].filter((entry) => entry[1]).map((entry) => `${entry[0]}: ${entry[1]}`);
  return details.length ? details.join(" · ") : undefined;
}

function cleanEntity(value?: string): string {
  return (value ?? "").replace(/[?.!]+$/, "").replace(/^(the|a|an)\s+/i, "")
    .trim();
}

function normalizeFact(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function label(value: string): string {
  return value.split("_").filter(Boolean).map((part) =>
    part[0].toUpperCase() + part.slice(1)
  ).join(" ");
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function safeContext(value: unknown): AskCommunioContext | undefined {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return undefined;
  }
  const input = value as Row;
  const allowedTypes = new Set([
    "member",
    "community",
    "ministry",
    "governance_body",
    "office_role",
  ]);
  const primaryType = text(input, "primary_entity_type");
  const secondaryType = text(input, "secondary_entity_type");
  const ambiguousType = text(input, "ambiguous_entity_type");
  const focusType = text(input, "focus_entity_type");
  const lastAnswerType = text(input, "last_answer_entity_type");
  const entitySetType = text(input, "entity_set_type");
  return {
    last_intent: text(input, "last_intent"),
    primary_entity_type: primaryType && allowedTypes.has(primaryType)
      ? primaryType
      : undefined,
    primary_entity_id: text(input, "primary_entity_id"),
    primary_entity_name: text(input, "primary_entity_name"),
    secondary_entity_type: secondaryType && allowedTypes.has(secondaryType)
      ? secondaryType
      : undefined,
    secondary_entity_id: text(input, "secondary_entity_id"),
    secondary_entity_name: text(input, "secondary_entity_name"),
    last_year: numeric(input.last_year),
    last_result_count: numeric(input.last_result_count),
    ambiguous_entity_type: ambiguousType && allowedTypes.has(ambiguousType)
      ? ambiguousType
      : undefined,
    focus_entity_type: focusType && allowedTypes.has(focusType)
      ? focusType
      : undefined,
    focus_entity_id: text(input, "focus_entity_id"),
    focus_entity_name: text(input, "focus_entity_name"),
    last_answer_entity_type: lastAnswerType && allowedTypes.has(lastAnswerType)
      ? lastAnswerType
      : undefined,
    last_answer_entity_id: text(input, "last_answer_entity_id"),
    last_answer_entity_name: text(input, "last_answer_entity_name"),
    entity_set_type: entitySetType && allowedTypes.has(entitySetType)
      ? entitySetType
      : undefined,
    entity_set_size: numeric(input.entity_set_size),
  };
}

function responseContext(
  input: Interpretation,
  result: { items: Row[]; entities: Row[] },
  semantic?: SemanticContext,
): AskCommunioContext {
  const context: AskCommunioContext = {
    last_intent: input.intent,
    last_year: input.year,
    last_result_count: numeric(result.items[0]?.count) ?? result.items.length,
  };
  if (semantic) {
    return applySemanticContext(context, semantic);
  }
  const memberEntities = uniqueEntities(
    result.entities.filter((row) => row.type === "member"),
  );
  const communityItems = input.intent === "community_size_ranking"
    ? result.items.filter((row) =>
      idOf(row) && nameOf(row) !== "Communio record"
    )
    : [];

  if (
    [
      "member_history",
      "member_appointment_history",
      "member_current_location",
      "member_historical_location",
    ].includes(input.intent) && input.entity
  ) {
    context.primary_entity_type = "member";
    context.primary_entity_id = input.entityId ??
      text(memberEntities[0] ?? {}, "id");
    context.primary_entity_name = text(memberEntities[0] ?? {}, "label") ??
      input.entity;
  } else if (
    ["community_membership_history", "community_superior_history"].includes(
      input.intent,
    ) && input.entity
  ) {
    context.primary_entity_type = "community";
    context.primary_entity_id = input.entityId ??
      text(result.items[0] ?? {}, "community_id");
    context.primary_entity_name = input.entity;
  } else if (communityItems.length === 1) {
    context.primary_entity_type = "community";
    context.primary_entity_id = idOf(communityItems[0]);
    context.primary_entity_name = placeLabel(communityItems[0]);
  } else if (communityItems.length > 1) {
    context.ambiguous_entity_type = "community";
    context.last_result_count = communityItems.length;
  } else if (memberEntities.length === 1) {
    context.primary_entity_type = "member";
    context.primary_entity_id = text(memberEntities[0], "id");
    context.primary_entity_name = text(memberEntities[0], "label");
  } else if (memberEntities.length > 1) {
    context.ambiguous_entity_type = "member";
    context.last_result_count = memberEntities.length;
  }

  if (
    ["member_current_location", "member_historical_location"].includes(
      input.intent,
    )
  ) {
    const community = result.items.find((row) =>
      text(row, "assignment_kind") === "Community"
    );
    if (community) {
      context.secondary_entity_type = "community";
      context.secondary_entity_id = text(community, "community_id");
      context.secondary_entity_name = text(community, "assignment_name");
    }
  }
  return context;
}

function numeric(value: unknown): number | undefined {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function semanticEntity(
  type: string,
  id: string,
  name: string,
): SemanticEntity {
  return { type, id, name };
}
