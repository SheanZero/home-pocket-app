---
phase: 61-android-toolchain-emulator-lane
plan: "05"
subsystem: android-runtime-testing
tags: [android, emulator, api-36, arm64-v8a, integration-test, release-hygiene]
requires:
  - phase: 61-04
    provides: non-debug-signed Android AAB/APK evidence and hygiene scanner
provides:
  - Local Apple Silicon API 36 google_apis arm64-v8a primary Emulator acceptance
  - Complete per-file Android integration matrix and post-test release hygiene evidence
  - Explicit API 36 x86_64 GitHub/Intel supplemental lane with no mixed-ABI claim
affects: [61-06, phase-62-release-gates]
actuals:
  tokens: 16868
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns:
    - Primary and supplemental Emulator ABIs are represented as separate fail-closed evidence classes.
    - A runner-owned AVD is cold-booted, verified, and deleted before post-test release hygiene is accepted.
key-files:
  created: []
  modified:
    - scripts/verify_android_safety_lane.dart
    - test/scripts/android_safety_lane_test.dart
    - test/architecture/device_e2e_contract_test.dart
    - .github/workflows/device-e2e.yml
    - .planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md
key-decisions:
  - "Owner-approved 2026-08-10: local API 36 google_apis arm64-v8a is primary; x86_64 GitHub/Intel is supplemental."
  - "Android physical-device validation remains NOT_PERFORMED_NOT_CLAIMED."
requirements-completed: [AND-03, AND-04]
coverage:
  - id: D1
    description: Primary API 36 arm64-v8a Emulator cold-boot, readiness, redaction, ownership, and cleanup.
    requirement: AND-04
    verification:
      - kind: integration
        ref: dart scripts/verify_android_safety_lane.dart --mode=emulator --prepare-only
        status: pass
    human_judgment: false
  - id: D2
    description: Every discovered Android integration test and post-test signed artifact hygiene pass on the primary graph.
    requirement: AND-03
    verification:
      - kind: e2e
        ref: dart scripts/verify_android_safety_lane.dart --mode=emulator
        status: pass
      - kind: other
        ref: dart run scripts/verify_android_safety_lane.dart --mode=verify
        status: pass
    human_judgment: false
duration: 17m
completed: 2026-08-10
status: complete
---

# Phase 61 Plan 05: Arm64 Primary Emulator Acceptance Summary

**API 36 google_apis arm64-v8a primary Emulator acceptance on Apple Silicon, with six observed integration files and clean post-test non-debug AAB/APK hygiene.**

## Performance

- **Duration:** 17m
- **Started:** 2026-08-10T00:26:24Z
- **Completed:** 2026-08-10T00:43:54Z
- **Tasks:** 2/2
- **Files modified:** 12

## Accomplishments

- Reconciled active Phase 61 truth to the owner-approved local arm64 primary runtime contract while retaining x86_64 GitHub/Intel as a distinct supplemental lane.
- Cold-booted a disposable API 36 `google_apis` `arm64-v8a` Pixel 6 AVD with wipe/no-snapshot, deterministic readiness, redacted serial, exclusive ownership, and confirmed cleanup.
- Executed all six discovered `integration_test/` files on that exact graph, then regenerated non-debug signed AAB/APK artifacts and passed signature, registrant, and packaged-content hygiene scans.

## Task Commits

1. **Task 1: Provision and verify a deterministic API 36 arm64 primary AVD boundary** — `d2657cfb` (RED), `8f8d6306` (GREEN), `87093201` (cleanup correctness), with `f569e8a6` reconciling the owner-approved contract.
2. **Task 2: Run the complete integration matrix and post-test release rescan** — `e6b5cbf6` (matrix runner), `a117e865` (observed runtime and package evidence).

## Files Created/Modified

- `scripts/verify_android_safety_lane.dart` — primary arm64 preparation, complete per-file matrix, cleanup proof, release rescan, and separate supplemental-x86 validation.
- `test/scripts/android_safety_lane_test.dart` — ABI separation, identity, ownership, and complete-matrix fail-closed fixtures.
- `test/architecture/device_e2e_contract_test.dart` and `.github/workflows/device-e2e.yml` — preserve the explicit API 36 x86_64 GitHub/Intel supplemental lane.
- `61-ANDROID-SAFETY-EVIDENCE.md` — redacted observed arm64 runtime matrix, release evidence, and physical-device prohibition.

## Decisions Made

- The local Apple Silicon API 36 `google_apis` `arm64-v8a` lane is the mandatory runtime acceptance surface.
- The checked-in API 36 `x86_64` GitHub/Intel lane remains independently testable supplemental evidence; its current unavailable result is a limitation, not a pass or a blocker.
- Android physical-device validation was not performed or claimed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added explicit runner-owned AVD cleanup verification.**
- **Found during:** Task 1
- **Issue:** A successful preparation record did not prove deletion of the disposable AVD.
- **Fix:** Fail preparation when AVD deletion fails and record the ownership cleanup result only after success.
- **Files modified:** `scripts/verify_android_safety_lane.dart`, `61-ANDROID-SAFETY-EVIDENCE.md`
- **Verification:** Targeted contracts, primary prepare-only gate, and strict evidence verifier passed.
- **Committed in:** `87093201`

**2. [Rule 1 - Bug] Updated the post-runtime evidence assertion.**
- **Found during:** Final verification
- **Issue:** The architecture contract still expected the deliberately pre-run `NOT_RUN` value after observed primary runtime evidence correctly recorded `PASS`.
- **Fix:** Assert the observed primary Emulator `PASS` result while retaining x86 supplemental and physical-device absence checks.
- **Files modified:** `test/architecture/device_e2e_contract_test.dart`
- **Verification:** Targeted Flutter contracts and strict evidence verifier passed.

**Total deviations:** 2 auto-fixed (Rule 1: 1, Rule 2: 1).

## Issues Encountered

- The superseded local x86_64 result remains retained solely as a supplemental limitation. It did not enter arm64 primary evidence.

## User Setup Required

None.

## Next Phase Readiness

Plan 06 can converge the final Phase 61 ledger using observed API 36 arm64 runtime and post-test release evidence. The x86_64 GitHub/Intel lane remains explicitly supplemental; no Android physical-device claim is permitted.

## Self-Check: PASSED

- `scripts/verify_android_safety_lane.dart` and all recorded contract files exist.
- Commits `f569e8a6`, `d2657cfb`, `8f8d6306`, `87093201`, `e6b5cbf6`, and `a117e865` exist.

---
*Phase: 61-android-toolchain-emulator-lane*
*Completed: 2026-08-10*
