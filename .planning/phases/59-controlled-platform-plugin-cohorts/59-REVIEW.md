---
phase: 59-controlled-platform-plugin-cohorts
reviewed: 2026-08-09T02:33:57Z
depth: standard
files_reviewed: 115
files_reviewed_list:
  - docs/testing/DEPENDENCY_COMPATIBILITY.md
  - docs/testing/STABLE_BASELINE.json
  - lib/application/accounting/create_category_use_case.dart
  - lib/application/accounting/create_transaction_use_case.dart
  - lib/application/accounting/delete_transaction_use_case.dart
  - lib/application/accounting/merchant_category_learning_service.dart
  - lib/application/accounting/update_transaction_use_case.dart
  - lib/application/analytics/get_monthly_report_use_case.dart
  - lib/application/currency/get_exchange_rate_use_case.dart
  - lib/application/family_sync/apply_sync_operations_use_case.dart
  - lib/application/family_sync/avatar_semantic_staging_maintenance.dart
  - lib/application/family_sync/category_reference_sync_service.dart
  - lib/application/family_sync/check_group_use_case.dart
  - lib/application/family_sync/check_group_validity_use_case.dart
  - lib/application/family_sync/complete_member_activation_use_case.dart
  - lib/application/family_sync/confirm_join_use_case.dart
  - lib/application/family_sync/confirm_member_use_case.dart
  - lib/application/family_sync/control_plane_reconciliation_use_case.dart
  - lib/application/family_sync/create_group_use_case.dart
  - lib/application/family_sync/deactivate_group_use_case.dart
  - lib/application/family_sync/drain_family_sync_outbox_use_case.dart
  - lib/application/family_sync/epoch_sync_recovery_use_case.dart
  - lib/application/family_sync/full_sync_use_case.dart
  - lib/application/family_sync/group_key_recovery_use_case.dart
  - lib/application/family_sync/handle_group_dissolved_use_case.dart
  - lib/application/family_sync/handle_member_left_use_case.dart
  - lib/application/family_sync/inbound_sync_recovery_use_case.dart
  - lib/application/family_sync/join_group_use_case.dart
  - lib/application/family_sync/join_request_lifecycle_use_cases.dart
  - lib/application/family_sync/leave_group_use_case.dart
  - lib/application/family_sync/listen_to_push_notifications_use_case.dart
  - lib/application/family_sync/manage_group_invite_use_case.dart
  - lib/application/family_sync/membership_rotation_coordinator.dart
  - lib/application/family_sync/notify_member_approval_use_case.dart
  - lib/application/family_sync/pull_sync_use_case.dart
  - lib/application/family_sync/push_sync_use_case.dart
  - lib/application/family_sync/refresh_group_snapshot_use_case.dart
  - lib/application/family_sync/remove_member_use_case.dart
  - lib/application/family_sync/rename_group_use_case.dart
  - lib/application/family_sync/rotate_group_key_use_case.dart
  - lib/application/family_sync/shadow_book_service.dart
  - lib/application/family_sync/sync_avatar_use_case.dart
  - lib/application/family_sync/sync_engine.dart
  - lib/application/family_sync/sync_orchestrator.dart
  - lib/application/family_sync/sync_queue_recovery_use_case.dart
  - lib/application/family_sync/transaction_withdrawal_acknowledger.dart
  - lib/application/family_sync/transfer_owner_use_case.dart
  - lib/application/profile/save_user_profile_use_case.dart
  - lib/application/security/app_lock_service.dart
  - lib/application/seed/seed_all_use_case.dart
  - lib/application/settings/clear_all_data_use_case.dart
  - lib/application/settings/export_backup_use_case.dart
  - lib/application/settings/import_backup_use_case.dart
  - lib/application/settings/restore_backup_use_case.dart
  - lib/application/shopping_list/clear_completed_items_use_case.dart
  - lib/application/shopping_list/create_shopping_item_use_case.dart
  - lib/application/shopping_list/delete_shopping_item_use_case.dart
  - lib/application/shopping_list/shopping_item_update_persistence.dart
  - lib/application/shopping_list/watch_shopping_unit_suggestions_use_case.dart
  - lib/application/voice/parse_voice_input_use_case.dart
  - lib/application/voice/recognition/category_recognizer.dart
  - lib/application/voice/recognition/merchant_recognizer.dart
  - lib/application/voice/record_category_correction_use_case.dart
  - lib/application/voice/start_speech_recognition_use_case.dart
  - lib/application/voice/voice_chunk_merger.dart
  - lib/core/initialization/app_initializer.dart
  - lib/data/app_database_migrations.dart
  - lib/data/repositories/analytics_repository_impl.dart
  - lib/data/repositories/book_repository_impl.dart
  - lib/data/repositories/category_keyword_preference_repository_impl.dart
  - lib/data/repositories/category_ledger_config_repository_impl.dart
  - lib/data/repositories/category_repository_impl.dart
  - lib/data/repositories/category_sync_repository_impl.dart
  - lib/data/repositories/device_identity_repository_impl.dart
  - lib/data/repositories/exchange_rate_repository_impl.dart
  - lib/data/repositories/family_sync_outbox_repository_impl.dart
  - lib/data/repositories/group_repository_impl.dart
  - lib/data/repositories/inbound_sync_operation_repository_impl.dart
  - lib/data/repositories/merchant_category_preference_repository_impl.dart
  - lib/data/repositories/merchant_repository_impl.dart
  - lib/data/repositories/settings_repository_impl.dart
  - lib/data/repositories/shopping_item_repository_impl.dart
  - lib/data/repositories/shopping_unit_usage_repository_impl.dart
  - lib/data/repositories/sync_repository_impl.dart
  - lib/data/repositories/transaction_repository_impl.dart
  - lib/data/repositories/unit_of_work_impl.dart
  - lib/features/accounting/presentation/widgets/amount_input_controller.dart
  - lib/infrastructure/crypto/repositories/encryption_repository_impl.dart
  - lib/infrastructure/crypto/repositories/key_repository_impl.dart
  - lib/infrastructure/crypto/repositories/master_key_repository_impl.dart
  - lib/infrastructure/crypto/services/field_encryption_service.dart
  - lib/infrastructure/crypto/services/key_manager.dart
  - lib/infrastructure/exchange_rate/exchange_rate_cache_service.dart
  - lib/infrastructure/security/app_lock_lifecycle_observer.dart
  - lib/infrastructure/security/audit_logger.dart
  - lib/infrastructure/security/biometric_service.dart
  - lib/infrastructure/security/secure_storage_service.dart
  - lib/infrastructure/storage/app_owned_user_files_cleaner.dart
  - lib/infrastructure/storage/file_privacy_wipe_journal_store.dart
  - lib/infrastructure/sync/avatar_semantic_staging_store.dart
  - lib/infrastructure/sync/e2ee_service.dart
  - lib/infrastructure/sync/push_notification_service.dart
  - lib/infrastructure/sync/relay_api_client.dart
  - lib/infrastructure/sync/sync_lifecycle_observer.dart
  - lib/infrastructure/sync/sync_queue_manager.dart
  - lib/infrastructure/sync/sync_scheduler.dart
  - lib/infrastructure/sync/websocket_service.dart
  - scripts/dependency_compatibility.dart
  - test/architecture/dependency_compatibility_contract_test.dart
  - test/architecture/first_release_feature_contract_test.dart
  - test/core/initialization/app_initializer_test.dart
  - test/infrastructure/security/biometric_service_test.dart
  - test/infrastructure/security/secure_storage_service_test.dart
  - test/infrastructure/sync/push_notification_service_test.dart
  - test/widget/features/settings/backup_restore_screen_test.dart
findings:
  critical: 0
  blocker: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 59: Code Review Report

**Reviewed:** 2026-08-09T02:33:57Z  
**Depth:** standard  
**Files Reviewed:** 115  
**Status:** issues_found

## Summary

Reviewed the exact existing-file scope from `fd7a128f^..HEAD`: Phase 59's dependency/evidence contracts, push retry path, biometric fallback, secure-storage/startup tests, and the repository-wide constructor-formal cleanup. The targeted suites, full analyzer, dependency validator, and diff whitespace check pass. One test-reliability defect remains: initializer tests leak in-memory Drift databases and emit Drift's concurrency/corruption warning during the suite.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Evidence-convergence gate can pass a contradictory native acceptance ledger

**File:** `/Users/xinz/Development/home-pocket-app/scripts/dependency_compatibility.dart:1404-1460`  
**Evidence:** `validatePhase59EvidenceArtifacts()` treats the readable compatibility document and acceptance ledger as unstructured text: it checks a few fixed version rows/section markers and only rejects the adjacent string `UNAVAILABLE — PASS`. It never parses or compares the terminal `Decision:` values, native evidence rows, or their result states with the manifest. For example, changing the notification or secure-storage terminal `**Decision:** HOLD` text in the ledger to `ACCEPTED` while retaining the existing inventory row and headings still passes this function. The matching contract only mutates a version literal and one coverage row at `test/architecture/dependency_compatibility_contract_test.dart:1943-1977`.  
**Impact:** The advertised “artifact convergence” release gate can greenlight a ledger that falsely claims a native cohort was accepted despite the canonical baseline still holding it. That defeats the phase’s stated fail-closed native-evidence policy and can mislead a release decision.  
**Fix:** Put the terminal decision and each required evidence result in a machine-readable Phase 59 manifest (or parse the Markdown table/decision sections into typed records), then require exact agreement with `STABLE_BASELINE.json`. Add negative tests that independently flip each ledger terminal decision and each `UNAVAILABLE` native result to `PASS`.

### WR-02: Initializer tests leak every successful in-memory database

**File:** `/Users/xinz/Development/home-pocket-app/test/core/initialization/app_initializer_test.dart:34-35`  
**Evidence:** `_successDatabaseFactory()` creates `AppDatabase.forTesting()`, while successful tests only call `ProviderContainer.dispose()` (for example lines 90-95 and 105-110). The provider is injected with `overrideWithValue`, so disposing the container does not close the database. Running the changed initializer suite repeatedly emits Drift's warning that multiple database instances use the same executor and “might corrupt the database.”  
**Impact:** Tests leave database isolates/connections alive across cases. That makes the new key-before-database regressions less isolated and can mask ordering or cleanup failures; Drift explicitly identifies the pattern as a race/corruption risk.  
**Fix:** Explicitly close the database obtained from the successful container in an async teardown (and await it) before or alongside disposing the container. Centralize this in a helper so every `InitSuccess` path is cleaned up; do not suppress Drift's warning.

```dart
Future<void> disposeInitSuccess(InitSuccess success) async {
  final database = success.container.read(appDatabaseProvider);
  success.container.dispose();
  await database.close();
}

// In each successful test:
final success = result as InitSuccess;
addTearDown(() => disposeInitSuccess(success));
```

---

_Reviewed: 2026-08-09T02:33:57Z_  
_Reviewer: gsd-code-reviewer_  
_Depth: standard_
