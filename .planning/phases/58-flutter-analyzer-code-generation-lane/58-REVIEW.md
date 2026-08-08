---
phase: 58-flutter-analyzer-code-generation-lane
reviewed: 2026-08-08T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - analysis_options.yaml
  - scripts/verify_tooling_guards.dart
  - scripts/audit/provider_contract.dart
  - test/architecture/tooling_guard_negative_fixture_test.dart
  - test/architecture/provider_contract_test.dart
  - test/architecture/providers_audit_contract_test.dart
  - pubspec.yaml
  - pubspec.lock
  - scripts/dependency_compatibility.dart
  - test/architecture/dependency_compatibility_contract_test.dart
  - docs/testing/STABLE_BASELINE.json
  - docs/testing/DEPENDENCY_COMPATIBILITY.md
  - scripts/verify_codegen_reproducibility.sh
  - test/architecture/codegen_reproducibility_contract_test.dart
  - .github/workflows/audit.yml
  - test/architecture/audit_yml_invariants_test.dart
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 58: Code Review Report

**Reviewed:** 2026-08-08T00:00:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The selected Flutter 3.44.8/Dart 3.12.2, analyzer 12.1.0, import_lint 2.0.0, and Riverpod lint 3.1.4 graph is consistently declared, and the reviewed source-contract suite passed. However, the repository-owned provider-root guard can be bypassed through a qualified Flutter call and can reject valid code due to file-global shadow tracking. Stable coverage also resolves dependencies without enforcing the committed lock, and the human contract documents a CI sequence the workflow no longer executes.

## Warnings

### WR-01: Qualified `runApp` calls bypass the provider-root contract

**File:** `scripts/audit/provider_contract.dart:503`

**Issue:** `_findCalls` skips every call whose preceding token is `.`. Consequently, valid Dart such as `import 'package:flutter/widgets.dart' as widgets;` followed by `widgets.runApp(const Placeholder())` is never checked. A production app root can therefore omit `ProviderScope` while both `provider_contract.dart` and the Phase 58 negative guards report success.

**Fix:** Track Flutter widgets import prefixes and treat `<verified-widgets-prefix>.runApp(...)` as an app-root call. Add a negative fixture for the qualified form and retain the existing exclusion for arbitrary instance-method calls.

### WR-02: Provider import aliases are treated as shadowed anywhere in a file

**File:** `scripts/audit/provider_contract.dart:301`

**Issue:** `_riverpodScopeBindings` builds one file-wide `scopeShadows` set, and `allowsQualified` ignores its `callOffset` parameter at lines 625-637. Thus a valid root such as `runApp(riverpod.ProviderScope(...))` in `main` is rejected if an unrelated or later helper has a parameter/local named `riverpod`. This false positive can break analysis/CI without any bad app root.

**Fix:** Make shadow detection lexical and call-site-aware (or use analyzer resolution). At minimum, only consider declarations whose lexical scope encloses the call, and add fixtures for a valid root plus a sibling/later function that declares `riverpod`.

### WR-03: The coverage job can resolve a graph different from the reviewed lockfile

**File:** `.github/workflows/audit.yml:94`

**Issue:** The independent `coverage` job uses `flutter pub get` without `--enforce-lockfile`. Unlike static analysis and guardrails, it can rewrite or re-resolve the dependency graph when a PR changes constraints without an updated lockfile. Coverage may then execute against packages that were not accepted by the Phase 58 compatibility/reproducibility gate.

**Fix:** Replace the command with `flutter pub get --enforce-lockfile` and extend `audit_yml_invariants_test.dart` (or the dependency workflow contract) to require lock enforcement in every Stable CI job that runs Flutter code.

### WR-04: The compatibility guide documents a retired inline Stable-CI path

**File:** `docs/testing/DEPENDENCY_COMPATIBILITY.md:64`

**Issue:** The guide says Stable static analysis runs `flutter pub get --enforce-lockfile` followed by the inline `dependency_compatibility.dart` command (lines 64-70). The actual authoritative path is the single `bash scripts/verify_codegen_reproducibility.sh` invocation at `audit.yml:42`, which owns both commands plus generation and architecture checks. The stale instructions invite a future duplicate or out-of-order CI gate.

**Fix:** Document the wrapper as the sole Stable static-analysis command and describe its ordered internals; retain direct validator commands only where they are explicitly intended for local diagnosis or beta probes.

---

_Reviewed: 2026-08-08T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
