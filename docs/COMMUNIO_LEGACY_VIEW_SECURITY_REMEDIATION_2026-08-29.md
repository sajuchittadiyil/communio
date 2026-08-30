# Communio Legacy Reporting-View Security Remediation — 2026-08-29

## Scope and decision

This security-only change prepares a fail-closed authorization correction for every `public.v_demo_*` view known to the repository and live PostgREST schema. It changes no data, Flutter capability, Ask Communio intent, function deployment, or application role.

The minimal design is:

1. Remove all `anon` and inherited `PUBLIC` privileges from all eleven legacy views.
2. Set all eleven views to `security_invoker = true`, preventing view-owner bypass of base-table privileges/RLS.
3. Reduce the `authenticated` view grant to `SELECT` only.
4. Retain caller identity. No Flutter or Edge path receives `service_role` access.
5. Assert the view options and grants inside the migration and provide a post-deployment catalog/role validation script.

The migration was deployed on 2026-08-29 to project
`spcqxnrdaucxbxkrkqdq` after explicit authorization. Supabase reported that
`202608290001_secure_legacy_demo_views.sql` was the only applied migration.

## Complete `v_demo_*` inventory

The original definitions predate the checked-in migration history. Consequently, exact `pg_get_viewdef` text, raw ACL provenance (`anon` directly versus inherited `PUBLIC`), and every transitive source relation must be collected from the live catalog. The supplied validation SQL does that without selecting row data. Source families below are based on checked-in consumers, safe-RPC SQL, exposed columns, and schema dependencies visible in the repository; they must be reconciled with the catalog output before deployment approval.

| View | Current anonymous result | Current invoker state | Effective grants | Known source family | Flutter | Ask Communio | Sensitivity |
|---|---|---|---|---|---|---|---|
| `v_demo_current_communities` | Readable; 16 rows | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | communities, community assignments, members | Dashboard direct; Provincial safe RPC internally | No direct use | Operational membership and leadership |
| `v_demo_current_office_holders` | Denied (`42501`) | Already set invoker by `202608190001` | anon revoked; authenticated SELECT | office appointments/types, members, organizational locations | Dashboard/calendar direct; rollback paths | Direct | Province leadership and appointments |
| `v_demo_formation_pipeline` | Readable; 34 rows | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | members, formation status/assignments/houses | Dashboard direct; Provincial formation/count RPC internally | No direct use | DOB and formation status/location |
| `v_demo_member_attention_events` | Readable; count-only check | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | member attention/event records, members | Dashboard/calendar direct; Provincial profile RPC internally | Direct member-history use | Notes, status, movements and locations |
| `v_demo_member_directory` | Denied (`42501`) | Already set invoker by `202608190001` | anon revoked; authenticated SELECT | members, current community/ministry assignments | Rollback-only Province/profile references | Direct lookup/search | Identity, DOB/status and assignments |
| `v_demo_member_public_contacts` | Readable; 113 rows | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | members and member contacts | Dashboard direct; safe Provincial/member/superior APIs internally | No direct Edge use | Mobile, WhatsApp and official email |
| `v_demo_ministry_operational` | Readable; 36 rows | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | ministries, communities, ministry assignments, members | Dashboard/rollback reference; Provincial safe RPC internally | No direct use | Contact, notes, location, staffing and head |
| `v_demo_province_pulse` | Readable; aggregate row | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | members, communities, ministries, formation/events | Dashboard direct | No direct use | Province-wide operational aggregates |
| `v_demo_recent_appointments` | Readable; 168-row count observed | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | member appointments, members, roles/locations | Dashboard direct | No direct use | Appointment/person/location history |
| `v_demo_upcoming_birthdays` | Readable; 11 next-30-day rows observed | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | members | Dashboard direct | No direct use | DOB, age and identity |
| `v_demo_upcoming_feast_days` | Readable; count-only check | Legacy owner context | anon effective; authenticated expected; PUBLIC provenance pending catalog | members and feast/patron data | Dashboard direct; member-safe celebration view internally | No direct use | Member identity and feast data |

Related reporting interfaces already secured in `202608190001_secure_ask_communio_reporting_views.sql` are `v_member_qualifications_normalized`, `v_member_teaching_qualification_profile`, `v_responsibility_eligibility` and `v_office_eligibility`, together with the two invoker views listed above. Newer member/superior/governance/language/lifecycle/transfer views are explicit scoped interfaces and are not legacy `v_demo_*` targets.

## Why the exposure exists

Nine views retained PostgreSQL's historical view-owner execution behavior and an effective anonymous `SELECT` grant. Their base-table reads therefore ran with the view owner's authority instead of the caller's RLS context. The two views corrected in migration `202608190001` demonstrate the intended pattern: `security_invoker`, no anonymous privilege, and signed-in read access.

## Dependency classification

- **Still required directly:** the dashboard uses all nine currently exposed views plus the two already-secured views. Calendar directly uses office holders, attention events, directory and communities. Ask Communio directly uses attention events, directory and office holders.
- **Still required indirectly:** current Provincial safe RPCs use contacts, attention, ministry operational, formation and related legacy views inside explicit `require_current_provincial_access()` security-definer boundaries.
- **Rollback-only references:** older community/ministry/formation/leadership/profile paths remain in source but active Provincial flows use safe RPCs where the repository switch is permanently true.
- **Safe to drop now:** none. Dropping or revoking authenticated access would break current direct consumers.

## Authorization target and prepared matrix

| Caller | Required result | Pre-deployment/static status | Required post-deployment proof |
|---|---|---|---|
| Anonymous | No `v_demo_*` operational data | **PASS:** all eleven PostgREST requests return HTTP 401 / PostgreSQL `42501` | Continue as a release-gate regression |
| Ordinary Member | Existing member-safe/profile-safe RLS only | Invoker conversion preserves caller and prevents owner bypass; existing role tests pass | Sign in through approved harness and verify no Province-wide rows/contact/DOB/private detail |
| Community Superior | Self plus managed-community RLS only | Invoker conversion preserves caller; existing superior repository/policy tests pass | Verify own/resident/managed-community rows and deny outsiders/Province-wide data |
| Provincial | Complete authorized Province read | Existing direct repositories retain authenticated SELECT; safe RPCs retain explicit Provincial gate | Execute dashboard, directory, profile, communities, ministries, formation, governance, calendar and Ask journey |

Static checks cannot prove live authenticated base-table ACL/RLS behavior. The
Member, Community Superior, and Provincial matrices remain mandatory because no
approved demo credentials or authenticated session were available. If any
ordinary-member or superior request returns broader data, stop demo use and
migrate that consumer to an existing/new caller-authorized RPC.

## Prepared artifacts

- Migration: `supabase/migrations/202608290001_secure_legacy_demo_views.sql`
- Catalog and role matrix: `supabase/validation/validate_legacy_demo_view_security.sql`
- Static regression: `test/features/access/legacy_demo_view_security_migration_test.dart`

## Deployment validation and residual risk

The original nine anonymous exposures are closed: all eleven legacy views now
deny anonymous REST reads with `42501`. Exact origin definitions and transitive
live dependencies are not stored in this repository and can be captured with
the supplied catalog query. Member, Community Superior, and Provincial behavior
cannot yet be marked live-pass until authenticated role validation is completed.
No real credentials were extracted for validation.
