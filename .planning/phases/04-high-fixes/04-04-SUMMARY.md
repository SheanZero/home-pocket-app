---
phase: "04-high-fixes"
plan: "04-04"
subsystem: "test-infrastructure"
tags:
  - mocktail_migration
  - test_infra
  - high_fixes
dependency_graph:
  requires:
    - "04-06 (Wave 0 — characterization tests for covered source files)"
    - "04-03 (Wave 1 parallel — RLS test/mock deletion)"
  provides:
    - "Zero Mockito files in test/ — fully Mocktail-only test suite"
    - "mockito removed from pubspec.yaml dev_dependencies"
    - "coverage_gate.dart passing at ≥80% for all 12 migrated source files"
  affects:
    - "04-05 (provider-graph hygiene test — relies on Mocktail-only convention)"
tech_stack:
  added: []
  patterns:
    - "Inline Mocktail fakes: `class _MockX extends Mock implements X {}` per-file"
    - "registerFallbackValue + _FakeX pattern for non-primitive any() matchers"
    - "Closure-wrapped stubs: `when(() => mock.method(any())).thenAnswer(...)`"
    - "Exact-value verification replacing captured-index approach"
key_files:
  created: []
  modified:
    - test/unit/application/accounting/create_transaction_use_case_test.dart
    - test/unit/application/accounting/delete_transaction_use_case_test.dart
    - test/unit/application/accounting/ensure_default_book_use_case_test.dart
    - test/unit/application/accounting/get_transactions_use_case_test.dart
    - test/unit/application/accounting/seed_categories_use_case_test.dart
    - test/unit/application/voice/fuzzy_category_matcher_test.dart
    - test/unit/application/voice/parse_voice_input_use_case_test.dart
    - test/unit/application/voice/record_category_correction_use_case_test.dart
    - test/unit/application/family_sync/shadow_book_service_test.dart
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
    - test/unit/data/repositories/transaction_repository_impl_test.dart
    - test/unit/features/home/presentation/providers/today_transactions_provider_test.dart
    - test/integration/sync/bill_sync_round_trip_test.dart
    - pubspec.yaml
    - lib/data/daos/transaction_dao.dart
    - lib/data/repositories/transaction_repository_impl.dart
  deleted:
    - test/unit/application/accounting/create_transaction_use_case_test.mocks.dart
    - test/unit/application/accounting/delete_transaction_use_case_test.mocks.dart
    - test/unit/application/accounting/ensure_default_book_use_case_test.mocks.dart
    - test/unit/application/accounting/get_transactions_use_case_test.mocks.dart
    - test/unit/application/accounting/seed_categories_use_case_test.mocks.dart
    - test/unit/application/voice/fuzzy_category_matcher_test.mocks.dart
    - test/unit/application/voice/parse_voice_input_use_case_test.mocks.dart
    - test/unit/application/voice/record_category_correction_use_case_test.mocks.dart
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.mocks.dart
    - test/unit/application/family_sync/shadow_book_service_test.mocks.dart
    - test/unit/data/repositories/transaction_repository_impl_test.mocks.dart
    - test/unit/features/home/presentation/providers/today_transactions_provider_test.mocks.dart
    - test/integration/sync/bill_sync_round_trip_test.mocks.dart
    - test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart
    - test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart
decisions:
  - "D-mocktail-update: TransactionRepositoryImpl.update() bug fixed (softDelete+insert → updateTransaction) as part of coverage gate work; DAO gained updateTransaction() method using Drift .write()"
  - "D-rls-pre-delete: resolve_ledger_type_service_test.dart and its mock deleted in this plan (Plan 04-03's parallel worktree hadn't applied the deletion); documented as deviation"
  - "D-captured-to-exact: today_transactions_provider_test.dart date-range test changed from Mockito-style captured-index to exact DateTime value verification (Mocktail captured order differs from Mockito)"
metrics:
  duration: "~90 minutes (across two agent sessions due to context compaction)"
  completed: "2026-04-26"
  tasks_completed: 5
  files_changed: 31
---

# Phase 04 Plan 04: Mocktail Big-Bang Migration Summary

**One-liner:** Migrated all 13 Mockito test fixtures to inline Mocktail fakes, deleted 13+ `.mocks.dart` files, removed mockito from pubspec.yaml, and verified ≥80% coverage gate on all 12 source files.

## What Was Done

Executed a complete big-bang migration from Mockito (code-generation-based) to Mocktail (inline hand-written fakes) across the entire test suite. Prior to this plan, 13 test files used `@GenerateMocks` annotations and imported generated `*.mocks.dart` artifacts. After this plan:

- `find test -name '*.mocks.dart'` returns 0 results
- `grep -rn 'package:mockito' test/` returns 0 matches
- `grep -rn '@GenerateMocks' test/` returns 0 matches
- `mockito` removed from `pubspec.yaml dev_dependencies`
- All 1183 tests pass
- Coverage gate: 12/12 source files ≥80%

## Commits

| Hash | Description |
|------|-------------|
| `b7f4c32` | test(04-04): migrate accounting + voice tests to Mocktail (HIGH-07 part 1 of 3) |
| `244e8b5` | test(04-04): migrate family_sync + data + home + integration tests to Mocktail (HIGH-07 part 2 of 3) |
| `eed295a` | chore(04-04): remove mockito dev_dep + close HIGH-07 (HIGH-07 part 3 of 3) |
| `5dc7048` | test(04-04): boost apply_sync_operations coverage to 83%+ (coverage gate) |

## Coverage Gate Results

| File | Covered/Total | % | Status |
|------|--------------|---|--------|
| create_transaction_use_case.dart | 52/60 | 86.67% | PASS |
| delete_transaction_use_case.dart | 10/11 | 90.91% | PASS |
| ensure_default_book_use_case.dart | 13/13 | 100.00% | PASS |
| get_transactions_use_case.dart | 14/14 | 100.00% | PASS |
| seed_categories_use_case.dart | 8/8 | 100.00% | PASS |
| apply_sync_operations_use_case.dart | 51/61 | 83.61% | PASS |
| shadow_book_service.dart | 21/22 | 95.45% | PASS |
| fuzzy_category_matcher.dart | 70/74 | 94.59% | PASS |
| parse_voice_input_use_case.dart | 25/26 | 96.15% | PASS |
| record_category_correction_use_case.dart | 4/4 | 100.00% | PASS |
| transaction_repository_impl.dart | 99/105 | 94.29% | PASS |
| today_transactions_provider.dart | 11/11 | 100.00% | PASS |

**Result: 12 checked, 0 failed (threshold: 80%)**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed TransactionRepositoryImpl.update() UNIQUE constraint bug**

- **Found during:** Task 5 (coverage gate boost for apply_sync_operations_use_case_test.dart)
- **Issue:** `update()` implemented as `softDelete(id) + insert(transaction)` — softDelete marks `isDeleted=true` but leaves the row in the DB; subsequent INSERT with same ID fails with SQLite UNIQUE constraint violation
- **Fix:** Added `TransactionDao.updateTransaction()` using Drift's `update(..).write()` for in-place field update; rewrote `TransactionRepositoryImpl.update()` to use the new DAO method with proper note encryption
- **Files modified:** `lib/data/daos/transaction_dao.dart`, `lib/data/repositories/transaction_repository_impl.dart`
- **Commit:** `5dc7048`

**2. [Rule 3 - Blocking] Pre-deleted resolve_ledger_type_service test files**

- **Found during:** Task 3 (mockito removal from pubspec.yaml)
- **Issue:** After removing `mockito` from pubspec.yaml, `resolve_ledger_type_service_test.mocks.dart` (which uses Mockito APIs) caused compile failures. Plan 04-03 was supposed to delete these files, but 04-03 runs in a parallel worktree and hadn't applied deletions to this worktree's branch.
- **Fix:** Deleted both `resolve_ledger_type_service_test.dart` and its `.mocks.dart` file in this plan's commit
- **Files deleted:** `test/unit/application/dual_ledger/resolve_ledger_type_service_test.dart`, `test/unit/application/dual_ledger/resolve_ledger_type_service_test.mocks.dart`
- **Commit:** `eed295a`

**3. [Rule 1 - Bug] Fixed today_transactions_provider_test captured-index approach**

- **Found during:** Task 2 (migration of today_transactions_provider_test.dart)
- **Issue:** Mockito's `verify(mock.method(captureAny)).captured` returns positional arguments in a different order than Mocktail; the test used `captured[3]` to access the `startDate` named parameter which returned `null` in Mocktail
- **Fix:** Replaced capture-based date verification with exact-value verification using pre-computed `expectedStart` and `expectedEnd` DateTime values
- **Files modified:** `test/unit/features/home/presentation/providers/today_transactions_provider_test.dart`
- **Commit:** `244e8b5`

**4. [Rule 2 - Missing] Added 7 additional test scenarios for apply_sync_operations_use_case.dart**

- **Found during:** Task 5 (coverage gate verification)
- **Issue:** Original migrated test only had 3 test scenarios covering 54.10% (33/61 lines) — below the 80% threshold
- **Fix:** Added 7 new test scenarios: insert op alias, update-when-exists, update-when-not-exists, null entityId skip, profile entityType, profile skipped without groupId, idempotent create
- **Files modified:** `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
- **Commit:** `5dc7048`

## Mocktail Migration Patterns Applied

### Inline fakes (no code generation)
```dart
class _MockTransactionRepository extends Mock implements TransactionRepository {}
class _FakeTransaction extends Fake implements Transaction {}

setUpAll(() {
  registerFallbackValue(_FakeTransaction());
});
```

### Closure-wrapped stubs
```dart
// Mocktail style (closure required)
when(() => mock.method(any())).thenAnswer((_) async {});
// NOT Mockito style: when(mock.method(any)).thenAnswer(...)
```

### Named parameter matchers
```dart
when(() => mockRepo.findByBookId(
  any(),
  limit: any(named: 'limit'),
  offset: any(named: 'offset'),
)).thenAnswer((_) async => []);
```

### Verify with exact values (not capture)
```dart
verify(() => mockRepo.findByBookId(
  'book_001',
  startDate: expectedStart,
  endDate: expectedEnd,
  limit: any(named: 'limit'),
  offset: any(named: 'offset'),
)).called(1);
```

## Known Stubs

None — all test data is fully wired to real or mock implementations. No placeholder values flow to UI rendering.

## Threat Flags

None — this plan only modifies test files, pubspec.yaml, and two DAO/repository source files. No new network endpoints, auth paths, or trust boundary changes introduced.

## Self-Check: PASSED

- [x] All 4 commits exist in git log: `b7f4c32`, `244e8b5`, `eed295a`, `5dc7048`
- [x] `find test -name '*.mocks.dart'` returns 0 results
- [x] `grep -rn 'package:mockito' test/` returns 0 matches
- [x] All 1183 tests pass (`flutter test`)
- [x] Coverage gate: 12/12 PASS at ≥80% threshold
- [x] SUMMARY.md created at `.planning/phases/04-high-fixes/04-04-SUMMARY.md`
