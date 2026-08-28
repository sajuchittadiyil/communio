import {
  lifecycleAnswer,
  lifecycleEvidenceLabel,
} from "./community_lifecycle_query_logic.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (!Object.is(actual, expected)) {
    throw new Error(
      `expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`,
    );
  }
}

Deno.test("community lifecycle answers preserve success and precise zero semantics", () => {
  assertEquals(
    lifecycleAnswer("OPENED", 2015, ["St. Joachim Senior Community"]),
    "1 community is recorded as opening in 2015:\n• St. Joachim Senior Community",
  );
  assertEquals(
    lifecycleAnswer("CLOSED", 2015, []),
    "No communities are recorded as closing in 2015.",
  );
});

Deno.test("community lifecycle evidence stays human-facing", () => {
  assertEquals(lifecycleEvidenceLabel("OPENED"), "Community opening");
  assertEquals(lifecycleEvidenceLabel("CLOSED"), "Community closure");
});

Deno.test("lifecycle implementation uses only the scoped security-invoker view", async () => {
  const index = await Deno.readTextFile(new URL("./index.ts", import.meta.url));
  const migration = await Deno.readTextFile(
    new URL(
      "../../migrations/202608280003_add_community_lifecycle.sql",
      import.meta.url,
    ),
  );
  if (!index.includes('.from("v_community_lifecycle")')) {
    throw new Error("Ask lifecycle query must use v_community_lifecycle");
  }
  if (!migration.includes("with (security_invoker = true)")) {
    throw new Error("lifecycle reporting view must be security-invoker");
  }
  if (index.includes('.from("community_lifecycle_events")')) {
    throw new Error("Ask lifecycle query must not bypass the reporting view");
  }
});
