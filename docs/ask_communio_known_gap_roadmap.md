# Ask Communio known-gap roadmap

## Executive summary

**Total known gaps: 80.** The stable parser baseline remains 211/211 scored cases; this roadmap does not change a competency status or implement a capability.

Primary implementation type:

| Type | Cases | Meaning |
| --- | ---: | --- |
| Type 1 — Query only | 29 | Authorized schema/query building blocks already exist. |
| Type 2 — View/RPC required | 31 | Data exists, but a reusable secure reporting boundary or aggregation is preferable. |
| Type 3 — Data-model gap | 9 | The audited schema does not reliably represent the fact or history. |
| Type 4 — UI/format only | 8 | Resolution or validation behavior exists; consistent presentation/integration is missing. |
| Type 5 — Security design required | 3 | Sensitive contact/address access needs an explicit role policy. |

Recommended delivery waves:

| Wave | Cases | Focus |
| --- | ---: | --- |
| Wave 1 | 24 | High-value, low-risk directory, ministry, leadership, and count quick wins. |
| Wave 2 | 20 | Historical community, ministry grouping, office tenure, and appointment reporting. |
| Wave 3 | 16 | Qualifications, eligibility/compliance, private profile facts, and governance modeling. |
| Wave 4 | 20 | Analytics, advanced composition, ambiguous bare input, and incomplete historical models. |

The counts classify each case by its *primary* blocker. Some Type 2 work will also require RLS review, and every new view/RPC must be invoker-safe and limited to authorized rows.

## Capability families

| Family | Cases | Primary types | Recommended direction |
| --- | ---: | --- | --- |
| Member profile and privacy | 9 | 1, 2, 3, 5 | Extend safe profile RPCs; design contact permissions separately. |
| Community directory | 6 | 1 | Add browse/profile executor branches over `communities`. |
| Community history and movement | 12 | 1, 2, 3 | Build effective-date reporting RPCs; add lifecycle dates before open/close claims. |
| Ministry intelligence | 12 | 1, 2 | Reuse `ministries`, operational profiles, and ministry assignments. |
| Leadership and appointment history | 12 | 1, 2 | Reuse office appointments/types; centralize tenure and succession calculations. |
| Qualifications and compliance | 6 | 1, 2 | Extend normalized qualification and eligibility reporting. |
| Statistics and analytics | 7 | 1, 2 | Add bounded aggregate RPCs instead of exposing broad raw tables. |
| Governance bodies | 6 | 3 | Model bodies, memberships, roles, and effective dates first. |
| Entity resolution UX | 4 | 4 | Return candidate/domain clarification for bare names and nouns. |
| Advanced composed queries | 3 | 2 | Compose authorized result IDs, never intermediate unrestricted datasets. |
| Input validation UX | 4 | 4 | Standardize API/client validation responses. |

No current known-gap case requires document or institutional-memory search. That should remain a separate future family built on authorized document metadata and content access, not inferred from these 80 cases.

## Top 10 highest-value capabilities

1. Community directory and community profile.
2. Ministry directory with school/parish/hospital/formation-house filters.
3. Past Provincial and leadership timelines.
4. Community membership history with effective-date counts.
5. Join/leave/transfer reporting derived from assignment intervals.
6. Previous assignment and named-member office tenure.
7. Ministry staffing by type, including education counts.
8. Qualification vocabulary and formation-director eligibility.
9. Appointment compliance reporting with evidence and rule versions.
10. Governance bodies and commission membership history, after modeling.

## Top 10 easiest quick wins

These are verified against existing tables/views or existing executor patterns, not assumed from wording alone:

1. List active communities — `communities.active`.
2. Show a community profile/location — `communities` location fields.
3. Count ministries — `ministries`.
4. List ministries — `ministries`.
5. Filter schools — `ministries` plus ministry type/profile fields.
6. Filter parishes — the same ministry directory path.
7. Show ministry location — `ministries` location fields.
8. Resolve Bursar/Treasurer aliases — `office_types` and `member_office_appointments`.
9. List past Provincials — effective-dated office appointments.
10. Count priests/brothers — active `members` and ecclesiastical/status fields, subject to terminology confirmation.

## Key data-model gaps

- **Community lifecycle:** `communities.active` is not enough to answer “opened/closed in 2015.” Add `opened_on`, `closed_on`, lifecycle reason/status, or an effective-dated `community_lifecycle_events` table.
- **Governance commissions:** add `governance_bodies`, `governance_body_memberships` (`member_id`, role, `from_date`, `to_date`) and optionally body terms/mandates. Commission chairs must be stored as roles, not inferred from row order.
- **Member languages:** add a normalized `languages` reference and `member_languages` join with proficiency and visibility classification.
- **Transfers:** assignment start/end dates can derive likely joins/leaves, but an explicit transfer event or reason/source field is needed if the product must distinguish transfer, temporary absence, closure, and data correction.
- **Succession:** it can be computed from complete non-overlapping office terms, but should not be claimed when appointment history is incomplete or overlapping. A validated reporting RPC is required even if no new table is added.

## Per-case audit

Legend: **Y/P/N** = schema support yes/partial/no. “Missing” identifies the main implementation work: **Q** query/executor, **V** secure view/RPC, **M** model/migration, **F** response/UI formatting, **S** security policy. Complexity and value are LOW/MEDIUM/HIGH.

| ID | Question | Domain / subdomain | Pri | Desired capability | Likely source | Schema | Type | Missing | Complexity | Value | Wave |
| --- | --- | --- | --- | --- | --- | :---: | --- | --- | --- | --- | ---: |
| AC-017 | profile of Joseph Varghese | members / profile | P2 | Safe profile overview | `members`, profile RPCs | Y | 2 | V | MEDIUM | HIGH | 1 |
| AC-018 | Joseph's date of birth | members / profile | P2 | Safe DOB fact | `members.date_of_birth`, profile RPCs | Y | 2 | V | LOW | HIGH | 1 |
| AC-019 | when was Joseph born | members / profile | P2 | DOB phrasing | same as AC-018 | Y | 2 | V | LOW | HIGH | 1 |
| AC-020 | how old is Joseph | members / profile | P2 | Derived current age | `members.date_of_birth` | Y | 2 | V | LOW | HIGH | 1 |
| AC-021 | Joseph's email | members / profile | P2 | Authorized email fact | `member_home_contacts` / safe RPC | Y | 5 | S | MEDIUM | MEDIUM | 3 |
| AC-022 | Joseph's phone | members / profile | P2 | Authorized phone fact | `member_home_contacts` / safe RPC | Y | 5 | S | MEDIUM | MEDIUM | 3 |
| AC-023 | Joseph's address | members / profile | P2 | Authorized address fact | native/home-contact tables | P | 5 | S | MEDIUM | MEDIUM | 3 |
| AC-024 | languages Joseph speaks | members / profile | P2 | Language/proficiency profile | no normalized language relation found | N | 3 | M | HIGH | LOW | 3 |
| AC-025 | Joseph's status | members / profile | P2 | Safe membership status | `members.member_status_code` | Y | 2 | V | LOW | HIGH | 1 |
| AC-065 | list all communities | communities / browse | P2 | Active community directory | `communities` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-066 | show communities | communities / browse | P2 | Community directory alias | `communities` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-067 | where is St Antony Community | communities / browse | P2 | Community location | `communities` location fields | Y | 1 | Q | LOW | HIGH | 1 |
| AC-068 | show St Antony Community | communities / browse | P2 | Community profile | `communities` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-069 | tell me about St Antony Community | communities / browse | P2 | Community summary | `communities` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-070 | list closed communities | communities / browse | P2 | Inactive community list | `communities.active` | P | 1 | Q | LOW | MEDIUM | 2 |
| AC-080 | community membership in 2010 | community / movement | P2 | Clarify scope, then dated roster | `member_community_assignments` | Y | 1 | Q | LOW | MEDIUM | 2 |
| AC-081 | members between 2010 and 2015 | community / movement | P2 | Interval-overlap membership | community assignments | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-082 | who joined in 2015 | community / movement | P2 | Assignment starts in year | community assignments `from_date` | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-083 | who left in 2015 | community / movement | P2 | Assignment ends in year | community assignments `to_date` | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-084 | history of St Antony Community | community / movement | P2 | Community timeline | assignments, superior offices, community | Y | 2 | V | HIGH | HIGH | 2 |
| AC-085 | how many members were there in 2015 | community / movement | P2 | Clarify community/province then count | community assignments | Y | 1 | Q | LOW | MEDIUM | 4 |
| AC-086 | largest community in 2015 | community / movement | P2 | Historical size ranking | communities + assignments | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-087 | community strength in 2010 | community / movement | P2 | Effective-date count | community assignments | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-088 | communities opened in 2015 | community / movement | P2 | Lifecycle starts | no reliable lifecycle dates found | N | 3 | M | HIGH | MEDIUM | 4 |
| AC-089 | communities closed in 2015 | community / movement | P2 | Lifecycle ends | no reliable lifecycle dates found | N | 3 | M | HIGH | MEDIUM | 4 |
| AC-090 | transferred from St Antony in 2015 | community / movement | P2 | Transfer-event report | assignment intervals; transfer reason absent | P | 2 | V | HIGH | HIGH | 2 |
| AC-103 | how many ministries | ministries / browse | P2 | Ministry count | `ministries` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-104 | list all ministries | ministries / browse | P2 | Ministry directory | `ministries` | Y | 1 | Q | LOW | HIGH | 1 |
| AC-105 | list schools | ministries / browse | P2 | Ministry-type filter | `ministries`, operational profiles | Y | 1 | Q | LOW | HIGH | 1 |
| AC-106 | show parishes | ministries / browse | P2 | Ministry-type filter | same ministry sources | Y | 1 | Q | LOW | HIGH | 1 |
| AC-107 | show hospitals | ministries / browse | P2 | Ministry-type filter | same ministry sources | Y | 1 | Q | LOW | MEDIUM | 1 |
| AC-108 | show formation houses | ministries / browse | P2 | Ministry-type filter | ministries / formation data | Y | 1 | Q | LOW | HIGH | 1 |
| AC-109 | members working in schools | ministries / browse | P2 | Current staff by ministry type | ministry assignments + ministries | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-110 | members working in parishes | ministries / browse | P2 | Current staff by ministry type | same assignment join | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-111 | count education-ministry members | ministries / browse | P2 | Distinct current member count | same assignment join | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-112 | where is St Antony School | ministries / browse | P2 | Ministry location | `ministries` location fields | Y | 1 | Q | LOW | HIGH | 1 |
| AC-113 | show active schools | ministries / browse | P2 | Active/type-filtered ministries | `ministries.active` + type | Y | 1 | Q | LOW | HIGH | 1 |
| AC-133 | who is bursar | leadership / advanced | P2 | Current-office alias | office appointments/types | Y | 1 | Q | LOW | HIGH | 1 |
| AC-134 | who is provincial treasurer | leadership / advanced | P2 | Treasurer/Bursar alias | office appointments/types | Y | 1 | Q | LOW | HIGH | 1 |
| AC-135 | list past provincials | leadership / advanced | P2 | Historical office-holder list | office appointments/types | Y | 1 | Q | LOW | HIGH | 1 |
| AC-136 | history of provincials | leadership / advanced | P2 | Provincial timeline | office appointments/types | Y | 1 | Q | LOW | HIGH | 1 |
| AC-137 | who succeeded Thomas Mathew | leadership / advanced | P2 | Validated chronological successor | office appointments/types | P | 2 | V | MEDIUM | HIGH | 2 |
| AC-138 | Joseph's Provincial tenure | leadership / advanced | P2 | Effective-date duration | office appointments/types | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-180 | previous assignment of Joseph | appointments / advanced | P2 | Latest ended assignment | community/ministry/office assignments | Y | 1 | Q | MEDIUM | HIGH | 2 |
| AC-181 | when was Joseph Provincial | appointments / advanced | P2 | Named-member office dates | office appointments/types | Y | 1 | Q | LOW | HIGH | 2 |
| AC-182 | how long was Joseph Provincial | appointments / advanced | P2 | Named-member tenure duration | office appointments/types | Y | 2 | V | MEDIUM | HIGH | 2 |
| AC-183 | appointments before 2010 | appointments / advanced | P2 | Authorized historical filter | office appointments | Y | 2 | V | MEDIUM | MEDIUM | 2 |
| AC-184 | appointments after 2020 | appointments / advanced | P2 | Authorized historical filter | office appointments | Y | 2 | V | MEDIUM | MEDIUM | 2 |
| AC-185 | compare Joseph and Francis | appointments / advanced | P2 | Scoped two-member comparison | appointment sources + safe resolution | Y | 2 | V | HIGH | MEDIUM | 2 |
| AC-197 | theology master's | qualifications / advanced | P2 | Qualification synonym/filter | normalized qualifications view | Y | 1 | Q | LOW | HIGH | 3 |
| AC-198 | formation diploma | qualifications / advanced | P2 | Qualification subject/type filter | normalized qualifications view | Y | 1 | Q | LOW | HIGH | 3 |
| AC-199 | BTh | qualifications / advanced | P2 | Abbreviation normalization | normalized qualifications view | Y | 1 | Q | LOW | HIGH | 3 |
| AC-200 | formation director eligibility | eligibility / advanced | P2 | Explainable eligibility rule | eligibility views | Y | 1 | Q | MEDIUM | HIGH | 3 |
| AC-201 | compliant current appointments | eligibility / advanced | P2 | Appointment-to-rule audit | eligibility views + current appointments | Y | 2 | V | HIGH | HIGH | 3 |
| AC-202 | appointment compliance issues | eligibility / advanced | P2 | Evidence-backed exceptions | same compliance sources | Y | 2 | V | HIGH | HIGH | 3 |
| AC-216 | count priests | statistics / known gap | P2 | Active priest count | `members` title/status fields | Y | 1 | Q | LOW | HIGH | 1 |
| AC-217 | count brothers | statistics / known gap | P2 | Active brother count | `members` title/status fields | Y | 1 | Q | LOW | HIGH | 1 |
| AC-218 | communities under five members | statistics / known gap | P2 | Current grouped threshold | communities + assignments | Y | 2 | V | MEDIUM | HIGH | 4 |
| AC-219 | average member age | statistics / known gap | P2 | DOB aggregate | active members DOB | Y | 1 | Q | LOW | MEDIUM | 4 |
| AC-220 | age distribution | statistics / known gap | P2 | Defined age bands | active members DOB | Y | 2 | V | MEDIUM | MEDIUM | 4 |
| AC-221 | median age | statistics / known gap | P2 | Median DOB/age aggregate | active members DOB | Y | 2 | V | MEDIUM | LOW | 4 |
| AC-222 | members by state | statistics / known gap | P2 | Origin-state grouping | native details + members | Y | 2 | V | MEDIUM | MEDIUM | 4 |
| AC-227 | list governance bodies | governance / bodies | P2 | Body directory | no body relation found | N | 3 | M | HIGH | HIGH | 3 |
| AC-228 | show governance bodies | governance / bodies | P2 | Body directory alias | no body relation found | N | 3 | M | HIGH | HIGH | 3 |
| AC-229 | education commission members | governance / bodies | P2 | Effective-dated membership | new governance membership model | N | 3 | M | HIGH | HIGH | 3 |
| AC-230 | finance commission members | governance / bodies | P2 | Effective-dated membership | new governance membership model | N | 3 | M | HIGH | HIGH | 3 |
| AC-231 | sustainability commission members | governance / bodies | P2 | Effective-dated membership | new governance membership model | N | 3 | M | HIGH | MEDIUM | 3 |
| AC-232 | education commission chair | governance / bodies | P2 | Stored chair role and term | new governance membership model | N | 3 | M | HIGH | HIGH | 3 |
| AC-245 | St Antony | entity resolution / malformed | P2 | Candidate/domain clarification | existing entity resolvers | Y | 4 | F | MEDIUM | MEDIUM | 4 |
| AC-246 | Joseph | entity resolution / malformed | P2 | Member candidate clarification | member directory/resolver | Y | 4 | F | MEDIUM | HIGH | 4 |
| AC-247 | community | entity resolution / malformed | P2 | Missing-entity clarification | interpreter/UI | Y | 4 | F | LOW | LOW | 4 |
| AC-248 | member | entity resolution / malformed | P2 | Missing-name clarification | interpreter/UI | Y | 4 | F | LOW | LOW | 4 |
| AC-273 | largest community in 2015 | composed / temporal | P1 | Historical ranking | assignments + communities | Y | 2 | V | MEDIUM | HIGH | 4 |
| AC-274 | location of largest-community superior | composed / advanced | P2 | Authorized nested lookup | ranking + superior + member location | Y | 2 | V | HIGH | MEDIUM | 4 |
| AC-275 | age of largest-community superior | composed / advanced | P2 | Authorized nested profile fact | ranking + superior + safe DOB | Y | 2 | V | HIGH | LOW | 4 |
| AC-276 | ministry with most members | ministries / composed | P2 | Current ministry ranking | ministries + assignments | Y | 2 | V | MEDIUM | MEDIUM | 4 |
| AC-288 | empty input | negative / validation | P2 | Consistent validation response | API/client validation | Y | 4 | F | LOW | LOW | 4 |
| AC-289 | `?` | negative / validation | P2 | Punctuation-only validation | API/client validation | Y | 4 | F | LOW | LOW | 4 |
| AC-290 | `..` | negative / validation | P2 | Punctuation-only validation | API/client validation | Y | 4 | F | LOW | LOW | 4 |
| AC-291 | `a` | negative / validation | P2 | Too-short input validation | API/client validation | Y | 4 | F | LOW | LOW | 4 |

## Wave acceptance gates

Every wave should begin by promoting only its implemented cases from `KNOWN_GAP` to semantic expectations. Required gates remain: P0 60/60, all previously scored cases passing, conversation 18/18, zero-result distinct from unsupported, ambiguity never guessed, member-owned records scoped to the resolved member, effective dates honored, and RLS/access-policy tests active.

Wave 2 reporting views/RPCs should be designed before parser additions. Wave 3 compliance output must show the rule and evidence used and must not become an automated appointment recommendation. Wave 4 historical/composed work must pass only authorized entity IDs between stages; intermediate evidence must not redefine conversation focus.

## Audit basis and limitations

This roadmap was derived from the 80 CSV rows, the current Edge executor, repository migrations, safe views/RPCs, and references to the linked schema. Relevant existing sources include `members`, `member_home_contacts`, `member_native_details`, `communities`, `member_community_assignments`, `ministries`, `ministry_operational_profiles`, `member_ministry_assignments`, `member_office_appointments`, `office_types`, `member_qualifications`, `v_member_qualifications_normalized`, `v_office_eligibility`, and `v_responsibility_eligibility`.

“Schema support” means the audited structure appears capable of representing the answer; it does not certify data completeness. The linked REST OpenAPI endpoint did not permit anonymous schema enumeration with the configured publishable key, so conclusions are intentionally conservative and based on checked-in migrations plus the deployed function's current table/view usage. No data or RLS policy was changed.
