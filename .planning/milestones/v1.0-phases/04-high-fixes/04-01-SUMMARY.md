---
phase: 04-high-fixes
plan: 01
subsystem: application_layer
tags:
  - application_layer_scaffolding
  - hoisting
  - high_fixes
  - HIGH-02
dependency_graph:
  requires:
    - 04-06  # characterization safety net
  provides:
    - application-layer DI surface for all 6 features
    - use case classes wrapping infrastructure-touching screens
    - FormatterService const class
  affects:
    - lib/application/family_sync/
    - lib/application/accounting/
    - lib/application/analytics/
    - lib/application/profile/
    - lib/application/settings/
    - lib/application/dual_ledger/
    - lib/application/home/
    - lib/application/ml/
    - lib/application/voice/
    - lib/application/i18n/
tech_stack:
  added:
    - FormatterService const class (application/i18n)
    - LookupMerchantUseCase (application/ml)
    - StartSpeechRecognitionUseCase (application/voice)
    - NotifyMemberApprovalUseCase (application/family_sync)
    - ListenToPushNotificationsUseCase (application/family_sync)
  patterns:
    - app-prefix Riverpod provider convention (Warning 7 fix for Wave 2/3 coexistence)
    - throw-if-not-overridden Provider holder (appSyncRepositoryProvider)
    - constructor-injection use case pattern (PATTERNS.md §C)
    - const class with instance methods delegating to statics (FormatterService)
key_files:
  created:
    - lib/application/i18n/formatter_service.dart
    - lib/application/i18n/locale_settings_view.dart
    - lib/application/family_sync/repository_providers.dart
    - lib/application/accounting/repository_providers.dart
    - lib/application/analytics/repository_providers.dart
    - lib/application/profile/repository_providers.dart
    - lib/application/settings/repository_providers.dart
    - lib/application/home/repository_providers.dart
    - lib/application/ml/lookup_merchant_use_case.dart
    - lib/application/ml/repository_providers.dart
    - lib/application/voice/start_speech_recognition_use_case.dart
    - lib/application/voice/repository_providers.dart
    - lib/application/family_sync/notify_member_approval_use_case.dart
    - lib/application/family_sync/listen_to_push_notifications_use_case.dart
    - test/unit/application/i18n/formatter_service_test.dart
    - test/unit/application/ml/lookup_merchant_use_case_test.dart
    - test/unit/application/voice/start_speech_recognition_use_case_test.dart
    - test/unit/application/family_sync/notify_member_approval_use_case_test.dart
    - test/unit/application/family_sync/repository_providers_test.dart
    - test/unit/application/accounting/repository_providers_test.dart
  modified:
    - lib/application/dual_ledger/repository_providers.dart  # renamed from providers.dart
    - lib/application/dual_ledger/repository_providers.g.dart  # renamed
    - lib/features/accounting/presentation/providers/use_case_providers.dart  # import update
    - test/unit/application/dual_ledger/providers_characterization_test.dart  # import update
    - test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart  # import update
decisions:
  - "Use `app` symbol prefix on ALL hoisted providers to prevent Riverpod codegen symbol collision during Wave 2/3 coexistence (Warning 7 fix)"
  - "appSyncRepositoryProvider implemented as throw-if-not-overridden Provider holder — SyncRepository impl requires DAO (banned in application layer); Plan 04-02 wires the concrete impl via feature override"
  - "appMerchantDatabaseProvider retains @Riverpod(keepAlive: true) — on HIGH-05 hard list; Plan 04-05 updated to reference appMerchantDatabaseProvider"
  - "NotifyMemberApprovalUseCase takes only WebSocketService + KeyManager (not RelayApiClient) — RelayApiClient was unused; screens use separate use cases for approve/reject"
  - "SpeechRecognitionService uses callback API not Stream; StartSpeechRecognitionUseCase is a thin delegation wrapper"
  - "Coverage gate scoped to 8 files with real executable lines; 7 pure-@riverpod provider files have 0/0 lcov entries (executable code in .g.dart, excluded by lcov filter)"
metrics:
  duration_minutes: ~180
  completed_date: "2026-04-26"
  tasks_completed: 4
  files_created: 20
  files_modified: 5
  tests_added: 40
  commits: 14
---

# Phase 04 Plan 01: Application-Layer Routing Scaffolding Summary

**One-liner:** 8 application-layer `repository_providers.dart` files + 4 use case classes hoisting infrastructure-touching providers behind an `app`-prefixed DI surface so Plan 04-02 can eliminate 33 direct `infrastructure/` imports from feature presentation.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | FormatterService + LocaleSettings re-export | 82e4ff4 | formatter_service.dart, locale_settings_view.dart |
| 2 | 5-feature DI hoist + family_sync providers | 51ac1dc–fcb5fe9 | accounting, analytics, profile, settings, family_sync repository_providers.dart |
| 3 | ML + voice + dual_ledger + home + 4 use cases | 1141bb8–9f2196c | lookup_merchant, start_speech_recognition, notify_member_approval, listen_to_push_notifications |
| 4 | Coverage gate + test top-up | 55c19ee | 3 test files extended |

## Coverage Gate Results

All 8 files with real executable lines pass ≥80% threshold:

| File | Covered/Total | % | Result |
|------|--------------|---|--------|
| application/accounting/repository_providers.dart | 4/4 | 100.00 | PASS |
| application/dual_ledger/repository_providers.dart | 5/5 | 100.00 | PASS |
| application/family_sync/listen_to_push_notifications_use_case.dart | 6/6 | 100.00 | PASS |
| application/family_sync/notify_member_approval_use_case.dart | 13/13 | 100.00 | PASS |
| application/family_sync/repository_providers.dart | 34/36 | 94.44 | PASS |
| application/i18n/formatter_service.dart | 18/18 | 100.00 | PASS |
| application/ml/lookup_merchant_use_case.dart | 3/3 | 100.00 | PASS |
| application/voice/start_speech_recognition_use_case.dart | 9/9 | 100.00 | PASS |

**7 pure-@riverpod provider files** (analytics, profile, settings, home, ml/repo, voice/repo, locale_settings_view) report 0/0 in lcov — their executable code is in `.g.dart` (excluded by lcov filter). These are DI scaffolding stubs; coverage will be verified in Plans 04-02 and 04-06 per the plan's note.

The 2 uncovered lines in `family_sync/repository_providers.dart` (94.44%): the `FirebasePushMessagingClient()` Android branch (line 62, Platform.isIOS=false not hit in unit tests) and the throw in `appSyncRepositoryProvider` (line 78, intentionally not tested — it's a sentinel for missing override).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MerchantDatabase.lookup() does not exist — corrected to findMerchant()**
- **Found during:** Task 3
- **Issue:** Plan template used `lookup()` but the actual method is `findMerchant()`
- **Fix:** `LookupMerchantUseCase` calls `_database.findMerchant(name)`, returns null on null result or exception
- **Files modified:** lib/application/ml/lookup_merchant_use_case.dart
- **Commit:** 1141bb8

**2. [Rule 1 - Bug] SpeechRecognitionService uses callback API, not Stream**
- **Found during:** Task 3
- **Issue:** Plan assumed a Stream-based API; actual service uses callbacks (onResult, onSoundLevel, onStatus, onError)
- **Fix:** `StartSpeechRecognitionUseCase` delegates the callback-based API (thin delegation wrapper)
- **Files modified:** lib/application/voice/start_speech_recognition_use_case.dart
- **Commit:** 3c64a4f

**3. [Rule 1 - Bug] NotifyMemberApprovalUseCase had unused _apiClient field**
- **Found during:** Task 3 (analyzer warning)
- **Issue:** Plan template included RelayApiClient dependency but it was never used — screens use separate use cases for approve/reject actions
- **Fix:** Removed RelayApiClient from constructor and field entirely
- **Files modified:** lib/application/family_sync/notify_member_approval_use_case.dart
- **Commit:** c95a40a

**4. [Rule 1 - Bug] dual_ledger rename required two additional fix commits**
- **Found during:** Task 3
- **Issue:** git mv committed the rename but the `part` directive and `.g.dart` content still referenced old filename
- **Fix:** Two separate fix commits updating `part 'providers.g.dart'` → `part 'repository_providers.g.dart'` and the `.g.dart` `part of` directive
- **Files modified:** lib/application/dual_ledger/repository_providers.dart, repository_providers.g.dart
- **Commits:** 9f2196c, 2847758

**5. [Rule 2 - Missing functionality] Coverage gate failed on 3 use case files at initial run**
- **Found during:** Task 4
- **Issue:** voice/start_speech_recognition_use_case (77.78%), notify_member_approval_use_case (76.92%), family_sync/repository_providers (75%) below 80% threshold
- **Fix:** Added cancel()/isAvailable tests, signMessage callback invocation test, notifyMemberApproval + listenToPushNotifications provider tests
- **Files modified:** 3 test files
- **Commit:** 55c19ee

**6. [Rule 3 - Deviation] Coverage gate scoped to instrumentable files only**
- **Found during:** Task 4
- **Issue:** Plan listed all 15 source files for gate; 7 pure-@riverpod provider files have 0/0 lcov entries (executable code in .g.dart, excluded by lcov filter). Gate tool treats 0/0 as 0% failure.
- **Fix:** Gate run against the 8 files with real executable lines; 7 scaffolding files deferred to Plans 04-02/04-06 per plan note ("For analytics, profile, settings: covered via Plan 04-06 characterization tests + Plan 04-02 integration tests")
- **Documentation:** Plan's `<automated>` hint confirms intent — only checks formatter_service.dart and lookup_merchant_use_case.dart

**7. [Rule 1 - Bug] FormatterService test: LocaleDataException on intl initialization**
- **Found during:** Task 1
- **Issue:** `initializeDateFormatting` required before any locale-specific date formatting in tests
- **Fix:** Added `setUpAll(() async { await initializeDateFormatting('ja', null); ... })` with import `package:intl/date_symbol_data_local.dart`
- **Files modified:** test/unit/application/i18n/formatter_service_test.dart
- **Commit:** 82e4ff4

## Known Stubs

`appSyncRepositoryProvider` in `lib/application/family_sync/repository_providers.dart` (line 78) is intentionally a throw-if-not-overridden sentinel. Plan 04-02 Task 5 wires the concrete implementation via feature presentation override. This is documented in the file and is not a stub — it is the intended pattern per `appDatabaseProvider` analog.

## Threat Flags

None. All new files are application-layer DI scaffolding. No new network endpoints, auth paths, or trust-boundary crossings introduced. Infrastructure services are wrapped (not re-exposed) via application-layer providers.

## Self-Check: PASSED

Files created:
- lib/application/i18n/formatter_service.dart: FOUND
- lib/application/i18n/locale_settings_view.dart: FOUND
- lib/application/family_sync/repository_providers.dart: FOUND
- lib/application/accounting/repository_providers.dart: FOUND
- lib/application/analytics/repository_providers.dart: FOUND
- lib/application/profile/repository_providers.dart: FOUND
- lib/application/settings/repository_providers.dart: FOUND
- lib/application/home/repository_providers.dart: FOUND
- lib/application/ml/lookup_merchant_use_case.dart: FOUND
- lib/application/ml/repository_providers.dart: FOUND
- lib/application/voice/start_speech_recognition_use_case.dart: FOUND
- lib/application/voice/repository_providers.dart: FOUND
- lib/application/family_sync/notify_member_approval_use_case.dart: FOUND
- lib/application/family_sync/listen_to_push_notifications_use_case.dart: FOUND

Commits verified: 82e4ff4, 51ac1dc, f7bf667, 96fc649, 82cf9f4, fcb5fe9, 1141bb8, 3c64a4f, c95a40a, 88a68e5, 912b187, 9f2196c, 2847758, 55c19ee — all present in git log.

Test suite: 1226 tests ALL PASS.
flutter analyze: 26 issues (all pre-existing warnings in test files; 0 new issues).
