---
phase: 58-flutter-analyzer-code-generation-lane
reviewed: 2026-08-08T12:29:47Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .github/workflows/audit.yml
  - analysis_options.yaml
  - docs/testing/DEPENDENCY_COMPATIBILITY.md
  - docs/testing/STABLE_BASELINE.json
  - pubspec.lock
  - pubspec.yaml
  - scripts/audit/provider_contract.dart
  - scripts/dependency_compatibility.dart
  - scripts/verify_codegen_reproducibility.sh
  - scripts/verify_tooling_guards.dart
  - test/architecture/audit_yml_invariants_test.dart
  - test/architecture/codegen_reproducibility_contract_test.dart
  - test/architecture/dependency_compatibility_contract_test.dart
  - test/architecture/provider_contract_test.dart
  - test/architecture/providers_audit_contract_test.dart
  - test/architecture/tooling_guard_negative_fixture_test.dart
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 58: Code Review Report

**Reviewed:** 2026-08-08T12:29:47Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The selected Flutter/Dart dependency graph, lockfile enforcement, and fixture-lock recovery path were reviewed together with their architecture contracts. The native/plugin/device boundary deferred by D-10 was not treated as a defect. However, the repository-owned ProviderScope guard still has a valid Dart call form that bypasses enforcement; its lexical-shadow scanner also rejects valid code after a loop-local alias. Separately, the authoritative code-generation wrapper does not run the mandated conflict-deleting build step, so valid generator-input changes can fail before reproducibility is checked.

## Critical Issues

### CR-01: Parenthesized `runApp` invocation bypasses the owned ProviderScope guard

**File:** `scripts/audit/provider_contract.dart:742-759`

**Issue:** `_findCalls` accepts only `runApp(...)` and `runApp.call(...)` (plus approved import-prefix variants). Dart also permits invoking the function tear-off as `(runApp)(const Placeholder())` and `(widgets.runApp)(...)`. Those token sequences have `)` immediately after `runApp`, so they are ignored and an unscoped application root passes `checkProviderContract`. The new negative fixtures cover only `.call` forms (`test/architecture/provider_contract_test.dart:55-120` and `test/architecture/tooling_guard_negative_fixture_test.dart:75-105`), leaving this D-04 enforcement bypass untested.

**Fix:** Extend `_findCalls` to recognize a single parenthesized direct function reference, preserving the same verified-prefix rule, then add unit and live-harness bad/control cases. For example, recognize `(` + `runApp` + `)` + `(` and `(` + verified-prefix + `.` + `runApp` + `)` + `(`, while continuing to reject arbitrary receiver chains.

## Warnings

### WR-01: `for`-header bindings shadow Riverpod import aliases past the loop

**File:** `scripts/audit/provider_contract.dart:362-368, 615-648`

**Issue:** A `final`/`var` binding in a `for` header is classified as a normal declaration, then `_scopeShadowFor` extends its range to `_enclosingBlock`—the surrounding function body. Consequently, a valid qualified root after a loop, such as `for (final riverpod in values) {} runApp(riverpod.ProviderScope(...));`, is rejected even though the loop variable is out of scope. The lexical-boundary tests cover type, if-case, and switch-case scopes but have no loop-header control (`test/architecture/provider_contract_test.dart:461-590`). This can block otherwise valid application code in CI.

**Fix:** Detect declarations inside `for (...)` headers and bound their shadow range to that loop statement/body (including the condition/update area as appropriate). Add passing controls for roots after `for-in` and C-style loops, and a failing control for a root inside the loop body.

### WR-02: The reproducibility wrapper omits `--delete-conflicting-outputs`

**File:** `scripts/verify_codegen_reproducibility.sh:61,66`

**Issue:** Both generation passes run `flutter pub run build_runner build` without `--delete-conflicting-outputs`, contrary to the Phase 58 D-08 sequence. After a legitimate annotated-source or generator configuration change, stale committed outputs can make build_runner stop on a conflict instead of regenerating them for the two-pass diff oracle. The source contract only checks the shorter command (`test/architecture/codegen_reproducibility_contract_test.dart:64,101`), so it cannot catch the omission.

**Fix:** Run both passes as `flutter pub run build_runner build --delete-conflicting-outputs` and update the contract test to assert that complete command exactly twice and in the same order relative to localization and the clean-scope checks.

---

_Reviewed: 2026-08-08T12:29:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
