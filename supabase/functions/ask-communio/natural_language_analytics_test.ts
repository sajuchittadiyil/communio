import {
  ageInInclusiveRange,
  birthdayMatchesMonth,
  ordinalNumber,
  professionYearForAnniversary,
} from "./natural_language_analytics.ts";

function assert(value: boolean, message: string): void {
  if (!value) throw new Error(message);
}

Deno.test("natural age ranges are inclusive and normalize reversed endpoints", () => {
  assert(ageInInclusiveRange(55, 55, 60), "lower boundary was excluded");
  assert(ageInInclusiveRange(60, 55, 60), "upper boundary was excluded");
  assert(ageInInclusiveRange(57, 60, 55), "reversed range was not normalized");
  assert(!ageInInclusiveRange(61, 55, 60), "out-of-range age was included");
});

Deno.test("birthday month matching ignores birth year", () => {
  assert(birthdayMatchesMonth("1970-09-08", 9), "September did not match");
  assert(birthdayMatchesMonth("2001-09-21", 9), "birth year affected match");
  assert(!birthdayMatchesMonth("1970-08-08", 9), "August matched September");
  assert(!birthdayMatchesMonth("1970-09-08", 13), "invalid month matched");
});

Deno.test("vocation anniversaries derive the canonical profession year", () => {
  assert(
    professionYearForAnniversary(2027, 10) === 2017,
    "10th anniversary year was wrong",
  );
  assert(
    professionYearForAnniversary(2030, 25) === 2005,
    "25th anniversary year was wrong",
  );
  assert(ordinalNumber(11) === "11th", "11th ordinal was wrong");
  assert(ordinalNumber(25) === "25th", "25th ordinal was wrong");
});
