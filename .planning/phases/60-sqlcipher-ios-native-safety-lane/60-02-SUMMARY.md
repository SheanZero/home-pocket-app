---
phase: 60-sqlcipher-ios-native-safety-lane
plan: "02"
subsystem: native-safety
tags: [flutter, ios, sqlcipher, swiftpm, native-assets, simulator, dependency-resolution]
requires:
  - phase: 60-01
    provides: Canonical dependency compatibility validator and iOS 15 baseline
provides:
  - Fail-closed retained and from-zero iOS Native Assets evidence runner
  - Notification-free MVP dependency and native-registration graph
  - Unsigned generic-device matrix and SQLCipher Simulator runtime proof
affects: [phase-60, phase-62, phase-63, release-gates, dependency-compatibility]
actuals:
  tokens: 28178
  tasks: 2
  commits: 11
tech-stack:
  added: []
  patterns:
    - Disposable resolution must equal the retained Pub/Pod/native graph before runtime evidence.
    - Notification lifecycle barriers use dependency-free no-op clients when native notifications are absent.
key-files:
  created: []
  modified:
    - scripts/verify_ios_native_safety_lane.dart
    - scripts/dependency_compatibility.dart
    - lib/infrastructure/sync/push_notification_service.dart
    - ios/Runner/AppDelegate.swift
    - docs/testing/STABLE_BASELINE.json
key-decisions:
  - "Removed dormant Firebase, FCM, APNs, and local-notification dependencies from the MVP instead of upgrading or pinning them."
  - "Treat Profile and Release as unsigned generic-device-only checks because Flutter AOT does not support them on Simulator."
requirements-completed: [SEC-01, SEC-02, SEC-03]
coverage:
  - id: D1
    description: "Fail-closed retained-lock, from-zero, iOS 15 generated-floor, and unsigned-build evidence runner."
    requirement: SEC-02
    verification:
      - kind: integration
        ref: "dart scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_migration_test.dart"
        status: pass
      - kind: unit
        ref: "test/architecture/ios_minimum_version_contract_test.dart"
        status: pass
    human_judgment: false
  - id: D2
    description: "Booted Simulator runs the production encrypted SQLCipher migration executor."
    requirement: SEC-03
    verification:
      - kind: e2e
        ref: "build/native_safety_evidence.json#simulator-sqlcipher-runtime"
        status: pass
    human_judgment: false
  - id: D3
    description: "MVP removes notification packages and all Firebase/APNs/local registration surfaces."
    requirement: SEC-01
    verification:
      - kind: unit
        ref: "test/architecture/first_release_feature_contract_test.dart"
        status: pass
      - kind: unit
        ref: "test/architecture/ios_uat_identity_contract_test.dart"
        status: pass
    human_judgment: false
duration: 2h 50m
completed: 2026-08-09
status: complete
---

# Phase 60 Plan 02: Native Safety Lane Summary

**A fail-closed iOS SQLCipher evidence lane now reproduces the native graph from zero, proves the iOS 15 generated floor, compiles supported unsigned targets, and executes the encrypted migration on a booted Simulator without any notification stack.**

## Performance

- **Duration:** 2h 50m
- **Tasks:** 2/2
- **Files modified:** 24

## Accomplishments

- Added retained-lock and disposable from-zero native graph verification with redacted structured evidence.
- Passed generated iOS 15 validation, Debug simulator tracer, unsigned generic-device Debug/Profile/Release builds, and the SQLCipher runtime migration journey.
- Removed Firebase, FCM, APNs, local-notification packages, Android/iOS auto-registration, and production token registration; destructive data operations retain only inert identity-clear ordering.

## Task Commits

1. **Task 1: native safety tracer** - `fb208656`, `426d1d61`
2. **Task 2: full native safety lane** - `59498f62`, `a3f00138`, `d97cfc4e`, `eedf605a`
3. **MVP notification removal and corrections** - `ae4f510a`, `86b43418`, `6a538e34`, `f50cd961`, `2fbc1168`

## Decisions Made

- Removed the dormant notification graph rather than retaining or upgrading it; future notifications require their own reviewed native/privacy evidence lane.
- Retained the application-level disabled clients solely for safe destructive-operation ordering; they have no Firebase, APNs, local-notification, or token-registration path.

## Deviations from Plan

### Auto-fixed Issues

1. **[Owner decision] Removed dormant notification infrastructure**
- **Found during:** Task 2
- **Issue:** The prior retained notification graph could not satisfy a fresh resolution without an unwanted upgrade.
- **Fix:** Removed direct/transitive notification dependencies, native registration, and MVP token wiring; updated compatibility history and contracts.
- **Committed in:** `ae4f510a`, `86b43418`

2. **[Rule 1 - Bug] Refreshed stale from-zero lock graph**
- **Found during:** Task 2 full-lane verification
- **Issue:** A fresh Pub resolution selected four legitimate transitive updates, so the retained lock failed the runner's exact digest gate.
- **Fix:** Refreshed the resolved lock and its reviewed baseline digest.
- **Committed in:** `6a538e34`

3. **[Rule 1 - Bug] Excluded unsupported Simulator AOT configurations**
- **Found during:** Task 2 full-lane verification
- **Issue:** Xcode rejects Flutter Profile/Release AOT builds for Simulator.
- **Fix:** Kept Debug Simulator proof and covered Profile/Release through unsigned generic-device builds.
- **Committed in:** `f50cd961`

4. **[Rule 1 - Bug] Preserved destructive-operation barriers without notifications**
- **Found during:** Full-suite regression run
- **Issue:** Removing the no-op identity-clear call broke backup/clear ordering; the old UAT APNs source contract also became obsolete.
- **Fix:** Restored only the disabled-client ordering and strengthened the UAT contract to require no APNs path for either identity.
- **Committed in:** `2fbc1168`

## Verification

- `flutter pub run build_runner build` — passed.
- Targeted provider, notification-removal, UAT identity, iOS safety, and dependency contract tests — passed.
- `flutter analyze` — 0 issues.
- Full native lane — passed with `RUNTIME_PASS` for `simulator-sqlcipher-runtime`; Profile/Release simulator runtime records are explicitly `NOT_RUN` because Flutter supports Simulator runtime only for Debug.
- A serialized full suite was intentionally stopped after it found the two scoped regressions above; both were fixed and their targeted final gates passed. Its remaining long script-fixture portion was not rerun.

## Next Phase Readiness

The Phase 60 native safety evidence path is complete. Future notification work must reintroduce dependencies, native registration, privacy handling, and supported-device evidence as a separate planned transaction.

## Self-Check: PASSED

- Runner, contract tests, notification-free source, and structured runtime evidence exist and passed their final checks.
- All task commits listed above exist in Git history.
