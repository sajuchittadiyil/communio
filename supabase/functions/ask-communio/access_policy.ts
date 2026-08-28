import type { AskCommunioIntent } from "./intent_interpreter.ts";

export function memberAllowedIntent(intent: AskCommunioIntent): boolean {
  return new Set<AskCommunioIntent>([
    "organization_identity",
    "person_search",
    "decision_boundary",
    "clarification_needed",
    "member_safe_factual",
    "member_profile",
    "member_languages",
    "member_history",
    "community_directory",
    "community_profile",
    "ministry_directory",
    "ministry_profile",
  ]).has(intent);
}
