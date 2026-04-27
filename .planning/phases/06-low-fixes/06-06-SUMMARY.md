# 06-06 Summary — Final Gates and Per-File Coverage

## Outcome

Completed the Phase 6 final gate expansion. The per-file coverage gate now checks the Phase 6 touched-file list at an 80% threshold, and all listed files pass.

## Key Changes

- Added the CI audit gate for `flutter analyze`, audit scanners, and the Phase 6 per-file coverage threshold.
- Added `.planning/audit/phase6-touched-files.txt` as the explicit coverage gate input.
- Enabled `avoid_print` and converted audit/utility script output to `stdout.writeln`.
- Added focused coverage tests for family sync orchestration, relay API client paths, push notification routing, WebSocket lifecycle/event handling, database migrations, and `main.dart` boot/UI states.
- Added `fake_async` as a direct dev dependency because tests import it directly.
- Marked Drift column DSL declarations as coverage-ignored where they are code-generation inputs and intentionally not callable at runtime; generated/runtime table behavior remains covered by database tests.

## Final Coverage Gate

Command:

```bash
dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info
```

Result: `19 checked, 0 failed`.

Lowest passing Phase 6 files:

- `lib/infrastructure/sync/push_notification_service.dart`: 80.67%
- `lib/application/family_sync/full_sync_use_case.dart`: 81.82%
- `lib/application/accounting/create_transaction_use_case.dart`: 83.33%

Files that were below 80% before expansion and now pass include:

- `lib/application/family_sync/sync_engine.dart`
- `lib/application/family_sync/sync_orchestrator.dart`
- `lib/application/family_sync/transaction_change_tracker.dart`
- `lib/data/app_database.dart`
- `lib/data/tables/audit_logs_table.dart`
- `lib/data/tables/category_ledger_configs_table.dart`
- `lib/data/tables/user_profiles_table.dart`
- `lib/infrastructure/sync/push_notification_service.dart`
- `lib/infrastructure/sync/relay_api_client.dart`
- `lib/infrastructure/sync/sync_lifecycle_observer.dart`
- `lib/infrastructure/sync/sync_scheduler.dart`
- `lib/infrastructure/sync/websocket_service.dart`
- `lib/main.dart`

## Verification

Passed:

```bash
dart format .
flutter analyze
dart run dart_code_linter:metrics check-unused-code lib
dart run dart_code_linter:metrics check-unused-files lib
bash scripts/audit_dead_code.sh
dart run scripts/merge_findings.dart
jq '[.findings[] | select(.severity == "LOW" and .status == "open")] | length' .planning/audit/issues.json
flutter test test/architecture/low_findings_closed_test.dart test/architecture/stale_suppressions_scan_test.dart test/architecture/production_logging_privacy_test.dart test/unit/data/migrations/index_v15_migration_test.dart test/unit/data/phase6_database_coverage_test.dart test/unit/application/family_sync/phase6_sync_coverage_test.dart test/infrastructure/sync/relay_api_client_test.dart test/infrastructure/sync/push_notification_service_test.dart test/infrastructure/sync/websocket_service_test.dart test/main_characterization_smoke_test.dart
flutter test --coverage --file-reporter json:/tmp/home_pocket_phase6_coverage_test.json
/Users/xinz/.pub-cache/bin/coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --mode w --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'
dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info
flutter test
```

`jq` open LOW count: `0`.
