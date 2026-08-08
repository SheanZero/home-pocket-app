---
phase: 58-flutter-analyzer-code-generation-lane
reviewed: 2026-08-08T11:06:32Z
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

**Reviewed:** 2026-08-08T11:06:32Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The dependency and CI contracts are tightly specified, and the focused contract matrix passed. However, the repository-owned provider-root guard can be bypassed with a valid Dart invocation form, while its new lexical-shadow model still misclassifies several valid lexical scopes. The cross-process fixture lock also leaves the in-process queue permanently blocked if opening the lock fails.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Provider-root contract misses `runApp.call(...)`

**File:** `/Users/xinz/Development/home-pocket-app/scripts/audit/provider_contract.dart:599-607`

**Issue:** `_findCalls` records `runApp` only when its next token is `(`. Dart functions can also be invoked through their `call` member, so `runApp.call(const Placeholder())` (and `widgets.runApp.call(...)`) is a real Flutter application root but is silently ignored. An unscoped root written this way passes the owned provider contract and the negative tooling proof, defeating the Phase 58 D-04 guard.

**Fix:** Recognize the exact direct-function `.call(...)` form for both unqualified and verified Flutter import-prefix references, then run it through the same `_isScopedRoot` validation. Add unscoped and scoped `.call` fixtures for unqualified and qualified Flutter imports; continue to reject arbitrary receiver/member chains.

## Warnings

### WR-01: Lexical shadow ranges include unrelated class members and branches

**File:** `/Users/xinz/Development/home-pocket-app/scripts/audit/provider_contract.dart:329-389`

**Issue:** `_isScopeBrace` does not recognize class/mixin/extension bodies, so a member named `ProviderScope` or `riverpod` is treated as a library-wide declaration by `_isAtLibraryScope`. Separately, a pattern bound in an `if` condition is assigned the enclosing function block by `_scopeShadowFor`, and a `switch` case binding extends through later cases. Those names do not shadow an import outside their class/member, then-branch, or individual case. Consequently, valid Riverpod-wrapped roots can be rejected by CI merely because an unrelated member or earlier branch uses the same name.

**Fix:** Build scope records from declaration context rather than only the nearest recognized brace: classify type bodies as non-library scopes, bind `if`-case variables to the then statement/block, and terminate `switch` pattern bindings at the next `case`/`default` (or switch close). Add passing controls for a class member, a post-`if` root, and a later switch case.

### WR-02: Lock-acquisition failure poisons the fixture queue

**File:** `/Users/xinz/Development/home-pocket-app/scripts/verify_tooling_guards.dart:17-39`

**Issue:** The lock file is opened before the `try`/`finally`. If `.dart_tool` is absent or `lock.open` fails, `releaseQueue.complete()` is never reached. The initiating invocation throws and every later same-process invocation waits indefinitely at `await previous`. This makes the exported helper non-recoverable for a fresh/custom `workingDirectory` and can hang a test process after a transient filesystem failure.

**Fix:** Create `lock.parent` first, and put opening, locking, unlocking, closing, and `releaseQueue.complete()` under an outer `try`/`finally` that always releases the in-process queue. Add a test using a directory without `.dart_tool` and an injected/open-failure seam, followed by a second invocation that proves the queue remains usable.

---

_Reviewed: 2026-08-08T11:06:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
