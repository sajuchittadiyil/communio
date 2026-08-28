import { canonicalMemberCategory } from "./query_guards.ts";

export type Wave1Row = Record<string, unknown>;

export type CommunityReferenceResolution = {
  matches: Wave1Row[];
  suggestions: Wave1Row[];
  conflict: boolean;
  location?: string;
};

const value = (row: Wave1Row, ...keys: string[]): string => {
  for (const key of keys) {
    if (row[key] != null && String(row[key]).trim()) {
      return String(row[key]).trim();
    }
  }
  return "";
};
const normalize = (input: string): string =>
  input.toLowerCase().replace(/[‐‑‒–—−,._-]+/g, " ").replace(/[^a-z0-9 ]/g, "")
    .replace(/\bkolkota\b/g, "kolkata").replace(/\s+/g, " ").trim();

const normalizedEntity = (input: string): string =>
  normalize(input).replace(/\bin\b/g, " ").replace(/\s+/g, " ").trim();

export function matchingDirectoryRows(
  rows: Wave1Row[],
  entity: string,
  kind: "community" | "ministry",
): Wave1Row[] {
  const withoutKind = (input: string): string =>
    input.replace(new RegExp(`\\b${kind}\\b`, "g"), " ").replace(/\s+/g, " ")
      .trim();
  const needle = withoutKind(normalizedEntity(entity));
  const candidates = rows.map((row) => {
    const name = value(
      row,
      kind === "community" ? "name" : "ministry_name",
      `${kind}_name`,
      "name",
    );
    const normalizedName = withoutKind(normalizedEntity(name));
    return { row, normalizedName };
  });
  const partial = candidates.filter(({ normalizedName }) =>
    normalizedName.includes(needle) || needle.includes(normalizedName)
  );
  const exact = partial.filter(({ normalizedName }) =>
    normalizedName === needle
  );
  if (exact.length) {
    const hasQualifiedSibling = exact.length === 1 &&
      partial.some(({ normalizedName }) =>
        normalizedName.startsWith(`${exact[0].normalizedName} `)
      );
    return (hasQualifiedSibling ? partial : exact).map(({ row }) => row);
  }
  const qualified = candidates.filter(({ row, normalizedName }) => {
    const locations = [
      value(row, "city", "location_city"),
      value(row, "district"),
      value(row, "state"),
    ].map(normalize).filter(Boolean);
    return locations.some((location) =>
      needle === `${normalizedName} ${location}` ||
      needle.startsWith(`${normalizedName} `) &&
        needle.slice(normalizedName.length + 1) === location
    );
  });
  if (qualified.length) return qualified.map(({ row }) => row);
  return partial.map(({ row }) => row);
}

export function resolveCommunityReference(
  rows: Wave1Row[],
  entity: string,
  allowLocationOnly = false,
): CommunityReferenceResolution {
  const normalized = normalize(entity);
  const locations = [
    ...new Set(rows.flatMap((row) =>
      [
        value(row, "city", "location_city"),
        value(row, "district"),
        value(row, "state"),
      ].map(normalize).filter(Boolean)
    )),
  ].sort((a, b) => b.length - a.length);
  const location = locations.find((candidate) =>
    new RegExp(`(?:^| )${escapeRegExp(candidate)}(?: |$)`).test(normalized)
  );
  const communityIndex = normalized.indexOf(" community");
  const beginsWithCommunity = normalized === "community" ||
    normalized.startsWith("community ");
  const suffix = beginsWithCommunity
    ? normalized.slice("community".length).replace(/^ in /, "").trim()
    : communityIndex >= 0
    ? normalized.slice(communityIndex + " community".length).replace(
      /^ in /,
      "",
    ).trim()
    : "";
  const requestedLocation = (location ?? suffix) || undefined;
  const locationMatches = requestedLocation
    ? rows.filter((row) =>
      [
        value(row, "city", "location_city"),
        value(row, "district"),
        value(row, "state"),
      ].some((candidate) => normalize(candidate) === requestedLocation)
    )
    : [];
  const meaningfulName = normalized
    .replace(
      requestedLocation
        ? new RegExp(`\\b${escapeRegExp(requestedLocation)}\\b`, "g")
        : /$^/,
      " ",
    )
    .replace(/\b(?:the|in|at|community|house|residence)\b/g, " ")
    .replace(/\s+/g, " ").trim();

  if (!meaningfulName) {
    return {
      matches: allowLocationOnly && locationMatches.length === 1
        ? locationMatches
        : [],
      suggestions: locationMatches,
      conflict: false,
      location: requestedLocation,
    };
  }

  const namedMatches = rows.filter((row) => {
    const name = normalize(value(row, "name", "community_name"))
      .replace(/\b(?:community|house|residence)\b/g, " ")
      .replace(/\s+/g, " ").trim();
    return name === meaningfulName || name.includes(meaningfulName) ||
      meaningfulName.includes(name);
  });
  if (!requestedLocation) {
    return {
      matches: matchingDirectoryRows(rows, entity, "community"),
      suggestions: [],
      conflict: false,
    };
  }
  const compatible = namedMatches.filter((row) =>
    locationMatches.includes(row)
  );
  if (compatible.length) {
    return {
      matches: compatible,
      suggestions: [],
      conflict: false,
      location: requestedLocation,
    };
  }
  return {
    matches: [],
    suggestions: locationMatches.length ? locationMatches : namedMatches,
    conflict: namedMatches.length > 0 || locationMatches.length > 0,
    location: requestedLocation,
  };
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function filterMinistryTypeRows(
  rows: Wave1Row[],
  requested: string,
): Wave1Row[] {
  if (requested === "all") return rows;
  const aliases: Record<string, string[]> = {
    school: ["school", "education", "educational institution"],
    parish: ["parish", "pastoral"],
    hospital: ["hospital", "health", "healthcare"],
    formation_house: ["formation house", "formation", "novitiate", "seminary"],
    retreat_centre: ["retreat centre", "retreat center", "retreat"],
    old_age_home: ["old age home", "elder care", "senior care"],
  };
  return rows.filter((row) => {
    const actual = normalize(
      value(row, "ministry_type", "ministry_type_code", "type_code"),
    );
    return (aliases[requested] ?? [requested.replaceAll("_", " ")]).some((
      alias,
    ) => actual.includes(alias));
  });
}

export function filterPastOfficeTerms(
  rows: Wave1Row[],
  requestedRole: string,
  isoDate: string,
): Wave1Row[] {
  const requested = normalize(requestedRole);
  return rows.filter((row) => {
    const role = normalize(
      value(row, "resolved_office_code", "office_type_code", "office_code"),
    );
    const from = value(row, "from_date", "start_date");
    const to = value(row, "to_date", "end_date");
    return role === requested && (!from || from <= isoDate) &&
      Boolean(to && to < isoDate);
  }).sort((a, b) =>
    value(a, "from_date", "start_date").localeCompare(
      value(b, "from_date", "start_date"),
    )
  );
}

export function countCanonicalMemberCategory(
  rows: Wave1Row[],
  category: "priest" | "brother",
): { count: number; covered: number } {
  const classified = rows.map((row) =>
    canonicalMemberCategory(
      value(row, "ecclesiastical_title_code", "title_code"),
    )
  );
  return {
    count: classified.filter((item) => item === category).length,
    covered: classified.filter(Boolean).length,
  };
}
