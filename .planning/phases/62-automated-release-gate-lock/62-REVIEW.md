---
phase: 62-automated-release-gate-lock
reviewed: 2026-08-10T10:43:53Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - .github/workflows/audit.yml
  - .github/workflows/device-e2e.yml
  - docs/testing/RELEASE_COMPATIBILITY.md
  - scripts/dependency_compatibility.dart
  - scripts/release_gate.dart
  - scripts/release_gate/execution.dart
  - scripts/release_gate/expected_skips.json
  - scripts/release_gate/ios_simulator_stage.dart
  - scripts/release_gate/models.dart
  - scripts/release_gate/process_adapter.dart
  - scripts/release_gate/report.dart
  - scripts/release_preflight.sh
  - scripts/verify_android_safety_lane.dart
  - test/architecture/android_toolchain_contract_test.dart
  - test/architecture/audit_yml_invariants_test.dart
  - test/architecture/dependency_compatibility_contract_test.dart
  - test/architecture/device_e2e_contract_test.dart
  - test/architecture/release_gate_ci_contract_test.dart
  - test/architecture/release_gate_ios_contract_test.dart
  - test/helpers/release_gate_test_support.dart
  - test/scripts/android_safety_lane_test.dart
  - test/scripts/coverage_gate_test.dart
  - test/scripts/release_gate_ios_test.dart
  - test/scripts/release_gate_test.dart
  - test/scripts/release_preflight_test.dart
findings:
  critical: 6
  warning: 0
  info: 0
  total: 6
status: issues_found
---

# Phase 62: Code Review Report

**Reviewed:** 2026-08-10T10:43:53Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

Static review found six blocker-level defects in the candidate-bound release authority. They can misidentify merge candidates, hang indefinitely instead of timing out, accept invalid device evidence as a pass, leak secret-shaped diagnostics into retained CI artifacts, make timeout recovery unpublishable, and permit direct Android release packaging without the mandatory JDK 17 proof. Tests were intentionally not run.

## Critical Issues

### CR-01: Merge commits can be attributed to an older candidate

**File:** `scripts/release_gate.dart:78-92`

**Issue:** `resolveAttestedCandidateCommit` inspects each commit with `git diff-tree` but does not request a first-parent diff for merge commits. Git's default merge diff does not provide the PR-vs-main change set needed here, so a merge that changes a candidate-scoped file can be skipped. The resolver then selects an older commit while hashing the current merged files, producing an internally inconsistent candidate attestation and allowing publication to name the wrong tested commit.

**Fix:** Inspect merge commits against their first parent (for example, use merge-aware `diff-tree` options such as `-m --first-parent`, or explicitly diff each commit against `commit^1` while retaining a root-commit path). Add a fixture with a merge commit that changes `scripts/` or `lib/` and assert that its SHA is selected.

### CR-02: The process timeout never starts while a child is hung

**File:** `scripts/release_gate/process_adapter.dart:40-45`

**Issue:** The adapter awaits both stdout/stderr stream joins before it applies `timeout` to `process.exitCode`. A hung child keeps its pipes open, so `Future.wait` never completes and execution never reaches the timeout or termination branch. This affects the host prerequisite/coverage commands and every iOS Simulator command using this adapter, allowing the mandatory release gate to hang indefinitely.

**Fix:** Start draining output without awaiting completion, await `process.exitCode.timeout(timeout)` first, terminate/escalate on timeout, then await the drain futures. Preserve bounded, scrubbed output after the process has exited or been killed.

### CR-03: Diagnostic privacy filtering permits common token and credential formats

**File:** `scripts/release_gate/process_adapter.dart:64-85`

**Issue:** Redaction only recognizes `name=value` with no whitespace. It leaves output such as `token: secret`, `TOKEN = secret`, and JSON such as `{"api_key":"secret"}` intact. The second-layer scanner in `scripts/release_gate/report.dart:11-14` has the same `=`-only limitation, so those values pass validation and are written into ignored release evidence that the workflow uploads as an artifact. This violates the project's rule that tokens and recovery material must never be logged.

**Fix:** Use the same key/value-aware scrubber already used by the Android lane: match sensitive keys with optional quotes and whitespace followed by either `:` or `=`, then redact quoted and unquoted values. Apply the identical rule in `validateEvidencePrivacy`, and add cases for colon-delimited, spaced, and JSON-formatted secrets.

### CR-04: The aggregate gate can pass malformed iOS or Android evidence

**File:** `scripts/release_gate.dart:388-421`

**Issue:** The full gate accepts iOS evidence when `failure == null` and its path accounting matches, but never calls `validateIosSimulatorEvidence`. It likewise trusts Android's `result == 'PASS'` without calling `validatePhase62AndroidEvidence`. The existing full-scope test demonstrates the iOS bypass: it supplies an `IosSimulatorProfile.unavailable()` with no per-test records and still expects an aggregate `PASS` (`test/scripts/release_gate_test.dart:290-331`). Consequently, malformed simulator identity/redaction data, missing test records, an unrun iOS preflight, or invalid Android prerequisite/release evidence can be represented as a passing mandatory platform stage.

**Fix:** Require both validators at this boundary, e.g. `ios.isReady && ios.preflightRan && validateIosSimulatorEvidence(ios) && ...` and `android != null && validatePhase62AndroidEvidence(android).isEmpty && ...`. Extend iOS validation to require successful record exit codes and preflight completion, then make the injected malformed evidence cases block.

### CR-05: Timeout recovery is rejected as a privacy violation

**File:** `scripts/release_gate/models.dart:28`, `scripts/release_gate/execution.dart:485-492`, `scripts/release_gate/report.dart:11-14`

**Issue:** The timeout-recovery path adds `GateStage.serialHostSuite`, whose serialized name contains `serial`. The report privacy expression rejects any occurrence of `serial`, so `validateGateResult(result.toJson())` fails whenever the recovery stage is present—even if the identified tests and serial rerun pass. `_persist` then returns a blocked result without writing the JSON/preview. This makes the advertised timeout diagnosis and serial recovery path incapable of producing authoritative evidence.

**Fix:** Make the privacy rule target a sensitive serial field/value rather than a bare substring (for example, a `serial` key followed by `:` or `=`), and retain tests proving both actual device serials are rejected and `serialHostSuite` is accepted.

### CR-06: Direct Android packaging no longer enforces the JDK 17 prerequisite

**File:** `scripts/release_preflight.sh:18`, `scripts/release_preflight.sh:269-292`

**Issue:** The Phase 62 change removed the old coupled JDK variable but did not replace it with an independent JDK 17 assertion. `release_preflight.sh --platform android --package` now invokes Gradle or `flutter build` using whichever JVM the caller happens to expose. The selected SIGN-A contract requires JDK 17 selection to remain mandatory and fail closed; only the Android adapter happens to supply a verified `JAVA_HOME` for its own call. A direct release-preflight invocation can therefore produce a release package without the required JDK proof.

**Fix:** Add an independent Android-package preflight that resolves the configured JDK home, runs `java -version`, requires major version 17, and passes that verified home to Gradle/Flutter. Keep `PHASE61_SIGNING_EVIDENCE` solely responsible for the evidence-signing route; do not restore the old coupling. Add mutation tests for JDK 17, JDK 21/invalid, and signing-switch combinations.

---

_Reviewed: 2026-08-10T10:43:53Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
