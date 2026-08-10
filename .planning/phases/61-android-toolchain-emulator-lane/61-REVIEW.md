---
phase: 61-android-toolchain-emulator-lane
reviewed: 2026-08-10T01:09:40Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - .github/workflows/device-e2e.yml
  - android/app/build.gradle.kts
  - docs/testing/DEPENDENCY_COMPATIBILITY.md
  - docs/testing/STABLE_BASELINE.json
  - scripts/dependency_compatibility.dart
  - scripts/release_preflight.sh
  - scripts/verify_android_safety_lane.dart
  - test/architecture/android_release_signing_contract_test.dart
  - test/architecture/android_toolchain_contract_test.dart
  - test/architecture/dependency_compatibility_contract_test.dart
  - test/architecture/device_e2e_contract_test.dart
  - test/scripts/android_safety_lane_test.dart
  - test/scripts/release_preflight_test.dart
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 61: Code Review Report

**Reviewed:** 2026-08-10T01:09:40Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

The implementation has strong declarative checks, but its acceptance evidence is not bound to the current source tree. In particular, the strict verifier reports success on this checkout even though the evidence's `source_commit` is `e6b5cbf672e885dcbb4446621cc20e7ca05aa058` and `HEAD` is `31a25528c409833937927edd18b580b107aeb5d8`. The GitHub lane also contradicts the owner-approved separation of a blocking local arm64 lane from a non-blocking x86_64 supplemental lane.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Primary arm64 PASS evidence can be stale or built from uncommitted sources

**Classification:** BLOCKER

**File:** `scripts/verify_android_safety_lane.dart:156`

**Issue:** `validateCurrentAndroidSafetyLane` never obtains the current commit or a source-tree digest. `_validateEvidence` only requires the evidence commit fields to be syntactically valid and that `source_commit == package_source_commit` (lines 440-455). Therefore an old arm64 Emulator/packaging PASS remains valid after a change to app code or an integration test. This is demonstrable in the submitted tree: strict `dart scripts/verify_android_safety_lane.dart --mode=verify` returns PASS while the ledger's source commit differs from the checkout's `HEAD`. The producers have the same provenance defect: the candidate probe archives `HEAD` (lines 2437-2444), while release/emulator runs use the mutable working tree but record only `git rev-parse HEAD` (lines 1207-1215 and 1789). Uncommitted edits can thus be tested or packaged while being attributed to a clean commit.

**Fix:** Bind every accepted record to an immutable, scoped source identity and verify that identity at read time. For example, require a clean relevant worktree before running, record a SHA-256 manifest of all release inputs plus `lib/` and `integration_test/`, and have `validateCurrentAndroidSafetyLane` recompute and compare it. Alternatively, reject when `git diff --quiet <evidence-source>..HEAD -- lib integration_test android scripts pubspec.yaml pubspec.lock` fails. Add a regression test that changes an integration-test or `lib/` file after producing evidence and asserts that strict verification fails.

### CR-02: The declared supplemental x86_64 lane is still workflow-blocking

**Classification:** BLOCKER

**File:** `.github/workflows/device-e2e.yml:37`

**Issue:** The `android-device-e2e` job is described as “supplemental” but has the default fail-fast job behavior. A failed x86_64 GitHub/Intel run fails the `device-e2e` workflow; if that check is required by branch protection it blocks the pull request. No job-level `continue-on-error: true`, separate informational workflow, or equivalent non-blocking mechanism exists. This violates the approved contract that local API 36 `arm64-v8a` is the primary/blocking lane and x86_64 GitHub/Intel is supplemental/non-blocking. The source-contract tests assert the label and ABI only, so they would allow this contract reversal.

**Fix:** Make the x86_64 job explicitly informational (for example, add job-level `continue-on-error: true` and publish its result as supplemental evidence), or move it to a workflow/check that is not a required merge gate. Extend `device_e2e_contract_test.dart` to assert the chosen non-blocking mechanism rather than only checking the job name.

### CR-03: Release-hygiene changes can skip the device-E2E workflow entirely

**Classification:** BLOCKER

**File:** `.github/workflows/device-e2e.yml:10`

**Issue:** Both the pull-request and push `paths` filters omit `scripts/release_preflight.sh`, even though the Android job executes that script as its final hygiene gate (line 75). A change that disables the registrant/artifact scan can therefore skip the only workflow that executes this preflight against emulator-generated Android output when the PR changes that script alone. This makes a release-validation control fail open at the workflow-selection boundary.

**Fix:** Add `scripts/release_preflight.sh` to both path lists (and include any other script directly executed by this workflow). Add a contract test that parses both trigger path lists and requires the preflight script to be present.

## Warnings

### WR-01: Selecting the phase JDK silently disables the documented local signing configuration

**Classification:** WARNING

**File:** `scripts/release_preflight.sh:273`

**Issue:** When `PHASE61_GRADLE_JAVA_HOME` is set, `--package` invokes Gradle with `-Pphase61SigningEvidence=true` (lines 273-281). That property suppresses loading `android/key.properties` in `android/app/build.gradle.kts:18-22`. Consequently, a local release using the documented ignored `key.properties` fails unless it also supplies all four CI environment variables. Selecting the verified JDK should not change the credential source for a production package.

**Fix:** Reserve `phase61SigningEvidence` for the ephemeral evidence runner only. Remove it from the ordinary preflight packaging commands; environment values already take precedence when the evidence runner needs to override a local file. Add a script-level regression test for a package invocation with `PHASE61_GRADLE_JAVA_HOME` that asserts the production command does not add the evidence property.

---

_Reviewed: 2026-08-10T01:09:40Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
