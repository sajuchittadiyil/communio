import { countCanonicalMemberCategory, filterMinistryTypeRows, filterPastOfficeTerms, matchingDirectoryRows } from "./wave1_query_logic.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

Deno.test("Wave 1 named directory matching returns zero, one, or ambiguous candidates", () => {
  const rows = [{ name: "St Antony Community Kolkata" }, { name: "St Antony Community Delhi" }];
  assert(matchingDirectoryRows(rows, "Sacred Heart Community", "community").length === 0, "zero result was not preserved");
  assert(matchingDirectoryRows(rows, "St Antony Community Kolkata", "community").length === 1, "exact community did not resolve");
  assert(matchingDirectoryRows(rows, "St Antony", "community").length === 2, "ambiguous community was guessed");
});

Deno.test("Wave 1 ministry aliases filter canonical stored types", () => {
  const rows = [{ ministry_type: "SCHOOL" }, { ministry_type: "PARISH" }, { ministry_type: "FORMATION_HOUSE" }];
  assert(filterMinistryTypeRows(rows, "school").length === 1, "school filter failed");
  assert(filterMinistryTypeRows(rows, "formation_house").length === 1, "formation filter failed");
  assert(filterMinistryTypeRows(rows, "hospital").length === 0, "zero-result type filter failed");
});

Deno.test("exact qualified ministry names outrank partial siblings while base names clarify", () => {
  const rows = [
    { ministry_id: "base", ministry_name: "St. Joseph School", city: "Kolkata" },
    { ministry_id: "rourkela", ministry_name: "St. Joseph School - Rourkela", city: "Rourkela" },
  ];
  assert(matchingDirectoryRows(rows, "St. Joseph School", "ministry").length === 2, "unqualified sibling ambiguity was lost");
  for (const query of [
    "St. Joseph School - Rourkela",
    "St Joseph School Rourkela",
    "St. Joseph School, Rourkela",
    "St Joseph School in Rourkela",
  ]) {
    const matches = matchingDirectoryRows(rows, query, "ministry");
    assert(matches.length === 1 && matches[0].ministry_id === "rourkela", `${query} did not resolve the qualified ministry`);
  }
});

Deno.test("stored ministry location fields conservatively disambiguate canonical names", () => {
  const rows = [
    { ministry_id: "kolkata", ministry_name: "Sacred Heart School", city: "Kolkata" },
    { ministry_id: "ranchi", ministry_name: "Sacred Heart School", city: "Ranchi" },
  ];
  const matches = matchingDirectoryRows(rows, "Sacred Heart School in Ranchi", "ministry");
  assert(matches.length === 1 && matches[0].ministry_id === "ranchi", "explicit city did not disambiguate canonical names");
});

Deno.test("stored community location fields resolve natural Kolkata variants conservatively", () => {
  const rows = [
    { id: "kolkata", name: "St. Antony Community", city: "Kolkata" },
    { id: "ranchi", name: "St. Antony Community", city: "Ranchi" },
  ];
  for (const query of ["St Antony Community Kolkata", "St. Antony Community in Kolkata", "St. Antony Community, Kolkata", "St Antony Kolkata", "St Antony Community kolkota"]) {
    const matches = matchingDirectoryRows(rows, query, "community");
    assert(matches.length === 1 && matches[0].id === "kolkata", `${query} did not resolve the Kolkata community`);
  }
  assert(matchingDirectoryRows(rows, "St Antony Community", "community").length === 2, "unqualified community ambiguity was lost");
});

Deno.test("Wave 1 past leadership excludes current and future terms and preserves repeated terms", () => {
  const rows = [
    { id: "past-1", resolved_office_code: "provincial", from_date: "2000-01-01", to_date: "2006-12-31" },
    { id: "past-2", resolved_office_code: "provincial", from_date: "2012-01-01", to_date: "2018-12-31" },
    { id: "current", resolved_office_code: "provincial", from_date: "2024-01-01", to_date: null },
    { id: "other", resolved_office_code: "secretary", from_date: "2010-01-01", to_date: "2015-01-01" },
  ];
  const result = filterPastOfficeTerms(rows, "provincial", "2026-08-27");
  assert(result.length === 2 && result[0].id === "past-1" && result[1].id === "past-2", "past terms were not scoped and ordered correctly");
});

Deno.test("Wave 1 category counts ignore names and report classification coverage", () => {
  const result = countCanonicalMemberCategory([
    { display_name: "Fr Prefix Only", ecclesiastical_title_code: null },
    { display_name: "Joseph", ecclesiastical_title_code: "PRIEST" },
    { display_name: "Thomas", ecclesiastical_title_code: "BROTHER" },
  ], "priest");
  assert(result.count === 1 && result.covered === 2, "canonical category count or coverage is wrong");
});
