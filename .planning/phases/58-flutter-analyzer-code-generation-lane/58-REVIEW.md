---
phase: 58-flutter-analyzer-code-generation-lane
reviewed: 2026-08-08T14:11:25Z
depth: deep
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
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 58: Code Review Report

**Reviewed:** 2026-08-08T14:11:25Z
**Depth:** deep
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The Phase 58 Dart/analyzer/code-generation scope was reviewed end to end, including workflow-to-wrapper execution, dependency-policy validation, temporary-fixture locking, and provider-contract parsing. The previous review findings are resolved: exact one-level parenthesized roots are handled, for-header aliases have statement bounds for the covered cases, and both build-runner passes use `--delete-conflicting-outputs` under an exact-line contract.

However, the new statement-bound implementation truncates lexical scopes when a loop or `if-case` body is itself an unbraced control-flow statement. That permits a locally shadowed Riverpod alias to be accepted as the real import in a nested `else`/loop branch, bypassing the owned ProviderScope guard. The scanner also treats any unqualified callable named `runApp` as Flutter's global app root, so valid local helpers can fail CI.

## Critical Issues

### CR-01: Nested control-flow bodies end Riverpod alias shadows before their real statement boundary

**Classification:** BLOCKER

**File:** `scripts/audit/provider_contract.dart:534-541`

**Issue:** `_statementEnd` returns the first semicolon after an unbraced statement start. It does not consume compound statements such as `if (...) statement else statement`, `while`, nested `for`, `try`, or `do`. `_forHeaderShadowEnd` uses this result at line 741, so a loop-header alias can stop shadowing after the inner `then` branch rather than after the entire loop body. For example, in a valid Dart source shape such as:

```dart
for (final riverpod in [FakeNamespace()])
  if (condition) {
    Object();
  } else
    runApp(riverpod.ProviderScope(child: const Placeholder()));
```

`riverpod` is still the loop-local `FakeNamespace` in the `else` arm, but the scanner ends its shadow at `Object();` and accepts it as the imported Riverpod prefix. The same broken helper is used by `_ifCaseShadowEnd` at line 482. This reopens a `missing_provider_scope` bypass in the repository-owned defense-in-depth guard.

**Fix:** Make `_statementEnd` parse complete Dart statement forms, including an optional `else` for `if`, and recursively consume loop, `do`, `try`/`catch`/`finally`, and switch statements; alternatively derive ranges from the analyzer AST. Add failing provider-contract and live-fixture cases for a for-header alias and an if-case binding whose protected root appears in a nested unbraced `else`/control-flow branch.

## Warnings

### WR-01: Locally shadowed `runApp` helpers are incorrectly treated as Flutter app roots

**Classification:** WARNING

**File:** `scripts/audit/provider_contract.dart:72-77, 764-820`

**Issue:** `_checkAppRoots` passes every unqualified token sequence named `runApp` to `_findCalls`, but `_findCalls` only verifies receiver provenance for qualified calls. Valid Dart may declare a local function, parameter, or variable named `runApp`; invoking that local symbol is not an application root. For example, a local `void runApp(Widget widget) {}` followed by `runApp(const Placeholder())` is reported as `missing_provider_scope`, even though Flutter's `runApp` was never called. The current shadow machinery protects only `ProviderScope` identities, not the `runApp` callee identity.

**Fix:** Track declarations that shadow the unqualified Flutter `runApp` import and exclude calls within their lexical range (or resolve the callee with the analyzer AST). Add bad/control tests for local-function, parameter, and variable shadows, while retaining the real unqualified Flutter-root negative.

---

_Reviewed: 2026-08-08T14:11:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
