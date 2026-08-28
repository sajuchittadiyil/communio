import { interpretAskCommunioQuestion } from "./intent_interpreter.ts";

function assert(value: boolean, message: string): void {
  if (!value) throw new Error(message);
}

Deno.test("specific ministry relations outrank broad and current routing", () => {
  const earliest = interpretAskCommunioQuestion(
    "who was the first principal of St. Antony College",
  );
  assert(
    earliest.intent === "ministry_leadership_history" &&
      earliest.topic === "earliest",
    "first principal silently became current leadership",
  );
  const staffing = interpretAskCommunioQuestion(
    "How many members works at St. Antony college",
  );
  assert(
    staffing.intent === "ministry_assignment_history" &&
      staffing.topic === "current" && staffing.outputType === "count",
    "named ministry staffing became a province-wide member count",
  );
  const followUp = interpretAskCommunioQuestion(
    "how many are assigned there",
    {
      focus_entity_type: "ministry",
      focus_entity_id: "ministry-1",
      focus_entity_name: "St. Antony College",
    },
  );
  assert(
    followUp.intent === "ministry_assignment_history" &&
      followUp.outputType === "count" && followUp.entityId === "ministry-1",
    "ministry staffing follow-up lost its ministry context",
  );
});

Deno.test("opening questions use explicit lifecycle data and never staffing dates", async () => {
  const community = interpretAskCommunioQuestion(
    "When was the St. Joseph Community - Rourkela formed?",
  );
  assert(
    community.intent === "community_lifecycle" &&
      community.topic === "OPENED",
    "community opening did not route to lifecycle",
  );
  const ministry = interpretAskCommunioQuestion(
    "when was St. Antony College started",
  );
  assert(
    ministry.intent === "ministry_establishment",
    "ministry establishment did not retain its data-gap route",
  );
  const index = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const start = index.indexOf("async function ministryEstablishment");
  const end = index.indexOf("\nasync function", start + 20);
  const handler = index.slice(start, end);
  assert(start >= 0, "ministry establishment handler is missing");
  assert(
    !handler.includes("member_ministry_assignments"),
    "ministry establishment inferred a date from staffing history",
  );
  assert(
    handler.includes("no recorded establishment date"),
    "ministry establishment lacks a precise data-gap response",
  );
  const lifecycleStart = index.indexOf("async function communityLifecycle");
  const lifecycleEnd = index.indexOf("\nasync function", lifecycleStart + 20);
  assert(
    index.slice(lifecycleStart, lifecycleEnd).includes(
      '.from("v_community_lifecycle")',
    ),
    "community opening does not query the explicit lifecycle view",
  );
});

Deno.test("location-only community opening grammar remains lifecycle-scoped", () => {
  for (
    const question of [
      "When was the community in Rourkela formed?",
      "When did the Rourkela community start?",
      "When was St. Antony Community - Rourkela formed?",
    ]
  ) {
    const result = interpretAskCommunioQuestion(question);
    assert(
      result.intent === "community_lifecycle" && result.topic === "OPENED",
      `${question} did not route to community lifecycle`,
    );
  }
});
