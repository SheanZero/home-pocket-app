---
phase: 24-data-layer-extension
plan: "02"
subsystem: data-layer
tags: [dao, drift, multi-book, reactive-stream, tdd]
dependency_graph:
  requires:
    - 24-01 (SortField/SortDirection enums from sort_config.dart)
  provides:
    - findByBookIds — one-shot multi-book query for LIST-02
    - watchByBookIds — reactive stream backbone for multi-book list screen
  affects:
    - Phase 26+ multi-book list screen (consumes watchByBookIds)
tech_stack:
  added: []
  patterns:
    - Drift customSelect with IN (?) parameterized binding
    - readsFrom: {_db.transactions} for watch reactivity
    - SortField enum → compile-time ORDER BY column selection
key_files:
  created:
    - test/unit/data/daos/transaction_dao_multi_book_test.dart
  modified:
    - lib/data/daos/transaction_dao.dart
decisions:
  - Used table.map(row.data) instead of mapFromRow (which is async); table.map() is the synchronous generated method accepting Map<String, dynamic>
  - SC#2 UPDATE test uses entrySource='manual' (not 'sync') — DB has CHECK constraint limiting entry_source to manual/voice/ocr
metrics:
  duration: "222 seconds (~4 min)"
  completed: "2026-05-29T05:59:45Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 1
---

# Phase 24 Plan 02: Multi-Book DAO Methods Summary

Added `findByBookIds` (one-shot query) and `watchByBookIds` (reactive stream) to `TransactionDao`. The watch variant is the backbone of LIST-02 — it eliminates `ref.invalidate` by having Drift auto-push new results whenever any write touches the transactions table.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | TDD: test file (RED) + findByBookIds + watchByBookIds (GREEN) | 5fe9dfe | lib/data/daos/transaction_dao.dart, test/unit/data/daos/transaction_dao_multi_book_test.dart |

## What Was Built

### findByBookIds

```dart
Future<List<TransactionRow>> findByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
})
```

- Single SQL query with `IN (?, ?, ...)` parameterized binding (T-24-02-01)
- Excludes `is_deleted = 0` rows
- `bookIds.isEmpty` short-circuit returns `const []` without SQL
- ORDER BY driven by `SortField` switch: `timestamp`, `COALESCE(updated_at, created_at)`, `amount` (T-24-02-02)
- No default limit applied (D-02)

### watchByBookIds

```dart
Stream<List<TransactionRow>> watchByBookIds(
  List<String> bookIds, {
  required DateTime startDate,
  required DateTime endDate,
  String? ledgerType,
  String? categoryId,
  SortField sortField = SortField.timestamp,
  SortDirection sortDirection = SortDirection.desc,
})
```

- Same SQL construction as `findByBookIds`
- `readsFrom: {_db.transactions}` mandatory for Drift table-change detection (SC#2)
- All filters bound in SQL — provider layer stays thin (D-03)
- `bookIds.isEmpty` short-circuit returns `const Stream.empty()`

## Test Coverage

**SC#1 — findByBookIds (6 tests):**
- Multi-book single call returns rows from both books
- Excludes `is_deleted=1` rows
- `ledgerType` filter works correctly
- `categoryId` filter works correctly
- `SortField.amount` + `SortDirection.asc` returns ascending by amount
- `SortField.updatedAt` uses `COALESCE(updated_at, created_at)` (null-safe)
- `bookIds=[]` returns empty without SQL

**SC#2 — watchByBookIds (3 tests):**
- Stream emits after insert (no ref.invalidate required)
- Stream emits `[]` after soft-delete
- Stream emits updated list after sync-applied UPDATE

**SC#4 — softDelete hash safety (1 test):**
- `softDelete()` sets `isDeleted=true` but leaves `currentHash` and `prevHash` unchanged
- `verifyChain` on all 3 rows (including soft-deleted) returns `ChainVerificationResult.valid`

**All 11 tests pass. `flutter analyze` reports 0 issues.**

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] mapFromRow is async — used synchronous table.map() instead**
- **Found during:** GREEN phase compilation
- **Issue:** Plan directed `_db.transactions.mapFromRow(row.data)` but `mapFromRow` takes a `QueryRow` (not `Map<String, dynamic>`) and is async (returns `Future<D>`). Using it would have returned `List<Future<TransactionRow>>`.
- **Fix:** Used the generated synchronous `_db.transactions.map(row.data)` which accepts `Map<String, dynamic>` directly.
- **Files modified:** `lib/data/daos/transaction_dao.dart`
- **Commit:** 5fe9dfe

**2. [Rule 1 - Bug] SC#2 UPDATE test used invalid entry_source value**
- **Found during:** GREEN phase test run (test 10 failed)
- **Issue:** Test used `entrySource: 'sync'` in `updateTransaction()` but the DB has a `CHECK` constraint: `entry_source IN ('manual', 'voice', 'ocr')`. This triggered `SqliteException(275): CHECK constraint failed`.
- **Fix:** Changed test to use `entrySource: 'manual'` (valid enum value that still simulates a sync-applied write for stream reactivity purposes).
- **Files modified:** `test/unit/data/daos/transaction_dao_multi_book_test.dart`
- **Commit:** 5fe9dfe

**3. [Rule 3 - Blocking] Test file needed Drift import for OrderingTerm**
- **Found during:** RED phase compilation
- **Issue:** SC#4 test used `OrderingTerm.asc(t.timestamp)` in a raw DB select but did not import `drift/drift.dart`.
- **Fix:** Added `import 'package:drift/drift.dart' show OrderingTerm;` to test file.
- **Files modified:** `test/unit/data/daos/transaction_dao_multi_book_test.dart`
- **Commit:** 5fe9dfe

## Verification Spot-Checks

```
grep -c "readsFrom: {_db.transactions}" lib/data/daos/transaction_dao.dart → 2
  (1 in code, 1 in doc comment — actual code has the required annotation)
grep -c "bookIds.isEmpty" lib/data/daos/transaction_dao.dart → 2
grep -c "COALESCE(updated_at, created_at)" lib/data/daos/transaction_dao.dart → 1
grep -c "import.*sort_config" lib/data/daos/transaction_dao.dart → 1
```

## Known Stubs

None — both methods are fully wired and tested.

## Threat Flags

No new security surface beyond what was planned. All bookId values use `Variable.withString` parameterized binding. ORDER BY uses compile-time string literals from `SortField` switch.

## Self-Check: PASSED

- [x] `lib/data/daos/transaction_dao.dart` exists and contains `findByBookIds` and `watchByBookIds`
- [x] `test/unit/data/daos/transaction_dao_multi_book_test.dart` exists with 11 passing tests
- [x] Commit `5fe9dfe` exists in git log
- [x] `flutter analyze lib/data/daos/transaction_dao.dart` → 0 issues
