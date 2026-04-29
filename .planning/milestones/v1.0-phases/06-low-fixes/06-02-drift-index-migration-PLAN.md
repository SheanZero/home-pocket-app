---
phase: "06-low-fixes"
plan: "02"
type: execute
wave: 2
depends_on:
  - "06-01"
files_modified:
  - lib/data/tables/audit_logs_table.dart
  - lib/data/tables/user_profiles_table.dart
  - lib/data/tables/category_ledger_configs_table.dart
  - lib/data/app_database.dart
  - lib/data/app_database.g.dart
  - test/unit/data/migrations/index_v15_migration_test.dart
autonomous: true
requirements:
  - LOW-04
  - LOW-05
  - LOW-07
must_haves:
  truths:
    - "The three required Drift table files each declare TableIndex customIndices using Symbol syntax."
    - "AppDatabase schemaVersion is bumped from 14 to 15."
    - "The v15 migration creates all new indices for existing databases."
  artifacts:
    - path: "test/unit/data/migrations/index_v15_migration_test.dart"
      provides: "v14-to-v15 index migration coverage"
  key_links:
    - from: "lib/data/app_database.dart"
      to: "lib/data/tables/*_table.dart"
      via: "schemaVersion 15 migration creates matching index names"
      pattern: "CREATE INDEX IF NOT EXISTS idx_"
---

<objective>
Add the required Drift indices and verify v14-to-v15 migration behavior.

Purpose: satisfy LOW-04 and LOW-05 without changing table shapes or user-visible behavior.
Output: table-level `TableIndex` declarations, `schemaVersion => 15`, static migration SQL, regenerated Drift output, and migration tests.
</objective>

<execution_context>
@/Users/xinz/.codex/get-shit-done/workflows/execute-plan.md
@/Users/xinz/.codex/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/06-low-fixes/06-CONTEXT.md
@.planning/phases/06-low-fixes/06-RESEARCH.md
@.planning/phases/06-low-fixes/06-VALIDATION.md
@.planning/phases/06-low-fixes/06-PATTERNS.md
@.planning/codebase/CONVENTIONS.md
@.planning/codebase/TESTING.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add table indices and static v15 migration</name>
  <files>lib/data/tables/audit_logs_table.dart, lib/data/tables/user_profiles_table.dart, lib/data/tables/category_ledger_configs_table.dart, lib/data/app_database.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-PATTERNS.md
    - lib/data/tables/audit_logs_table.dart
    - lib/data/tables/user_profiles_table.dart
    - lib/data/tables/category_ledger_configs_table.dart
    - lib/data/tables/transactions_table.dart
    - lib/data/tables/books_table.dart
    - lib/data/app_database.dart
  </read_first>
  <action>
    In `audit_logs_table.dart`, add `List<TableIndex> get customIndices => [` with `TableIndex(name: 'idx_audit_logs_event', columns: {#event})`, `TableIndex(name: 'idx_audit_logs_device_id', columns: {#deviceId})`, and `TableIndex(name: 'idx_audit_logs_timestamp', columns: {#timestamp})`. In `user_profiles_table.dart`, add `TableIndex(name: 'idx_user_profiles_updated_at', columns: {#updatedAt})`. In `category_ledger_configs_table.dart`, add `TableIndex(name: 'idx_category_ledger_configs_ledger_type', columns: {#ledgerType})` and `TableIndex(name: 'idx_category_ledger_configs_updated_at', columns: {#updatedAt})`. Do not add `@override` to `customIndices`. In `app_database.dart`, change `schemaVersion => 14` to `schemaVersion => 15` and add an `if (from < 15)` migration block after the v14 block. The block must call `customStatement` with static SQL for each exact `CREATE INDEX IF NOT EXISTS ...` statement listed in `06-PATTERNS.md`; no string interpolation is allowed.
  </action>
  <acceptance_criteria>
    - `rg -n "idx_audit_logs_event|idx_audit_logs_device_id|idx_audit_logs_timestamp" lib/data/tables/audit_logs_table.dart` finds matches.
    - `rg -n "idx_user_profiles_updated_at" lib/data/tables/user_profiles_table.dart` finds one match.
    - `rg -n "idx_category_ledger_configs_ledger_type|idx_category_ledger_configs_updated_at" lib/data/tables/category_ledger_configs_table.dart` finds matches.
    - `rg -n "schemaVersion => 15|from < 15|CREATE INDEX IF NOT EXISTS idx_audit_logs_event" lib/data/app_database.dart` finds matches.
    - `rg -n "@override\\n\\s*List<TableIndex> get customIndices" lib/data/tables/audit_logs_table.dart lib/data/tables/user_profiles_table.dart lib/data/tables/category_ledger_configs_table.dart` finds zero matches.
  </acceptance_criteria>
  <verify>
    <automated>dart format . && flutter analyze</automated>
  </verify>
  <done>The table declarations and migration code define the exact v15 indices with project Drift conventions.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Add v15 index migration test and regenerate Drift output</name>
  <files>test/unit/data/migrations/index_v15_migration_test.dart, lib/data/app_database.g.dart</files>
  <read_first>
    - .planning/phases/06-low-fixes/06-VALIDATION.md
    - test/unit/data/migrations/category_v14_migration_test.dart
    - test/unit/data/daos/merchant_category_preference_dao_test.dart
    - lib/data/app_database.dart
    - lib/data/app_database.g.dart
  </read_first>
  <action>
    Create `test/unit/data/migrations/index_v15_migration_test.dart`. It must open a raw in-memory SQLite database representing schema version 14 with the three tables `audit_logs`, `user_profiles`, and `category_ledger_configs` but without the new indices. Then run the same v15 migration SQL from `app_database.dart` and assert via `PRAGMA index_list('audit_logs')`, `PRAGMA index_list('user_profiles')`, and `PRAGMA index_list('category_ledger_configs')` that the exact index names exist. Include a guard test asserting `AppDatabase.forTesting().schemaVersion == 15`. Run `flutter pub run build_runner build --delete-conflicting-outputs` after table/database source changes and commit the tracked `lib/data/app_database.g.dart` changes.
  </action>
  <acceptance_criteria>
    - `rg -n "schemaVersion.*15|PRAGMA index_list|idx_audit_logs_event|idx_user_profiles_updated_at|idx_category_ledger_configs_ledger_type" test/unit/data/migrations/index_v15_migration_test.dart` finds matches.
    - `flutter test test/unit/data/migrations/index_v15_migration_test.dart` exits 0.
    - `flutter pub run build_runner build --delete-conflicting-outputs` exits 0.
    - `git diff --exit-code lib/data/app_database.g.dart` exits 0 after generated output is committed or no diff remains.
  </acceptance_criteria>
  <verify>
    <automated>flutter test test/unit/data/migrations/index_v15_migration_test.dart && flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/data/app_database.g.dart && flutter analyze</automated>
  </verify>
  <done>The generated database output is current and the v15 migration test proves existing databases receive the new indices.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Migration SQL -> encrypted local database | Static migration statements change existing user databases. |
| Test old schema -> current migration | Raw schema fixture validates upgrade behavior. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-06-02-01 | T | `app_database.dart` v15 migration | mitigate | Use literal `CREATE INDEX IF NOT EXISTS` statements with no interpolation. |
| T-06-02-02 | D | v15 migration | mitigate | Use idempotent index creation and test all expected names with `PRAGMA index_list`. |
</threat_model>

<verification>
Run the v15 migration test, build_runner, `flutter analyze`, and a full `flutter test` before phase close.
</verification>

<success_criteria>
All three required table files declare `TableIndex` entries, schema version is 15, migration SQL creates the same indices, generated output is fresh, and the v15 migration test passes.
</success_criteria>

<output>
After completion, create `.planning/phases/06-low-fixes/06-02-SUMMARY.md`.
</output>
