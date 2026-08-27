export type Wave4Row = Record<string, unknown>;

const value = (row: Wave4Row, key: string): string =>
  row[key] == null ? "" : String(row[key]).trim();

export function ageOnUtcDate(dateOfBirth: string, reference: Date): number {
  const [year, month, day] = dateOfBirth.slice(0, 10).split("-").map(Number);
  let age = reference.getUTCFullYear() - year;
  if (
    reference.getUTCMonth() + 1 < month ||
    (reference.getUTCMonth() + 1 === month && reference.getUTCDate() < day)
  ) age--;
  return age;
}

export function ageSummary(rows: Wave4Row[], reference: Date) {
  const ages = rows.map((row) =>
    ageOnUtcDate(value(row, "date_of_birth"), reference)
  ).filter((age) => Number.isFinite(age) && age >= 0).sort((a, b) => a - b);
  const average = ages.length
    ? ages.reduce((sum, age) => sum + age, 0) / ages.length
    : undefined;
  const middle = Math.floor(ages.length / 2);
  const median = ages.length
    ? ages.length % 2 ? ages[middle] : (ages[middle - 1] + ages[middle]) / 2
    : undefined;
  const bands = [
    { label: "Under 40", minimum: 0, maximum: 39 },
    { label: "40–59", minimum: 40, maximum: 59 },
    { label: "60–79", minimum: 60, maximum: 79 },
    { label: "80+", minimum: 80, maximum: Number.POSITIVE_INFINITY },
  ].map((band) => ({
    band: band.label,
    count:
      ages.filter((age) => age >= band.minimum && age <= band.maximum).length,
  }));
  return { ages, average, median, bands };
}

export function distinctActiveCounts(
  assignments: Wave4Row[],
  targetKey: string,
  activeTargetIds: Set<string>,
  activeMemberIds: Set<string>,
  isCurrent: (row: Wave4Row) => boolean,
) {
  const membersByTarget = new Map<string, Set<string>>(
    [...activeTargetIds].map((id) => [id, new Set<string>()]),
  );
  for (const row of assignments) {
    const targetId = value(row, targetKey);
    const memberId = value(row, "member_id");
    if (
      membersByTarget.has(targetId) && activeMemberIds.has(memberId) &&
      isCurrent(row)
    ) membersByTarget.get(targetId)!.add(memberId);
  }
  return new Map(
    [...membersByTarget].map(([id, members]) => [id, members.size]),
  );
}
