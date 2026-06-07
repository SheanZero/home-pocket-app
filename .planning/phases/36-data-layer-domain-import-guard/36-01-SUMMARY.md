---
phase: 36
plan: "01"
type: summary
status: complete
subsystem: data/test
tags: [tdd, wave-0, shopping-list, contract-test, drift, red-phase]
completed_date: "2026-06-07"
duration_minutes: 4

dependency_graph:
  requires: []
  provides:
    - test/unit/data/migrations/shopping_items_v20_contract_test.dart
    - test/unit/data/daos/shopping_item_dao_test.dart
    - test/unit/data/repositories/shopping_item_repository_impl_test.dart
  affects:
    - "Plans 02, 05, 06 — production code will turn these RED tests GREEN"

tech_stack:
  added: []
  patterns:
    - "Wave-0 raw-sqlite3 contract test (mirrors entry_source_v17_migration_test.dart)"
    - "DAO test with AppDatabase.forTesting() + tearDown(db.close)"
    - "Repository test with _MockFieldEncryptionService + _ThrowingFieldEncryptionService"

key_files:
  created:
    - test/unit/data/migrations/shopping_items_v20_contract_test.dart
    - test/unit/data/daos/shopping_item_dao_test.dart
    - test/unit/data/repositories/shopping_item_repository_impl_test.dart
  modified: []

decisions:
  - "Wave-0 gate satisfied: verification harness created before any production code (D-03 TDD discipline)"
  - "Contract test uses equals(20) not greaterThanOrEqualTo for schemaVersion — strict assertion to catch version drift"
  - "DAO test hides drift isNotNull/isNull to avoid ambiguous_import from flutter_test vs drift"
---

# Phase 36 Plan 01: Wave-0 TDD Test Scaffold Summary

Three test scaffold files created that define the verification harness before any production code is written. All three are intentionally in RED state — production code does not exist yet.

## What Was Built

**Wave-0 contract test** (`shopping_items_v20_contract_test.dart`): Asserts `schemaVersion == 20` (FAILS RED at 19) and validates the v20 physical schema including all 18 column names, `list_type` CHECK constraint acceptance/rejection, `completed_at` NULL acceptance (D-03/SYNC-05), and soft-delete flag persistence. Raw-sqlite3 group tests PASS (they use the `_createV20ShoppingItemsTable` DDL helper directly, not the ORM).

**Wave-0 DAO test** (`shopping_item_dao_test.dart`): Declares tests for `watchByListType` ordering (`ORDER BY is_completed ASC, sort_order ASC, created_at ASC` — DONE-02), soft-delete exclusion from the stream while row persists with `isDeleted=true`, and `upsert` insert+update round-trip. FAILS RED: `ShoppingItemDao` import does not exist.

**Wave-0 repository test** (`shopping_item_repository_impl_test.dart`): Declares tests for `note` encryption called/skipped, `tags` JSON encode/decode, `estimatedPrice` integer storage, `findById` decrypt+decode, and `_ThrowingFieldEncryptionService` silent decrypt-failure behaviour (ITEM-05). FAILS RED: `ShoppingItemDao`, `ShoppingItemRepositoryImpl`, `ShoppingItem` imports do not exist.

## RED State Verification

| File | RED Evidence | Expected Turn-GREEN Plan |
|------|-------------|--------------------------|
| `shopping_items_v20_contract_test.dart` | schemaVersion test: `Expected: <20>, Actual: <19>` (1 FAILED, 5 PASSED) | Plan 02 (migration + table) |
| `shopping_item_dao_test.dart` | 5 analyzer errors: `ShoppingItemDao` undefined, `ShoppingItemsCompanion` undefined | Plan 05 (DAO) |
| `shopping_item_repository_impl_test.dart` | 10 analyzer errors: 3 missing file URIs, 4 undefined classes | Plans 04, 05, 06 |

## Verification Results

- `flutter analyze test/unit/data/migrations/shopping_items_v20_contract_test.dart` → **No issues found** (file itself is syntactically valid; schemaVersion mismatch is runtime)
- `flutter test test/unit/data/migrations/shopping_items_v20_contract_test.dart` → **1 FAILED** (schemaVersion), **5 PASSED** (raw-sqlite3 group) — correct RED state
- DAO and repository test files have import-level errors (expected — production code does not exist yet)

## Deviations from Plan

**1. [Rule 1 - Bug] Fixed `ambiguous_import` for `isNotNull`/`isNull` in DAO test**
- **Found during:** Task 2 verify step
- **Issue:** `import 'package:drift/drift.dart'` exports its own `isNotNull` / `isNull` matchers that shadow `flutter_test`'s matchers, causing `ambiguous_import` analyzer errors
- **Fix:** Changed to `import 'package:drift/drift.dart' hide isNotNull, isNull;`
- **Files modified:** `test/unit/data/daos/shopping_item_dao_test.dart`
- **Commit:** b77b6870

## Known Stubs

None — these are test scaffold files with intentional RED state, not production stubs.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced in this plan (test-only files).

## Self-Check: PASSED

- `test/unit/data/migrations/shopping_items_v20_contract_test.dart` FOUND ✓
- `test/unit/data/daos/shopping_item_dao_test.dart` FOUND ✓
- `test/unit/data/repositories/shopping_item_repository_impl_test.dart` FOUND ✓
- Commit c5f3f6d6 FOUND ✓
- Commit b77b6870 FOUND ✓
- Commit 3d079fab FOUND ✓
