import { durationLabel, historicalAssignmentEmptyMessage, overlapsYear, startsOrEndsInYear, uniqueMemberRows } from "./wave2_query_logic.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

Deno.test("Wave 2 effective-year overlap includes boundary and open terms", () => {
  assert(overlapsYear({ from_date: "2015-12-31", to_date: null }, 2015), "Dec 31 start excluded");
  assert(overlapsYear({ from_date: "2010-01-01", to_date: "2015-01-01" }, 2015), "Jan 1 end excluded");
  assert(!overlapsYear({ from_date: "2016-01-01", to_date: null }, 2015), "future term included");
});

Deno.test("Wave 2 join and leave semantics use the correct boundary", () => {
  const row = { from_date: "2015-12-31", to_date: "2016-01-01" };
  assert(startsOrEndsInYear(row, 2015, "started"), "join year failed");
  assert(startsOrEndsInYear(row, 2016, "ended"), "leave year failed");
});

Deno.test("Wave 2 people lists deduplicate overlapping assignment rows", () => {
  assert(uniqueMemberRows([{ member_id: "a", id: "1" }, { member_id: "a", id: "2" }, { member_id: "b", id: "3" }]).length === 2, "members were not deduplicated");
});

Deno.test("Wave 2 tenure uses inclusive completed dates without rounding partial terms", () => {
  const first = durationLabel({ from_date: "2018-07-01", to_date: "2024-06-30" });
  const threeYears = durationLabel({ from_date: "2020-07-01", to_date: "2023-06-30" });
  const partial = durationLabel({ from_date: "2024-07-01", to_date: "2026-08-07" });
  const second = durationLabel({ from_date: "2025-01-01", to_date: null }, new Date("2026-01-01T00:00:00Z"));
  assert(first === "6 years", "six-year institutional term failed");
  assert(threeYears === "3 years", "three-year institutional term failed");
  assert(partial === "2 years 1 month 7 days", "partial term was rounded incorrectly");
  assert(second === "1 year", "open duration failed");
});

Deno.test("Wave 2 historical superior zero results remain domain-specific", () => {
  const message = historicalAssignmentEmptyMessage("community", "St. Antony Community, Kolkata", 2015, true);
  assert(message === "I found no recorded Community Superior appointment for St. Antony Community, Kolkata covering 2015.", "superior zero-result wording fell through to membership");
  assert(!message.includes("recorded members"), "superior zero result mentions members");
});
