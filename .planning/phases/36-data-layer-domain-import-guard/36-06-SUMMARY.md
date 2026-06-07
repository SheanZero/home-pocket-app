---
phase: 36
plan: "06"
subsystem: data/repository
tags: [feat, data, repository, encryption, shopping-list, tdd-green, wave-0-complete]
dependency_graph:
  requires:
    - "36-04 (ShoppingItem domain model + ShoppingItemRepository interface)"
    - "36-05 (ShoppingItemDao)"
  provides:
    - lib/data/repositories/shopping_item_repository_impl.dart
  affects:
    - "Phase 37 use cases — ShoppingItemRepositoryImpl now injectable"
    - "test/unit/data/repositories/shopping_item_repository_impl_test.dart — turns GREEN"
tech_stack:
  added: []
  patterns:
    - "Repository impl pattern: constructor injection of DAO + FieldEncryptionService"
    - "Silent decrypt failure: catch (_) { decryptedNote = null; } — no logging"
    - "asyncMap on reactive stream for async decryption per Drift stream + encryption pattern"
    - "jsonEncode/jsonDecode at repository boundary for List<String> tags"
key_files:
  created:
    - lib/data/repositories/shopping_item_repository_impl.dart
  modified: []
decisions:
  - "Relative imports used (not package:home_pocket/...) — matches TransactionRepositoryImpl style; analyzer enforces prefer_relative_imports"
  - "Empty tags stored as null (not empty JSON array '[]') — matches test assertion row!.tags isNull for empty list"
  - "LedgerType? conversion uses .where((e) => e.name == row.ledgerType).firstOrNull — handles null and unknown values safely"
  - "Private _encryptNote and _encodeTags helpers extracted to avoid duplication across insert/update/upsert"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-07"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 0
  files_deleted: 0
---

# Phase 36 Plan 06: ShoppingItemRepositoryImpl Summary

**One-liner:** `ShoppingItemRepositoryImpl` implements all 8 `ShoppingItemRepository` methods with note field encryption via `FieldEncryptionService`, JSON-encoded tags at the repository boundary, and async stream mapping — turning all Wave-0 tests GREEN.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implement ShoppingItemRepositoryImpl with encryption and JSON tags | c0c61fd7 | lib/data/repositories/shopping_item_repository_impl.dart |

## What Was Built

**`lib/data/repositories/shopping_item_repository_impl.dart`** — implements `ShoppingItemRepository` with 8 methods + 2 private helpers + `_toModel`:

| Method | Description |
|--------|-------------|
| `insert(ShoppingItem)` | Encrypts note, JSON-encodes tags, builds `ShoppingItemsCompanion`, delegates to `_dao.insert` |
| `update(ShoppingItem)` | Same encrypt+encode pattern; delegates to `_dao.update` |
| `softDelete(String)` | Delegates directly to `_dao.softDelete` |
| `softDeleteAllCompleted(String)` | Delegates directly to `_dao.softDeleteAllCompleted` |
| `findById(String)` | Fetches row via DAO; returns null if not found; awaits `_toModel` |
| `watchByListType(String)` | Chains `_dao.watchByListType(listType).asyncMap((rows) => Future.wait(rows.map(_toModel)))` |
| `upsert(ShoppingItem)` | Same encrypt+encode pattern; delegates to `_dao.upsert` |
| `reorder(String, int)` | Delegates directly to `_dao.reorder` |

**Security boundary (ITEM-05 / T-36-11):**
- `_encryptNote(String?)`: calls `_encryptionService.encryptField(note)` if non-null and non-empty; returns null otherwise
- `_toModel` decryption: `try { decryptedNote = await _encryptionService.decryptField(row.note!); } catch (_) { decryptedNote = null; }` — catch block is intentionally empty; no logging of ciphertext or exception (T-36-13)

**JSON tags boundary (D-01 / T-36-12):**
- `_encodeTags(List<String>)`: returns `jsonEncode(tags)` if non-empty, `null` for empty lists
- `_toModel` decode: `(jsonDecode(row.tags!) as List).cast<String>()` wrapped in try/catch; returns `[]` on malformed JSON

**LedgerType conversion:** `LedgerType.values.where((e) => e.name == row.ledgerType).firstOrNull` — null-safe, handles unknown enum values gracefully without throwing.

## Wave-0 Results

All 3 Wave-0 test files now GREEN:

| Test File | Tests | Result |
|-----------|-------|--------|
| `shopping_items_v20_contract_test.dart` | 6 | GREEN |
| `shopping_item_dao_test.dart` | 3 | GREEN |
| `shopping_item_repository_impl_test.dart` | 7 | GREEN |

Full data-layer suite: **244/244 GREEN**.

## Verification Results

| Check | Result |
|-------|--------|
| `flutter analyze lib/data/repositories/shopping_item_repository_impl.dart` | 0 issues |
| `flutter test .../shopping_item_repository_impl_test.dart` | 7/7 GREEN |
| `flutter test test/unit/data/` | 244/244 GREEN |
| `grep 'implements ShoppingItemRepository'` | PASS |
| `grep 'encryptField'` | PASS |
| `grep 'jsonEncode'` | PASS |
| `grep 'decryptedNote = null'` | PASS |

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed relative imports (prefer_relative_imports)**
- **Found during:** Task 1 analyzer check
- **Issue:** Plan spec said to use `package:home_pocket/...` absolute imports; analyzer reported 6 `prefer_relative_imports` violations
- **Fix:** Switched all imports to relative paths (same pattern as `TransactionRepositoryImpl`)
- **Files modified:** `lib/data/repositories/shopping_item_repository_impl.dart`
- **Commit:** c0c61fd7 (same commit)

## Known Stubs

None — all 8 methods are fully implemented. No placeholder patterns.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-36-11 mitigated | shopping_item_repository_impl.dart | `encryptField` called on every write; `decryptField` on every read; catch block silences errors without logging |
| T-36-12 mitigated | shopping_item_repository_impl.dart | `jsonEncode(List<String>)` from dart:convert; decode wrapped in try/catch |
| T-36-13 mitigated | shopping_item_repository_impl.dart | `catch (_) { decryptedNote = null; }` — empty catch, no `e.toString()` or logging |

## Self-Check: PASSED

- [x] `lib/data/repositories/shopping_item_repository_impl.dart` exists
- [x] `grep 'implements ShoppingItemRepository'` exits 0
- [x] `grep 'encryptField'` exits 0
- [x] `grep 'jsonEncode'` exits 0
- [x] `grep 'decryptedNote = null'` exits 0
- [x] `flutter test .../shopping_item_repository_impl_test.dart` — 7/7 GREEN
- [x] `flutter test test/unit/data/` — 244/244 GREEN
- [x] `flutter analyze .../shopping_item_repository_impl.dart` — 0 issues
- [x] Commit c0c61fd7 exists in git log
