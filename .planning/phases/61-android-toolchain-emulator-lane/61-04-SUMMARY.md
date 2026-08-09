---
phase: 61-android-toolchain-emulator-lane
plan: "04"
subsystem: android-release-evidence
tags: [android, release, aab, apk, signing, hygiene]
requires:
  - phase: 61-03
    provides: Exact held Android graph compiled under verified JDK 17
provides:
  - Fail-closed dual-format Android release packaging
  - Observed missing/debug signing rejection
  - Independently verified ephemeral non-debug AAB/APK evidence
affects: [phase-61-emulator, phase-62-release-gates, AND-03]
actuals:
  tokens: 16000
  tasks: 2
  commits: 8
tech-stack:
  added: []
  patterns:
    - Production credentials are never needed for release evidence; runner-owned random secrets and PKCS12 keys are temporary
    - AAB and APK signatures are verified independently from Gradle using JDK and Android SDK tools
    - Packaged-content denylisting names concrete Flutter integration-test identifiers, not generic prose
key-files:
  created: []
  modified:
    - android/app/build.gradle.kts
    - scripts/release_preflight.sh
    - scripts/verify_android_safety_lane.dart
    - test/architecture/android_release_signing_contract_test.dart
    - test/scripts/android_safety_lane_test.dart
    - test/scripts/release_preflight_test.dart
    - .planning/phases/61-android-toolchain-emulator-lane/61-ANDROID-SAFETY-EVIDENCE.md
key-decisions:
  - "Release evidence uses an explicit Gradle property to bypass ignored developer key.properties while preserving existing CI environment names and precedence."
  - "The artifact denylist is limited to integration_test, IntegrationTestPlugin, and dev.flutter.integration_test; ordinary integration-test prose is allowed."
  - "JDK signing tools force deterministic English output, and AAB verification is non-verbose because keytool owns certificate detail."
patterns-established:
  - "The runner records hashes, certificate class/fingerprint, package metadata, exit codes, and hygiene only, then removes every key and release-artifact copy."
requirements-completed: [AND-03]
coverage:
  - id: D1
    description: Missing release credentials and an observed Android Debug certificate both fail the real Gradle signing task.
    requirement: AND-03
    verification:
      - kind: integration
        ref: dart run scripts/verify_android_safety_lane.dart --mode=release
        status: pass
    human_judgment: false
  - id: D2
    description: One ephemeral non-debug certificate produces signed AAB and APK artifacts whose fingerprints and package metadata match.
    requirement: AND-03
    verification:
      - kind: integration
        ref: apksigner + jarsigner + keytool + aapt evidence ledger
        status: pass
    human_judgment: false
  - id: D3
    description: Both archives and the regenerated Android registrant exclude concrete Flutter integration-test identifiers, and no secret or artifact remains.
    requirement: AND-03
    verification:
      - kind: unit
        ref: test/scripts/android_safety_lane_test.dart
        status: pass
      - kind: unit
        ref: test/scripts/release_preflight_test.dart
        status: pass
      - kind: other
        ref: dart run scripts/verify_android_safety_lane.dart --mode=verify
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-08-09
status: complete
---

# Phase 61 Plan 04: Signed Android Release Evidence Summary

**The held Android graph now rejects absent/debug signing, produces both release formats with an ephemeral non-debug key, and independently proves signature, metadata, and packaged hygiene before deleting all private material and artifacts.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-08-09T15:18:00Z
- **Completed:** 2026-08-09T15:51:04Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended the existing release preflight to package AAB then APK under verified JDK 17 and scan both artifacts after clean Android registrant regeneration.
- Added real missing-credential and Android Debug-certificate negatives plus fresh random-password, non-debug PKCS12 evidence packaging.
- Independently verified APK and AAB signatures, matching SHA-256 certificate fingerprints, application/version/SDK metadata, concrete test-plugin hygiene, and post-run absence of credentials and release artifacts.

## Task Commits

1. **Task 1: enforce dual Android release hygiene** - `fcccef0b` (feat)
2. **Task 2: add ephemeral release evidence runner** - `68a2fb98` (feat)
3. **Task 2: scope regenerated registrant scan** - `f29ef91a` (fix)
4. **Task 2: narrow artifact denylist and cleanup copies** - `153ed534` (fix)
5. **Task 2: preserve bounded verification tails** - `0feebf85` (fix)
6. **Task 2: stabilize JDK tool locale** - `5c350752` (fix)
7. **Task 2: use concise AAB signature verification** - `b953bcc3` (fix)
8. **Task 2: record signed package evidence** - `2a27a077` (docs)

## Files Created/Modified

- `android/app/build.gradle.kts` - Adds runner-only evidence signing selection without weakening production fail-closed behavior.
- `scripts/release_preflight.sh` - Builds and scans both Android release formats in deterministic order.
- `scripts/verify_android_safety_lane.dart` - Owns ephemeral keys, real negatives, independent verification, redaction, and cleanup.
- `test/architecture/android_release_signing_contract_test.dart` - Locks signing precedence and the release verification task.
- `test/scripts/android_safety_lane_test.dart` - Covers contaminated/benign archives, output bounds, locale, and certificate classification.
- `test/scripts/release_preflight_test.dart` - Covers dual-format ordering, platform-scoped registrants, and credential-free dry runs.
- `61-ANDROID-SAFETY-EVIDENCE.md` - Records attributable package PASS without retaining artifacts or secrets.

## Decisions Made

- Kept production signing environment names unchanged and used a dedicated project property only for the runner-owned disposable evidence path.
- Required exact packaged plugin identifiers instead of the generic hyphenated phrase `integration-test`, avoiding false positives in ordinary release content.
- Used concise `jarsigner -verify` for the cryptographic AAB verdict and separate `keytool -printcert` for certificate inspection; both force English output for stable parsing on localized hosts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scoped regenerated registrant scanning to the requested platform**
- **Found during:** Task 2 first real package run
- **Issue:** Android-only preflight rejected the freshly regenerated iOS development registrant even though only the Android release surface was in scope.
- **Fix:** Made registrant hygiene platform-aware while retaining Android fail-closed scanning.
- **Verification:** Added an Android-only fixture with an unrelated iOS test registrant; focused tests and real packaging pass.
- **Committed in:** `f29ef91a`

**2. [Rule 1 - Bug] Removed generic prose from the packaged-content denylist**
- **Found during:** Task 2 signed archive scan
- **Issue:** The generic `integration-test` token appeared in benign packaged text and rejected both otherwise clean artifacts.
- **Fix:** Limited the denylist to concrete Flutter identifiers and added a benign prose regression; also cleaned the Flutter-copied APK path.
- **Verification:** Contaminated ZIP fixtures still fail, benign prose passes, and all release copies are absent after execution.
- **Committed in:** `153ed534`

**3. [Rule 1 - Bug] Made bounded command capture retain completion output**
- **Found during:** Task 2 AAB signature verification
- **Issue:** The bounded buffer kept only command prefixes, dropping completion text after verbose output.
- **Fix:** Retained bounded head and tail with a truncation marker and added a large-output regression fixture.
- **Verification:** The fixture preserves both start and completion markers under the durable size ceiling.
- **Committed in:** `0feebf85`

**4. [Rule 3 - Blocking] Stabilized localized and oversized JDK signing output**
- **Found during:** Task 2 independent AAB verification
- **Issue:** macOS selected Chinese Java-tool messages, and verbose `jarsigner` placed `jar verified` between a large entry list and a larger ZIP-consistency warning block.
- **Fix:** Forced English Java-tool locale and used non-verbose verification, leaving certificate detail to keytool.
- **Verification:** Direct diagnostic verification and the clean runner both returned `jar verified`, exit 0; the diagnostic key/artifacts were deleted before the accepted run.
- **Committed in:** `5c350752`, `b953bcc3`

---

**Total deviations:** 4 auto-fixed (3 release-runner bugs, 1 blocking verifier issue).
**Impact on plan:** Stronger reproducibility and cleanup; production signing behavior and the selected Android graph remain unchanged.

## Issues Encountered

- JDK 17 reports expected self-signed/untimestamped warnings for the short-lived evidence certificate. These do not affect the verified signature or enter production material.

## User Setup Required

None.

## Next Phase Readiness

- AND-03 has attributable dual-format package evidence and is ready for the required post-Emulator rescan in Plan 61-05.
- API 36 x86_64 Emulator runtime remains `NOT_RUN`; no Android physical-device validation was performed or claimed.

## Self-Check: PASSED

- Strict evidence validation passes at package stage.
- Twenty-three focused signing/preflight/runner tests pass and targeted analysis reports no issues.
- No evidence key, release AAB, release APK, or repository credential remains.

---
*Phase: 61-android-toolchain-emulator-lane*
*Completed: 2026-08-09*
