---
phase: 17-manual-only-joy-sub-metric-happy-v2-03
plan: 02
subsystem: database
tags: [drift, migration, entry-source, sqlite-check, happy-v2-03]

requires:
  - phase: 17-01
    provides: corrected ROADMAP Phase 17 SC-3 scope
provides:
  - Drift schema v17 with transactions.entry_source defaulting to manual
  - Fresh-install CHECK constraint for manual/voice/ocr entry sources
  - v16-to-v17 raw ALTER TABLE migration with inline DEFAULT and CHECK
  - Fresh-install and migrated-path tests for default backfill and CHECK enforcement
affects: [analytics-filtering, transaction-persistence, sync-mapper, entry-path-stamping]

tech-stack:
  added: []
  patterns:
    - Drift schema bump with raw customStatement for inline column CHECK
    - Raw sqlite3 migration test for migrated schema behavior

key-files:
  created:
    - test/unit/data/migrations/migration_v16_to_v17_test.dart
    - test/unit/data/migrations/entry_source_v17_migration_test.dart
    - .planning/phases/17-manual-only-joy-sub-metric-happy-v2-03/17-02-SUMMARY.md
  modified:
    - lib/data/tables/transactions_table.dart
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart

key-decisions:
  - "The v17 migration uses customStatement instead of migrator.addColumn so migrated databases receive the entry_source CHECK constraint."
  - "No entry_source index was added; existing transaction indices remain unchanged."

patterns-established:
  - "Fresh-install Drift constraints and migrated raw SQL constraints are tested separately when customConstraints cannot cover ALTER TABLE paths."

requirements-completed: [HAPPY-V2-03]

duration: 6 min
completed: 2026-05-21
---

# Phase 17 Plan 02: Entry Source Schema Foundation Summary

**Drift schema v17 adds `transactions.entry_source` with manual default, a 3-value CHECK, and dual-path migration tests.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-21T00:52:18Z
- **Completed:** 2026-05-21T00:58:01Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `entrySource` to the `Transactions` table with `DEFAULT 'manual'`.
- Bumped `AppDatabase.schemaVersion` from 16 to 17 and added an `if (from < 17)` migration using raw `ALTER TABLE ... DEFAULT ... CHECK(...)`.
- Regenerated Drift output so `TransactionRow` and `TransactionsCompanion` expose `entrySource`.
- Added fresh-install and migrated-from-v16 tests that verify default manual, accepted `voice`/`ocr`, invalid value rejection, and migrated column metadata.

## Task Commits

Each task was committed atomically:

1. **Task 1: Declare entry_source column + CHECK; bump schemaVersion to 17** - `1682b01` (feat)
2. **Task 2: Migration round-trip test for fresh schema path** - `45d9f61` (test)
3. **Task 3: Raw-sqlite3 migrated-from-v16 path test** - `c3f83b1` (test)

**Plan metadata:** pending current commit

## Files Created/Modified

- `lib/data/tables/transactions_table.dart` - Adds `entrySource` and fresh-install CHECK constraint.
- `lib/data/app_database.dart` - Bumps schema to 17 and adds customStatement migration.
- `lib/data/app_database.g.dart` - Regenerated Drift table/data/companion accessors for `entrySource`.
- `test/unit/data/migrations/migration_v16_to_v17_test.dart` - Fresh-install default and CHECK coverage.
- `test/unit/data/migrations/entry_source_v17_migration_test.dart` - Raw migrated-schema DEFAULT/CHECK coverage.

## Decisions Made

- Used raw `customStatement` for the migration path because Drift table-level `customConstraints` apply on fresh table creation, not existing tables altered in place.
- Kept `customIndices` unchanged; Phase 17 follows D-05 and does not add an `entry_source` index.

## Verification

- `flutter pub run build_runner build --delete-conflicting-outputs` exited 0 and regenerated `lib/data/app_database.g.dart`.
- `flutter analyze lib/data/tables/transactions_table.dart lib/data/app_database.dart test/unit/data/migrations/migration_v16_to_v17_test.dart test/unit/data/migrations/entry_source_v17_migration_test.dart` returned `No issues found`.
- `flutter test test/unit/data/migrations/migration_v16_to_v17_test.dart test/unit/data/migrations/entry_source_v17_migration_test.dart` passed 11 tests.
- Required greps passed for `entrySource`, schemaVersion 17, customStatement SQL, generated `Value<String> entrySource`, and absence of `migrator.addColumn(transactions, transactions.entrySource)`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Targeted analyze flagged the first migration SQL literal for `prefer_single_quotes`. The SQL was rewritten as adjacent triple-single-quoted Dart strings, preserving the exact emitted SQL.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 17-03 can add the domain `EntrySource` enum and sync mapper field now that persistence exposes the column and generated companion field.

---
*Phase: 17-manual-only-joy-sub-metric-happy-v2-03*
*Completed: 2026-05-21*
