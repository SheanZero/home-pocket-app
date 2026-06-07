---
phase: 31-terminology-rename
plan: "02"
subsystem: data/domain
tags: [drift, migration, enum-rename, freezed, flutter, dart, sqlite3]

requires:
  - 31-01 (Wave-0 RED migration test)

provides:
  - "LedgerType enum renamed daily/joy + Transaction.joyFullness field"
  - "v17→v18 Drift migration (CHECK recreate + ledger_type rewrite + column rename)"
  - "Wave-0 migration test GREEN (all 6 tests pass)"

affects:
  - 31-03 (ARB plans can now reference renamed identifiers)
  - 31-04 (color plans build on renamed enum)
  - 31-05 (class-rename plans build on renamed foundation)

tech-stack:
  added: []
  patterns:
    - "Perl-based mass enum rename across ~50 files + manual persistence literal cleanup"
    - "category_ledger_configs CHECK pre-upgrade at v14 migration step to unblock new vocab inserts"
    - "Legacy enum name mapping in v14 step using .name and const map fallback"
    - "Historical DDL restoration pattern for pre-migration test schemas (soul_satisfaction column)"

key-files:
  created: []
  modified:
    - lib/features/accounting/domain/models/transaction.dart
    - lib/data/app_database.dart
    - lib/data/tables/transactions_table.dart
    - lib/data/tables/category_ledger_configs_table.dart
    - lib/data/daos/analytics_dao.dart
    - lib/application/analytics/get_monthly_report_use_case.dart
    - lib/application/analytics/demo_data_service.dart
    - lib/features/accounting/domain/models/transaction_sync_mapper.dart
    - lib/shared/constants/default_categories.dart
    - lib/data/app_database.g.dart
    - lib/features/accounting/domain/models/transaction.freezed.dart
    - lib/features/accounting/domain/models/transaction.g.dart
    - test/unit/data/migrations/entry_source_v17_migration_test.dart
    - test/unit/data/migrations/migration_v15_to_v16_test.dart
    - test/unit/data/migrations/migration_v16_to_v17_test.dart
    - test/unit/data/migrations/category_v14_migration_test.dart
    - test/unit/data/migrations/index_v15_migration_test.dart
    - test/unit/data/phase6_database_coverage_test.dart
    - test/unit/data/daos/analytics_dao_happiness_test.dart
    - test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart
    - test/unit/data/daos/analytics_dao_per_category_test.dart
    - test/unit/data/daos/analytics_dao_test.dart
    - test/unit/data/daos/category_ledger_config_dao_test.dart
    - test/unit/data/daos/merchant_category_preference_dao_test.dart
    - test/integration/sync/bill_sync_round_trip_test.dart
    - test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart
    - test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
    - test/unit/application/family_sync/shadow_book_service_test.dart
    - test/unit/application/analytics/get_monthly_report_use_case_test.dart
    - test/unit/application/analytics/get_expense_trend_use_case_test.dart
    - test/unit/data/tables/transactions_table_test.dart
    - test/unit/data/repositories/transaction_repository_note_decrypt_test.dart

decisions:
  - "Use Perl for mass enum rename across ~50 files (faster than LSP symbol rename for this scope)"
  - "Historical DDL in test schemas must keep soul_satisfaction column name (pre-v18 state)"
  - "Add category_ledger_configs CHECK pre-upgrade inside from<14 block (not a new schema version) to handle v5-v13 devices that have old CHECK before v14 inserts"
  - "v5 migration INSERT uses 'daily' (not legacy 'survival') because createTable() creates current CHECK IN('daily','joy')"
  - "Sibling migration tests _targetSchemaVersion bumped to 18 (they assert db.schemaVersion == constant)"
  - "category_v14 test expects 'joy' for cat_pet/cat_allowance after rename"
  - "predicate drift guardrail test updated to assert new 'joy'/'daily' constants"

metrics:
  duration: ~47min
  started: "2026-06-01T00:57:53Z"
  completed: "2026-06-01T01:43:41Z"
  tasks: 3
  files_changed: 107
---

# Phase 31 Plan 02: LedgerType Rename + v18 Migration Summary

**LedgerType enum renamed survival→daily, soul→joy across all 242 call sites; Transaction.joyFullness replaces soulSatisfaction; schemaVersion bumped to 18 with atomic v18 onUpgrade block; Wave-0 migration test (Plan 01) turns GREEN.**

## Performance

- **Duration:** ~47 min
- **Started:** 2026-06-01T00:57:53Z
- **Completed:** 2026-06-01T01:43:41Z
- **Tasks:** 3
- **Files changed:** 107+ (107 in Task 1 commit, +1 in Task 2, +13 in Task 3)

## Accomplishments

### Task 1 — LedgerType Enum Rename + Field Rename + Persistence Literals

- Renamed `LedgerType { survival, soul }` → `{ daily, joy }` in `transaction.dart`
- Renamed `Transaction.soulSatisfaction` Freezed field → `joyFullness` (D-16)
- Updated persistence string literals (raw SQL constants, JSON keys, seed data):
  - `analytics_dao.dart`: `_soulExpenseFilter`/`_survivalExpenseFilter` constants updated to `'joy'`/`'daily'`
  - `get_monthly_report_use_case.dart`: ledger split comparisons updated
  - `demo_data_service.dart`: seed literals updated
  - `transaction_sync_mapper.dart`: JSON key `'soulSatisfaction'` → `'joyFullness'` (D-03)
  - `transactions_table.dart`: column name + CHECK literal updated
  - `category_ledger_configs_table.dart`: fresh-install CHECK updated to `IN ('daily', 'joy')`
- Used Perl mass-replace for ~50 files across lib/ and test/
- Regenerated transaction.freezed.dart, transaction.g.dart, app_database.g.dart via build_runner
- Updated test fixtures (mapper test, apply_sync test, shadow_book test, monthly_report test, etc.)
- Bumped sibling migration `_targetSchemaVersion` to 18 in entry_source_v17, index_v15, migration_v15_to_v16 tests

### Task 2 — v17→v18 Drift Migration

- Bumped `schemaVersion` from 17 to 18 in `app_database.dart`
- Added `if (from < 18)` block wrapped in `await transaction()` with 3 sub-steps:
  1. `category_ledger_configs` table-recreate: DROP INDEX → RENAME TO _old → `createTable` (new CHECK) → CREATE INDEX x2 (A5 safeguard) → INSERT...SELECT with CASE rewrite → DROP _old
  2. `UPDATE transactions SET ledger_type = 'daily' WHERE ledger_type = 'survival'` + `'joy'/'soul'`
  3. `ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness` (D-16)
- Wave-0 migration test now passes GREEN: all 6 tests including schemaVersion guard

### Task 3 — Build-Green Gate

- Identified and fixed additional test fixtures not caught by initial mass-replace
- **Critical discovery**: `category_ledger_configs` CHECK constraint conflict in migration chain
  - For v4-v8 devices upgrading to v18, v14 migration ran BEFORE v18 could update the CHECK
  - Added pre-upgrade step at start of `from < 14` block to recreate the table with new CHECK
  - Updated v5 migration INSERT to use `'daily'` (new vocab) since `createTable()` always creates current schema
  - Updated v14 migration to use `cfg.ledgerType.name` (new vocab) after the pre-upgrade
- Restored `soul_satisfaction` column name in historical test DDL schemas (merchant_dao v5, entry_source_v17, phase6 v4/v8 schemas)
- 2244/2244 tests pass; flutter analyze 0 errors; custom_lint 0; generated diff clean

## Task Commits

1. **Task 1: Rename LedgerType + joyFullness + persistence literals** — `13f0ccc6` (feat)
2. **Task 2: v17→v18 migration** — `0d938eb8` (feat)
3. **Task 3: Build-green gate + migration chain fix** — `d4cfa0e0` (fix)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Migration chain conflict: v14 migration fails for v4-v8 upgrade path**
- **Found during:** Task 3 (full test run)
- **Issue:** The `from < 14` migration step uses `migrator.createTable(categoryLedgerConfigs)` at v5 (which always creates the CURRENT schema with new CHECK `IN('daily','joy')`) and then inserts new vocab in v14. For devices upgrading from v8+ with OLD `category_ledger_configs` (old CHECK), v14 inserted new vocab (`'daily'`) which was rejected by the old CHECK.
- **Fix:** Added a `category_ledger_configs` table-recreate pre-step at the beginning of the `from < 14` block (before the `transaction()` wrapper): DROP INDEX IF EXISTS (both), RENAME to `_pre14`, `createTable` with new CHECK, copy data with CASE conversion (old → new), DROP `_pre14`. This ensures the CHECK is always new before any v14 inserts.
- **Files modified:** `lib/data/app_database.dart`
- **Commits:** `d4cfa0e0`

**2. [Rule 1 - Bug] Historical DDL in test schemas incorrectly renamed**
- **Found during:** Task 3 (test run)
- **Issue:** The Perl mass-replace script changed `soul_satisfaction` → `joy_fullness` everywhere, including in test files that create pre-migration (v5, v8, v16) raw sqlite3 schemas. Those schemas should preserve the OLD column name (they represent the database state BEFORE v18 migration).
- **Fix:** Restored `soul_satisfaction` column name in `merchant_category_preference_dao_test.dart` (v5 raw DDL), `entry_source_v17_migration_test.dart` (v16 raw DDL + v16/v17 INSERT helpers), and `phase6_database_coverage_test.dart` (v4/v8 raw DDL).
- **Files modified:** 3 test files
- **Commits:** `d4cfa0e0`

**3. [Rule 1 - Bug] predicate drift guardrail test asserted old string literals**
- **Found during:** Task 3 (analytics_dao_test.dart failure)
- **Issue:** Test `'soul and survival predicate constants remain byte-identical'` checked for exact source strings `"ledger_type = 'soul' ..."` and `"ledger_type = 'survival' ..."` using escaped string matching. Perl mass-replace didn't catch these (escaped quotes inside double-quoted strings).
- **Fix:** Manually updated the `contains()` assertions to `"ledger_type = 'joy' ..."` and `"ledger_type = 'daily' ..."`.
- **Files modified:** `test/unit/data/daos/analytics_dao_test.dart`
- **Commits:** `d4cfa0e0`

**4. [Rule 1 - Bug] category_v14_migration_test $now dropped from VALUES**
- **Found during:** Task 3 (test run)
- **Issue:** An early manual Perl command to replace `'soul'` → `'joy'` in category_v14 INSERT statements accidentally dropped the `$now` interpolation variable, resulting in `VALUES ('cat_pet', 'joy', )` (syntax error).
- **Fix:** Restored `$now` variable in both VALUES clauses.
- **Files modified:** `test/unit/data/migrations/category_v14_migration_test.dart`
- **Commits:** `d4cfa0e0`

**5. [Rule 2 - Missing] Sibling migration tests had stale _targetSchemaVersion = 17**
- **Found during:** Task 3
- **Issue:** `entry_source_v17_migration_test.dart`, `index_v15_migration_test.dart`, `migration_v15_to_v16_test.dart`, `migration_v16_to_v17_test.dart` all had `_targetSchemaVersion = 17` and asserted `db.schemaVersion == 17`. Bumping to 18 caused all these to fail.
- **Fix:** Updated all 4 test files to `_targetSchemaVersion = 18`. These tests verify that features from their respective version are INCLUDED in the current schema, not that the schema IS exactly that version.
- **Commits:** `13f0ccc6`, `d4cfa0e0`

---

**Total deviations:** 5 auto-fixed (all Rule 1 bugs or Rule 2 additions)
**Impact on plan:** The migration chain fix (Deviation 1) was the most complex, requiring a pre-upgrade step in the `from < 14` block. This deviation was not anticipated in the PLAN but correctly follows the RESEARCH §Pitfall 2 principle (ordering matters).

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond what the plan's threat model covers. The v18 migration is the sole runtime-state mutation.

## Self-Check

Files created/modified:
- `lib/features/accounting/domain/models/transaction.dart` — `{ daily, joy }` ✓
- `lib/data/app_database.dart` — `schemaVersion => 18` + `from < 18` block ✓
- `lib/data/tables/category_ledger_configs_table.dart` — `IN ('daily', 'joy')` ✓
- `lib/data/tables/transactions_table.dart` — `joy_fullness BETWEEN 1 AND 10` ✓

Commits:
- `13f0ccc6` ✓ (107 files)
- `0d938eb8` ✓ (1 file)
- `d4cfa0e0` ✓ (13 files)

Acceptance criteria:
- `grep -n 'enum LedgerType' transaction.dart` → `{ daily, joy }` ✓
- `grep -rnE 'LedgerType\.(survival|soul)\b' lib/ test/ | grep -v .g.dart/.freezed.dart` → 0 ✓
- `grep -rn 'soulSatisfaction' lib/ | grep -v .g.dart/.freezed.dart` → 0 ✓
- `schemaVersion => 18` ✓
- `from < 18` block with 3 sub-steps ✓
- Wave-0 test GREEN: 6/6 pass ✓
- flutter analyze 0 errors ✓
- custom_lint 0 issues ✓
- flutter test 2244/2244 pass ✓

## Self-Check: PASSED
