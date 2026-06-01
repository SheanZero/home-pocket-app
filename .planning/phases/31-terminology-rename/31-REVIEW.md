---
phase: 31-terminology-rename
reviewed: 2026-06-01T13:20:00Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - lib/core/theme/app_colors.dart
  - lib/core/theme/app_theme_colors.dart
  - lib/data/app_database.dart
  - lib/data/daos/analytics_dao.dart
  - lib/data/repositories/analytics_repository_impl.dart
  - lib/data/tables/category_ledger_configs_table.dart
  - lib/data/tables/transactions_table.dart
  - lib/features/accounting/domain/models/transaction.dart
  - lib/features/accounting/domain/models/transaction_sync_mapper.dart
  - lib/application/analytics/demo_data_service.dart
  - lib/application/analytics/get_daily_vs_joy_snapshot_use_case.dart
  - lib/application/analytics/get_daily_vs_joy_snapshot_across_books_use_case.dart
  - lib/application/analytics/get_monthly_report_use_case.dart
  - lib/application/analytics/get_per_category_joy_breakdown_use_case.dart
  - lib/application/analytics/get_per_category_joy_breakdown_across_books_use_case.dart
  - lib/features/analytics/domain/models/analytics_aggregate.dart
  - lib/features/analytics/domain/models/ledger_snapshot.dart
  - lib/features/analytics/domain/models/per_category_joy_breakdown.dart
  - lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart
  - lib/features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart
  - lib/shared/constants/default_categories.dart
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
resolved_during_phase:
  - "CR-01 (BLOCKER): fixed — from<4 step restored to add soul_satisfaction; regression tests added"
  - "WR-04: closed — CR-01 regression tests added to ledger_type_v18_migration_test.dart"
---

# Phase 31: Code Review Report

**Reviewed:** 2026-06-01T13:20:00Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found (CR-01 BLOCKER resolved in-phase; 3 WARNING + 2 INFO quality-debt items remain)

> **Post-review resolution (2026-06-01):** CR-01 was verified against the codebase
> and fixed in commit (fix(31): CR-01 ...). The `from < 4` step now adds
> `soul_satisfaction` via a raw statement so the `from < 18` rename composes;
> positive + TRAP regression tests were added (closing WR-04). Full suite 2246/2246.
> The 3 remaining WARNINGs (WR-01/02/03) and 2 INFOs are incomplete-rename quality
> debt with no runtime impact — carried as non-blocking follow-ups.

## Summary

Phase 31 is a terminology rename (survival→daily, soul→joy; soul_satisfaction→joy_fullness)
spanning the `LedgerType` enum, Drift schema (v17→v18 migration), Freezed model field,
sync-mapper JSON keys, `AppColors` symbols, and ~21 source files. The persistence
round-trip and sync-mapper symmetry are **clean**: enum `LedgerType { daily, joy }`
serializes via `.name` to `'daily'`/`'joy'`, every DAO filter literal and use-case
comparison (`r.ledgerType == 'joy'`, `lt.ledgerType == 'daily'`) co-updated to the new
vocabulary, and the v18 migration's value-rewrite uses the correct read-old-write-new
direction (`CASE ledger_type WHEN 'survival' THEN 'daily' ...`). The intentional A1
deviation (`Book.survivalBalance`/`Book.soulBalance` column bindings preserved) is
internally consistent end-to-end — table, freezed model, repo interface, and JSON keys
all agree. No write-path string-literal corruption was found in the ledger_type rewrite.

**However**, the rename introduced one BLOCKER: the `from < 4` migration step was
mechanically renamed from `transactions.soulSatisfaction` to `transactions.joyFullness`,
which now collides with the unconditional `from < 18` `RENAME COLUMN soul_satisfaction
TO joy_fullness`. Any database upgrading from schema v1–v3 will crash mid-migration.
The v18 migration test does not exercise this path (it synthesizes a v17 schema directly),
so the regression is uncaught by CI.

The remaining findings are incomplete-rename quality debt (stale symbol names / doc strings
that still say "survival"/"soul"/"purple") that do not affect runtime behavior.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: v18 column-rename collides with renamed `from < 4` step — migration crash for v1–v3 databases

**File:** `lib/data/app_database.dart:59` (and `:396`)
**Issue:**
The Phase 31 rename changed the `from < 4` migration step from
`migrator.addColumn(transactions, transactions.soulSatisfaction)` to
`migrator.addColumn(transactions, transactions.joyFullness)`. Because the generated
column for `joyFullness` is named `joy_fullness` (verified in
`app_database.g.dart:4990-4991`), this step now emits
`ALTER TABLE transactions ADD COLUMN joy_fullness ...`.

Later, the `from < 18` block runs unconditionally for every upgrade and executes:
```
ALTER TABLE transactions RENAME COLUMN soul_satisfaction TO joy_fullness
```

Trace by source version:
- **v1–v3 → v18:** `from < 4` adds `joy_fullness`. Then `from < 18` tries to rename
  `soul_satisfaction` (which never existed for this device) to `joy_fullness` (which now
  already exists). SQLite throws `no such column: soul_satisfaction` (or a duplicate-column
  error). The whole `onUpgrade` transaction **rolls back / crashes** — the app cannot open
  its database. This is a crash + effective data-access-loss class.
- **v4–v17 → v18:** the device already has `soul_satisfaction` (added at v4 by the *old*
  code when the field was still `soulSatisfaction`); `from < 4` is skipped; the v18 rename
  succeeds. **OK.**

The git diff confirms this is a rename-introduced regression:
```
-          await migrator.addColumn(transactions, transactions.soulSatisfaction);
+          await migrator.addColumn(transactions, transactions.joyFullness);
```
The `ledger_type_v18_migration_test.dart` does NOT catch it — it builds a synthetic v17
table that already contains `soul_satisfaction` and runs only the `from < 18` sub-steps in
isolation; it never drives the real Drift `from < 4` `addColumn` path. No test exercises a
v1–v3 → v18 chain.

Mitigating context: CLAUDE.md states the app is "Phase 1 - Infrastructure Layer (v0.1.0)"
and migration comments assert a "pre-launch project," so v1–v3 databases may not exist in
production. But the broken path is still live in shipped migration code, will fault any
dev/CI/test database created at v1–v3, and silently couples two unrelated migration steps —
a latent crash that must not ship.

**Fix:** Keep the historical `from < 4` step emitting the column under its *original* name
so the v18 rename has a `soul_satisfaction` column to rename. The cleanest fix is a raw
statement that reproduces the v4-era DDL verbatim instead of using the (now-renamed)
generated column:
```dart
if (from < 4) {
  // Historical v4 added the column as soul_satisfaction. Emit the original
  // name so the v18 RENAME COLUMN soul_satisfaction -> joy_fullness has a
  // column to act on. Do NOT use migrator.addColumn(transactions.joyFullness)
  // here — that emits joy_fullness and collides with the v18 rename.
  await customStatement(
    "ALTER TABLE transactions ADD COLUMN soul_satisfaction INTEGER NOT NULL DEFAULT 2",
  );
}
```
Alternatively, guard the v18 rename so it is a no-op when `joy_fullness` already exists
(e.g. check `PRAGMA table_info(transactions)` before renaming). The raw-DDL approach is
preferred because it keeps the column-name history correct and matches the existing v18
test's assumption that `soul_satisfaction` exists pre-v18. After the fix, add a
v3→v18 (or v1→v18) full-chain migration test so the path is no longer uncovered.

## Warnings

### WR-01: Stale `wmSurvivalTagBg` / `wmSoulTagBg` extension getters — incomplete rename

**File:** `lib/core/theme/app_theme_colors.dart:59-62`
**Issue:**
The theme-color extension getters still carry the old vocabulary
(`wmSurvivalTagBg`, `wmSoulTagBg`) while the underlying `AppColors` symbols were renamed
to `daily`/`joy`. The mapping is functionally correct (`wmSurvivalTagBg → AppColors.dailyLight`,
`wmSoulTagBg → AppColors.joyLight`), so no visual bug results — but the half-renamed names
are now misleading: `daily_vs_joy_card.dart` reads `context.wmSoulTagBg` for the **Joy**
cell and `context.wmSurvivalTagBg` for the **Daily** cell, which reads as a swap until you
trace the getter. Five call sites depend on these stale names
(`home_screen.dart:299-300`, `hero_header.dart:86`, `total_spending_kpi_tile.dart:35`,
`daily_vs_joy_card.dart:327,398`, `joy_headline_kpi_tile.dart:58`).
**Fix:** Rename the getters to `wmDailyTagBg` / `wmJoyTagBg` (use `rename_symbol` for an
atomic cross-file update) so the terminology rename is complete and the Joy/Daily mapping is
self-evident at the call site.

### WR-02: `joy_celebration_overlay.dart` still purple-themed — file renamed soul→joy but theme not updated

**File:** `lib/features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart:5,79-125`
**Issue:**
The widget was renamed to `JoyCelebrationOverlay` but its body still hardcodes purple
(`Colors.purple`, `Colors.deepPurple`, `Colors.purple.shade300`) and the doc comment says
"A purple-themed celebration overlay." The Joy ledger's canonical accent is green
(`AppColors.joy = #47B88A`, per project memory and `app_colors.dart:44`). The overlay now
fires for a "joy transaction" but renders in the **soul** ledger's old purple palette —
an incomplete rename that produces an off-brand celebration color and contradicts the new
Joy = green theme. It also hardcodes raw `Colors.*` instead of `AppColors.joy*`
(CLAUDE.md: "No hardcoded values").
**Fix:** Replace the purple constants with `AppColors.joy` / `AppColors.joyLight`
(and update the doc comment) so the celebration matches the Joy ledger theme. If purple is
an intentional celebration accent independent of the ledger color, document that explicitly
to mark it as a deliberate exception.

### WR-03: Stale "Soul ledger" doc comment on the renamed column

**File:** `lib/data/tables/transactions_table.dart:34`
**Issue:**
The comment above the renamed `joyFullness` column still reads
`// Soul ledger satisfaction (1-10, default 2; ...)`. The field, DB column, enum value, and
sync key were all migrated to "joy," leaving this the lone "Soul" reference on the column —
misleading for future maintainers tracing the rename.
**Fix:** Update to `// Joy ledger fullness (1-10, default 2; D-10 unipolar positive scale)`
to match the field name and the `transaction.dart:43` doc string ("Joy ledger fullness").

### WR-04: v1–v3 → v18 migration chain has no test coverage

**File:** `test/unit/data/migrations/ledger_type_v18_migration_test.dart:40-89`
**Issue:**
The v18 migration test constructs a synthetic v17 schema (`_createV17Tables`) that already
contains `soul_satisfaction`, then runs only the `from < 18` sub-steps via a hand-mirrored
`_runV18MigrationSteps`. It never drives the real Drift `onUpgrade` from an early schema
version, so the `from < 4` → `from < 18` interaction (CR-01) is structurally invisible to
CI. The migration suite has per-step tests (v14, v15, v16, v17, v18) but no end-to-end
chain test from a v1–v3 baseline through to v18.
**Fix:** Add a migration test that creates the database at schema v3 (or uses Drift's
`SchemaVerifier` / step-by-step `runMigrationSteps`) and migrates straight to v18, asserting
the upgrade completes without throwing and that `joy_fullness` exists with preserved data.
This both proves the CR-01 fix and guards the chain against future per-step renames.

## Info

### IN-01: `DailyVsJoyCard` error arm discards error+stack with `(_, _)`

**File:** `lib/features/analytics/presentation/widgets/daily_vs_joy_card.dart:92`
**Issue:**
`error: (_, _) => AnalyticsCardErrorState(...)` silently drops both the error object and
stack trace. The UI degrades gracefully (retry button), so this is not a functional bug,
but the error is never logged, making field diagnosis of a failed snapshot fetch harder.
This mirrors the family arm at `:232`.
**Fix:** Optionally log the error/stack (e.g. via the project audit/logger) before rendering
the fallback, consistent with CLAUDE.md "Log detailed error context."

### IN-02: Doc comment references a non-existent "Soul column"

**File:** `lib/data/daos/analytics_dao.dart:656`
**Issue:**
The `getLedgerSnapshot` doc comment says "The Soul column's `avgSatisfaction` is computed
separately via [getJoyFullnessOverview]." After the rename this should read "Joy column."
Purely a documentation staleness item; code is correct.
**Fix:** Change "Soul column" to "Joy column" in the doc comment.

---

_Reviewed: 2026-06-01T13:20:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
