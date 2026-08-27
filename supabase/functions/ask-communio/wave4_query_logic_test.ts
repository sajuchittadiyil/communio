import {
  ageOnUtcDate,
  ageSummary,
  distinctActiveCounts,
} from "./wave4_query_logic.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  const encode = (value: unknown) =>
    value instanceof Map ? JSON.stringify([...value]) : JSON.stringify(value);
  if (encode(actual) !== encode(expected)) {
    throw new Error(`Expected ${encode(expected)}, got ${encode(actual)}`);
  }
}

Deno.test("Wave 4 ages honor UTC birthdays and compute even medians", () => {
  const today = new Date("2026-08-27T00:00:00Z");
  assertEquals(ageOnUtcDate("2000-08-28", today), 25);
  assertEquals(
    ageSummary([{ date_of_birth: "2000-08-27" }, {
      date_of_birth: "1980-01-01",
    }], today).median,
    36,
  );
});

Deno.test("Wave 4 age bands have stable inclusive boundaries", () => {
  const summary = ageSummary([
    { date_of_birth: "1987-08-28" },
    { date_of_birth: "1986-08-27" },
    { date_of_birth: "1967-08-28" },
    { date_of_birth: "1966-08-27" },
    { date_of_birth: "1947-08-28" },
    { date_of_birth: "1946-08-27" },
  ], new Date("2026-08-27T00:00:00Z"));
  assertEquals(summary.bands.map((row) => row.count), [1, 2, 2, 1]);
});

Deno.test("Wave 4 grouped counts deduplicate members and retain zero targets", () => {
  const rows = [{ target_id: "a", member_id: "m1" }, {
    target_id: "a",
    member_id: "m1",
  }, { target_id: "a", member_id: "m2" }];
  assertEquals(
    distinctActiveCounts(
      rows,
      "target_id",
      new Set(["a", "b"]),
      new Set(["m1", "m2"]),
      () => true,
    ),
    new Map([["a", 2], ["b", 0]]),
  );
});
