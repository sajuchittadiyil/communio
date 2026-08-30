# Communio Live Demo Checklist

Use this checklist immediately before a Provincial/Provincial Council presentation.

## Compact pre-demo smoke

- [ ] Provincial test login works and logout has been checked.
- [ ] Supabase is reachable from the presentation browser/device.
- [ ] Province Pulse, birthdays and appointments load.
- [ ] The rehearsed sample member and full profile load.
- [ ] The rehearsed sample community and member/history sections load.
- [ ] The rehearsed sample ministry and leadership/assignment sections load.
- [ ] Governance and Education Commission load.
- [ ] Ask Communio current, historical, governance and transfer questions pass.
- [ ] The restricted/private-document question is denied safely.
- [ ] Selected profile photos resolve or use the approved fallback.
- [ ] Presentation browser/device, zoom, network and screen sharing are ready.
- [ ] Backup demo questions and reviewed fallback screenshots are ready.

## Mandatory release gate

- [ ] Anonymous REST checks return permission errors/no rows for every private `v_demo_*` view, especially contacts, birthdays, feast days, attention, formation, appointments, communities, ministries and Province Pulse.
- [ ] Provincial access still works after the authorization fix.
- [ ] Ordinary Member and Community Superior backend scope has been retested, not merely hidden in navigation.
- [ ] A designated demo account is available; no real credential is shared in notes or screen recordings.
- [ ] The exact 18-step journey below has been completed once against the presentation environment.

Do not present if any mandatory gate is unchecked.

## Environment and device

- [ ] Correct Supabase project/environment is selected; no production mutation tools are open.
- [ ] Stable network and power are available; browser notifications and unrelated tabs are closed.
- [ ] Communio opens without a blank transition, console-visible error or overflow.
- [ ] Display resolution/zoom is rehearsed (recommended 1366×768 or higher at 100%).
- [ ] Mobile/tablet backup view has been sanity-checked if it will be shown.
- [ ] Screen sharing reveals no terminal, environment file, secret, personal notification or unrelated Sisters asset.
- [ ] A fallback screenshot/video is available for network failure, with sensitive data reviewed.

## Content and data

- [ ] Province Pulse counts are plausible and match the approved demo dataset.
- [ ] Selected member has family, vocation, qualifications, languages and timeline content suitable for presentation.
- [ ] Selected community has populated members, leadership and lifecycle/history.
- [ ] Selected ministry has populated location, community, head and assigned members.
- [ ] Education Commission has chair/current members/history ready to show.
- [ ] Profile photos resolve for selected records, or the chosen records intentionally use the approved fallback.
- [ ] Every document intended to be opened has a valid demo PDF; metadata-only items are not selected accidentally.
- [ ] No selected record contains placeholder, private, contradictory or unapproved narrative content.

## Ask Communio

- [ ] Deployed function/version is the approved checkpoint (version 39 unless a later version is separately approved).
- [ ] Frozen competency is 291/291, natural-language suite is 63/63 and Edge suite is 93/93.
- [ ] Rehearsed current-state question returns concise correct evidence.
- [ ] Rehearsed historical question returns the intended record/year.
- [ ] Rehearsed governance question opens the intended body/member.
- [ ] Rehearsed formal-transfer question returns the intended timeline.
- [ ] Restricted wills/digital-safe/private-file question is denied safely.
- [ ] No experimental question is improvised during the presentation.

## Exact presentation journey

- [ ] 1. Open Communio.
- [ ] 2. Log in as Provincial.
- [ ] 3. View Province Pulse.
- [ ] 4. Open the rehearsed member.
- [ ] 5. Show family, origin, vocation, qualifications, languages and timeline.
- [ ] 6. Open the rehearsed community.
- [ ] 7. Show community members and history.
- [ ] 8. Open the rehearsed ministry.
- [ ] 9. Show assigned members and leadership.
- [ ] 10. Open Governance.
- [ ] 11. Show Education Commission.
- [ ] 12. Open Ask Communio.
- [ ] 13. Ask the rehearsed current-state question.
- [ ] 14. Ask the rehearsed historical question.
- [ ] 15. Ask the rehearsed governance question.
- [ ] 16. Ask the rehearsed formal-transfer question.
- [ ] 17. Ask the restricted question and show the safe denial.
- [ ] 18. Return to the dashboard.

## Final 10-minute check

- [ ] Sign out, reload, and sign in once successfully.
- [ ] Confirm search/member/community/ministry/governance taps open the expected record.
- [ ] Confirm no coming-soon or blank navigation item is visible.
- [ ] Confirm browser zoom, audio/screen sharing and presenter notes.
- [ ] Keep the demo read-only; do not deploy, migrate or edit data during the meeting.
