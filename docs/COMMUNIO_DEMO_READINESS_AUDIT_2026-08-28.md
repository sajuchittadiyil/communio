# Communio Demo-Readiness Audit — 2026-08-28

## Executive summary

Communio is functionally strong and visually credible, but it is **not safe to demonstrate against the current Supabase project**. Read-only unauthenticated REST checks using only the public client configuration returned personal and operational data from several legacy `v_demo_*` views. This is a systemic P0 information-disclosure blocker. The login screen and role-aware application navigation do not compensate for backend resources that can be read without authentication.

The application, tests, Ask Communio baseline, web build, and Android debug bundle are otherwise healthy. Safe local P1 fixes made during this audit remove unfinished navigation/actions, correct login wording, strengthen responsive login behavior, replace default web/iOS identity metadata, and avoid an unsupported security claim. No function, migration, schema, data, RLS, or deployment was changed.

**Readiness score: 61/80 (76.25%) — FIX BEFORE DEMO by score; final recommendation: NO-GO because of the P0 security blocker.**

Audit confidence is based on source inspection, automated widget/integration-style tests, build checks, read-only API validation, and unauthenticated Chrome login-screen inspection. An authenticated live rehearsal was not possible without a supplied demo account; authenticated journeys below are therefore test-backed rather than claimed as live-operator verification.

## Finding totals

| Priority | Count | Summary |
|---|---:|---|
| P0 | 1 | Systemic anonymous disclosure through multiple legacy demo views |
| P1 | 3 | Unbranded native splash; release privacy/signing prerequisites; authenticated end-to-end rehearsal still required |
| P2 | 4 | Some metadata-only demo documents; photo coverage not independently verified; initial release version needs deliberate review; a few dense/secondary states merit rehearsal polish |
| P3 | 4 | Edit/admin workflows; advanced reporting; fuller document-management workflow; dead/placeholder splash code and future calendar/help tooling |

Resolved local findings are recorded separately and are not included in the remaining counts.

## Readiness scoring

| Area | Score / 5 | Status | Evidence and findings |
|---|---:|---|---|
| Authentication | 4 | Demo ready with polish | Login is responsive at all requested sizes and 150% text scaling; password visibility, forgot-password, loading/error, session gate and logout paths are implemented/tested. Google placeholder removed and email label corrected. Native splash remains generic. |
| Dashboard | 4 | Demo ready with polish | Responsive dashboard tests, card navigation, Province Pulse and repository mappings are covered. Aggregate demo values are populated. Its legacy read sources must be secured before use. |
| Religious Directory | 4 | Demo ready with polish | Search, filters, responsive scrolling, member count/navigation and accessibility have test coverage. Canonical photo coverage could not be authenticated independently. |
| Religious Profile | 4 | Demo ready with polish | Rich and sparse profiles, family, vocation, qualifications, languages, history, transfers, long timelines and role-safe resolution are covered. |
| Communities | 4 | Demo ready with polish | Sixteen communities were present with superior, accountant and members populated; no duplicate names or zero-member records were found in the audited response. Directory/profile/responsive behavior is tested. |
| Ministries | 4 | Demo ready with polish | Thirty-six ministries were present with type, location, head and member coverage; no duplicate names or stale terminology was found. Representative module behavior is tested. |
| Governance | 4 | Demo ready with polish | Five expected bodies, leadership/membership/history presentation, responsive layouts, accessibility and role exclusion are covered by tests. Authenticated live rehearsal remains required. |
| Organization identity | 4 | Demo ready with polish | Communio, Missionaries of St. Antony and Province identity are consistent in app-facing source. No app-facing Marianist/Marianists/Chaminade leakage was found. |
| Documents | 4 | Demo ready with polish | Ten referenced PDFs exist and parse; list, metadata, mobile and permission-wrapper behavior are tested. Metadata-only items honestly report that the demo file is unavailable. |
| Ask Communio | 5 | Demo ready | Deployed version 39 was already verified at the checkpoint. Frozen competency 291/291, natural-language 63/63 and Edge 93/93 pass; no capability was changed. |
| Calendar/events | 4 | Demo ready with polish | Month/week and event behavior are covered; current scope is suitable for the demo story, with richer meeting workflows remaining future work. |
| Access/security | 1 | Blocked | App role routing and profile/document tests are strong, but anonymous reads from legacy views are a decisive backend-enforcement failure. |
| Responsiveness | 4 | Demo ready with polish | Login now covers 390×844, 430×932, 768×1024, 900×700, 1366×768, 1440×900, 1920×1080 and 150% text scaling. Major module responsive tests pass. |
| Visual consistency | 4 | Demo ready with polish | Typography, cards, colors and hierarchy are coherent. Unfinished actions were removed from presentation surfaces; native launch treatment remains plain. |
| Demo data quality | 4 | Demo ready with polish | Audited aggregates and community/ministry/formation samples showed no duplicate-name, missing-location, missing-leader or impossible-date anomaly. Results came from views that must first be secured. |
| Android readiness | 3 | Usable with obvious weakness | Package/app/icon are configured and a debug AAB builds. Local release signing material and a privacy-policy release reference are absent; native splash remains generic. |
| **Total** | **61/80** | **76.25%** | **NO-GO until P0 is remediated and retested** |

## P0 blocker: anonymous legacy-view disclosure

The following read-only checks were made with the project's publishable client key and no user session. These legacy views returned data:

- `v_demo_member_public_contacts`: 113 rows; mobile, WhatsApp and official email were populated.
- `v_demo_upcoming_birthdays`: names/IDs, dates of birth, next birthdays and turning ages.
- `v_demo_upcoming_feast_days`: member identity and feast details.
- `v_demo_member_attention_events`: identity, notes, status, location and dates.
- `v_demo_formation_pipeline`: identity, date of birth, formation status/house/dates.
- `v_demo_recent_appointments`: identity, role, location and appointment dates.
- `v_demo_current_communities`: community membership, superior and accountant details.
- `v_demo_ministry_operational`: ministry phone, email, notes, head and location.
- `v_demo_province_pulse`: Province aggregate metrics.

The safer resources checked in the same manner correctly rejected anonymous access with PostgreSQL permission error `42501`, including `v_demo_member_directory`, governance/current-office-holder resources, compliance/eligibility views and `province_updates`.

This is one systemic P0, not nine unrelated cosmetic findings. Remediation must review grants/security characteristics for every exposed view, remove anonymous access, preserve intended authenticated role behavior, and repeat the complete unauthenticated matrix. The audit intentionally did not create or deploy a migration.

## Demo-data observations

Read-only aggregate inspection found 113 active members, 16 communities, 36 ministries, 34 people in formation, 11 candidates, 6 novices, 15 temporary professed, 11 birthdays in the next 30 days, no current attention event, and 168 recent appointment rows. These values are useful for rehearsal, but should not be exposed or relied on until the P0 is fixed.

- Communities: 16; no missing superior/accountant, duplicate name or zero-member record in the response.
- Ministries: 36; no missing head/location, zero-religious assignment, duplicate name, or stale Marianist term in the response.
- Formation: 34; no missing house/status, future birth date, or invalid term range in the response.
- Storage root listing returned no objects. That does not prove member photos are absent; authenticated canonical photo resolution was not available to verify.
- Governance migrations/tests describe five bodies, 22 current memberships and seven history entries with chairs populated.

## Module audit notes

### Authentication and presentation

The live Chrome login view was inspected at desktop and narrow/mobile sizes, including browser zoom. Branding and hierarchy are polished and no desktop overflow was visible. Automated coverage now provides a deterministic guard at every requested viewport and 150% text scaling. The login field previously promised username support although validation/auth uses email, and a visible Google action only produced a coming-soon message; both were corrected locally. The security card's unsupported “complete confidentiality” claim was replaced with factual role-aware wording.

### Dashboard, directory, profiles, communities and ministries

The primary Provincial journey is well represented in responsive widget tests. Member taps resolve canonical profile IDs, profile repositories distinguish self/member/community-superior paths, and permission failures are not silently downgraded. Communities and ministries have populated representative data. St. Antony naming is consistent; no establishment date was inferred where absent.

The dashboard repository still consumes some legacy demo views implicated in the P0. After backend remediation, confirm that authenticated dashboard calls still succeed for the Provincial role and fail for anonymous/member roles where appropriate.

### Governance and organization

Governance directory/profile behavior, body types, chairs, current membership, historical terms, responsive layout and accessibility are covered. Member navigation excludes Province-wide governance. Organization/congregation/Province labels and imagery are consistently branded in the full Communio persona.

### Documents and restricted information

All ten referenced local PDF assets exist and were structurally readable. Missing demo binaries use an honest metadata-only state rather than a broken link. Member and Community Superior document visibility is filtered in the client and covered by tests, while backend authorization remains the controlling requirement. Ask Communio's restricted-query suite passes; no wills, digital-safe or private-file capability was added.

### Ask Communio

Ask Communio was audited as the frozen product, not expanded. Its directory, count, history, member, governance, natural-language/entity-resolution and restricted-query competencies remain green: frozen 291/291, natural-language 63/63, Edge 93/93. No Edge Function was changed or deployed during this audit.

### Build, packaging and secret hygiene

- Flutter web release build completed using the local development environment configuration.
- Android debug AAB completed at `build/app/outputs/bundle/debug/app-debug.aab`.
- Android application ID is `com.nilacode.communio`; app name, icon and INTERNET-only permission are appropriate.
- iOS bundle identifiers were locally corrected from the Flutter example identifier to `com.nilacode.communio` (including RunnerTests).
- Web manifest/title/description/colors were locally replaced with Communio identity.
- A release build is intentionally prevented when local `android/key.properties` is absent. No signing material is tracked.
- No token-like secret was found in tracked files. Client publishable configuration remains local/ignored; no secret values are reproduced here.
- Existing untracked Sisters assets, manifests, reports and scripts were excluded from this work and left untouched.
- A public privacy-policy reference and final release version/signing setup are still prerequisites for closed testing.

## Exact demo journey

Because no authenticated demo credentials were used, steps after login are backed by existing tests/source/data inspection rather than a completed live operator rehearsal.

| # | Step | Result | Note |
|---:|---|---|---|
| 1 | Open Communio | PASS | Chrome launch and web build succeeded. |
| 2 | Login as Provincial | PASS WITH POLISH | Login/auth flow is tested; a real Provincial-session rehearsal remains outstanding. |
| 3 | View Province Pulse | PASS WITH POLISH | UI/repository/data are populated; secure the backing legacy view first. |
| 4 | Open a member | PASS | Canonical member navigation is covered. |
| 5 | Show family/origin/vocation/qualifications/languages/timeline | PASS | Rich/sparse profile coverage passes. |
| 6 | Open a community | PASS | Directory-to-profile navigation is covered. |
| 7 | Show community members/history | PASS | Populated lifecycle/member presentation is covered. |
| 8 | Open a ministry | PASS | Representative navigation is covered. |
| 9 | Show assigned members/leadership | PASS | Populated assignment/leadership presentation is covered. |
| 10 | Open Governance | PASS | Provincial route and responsive module tests pass. |
| 11 | Show Education Commission | PASS | Expected body/profile/membership data is covered. |
| 12 | Open Ask Communio | PASS | Stable product route and UI. |
| 13 | Ask current-state question | PASS | Frozen/natural-language suites pass. |
| 14 | Ask historical question | PASS | Frozen history competencies pass. |
| 15 | Ask governance question | PASS | Governance competencies pass. |
| 16 | Ask formal transfer question | PASS | Frozen transfer competencies pass. |
| 17 | Ask restricted question | PASS | Restricted-query tests deny disclosure. |
| 18 | Return to dashboard | PASS | Shell routing is covered. |

**Journey result: PASS WITH POLISH when test-backed, but the presentation remains NO-GO as an environment because the pre-login backend security gate fails.**

## Safe local fixes made

- Removed unfinished Google sign-in and corrected the input label to “Email address.”
- Added mobile/tablet/desktop and 150%-text login regression coverage.
- Made compact login options and mobile wordmarks/emblems responsive under enlarged text.
- Removed blank Reports/Settings destinations and coming-soon Profile/Settings/Notifications/Help presentation actions.
- Replaced an absolute confidentiality claim with factual authenticated/role-aware wording.
- Replaced Flutter-default web metadata and corrected iOS bundle identifiers.
- Removed a stale Android application-ID TODO.

These are local-only presentation/configuration fixes. They require an ordinary future app/web build deployment to reach users, but no database or Edge deployment.

## Remaining findings and recommended order

1. **P0 — Backend enforcement:** inventory all public-schema views/functions, revoke anonymous access to the listed legacy views, preserve least-privilege authenticated grants/RLS, then repeat anonymous/member/superior/Provincial tests.
2. **P1 — Authenticated rehearsal:** use a designated demo Provincial account to perform the exact 18-step journey and validate dashboard calls after the security fix.
3. **P1 — Release prerequisites:** configure recoverable local/CI release signing, approve versioning, and publish/link the required privacy policy before Play closed testing.
4. **P1 — Native launch polish:** replace default Android/iOS launch treatment with the existing Communio brand without redesigning login.
5. **P2 — Content pass:** verify canonical profile-photo URLs with an authenticated role, decide which metadata-only documents belong in the live story, and rehearse the exact sample records/questions.

P3 items should remain outside the pre-demo critical path: edit/admin workflows, advanced reports, a larger archive/DMS, and expanded calendar/help/notification tooling. The unused placeholder splash implementation can be removed in routine cleanup.

## Deployment impact and recommendation

No deployment occurred. The P0 will require an explicitly authorized Supabase authorization change and verification; none was prepared or applied here. The safe UI/configuration fixes need a later application build/deployment only after validation and approval. Ask Communio version 39 and its 291-question frozen capability remain unchanged.

Final local validation:

- `flutter analyze`: no issues.
- `flutter test`: 208/208 passed.
- Ask Communio frozen runner: 291/291, 100%, zero gaps/failures/regressions.
- Ask Communio Edge suite: 93/93 passed, including the separate 63/63 natural-language suite.
- `git diff --check`: clean.
- Flutter web build: passed.
- Android debug AAB build: passed.
- Chrome launch: passed; desktop and narrow login were visually inspected and the process was stopped cleanly.

**Final recommendation: NO-GO.** After the P0 is fixed and the unauthenticated matrix is clean, perform the authenticated 18-step rehearsal. If it passes, the product should move directly to Conditional Go while the native splash and closed-testing prerequisites are completed.

## Post-Security-Remediation Reassessment — 2026-08-29

Migration `202608290001_secure_legacy_demo_views.sql` was applied to project
`spcqxnrdaucxbxkrkqdq` under explicit authorization. All eleven legacy
`v_demo_*` views now reject anonymous REST access with HTTP 401 / PostgreSQL
`42501`. The former P0 anonymous disclosure is closed.

No connected browser, approved live credentials, or reusable authenticated
session was available for this reassessment. In accordance with the audit's
authentication rules, the Provincial, Community Superior, and Member live
smoke tests remain **PENDING**. Existing application, repository, migration,
role-policy, and Ask Communio tests provide partial evidence only.

### Authenticated smoke-test status

| Role | Result | Evidence | Outstanding live proof |
|---|---|---|---|
| Provincial | **PARTIAL** | Province shell/modules, safe Provincial RPC authorization, navigation, profiles, communities, ministries, formation, governance, documents, calendar and Ask Communio tests pass | Login/logout and exact 19-step journey against the migrated environment; specifically verify Pulse, birthdays and appointments |
| Community Superior | **PARTIAL** | Managed-community administration, resident-profile resolution, outsider denial/fallback behavior, navigation restrictions and Ask access policy are covered | Login/logout plus direct cross-community attempts through UI, repository and Ask Communio |
| Ordinary Member | **PARTIAL** | Safe home, self/other profile boundaries, directory-safe Ask intents, navigation restrictions and document restrictions are covered | Login/logout plus direct backend attempts for contacts, governance, private documents, wills and digital-safe themes |

### Post-remediation authorization matrix

`PENDING` means an authenticated live request was not made; it is not a pass.

| Resource | Anonymous | Member | Community Superior | Provincial |
|---|---|---|---|---|
| Legacy `v_demo_*` views | **DENIED — live** | SCOPED by invoker/RLS — static, **PENDING live** | SCOPED by invoker/RLS — static, **PENDING live** | ALLOWED — static, **PENDING live** |
| Safe directory/profile/contact APIs | DENIED | SCOPED — tests pass | SCOPED — tests pass | ALLOWED — tests pass |
| Birthdays/celebrations | Legacy view denied | SCOPED safe celebration projection — tests pass | SCOPED — static, **PENDING live** | ALLOWED — static, **PENDING live** |
| Formation | Legacy view denied | DENIED from Province-wide module — tests/static | DENIED Province-wide — tests/static | ALLOWED through gated RPC — tests, **PENDING live** |
| Appointments/Province Pulse | Legacy views denied | DENIED Province-wide — tests/static | DENIED Province-wide — tests/static | ALLOWED — static, **PENDING live** |
| Communities/ministries | Legacy views denied | SCOPED safe views — tests pass | SCOPED to managed community — tests pass | ALLOWED through gated RPCs — tests, **PENDING live** |
| Governance | DENIED | DENIED Province-wide — tests pass | DENIED unless independently Provincial — tests/static | ALLOWED through gated RPC — tests pass, **PENDING live** |
| Languages/lifecycle/transfers | DENIED | SCOPED by role policies — migration/tests pass | SCOPED by role policies — migration/tests pass | ALLOWED — tests pass |
| Private documents/wills/digital safe | DENIED | DENIED — tests/Ask policy | DENIED — tests/Ask policy | Restricted-query denial remains enforced in Ask Communio |

### Revised scoring

| Area | Score / 5 | Reassessment |
|---|---:|---|
| Authentication | 4 | Automated flows remain healthy; live role logins pending |
| Dashboard | 4 | Strong tests; post-migration authenticated Pulse smoke pending |
| Religious Directory | 4 | Safe Provincial RPC and responsive tests pass |
| Religious Profile | 4 | Role-aware resolvers and rich/sparse profiles pass |
| Communities | 4 | Provincial and superior scoped paths are tested |
| Ministries | 4 | Provincial safe RPC and responsive module tests pass |
| Governance | 4 | Gated RPC, profiles and navigation restrictions pass |
| Organization identity | 4 | Identity remains consistent |
| Documents | 4 | Permission wrappers and restricted behavior pass |
| Ask Communio | 5 | 291/291 frozen, 63/63 natural language, 93/93 Edge |
| Calendar/events | 4 | UI tests pass; authenticated migrated-data smoke pending |
| Access/security | 3 | Anonymous P0 closed; authenticated live matrix still pending |
| Responsiveness | 4 | Requested viewport and accessibility tests pass |
| Visual consistency | 4 | No regression found |
| Demo data quality | 4 | No new defect found; live authenticated sample pending |
| Android readiness | 3 | Debug AAB works; release prerequisites remain |
| **Total** | **63/80** | **78.75% — FIX BEFORE DEMO** |

### Revised recommendation

**FIX BEFORE DEMO**, with no remaining confirmed P0. The exact blocker is now
operational evidence: complete one authenticated Provincial journey and scoped
Member/Superior denial smoke against the migrated environment. If those pass,
the product can move to **CONDITIONAL GO** without waiting for Play signing,
native splash polish, or the future Ministry In-charge role.

- **Blocks the Provincial demo:** authenticated post-migration smoke remains incomplete.
- **Polish before demo:** native splash, selected photos/documents, and rehearsed records/questions.
- **Google Play work that can wait:** release signing, privacy-policy linkage, release version review.
- **Future product development:** Ministry In-charge/Manager, edit/admin expansion, advanced reports and fuller document workflows.
