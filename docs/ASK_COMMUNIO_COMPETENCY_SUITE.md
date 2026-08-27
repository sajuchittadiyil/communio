# Ask Communio Competency Suite

This suite is the permanent natural-language quality and regression benchmark for the main Communio Ask Communio feature. Its CSV is the source of truth. It intentionally includes working behavior, expected clarification, zero-result cases, unsupported requests, and product-roadmap gaps.

## What it tests

The 291 cases cover member/profile lookup, age and demographics, current and historical communities, ministries, leadership, vocation, appointment history, qualifications and eligibility, aggregations, governance, entity resolution, conversations, composed questions, and negative inputs.

The benchmark is split into three verification layers:

1. **Contract layer (Flutter):** validates the CSV schema, size, stable IDs, priority mix, regression anchors, classifications, and conversation fixtures.
2. **Interpreter/context layer (Edge):** executes each scored question through `interpretAskCommunioQuestion`, including synthetic conversation focus and ambiguous-result contexts. Any P0 mismatch fails the build; known gaps do not.
3. **Authenticated integration layer:** must execute the deployed function against a controlled authorized dataset to verify retrieval, RLS, effective dates, current/historical filtering, ambiguity candidates, counts, zero rows, and response claims. The initial local baseline does not pretend this layer ran.

Existing `access_policy_test.ts`, `query_guards_test.ts`, and `semantic_context_test.ts` retain the executable safety invariants for authorization, member-specific row ownership, and evidence-vs-primary-context behavior.

## CSV contract

Each row has a stable ID and semantic expectations rather than a brittle full answer string. The important fields are:

- `domain`, `subdomain`, and `question`: organization and input.
- `conversation_id`, `turn_number`: ordered multi-turn fixtures; blank for standalone cases.
- `expected_intent`, `expected_entity_type`, `expected_entity_name`: routing and scope.
- `expected_output_type`, `expected_time_scope`: count/list shape and year/range extraction.
- `expected_behavior`: `PASS`, `KNOWN_GAP`, `CLARIFY`, `ZERO_RESULT`, `UNSUPPORTED`, or `SECURITY_DENY`.
- `expected_answer_contains`, `expected_answer_not_contains`, result bounds, ambiguity, and zero-result flags: integration-level semantic assertions.
- `priority`: P0 fundamental, P1 important, P2 edge/roadmap.
- `notes`: rationale and current limitations.

`KNOWN_GAP` is deliberately retained and excluded from the regression score. Promote it to `PASS` only when the capability is implemented and covered at the appropriate verification layer. `ZERO_RESULT` means a recognized domain intent returning no rows, never an unsupported request. Eligibility cases are evidence-based rule evaluation, not appointment recommendations.

## Running the suite

From the repository root:

```sh
node scripts/generate_ask_communio_competency.mjs
node --experimental-strip-types scripts/run_ask_communio_competency.mjs
flutter test test/features/ask_communio/ask_communio_competency_test.dart
deno test --allow-read supabase/functions/ask-communio/competency_test.ts
```

The generator is checked in so edits remain reviewable and reproducible; regenerate the CSV after changing it. The baseline runner rewrites `docs/ask_communio_competency_baseline.md` and reports all parser failures while leaving only P0 regressions build-breaking in the Edge test.

If Deno is unavailable locally, use the repository's Node-based Deno test shim with Node's TypeScript stripping enabled, as used for the other Edge tests.

## Adding or changing cases

Add authored cases to `scripts/generate_ask_communio_competency.mjs`, regenerate, and inspect both the CSV diff and baseline. Do not edit generated CSV rows alone. Use database-independent expectations wherever values can change. A database-dependent assertion needs a controlled fixture or a range/semantic assertion, not a copied production answer.

Before promoting a known gap:

- confirm intent, entity, dates, and output type;
- verify authorized retrieval and RLS remain active;
- verify named-member rows all belong to that resolved member;
- verify historical effective dates and current-only filtering;
- exercise ambiguous, tied, zero-result, and follow-up variants;
- regenerate the baseline and run all Ask Communio and Edge tests.

Never change production/demo data, weaken RLS, or relax a safety assertion merely to improve the score.
