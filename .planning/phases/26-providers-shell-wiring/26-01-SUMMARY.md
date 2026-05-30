---
phase: 26-providers-shell-wiring
plan: "01"
subsystem: list-domain-models
tags:
  - freezed
  - domain-models
  - import-guard
  - test-stubs
dependency_graph:
  requires:
    - "25-domain-models-use-case (ListFilterState, Transaction)"
  provides:
    - "TaggedTransaction + MemberTag Freezed VOs (list provider return type)"
    - "lib/features/list/presentation/import_guard.yaml (deny rules)"
    - "Wave 0 test stubs for Plans 02 and 03"
  affects:
    - "26-02 (listFilterProvider implements against TaggedTransaction type)"
    - "26-03 (listTransactionsProvider returns List<TaggedTransaction>)"
tech_stack:
  added: []
  patterns:
    - "Freezed abstract class pattern matching list_sort_config.dart"
    - "import_guard.yaml deny rules matching analytics presentation pattern"
    - "Wave 0 test stubs with skip: parameter"
key_files:
  created:
    - lib/features/list/domain/models/tagged_transaction.dart
    - lib/features/list/domain/models/tagged_transaction.freezed.dart
    - lib/features/list/presentation/import_guard.yaml
    - test/unit/features/list/domain/models/tagged_transaction_test.dart
    - test/unit/features/list/presentation/providers/list_filter_notifier_test.dart
    - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
  modified: []
decisions:
  - "Used @freezed abstract class pattern (no private ._() constructor needed since no custom methods)"
  - "MemberTag built fully per D-07 — emoji + name fields for Phase 29 family attribution"
  - "TaggedTransaction.memberTag is nullable for own-book path this phase"
  - "import_guard.yaml copied exactly from analytics presentation pattern"
  - "Wave 0 test stubs use flutter_test only; no unreleased provider imports"
metrics:
  duration_seconds: 172
  completed_date: "2026-05-30"
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 0
---

# Phase 26 Plan 01: TaggedTransaction VOs + import_guard + Wave 0 stubs Summary

**One-liner:** TaggedTransaction + MemberTag Freezed VOs with generated .freezed.dart, presentation layer import_guard.yaml deny rules, and Wave 0 skip-stub test files for Plans 02 and 03.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | TaggedTransaction + MemberTag Freezed VOs + import_guard | 9ad2b67 | tagged_transaction.dart, tagged_transaction.freezed.dart, import_guard.yaml, tagged_transaction_test.dart |
| 2 | Wave 0 test stubs for Plans 02 and 03 | 094e03f | list_filter_notifier_test.dart, list_transactions_provider_test.dart |

## What Was Built

### TaggedTransaction + MemberTag Freezed VOs

`lib/features/list/domain/models/tagged_transaction.dart` defines two Freezed value objects:

- **`MemberTag`**: `{ required String emoji; required String name }` — family member attribution VO for Phase 29 shadow-book path. Built fully now per D-07 to avoid type changes in Phase 29.
- **`TaggedTransaction`**: `{ required Transaction transaction; MemberTag? memberTag }` — the sealed contract between `listTransactionsProvider` and the list UI. `memberTag` is `null` for all own-book transactions in Phase 26; Phase 29 fills it.

Both classes use the standard `@freezed abstract class X with _$X` pattern matching `list_sort_config.dart`. `build_runner` generated `tagged_transaction.freezed.dart` cleanly with zero errors.

### Presentation Layer import_guard.yaml

`lib/features/list/presentation/import_guard.yaml` denies:
- `package:home_pocket/infrastructure/**`
- `package:home_pocket/data/daos/**`
- `package:home_pocket/data/tables/**`

Exact copy of the analytics presentation deny rules, enforced by `custom_lint` at CI (T-26-01-IG mitigation).

### Domain Model Tests

`test/unit/features/list/domain/models/tagged_transaction_test.dart` — 8 tests covering:
- MemberTag equality by fields, copyWith immutability
- TaggedTransaction equality with null memberTag, equality with non-null memberTag, inequality when memberTags differ
- copyWith creates new object (original memberTag remains null)
- TaggedTransaction with null memberTag is valid (own-book path)

### Wave 0 Test Stubs

Both stubs use `skip:` parameter to prevent "No tests ran" failure while marking them as pending:
- `list_filter_notifier_test.dart`: `skip: 'wave 0 stub — provider ships in Plan 02'`
- `list_transactions_provider_test.dart`: `skip: 'wave 0 stub — provider ships in Plan 03'`

Plans 02 and 03 overwrite these stubs with real implementations.

## Verification Results

```
flutter test test/unit/features/list/ → All tests passed! (8 passed, 2 skipped)
flutter analyze lib/features/list/domain/models/tagged_transaction.dart → No issues found
flutter analyze test/unit/features/list/ → No issues found
```

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None — all placeholder test stubs are intentional (Wave 0 pattern per plan spec). The tagged_transaction.dart source has no stub values.

## Threat Flags

None — no new network endpoints, auth paths, or file access patterns introduced. The import_guard.yaml mitigates T-26-01-IG (presentation layer reaching infrastructure/daos/tables).

## Self-Check: PASSED

- [x] `lib/features/list/domain/models/tagged_transaction.dart` — FOUND
- [x] `lib/features/list/domain/models/tagged_transaction.freezed.dart` — FOUND (generated)
- [x] `lib/features/list/presentation/import_guard.yaml` — FOUND
- [x] `test/unit/features/list/domain/models/tagged_transaction_test.dart` — FOUND
- [x] `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — FOUND
- [x] `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` — FOUND
- [x] Commit 9ad2b67 — verified
- [x] Commit 094e03f — verified
