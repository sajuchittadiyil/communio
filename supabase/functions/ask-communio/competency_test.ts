import { interpretAskCommunioQuestion } from "./intent_interpreter.ts";
import type { AskCommunioContext } from "./intent_interpreter.ts";

type CompetencyRow = Record<string, string>;

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

function parseCsv(source: string): CompetencyRow[] {
  const records: string[][] = [];
  let record: string[] = [], field = "", quoted = false;
  for (let index = 0; index < source.length; index++) {
    const character = source[index];
    if (quoted && character === '"' && source[index + 1] === '"') { field += '"'; index++; }
    else if (character === '"') quoted = !quoted;
    else if (character === "," && !quoted) { record.push(field); field = ""; }
    else if ((character === "\n" || character === "\r") && !quoted) {
      if (character === "\r" && source[index + 1] === "\n") index++;
      record.push(field); field = "";
      if (record.some((value) => value.length)) records.push(record);
      record = [];
    } else field += character;
  }
  const [headers, ...rows] = records;
  return rows.map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
}

function contextFor(row: CompetencyRow): AskCommunioContext | undefined {
  if (!row.conversation_id || Number(row.turn_number) === 1) return undefined;
  if (row.conversation_id === "D") return { entity_set_type: "member", entity_set_size: 6, ambiguous_entity_type: "member" };
  if (row.conversation_id === "E") return { entity_set_type: "community", entity_set_size: 2, ambiguous_entity_type: "community" };
  if (row.conversation_id === "A" || row.conversation_id === "F") {
    return { focus_entity_type: "community", focus_entity_id: "benchmark-community", focus_entity_name: "Benchmark Community" };
  }
  return {
    focus_entity_type: "member", focus_entity_id: "benchmark-member", focus_entity_name: "Benchmark Member",
    last_answer_entity_type: "member", last_answer_entity_name: "Benchmark Member",
  };
}

function failuresFor(row: CompetencyRow): string[] {
  if (row.expected_behavior === "KNOWN_GAP") return [];
  const actual = interpretAskCommunioQuestion(row.question, contextFor(row));
  const failures: string[] = [];
  if (actual.intent !== row.expected_intent) failures.push(`intent ${actual.intent} != ${row.expected_intent}`);
  if (row.expected_output_type === "count" && actual.outputType !== "count") failures.push("count output not detected");
  if (row.expected_time_scope) {
    const [from, to] = row.expected_time_scope.split("..").map(Number);
    if (actual.year !== from) failures.push(`year ${actual.year ?? "none"} != ${from}`);
    if (to && actual.yearTo !== to) failures.push(`end year ${actual.yearTo ?? "none"} != ${to}`);
  }
  return failures;
}

Deno.test("Ask Communio competency suite protects P0 parser and context regressions", () => {
  const suiteUrl = new URL("../../../docs/ask_communio_competency_suite.csv", import.meta.url);
  const rows = parseCsv(Deno.readTextFileSync(suiteUrl));
  const failures = rows.flatMap((row) => {
    const reasons = failuresFor(row);
    return reasons.length ? [{ row, reasons }] : [];
  });
  const p0Regressions = failures.filter(({ row }) => row.priority === "P0" && row.expected_behavior !== "KNOWN_GAP");
  const knownGaps = rows.filter((row) => row.expected_behavior === "KNOWN_GAP").length;
  console.log(`ASK COMMUNIO COMPETENCY REPORT: total=${rows.length}, parser_failures=${failures.length}, known_gaps=${knownGaps}, p0_regressions=${p0Regressions.length}`);
  assert(rows.length >= 250 && rows.length <= 300, `expected 250–300 cases, found ${rows.length}`);
  assert(p0Regressions.length === 0, p0Regressions.slice(0, 20).map(({ row, reasons }) => `${row.id} ${row.question}: ${reasons.join("; ")}`).join("\n"));
});

Deno.test("competency conversations cover focus, ambiguity, and unsupported-turn preservation", () => {
  const suiteUrl = new URL("../../../docs/ask_communio_competency_suite.csv", import.meta.url);
  const rows = parseCsv(Deno.readTextFileSync(suiteUrl)).filter((row) => row.conversation_id);
  assert(new Set(rows.map((row) => row.conversation_id)).size === 6, "expected conversations A–F");
  for (const row of rows) {
    const reasons = failuresFor(row);
    assert(reasons.length === 0, `${row.id} conversation ${row.conversation_id}.${row.turn_number}: ${reasons.join("; ")}`);
  }
});
