import { memberAllowedIntent } from "./access_policy.ts";

Deno.test("Member Ask Communio permits only directory-safe intents", () => {
  for (
    const intent of [
      "organization_identity",
      "person_search",
      "decision_boundary",
      "clarification_needed",
      "member_safe_factual",
      "member_profile",
      "member_languages",
      "member_history",
    ] as const
  ) {
    if (!memberAllowedIntent(intent)) {
      throw new Error(`expected ${intent} to be allowed`);
    }
  }
  for (
    const intent of [
      "eligibility_search",
      "appointment_compliance",
      "appointment_expiry",
      "appointment_search",
      "historical_office_holder",
      "governance_body_membership",
      "governance_directory",
      "governance_body_profile",
      "governance_body_members",
      "governance_body_leader",
      "community_lifecycle",
      "formal_transfer",
      "birthday_month",
      "vocation_anniversary",
      "ministry_establishment",
      "current_assignment",
      "present_state",
    ] as const
  ) {
    if (memberAllowedIntent(intent)) {
      throw new Error(`expected ${intent} to be denied`);
    }
  }
});
