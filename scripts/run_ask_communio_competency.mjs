import fs from "node:fs";
import { interpretAskCommunioQuestion } from "../supabase/functions/ask-communio/intent_interpreter.ts";

const csvPath = "docs/ask_communio_competency_suite.csv";
const reportPath = "docs/ask_communio_competency_baseline.md";

function parseCsv(source) {
  const records = [];
  let record = [], field = "", quoted = false;
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
  if (field || record.length) { record.push(field); records.push(record); }
  const [headers, ...values] = records;
  return values.map((row) => Object.fromEntries(headers.map((header, index) => [header, row[index] ?? ""])));
}

const normalize = (value) => String(value ?? "").toLowerCase().replaceAll(".", "").replace(/\s+/g, " ").trim();

function contextFor(row) {
  if (!row.conversation_id || Number(row.turn_number) === 1) return undefined;
  if (row.conversation_id === "D") return { entity_set_type: "member", entity_set_size: 6, ambiguous_entity_type: "member" };
  if (row.conversation_id === "E") return { entity_set_type: "community", entity_set_size: 2, ambiguous_entity_type: "community" };
  if (["A", "F"].includes(row.conversation_id)) return { focus_entity_type: "community", focus_entity_id: "benchmark-community", focus_entity_name: "Benchmark Community" };
  return { focus_entity_type: "member", focus_entity_id: "benchmark-member", focus_entity_name: "Benchmark Member", last_answer_entity_type: "member", last_answer_entity_name: "Benchmark Member" };
}

function evaluate(row) {
  if (row.expected_behavior === "KNOWN_GAP") return { status: "known_gap", reasons: [] };
  const actual = interpretAskCommunioQuestion(row.question, contextFor(row));
  const reasons = [];
  if (actual.intent !== row.expected_intent) reasons.push(`intent expected ${row.expected_intent}, got ${actual.intent}`);
  if (row.expected_output_type === "count" && actual.outputType !== "count") reasons.push("count output was not detected");
  if (row.expected_time_scope) {
    const [from, to] = row.expected_time_scope.split("..").map(Number);
    if (actual.year !== from) reasons.push(`year expected ${from}, got ${actual.year ?? "none"}`);
    if (to && actual.yearTo !== to) reasons.push(`end year expected ${to}, got ${actual.yearTo ?? "none"}`);
  }
  if (row.expected_entity_name && actual.entity && !normalize(actual.entity).includes(normalize(row.expected_entity_name))) {
    reasons.push(`entity expected ${row.expected_entity_name}, got ${actual.entity}`);
  }
  return { status: reasons.length ? "failure" : "pass", reasons, actual };
}

const rows = parseCsv(fs.readFileSync(csvPath, "utf8"));
const results = rows.map((row) => ({ row, ...evaluate(row) }));
const knownGaps = results.filter((result) => result.status === "known_gap");
const failures = results.filter((result) => result.status === "failure");
const passes = results.filter((result) => result.status === "pass");
const regressions = failures.filter((result) => result.row.priority === "P0");
const scored = results.filter((result) => result.status !== "known_gap");
const pct = (numerator, denominator) => denominator ? `${(100 * numerator / denominator).toFixed(1)}%` : "n/a";
const escape = (value) => String(value).replaceAll("|", "\\|");

function scoreRows(key, values) {
  return values.map((value) => {
    const subset = results.filter((result) => result.row[key] === value && result.status !== "known_gap");
    return `| ${escape(value)} | ${subset.filter((result) => result.status === "pass").length}/${subset.length} | ${pct(subset.filter((result) => result.status === "pass").length, subset.length)} |`;
  }).join("\n");
}

const behaviorCounts = Object.fromEntries(["PASS", "KNOWN_GAP", "CLARIFY", "ZERO_RESULT", "UNSUPPORTED", "SECURITY_DENY"].map((behavior) => [behavior, rows.filter((row) => row.expected_behavior === behavior).length]));
const behaviorPasses = Object.fromEntries(Object.keys(behaviorCounts).map((behavior) => [behavior, results.filter((result) => result.row.expected_behavior === behavior && result.status === "pass").length]));
const domains = [...new Set(rows.map((row) => row.domain))];
const priorities = ["P0", "P1", "P2"];
const conversationRows = results.filter((result) => result.row.conversation_id);

const report = `# Ask Communio competency baseline

Generated on 2026-08-27 against the current local intent interpreter. This is an honest parser/context baseline, not a live-database certification. Retrieval, RLS, effective-date filtering, answer text, and database-dependent ambiguity/zero-row outcomes require an authenticated integration environment and are recorded as unverified here rather than assumed to pass.

## Summary

- Total cases: ${rows.length}
- Parser/context passing: ${passes.length}
- Known gaps (excluded from score): ${knownGaps.length}
- True parser failures: ${failures.length}
- P0 regression failures: ${regressions.length}
- Scored baseline: ${passes.length}/${scored.length} (${pct(passes.length, scored.length)})
- Conversation parser/context turns: ${conversationRows.filter((result) => result.status === "pass").length}/${conversationRows.length}
- Database-dependent assertions: unverified locally

## Expected-behavior classification

| Classification | Cases | Parser/context passes |
| --- | ---: | ---: |
${Object.keys(behaviorCounts).map((behavior) => `| ${behavior} | ${behaviorCounts[behavior]} | ${behaviorPasses[behavior]} |`).join("\n")}

` + `## Score by domain

| Domain | Passing/scored | Score |
| --- | ---: | ---: |
${scoreRows("domain", domains)}

## Score by priority

| Priority | Passing/scored | Score |
| --- | ---: | ---: |
${scoreRows("priority", priorities)}

## P0 regression failures

${regressions.length ? regressions.map(({ row, reasons }) => `- ${row.id}: “${row.question}” — ${reasons.join("; ")}`).join("\n") : "None at the parser/context layer."}

## Top 20 unsupported capabilities (known gaps)

${knownGaps.slice(0, 20).map(({ row }) => `- ${row.id}: ${row.question} — ${row.notes}`).join("\n")}

## Top 20 parser failures

${failures.slice(0, 20).map(({ row, reasons }) => `- ${row.id} [${row.priority}]: “${row.question}” — ${reasons.join("; ")}`).join("\n") || "None."}

## Top correctness risks

1. This baseline does not execute authenticated database retrieval, so member ownership, RLS, effective dates, current-vs-historical filtering, and result cardinality remain integration risks.
2. Entity ambiguity is partly data-dependent; parser recognition alone cannot prove that candidate clarification is rendered.
3. ZERO_RESULT cases verify that the intent remains recognized, but the selected years/ages must be confirmed against each target database.
4. Natural-language prefix variants expose normalization gaps and can lower the score without indicating a retrieval defect.
5. Tied largest/smallest communities require runtime result-set semantics; synthetic context only verifies follow-up safety.

## Recommended implementation sequence

1. Fix P0 parser regressions while preserving the existing query guards and access policy.
2. Add an authenticated disposable-fixture integration runner for retrieval, RLS, effective dates, and response semantics.
3. Promote high-value P1 known gaps for community/ministry browsing and historical movement queries.
4. Expand runtime ambiguity and tied-ranking fixtures, including conversation focus preservation.
5. Promote qualification vocabulary and compliance reporting only after evidence/provenance rules are specified.
6. Add broader statistical aggregations last; they are useful but less safety-critical than scoping and history.
`;

fs.writeFileSync(reportPath, report);
console.log(JSON.stringify({ total: rows.length, passing: passes.length, knownGaps: knownGaps.length, failures: failures.length, regressions: regressions.length, score: pct(passes.length, scored.length) }, null, 2));
