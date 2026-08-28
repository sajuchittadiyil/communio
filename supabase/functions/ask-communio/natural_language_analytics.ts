export function ageInInclusiveRange(
  actualAge: number,
  first: number,
  second: number,
): boolean {
  return actualAge >= Math.min(first, second) &&
    actualAge <= Math.max(first, second);
}

export function birthdayMatchesMonth(
  dateOfBirth: string,
  month: number,
): boolean {
  return month >= 1 && month <= 12 &&
    Number(dateOfBirth.slice(5, 7)) === month;
}

export function professionYearForAnniversary(
  targetYear: number,
  anniversary: number,
): number {
  return targetYear - anniversary;
}

export function ordinalNumber(value: number): string {
  const remainder100 = value % 100;
  const suffix = remainder100 >= 11 && remainder100 <= 13
    ? "th"
    : value % 10 === 1
    ? "st"
    : value % 10 === 2
    ? "nd"
    : value % 10 === 3
    ? "rd"
    : "th";
  return `${value}${suffix}`;
}
