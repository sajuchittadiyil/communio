export type GovernanceRow = Record<string, unknown>;

export type GovernanceResolution =
  | { kind: "match"; row: GovernanceRow }
  | { kind: "ambiguous"; rows: GovernanceRow[] }
  | { kind: "missing" };

export function normalizeGovernanceName(value: unknown): string {
  return String(value ?? "").toLowerCase()
    .replace(/[’']/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\bcommittee\b/g, "commission")
    .replace(/\s+/g, " ");
}

export function resolveGovernanceBody(
  rows: GovernanceRow[],
  query: string,
): GovernanceResolution {
  const needle = normalizeGovernanceName(query);
  if (!needle) return { kind: "missing" };
  const names = (row: GovernanceRow) =>
    [
      row.governance_body_id,
      row.id,
      row.name,
      row.short_name,
      row.code,
    ].map(normalizeGovernanceName).filter(Boolean);
  const exact = rows.filter((row) => names(row).includes(needle));
  if (exact.length === 1) return { kind: "match", row: exact[0] };
  if (exact.length > 1) return { kind: "ambiguous", rows: exact };
  const partial = rows.filter((row) =>
    names(row).some((name) => name.includes(needle) || needle.includes(name))
  );
  if (partial.length === 1) return { kind: "match", row: partial[0] };
  return partial.length > 1
    ? { kind: "ambiguous", rows: partial }
    : { kind: "missing" };
}

export function orderGovernanceMembers(rows: GovernanceRow[]): GovernanceRow[] {
  const priority = (row: GovernanceRow) => {
    switch (String(row.role_code ?? "").toUpperCase()) {
      case "CHAIR":
        return 0;
      case "PRESIDENT":
        return 1;
      case "SECRETARY":
        return 2;
      case "TREASURER":
        return 3;
      case "EX_OFFICIO":
        return 4;
      default:
        return 5;
    }
  };
  return [...rows].sort((first, second) =>
    priority(first) - priority(second) ||
    String(first.display_name ?? "").localeCompare(
      String(second.display_name ?? ""),
    )
  );
}

export function governanceLeaders(rows: GovernanceRow[]): GovernanceRow[] {
  return orderGovernanceMembers(rows).filter((row) =>
    ["CHAIR", "PRESIDENT"].includes(
      String(row.role_code ?? "").toUpperCase(),
    )
  );
}
