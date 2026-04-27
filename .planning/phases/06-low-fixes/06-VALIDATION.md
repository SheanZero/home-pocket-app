---
phase: 06
slug: low-fixes
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-27
---

# Phase 06 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test / Dart test |
| **Config file** | `pubspec.yaml`, `analysis_options.yaml`, `.github/workflows/audit.yml` |
| **Quick run command** | `flutter test <changed-test-files>` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~180 seconds targeted, ~900 seconds full |

---

## Sampling Rate

- **After every task commit:** Run the task's targeted `<verify><automated>` command.
- **After every plan wave:** Run `flutter analyze` plus tests touched in that wave.
- **Before `$gsd-verify-work`:** `dart format .`, `flutter analyze`, and `flutter test` must be green.
- **Max feedback latency:** 15 minutes for full-suite feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | LOW-01, LOW-02 | T-06-01-01 | Audit catalogue preserves LOW traceability | architecture | `bash scripts/audit_dead_code.sh && dart run scripts/merge_findings.dart` | ✅ | pending |
| 06-01-02 | 01 | 1 | LOW-02, LOW-03, LOW-07 | T-06-01-02 | Generated suppressions are not hand-edited | analyzer/scanner | `dart run dart_code_linter:metrics check-unused-code lib && dart run dart_code_linter:metrics check-unused-files lib` | ✅ | pending |
| 06-02-01 | 02 | 2 | LOW-04, LOW-05 | T-06-02-01 | Static index migration cannot interpolate user data | unit | `flutter test test/unit/data/migrations/index_v15_migration_test.dart` | ✅ | pending |
| 06-02-02 | 02 | 2 | LOW-04, LOW-05, LOW-07 | T-06-02-02 | Drift generated output matches table sources | generation | `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/data/app_database.g.dart` | ✅ | pending |
| 06-03-01 | 03 | 3 | LOW-06, LOW-07 | T-06-03-01 | App/accounting release logs do not expose identifiers or payloads | architecture | `LOGGING_PRIVACY_SCOPE=lib/main.dart,lib/core/initialization/app_initializer.dart,lib/application/accounting/create_transaction_use_case.dart,lib/application/accounting/merchant_category_learning_service.dart,lib/data/repositories/transaction_repository_impl.dart flutter test test/architecture/production_logging_privacy_test.dart` | ✅ | pending |
| 06-04-01 | 04 | 4 | LOW-06, LOW-07 | T-06-04-01 | Family-sync application logs do not expose identifiers or payloads | architecture | `LOGGING_PRIVACY_SCOPE=lib/application/family_sync/sync_engine.dart,lib/application/family_sync/sync_orchestrator.dart,lib/application/family_sync/transaction_change_tracker.dart,lib/application/family_sync/full_sync_use_case.dart,lib/application/family_sync/pull_sync_use_case.dart flutter test test/architecture/production_logging_privacy_test.dart && flutter analyze` | ✅ | pending |
| 06-05-01 | 05 | 4 | LOW-06, LOW-07 | T-06-05-01 | Sync infrastructure logs do not expose tokens, signatures, identifiers, or payloads | architecture | `LOGGING_PRIVACY_SCOPE=lib/infrastructure/sync/relay_api_client.dart,lib/infrastructure/sync/push_notification_service.dart,lib/infrastructure/sync/sync_lifecycle_observer.dart,lib/infrastructure/sync/sync_scheduler.dart,lib/infrastructure/sync/websocket_service.dart flutter test test/architecture/production_logging_privacy_test.dart && flutter analyze` | ✅ | pending |
| 06-06-01 | 06 | 5 | LOW-01, LOW-02, LOW-03, LOW-04, LOW-05, LOW-06, LOW-07 | T-06-06-01 | LOW gates block regressions after fixes land | CI/static | `flutter test --coverage && coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/' && dart run scripts/coverage_gate.dart --list .planning/audit/phase6-touched-files.txt --threshold 80 --lcov coverage/lcov_clean.info` | ✅ | pending |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `scripts/audit_dead_code.sh`
- `scripts/coverage_gate.dart`
- `flutter_test`
- `dart_code_linter`
- Drift migration test patterns under `test/unit/data/migrations/`

---

## Manual-Only Verifications

All Phase 6 behaviors have automated verification. Manual review is still required for logging sensitivity judgment before accepting Plans 03, 04, and 05.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 900s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
