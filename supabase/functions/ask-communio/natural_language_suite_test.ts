import { interpretAskCommunioQuestion } from "./intent_interpreter.ts";

function assertEquals(
  actual: unknown,
  expected: unknown,
  message: string,
): void {
  if (!Object.is(actual, expected)) {
    throw new Error(
      `${message}: expected ${JSON.stringify(expected)}, got ${
        JSON.stringify(actual)
      }`,
    );
  }
}

Deno.test("separate natural-language suite routes every exploratory phrase", async () => {
  const source = await Deno.readTextFile(
    new URL(
      "../../../docs/ask_communio_natural_language_suite.csv",
      import.meta.url,
    ),
  );
  const [header, ...lines] = source.trim().split("\n");
  const columns = header.split(",");
  assertEquals(lines.length, 63, "exploratory suite size");
  for (const line of lines) {
    const values = line.split(",");
    const row = Object.fromEntries(
      columns.map((column, index) => [column, values[index] ?? ""]),
    );
    const result = interpretAskCommunioQuestion(row.question);
    assertEquals(result.intent, row.expected_intent, `${row.id} intent`);
    if (row.topic) assertEquals(result.topic, row.topic, `${row.id} topic`);
    if (row.output_type) {
      assertEquals(
        result.outputType ?? "records",
        row.output_type,
        `${row.id} output`,
      );
    }
    if (row.age) assertEquals(result.age, Number(row.age), `${row.id} age`);
    if (row.age_to) {
      assertEquals(result.ageTo, Number(row.age_to), `${row.id} age_to`);
    }
    if (row.month) {
      assertEquals(result.month, Number(row.month), `${row.id} month`);
    }
    if (row.anniversary) {
      assertEquals(
        result.anniversary,
        Number(row.anniversary),
        `${row.id} anniversary`,
      );
    }
    if (row.expected_year) {
      const current = new Date().getUTCFullYear();
      const expected = row.expected_year === "NEXT_YEAR"
        ? current + 1
        : row.expected_year === "LAST_YEAR"
        ? current - 1
        : row.expected_year === "THIS_YEAR"
        ? current
        : Number(row.expected_year);
      assertEquals(result.year, expected, `${row.id} year`);
    }
  }
});
