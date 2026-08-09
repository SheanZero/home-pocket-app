---
phase: 59-controlled-platform-plugin-cohorts
plan: "02"
subsystem: platform-plugin-compatibility
tags: [flutter, file-picker, share-plus, package-info-plus, win32, safe-hold]
requires:
  - phase: 59-01
    provides: Exact platform-plugin inventory and initial acceptance ledger
provides:
  - Fail-closed PLUG-02 atomic file/share/package-info/win32 hold contract
  - Mechanical preservation checks for .hpb restore and all share entry points
  - Attributable redacted native-prerequisite evidence and terminal hold decision
affects: [59-03, 59-04, 59-05, 59-06, 59-07, 62-automated-release-gate-lock]
tech-stack:
  added: []
  patterns: [atomic dependency cohort, evidence-backed native hold, source-level seam characterization]
key-files:
  created: [.planning/phases/59-controlled-platform-plugin-cohorts/deferred-items.md, .planning/phases/59-controlled-platform-plugin-cohorts/59-02-SUMMARY.md]
  modified: [docs/testing/STABLE_BASELINE.json, docs/testing/DEPENDENCY_COMPATIBILITY.md, scripts/dependency_compatibility.dart, test/architecture/dependency_compatibility_contract_test.dart, test/widget/features/settings/backup_restore_screen_test.dart, .planning/phases/59-controlled-platform-plugin-cohorts/59-PLUGIN-ACCEPTANCE.md]
decisions:
  - "Retain file_picker 11.0.3, share_plus 12.0.2, package_info_plus 9.0.1, and transitive win32 5.15.0 as one exact hold because the complete Java 17/Android/native UI evidence gate is unavailable."
  - "Do not exercise the iOS destinations independently: PLUG-02 requires the complete supported-platform matrix before any candidate can be accepted."
metrics:
  duration: 7min
  completed: 2026-08-09
status: complete
actuals:
  tokens: 4702
  tasks: 3
  commits: 5
---

# Phase 59 Plan 02: Atomic File/Share Cohort Summary

**A fail-closed, evidence-backed hold keeps the exact file-picker/share/package-info/win32 graph while preserving encrypted `.hpb` restore and all existing share seams.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-09T00:14:22Z
- **Completed:** 2026-08-09T00:21:44Z
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Added RED/GREEN contract tests that name every partial declaration or lock mutation and reject missing held evidence for every atomic member.
- Rechecked the official cohort candidates and recorded why the newer Plus line cannot move independently of AGP/toolchain/native behavior evidence.
- Preserved the exact selected Pub graph: no change to `pubspec.yaml`, `pubspec.lock`, Android tooling, iOS tooling, or application callers.
- Characterized the `.hpb` picker guards, encrypted `restoreBackupUseCaseProvider` boundary, encrypted backup-file share, and both family invite text-share callers.
- Recorded redacted automation and unavailable-native rows; the terminal state is an explicit four-member hold, never a partial upgrade or a false native pass.

## Task Commits

1. **Task 1: Make the atomic cohort decision fail first on every partial graph** — `4e20b8fc` (RED), `c0703166` (GREEN)
2. **Task 2: Probe one compatible graph without weakening `.hpb` or share behavior** — `03bebfe8`
3. **Task 3: Record attributable native results and the terminal atomic decision** — `165dc76e`, `b193eebf`

## Verification

- `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'PLUG-02'` — passed (5 tests)
- `flutter test test/widget/features/settings/backup_restore_screen_test.dart test/unit/application/settings/import_backup_use_case_test.dart test/unit/application/settings/restore_backup_use_case_test.dart test/architecture/dependency_compatibility_contract_test.dart` — passed (73 tests)
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed (0 errors, 0 warnings)
- `flutter analyze` — ran but reports 289 pre-existing `prefer_initializing_formals` information diagnostics outside this plan's files; recorded in `deferred-items.md` and `.planning/WINDOWS.md` rather than changed out of scope.

## Decisions Made

- `file_picker 11.0.3`, `share_plus 12.0.2`, `package_info_plus 9.0.1`, and `win32 5.15.0` remain one exact atomic hold.
- No candidate was resolved because Java 17 and an Android emulator/device are unavailable; iOS destinations alone cannot satisfy the all-platform acceptance gate.
- Existing restore and share call sites remain byte-for-byte unchanged; only contract/evidence coverage was added.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test bug] Corrected the characterization test import placement**
- **Found during:** Task 3
- **Issue:** The new `dart:io` directive was inserted after declarations and the test could not compile.
- **Fix:** Moved the directive into the import block, then formatted and reran the scoped test.
- **Files modified:** `test/widget/features/settings/backup_restore_screen_test.dart`
- **Commit:** `165dc76e`

**2. [Rule 2 - Missing critical functionality] Validated cohort-level hold evidence**
- **Found during:** Task 2
- **Issue:** The manifest added a cohort-level native-prerequisite result but the validator did not require it.
- **Fix:** Required the decision, query date, prerequisite result, compatibility reason, and exit condition for the atomic lane.
- **Files modified:** `scripts/dependency_compatibility.dart`, `docs/testing/STABLE_BASELINE.json`
- **Commit:** `03bebfe8`

## Known Holds

- Native candidate evaluation remains unavailable: there is no Java 17 runtime or Android emulator/device. No native build, picker, share-sheet, or package-identity observation was fabricated.
- The existing iOS destinations were deliberately not exercised because the plan requires one complete supported-platform cohort decision, not an iOS-only result.

## Deferred Issues

- `flutter analyze` currently reports 289 pre-existing `prefer_initializing_formals` information diagnostics in unrelated source files. This plan did not introduce any analyzer diagnostics; the discovery is recorded in `deferred-items.md` and `.planning/WINDOWS.md`.

## Self-Check: PASSED

- All seven task deliverables and this summary exist.
- Commits `4e20b8fc`, `c0703166`, `03bebfe8`, `165dc76e`, and `b193eebf` exist in repository history.
