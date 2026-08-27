import { applySemanticContext } from "./semantic_context.ts";

Deno.test("one semantic community remains singular regardless of evidence count", () => {
  const context = applySemanticContext(
    { last_intent: "community_size_ranking", last_result_count: 19 },
    { focus: { type: "community", id: "winner", name: "Winning Community" } },
  );
  if (context.focus_entity_id !== "winner" || context.ambiguous_entity_type) {
    throw new Error("supporting evidence polluted the semantic community context");
  }
});

Deno.test("a semantic tie is explicitly ambiguous", () => {
  const context = applySemanticContext({}, {
    entitySet: {
      type: "community",
      entities: [
        { type: "community", id: "one", name: "Community One" },
        { type: "community", id: "two", name: "Community Two" },
      ],
    },
  });
  if (context.entity_set_size !== 2 || context.ambiguous_entity_type !== "community") {
    throw new Error("a genuine community tie was not marked ambiguous");
  }
});
