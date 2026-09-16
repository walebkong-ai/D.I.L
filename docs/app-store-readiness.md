# Good Morning release readiness
Updated 2026-09-16. This checklist describes the current native app, not the standalone HTML prototypes. Approval is Apple's decision. See [review guidelines](https://developer.apple.com/app-store/review/guidelines/).

## Core data flows
- [x] Fresh install has no completed tasks or earned points; completion/uncompletion, category caps, editing and deletion checked by executable production-source tests.
- [x] Points are calculated from saved tasks; no independently stored daily/category totals.
- [ ] Real-device goal interaction, storage failure, and performance checks.

## Daily history
- [x] Date-keyed records preserve yesterday and stable task IDs; rollover, repeated launches, backward clock selection, corruption protection, v1 migration checked.
- [ ] Physical-device midnight, time zone travel, DST, and long-history tests.
- [ ] History browsing UI (export is available).

## HealthKit
- [x] Pure calculation tests verify missing inputs never produce scores, including no samples and partial data with a recorded zero.
- [ ] IN PROGRESS: read-only production queries compile; on-device Health permission/data scenarios still need verification.
- [ ] Sleep aggregation across midnight/noon, multiple sources, revoked access and partial permissions tested with real records.
- [ ] Experimental duration/recovery indices validated for product suitability; not diagnostic or clinical scores.
- [ ] After permission denial, no-readable-samples state tested on device. Apple does not expose definitive read-denial status.

## Garmin verification
- [x] No direct-connect or self-certified connection state drives UI.
- [ ] BLOCKED: verify each exported metric from a physical Forerunner 165. See [Garmin data limitations](garmin-health-data.md).
- [ ] Any future direct API needs Garmin approval, secure backend, and consent.

## Friends / leaderboard
- [x] Static friend entries do not drive native production UI.
- [ ] Service boundary and privacy-limited payload exist; backend, authentication, invitations, opt-in sharing, moderation/report/block remain unimplemented.

## Privacy and security
- [x] UserDefaults CA92.1 declaration passes plist lint.
- [x] HEAD, PR #1, and all 15 locally reachable commit snapshots were scanned by filename-only searches for both GitHub token prefixes; none found. This is not proof of all secret types or unavailable remote history.
- [ ] Final linked-binary privacy manifest/App Privacy review; no third-party SDKs currently used.
- [ ] Final signing/archive secret and permission review.
- [ ] Goal history is UserDefaults data and may be backed up; manual logs are protected on-device files excluded from backup.
- [ ] Health data stays in memory, not persisted/transmitted; verify with device/network inspection.

## Accessibility
- [ ] Full accessibility pass, reduced motion, contrast and minimum touch targets.

## Dark Mode
- [ ] Custom dashboard palette remains primarily light; native forms adapt. Full dark-mode verification outstanding.

## Dynamic Type
- [ ] Header/new forms use semantic styles; custom metrics and existing cards still need largest-size testing.

## VoiceOver
- [ ] Goal icon controls have labels; full reading order and actions testing outstanding.

## Device layouts
- [ ] SE through Pro Max, rotation, keyboard and safe areas; no screenshot validation completed this slice.

## App icon
- [ ] BLOCKED: verify release artwork, dimensions, asset catalog and rights.

## Privacy policy
- [ ] In-app text updated for goal history, Health memory use, export and deletion; publish accurate HTTPS policy with owner contact.

## Support page
- [ ] BLOCKED: working HTTPS support/contact page required.

## Signing
- [ ] BLOCKED: Apple Developer team, distribution signing and HealthKit provisioning. Current team is empty.

## App Store metadata
- [ ] Final name/subtitle/description/keywords/category/age questionnaire. Draft: Good Morning / Daily goals and personal logs. Do not advertise live social sync or direct Garmin integration.

## Screenshots
- [ ] Capture actual completed features in Apple's required sizes; no synthetic user measurements.

## TestFlight
- [ ] Signed archive upload, internal testers, feedback and crash review.

## Fresh-install testing
- [x] Isolated UserDefaults core checks pass for empty goals and zero points.
- [ ] Device fresh install and no unsolicited permission prompts.

## Upgrade testing
- [x] PR #1 v1 stored plan migrates with stable task IDs in core checks.
- [ ] Signed app upgrade and older corrupted/invalid data scenarios on device.

## Offline testing
- [ ] No backend is needed for goals/logs; full airplane-mode device test outstanding.

## Permission-denial testing
- [ ] Health sheet denial/cancel/restricted/device-locked/unavailable scenarios; preserve manual goals/logs.

## Export
- [ ] Daily history JSON export and manual-log export implemented; system share destination/cancel/recipient tests outstanding.

## Account/data deletion
- [ ] No accounts exist. Confirmed local log and goal-history deletion implemented; device/relaunch verification outstanding. Original Health records are unchanged.

## Real-device stability
- [ ] Release install, relaunch, background/foreground, locked-device access, large history, memory/battery checks.

## Secret rotation
- [ ] BLOCKED: revoke/rotate the GitHub token previously pasted into chat; treat it as compromised. No token value is reproduced.

## Review notes draft
No login or payment required. Goals adds/edits/deletes daily tasks; Today toggles completion and shows calculated points. Local calendar midnight starts a fresh saved day. Track records category notes. Profile offers optional Health access, goal-history export/deletion, and privacy information. Health denial does not prevent manual tracking. Garmin is an upstream Health source only. Online friends are unavailable. Export destinations control exported copies. Final reviewer notes must match the submitted build.

## Validation record
DIL scheme and available destinations discovered with xcodebuild. Release iPhone 17 Pro simulator build completed. Standalone Swift core checks compiled against production sources and passed. No XCTest target exists; these are executable pure/core checks, not simulated HealthKit permission tests. See Tests/README.md. Physical-device/TestFlight testing remains outstanding.
