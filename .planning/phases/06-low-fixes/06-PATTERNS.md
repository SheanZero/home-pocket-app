# Phase 6: LOW Fixes - Pattern Map

**Generated:** 2026-04-27
**Status:** Complete

## Files To Modify And Closest Analogs

| Target | Role | Closest Analog | Pattern To Reuse |
|--------|------|----------------|------------------|
| `.planning/audit/issues.json` | Audit finding catalogue | `.planning/audit/SCHEMA.md`, Phase 5 `medium_findings_closed_test.dart` | Preserve stable IDs; close rows with `status`, `closed_in_phase`, `closed_commit` |
| `.planning/audit/ISSUES.md` | Human-readable audit summary | Existing `.planning/audit/ISSUES.md` | Keep severity-sorted summary aligned with `issues.json` |
| `scripts/audit/dead_code.dart` | LOW scanner | Existing scanner scripts under `scripts/audit/` | Emit shard JSON consumed by `scripts/merge_findings.dart` |
| `test/architecture/low_findings_closed_test.dart` | Closure gate | `test/architecture/medium_findings_closed_test.dart` | Parse `issues.json`; assert no open severity rows |
| `test/architecture/stale_suppressions_scan_test.dart` | Suppression gate | `test/architecture/hardcoded_cjk_ui_scan_test.dart` | Recursive Dart file scan, skip generated files, fail on forbidden patterns |
| `lib/data/tables/audit_logs_table.dart` | Drift table indices | `lib/data/tables/transactions_table.dart` | `List<TableIndex> get customIndices => [...]`, Symbol syntax |
| `lib/data/tables/user_profiles_table.dart` | Drift table indices | `lib/data/tables/books_table.dart` | Stable index names and no `@override` |
| `lib/data/tables/category_ledger_configs_table.dart` | Drift table indices | `lib/data/tables/categories_table.dart` | Primary key remains unchanged; add secondary query indices only |
| `lib/data/app_database.dart` | Schema bump and migration | Existing v14 block in same file | `if (from < 15) { await customStatement('CREATE INDEX IF NOT EXISTS ...'); }` |
| `test/unit/data/migrations/index_v15_migration_test.dart` | Migration test | `test/unit/data/migrations/category_v14_migration_test.dart` | Raw old-schema setup plus `PRAGMA index_list(table)` assertions |
| `lib/main.dart` | App init logging | Existing guarded `debugPrint` pattern in family sync | Remove or guard debug-only logs; no sensitive values in release logs |
| `lib/core/initialization/app_initializer.dart` | Device/key init logging | Same file plus sync logging guards | Scrub device IDs; retain only non-sensitive lifecycle messages behind `kDebugMode` |
| `lib/application/accounting/create_transaction_use_case.dart` | Transaction flow logging | Result-returning use case pattern | Do not log transaction IDs, amounts, merchant names, raw text, or persistence IDs in release |
| `lib/data/repositories/transaction_repository_impl.dart` | Repository logging | Repository tests and Result patterns | Remove or debug-guard SQL/data-flow diagnostics |
| `lib/application/family_sync/*`, `lib/infrastructure/sync/*` | Sync logging | Existing `if (kDebugMode) debugPrint(...)` guards | Keep diagnostics behind `kDebugMode`; scrub request bodies, signatures, tokens, device/group identifiers |
| `analysis_options.yaml` | Lint enforcement | Existing linter rule block | Flip `avoid_print: true` in final close plan |
| `.github/workflows/audit.yml` | CI enforcement | Existing staged `continue-on-error` comments | Remove/adjust LOW-related non-blocking gates only after LOW debt is fixed |

## Concrete Drift Index Targets

Plan 02 should add these exact table indices unless implementation discovers a stronger existing query-path reason to use a smaller set:

- `AuditLogs`: `idx_audit_logs_event`, `idx_audit_logs_device_id`, `idx_audit_logs_timestamp`
- `UserProfiles`: `idx_user_profiles_updated_at`
- `CategoryLedgerConfigs`: `idx_category_ledger_configs_ledger_type`, `idx_category_ledger_configs_updated_at`

Migration SQL should create the same names:

- `CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)`
- `CREATE INDEX IF NOT EXISTS idx_audit_logs_device_id ON audit_logs (device_id)`
- `CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs (timestamp)`
- `CREATE INDEX IF NOT EXISTS idx_user_profiles_updated_at ON user_profiles (updated_at)`
- `CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_ledger_type ON category_ledger_configs (ledger_type)`
- `CREATE INDEX IF NOT EXISTS idx_category_ledger_configs_updated_at ON category_ledger_configs (updated_at)`

## Verification Commands

- `bash scripts/audit_dead_code.sh`
- `dart run scripts/merge_findings.dart`
- `dart run dart_code_linter:metrics check-unused-code lib`
- `dart run dart_code_linter:metrics check-unused-files lib`
- `flutter test test/unit/data/migrations/index_v15_migration_test.dart`
- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter test test/architecture/production_logging_privacy_test.dart`
- `flutter analyze`
- `flutter test`

## PATTERN MAPPING COMPLETE
