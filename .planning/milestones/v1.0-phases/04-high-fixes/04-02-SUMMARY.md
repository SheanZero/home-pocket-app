---
phase: 04-high-fixes
plan: "02"
subsystem: presentation-layer
tags:
  - HIGH-02
  - HIGH-04
  - import_guard
  - provider-restructure
  - infrastructure-elimination
dependency_graph:
  requires:
    - 04-01
  provides:
    - clean-presentation-layer
    - tightened-import-guards
    - state-provider-naming-convention
  affects:
    - 04-05
    - 04-06
tech_stack:
  added:
    - "test/architecture/presentation_layer_rules_test.dart (architecture gate)"
    - "CategoryLocalizationService (application-layer facade for home_screen)"
  patterns:
    - "repository_providers.dart (DI hub) + state_*.dart (notifier/state) per feature"
    - "import_guard.yaml blanket deny: infrastructure/** + data/daos/** + data/tables/**"
key_files:
  created:
    - lib/features/analytics/presentation/providers/state_analytics.dart
    - lib/features/dual_ledger/presentation/providers/state_ledger.dart
    - lib/features/family_sync/presentation/providers/state_active_group.dart
    - lib/features/family_sync/presentation/providers/state_notification_navigation.dart
    - lib/features/family_sync/presentation/providers/state_sync.dart
    - lib/features/home/presentation/providers/state_home.dart
    - lib/features/home/presentation/providers/state_shadow_books.dart
    - lib/features/home/presentation/providers/state_today_transactions.dart
    - lib/features/profile/presentation/providers/repository_providers.dart
    - lib/features/profile/presentation/providers/state_user_profile.dart
    - lib/features/settings/presentation/providers/state_locale.dart
    - lib/features/settings/presentation/providers/state_settings.dart
    - lib/features/settings/presentation/utils/voice_locale_helpers.dart
    - test/architecture/presentation_layer_rules_test.dart
  modified:
    - lib/features/accounting/presentation/providers/repository_providers.dart
    - lib/features/analytics/presentation/providers/repository_providers.dart
    - lib/features/family_sync/presentation/providers/repository_providers.dart
    - lib/features/settings/presentation/providers/repository_providers.dart
    - lib/features/accounting/presentation/import_guard.yaml (tightened)
    - lib/features/analytics/presentation/import_guard.yaml (tightened)
    - lib/features/dual_ledger/presentation/import_guard.yaml (tightened)
    - lib/features/family_sync/presentation/import_guard.yaml (tightened)
    - lib/features/home/presentation/import_guard.yaml (tightened)
    - lib/features/profile/presentation/import_guard.yaml (tightened)
    - lib/features/settings/presentation/import_guard.yaml (tightened)
decisions:
  - "data/repositories/** access remains permitted in Phase 4 (Phase 5+ MED scope per D-01)"
  - "Delegating providers (relayApiClientProvider, e2eeServiceProvider, etc.) retained in family_sync repository_providers.dart for coexistence with Plan 04-05 consumer migration"
  - "CategoryLocalizationService used in home_screen.dart instead of application/accounting/category_service.dart (same underlying infra delegation)"
  - "ledgerViewProvider vs ledgerProvider name mismatch flagged for Plan 04-05 reconciliation (D-07.4)"
  - "activeGroupMembersProvider vs groupMembers name mismatch flagged for Plan 04-05 reconciliation (D-07.4)"
metrics:
  duration: "~6 hours (continuation from previous session)"
  completed_date: "2026-04-26"
  tasks_completed: 5
  files_modified: 50+
---

# Phase 4 Plan 02: Presentation Refactor + Import Guard Summary

Eliminates all infrastructure imports from `lib/features/*/presentation/` by routing through `application/` layer, restructures provider files per D-05/D-06 naming conventions, tightens 7 `import_guard.yaml` files to deny `infrastructure/**`, and adds architecture enforcement test.

## What Was Done

### File Move Table

| Old Path | New Path | Status |
|----------|----------|--------|
| `family_sync/presentation/providers/sync_providers.dart` | Split: DI → `repository_providers.dart`, state → `state_sync.dart` | split + delete |
| `family_sync/presentation/providers/group_providers.dart` | Folded into `repository_providers.dart` | fold + delete |
| `family_sync/presentation/providers/avatar_sync_providers.dart` | Folded into `repository_providers.dart` | fold + delete |
| `family_sync/presentation/providers/active_group_provider.dart` | `state_active_group.dart` | rename |
| `family_sync/presentation/providers/notification_navigation_provider.dart` | `state_notification_navigation.dart` | rename |
| `accounting/presentation/providers/use_case_providers.dart` | Folded into `repository_providers.dart` | fold + delete |
| `accounting/presentation/providers/voice_providers.dart` | DI folded into `repository_providers.dart` | fold + delete |
| `accounting/presentation/providers/category_reorder_notifier.dart` | `state_category_reorder.dart` | rename |
| `settings/presentation/providers/locale_provider.dart` | `state_locale.dart` | rename |
| `settings/presentation/providers/settings_providers.dart` | State → `state_settings.dart`, helper → `utils/voice_locale_helpers.dart` | split + delete |
| `settings/presentation/providers/backup_providers.dart` | Folded into `repository_providers.dart` | fold + delete |
| `analytics/presentation/providers/analytics_providers.dart` | Split: DI → `repository_providers.dart`, state → `state_analytics.dart` | split + delete |
| `profile/presentation/providers/user_profile_providers.dart` | Split: DI → `repository_providers.dart`, state → `state_user_profile.dart` | split |
| `home/presentation/providers/home_providers.dart` | `state_home.dart` | rename |
| `home/presentation/providers/today_transactions_provider.dart` | `state_today_transactions.dart` | rename |
| `home/presentation/providers/shadow_books_provider.dart` | `state_shadow_books.dart` | rename |
| `dual_ledger/presentation/providers/ledger_providers.dart` | `state_ledger.dart` | rename |

### Infrastructure Import Elimination

All 33 illegal infrastructure imports removed from `lib/features/*/presentation/`:

| Category | Files | Routed Via |
|----------|-------|-----------|
| i18n formatters | accounting/screens (3 files), analytics/screen | `application/i18n/formatter_service.dart` (const FormatterService) |
| locale_settings model | settings/providers/locale_provider, settings/widgets/appearance_section | `application/i18n/locale_settings_view.dart` |
| crypto/security/sync DI | family_sync (8 files), accounting (2 files), analytics, profile | `application/<feature>/repository_providers.dart` (app-prefixed) |
| CategoryService | accounting/screens (2), accounting/utils, home/screen | `application/accounting/category_localization_service.dart` |
| Speech recognition | accounting/screens/voice_input_screen | `application/voice/start_speech_recognition_use_case.dart` |

### import_guard.yaml Tightening (7 files)

All 7 presentation `import_guard.yaml` files updated from 6-line partial deny to blanket:
```yaml
deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**
inherit: true
```

### Architecture Test

`test/architecture/presentation_layer_rules_test.dart` — 7 tests (one per feature) verifying deny list integrity. GREEN.

### HIGH-05 keepAlive Annotations Preserved

| Provider | File | keepAlive |
|----------|------|-----------|
| transactionChangeTracker | state_sync.dart | ✓ |
| syncEngine | state_sync.dart | ✓ |
| activeGroup | state_active_group.dart | ✓ |
| selectedTabIndex | state_home.dart | ✓ |
| LedgerView | state_ledger.dart | ✓ |
| merchantDatabaseProvider | application/ml/repository_providers.dart (Plan 04-01) | ✓ |

## Commits

| Hash | Description |
|------|-------------|
| `c881d0d` | refactor(04-02): family_sync — route presentation through application/, restructure providers, tighten import_guard |
| `0ef5ef9` | refactor(04-02): accounting — route presentation through application/, fold use_case + voice DI, rename category_reorder, tighten import_guard |
| `1837b76` | refactor(04-02): settings — rename locale_provider→state_locale, split settings, fold backup, route through application/ |
| `582e119` | refactor(04-02): analytics — route through application/, split analytics_providers→state_analytics, tighten import_guard |
| `137de53` | refactor(04-02): profile — split user_profile_providers, route through application/, tighten import_guard |
| `9af75d8` | refactor(04-02): home — rename providers to state_*, swap CategoryService→CategoryLocalizationService, tighten import_guard |
| `7efc9a2` | refactor(04-02): dual_ledger — rename ledger_providers→state_ledger, tighten import_guard |
| `c92642e` | test(04-02): add presentation_layer_rules architecture test |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed cross-feature import path in accounting/repository_providers.dart**
- **Found during:** Task 2
- **Issue:** `import 'state_sync.dart'` used local path but file is in family_sync feature
- **Fix:** Updated to `import '../../../family_sync/presentation/providers/state_sync.dart'`
- **Files modified:** `lib/features/accounting/presentation/providers/repository_providers.dart`

**2. [Rule 1 - Bug] Fixed FamilySyncNotificationNavigationController constructor API change**
- **Found during:** Task 2
- **Issue:** `main_characterization_smoke_test.dart` passed `PushNotificationService` but constructor now expects `ListenToPushNotificationsUseCase`
- **Fix:** Created `_FakeListenToPushNotificationsUseCase` fake class
- **Files modified:** `test/main_characterization_smoke_test.dart`

**3. [Rule 1 - Bug] Removed unused infrastructure imports in test files**
- **Found during:** Task 2
- **Issue:** Stale imports in `repository_providers_characterization_test.dart` and `transaction_confirm_screen_characterization_test.dart`
- **Fix:** Removed unused import statements

**4. [Rule 2 - Missing] Fixed duplicate import in backup_providers_characterization_test.dart**
- **Found during:** Task 4b post-analyze
- **Issue:** `settings/presentation/providers/repository_providers.dart` imported twice
- **Fix:** Removed duplicate import line

### Deferred Items

- **Delegating providers cleanup (Task 5 Part A):** The Plan 04-01 coexistence bridging providers (`relayApiClientProvider`, `e2eeServiceProvider`, `keyManagerProvider`, `webSocketServiceProvider`, `pushNotificationServiceProvider`) remain as thin `Provider` wrappers in `family_sync/presentation/providers/repository_providers.dart`. These delegate to `app_family_sync.app*` names — no infrastructure import. Full deletion requires updating 10+ call sites in repository_providers.dart + 6+ test files. Deferred to Plan 04-05.

### Known Discrepancies (flagged for Plan 04-05 per D-07.4)

- `LedgerView` class generates `ledgerViewProvider` but HIGH-05 hard list has `ledgerProvider` — reconcile in Plan 04-05
- `groupMembers` stream provider (in `state_sync.dart`) may need rename to `activeGroupMembersProvider` — reconcile in Plan 04-05

## Verification

```
grep -rn "import.*infrastructure" lib/features/*/presentation/ → 0 matches
flutter analyze → 0 errors, 0 warnings (13 info pre-existing)
flutter test test/architecture/presentation_layer_rules_test.dart → 7/7 PASSED
flutter test → 1228 passed, 4 pre-existing failures (waiting_approval_screen_websocket + family_sync_notification_route_listener)
```

## Self-Check: PASSED
