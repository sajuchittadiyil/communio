import { memberAllowedIntent } from "./access_policy.ts";

Deno.test("Member Ask Communio permits only directory-safe intents", () => {
  for (const intent of ["organization_identity", "person_search", "decision_boundary", "clarification_needed", "member_safe_factual", "member_profile", "member_history"] as const) {
    if (!memberAllowedIntent(intent)) throw new Error(`expected ${intent} to be allowed`);
  }
  for (const intent of ["eligibility_search", "appointment_compliance", "appointment_expiry", "appointment_search", "historical_office_holder", "governance_body_membership", "current_assignment", "present_state"] as const) {
    if (memberAllowedIntent(intent)) throw new Error(`expected ${intent} to be denied`);
  }
});
