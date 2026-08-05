---
phase: 57-stable-baseline-compatibility-contract
reviewed: 2026-08-05T14:46:32Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - .metadata
  - .github/workflows/audit.yml
  - .github/workflows/flutter-future-compat.yml
  - docs/testing/STABLE_BASELINE.json
  - docs/testing/DEPENDENCY_COMPATIBILITY.md
  - scripts/dependency_compatibility.dart
  - test/architecture/dependency_compatibility_contract_test.dart
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 57: Code Review Report

**Reviewed:** 2026-08-05T14:46:32Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The stable baseline contract, CI configuration, manifest, and architecture tests were reviewed at standard depth. The targeted contract test passes, but the beta workflow's required running-SDK check is incompatible with the validator's Stable-only identity rule, so the scheduled beta jobs fail as soon as beta differs from 3.44.8. The native SQLCipher linker-strip check can also be satisfied entirely by comments while the executable strip is removed. Dart identity and the actual iOS deployment target are recorded but not verified semantically.

## Critical Issues

### CR-01: The beta future-probe rejects every real beta SDK

**Classification:** BLOCKER

**File:** `/Users/xinz/Development/home-pocket-app/scripts/dependency_compatibility.dart:637-645`

**Issue:** Both beta jobs invoke `--mode=future-probe --verify-running-flutter-sdk` ([workflow](/Users/xinz/Development/home-pocket-app/.github/workflows/flutter-future-compat.yml:35)), but `_validateFlutterIdentity` always emits an error unless the running SDK version, channel, and framework revision exactly equal the pinned Stable manifest. `_severityFor` only demotes direct-dependency candidate diagnostics, so a normal beta identity (`channel: beta`, new version/revision) remains an error. The weekly early-warning lane will therefore fail before it can report compatibility information.

**Fix:** In `futureProbe` mode, treat the expected beta-vs-Stable identity difference as an explicitly classified warning (while still requiring parseable machine JSON and checking `FlutterExtension.kt` against the Android floor). Keep the exact Stable identity comparison blocking in baseline mode. Add a contract test using a beta machine JSON and asserting a warning-only report, plus a test that a beta SDK with `minSdkVersion < 24` remains an error.

### CR-02: The SQLCipher system-SQLite strip is accepted when only its comments remain

**Classification:** BLOCKER

**File:** `/Users/xinz/Development/home-pocket-app/scripts/dependency_compatibility.dart:386-391`

**Issue:** The guard merely checks whether `original.gsub`, `sqlite3`, and `stripped` occur anywhere in the Podfile. The explanatory comments in `ios/Podfile` already contain all three strings, so deleting or disabling the executable `original.gsub(...)` linker-strip code still passes this gate. That permits a Pod configuration where system `libsqlite3` can win symbol resolution, defeating the required SQLCipher-only native path.

**Fix:** Validate the active post-install transformation, not independent substrings: match the executable `original.gsub` expression and the subsequent assignment/write in the target loop, or extract the check into a Ruby test that evaluates the intended Podfile transformation against an xcconfig containing `-lsqlite3`. Add a negative architecture-test fixture that removes the executable strip but retains the comments.

## Warnings

### WR-01: The claimed Dart 3.12.2 runtime identity is never verified

**Classification:** WARNING

**File:** `/Users/xinz/Development/home-pocket-app/scripts/dependency_compatibility.dart:637-645`

**Issue:** The manifest and documentation define a Flutter 3.44.8 / Dart 3.12.2 baseline, but the machine JSON comparison checks only `flutterVersion`, `channel`, and `frameworkRevision`. A Flutter SDK reporting the pinned framework identity but carrying another Dart SDK still passes the running-SDK contract.

**Fix:** Read `dartSdkVersion` from `flutter --version --machine`, compare it with `toolchains.dart.selected_current`, and fail baseline mode on a mismatch. Extend the fixture and add a Dart-only mismatch test.

### WR-02: The iOS 15 floor is not checked against either native declaration

**Classification:** WARNING

**File:** `/Users/xinz/Development/home-pocket-app/scripts/dependency_compatibility.dart:476-483`

**Issue:** This validates only the manifest's declared iOS floor. Although `ios/Podfile` and `project.pbxproj` are digest-tracked, no semantic check verifies `platform :ios, '15.0'` or every `IPHONEOS_DEPLOYMENT_TARGET = 15.0`. A coordinated edit that updates the digest while lowering a native target leaves the manifest claiming iOS 15 and passes this validator.

**Fix:** Pass the required native source(s) to the validator and assert the Podfile platform declaration and all project deployment-target values are at least 15.0. Cover a lowered Podfile and a lowered Xcode setting with fail-closed tests.

---

_Reviewed: 2026-08-05T14:46:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
