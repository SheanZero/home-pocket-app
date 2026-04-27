# Phase 6: LOW Fixes - Research

**Phase:** 06-low-fixes
**Researched:** 2026-04-27
**Status:** Complete

## Research Question

What do we need to know to plan Phase 6 well?

Phase 6 is not a generic cleanup pass. The roadmap and context define four concrete workstreams:

1. Refresh the stale LOW audit catalogue before remediation.
2. Remove dead code, orphaned files, and stale suppression directives.
3. Add Drift indices with a schema bump and migration verification.
4. Make production logging privacy-safe and enforce the resulting gates.

## Source-of-Truth Findings

### Audit Catalogue State

- `.planning/audit/issues.json` currently has no `LOW` findings.
- `06-CONTEXT.md` explicitly treats that as stale catalogue data, not absence of LOW work.
- Phase 6 must start by re-running the LOW scanners and adding stable issue rows for scanner-backed LOW findings before closing them.
- Stable issue rules are documented in `.planning/audit/SCHEMA.md`.

### LOW Scanner Paths

Existing scanner and verification assets:

- `scripts/audit/dead_code.dart`
- `scripts/audit_dead_code.sh`
- `.planning/audit/shards/dead_code.json`
- `.planning/audit/agent-shards/drift_col.json`
- `scripts/coverage_gate.dart`
- `.github/workflows/audit.yml`

The phase should use `dart run dart_code_linter:metrics check-unused-code lib` and `dart run dart_code_linter:metrics check-unused-files lib` as direct verification commands, with the existing audit wrapper updating shard/catalogue files where applicable.

### Drift Index and Migration Targets

Required target files from LOW-04:

- `lib/data/tables/audit_logs_table.dart`
- `lib/data/tables/user_profiles_table.dart`
- `lib/data/tables/category_ledger_configs_table.dart`
- `lib/data/app_database.dart`

Existing local Drift index convention:

- `List<TableIndex> get customIndices => [...]`
- `TableIndex(name: 'idx_{table}_{columns}', columns: {#columnName})`
- Symbol syntax is required.
- No `@override` annotation is used on `customIndices`.

Existing analog files:

- `lib/data/tables/books_table.dart`
- `lib/data/tables/categories_table.dart`
- `lib/data/tables/transactions_table.dart`
- `lib/data/tables/group_members_table.dart`
- `lib/data/tables/groups_table.dart`

Current database version:

- `lib/data/app_database.dart` has `schemaVersion => 14`.
- Phase 6 should bump to `15`.
- Migration code must create the three new indices when `from < 15`.
- Migration SQL must be static or otherwise parameterized; do not interpolate user-controlled identifiers or values.

Existing migration-test analog:

- `test/unit/data/migrations/category_v14_migration_test.dart`

The v15 index migration test should follow the same style: create an old-schema raw database, run v15 migration steps, and assert expected index names through `PRAGMA index_list(table_name)`.

## Validation Architecture

Phase 6 needs validation at three levels:

1. **Catalogue validation**
   - Re-scan LOW sources.
   - Confirm `.planning/audit/issues.json` has no open LOW rows after fixes.
   - Confirm any scanner-backed LOW rows added during the phase are closed with lifecycle metadata.

2. **Code cleanup validation**
   - `dart run dart_code_linter:metrics check-unused-code lib`
   - `dart run dart_code_linter:metrics check-unused-files lib`
   - Targeted `rg` checks for stale suppressions outside generated files.
   - `flutter analyze`

3. **Drift migration validation**
   - Unit migration test for v14-to-v15 index creation.
   - Assertions against `PRAGMA index_list(audit_logs)`, `PRAGMA index_list(user_profiles)`, and `PRAGMA index_list(category_ledger_configs)`.
   - Generated Drift outputs refreshed after source changes.

4. **Logging validation**
   - `rg -n "print\\(|debugPrint\\(|dev\\.log|dart:developer" lib`
   - All retained debug-only logs are guarded by `kDebugMode`.
   - Release-path logs must not include request bodies, transaction IDs, device IDs, tokens, signatures, group IDs, invite codes, or raw payloads.
   - `analysis_options.yaml` should enforce `avoid_print: true` in the final close plan.

## Logging Surface

Production paths currently include `dart:developer` logs and `debugPrint` calls in these areas:

- `lib/main.dart`
- `lib/core/initialization/app_initializer.dart`
- `lib/application/accounting/create_transaction_use_case.dart`
- `lib/application/accounting/merchant_category_learning_service.dart`
- `lib/data/repositories/transaction_repository_impl.dart`
- `lib/application/family_sync/*`
- `lib/infrastructure/sync/*`

The highest-risk logs are request signing/API body logs, transaction persistence logs, device identity logs, group IDs, invite codes, and token refresh logs. Prefer scrubbing/removal over guard-only when the logged value is sensitive.

## Planning Implications

Recommended plan split:

1. LOW catalogue refresh and dead-code/suppression cleanup.
2. Drift index migration and tests.
3. App/accounting privacy-safe logging cleanup and shared logging guard.
4. Family-sync application privacy-safe logging cleanup.
5. Sync infrastructure privacy-safe logging cleanup.
6. Final gate tightening and phase closure.

This sequencing keeps the context decision D-07 intact: intermediate work can run checks locally, while blocking CI/gate changes wait until the final close plan.

## Risks

- The catalogue starts stale. Plans must not treat zero current LOW rows as completion.
- Generated files contain many `// ignore` directives and must not be hand-edited.
- Logging cleanup can accidentally remove useful debug diagnostics. Keep debug-only diagnostics behind `kDebugMode`, but remove or scrub sensitive release-path details.
- Drift index names must be stable because the v15 migration test will assert them.
- Schema changes require regeneration of Drift outputs.

## RESEARCH COMPLETE
