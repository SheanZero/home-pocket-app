---
phase: 36
plan: "02"
type: summary
status: complete
subsystem: data/migration
tags: [drift, migration, schema-v20, shopping-list, contract-test-green]
completed_date: "2026-06-07"
duration_minutes: 12

dependency_graph:
  requires:
    - "36-01 (Wave-0 contract test in RED state)"
  provides:
    - lib/data/tables/shopping_items_table.dart
    - lib/data/app_database.dart (schemaVersion 20, ShoppingItems wired)
    - lib/data/app_database.g.dart (regenerated)
  affects:
    - "Plans 05, 06 — ShoppingItemDao and ShoppingItemRepositoryImpl now have an ORM table to target"
    - "Plans 03, 04 — domain models and repository interface can reference ShoppingItemRow"

tech_stack:
  added: []
  patterns:
    - "Drift table with @DataClassName, TableIndex {#symbol} syntax, no @override on customIndices"
    - "schemaVersion bump + if (from < N) migrator.createTable() migration block"
    - "build_runner regeneration after @DriftDatabase annotation change"

key_files:
  created:
    - lib/data/tables/shopping_items_table.dart
  modified:
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart

decisions:
  - "Used migrator.createTable(shoppingItems) NOT customStatement DDL — ensures customConstraints and customIndices are emitted correctly by Drift codegen (RESEARCH Pattern 2)"
  - "Import ordered alphabetically: shopping_items_table between merchant_category_preferences_table and sync_queue_table"
  - "ShoppingItems in @DriftDatabase tables list between MerchantCategoryPreferences and SyncQueue (alphabetical)"

metrics:
  duration_minutes: 12
  tasks_completed: 2
  files_created: 1
  files_modified: 2
---

# Phase 36 Plan 02: ShoppingItems Table + v20 Migration Summary

ShoppingItems Drift table created, wired into AppDatabase with schemaVersion 20 and a `if (from < 20)` migration block. build_runner regenerated `app_database.g.dart`. Wave-0 contract test turns GREEN (6/6 tests pass).

## What Was Built

**`lib/data/tables/shopping_items_table.dart`** — 18-column Drift table:
- Identity: `id`, `deviceId`
- Visibility: `listType` (default 'private', D1)
- Content: `name`, `ledgerType`, `categoryId`, `tags` (D-01 JSON), `note` (ITEM-05 encrypted at repo boundary)
- Quantity/price: `quantity` (D-02 default 1), `estimatedPrice` (nullable int, ITEM-05)
- Completion: `completedAt` (D-03/SYNC-05 sticky-complete merge timestamp), `isCompleted`
- State: `sortOrder`, `isSynced`, `isDeleted`
- Attribution: `addedByBookId` (nullable, no FK)
- Timestamps: `createdAt`, `updatedAt`
- 4 CHECK constraints: list_type, quantity, ledger_type, estimated_price
- 5 TableIndex entries with `{#symbol}` syntax, no `@override` (CLAUDE.md pitfall #11)

**`lib/data/app_database.dart`** — 4 targeted edits:
1. Import `tables/shopping_items_table.dart` (alphabetical position)
2. `ShoppingItems,` added to `@DriftDatabase(tables: [...])` list
3. `schemaVersion => 20` (was 19)
4. `if (from < 20) { await migrator.createTable(shoppingItems); }` block after `from < 19` block

**`lib/data/app_database.g.dart`** — regenerated via `flutter pub run build_runner build --delete-conflicting-outputs` (exits 0, 34s, 1486 outputs written).

## Verification Results

| Check | Result |
|-------|--------|
| `shopping_items_v20_contract_test.dart` schemaVersion test | PASS (was RED at 19, now GREEN at 20) |
| `shopping_items_v20_contract_test.dart` column names test | PASS |
| `shopping_items_v20_contract_test.dart` CHECK constraint tests (3) | PASS |
| Total contract tests | 6/6 GREEN |
| `flutter analyze` on modified files | 0 issues |

## Deviations from Plan

None — plan executed exactly as written. The `-x` flag in the plan's verify command (`flutter test ... -x`) is not a valid Flutter test flag; used plain `flutter test` instead (same result, cosmetic deviation only).

## Known Stubs

None — this plan delivers physical schema only. No placeholder data or hardcoded values.

## Threat Flags

None — no new network endpoints or auth paths. The `list_type` and `ledger_type` CHECK constraints (T-36-01, T-36-02) are implemented as required by the threat model. The `note` field is nullable at schema level; encryption is enforced at repository boundary in Plan 06 (T-36-03). Migration slot is `from < 20` (not `from < 19`), verified correct (T-36-04).

## Self-Check: PASSED

- `lib/data/tables/shopping_items_table.dart` FOUND ✓
- `lib/data/app_database.dart` contains `schemaVersion => 20` ✓
- `lib/data/app_database.dart` contains `from < 20` ✓
- `lib/data/app_database.dart` contains `migrator.createTable(shoppingItems)` ✓
- `lib/data/app_database.g.dart` regenerated ✓
- Commit 02cf82f9 (Task 1: ShoppingItems table) FOUND ✓
- Commit e9c995e6 (Task 2: AppDatabase wiring + build_runner) FOUND ✓
- All 6 contract tests GREEN ✓
