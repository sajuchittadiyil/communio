import {
  countCanonicalMemberCategory,
  filterMinistryTypeRows,
  filterPastOfficeTerms,
  matchingDirectoryRows,
  resolveCommunityReference,
} from "./wave1_query_logic.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

Deno.test("Wave 1 named directory matching returns zero, one, or ambiguous candidates", () => {
  const rows = [{ name: "St Antony Community Kolkata" }, {
    name: "St Antony Community Delhi",
  }];
  assert(
    matchingDirectoryRows(rows, "Sacred Heart Community", "community")
      .length === 0,
    "zero result was not preserved",
  );
  assert(
    matchingDirectoryRows(rows, "St Antony Community Kolkata", "community")
      .length === 1,
    "exact community did not resolve",
  );
  assert(
    matchingDirectoryRows(rows, "St Antony", "community").length === 2,
    "ambiguous community was guessed",
  );
});

Deno.test("ministry matching accepts canonical table name fields", () => {
  const rows = [{ id: "college", name: "St. Antony College", city: "Kolkata" }];
  const matches = matchingDirectoryRows(rows, "St Antony College", "ministry");
  assert(
    matches.length === 1 && matches[0].id === "college",
    "canonical ministry name did not resolve",
  );
});

Deno.test("Wave 1 ministry aliases filter canonical stored types", () => {
  const rows = [{ ministry_type: "SCHOOL" }, { ministry_type: "PARISH" }, {
    ministry_type: "FORMATION_HOUSE",
  }];
  assert(
    filterMinistryTypeRows(rows, "school").length === 1,
    "school filter failed",
  );
  assert(
    filterMinistryTypeRows(rows, "formation_house").length === 1,
    "formation filter failed",
  );
  assert(
    filterMinistryTypeRows(rows, "hospital").length === 0,
    "zero-result type filter failed",
  );
});

Deno.test("exact qualified ministry names outrank partial siblings while base names clarify", () => {
  const rows = [
    {
      ministry_id: "base",
      ministry_name: "St. Joseph School",
      city: "Kolkata",
    },
    {
      ministry_id: "rourkela",
      ministry_name: "St. Joseph School - Rourkela",
      city: "Rourkela",
    },
  ];
  assert(
    matchingDirectoryRows(rows, "St. Joseph School", "ministry").length === 2,
    "unqualified sibling ambiguity was lost",
  );
  for (
    const query of [
      "St. Joseph School - Rourkela",
      "St Joseph School Rourkela",
      "St. Joseph School, Rourkela",
      "St Joseph School in Rourkela",
    ]
  ) {
    const matches = matchingDirectoryRows(rows, query, "ministry");
    assert(
      matches.length === 1 && matches[0].ministry_id === "rourkela",
      `${query} did not resolve the qualified ministry`,
    );
  }
});

Deno.test("stored ministry location fields conservatively disambiguate canonical names", () => {
  const rows = [
    {
      ministry_id: "kolkata",
      ministry_name: "Sacred Heart School",
      city: "Kolkata",
    },
    {
      ministry_id: "ranchi",
      ministry_name: "Sacred Heart School",
      city: "Ranchi",
    },
  ];
  const matches = matchingDirectoryRows(
    rows,
    "Sacred Heart School in Ranchi",
    "ministry",
  );
  assert(
    matches.length === 1 && matches[0].ministry_id === "ranchi",
    "explicit city did not disambiguate canonical names",
  );
});

Deno.test("stored community location fields resolve natural Kolkata variants conservatively", () => {
  const rows = [
    { id: "kolkata", name: "St. Antony Community", city: "Kolkata" },
    { id: "ranchi", name: "St. Antony Community", city: "Ranchi" },
  ];
  for (
    const query of [
      "St Antony Community Kolkata",
      "St. Antony Community in Kolkata",
      "St. Antony Community, Kolkata",
      "St Antony Kolkata",
      "St Antony Community kolkota",
    ]
  ) {
    const matches = matchingDirectoryRows(rows, query, "community");
    assert(
      matches.length === 1 && matches[0].id === "kolkata",
      `${query} did not resolve the Kolkata community`,
    );
  }
  assert(
    matchingDirectoryRows(rows, "St Antony Community", "community").length ===
      2,
    "unqualified community ambiguity was lost",
  );
});

Deno.test("community references preserve explicit name and location agreement", () => {
  const rows = [
    { id: "antony-rourkela", name: "St. Antony Community", city: "Rourkela" },
    { id: "antony-ranchi", name: "St. Antony Community", city: "Ranchi" },
  ];
  for (
    const query of [
      "St Antony Community Rourkela",
      "St. Antony Community - Rourkela",
    ]
  ) {
    const result = resolveCommunityReference(rows, query, true);
    assert(
      result.matches.length === 1 &&
        result.matches[0].id === "antony-rourkela" && !result.conflict,
      `${query} did not preserve matching name and location`,
    );
  }
});

Deno.test("wrong-answer regression: St Joseph Rourkela cannot resolve St Antony", () => {
  const rows = [
    { id: "antony", name: "St. Antony Community", city: "Rourkela" },
    { id: "joseph", name: "St. Joseph Community", city: "Ranchi" },
  ];
  const result = resolveCommunityReference(
    rows,
    "St Joseph Community Rourkela",
    true,
  );
  assert(
    result.matches.length === 0,
    'conflict could produce "St. Antony Community is recorded as opening in 1965"',
  );
  assert(
    result.conflict,
    "conflicting reference was not marked for clarification",
  );
  assert(
    result.suggestions.length === 1 && result.suggestions[0].id === "antony",
    "the compatible-location suggestion was not preserved",
  );
});

Deno.test("community references allow only unambiguous location-only fallback", () => {
  const single = [
    { id: "antony", name: "St. Antony Community", city: "Rourkela" },
  ];
  for (
    const query of ["the community in Rourkela", "Rourkela community"]
  ) {
    const result = resolveCommunityReference(single, query, true);
    assert(
      result.matches.length === 1 && result.matches[0].id === "antony",
      `${query} did not use safe location-only resolution`,
    );
  }
  const ambiguous = resolveCommunityReference(
    [
      ...single,
      { id: "heart", name: "Sacred Heart Community", city: "Rourkela" },
    ],
    "the community in Rourkela",
    true,
  );
  assert(
    ambiguous.matches.length === 0 && ambiguous.suggestions.length === 2 &&
      !ambiguous.conflict,
    "ambiguous location-only reference selected an arbitrary community",
  );
});

Deno.test("exact community names do not override incompatible locations", () => {
  const rows = [
    { id: "antony", name: "St. Antony Community", city: "Rourkela" },
    { id: "joseph", name: "St. Joseph Community", city: "Ranchi" },
  ];
  const result = resolveCommunityReference(
    rows,
    "St Joseph Community Rourkela",
    true,
  );
  assert(
    result.matches.length === 0 && result.conflict,
    "exact name silently overrode an incompatible location",
  );
});

Deno.test("unknown location qualifiers cannot be ignored for exact names", () => {
  const result = resolveCommunityReference(
    [
      { id: "joseph", name: "St. Joseph Community", city: "Ranchi" },
    ],
    "St Joseph Community Mumbai",
    true,
  );
  assert(
    result.matches.length === 0 && result.conflict &&
      result.suggestions[0]?.id === "joseph",
    "an incompatible unknown location qualifier was ignored",
  );
});

Deno.test("Wave 1 past leadership excludes current and future terms and preserves repeated terms", () => {
  const rows = [
    {
      id: "past-1",
      resolved_office_code: "provincial",
      from_date: "2000-01-01",
      to_date: "2006-12-31",
    },
    {
      id: "past-2",
      resolved_office_code: "provincial",
      from_date: "2012-01-01",
      to_date: "2018-12-31",
    },
    {
      id: "current",
      resolved_office_code: "provincial",
      from_date: "2024-01-01",
      to_date: null,
    },
    {
      id: "other",
      resolved_office_code: "secretary",
      from_date: "2010-01-01",
      to_date: "2015-01-01",
    },
  ];
  const result = filterPastOfficeTerms(rows, "provincial", "2026-08-27");
  assert(
    result.length === 2 && result[0].id === "past-1" &&
      result[1].id === "past-2",
    "past terms were not scoped and ordered correctly",
  );
});

Deno.test("Wave 1 category counts ignore names and report classification coverage", () => {
  const result = countCanonicalMemberCategory([
    { display_name: "Fr Prefix Only", ecclesiastical_title_code: null },
    { display_name: "Joseph", ecclesiastical_title_code: "PRIEST" },
    { display_name: "Thomas", ecclesiastical_title_code: "BROTHER" },
  ], "priest");
  assert(
    result.count === 1 && result.covered === 2,
    "canonical category count or coverage is wrong",
  );
});
