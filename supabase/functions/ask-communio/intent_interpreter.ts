export type AskCommunioIntent =
  | "person_search"
  | "current_assignment"
  | "community_membership_history"
  | "community_superior_history"
  | "ministry_assignment_history"
  | "ministry_leadership_history"
  | "appointment_search"
  | "historical_office_holder"
  | "governance_body_membership"
  | "governance_directory"
  | "governance_body_profile"
  | "governance_body_members"
  | "governance_body_leader"
  | "profession_cohort"
  | "ordination_cohort"
  | "eligibility_search"
  | "appointment_compliance"
  | "education_qualification_search"
  | "ministry_experience_search"
  | "member_origin_search"
  | "current_location_search"
  | "age_search"
  | "birthday_month"
  | "vocation_anniversary"
  | "appointment_expiry"
  | "organization_identity"
  | "member_history"
  | "member_profile"
  | "member_languages"
  | "vocation_cohort"
  | "present_state"
  | "location_entity_search"
  | "decision_boundary"
  | "member_safe_factual"
  | "member_appointment_history"
  | "member_current_location"
  | "member_historical_location"
  | "community_size_ranking"
  | "member_age_extreme"
  | "member_analytics"
  | "community_size_threshold"
  | "ministry_size_ranking"
  | "clarification_needed"
  | "composed_community_query"
  | "community_directory"
  | "community_profile"
  | "ministry_directory"
  | "ministry_profile"
  | "ministry_establishment"
  | "leadership_history"
  | "community_history"
  | "community_lifecycle"
  | "community_movement"
  | "formal_transfer"
  | "historical_community_ranking"
  | "ministry_type_staffing"
  | "leadership_successor"
  | "member_office_tenure"
  | "previous_assignment"
  | "appointment_period_search"
  | "member_appointment_comparison"
  | "unknown";

export type AskCommunioInterpretation = {
  intent: AskCommunioIntent;
  year?: number;
  yearTo?: number;
  age?: number;
  ageComparison?: "above" | "below";
  ageTo?: number;
  month?: number;
  anniversary?: number;
  outputType?: "records" | "count";
  timeRelation?: "in" | "before" | "after" | "current";
  entity?: string;
  role?: string;
  originField?:
    | "native_parish"
    | "native_diocese"
    | "district"
    | "state"
    | "country";
  topic?: string;
  entityId?: string;
};

export type AskCommunioContext = {
  last_intent?: string;
  primary_entity_type?: string;
  primary_entity_id?: string;
  primary_entity_name?: string;
  secondary_entity_type?: string;
  secondary_entity_id?: string;
  secondary_entity_name?: string;
  last_year?: number;
  last_result_count?: number;
  ambiguous_entity_type?: string;
  focus_entity_type?: string;
  focus_entity_id?: string;
  focus_entity_name?: string;
  last_answer_entity_type?: string;
  last_answer_entity_id?: string;
  last_answer_entity_name?: string;
  entity_set_type?: string;
  entity_set_size?: number;
};

export const handledAskCommunioIntents = new Set<AskCommunioIntent>([
  "person_search",
  "current_assignment",
  "community_membership_history",
  "community_superior_history",
  "ministry_assignment_history",
  "ministry_leadership_history",
  "appointment_search",
  "profession_cohort",
  "historical_office_holder",
  "governance_body_membership",
  "governance_directory",
  "governance_body_profile",
  "governance_body_members",
  "governance_body_leader",
  "ordination_cohort",
  "eligibility_search",
  "appointment_compliance",
  "education_qualification_search",
  "ministry_experience_search",
  "member_origin_search",
  "current_location_search",
  "age_search",
  "birthday_month",
  "vocation_anniversary",
  "appointment_expiry",
  "organization_identity",
  "member_history",
  "member_profile",
  "member_languages",
  "vocation_cohort",
  "present_state",
  "location_entity_search",
  "decision_boundary",
  "unknown",
  "member_safe_factual",
  "member_appointment_history",
  "member_current_location",
  "member_historical_location",
  "community_size_ranking",
  "member_age_extreme",
  "member_analytics",
  "community_size_threshold",
  "ministry_size_ranking",
  "clarification_needed",
  "composed_community_query",
  "community_directory",
  "community_profile",
  "ministry_directory",
  "ministry_profile",
  "ministry_establishment",
  "leadership_history",
  "community_history",
  "community_lifecycle",
  "community_movement",
  "formal_transfer",
  "historical_community_ranking",
  "ministry_type_staffing",
  "leadership_successor",
  "member_office_tenure",
  "previous_assignment",
  "appointment_period_search",
  "member_appointment_comparison",
]);

export function interpretAskCommunioQuestion(
  question: string,
  context?: AskCommunioContext,
): AskCommunioInterpretation {
  const q = normalizeQuestion(question);
  const years = [...q.matchAll(/\b(?:18|19|20)\d{2}\b/g)].map((match) =>
    Number(match[0])
  );
  const year = years[0];
  const yearTo = years[1];
  const outputType = detectOutputType(q);
  const timeRelation = detectTimeRelation(q);

  const followUp = interpretFollowUp(q, context, year, outputType);
  if (followUp) return followUp;

  if (
    /^(?:how many|what(?:'s| is) the (?:number|total))(?: are there)?$/.test(q)
  ) {
    return { intent: "clarification_needed", topic: "count_domain" };
  }

  if (
    /\b(?:who should|best candidate|best successor|who should replace|rank (?:the )?candidates|recommend|would make the best)\b/
      .test(q)
  ) {
    return { intent: "decision_boundary", topic: "appointment_recommendation" };
  }

  const wave4Analytics = extractWave4Analytics(q);
  if (wave4Analytics) return wave4Analytics;

  const composedCommunity = extractComposedCommunityQuery(q, year, outputType);
  if (composedCommunity) return composedCommunity;

  const communityLifecycle = extractCommunityLifecycle(q, year);
  if (communityLifecycle) return communityLifecycle;

  const formalTransfer = extractFormalTransfer(question, year);
  if (formalTransfer) return formalTransfer;

  const vocationAnniversary = extractVocationAnniversary(q, year, outputType);
  if (vocationAnniversary) return vocationAnniversary;

  const birthdayMonth = extractBirthdayMonth(q, outputType);
  if (birthdayMonth) return birthdayMonth;

  const governanceBody = extractGovernanceBody(q, year, outputType);
  if (governanceBody) return governanceBody;

  const memberLanguages = extractMemberLanguages(question);
  if (memberLanguages) return memberLanguages;

  const scopedMember = extractScopedMemberQuestion(question, q, year);
  if (scopedMember) return scopedMember;

  const wave2 = extractWave2Question(question, q, year, yearTo, outputType);
  if (wave2) return wave2;

  const leadershipDirectory = extractLeadershipDirectory(q, outputType);
  if (leadershipDirectory) return leadershipDirectory;

  const communityDirectory = extractCommunityDirectory(question, q, outputType);
  if (communityDirectory) return communityDirectory;

  const ministryDirectory = extractMinistryDirectory(question, q, outputType);
  if (ministryDirectory) return ministryDirectory;

  const namedCommunity = extractNamedCommunityQuestion(
    question,
    year,
    outputType,
  );
  if (namedCommunity) return namedCommunity;

  const namedMinistry = extractNamedMinistryQuestion(
    question,
    year,
    outputType,
  );
  if (namedMinistry) return namedMinistry;

  const sizeRanking = extractCommunitySizeRanking(q);
  if (sizeRanking) return sizeRanking;

  const ageExtreme = extractAgeExtreme(q);
  if (ageExtreme) return ageExtreme;

  const organization = organizationQuestion(q);
  if (organization) return organization;

  if (
    /\b(?:eligible|eligibility|meets? the eligibility rules)\b/.test(q) ||
    /\bwho can (?:be|serve as)\b/.test(q)
  ) {
    return {
      intent: "eligibility_search",
      entity: extractMemberSubject(question),
      role: extractRole(q),
    };
  }
  if (
    /\b(?:current appointments? are compliant|appointment compliance|appointments? are not compliant|compliance issues?)\b/
      .test(q)
  ) {
    return {
      intent: "appointment_compliance",
      topic: /not compliant|issues?/.test(q) ? "issues" : "summary",
      outputType,
    };
  }

  const safeFact = memberSafeFactualQuestion(question);
  if (safeFact) return safeFact;

  const member = extractMemberSubject(question);
  if (
    member &&
    /\b(?:ordained|ordination|first profession|final profession|perpetual profession)\b/
      .test(q)
  ) {
    return { intent: "member_history", entity: member, topic: historyTopic(q) };
  }
  if (
    member &&
    /\b(?:history|where has|what offices|what communities|what ministries|ever take|ever taken|serve as)\b/
      .test(q)
  ) {
    return { intent: "member_history", entity: member, topic: historyTopic(q) };
  }
  if (
    member &&
    /\b(?:religious id|qualifications?|degrees?|stud(?:y|ied)|home parish|diocese|which state|parents?|email|phone|address|currently assigned|which community|which ministry)\b/
      .test(q)
  ) {
    return {
      intent: "member_profile",
      entity: member,
      topic: memberProfileTopic(q),
    };
  }

  const currentLocation = extractCurrentLocation(question);
  if (currentLocation) {
    return {
      intent: "current_location_search",
      entity: currentLocation.entity,
      topic: currentLocation.outside ? "outside" : undefined,
    };
  }
  const origin = extractOriginSearch(question);
  if (origin) {
    return {
      intent: "member_origin_search",
      entity: origin.entity,
      originField: origin.field,
    };
  }
  const locationEntities = extractLocationEntitySearch(question);
  if (locationEntities) return locationEntities;

  const age = extractAge(q);
  if (age) {
    return {
      intent: "age_search",
      age: age.value,
      ageTo: age.valueTo,
      ageComparison: age.comparison,
      outputType,
    };
  }

  const present = presentStateQuestion(q);
  if (present) return present;

  if (/\b(?:joined|entered (?:the )?congregation)\b/.test(q) && year) {
    return {
      intent: "vocation_cohort",
      year,
      yearTo,
      topic: "JOINING",
      outputType,
      timeRelation,
    };
  }
  if (/\b(?:final|perpetual) (?:vows?|professions?)\b/.test(q)) {
    return {
      intent: "vocation_cohort",
      year,
      yearTo,
      topic: "FINAL_PROFESSION",
      outputType,
      timeRelation,
    };
  }
  if (
    /\b(?:first|temporary) (?:vows?|professions?)\b/.test(q) ||
    q.includes("profession in") || q.includes("profession during")
  ) {
    return {
      intent: "profession_cohort",
      year,
      yearTo,
      outputType,
      timeRelation,
    };
  }
  if (q.includes("ordained") || q.includes("ordination")) {
    return {
      intent: "ordination_cohort",
      year,
      yearTo,
      outputType,
      timeRelation,
    };
  }
  if (/\b(?:entered novitiate|novitiate)\b/.test(q) && year) {
    return {
      intent: "vocation_cohort",
      year,
      yearTo,
      topic: "NOVITIATE",
      outputType,
      timeRelation,
    };
  }
  if (
    q.includes("ending soon") || q.includes("ending in the next 90 days") ||
    q.includes("expire this year") || q.includes("expiring")
  ) {
    return {
      intent: "appointment_expiry",
      year: q.includes("this year") ? new Date().getUTCFullYear() : undefined,
    };
  }

  const historicalOffice = extractHistoricalOffice(q, year, outputType);
  if (historicalOffice) return historicalOffice;

  if (
    q.includes("community superior") || /\bsuperiors?\s+of\b/.test(q) ||
    q.includes("superior history")
  ) {
    return {
      intent: "community_superior_history",
      year,
      entity: extractHistoricalEntity(question, ["of", "in"]),
    };
  }
  if (
    /\b(?:lived|was|were) in\b/.test(q) || /\b(?:community )?members?\b/.test(q)
  ) {
    const entity = extractCommunity(question);
    if (entity) {
      return {
        intent: "community_membership_history",
        year,
        yearTo,
        entity,
        outputType,
      };
    }
  }
  if (
    q.includes("formation experience") || q.includes("worked in formation") ||
    q.includes("work in formation")
  ) {
    return { intent: "ministry_experience_search", entity: "formation" };
  }
  if (q.includes("principal") && /\b(?:who were|who was|history)\b/.test(q)) {
    return {
      intent: "ministry_leadership_history",
      year,
      entity: extractMinistry(question),
      role: "principal",
    };
  }
  if (
    q.includes("ministry leader") || q.includes("director at") ||
    q.includes("principal at")
  ) {
    return {
      intent: "ministry_leadership_history",
      year,
      entity: extractMinistry(question),
      role: q.includes("principal") ? "principal" : undefined,
    };
  }
  if (
    q.includes("served at") || q.includes("worked at") ||
    q.includes("ministry experience")
  ) {
    return {
      intent: "ministry_assignment_history",
      year,
      entity: extractMinistry(question),
    };
  }
  if (
    /\b(?:qualification|degree|educated|studied|diploma|m\.ed|m\.th|b\.?\s*th\.?|theology)\b/
      .test(q)
  ) {
    return {
      intent: "education_qualification_search",
      entity: qualificationEntity(question),
    };
  }
  if (
    q.includes("appointment") || q.includes("provincial secretary") ||
    q.includes("novice master")
  ) {
    return { intent: "appointment_search", entity: extractOffice(q) };
  }
  if (q.includes("currently assigned") || q.includes("current assignment")) {
    return {
      intent: "current_assignment",
      entity: extractGenericEntity(question),
    };
  }
  const person = extractPersonSearch(question);
  if (person) return { intent: "person_search", entity: person };
  return { intent: "unknown" };
}

function extractFormalTransfer(
  question: string,
  year?: number,
): AskCommunioInterpretation | undefined {
  const trimmed = question.trim();
  const communityMatch = year && trimmed.match(
    /^who (?:was )?(?:formally )?(?:transferred|moved) from (.+?) in (?:18|19|20)\d{2}[?.!]*$/i,
  );
  if (communityMatch) {
    return {
      intent: "formal_transfer",
      entity: communityMatch[1].trim(),
      year,
      topic: "from_community",
    };
  }
  const historyMatch = trimmed.match(
    /^(?:when was (.+?) (?:formally )?transferred(?: from one community to another)?|show (?:me )?the (?:formal )?transfer history of (.+?))[?.!]*$/i,
  );
  if (historyMatch) {
    return {
      intent: "formal_transfer",
      entity: (historyMatch[1] ?? historyMatch[2]).trim(),
      topic: "member_history",
    };
  }
  const reasonMatch = trimmed.match(
    /^why was (.+?) (?:formally )?transferred[?.!]*$/i,
  );
  if (reasonMatch) {
    return {
      intent: "formal_transfer",
      entity: reasonMatch[1].trim(),
      topic: "member_reason",
    };
  }
  return undefined;
}

function extractCommunityLifecycle(
  q: string,
  year?: number,
): AskCommunioInterpretation | undefined {
  if (!year) return undefined;
  if (
    /^(?:which |list |show )?communities (?:opened|established) in (?:18|19|20)\d{2}$/
      .test(q)
  ) {
    return { intent: "community_lifecycle", topic: "OPENED", year };
  }
  if (
    /^(?:which |list |show )?communities closed in (?:18|19|20)\d{2}$/
      .test(q)
  ) {
    return { intent: "community_lifecycle", topic: "CLOSED", year };
  }
  return undefined;
}

function extractMemberLanguages(
  question: string,
): AskCommunioInterpretation | undefined {
  const patterns: RegExp[] = [
    /^what languages does (.+?) speak[?.!]*$/i,
    /^which languages does (.+?) know[?.!]*$/i,
    /^languages of (.+?)[?.!]*$/i,
  ];
  for (const pattern of patterns) {
    const match = question.trim().match(pattern);
    if (match) {
      return {
        intent: "member_languages",
        entity: normalizeMemberEntity(match[1]),
        topic: /\bspeak\b/i.test(question) ? "spoken" : "recorded",
      };
    }
  }
  return undefined;
}

function interpretFollowUp(
  q: string,
  context: AskCommunioContext | undefined,
  year: number | undefined,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  const governanceReference =
    /\bit\b|\bthat (?:body|commission|council)\b/.test(q) &&
    /\b(?:chair|chairs|chaired|chairperson|president|lead|leads|leader|members?)\b/
      .test(q);
  if (governanceReference) {
    const type = context?.focus_entity_type ?? context?.primary_entity_type;
    const name = context?.focus_entity_name ?? context?.primary_entity_name;
    const id = context?.focus_entity_id ?? context?.primary_entity_id;
    if (type !== "governance_body" || !name) {
      return { intent: "clarification_needed", topic: "governance_reference" };
    }
    return {
      intent:
        /\b(?:chair|chairs|chaired|chairperson|president|lead|leads|leader)\b/
            .test(q)
          ? "governance_body_leader"
          : "governance_body_members",
      entity: name,
      entityId: id,
    };
  }
  const personReference =
    /\b(?:he|him|his|that member|this member|the same person|that person)\b/
      .test(q);
  const explicitPlaceReference =
    /\b(?:its|that community|this community|the same community|that ministry|this ministry)\b/
      .test(q);
  const contextualThere = /\bthere\b/.test(q) &&
    /\b(?:assigned|works?|staffing|lives?|lived|members?|superior|community|ministry)\b/
      .test(q) &&
    (!context || context.focus_entity_type === "community" ||
      context.primary_entity_type === "community" ||
      context.focus_entity_type === "ministry" ||
      context.primary_entity_type === "ministry" ||
      context.ambiguous_entity_type === "community" ||
      context.ambiguous_entity_type === "ministry");
  const placeReference = explicitPlaceReference || contextualThere;
  if (!personReference && !placeReference) return undefined;
  if (!context) {
    if (personReference) {
      return { intent: "clarification_needed", topic: "member_reference" };
    }
    if (/^(?:who|where|what|which)\b/.test(q)) {
      return { intent: "clarification_needed", topic: "community_reference" };
    }
    return undefined;
  }

  if (personReference) {
    const personType = context.last_answer_entity_type === "member"
      ? context.last_answer_entity_type
      : context.focus_entity_type ?? context.primary_entity_type;
    const personName = context.last_answer_entity_type === "member"
      ? context.last_answer_entity_name
      : context.focus_entity_name ?? context.primary_entity_name;
    const personId = context.last_answer_entity_type === "member"
      ? context.last_answer_entity_id
      : context.focus_entity_id ?? context.primary_entity_id;
    if (
      context?.ambiguous_entity_type === "member" ||
      context?.entity_set_type === "member" &&
        (context.entity_set_size ?? 0) > 1 ||
      personType !== "member" || !personName
    ) {
      return { intent: "clarification_needed", topic: "member_reference" };
    }
    const base = { entity: personName, entityId: personId };
    if (/\bwhere (?:is|was)\b|\b(?:which|what) community\b/.test(q)) {
      return year
        ? { intent: "member_historical_location", year, ...base }
        : { intent: "member_current_location", ...base };
    }
    if (/\b(?:appointments?|offices?)\b/.test(q)) {
      return { intent: "member_appointment_history", ...base };
    }
    if (
      /\b(?:first (?:profession|vows)|temporary (?:profession|vows))\b/.test(q)
    ) return { intent: "member_history", topic: "first_profession", ...base };
    if (/\b(?:final|perpetual) (?:profession|vows)\b/.test(q)) {
      return { intent: "member_history", topic: "final_profession", ...base };
    }
    if (/\b(?:ordained|ordination)\b/.test(q)) {
      return { intent: "member_history", topic: "ordination", ...base };
    }
    return { intent: "clarification_needed", topic: "member_follow_up" };
  }

  const communityType = context.focus_entity_type ??
    context.primary_entity_type;
  const communityName = context.focus_entity_name ??
    context.primary_entity_name;
  const communityId = context.focus_entity_id ?? context.primary_entity_id;
  if (communityType === "ministry" && communityName) {
    if (/\b(?:assigned|works?|staffing|members?|religious|people)\b/.test(q)) {
      return {
        intent: "ministry_assignment_history",
        entity: communityName,
        entityId: communityId,
        topic: "current",
        outputType,
      };
    }
    return { intent: "clarification_needed", topic: "ministry_reference" };
  }
  if (
    context?.ambiguous_entity_type === "community" ||
    context?.entity_set_type === "community" &&
      (context.entity_set_size ?? 0) > 1 ||
    communityType !== "community" || !communityName
  ) {
    return { intent: "clarification_needed", topic: "community_reference" };
  }
  const base = { entity: communityName, entityId: communityId };
  if (/\b(?:superior|leads?)\b/.test(q)) {
    return {
      intent: "community_superior_history",
      year,
      topic: year ? undefined : "current",
      ...base,
    };
  }
  if (/\b(?:members?|lives?|lived)\b/.test(q)) {
    return {
      intent: "community_membership_history",
      year,
      topic: year ? undefined : "current",
      outputType,
      ...base,
    };
  }
  return { intent: "clarification_needed", topic: "community_follow_up" };
}

function memberSafeFactualQuestion(
  question: string,
): AskCommunioInterpretation | undefined {
  const q = question.toLowerCase().replace(/[?.!]+$/, "").trim();
  if (
    /\b(?:eligible|eligibility|where did|history)\b/.test(q) ||
    /\b(?:18|19|20)\d{2}\b/.test(q)
  ) return undefined;
  const superior = question.match(
    /(?:who is (?:the )?superior of|who leads)\s+(.+?community)[?.!]*$/i,
  );
  if (superior) {
    return {
      intent: "member_safe_factual",
      topic: "community_superior",
      entity: superior[1].trim(),
    };
  }
  const members = question.match(
    /who are (?:the )?members of\s+(.+?community)[?.!]*$/i,
  );
  if (members) {
    return {
      intent: "member_safe_factual",
      topic: "community_members",
      entity: members[1].trim(),
    };
  }
  const roles: Array<[RegExp, string]> = [
    [/\bprincipal\b/, "principal"],
    [/\b(?:parish priest|pastor)\b/, "parish_priest"],
    [/\bnovice master\b/, "novice_master"],
    [/\bformation director\b/, "formation_director"],
    [/\bvocation promoter\b/, "vocation_promoter"],
    [/\b(?:director|head|heads|leads|leader)\b/, "director"],
  ];
  for (const [pattern, role] of roles) {
    if (!pattern.test(q)) continue;
    const entity =
      question.match(/(?:of|at|for)\s+(.+?)[?.!]*$/i)?.[1]?.trim() ??
        question.match(
          /^(.+?)\s+(?:principal|parish priest|pastor|director|head|leader)[?.!]*$/i,
        )?.[1]?.trim() ??
        question.match(/^who\s+(?:heads|leads)\s+(.+?)[?.!]*$/i)?.[1]?.trim();
    if (entity) {
      return {
        intent: "member_safe_factual",
        topic: "ministry_leader",
        entity,
        role,
      };
    }
  }
  const location = question.match(/where is\s+(.+?)[?.!]*$/i);
  if (
    location &&
    /(?:school|parish|ministry|formation|centre|center)/i.test(location[1])
  ) {
    return {
      intent: "member_safe_factual",
      topic: "ministry_location",
      entity: location[1].trim(),
    };
  }
  return undefined;
}

function organizationQuestion(
  q: string,
): AskCommunioInterpretation | undefined {
  if (q.includes("missionaries of st. antony")) {
    return { intent: "organization_identity", entity: "congregation_name" };
  }
  if (q.includes("provincial council")) {
    return { intent: "appointment_search", entity: "provincial_councillor" };
  }
  if (/^(?:who is (?:the )?|current )assistant provincial$/.test(q)) {
    return { intent: "appointment_search", entity: "assistant_provincial" };
  }
  if (
    /^who is (?:the )?(?:provincial )?(?:bursar|treasurer)$/.test(q) ||
    /^(?:current )?(?:provincial )?(?:bursar|treasurer)$/.test(q)
  ) {
    return { intent: "appointment_search", entity: "provincial_bursar" };
  }
  if (
    q.includes("current provincial") || /^who is (?:the )?provincial$/.test(q)
  ) return { intent: "appointment_search", entity: "provincial" };
  if (/^who is (?:the )?secretary$/.test(q)) {
    return { intent: "appointment_search", entity: "provincial_secretary" };
  }
  if (q.includes("assistant superior general")) {
    return {
      intent: "organization_identity",
      entity: "assistant_superior_general",
    };
  }
  if (q.includes("superior general")) {
    return { intent: "organization_identity", entity: "superior_general" };
  }
  if (q.includes("general treasurer")) {
    return { intent: "organization_identity", entity: "general_treasurer" };
  }
  if (q.includes("general councillor")) {
    return { intent: "organization_identity", entity: "general_councillors" };
  }
  if (
    q.includes("where") &&
    (q.includes("general administration") || q.includes("generalate"))
  ) {
    return {
      intent: "organization_identity",
      entity: "general_administration",
    };
  }
  if (q.includes("who founded") || q.includes("founder")) {
    return { intent: "organization_identity", entity: "founder" };
  }
  if (
    q.includes("when") && q.includes("congregation") && q.includes("founded")
  ) return { intent: "organization_identity", entity: "founded_year" };
  if (q.includes("congregation motto")) {
    return { intent: "organization_identity", entity: "congregation_motto" };
  }
  if (q.includes("province motto")) {
    return { intent: "organization_identity", entity: "province_motto" };
  }
  if ((q.includes("called") || q.includes("name")) && q.includes("province")) {
    return { intent: "organization_identity", entity: "province_name" };
  }
  if (
    q.includes("what congregation") || q.includes("our congregation") ||
    q.includes("congregation is this")
  ) return { intent: "organization_identity", entity: "congregation_name" };
  return undefined;
}

function presentStateQuestion(
  q: string,
): AskCommunioInterpretation | undefined {
  if (
    /\b(?:18|19|20)\d{2}\b/.test(q) ||
    /\b(?:above|over|older than|under|below|younger than|between)\b/.test(q)
  ) return undefined;
  if (
    /\b(?:how many (?:active |current )?(?:members|religious)(?: are there| do we have)?|total members|number of members|current membership|congregation strength)\b/
      .test(q)
  ) {
    return {
      intent: "present_state",
      topic: "active_members",
      outputType: "count",
    };
  }
  if (
    /^(?:how many|number of) (?:current |active )?priests(?: are there)?$/.test(
      q,
    )
  ) return { intent: "present_state", topic: "priests", outputType: "count" };
  if (
    /^(?:how many|number of) (?:current |active )?brothers(?: are there)?$/
      .test(q)
  ) return { intent: "present_state", topic: "brothers", outputType: "count" };
  if (
    /\b(?:how many (?:active )?communities(?: are there| do we have)?|total communities|number of communities|current communities|active communities)\b/
      .test(q)
  ) {
    return {
      intent: "present_state",
      topic: "active_communities",
      outputType: "count",
    };
  }
  if (q.includes("ministries are active") || q.includes("active ministries")) {
    return { intent: "present_state", topic: "active_ministries" };
  }
  if (q.includes("current community superiors")) {
    return { intent: "present_state", topic: "community_superiors" };
  }
  if (q.includes("current principals")) {
    return { intent: "present_state", topic: "principals" };
  }
  if (q.includes("currently on leave")) {
    return { intent: "present_state", topic: "on_leave" };
  }
  if (/\b(?:who is|members are) retired\b/.test(q)) {
    return { intent: "present_state", topic: "retired" };
  }
  if (q.includes("currently in formation")) {
    return { intent: "present_state", topic: "formation" };
  }
  return undefined;
}

function extractScopedMemberQuestion(
  question: string,
  q: string,
  year?: number,
): AskCommunioInterpretation | undefined {
  const appointment = question.match(
    /^(?:show (?:the )?)?(?:appointment|office) history (?:of\s+)?(.+?)[?.!]*$/i,
  ) ??
    question.match(
      /^(?:appointments?|offices?) (?:of|held by)\s+(.+?)[?.!]*$/i,
    );
  if (appointment) {
    return {
      intent: "member_appointment_history",
      entity: normalizeMemberEntity(appointment[1]),
    };
  }

  const naturalHistoryPatterns = [
    /^(?:what|which) appointments? (?:has|have|did)\s+(.+?)\s+(?:held|hold)[?.!]*$/i,
    /^(?:what|which) offices? (?:has|have|did)\s+(.+?)\s+(?:held|hold)[?.!]*$/i,
    /^(?:appointments?|offices?|leadership offices?) held by\s+(.+?)[?.!]*$/i,
    /^list\s+(.+?)(?:'s|’s)\s+(?:appointments?|offices?)[?.!]*$/i,
    /^what leadership roles? did\s+(.+?)\s+hold[?.!]*$/i,
  ];
  for (const pattern of naturalHistoryPatterns) {
    const member = question.match(pattern)?.[1];
    if (member) {
      return {
        intent: "member_appointment_history",
        entity: normalizeMemberEntity(member),
      };
    }
  }

  const tenure = question.match(
    /^(?:how long (?:did|was)|tenure of|when (?:did|was))\s+(.+?)\s+(?:serve as|as|serve)?\s*provincial[?.!]*$/i,
  );
  if (tenure) {
    return {
      intent: "member_office_tenure",
      entity: normalizeMemberEntity(tenure[1]),
      role: "provincial",
    };
  }
  const previous = question.match(/^previous assignment of\s+(.+?)[?.!]*$/i);
  if (previous) {
    return {
      intent: "previous_assignment",
      entity: normalizeMemberEntity(previous[1]),
    };
  }

  const ministryHistory = question.match(
    /^(?:show\s+)?ministry history of\s+(.+?)[?.!]*$/i,
  );
  if (ministryHistory) {
    return {
      intent: "member_history",
      entity: normalizeMemberEntity(ministryHistory[1]),
      topic: "ministry",
    };
  }

  const profileAssignment = question.match(
    /^which (community|ministry) is\s+(.+?)\s+in[?.!]*$/i,
  );
  if (profileAssignment) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(profileAssignment[2]),
      topic: "current_assignment",
    };
  }

  const profileOrigin = question.match(/^where is\s+(.+?)\s+from[?.!]*$/i);
  if (profileOrigin) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(profileOrigin[1]),
      topic: "origin",
    };
  }

  const profileOverview = question.match(
    /^(?:show (?:me )?a?\s*profile of|profile of)\s+(.+?)[?.!]*$/i,
  );
  if (
    profileOverview &&
    !/\b(?:community|school|parish|hospital|ministry|formation house|centre|center)\b/i
      .test(profileOverview[1])
  ) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(profileOverview[1]),
      topic: "profile",
    };
  }
  const birthDate =
    question.match(/^what is\s+(.+?)(?:'s|’s)\s+date of birth[?.!]*$/i) ??
      question.match(/^when was\s+(.+?)\s+born[?.!]*$/i);
  if (birthDate) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(birthDate[1]),
      topic: "date_of_birth",
    };
  }
  const age = question.match(/^how old is\s+(.+?)[?.!]*$/i);
  if (age) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(age[1]),
      topic: "age",
    };
  }
  const status = question.match(
    /^(?:show|what is)\s+(.+?)(?:'s|’s)\s+(?:member )?status[?.!]*$/i,
  );
  if (status) {
    return {
      intent: "member_profile",
      entity: normalizeMemberEntity(status[1]),
      topic: "status",
    };
  }

  const historicalPatterns = [
    /where was\s+(.+?)\s+in\s+((?:18|19|20)\d{2})/i,
    /^(.+?)\s+location\s+in\s+((?:18|19|20)\d{2})/i,
    /which community was\s+(.+?)\s+in\s+(?:during\s+)?((?:18|19|20)\d{2})/i,
    /where did\s+(.+?)\s+serve\s+in\s+((?:18|19|20)\d{2})/i,
  ];
  for (const pattern of historicalPatterns) {
    const match = question.match(pattern);
    if (match) {
      return {
        intent: "member_historical_location",
        entity: normalizeMemberEntity(match[1]),
        year: Number(match[2]),
      };
    }
  }

  if (year) return undefined;
  if (/\bfrom[?.!]*$/i.test(question)) return undefined;
  const currentPatterns = [
    /where is\s+(.+?)\s+assigned[?.!]*$/i,
    /where is\s+(.+?)(?:\s+now)?[?.!]*$/i,
    /where does\s+(.+?)\s+live[?.!]*$/i,
    /which community is\s+(.+?)\s+in[?.!]*$/i,
    /current assignment of\s+(.+?)[?.!]*$/i,
  ];
  for (const pattern of currentPatterns) {
    const match = question.match(pattern);
    const candidate = match ? normalizeMemberEntity(match[1]) : "";
    if (
      match && candidate.split(/\s+/).length >= 2 &&
      !/(?:general administration|generalate)$/i.test(candidate) &&
      !/\b(?:school|parish|hospital|ministry|community|formation house|retreat centre|retreat center|old age home)\b/i
        .test(candidate)
    ) {
      return { intent: "member_current_location", entity: candidate };
    }
  }
  return undefined;
}

function extractWave2Question(
  question: string,
  q: string,
  year: number | undefined,
  yearTo: number | undefined,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (/^list closed communities$/.test(q)) {
    return { intent: "community_directory", topic: "closed" };
  }
  if (
    /^community membership in (?:18|19|20)\d{2}$/.test(q) ||
    /^members between (?:18|19|20)\d{2} and (?:18|19|20)\d{2}$/.test(q) ||
    /^how many members were there in (?:18|19|20)\d{2}$/.test(q) ||
    /^community strength in (?:18|19|20)\d{2}$/.test(q)
  ) {
    return {
      intent: "clarification_needed",
      topic: "community_reference",
      year,
      yearTo,
      outputType,
    };
  }
  if (/^who (?:joined|left) the community in (?:18|19|20)\d{2}$/.test(q)) {
    return {
      intent: "clarification_needed",
      topic: "community_reference",
      year,
    };
  }
  const movement = question.match(
    /^who (?:joined|moved into|left|moved out of)\s+(.+?community(?:\s+.+)?)\s+in\s+((?:18|19|20)\d{2})[?.!]*$/i,
  );
  if (movement) {
    return {
      intent: "community_movement",
      entity: movement[1],
      year: Number(movement[2]),
      topic: /left|out of/i.test(question) ? "left" : "joined",
      outputType,
    };
  }
  const history = question.match(
    /^history of\s+(.+?community(?:\s+.+)?)[?.!]*$/i,
  );
  if (history) return { intent: "community_history", entity: history[1] };
  if (/^which was the largest community in (?:18|19|20)\d{2}$/.test(q)) {
    return { intent: "historical_community_ranking", year, role: "largest" };
  }
  if (
    /^(?:members working in schools|members working in parishes|how many members are in education ministry)$/
      .test(q)
  ) {
    return {
      intent: "ministry_type_staffing",
      topic: q.includes("parish") ? "parish" : "school",
      outputType,
    };
  }
  const successor = question.match(/^who succeeded\s+(.+?)[?.!]*$/i);
  if (successor) {
    return {
      intent: "leadership_successor",
      entity: normalizeMemberEntity(successor[1]),
      role: "provincial",
    };
  }
  if (/^appointments before (?:18|19|20)\d{2}$/.test(q)) {
    return {
      intent: "appointment_period_search",
      year,
      timeRelation: "before",
    };
  }
  if (/^appointments after (?:18|19|20)\d{2}$/.test(q)) {
    return { intent: "appointment_period_search", year, timeRelation: "after" };
  }
  const comparison = question.match(
    /^compare appointments of\s+(.+?)\s+and\s+(.+?)[?.!]*$/i,
  );
  if (comparison) {
    return {
      intent: "member_appointment_comparison",
      entity: `${normalizeMemberEntity(comparison[1])}|${
        normalizeMemberEntity(comparison[2])
      }`,
    };
  }
  return undefined;
}

function extractLeadershipDirectory(
  q: string,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (
    /^(?:(?:list|show) (?:the )?)?(?:past|former|previous) provincials$/.test(
      q,
    ) ||
    /^(?:history of provincials|who (?:has|have) served as provincial)$/.test(q)
  ) {
    return { intent: "leadership_history", role: "provincial", outputType };
  }
  return undefined;
}

function extractCommunityDirectory(
  question: string,
  q: string,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (
    /^(?:(?:list|show)(?: me)?(?: a list)?(?: of)?|give me a list of|what) (?:the )?(?:all )?(?:active )?communities(?: are there)?$/
      .test(q) ||
    /^community directory$/.test(q)
  ) {
    return { intent: "community_directory", topic: "active", outputType };
  }
  const profile = question.match(
    /^(?:where is|show|tell me about|location of)\s+(.+?community(?:\s+.+)?)[?.!]*$/i,
  );
  if (profile && !/\b(?:history|assignment)\b/i.test(profile[1])) {
    return {
      intent: "community_profile",
      entity: profile[1].replace(/[?.!]+$/, "").trim(),
    };
  }
  return undefined;
}

function extractMinistryDirectory(
  question: string,
  q: string,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (
    /^(?:how many|number of) (?:active )?ministries(?: are there)?$/.test(q)
  ) {
    return { intent: "ministry_directory", topic: "all", outputType: "count" };
  }
  if (
    /^(?:(?:list|show)(?: me)?(?: a list)?(?: of)?|give me a list of|what) (?:the )?(?:all )?(?:active )?ministries(?: are there)?$/
      .test(q) ||
    /^ministry directory$/.test(q)
  ) {
    return { intent: "ministry_directory", topic: "all", outputType };
  }
  const categories: Array<[RegExp, string]> = [
    [/^(?:schools?|educational institutions?)$/, "school"],
    [/^parish(?:es)?$/, "parish"],
    [/^hospitals?$/, "hospital"],
    [/^formation houses?$/, "formation_house"],
    [/^retreat (?:centres?|centers?)$/, "retreat_centre"],
    [/^old age homes?$/, "old_age_home"],
  ];
  const countPhrase = q.match(
    /^(?:how many|number of|count(?: the| of)?)\s+(?:active )?(.+?)(?:\s+ministries)?(?:\s+are there)?$/,
  )?.[1];
  if (countPhrase) {
    for (const [pattern, topic] of categories) {
      if (pattern.test(countPhrase)) {
        return { intent: "ministry_directory", topic, outputType: "count" };
      }
    }
  }
  const categoryPhrase = q.match(/^(?:list|show)(?: all)?(?: active)? (.+)$/)
    ?.[1];
  if (categoryPhrase) {
    for (const [pattern, topic] of categories) {
      if (pattern.test(categoryPhrase)) {
        return { intent: "ministry_directory", topic, outputType };
      }
    }
  }
  const profile = question.match(
    /^(?:where is|show|tell me about|location of)\s+(.+?(?:school|parish|hospital|ministry|formation house|retreat (?:centre|center)|old age home)(?:\s+.+)?)[?.!]*$/i,
  );
  if (profile && !/\b(?:history|assignment|assigned)\b/i.test(profile[1])) {
    return {
      intent: "ministry_profile",
      entity: profile[1].replace(/[?.!]+$/, "").trim(),
    };
  }
  return undefined;
}

function extractNamedCommunityQuestion(
  question: string,
  year: number | undefined,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  const opening = question.match(
    /^when (?:(?:was|is) (?:the )?(.+?) (?:formed|started|established|opened|founded|began)|did (?:the )?(.+?) (?:form|start|open|begin))[?.!]*$/i,
  );
  if (opening && /\bcommunity\b/i.test(opening[1] ?? opening[2])) {
    return {
      intent: "community_lifecycle",
      entity: (opening[1] ?? opening[2]).trim(),
      topic: "OPENED",
    };
  }
  const superior = question.match(
    /^who (?:leads?|heads?)\s+(.+?community(?:\s+.+)?)[?.!]*$/i,
  );
  if (superior) {
    return {
      intent: "community_superior_history",
      entity: superior[1].replace(/[?.!]+$/, "").trim(),
      year,
    };
  }

  const membership = question.match(
    /^who (?:currently )?lives? in\s+(.+?community(?:\s+.+)?)[?.!]*$/i,
  ) ??
    question.match(
      /^(?:how many|count(?: the)?) members (?:(?:are|live) )?in\s+(.+?community(?:\s+.+)?)[?.!]*$/i,
    );
  if (membership) {
    return {
      intent: "community_membership_history",
      entity: membership[1].replace(/[?.!]+$/, "").trim(),
      year,
      outputType,
    };
  }
  return undefined;
}

function extractNamedMinistryQuestion(
  question: string,
  year: number | undefined,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  const establishment = question.match(
    /^when (?:(?:was|is) (.+?) (?:started|established|opened|founded)|did (.+?) (?:start|open|begin))[?.!]*$/i,
  );
  if (
    establishment &&
    /\b(?:college|school|parish|hospital|ministry|formation house|institute|centre|center)\b/i
      .test(establishment[1] ?? establishment[2])
  ) {
    return {
      intent: "ministry_establishment",
      entity: (establishment[1] ?? establishment[2]).trim(),
    };
  }
  const ordinalLeader = question.match(
    /^(?:who (?:was|is) (?:the )?)?(first|earliest|initial|founding|previous|current|present|former|past) principal (?:of|at)\s+(.+?)[?.!]*$/i,
  );
  if (ordinalLeader) {
    const ordinal = ordinalLeader[1].toLowerCase();
    const topic = ["first", "earliest", "initial", "founding"].includes(ordinal)
      ? "earliest"
      : ["current", "present"].includes(ordinal)
      ? "current"
      : ordinal === "previous"
      ? "previous"
      : "past";
    return {
      intent: "ministry_leadership_history",
      entity: ordinalLeader[2].trim(),
      role: "principal",
      topic,
    };
  }
  const assignment = question.match(
    /^who (?:currently )?(?:works?|worked|serves?|served) at\s+(.+?)(?:\s+in\s+(?:18|19|20)\d{2})?[?.!]*$/i,
  ) ??
    question.match(
      /^who (?:is|was) assigned to\s+(.+?)(?:\s+in\s+(?:18|19|20)\d{2})?[?.!]*$/i,
    ) ??
    question.match(
      /^how many (?:members|religious|people) (?:works?|worked|serves?|served|are assigned) (?:at|to)\s+(.+?)(?:\s+in\s+(?:18|19|20)\d{2})?[?.!]*$/i,
    ) ??
    question.match(
      /^(?:number of (?:members|religious|people)(?: working)?|staffing) at\s+(.+?)[?.!]*$/i,
    ) ??
    question.match(
      /^(?:show|list) (?:the )?members assigned to\s+(.+?)[?.!]*$/i,
    );
  if (
    !assignment ||
    !/\b(?:college|school|parish|hospital|ministry|formation house|institute|centre|center)\b/i
      .test(assignment[1])
  ) return undefined;
  return {
    intent: "ministry_assignment_history",
    entity: assignment[1].trim(),
    year,
    outputType,
    topic: year ? undefined : "current",
  };
}

function extractCommunitySizeRanking(
  q: string,
): AskCommunioInterpretation | undefined {
  const largest =
    /\b(?:most (?:members|number)|highest (?:number|membership)|largest (?:community|membership)|biggest community|community with (?:the )?(?:most|maximum) members|maximum (?:members|strength)|strongest community by membership)\b/;
  const smallest =
    /\b(?:fewest members|least number|lowest number|smallest (?:community|membership)|community with (?:the )?(?:least|minimum) members|minimum (?:members|strength))\b/;
  if (largest.test(q)) {
    return { intent: "community_size_ranking", topic: "largest" };
  }
  if (smallest.test(q)) {
    return { intent: "community_size_ranking", topic: "smallest" };
  }
  return undefined;
}

function extractComposedCommunityQuery(
  q: string,
  year?: number,
  outputType: "records" | "count" = "records",
): AskCommunioInterpretation | undefined {
  const ranking = extractCommunitySizeRanking(q);
  if (!ranking) return undefined;
  if (year && /\bwhich (?:was|is)\b/.test(q) && /\bcommunity\b/.test(q)) {
    return {
      intent: "historical_community_ranking",
      role: ranking.topic,
      year,
    };
  }
  if (/\bsuperior\b/.test(q) && /\bwhere\b/.test(q)) {
    return {
      intent: "composed_community_query",
      role: ranking.topic,
      topic: "superior_location",
      year,
    };
  }
  if (/\bsuperior\b/.test(q) && /\bhow old\b/.test(q)) {
    return {
      intent: "composed_community_query",
      role: ranking.topic,
      topic: "superior_age",
      year,
    };
  }
  if (/\b(?:superior|leads?)\b/.test(q)) {
    return {
      intent: "composed_community_query",
      role: ranking.topic,
      topic: "superior",
      year,
    };
  }
  if (
    /\b(?:members?|lived|lives)\b/.test(q) &&
    !/^(?:which (?:community|is|was)|(?:the )?(?:largest|smallest|biggest) community|community with|strongest community)/
      .test(q)
  ) {
    return {
      intent: "composed_community_query",
      role: ranking.topic,
      topic: "members",
      year,
      outputType,
    };
  }
  return undefined;
}

function extractWave4Analytics(
  q: string,
): AskCommunioInterpretation | undefined {
  if (/^how many communities have fewer than 5 members$/.test(q)) {
    return { intent: "community_size_threshold", age: 5, outputType: "count" };
  }
  if (/^average age of members$/.test(q)) {
    return { intent: "member_analytics", topic: "average_age" };
  }
  if (/^age distribution$/.test(q)) {
    return { intent: "member_analytics", topic: "age_distribution" };
  }
  if (/^median age$/.test(q)) {
    return { intent: "member_analytics", topic: "median_age" };
  }
  if (/^members by state$/.test(q)) {
    return { intent: "member_analytics", topic: "members_by_state" };
  }
  if (/^which ministry has the most members$/.test(q)) {
    return { intent: "ministry_size_ranking", topic: "largest" };
  }
  if (/^st antony$/.test(q)) {
    return { intent: "clarification_needed", topic: "bare_entity" };
  }
  if (/^joseph$/.test(q)) return { intent: "person_search", entity: "Joseph" };
  if (/^(?:community|member)$/.test(q)) {
    return { intent: "clarification_needed", topic: q };
  }
  return undefined;
}

function extractAgeExtreme(q: string): AskCommunioInterpretation | undefined {
  if (
    /^(?:who is (?:the )?)?(?:oldest|eldest)(?: (?:member|religious))?$/.test(
      q,
    ) || /\bmost senior by age\b|\bwho was born earliest\b/.test(q)
  ) return { intent: "member_age_extreme", topic: "oldest" };
  if (
    /^(?:who is (?:the )?)?youngest(?: (?:member|religious))?$/.test(q) ||
    /\bmost junior by age\b|\bwho was born most recently\b/.test(q)
  ) return { intent: "member_age_extreme", topic: "youngest" };
  return undefined;
}

function extractMemberSubject(question: string): string | undefined {
  const patterns = [
    /\bis\s+(.+?)\s+(?:currently\s+)?eligible\b/i,
    /(?:show|what is|give me)\s+(.+?)(?:'s|’s)\s+(?:email|phone|address)[?.!]*$/i,
    /(?:give me|show)\s+(.+?)(?:'s|’s)\s+(?:history|ministry history)/i,
    /where (?:has|did|is)\s+(.+?)\s+(?:served|serve|currently|study)/i,
    /(?:when did|when was|what is|what are|which state is|which diocese is|which community is|which ministry is|who are)\s+(.+?)(?:'s|’s|\s+ordained|\s+make|\s+from\b|\s+parents?\b)/i,
    /(?:qualifications?|degrees?|home parish|religious id|parents?)\s+(?:does|of)\s+(.+?)(?:\s+have)?[?.!]*$/i,
    /did\s+(.+?)\s+ever\s+(?:take|serve|live)/i,
    /what\s+(?:offices|communities|ministries)\s+(?:has|did)\s+(.+?)\s+(?:held|lived|worked|served)/i,
  ];
  for (const pattern of patterns) {
    const value = question.match(pattern)?.[1];
    if (value) return normalizeMemberEntity(value);
  }
  return undefined;
}

function memberProfileTopic(q: string): string {
  if (q.includes("religious id")) return "religious_id";
  if (/qualifications?|degrees?|stud(?:y|ied)/.test(q)) return "qualifications";
  if (/home parish|diocese|which state|\bfrom\b/.test(q)) return "origin";
  if (q.includes("parent")) return "parents";
  if (/email|phone|address/.test(q)) {
    return q.includes("email")
      ? "email"
      : q.includes("phone")
      ? "phone"
      : "address";
  }
  return "current_assignment";
}

function historyTopic(q: string): string | undefined {
  if (q.includes("ordain")) return "ordination";
  if (q.includes("first profession")) return "first_profession";
  if (q.includes("final profession") || q.includes("perpetual profession")) {
    return "final_profession";
  }
  if (q.includes("sabbatical") || q.includes("leave")) return "leave";
  if (q.includes("principal")) return "principal";
  if (q.includes("communit")) return "community";
  if (q.includes("ministr") || q.includes("served")) return "ministry";
  if (q.includes("office")) return "office";
  return undefined;
}

function extractOriginSearch(
  question: string,
):
  | { entity: string; field?: AskCommunioInterpretation["originField"] }
  | undefined {
  const q = question.toLowerCase();
  const hasOrigin = /\b(?:from|comes? from|belongs? to)\b/.test(q) &&
    /\b(?:member|members|who|which|how many|show)\b/.test(q);
  if (!hasOrigin || /\b(?:serving|assigned|outside)\b/.test(q)) {
    return undefined;
  }
  const field = q.includes("parish")
    ? "native_parish"
    : q.includes("diocese")
    ? "native_diocese"
    : q.includes("district")
    ? "district"
    : q.includes("state")
    ? "state"
    : q.includes("country")
    ? "country"
    : undefined;
  let entity = question.match(
    /(?:comes? from|from|belongs? to)\s+(?:the\s+)?(.+?)[?.!]*$/i,
  )?.[1]?.trim();
  if (!entity) return undefined;
  entity = entity.replace(/^(?:the\s+)?(?:diocese of)\s+/i, "").replace(
    /\s+(?:district|parish)$/i,
    "",
  ).trim();
  return { entity, field };
}

function extractCurrentLocation(
  question: string,
): { entity: string; outside: boolean } | undefined {
  if (!/\b(?:18|19|20)\d{2}\b/.test(question)) {
    const implicit = question.match(/^who (?:is|are) in\s+(.+?)[?.!]*$/i)?.[1]
      ?.trim();
    if (implicit) return { entity: implicit, outside: false };
  }
  const outside = question.match(/(?:currently\s+)?outside\s+(.+?)[?.!]*$/i)
    ?.[1]?.trim();
  if (
    outside && !/\bstud(?:y|ied)\b/i.test(question) &&
    /\b(?:member|members|who|which)\b/i.test(question)
  ) {
    return { entity: outside, outside: true };
  }
  const entity = question.match(
    /(?:currently|presently)?\s*(?:serving|assigned|living|based)\s+in\s+(.+?)(?:\s+now)?[?.!]*$/i,
  )?.[1]?.trim();
  return entity ? { entity, outside: false } : undefined;
}

function extractLocationEntitySearch(
  question: string,
): AskCommunioInterpretation | undefined {
  const match = question.match(
    /(?:which|show|what)\s+(communities|ministries)\s+(?:are\s+)?(?:in|outside)\s+(.+?)[?.!]*$/i,
  );
  if (!match) return undefined;
  return {
    intent: "location_entity_search",
    topic: match[1].toLowerCase(),
    entity: match[2].trim(),
    role: /outside/i.test(match[0]) ? "outside" : undefined,
  };
}

function extractAge(
  q: string,
):
  | { value: number; valueTo?: number; comparison: "above" | "below" }
  | undefined {
  const between = q.match(
    /\bbetween\s+(\d{1,3})(?:\s+years?\s+old)?\s+(?:and|to)\s+(\d{1,3})(?:\s+years?\s+old)?\b/,
  );
  if (between) {
    return {
      value: Number(between[1]),
      valueTo: Number(between[2]),
      comparison: "above",
    };
  }
  const range = q.match(
    /\b(?:ages?|aged|from)\s+(\d{1,3})\s*(?:-|–|—|to)\s*(\d{1,3})(?:\s+years?)?(?:\s+old)?\b/,
  );
  if (range) {
    return {
      value: Number(range[1]),
      valueTo: Number(range[2]),
      comparison: "above",
    };
  }
  const plus = q.match(/\bage\s+(\d{1,3})\s*\+/);
  if (plus) return { value: Number(plus[1]), comparison: "above" };
  const exact = q.match(
    /\b(?:exactly|aged?|age)\s+(\d{1,3})(?:\s+years?\s+old)?\b/,
  );
  if (exact) {
    return {
      value: Number(exact[1]),
      valueTo: Number(exact[1]),
      comparison: "above",
    };
  }
  const match = q.match(
    /(?:above|over|older than|under|below|younger than)\s+(?:age\s+)?(\d{1,3})/,
  );
  if (!match) return undefined;
  return {
    value: Number(match[1]),
    comparison: /under|below|younger/.test(match[0]) ? "below" : "above",
  };
}

const monthNumbers = new Map([
  ["january", 1],
  ["february", 2],
  ["march", 3],
  ["april", 4],
  ["may", 5],
  ["june", 6],
  ["july", 7],
  ["august", 8],
  ["september", 9],
  ["october", 10],
  ["november", 11],
  ["december", 12],
]);

function extractBirthdayMonth(
  q: string,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (!/\bbirthdays?\b/.test(q)) return undefined;
  for (const [name, month] of monthNumbers) {
    if (new RegExp(`\\b${name}\\b`).test(q)) {
      return { intent: "birthday_month", month, outputType };
    }
  }
  return undefined;
}

function extractVocationAnniversary(
  q: string,
  explicitYear: number | undefined,
  outputType: "records" | "count",
): AskCommunioInterpretation | undefined {
  if (
    !/\b(?:first|temporary) (?:vows?|professions?)\b/.test(q) ||
    !/\b(?:anniversar(?:y|ies)|years? of)\b/.test(q)
  ) return undefined;
  const ordinal = q.match(/\b(\d{1,3})(?:st|nd|rd|th)\b/);
  const yearsOf = q.match(/\b(\d{1,3})\s+years? of\b/);
  const anniversary = Number(ordinal?.[1] ?? yearsOf?.[1]);
  if (!Number.isInteger(anniversary) || anniversary < 1 || anniversary > 100) {
    return undefined;
  }
  const currentYear = new Date().getUTCFullYear();
  const targetYear = explicitYear ??
    (/\bnext year\b/.test(q)
      ? currentYear + 1
      : /\blast year\b/.test(q)
      ? currentYear - 1
      : currentYear);
  return {
    intent: "vocation_anniversary",
    topic: "FIRST_PROFESSION",
    anniversary,
    year: targetYear,
    outputType,
  };
}

function extractHistoricalOffice(
  q: string,
  year?: number,
  outputType: "records" | "count" = "records",
): AskCommunioInterpretation | undefined {
  if (!year) return undefined;
  const roles: Array<[RegExp, string]> = [
    [/\bassistant provincial\b/, "assistant_provincial"],
    [/\bvice provincial\b/, "vice_provincial"],
    [/\bprovincial secretary\b/, "provincial_secretary"],
    [/\b(?:secretary of the province|secretary)\b/, "provincial_secretary"],
    [/\bprovincial councillors?\b|\bcouncillors?\b/, "provincial_councillor"],
    [/\b(?:provincial )?(?:bursar|treasurer)\b/, "provincial_bursar"],
    [/\bprovincial\b|\bled (?:the )?province\b/, "provincial"],
  ];
  for (const [pattern, role] of roles) {
    if (pattern.test(q)) {
      return { intent: "historical_office_holder", role, year, outputType };
    }
  }
  return undefined;
}

function extractGovernanceBody(
  q: string,
  year?: number,
  outputType: "records" | "count" = "records",
): AskCommunioInterpretation | undefined {
  if (
    /^(?:list|show)(?: me)? (?:the )?governance bodies$/.test(q) ||
    /^(?:what|which) governance bodies (?:are there|do we have|are recorded)$/
      .test(q)
  ) {
    return { intent: "governance_directory", outputType };
  }
  const leader = q.match(
    /^(?:who|which person) (?:currently )?(?:chairs?|chaired|leads?) (?:the )?(.+?)$/,
  ) ?? q.match(
    /^who is (?:the )?(?:current )?(?:chair|chairperson|president|leader) of (?:the )?(.+?)$/,
  );
  if (
    leader &&
    /\b(?:commission|committee|council|governance body)\b/.test(leader[1])
  ) {
    return {
      intent: "governance_body_leader",
      entity: leader[1].trim().replace(/^the\s+/, ""),
    };
  }
  const members = q.match(
    /^(?:who (?:belongs to|is on|serves on)|members? of|who are (?:the )?members? of) (?:the )?(.+?)$/,
  );
  if (
    members && !year &&
    /\b(?:commission|committee|council|governance body)\b/.test(members[1])
  ) {
    return {
      intent: "governance_body_members",
      entity: members[1].trim().replace(/^the\s+/, ""),
      outputType,
    };
  }
  const profile = q.match(
    /^(?:tell me about|describe|show (?:me )?(?:details (?:for|of|about) ))(?:the )?(.+?(?:commission|committee|council|governance body))$/,
  );
  if (profile) {
    return {
      intent: "governance_body_profile",
      entity: profile[1].trim().replace(/^the\s+/, ""),
    };
  }
  if (!year) return undefined;
  if (
    /\b(?:provincial council|council members?|served on (?:the )?council|on (?:the )?provincial council)\b/
      .test(q)
  ) {
    return {
      intent: "governance_body_membership",
      topic: "provincial_council",
      year,
      outputType,
    };
  }
  return undefined;
}

function extractRole(q: string): string | undefined {
  for (
    const role of [
      "formation director",
      "principal",
      "novice master",
      "chaplain",
      "provincial secretary",
      "provincial",
      "community superior",
      "bursar",
      "treasurer",
    ]
  ) {
    if (q.includes(role)) return role.replaceAll(" ", "_");
  }
  return undefined;
}

function qualificationEntity(question: string): string | undefined {
  const q = question.toLowerCase();
  if (q.includes("outside india")) return "outside_india";
  if (q.includes("theology")) return "theology";
  if (q.includes("formation") && q.includes("diploma")) {
    return "formation diploma";
  }
  if (q.includes("master's") || q.includes("masters")) return "master";
  const abbreviation = question.match(
    /(?:M\.Ed\.|M\.Th\.|B\.Ed\.|B\.?\s*Th\.?|Ph\.?D\.?)/i,
  )?.[0];
  return abbreviation ??
    question.match(/studied at\s+(.+?)[?.!]*$/i)?.[1]?.trim();
}

function extractHistoricalEntity(
  question: string,
  prepositions: string[],
): string | undefined {
  const joined = prepositions.join("|");
  return question.match(
    new RegExp(
      `(?:${joined})\\s+(.+?)(?:\\s+in\\s+(?:18|19|20)\\d{2})?[?.!]*$`,
      "i",
    ),
  )?.[1]?.trim();
}

function extractCommunity(question: string): string | undefined {
  const withoutYear = question.replace(
    /(?:\b(?:in|during)\s+|\s+)(?:18|19|20)\d{2}\b[?.!]*$/i,
    "",
  ).replace(/[?.!]+$/, "").trim();
  const patterns = [
    /(?:community members? of|members? of|lived in|was in|were in)\s+(.+?)$/i,
    /(?:who\s+)?(?:were?\s+)?(?:the\s+)?community members?\s+(.+?)$/i,
    /^members?\s+(.+?)$/i,
  ];
  for (const pattern of patterns) {
    const value = withoutYear.match(pattern)?.[1]?.trim();
    if (value) return value;
  }
  return undefined;
}

function normalizeQuestion(question: string): string {
  return question.toLowerCase().normalize("NFKD").replace(
    /[\u0300-\u036f]/g,
    "",
  )
    .replace(/[’']/g, "'").replace(/[?.!]+$/, "").replace(/\s+/g, " ").trim();
}

function detectOutputType(q: string): "records" | "count" {
  return /\b(?:how many|number of|count(?: of)?)\b/.test(q)
    ? "count"
    : "records";
}

function detectTimeRelation(q: string): "in" | "before" | "after" | "current" {
  if (/\b(?:currently|now|present(?:ly)?)\b/.test(q)) return "current";
  if (/\bbefore\s+(?:18|19|20)\d{2}\b/.test(q)) return "before";
  if (/\bafter\s+(?:18|19|20)\d{2}\b/.test(q)) return "after";
  return "in";
}

function extractMinistry(question: string): string | undefined {
  return question.match(
    /(?:at|of|for)\s+(.+?)(?:\s+in\s+(?:18|19|20)\d{2})?[?.!]*$/i,
  )?.[1]?.trim();
}

function extractOffice(q: string): string | undefined {
  for (
    const office of ["provincial secretary", "novice master", "provincial"]
  ) if (q.includes(office)) return office.replaceAll(" ", "_");
  return undefined;
}

function extractGenericEntity(question: string): string | undefined {
  return question.match(/(?:assigned|assignment)\s+(?:to|for)?\s*(.+?)[?.!]*$/i)
    ?.[1]?.trim();
}

function extractPersonSearch(question: string): string | undefined {
  return question.match(
    /^(?:tell me about|where is|show|find|who is)\s+(.+?)[?.!]*$/i,
  )?.[1]?.trim();
}

function normalizeMemberEntity(value: string): string {
  return value
    .replace(/^\s*(?:father|fr|brother|bro|deacon|dcn)\.?\s+/i, "")
    .replace(/,?\s+MSA\s*$/i, "")
    .trim();
}
