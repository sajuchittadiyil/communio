export type Wave2Row = Record<string, unknown>;

const value = (row: Wave2Row, ...keys: string[]): string => {
  for (const key of keys) if (row[key] != null && String(row[key]).trim()) return String(row[key]).slice(0, 10);
  return "";
};

export function overlapsYear(row: Wave2Row, year: number): boolean {
  const start = value(row, "from_date", "start_date");
  const end = value(row, "to_date", "end_date");
  return (!start || start <= `${year}-12-31`) && (!end || end >= `${year}-01-01`);
}

export function startsOrEndsInYear(row: Wave2Row, year: number, boundary: "started" | "ended"): boolean {
  const date = boundary === "started" ? value(row, "from_date", "start_date") : value(row, "to_date", "end_date");
  return date >= `${year}-01-01` && date <= `${year}-12-31`;
}

export function uniqueMemberRows(rows: Wave2Row[]): Wave2Row[] {
  const seen = new Set<string>();
  return rows.filter((row) => {
    const id = String(row.member_id ?? row.id ?? "");
    if (!id || seen.has(id)) return false;
    seen.add(id);
    return true;
  });
}

export function durationLabel(row: Wave2Row, through = new Date()): string {
  const startText = value(row, "from_date", "start_date");
  if (!startText) return "duration unavailable";
  const endText = value(row, "to_date", "end_date");
  const start = new Date(`${startText}T00:00:00Z`);
  const end = endText ? new Date(`${endText}T00:00:00Z`) : new Date(through.getTime());
  // Stored appointment end dates are inclusive: a June 30 end means the
  // member served through that day. Convert completed terms to an exclusive
  // boundary before calculating calendar components.
  if (endText) end.setUTCDate(end.getUTCDate() + 1);
  let years = end.getUTCFullYear() - start.getUTCFullYear();
  let months = end.getUTCMonth() - start.getUTCMonth();
  let days = end.getUTCDate() - start.getUTCDate();
  if (days < 0) {
    months -= 1;
    days += new Date(Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), 0)).getUTCDate();
  }
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  if (years < 0) {
    years = 0;
    months = 0;
  }
  return [years ? `${years} year${years === 1 ? "" : "s"}` : "", months ? `${months} month${months === 1 ? "" : "s"}` : "", days ? `${days} day${days === 1 ? "" : "s"}` : ""].filter(Boolean).join(" ") || "less than one day";
}

export function historicalAssignmentEmptyMessage(kind: "community" | "ministry", name: string, year: number, superiorOnly = false): string {
  if (kind === "community" && superiorOnly) return `I found no recorded Community Superior appointment for ${name} covering ${year}.`;
  return `I found no recorded members in ${name} in ${year}.`;
}
