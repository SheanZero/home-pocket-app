---
phase: 31-terminology-rename
plan: "01"
subsystem: testing
tags: [sqlite3, drift, migration, tdd, flutter, dart]

requires: []
provides:
  - "Wave-0 RED migration test pinning the v18 schema contract (D-02 + D-16) before any rename implementation exists"
affects:
  - 31-02 (implements v18 migration that turns this GREEN)
  - 31-03 through 31-06 (all subsequent plans depend on this contract being locked)

tech-stack:
  added: []
  patterns:
    - "raw-sqlite3 in-memory migration contract test (mirrors entry_source_v17 analog)"
    - "_runVNMigrationSteps as executable contract pattern — test helper SQL must be verbatim copy of onUpgrade SQL"
    - "DROP INDEX before RENAME TABLE to avoid index-name collision on recreate"

key-files:
  created:
    - test/unit/data/migrations/ledger_type_v18_migration_test.dart
  modified: []

key-decisions:
  - "Use raw-sqlite3 in-memory style (not forTesting()) to exercise the OLD CHECK(ledger_type IN ('survival','soul')) constraint directly"
  - "Drop old indices explicitly before RENAME TABLE + new CREATE INDEX — SQLite preserves index names on RENAME, causing CREATE INDEX to fail if IF NOT EXISTS is omitted and the old index name is still live"
  - "_runV18MigrationSteps wraps all three sub-steps in BEGIN/COMMIT for atomicity, matching the transaction(() async {}) wrapper Plan 02 will use"

patterns-established:
  - "DROP INDEX IF EXISTS before RENAME TABLE in migration contract tests to avoid index-name collision"

requirements-completed: [TERMID-03]

duration: 15min
completed: "2026-06-01"
---

# Phase 31 Plan 01: Wave-0 RED v18 Migration Test Summary

**Raw-sqlite3 migration contract test pinning D-02 (survival/soul→daily/joy enum rewrite + CHECK recreate) and D-16 (soul_satisfaction→joy_fullness column rename) — intentionally RED on v17 tree until Plan 31-02 ships the implementation.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-06-01T00:51:26Z
- **Completed:** 2026-06-01T00:56:43Z
- **Tasks:** 1
- **Files created:** 1

## Accomplishments

- Created `test/unit/data/migrations/ledger_type_v18_migration_test.dart` (478 lines) with 6 behavior tests
- Implemented `_createV17Tables` helper that creates the pre-migration sqlite3 schema with OLD CHECK(ledger_type IN ('survival','soul')) and `soul_satisfaction` column
- Implemented `_runV18MigrationSteps` contract helper with 3 atomically-wrapped sub-steps: (1) table-recreate category_ledger_configs with new CHECK(IN('daily','joy')); (2) UPDATE transactions ledger_type 'survival'/'soul' → 'daily'/'joy'; (3) RENAME COLUMN soul_satisfaction TO joy_fullness
- Test 1 (schemaVersion guard) is RED: `Expected: <18>, Actual: <17>` — confirmed on current v17 tree
- Tests 2–6 (raw-sqlite3 contract) all PASS, confirming the migration helper is correct and will validate Plan 02's onUpgrade implementation

## Task Commits

1. **Task 1: Write RED v18 migration test** - `d8568192` (test)

## Files Created/Modified

- `test/unit/data/migrations/ledger_type_v18_migration_test.dart` — Wave-0 RED migration contract test; 6 tests covering D-02 enum rewrite, CHECK recreate accept/reject (T-31-01), configs rewrite + index preservation (T-31-02 A5), D-16 column rename, row-count invariant

## Decisions Made

- **raw-sqlite3 over AppDatabase.forTesting()**: The v18 migration needs to seed rows against the OLD CHECK(ledger_type IN ('survival','soul')). Using raw sqlite3 in-memory gives full control over the pre-migration DDL including the old CHECK, whereas `forTesting()` already applies the current (post-rename) schema.
- **DROP INDEX before RENAME TABLE**: SQLite preserves index names globally when a table is renamed — `idx_category_ledger_configs_ledger_type` on `category_ledger_configs` becomes associated with `category_ledger_configs_old` after RENAME, but the name is still live. A subsequent `CREATE INDEX idx_...` on the new `category_ledger_configs` table fails with "already exists" unless the old index is dropped first. Pattern: `DROP INDEX IF EXISTS` → `RENAME TABLE` → `CREATE TABLE` → `CREATE INDEX`.
- **BEGIN/COMMIT wrapping**: All three sub-steps wrapped in a single transaction to match the `transaction(() async {})` atomicity that Plan 02 will use in Drift's onUpgrade.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed index-name collision in _runV18MigrationSteps**
- **Found during:** Task 1 (first test run)
- **Issue:** Initial `_runV18MigrationSteps` used `CREATE INDEX IF NOT EXISTS`, which silently skipped creating new indices on the rebuilt table because the old index names (from `_createV17Tables`) still existed after `ALTER TABLE ... RENAME TO _old`. Result: Test 4 (index preservation) failed with `Set:['sqlite_autoindex_...']` — only the PRIMARY KEY autoindex was found.
- **Fix:** Added `DROP INDEX IF EXISTS idx_category_ledger_configs_ledger_type` and `DROP INDEX IF EXISTS idx_category_ledger_configs_updated_at` before `RENAME TABLE`, then used plain `CREATE INDEX` (no `IF NOT EXISTS`) for the new table's indices.
- **Files modified:** test/unit/data/migrations/ledger_type_v18_migration_test.dart
- **Verification:** Test 4 passes; Tests 2–6 all green; only Test 1 (schemaVersion) remains RED as required.
- **Committed in:** d8568192 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in migration contract helper)
**Impact on plan:** Fix was necessary to make the contract test correctly validate index preservation (T-31-02 / A5 safeguard). No scope creep.

## Issues Encountered

- SQLite index-name semantics: `RENAME TABLE` does not drop associated indices — their names persist globally. This is the documented SQLite behavior but required the explicit DROP INDEX pattern before any subsequent `CREATE INDEX` with the same name.

## Known Stubs

None — this is a test-only plan with no UI or data stubs.

## Threat Flags

None — no production code was added or modified.

## Self-Check

Files created:
- `test/unit/data/migrations/ledger_type_v18_migration_test.dart` ✓

Commits:
- `d8568192` ✓

Acceptance criteria:
- 0 analyzer issues on test file ✓
- `grep -c '_runV18MigrationSteps'` ≥ 2 → actual: 8 ✓
- `_targetSchemaVersion = 18` present ✓
- `grep -cE 'test\('` ≥ 6 → actual: 6 ✓
- Test exits non-zero (RED): `Expected: <18>, Actual: <17>` ✓
- `entry_source_v17_migration_test.dart` line 5 unchanged (`_targetSchemaVersion = 17`) ✓
- `git diff --name-only lib/` → empty (no production code touched) ✓

## Self-Check: PASSED

## Next Phase Readiness

- Wave-0 RED gate committed; Plan 31-02 can now implement the v18 migration in `app_database.dart` and `_runV18MigrationSteps` in the test file will validate it turns GREEN
- No blockers for Plan 31-02

---
*Phase: 31-terminology-rename*
*Completed: 2026-06-01*
