export type MemberScopedRow = Record<string, unknown>;

export function memberScopedRows(
  rows: MemberScopedRow[],
  memberId: string,
): MemberScopedRow[] {
  return rows.filter((row) => String(row.member_id ?? "") === memberId);
}

export function isCurrentEffectiveRow(
  row: {
    from_date?: unknown;
    start_date?: unknown;
    to_date?: unknown;
    end_date?: unknown;
  },
  isoDate: string,
): boolean {
  const from = String(row.from_date ?? row.start_date ?? "");
  const to = String(row.to_date ?? row.end_date ?? "");
  return (!from || from <= isoDate) && (!to || to >= isoDate);
}

export function canonicalMemberCategory(
  titleCode: unknown,
): "priest" | "brother" | undefined {
  const code = String(titleCode ?? "").toLowerCase().replace(/[^a-z]/g, "");
  if (["priest", "father", "fr", "revfr"].includes(code)) return "priest";
  if (["brother", "bro", "br"].includes(code)) return "brother";
  return undefined;
}
