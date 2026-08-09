---
phase: 59-controlled-platform-plugin-cohorts
plan: "04"
subsystem: platform-plugin-compatibility
tags: [flutter, firebase, fcm, apns, notifications, safe-hold, privacy]
requires:
  - phase: 59-03
    provides: Fail-closed plugin evidence contract and redacted acceptance-ledger pattern
provides:
  - Fail-closed Firebase/local-notification candidate contract with independent declaration, lock, transport, policy, lifecycle, and native-build checks
  - Retryable cold-start push initialization that clears the pipeline before a successful retry
  - Hidden-release APNs/FCM transport contract and redacted terminal notification hold
affects: [59-05, 59-06, 59-07, 60-sqlcipher-ios-native-safety-lane, 61-android-toolchain-emulator-lane, 62-automated-release-gate-lock, 63-isolated-wired-iphone-acceptance]
tech-stack:
  added: []
  patterns: [binary candidate-or-hold contract, platform-selective transport injection, retryable initialization, redacted native evidence ledger]
key-files:
  created: [.planning/phases/59-controlled-platform-plugin-cohorts/59-04-SUMMARY.md]
  modified: [docs/testing/STABLE_BASELINE.json, docs/testing/DEPENDENCY_COMPATIBILITY.md, scripts/dependency_compatibility.dart, test/architecture/dependency_compatibility_contract_test.dart, lib/infrastructure/sync/push_notification_service.dart, test/infrastructure/sync/push_notification_service_test.dart, test/architecture/first_release_feature_contract_test.dart, .planning/phases/59-controlled-platform-plugin-cohorts/59-PLUGIN-ACCEPTANCE.md]
decisions:
  - "Keep Firebase Core 4.13.0, Firebase Messaging 16.5.0, and flutter_local_notifications 22.2.0 selected until attributable Android-FCM and custom-iOS-APNs native lifecycle matrices pass."
  - "Preserve custom APNs with no Firebase initializer on iOS and Firebase FCM on Android; the disclosed cloud fallback does not collapse the transport identities."
  - "Keep notification settings hidden and native auto-registration/entitlements absent; unavailable native evidence is an explicit hold, never a feature-enable justification."
requirements-completed: [PLUG-01, PLUG-04]
metrics:
  duration: 15min
  completed: 2026-08-09
status: complete
actuals:
  tokens: 7237
  tasks: 3
  commits: 5
coverage:
  - id: D1
    description: Notification candidate acceptance fails closed on declaration/lock drift, collapsed APNs/FCM transport evidence, visible policy, missing retry/cold-start proof, and acceptance without native-build PASS evidence.
    requirement: PLUG-04
    verification:
      - kind: unit
        ref: "flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-04 notification'"
        status: pass
    human_judgment: false
  - id: D2
    description: Push initialization preserves the APNs/FCM split, ordered setup, concurrent idempotency, failure/retry, token replay, routing, cold-start, and stale-identity fencing on fake clients.
    requirement: PLUG-04
    verification:
      - kind: integration
        ref: "flutter test test/infrastructure/sync/push_notification_service_test.dart"
        status: pass
    human_judgment: false
  - id: D3
    description: Hidden first-release notification policy keeps the feature flag off, Android auto-init disabled, iOS remote-notification mode and aps entitlement absent, and APNs/FCM construction distinct.
    requirement: PLUG-04
    verification:
      - kind: unit
        ref: "flutter test test/architecture/first_release_feature_contract_test.dart"
        status: pass
    human_judgment: false
  - id: D4
    description: Exact notification-package hold records redacted Android and iOS native lifecycle exit conditions without claiming a production or device observation.
    requirement: PLUG-04
    verification:
      - kind: other
        ref: "dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk"
        status: pass
    human_judgment: false
---

# Phase 59 Plan 04: Notification Cohort Hold Summary

**A fail-closed Firebase notification contract preserves custom iOS APNs, Android FCM, hidden first-release policy, and retryable push initialization while retaining the exact evidenced package hold.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-08-09T00:38:09Z
- **Completed:** 2026-08-09T00:52:45Z
- **Tasks:** 3/3
- **Files modified:** 8

## Accomplishments

- Added a machine-checked notification evidence model that rejects every package declaration/lock mismatch, missing APNs/FCM transport split, visible-release-policy regression, missing lifecycle proof, and selected state without native-build evidence.
- Preserved the existing split transport: Android injects `FirebasePushMessagingClient`, `Firebase.initializeApp`, and `fcm`; iOS injects `ApnsPushMessagingClient`, no Firebase initializer, and `apns`.
- Made a failed cold-start initialization retry safely without retaining duplicate subscriptions, while targeted fake-client coverage keeps success, idempotency, token replay, foreground/opened/tap, cold-start, and identity-wipe behavior proven.
- Recorded redacted Android-FCM and custom-iOS-APNs native-lifecycle `UNAVAILABLE` holds, with exact exit conditions and no production credential, payload, token, or identity evidence.

## Task Commits

1. **Task 1: Refresh the notification candidates and reject policy-incomplete acceptance** — `c265155c` (RED), `096d8416` (GREEN)
2. **Task 2: Evaluate the stable lane through retryable push lifecycle seams** — `aa5aa1d6` (RED), `7b255236` (GREEN)
3. **Task 3: Lock hidden-release policy and record notification evidence** — `a0a1bbe2`

## Verification

- `flutter test test/architecture/first_release_feature_contract_test.dart` — passed (4 tests).
- `flutter test test/infrastructure/sync/push_notification_service_test.dart test/architecture/first_release_feature_contract_test.dart test/architecture/dependency_compatibility_contract_test.dart` — passed (89 tests).
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed (0 errors, 0 warnings).

## Decisions Made

- Retain exactly Firebase Core `4.13.0`, Firebase Messaging `16.5.0`, and `flutter_local_notifications 22.2.0`; the recent `22.3.0` candidate cannot be selected from registry recency alone.
- Keep custom APNs/no-Firebase initialization on iOS and Firebase FCM on Android; the disclosed cloud fallback remains a policy constraint rather than a shared transport identity.
- Keep `ReleaseFeatures.pushNotifications` false, notification UI hidden, Android Firebase auto-init/analytics disabled, and iOS remote-notification mode plus `aps-environment` absent.
- Treat missing native lifecycle evidence as a package-specific hold. It requires attributable supported Android-FCM and custom-iOS-APNs builds covering initialization/retry, foreground, opened-app, local tap, and cold-start before any candidate can be accepted.

## Deviations from Plan

None - plan executed exactly as written. The plan explicitly requires an exact hold when native build or lifecycle evidence is unavailable.

## Issues Encountered

None. Flutter verification required normal SDK-cache access outside the repository sandbox; it completed successfully without source changes.

## Known Holds

- Android FCM native build and lifecycle evidence remain `UNAVAILABLE`: the execution environment has no JDK 17 runtime or usable Android emulator/device. Phase 61 remains the toolchain lane.
- Custom iOS APNs native build and lifecycle evidence remain `UNAVAILABLE`: there is no Phase-59-attributable supported-iPhone result, and the unavailable simulator service plus Phase 63 UAT do not substitute for this candidate decision.

## Next Phase Readiness

Later platform-plugin cohorts inherit the binary candidate-or-hold and redacted-evidence pattern. A future notification candidate must preserve the APNs/FCM split and hidden first-release policy, then complete both exact native matrices before changing Pub inputs.

## Self-Check: PASSED

- All eight planned files and this summary exist.
- Commits `c265155c`, `096d8416`, `aa5aa1d6`, `7b255236`, and `a0a1bbe2` exist in repository history.
