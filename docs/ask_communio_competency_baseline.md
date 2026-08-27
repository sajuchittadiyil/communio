# Ask Communio competency baseline

Generated on 2026-08-27 against the current local intent interpreter. This is an honest parser/context baseline, not a live-database certification. Retrieval, RLS, effective-date filtering, answer text, and database-dependent ambiguity/zero-row outcomes require an authenticated integration environment and are recorded as unverified here rather than assumed to pass.

## Summary

- Total cases: 291
- Parser/context passing: 281
- Known gaps (excluded from score): 10
- True parser failures: 0
- P0 regression failures: 0
- Scored baseline: 281/281 (100.0%)
- Conversation parser/context turns: 18/18
- Database-dependent assertions: unverified locally

## Expected-behavior classification

| Classification | Cases | Parser/context passes |
| --- | ---: | ---: |
| PASS | 249 | 249 |
| KNOWN_GAP | 10 | 0 |
| CLARIFY | 15 | 15 |
| ZERO_RESULT | 3 | 3 |
| UNSUPPORTED | 14 | 14 |
| SECURITY_DENY | 0 | 0 |

## Score by domain

| Domain | Passing/scored | Score |
| --- | ---: | ---: |
| members | 24/24 | 100.0% |
| age_demographics | 20/20 | 100.0% |
| current_communities | 25/25 | 100.0% |
| historical_community | 17/17 | 100.0% |
| ministries | 23/23 | 100.0% |
| leadership | 25/25 | 100.0% |
| vocation | 27/27 | 100.0% |
| appointment_history | 20/20 | 100.0% |
| qualifications_eligibility | 17/17 | 100.0% |
| aggregations | 20/20 | 100.0% |
| governance | 4/4 | 100.0% |
| entity_resolution | 16/16 | 100.0% |
| conversation | 18/18 | 100.0% |
| composed_queries | 10/10 | 100.0% |
| negative | 15/15 | 100.0% |

## Score by priority

| Priority | Passing/scored | Score |
| --- | ---: | ---: |
| P0 | 60/60 | 100.0% |
| P1 | 151/151 | 100.0% |
| P2 | 70/70 | 100.0% |

## P0 regression failures

None at the parser/context layer.

## Top 20 unsupported capabilities (known gaps)

- AC-024: what languages does Joseph Varghese speak — No normalized member-language relation or proficiency model
- AC-088: communities opened in 2015 — Lifecycle/explicit transfer semantics are not reliably stored
- AC-089: communities closed in 2015 — Lifecycle/explicit transfer semantics are not reliably stored
- AC-090: who transferred from St Antony Community in 2015 — Lifecycle/explicit transfer semantics are not reliably stored
- AC-227: list governance bodies — Governance body schema not exposed to Ask Communio
- AC-228: show governance bodies — Governance body schema not exposed to Ask Communio
- AC-229: who belongs to education commission — Governance body schema not exposed to Ask Communio
- AC-230: who belongs to finance commission — Governance body schema not exposed to Ask Communio
- AC-231: members of sustainability commission — Governance body schema not exposed to Ask Communio
- AC-232: who chaired the education commission — Governance body schema not exposed to Ask Communio

## Top 20 parser failures

None.

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
