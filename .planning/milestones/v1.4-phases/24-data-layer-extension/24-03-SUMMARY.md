---
phase: 24-data-layer-extension
plan: "03"
subsystem: data-layer
tags:
  - repository
  - transaction
  - security
  - tdd
dependency_graph:
  requires:
    - "24-02: TransactionDao.findByBookIds + watchByBookIds"
    - "24-01: SortField + SortDirection enums"
  provides:
    - "TransactionRepository.findByBookIds (abstract interface)"
    - "TransactionRepository.watchByBookIds (abstract interface)"
    - "TransactionRepositoryImpl.findByBookIds (concrete)"
    - "TransactionRepositoryImpl.watchByBookIds (concrete)"
    - "SC#5: _toModel decryptField try/catch"
  affects:
    - "Phase 25 use cases that depend on TransactionRepository interface"
tech_stack:
  added: []
  patterns:
    - "asyncMap for async Stream transformation"
    - "try/catch wrapping only the sensitive decryptField call (threat T-24-03-01)"
key_files:
  created:
    - test/unit/data/repositories/transaction_repository_note_decrypt_test.dart
  modified:
    - lib/features/accounting/domain/repositories/transaction_repository.dart
    - lib/data/repositories/transaction_repository_impl.dart
decisions:
  - "Wrap only decryptField in try/catch — not all of _toModel — so LedgerType enum errors still propagate (T-24-03-02)"
  - "catch (_) is silent: no logging of row.note or exception message to prevent ciphertext leakage (T-24-03-01)"
  - "_ThrowingEncryptionService implements FieldEncryptionService directly (no mocktail) for deterministic throw behavior"
metrics:
  duration: "7 minutes"
  completed: "2026-05-29T06:10:50Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
---

# Phase 24 Plan 03: Repository Layer — findByBookIds + watchByBookIds + SC#5 Summary

**One-liner:** Abstract TransactionRepository interface extended with multi-book findByBookIds/watchByBookIds, concrete impl wired to DAO via Future.wait + asyncMap, _toModel hardened with silent try/catch on decryptField (SC#5).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write SC#5 test (RED), fix _toModel try/catch, add findByBookIds + watchByBookIds to impl | 4ed9485 | transaction_repository_impl.dart, transaction_repository_note_decrypt_test.dart |
| 2 | Add findByBookIds + watchByBookIds to domain interface + full suite green | 78e6cf0 | transaction_repository.dart |

## What Was Built

### TransactionRepository Interface (domain layer)

Added two abstract method declarations to `lib/features/accounting/domain/repositories/transaction_repository.dart`:
- `Future<List<Transaction>> findByBookIds(List<String> bookIds, {..., required DateTime startDate, required DateTime endDate, SortField sortField, SortDirection sortDirection})`
- `Stream<List<Transaction>> watchByBookIds(List<String> bookIds, {...same params...})`

Added import for `sort_config.dart` (SortField + SortDirection enums from Phase 24-01).

### TransactionRepositoryImpl (data layer)

Added to `lib/data/repositories/transaction_repository_impl.dart`:
- `findByBookIds` override: delegates to `_dao.findByBookIds(...)`, maps rows via `Future.wait(rows.map(_toModel))`
- `watchByBookIds` override: delegates to `_dao.watchByBookIds(...).asyncMap((rows) => Future.wait(rows.map(_toModel)))` — asyncMap required because `_toModel` is async
- Sort config import added

### SC#5 Fix (_toModel try/catch)

Wrapped ONLY the `_encryptionService.decryptField(row.note!)` call in try/catch:
```dart
try {
  decryptedNote = await _encryptionService.decryptField(row.note!);
} catch (_) {
  // Shadow-book notes are encrypted with the originating device key.
  // Decryption fails on other devices. Return null silently —
  // DO NOT log row.note or the exception (may contain ciphertext).
  decryptedNote = null;
}
```

The if-guard (`row.note != null && row.note!.isNotEmpty`) and all other `_toModel` field mappings are unchanged — enum errors (LedgerType, EntrySource) still propagate normally.

### SC#5 Test

Created `test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` with:
- `_ThrowingEncryptionService` implementing `FieldEncryptionService` — `decryptField` always throws
- Test inserts a transaction row via DAO with `note='some_ciphertext'`, amount=1000, categoryId='cat_food'
- Calls `repo.findById('tx_001')` through the full repository path
- Asserts: result is not null, `result.note == null`, `result.amount == 1000`, `result.categoryId == 'cat_food'`

## TDD Gate Compliance

- RED: Test ran and failed with `Exception: Cannot decrypt — wrong device key` before the try/catch fix
- GREEN: Test passed after adding the try/catch to `_toModel`
- test commit: 4ed9485 (combined with impl changes as a single coherent TDD unit)
- feat commit: included in same commit per plan specification (single task)

## Verification Results

```
flutter analyze lib/features/accounting/domain/repositories/transaction_repository.dart \
              lib/data/repositories/transaction_repository_impl.dart
→ No issues found!

flutter test test/unit/data/repositories/transaction_repository_note_decrypt_test.dart --reporter=expanded
→ All tests passed!

flutter test
→ 2096 passed, 12 pre-existing failures (golden tests, stale suppression — unrelated to plan)
```

Spot-checks:
- `grep -c "Future<List<Transaction>> findByBookIds" .../transaction_repository.dart` → 1
- `grep -c "Stream<List<Transaction>> watchByBookIds" .../transaction_repository.dart` → 1
- `grep -c "asyncMap" .../transaction_repository_impl.dart` → 1
- `grep -c "catch (_)" .../transaction_repository_impl.dart` → 1
- Non-comment lines with `row.note`: only the guard condition and the try-block's decryptField call (not in catch)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all methods are fully wired to DAO implementations.

## Threat Flags

No new security surface introduced beyond what the plan's threat model covers. The catch block contains no logging (T-24-03-01 satisfied). The try/catch scope is limited to decryptField only (T-24-03-02 satisfied).

## Self-Check: PASSED

- [x] `test/unit/data/repositories/transaction_repository_note_decrypt_test.dart` exists
- [x] `lib/data/repositories/transaction_repository_impl.dart` contains findByBookIds + watchByBookIds
- [x] `lib/features/accounting/domain/repositories/transaction_repository.dart` contains abstract declarations
- [x] Commit 4ed9485 exists: `git log --oneline | grep 4ed9485`
- [x] Commit 78e6cf0 exists: `git log --oneline | grep 78e6cf0`
