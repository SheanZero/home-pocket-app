---
phase: 04-high-fixes
plan: 02
type: execute
wave: 3
depends_on:
  - 04-01
files_modified:
  - lib/features/accounting/presentation/screens/transaction_confirm_screen.dart
  - lib/features/accounting/presentation/screens/voice_input_screen.dart
  - lib/features/accounting/presentation/screens/transaction_entry_screen.dart
  - lib/features/accounting/presentation/screens/category_selection_screen.dart
  - lib/features/accounting/presentation/screens/transaction_form_screen.dart
  - lib/features/accounting/presentation/widgets/transaction_list_tile.dart
  - lib/features/accounting/presentation/utils/category_display_utils.dart
  - lib/features/accounting/presentation/providers/repository_providers.dart
  - lib/features/accounting/presentation/providers/repository_providers.g.dart
  - lib/features/accounting/presentation/providers/use_case_providers.dart
  - lib/features/accounting/presentation/providers/use_case_providers.g.dart
  - lib/features/accounting/presentation/providers/voice_providers.dart
  - lib/features/accounting/presentation/providers/state_voice.dart
  - lib/features/accounting/presentation/providers/state_voice.g.dart
  - lib/features/accounting/presentation/providers/category_reorder_notifier.dart
  - lib/features/accounting/presentation/providers/state_category_reorder.dart
  - lib/features/accounting/presentation/providers/state_category_reorder.g.dart
  - lib/features/analytics/presentation/screens/analytics_screen.dart
  - lib/features/analytics/presentation/providers/repository_providers.dart
  - lib/features/analytics/presentation/providers/repository_providers.g.dart
  - lib/features/analytics/presentation/providers/analytics_providers.dart
  - lib/features/analytics/presentation/providers/state_analytics.dart
  - lib/features/analytics/presentation/providers/state_analytics.g.dart
  - lib/features/dual_ledger/presentation/providers/ledger_providers.dart
  - lib/features/dual_ledger/presentation/providers/state_ledger.dart
  - lib/features/dual_ledger/presentation/providers/state_ledger.g.dart
  - lib/features/family_sync/presentation/providers/repository_providers.dart
  - lib/features/family_sync/presentation/providers/repository_providers.g.dart
  - lib/features/family_sync/presentation/providers/sync_providers.dart
  - lib/features/family_sync/presentation/providers/state_sync.dart
  - lib/features/family_sync/presentation/providers/state_sync.g.dart
  - lib/features/family_sync/presentation/providers/group_providers.dart
  - lib/features/family_sync/presentation/providers/avatar_sync_providers.dart
  - lib/features/family_sync/presentation/providers/active_group_provider.dart
  - lib/features/family_sync/presentation/providers/state_active_group.dart
  - lib/features/family_sync/presentation/providers/state_active_group.g.dart
  - lib/features/family_sync/presentation/providers/notification_navigation_provider.dart
  - lib/features/family_sync/presentation/providers/state_notification_navigation.dart
  - lib/features/family_sync/presentation/providers/state_notification_navigation.g.dart
  - lib/features/family_sync/presentation/screens/create_group_screen.dart
  - lib/features/family_sync/presentation/screens/member_approval_screen.dart
  - lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/providers/home_providers.dart
  - lib/features/home/presentation/providers/state_home.dart
  - lib/features/home/presentation/providers/state_home.g.dart
  - lib/features/home/presentation/providers/today_transactions_provider.dart
  - lib/features/home/presentation/providers/state_today_transactions.dart
  - lib/features/home/presentation/providers/state_today_transactions.g.dart
  - lib/features/home/presentation/providers/shadow_books_provider.dart
  - lib/features/home/presentation/providers/state_shadow_books.dart
  - lib/features/home/presentation/providers/state_shadow_books.g.dart
  - lib/features/profile/presentation/providers/user_profile_providers.dart
  - lib/features/profile/presentation/providers/state_user_profile.dart
  - lib/features/profile/presentation/providers/state_user_profile.g.dart
  - lib/features/settings/presentation/providers/locale_provider.dart
  - lib/features/settings/presentation/providers/state_locale.dart
  - lib/features/settings/presentation/providers/state_locale.g.dart
  - lib/features/settings/presentation/providers/settings_providers.dart
  - lib/features/settings/presentation/providers/state_settings.dart
  - lib/features/settings/presentation/providers/state_settings.g.dart
  - lib/features/settings/presentation/providers/backup_providers.dart
  - lib/features/settings/presentation/providers/repository_providers.dart
  - lib/features/settings/presentation/providers/repository_providers.g.dart
  - lib/features/settings/presentation/widgets/appearance_section.dart
  - lib/features/accounting/presentation/import_guard.yaml
  - lib/features/analytics/presentation/import_guard.yaml
  - lib/features/dual_ledger/presentation/import_guard.yaml
  - lib/features/family_sync/presentation/import_guard.yaml
  - lib/features/home/presentation/import_guard.yaml
  - lib/features/profile/presentation/import_guard.yaml
  - lib/features/settings/presentation/import_guard.yaml
  - test/architecture/presentation_layer_rules_test.dart
autonomous: true
requirements:
  - HIGH-01
  - HIGH-02
  - HIGH-04
must_haves:
  goals:
    - "Zero presentation→infrastructure imports across the 33 currently-violating files; presentation directories restructured to `repository_providers.dart` + `state_*.dart` only per CONTEXT.md D-05/D-06; all 7 presentation `import_guard.yaml` files tightened to deny `infrastructure/**` (collapsing the existing 4-line partial deny into a single blanket); `test/architecture/presentation_layer_rules_test.dart` GREEN; HIGH-02 + HIGH-04 (structural portion) closed; HIGH-01 trivially closed (no HIGH `issues.json` entries existed; this plan validates that). NOTE: `data/repositories/**` access from feature/presentation/ is NOT in Phase 4 scope per CONTEXT.md `<domain>` 'In scope' list (which only mentions `infrastructure/` imports) — that migration is Phase 5+ MED scope. The yaml blanket retains the existing `data/daos/**` + `data/tables/**` denies (already in place pre-Phase-4) but does NOT add `data/**` blanket."
  truths:
    - "D-01 strict reading: zero exceptions for HIGH-02 — every one of 33 violations is migrated, no carve-outs. data/repositories/** access is OUT OF SCOPE for Phase 4 (CONTEXT.md `<domain>` scope list); ~20 existing data/repositories/** imports from feature/presentation/ remain permitted in Phase 4 and are scheduled for Phase 5+ MED scope"
    - "Repo lock active throughout Phase 4 (CONTEXT.md D-19 + .planning/audit/REPO-LOCK-POLICY.md) — only Phase 4 cleanup PRs merge to main"
    - "coverage_gate.dart enforced per-plan only; CI integration deferred to Phase 6 (CONTEXT.md D-21)"
    - "import_guard remains BLOCKING (Phase 3 D-17 flip) — CRITICAL: per CONTEXT.md D-20, the new presentation `import_guard.yaml` rules MUST land in the SAME commit as the resolved violations for that feature, NEVER standalone. CI never sees a broken state. Each feature-level commit: (a) resolves all infrastructure imports in the feature, (b) folds DI providers into `repository_providers.dart`, (c) renames notifier files to `state_*.dart`, (d) tightens `presentation/import_guard.yaml` to deny `infrastructure/**`. ALL FOUR atomic in one commit per feature"
    - "Six keepAlive providers per HIGH-05 hard list MUST retain `@Riverpod(keepAlive: true)` verbatim during file moves: `syncEngineProvider` (currently `sync_providers.dart` line 141 — moves to `state_sync.dart`), `transactionChangeTrackerProvider` (currently `sync_providers.dart` line 118 — moves to `state_sync.dart`), `merchantDatabaseProvider` (Plan 04-01 already hoisted to `lib/application/ml/repository_providers.dart`), `activeGroupProvider` (currently `active_group_provider.dart` line 13 — renames to `state_active_group.dart`), `activeGroupMembersProvider` (RECONCILIATION REQUIRED — currently exists as `groupMembers` at `sync_providers.dart` line 161 with NO keepAlive — Plan 04-05 will reconcile by either renaming + adding keepAlive or updating the hard list; this plan flags the discrepancy), `ledgerProvider` (currently `LedgerView` class generates `ledgerViewProvider` — RECONCILIATION REQUIRED — Plan 04-05 verifies exact name)"
    - "`dual_ledger` has NO `domain/` subdir but DOES have `presentation/` (verified in PATTERNS.md §9 last paragraph) — this plan's architecture test MUST include `dual_ledger` in its features list. Existing test/architecture/domain_import_rules_test.dart omits dual_ledger; presentation_layer_rules_test.dart adds it"
    - "D-03 implementation: this plan lands `lib/features/*/presentation/import_guard.yaml` with `inherit: true` plus deny rules for `infrastructure/**` (allowing only `application/**`, `<self-feature>/domain/**`, `<self-feature>/presentation/**`, `core/**`, `shared/**`, `l10n/**`, `generated/**`, `dart:**`, `package:flutter/**`, `package:flutter_riverpod/**`, `package:riverpod_annotation/**`, `package:freezed_annotation/**`, `package:go_router/**`, and other vetted UI deps); companion `test/architecture/presentation_layer_rules_test.dart` parses each yaml and asserts the `infrastructure/**` deny entry is present and not weakened — mirrors Phase 3 D-02 pattern"
    - "Per CONTEXT.md D-06 file moves: `voice_providers.dart`→`state_voice.dart` (DI part folds), `use_case_providers.dart`→ DELETE (folds into `repository_providers.dart`), `category_reorder_notifier.dart`→`state_category_reorder.dart`, `active_group_provider.dart`→`state_active_group.dart`, `notification_navigation_provider.dart`→`state_notification_navigation.dart`, `sync_providers.dart`→ split DI/state, `group_providers.dart`→ DI fold, `avatar_sync_providers.dart`→ DI fold (no notifier), `ledger_providers.dart`→`state_ledger.dart`, `today_transactions_provider.dart`→`state_today_transactions.dart`, `home_providers.dart`→`state_home.dart`, `shadow_books_provider.dart`→`state_shadow_books.dart`, `user_profile_providers.dart`→ split, `locale_provider.dart`→`state_locale.dart`, `settings_providers.dart`→ split, `backup_providers.dart`→ DI fold, `analytics_providers.dart`→ split"
    - "Per CONTEXT.md D-13 commit 2 note: `use_case_providers.dart` is shrunken by Plan 04-03 (RLS deletion landed in Wave 1); this plan FOLDS the remaining contents into `repository_providers.dart` and DELETES the file"
    - "ResolveLedgerTypeService is GONE (Plan 04-03 deleted it Wave 1); zero references in any file edited here"
    - "Wave 3 — depends on Plan 04-01 (Wave 2); Plan 04-05 (Wave 4) consumes the structure created here"
    - "Application-layer providers consumed by presentation are PREFIXED with `app` per Plan 04-01 Task 2 (e.g., `appE2eeServiceProvider`, `appRelayApiClientProvider`, `appMerchantDatabaseProvider`) to eliminate library-level Riverpod codegen symbol collisions with the original infrastructure providers; this plan rewrites consumers to use the `app`-prefixed names then deletes the duplicate originals in Plan 04-02 final cleanup"
  artifacts:
    - path: "lib/features/accounting/presentation/providers/repository_providers.dart"
      provides: "Single DI hub per feature; absorbs use_case_providers.dart contents (post-Plan-04-03 RLS deletion); imports ONLY from application/ for infrastructure-touching deps"
      excludes: "infrastructure/"
      contains: "@riverpod"
    - path: "lib/features/accounting/presentation/providers/state_voice.dart"
      provides: "Notifier/state portion split out from voice_providers.dart"
    - path: "lib/features/accounting/presentation/providers/use_case_providers.dart"
      provides: "DELETED per CONTEXT.md D-06 (folded into repository_providers.dart)"
    - path: "lib/features/family_sync/presentation/providers/state_sync.dart"
      provides: "Notifier/stream portion split out from sync_providers.dart; PRESERVES @Riverpod(keepAlive: true) on transactionChangeTracker AND syncEngine"
      contains: "@Riverpod(keepAlive: true)"
    - path: "lib/features/family_sync/presentation/providers/state_active_group.dart"
      provides: "Renamed from active_group_provider.dart; PRESERVES @Riverpod(keepAlive: true) on activeGroupProvider"
      contains: "@Riverpod(keepAlive: true)"
    - path: "lib/features/dual_ledger/presentation/providers/state_ledger.dart"
      provides: "Renamed from ledger_providers.dart; PRESERVES @Riverpod(keepAlive: true) on LedgerView"
      contains: "@Riverpod(keepAlive: true)"
    - path: "lib/features/<f>/presentation/import_guard.yaml (×7)"
      provides: "Tightened deny: now denies package:home_pocket/infrastructure/** (single blanket; replaces partial 6-line deny). RETAINS existing data/daos/** + data/tables/** denies. Does NOT add data/** blanket (data/repositories/** out-of-scope for Phase 4 per D-01 + CONTEXT.md domain scope)"
      contains: "package:home_pocket/infrastructure/**"
    - path: "test/architecture/presentation_layer_rules_test.dart"
      provides: "Architecture test asserting the 7 presentation import_guard.yaml files all deny infrastructure/** + data/daos/** + data/tables/** (Phase-4 scope) and cannot be weakened"
      contains: "infrastructure/"
      min_lines: 60
  key_links:
    - from: "lib/features/<f>/presentation/screens/*.dart and providers/*.dart"
      to: "lib/application/<f>/repository_providers.dart and lib/application/<f>/<verb>_use_case.dart and lib/application/i18n/formatter_service.dart"
      via: "swap infrastructure imports for application imports per CONTEXT.md D-02 routing categories (a/b/c)"
      pattern: "import.*application/"
    - from: "test/architecture/presentation_layer_rules_test.dart"
      to: "lib/features/<f>/presentation/import_guard.yaml (×7)"
      via: "loadYaml + expect deny.containsAll(['package:home_pocket/infrastructure/**', 'package:home_pocket/data/daos/**', 'package:home_pocket/data/tables/**'])"
      pattern: "infrastructure/"
---

<objective>
Plan 04-02 is the **largest Phase 4 plan** (~50 file modifications, 8+ atomic commits). It executes the presentation-layer refactor that closes HIGH-02 and the structural portion of HIGH-04:

1. **Replace 33 illegal `infrastructure/` imports** in feature/presentation files with `application/` imports (consuming Plan 04-01's `app`-prefixed scaffolding).
2. **Restructure `lib/features/<f>/presentation/providers/`** per CONTEXT.md D-05/D-06: collapse to `repository_providers.dart` (single DI hub) + `state_*.dart` (notifier/state files). 12+ provider files renamed, 1+ deleted (use_case_providers.dart).
3. **Tighten 7 `lib/features/<f>/presentation/import_guard.yaml`** files: replace existing 6-line partial deny (currently denies `data/tables/**`, `data/daos/**`, `infrastructure/crypto/services/**`, `infrastructure/sync/**`, `infrastructure/security/secure_storage_service.dart`, `infrastructure/crypto/repositories/**`) with a stronger blanket: `infrastructure/**` plus retaining existing `data/daos/**` + `data/tables/**`. **Does NOT add `data/**` blanket** — `data/repositories/**` access remains permitted in Phase 4 (Phase 5+ MED scope per CONTEXT.md `<domain>`).
4. **Add `test/architecture/presentation_layer_rules_test.dart`** that asserts the 7 yaml files cannot be weakened (asserts `infrastructure/**` + `data/daos/**` + `data/tables/**` all present).

**Critical sequencing per CONTEXT.md D-20:** the new yaml deny + the resolved violations land in the SAME commit per feature. CI never sees a broken state because `import_guard` is already blocking (Phase 3 D-17).

**Executor `/clear` recommended between feature commits** — Plan 04-02's total scope (~50 files, 8 atomic commits) approaches the upper bound for a single context window. After committing each feature, `/clear` to reset and reload the next feature's context fresh.

**Per-feature commits (recommended order — largest to smallest impact):**
1. **family_sync** (largest — sync clients, 6+ providers, 5+ screens/widgets, sync_providers split)
2. **accounting** (large — voice_providers split, use_case_providers fold, 5 screens, 1 widget, 1 utils file, 1 reorder rename)
3. **settings** (medium — locale_provider rename, settings split, backup fold, appearance_section import swap)
4. **analytics** (medium — analytics_providers split, repository_providers swap, screen swap)
5. **profile** (small — user_profile_providers split)
6. **home** (small — 3 file renames, home_screen swap)
7. **dual_ledger** (smallest — ledger_providers rename only)
8. **architecture test commit** (final — adds the meta-test enforcing the rules cannot be weakened in future)
9. **infrastructure-side cleanup commit** (final — deletes the original `e2eeServiceProvider`, `relayApiClientProvider`, etc. from `lib/features/family_sync/presentation/providers/repository_providers.dart` once all consumers have migrated to `app`-prefixed application-layer versions; per Warning 7 fix)

Wave 3, depends on Plan 04-01 (Wave 2). Plan 04-05 (Wave 4) consumes the new structure.

Output: 33 imports removed; 7 yamls tightened (infrastructure/** + existing data/daos/** + data/tables/**); 12+ provider files renamed; 1+ deleted; 1 architecture test added; coverage_gate.dart exits 0 on all touched files; HIGH-02 + HIGH-04 (structural) + HIGH-01 closed.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/04-high-fixes/04-CONTEXT.md
@.planning/phases/04-high-fixes/04-PATTERNS.md
@.planning/audit/REPO-LOCK-POLICY.md
@CLAUDE.md

<!-- Plan 04-01 scaffolding (the consumption target) -->
@lib/application/family_sync/repository_providers.dart
@lib/application/i18n/formatter_service.dart
@lib/application/i18n/locale_settings_view.dart
@lib/application/ml/repository_providers.dart
@lib/application/ml/lookup_merchant_use_case.dart
@lib/application/voice/start_speech_recognition_use_case.dart
@lib/application/voice/repository_providers.dart
@lib/application/family_sync/notify_member_approval_use_case.dart
@lib/application/family_sync/listen_to_push_notifications_use_case.dart

<!-- Phase 3 architecture test analog (template for presentation_layer_rules_test) -->
@test/architecture/domain_import_rules_test.dart

<!-- Existing presentation import_guard yaml (current state — verify partial deny) -->
@lib/features/accounting/presentation/import_guard.yaml
@lib/features/family_sync/presentation/import_guard.yaml

<!-- Reference deny-pattern for tightening (full strict deny) -->
@lib/features/accounting/domain/import_guard.yaml

<!-- 33 violating files — read each before edit -->
@lib/features/accounting/presentation/providers/voice_providers.dart
@lib/features/accounting/presentation/providers/repository_providers.dart
@lib/features/accounting/presentation/providers/use_case_providers.dart
@lib/features/accounting/presentation/screens/category_selection_screen.dart
@lib/features/accounting/presentation/screens/transaction_form_screen.dart
@lib/features/accounting/presentation/screens/transaction_confirm_screen.dart
@lib/features/accounting/presentation/screens/voice_input_screen.dart
@lib/features/accounting/presentation/screens/transaction_entry_screen.dart
@lib/features/accounting/presentation/widgets/transaction_list_tile.dart
@lib/features/accounting/presentation/utils/category_display_utils.dart
@lib/features/accounting/presentation/providers/category_reorder_notifier.dart
@lib/features/analytics/presentation/providers/repository_providers.dart
@lib/features/analytics/presentation/providers/analytics_providers.dart
@lib/features/analytics/presentation/screens/analytics_screen.dart
@lib/features/dual_ledger/presentation/providers/ledger_providers.dart
@lib/features/family_sync/presentation/providers/active_group_provider.dart
@lib/features/family_sync/presentation/providers/avatar_sync_providers.dart
@lib/features/family_sync/presentation/providers/group_providers.dart
@lib/features/family_sync/presentation/providers/notification_navigation_provider.dart
@lib/features/family_sync/presentation/providers/repository_providers.dart
@lib/features/family_sync/presentation/providers/sync_providers.dart
@lib/features/family_sync/presentation/screens/create_group_screen.dart
@lib/features/family_sync/presentation/screens/member_approval_screen.dart
@lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart
@lib/features/home/presentation/providers/home_providers.dart
@lib/features/home/presentation/providers/today_transactions_provider.dart
@lib/features/home/presentation/providers/shadow_books_provider.dart
@lib/features/home/presentation/screens/home_screen.dart
@lib/features/profile/presentation/providers/user_profile_providers.dart
@lib/features/settings/presentation/providers/backup_providers.dart
@lib/features/settings/presentation/providers/locale_provider.dart
@lib/features/settings/presentation/providers/settings_providers.dart
@lib/features/settings/presentation/widgets/appearance_section.dart

<interfaces>
<!-- The 33 illegal imports → routing target table -->

| Sub-pattern | Files (count) | Routing target |
|-------------|---------------|----------------|
| (a) i18n formatters | accounting/screens/{transaction_confirm, voice_input, transaction_entry}.dart, accounting/widgets/transaction_list_tile.dart, analytics/screens/analytics_screen.dart (5 imports) | `import 'package:home_pocket_app/application/i18n/formatter_service.dart';` then `ref.watch(formatterServiceProvider).formatDate(...)` |
| (a') locale_settings model | settings/providers/locale_provider.dart, settings/widgets/appearance_section.dart (2 imports) | `import 'package:home_pocket_app/application/i18n/locale_settings_view.dart';` (re-export) |
| (b) crypto/security/sync DI | accounting/providers/{repository, use_case, voice}_providers.dart, family_sync/providers/{repository, sync, group}_providers.dart, family_sync/screens/{create_group, member_approval}_screen.dart, family_sync/widgets/family_sync_notification_route_listener.dart, family_sync/providers/notification_navigation_provider.dart, profile/providers/user_profile_providers.dart, analytics/providers/repository_providers.dart, analytics/screens/analytics_screen.dart (~16 imports) | `import 'package:home_pocket_app/application/<feature>/repository_providers.dart';` and reference `app`-prefixed names (`appE2eeServiceProvider`, `appRelayApiClientProvider`, etc.) per Plan 04-01 Task 2 |
| (c) direct service classes (CategoryService) | accounting/screens/{category_selection, transaction_form}_screen.dart, accounting/utils/category_display_utils.dart, home/screens/home_screen.dart (4 imports) | `import 'package:home_pocket_app/application/accounting/category_service.dart';` (already exists per PATTERNS.md §5(c)) — these screens may simply switch to `categoryServiceProvider` from the existing application-layer file |
| (d) sync clients in screens | family_sync/screens/{create_group, member_approval}_screen.dart, family_sync/widgets/family_sync_notification_route_listener.dart, family_sync/providers/notification_navigation_provider.dart (4 imports) | new use cases per Plan 04-01 (NotifyMemberApprovalUseCase, ListenToPushNotificationsUseCase) |
| (e) speech service in screen | accounting/screens/voice_input_screen.dart (1 import) | `ref.read(startSpeechRecognitionUseCaseProvider).execute(localeId: ...)` |

<!-- Edit pattern (before / after) for category (a) -->
```dart
// BEFORE
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
DateFormatter.formatDate(_date, locale)

// AFTER
import '../../../../application/i18n/formatter_service.dart';
ref.watch(formatterServiceProvider).formatDate(_date, locale)
```

<!-- Edit pattern (before / after) for category (b) — uses app-prefixed names from Plan 04-01 Task 2 -->
```dart
// BEFORE
import '../../../../infrastructure/sync/e2ee_service.dart';
final e2ee = ref.watch(e2eeServiceProvider);

// AFTER
import '../../../../application/family_sync/repository_providers.dart';
final e2ee = ref.watch(appE2eeServiceProvider);
```

<!-- Tightened import_guard.yaml (replaces existing 6-line partial deny — Phase 4 scope) -->
```yaml
# Presentation layer — uses Application + Domain only. MUST NOT reach Infrastructure.
# data/repositories/** access remains permitted in Phase 4 (Phase 5+ MED scope).
deny:
  - package:home_pocket/infrastructure/**
  - package:home_pocket/data/daos/**
  - package:home_pocket/data/tables/**

inherit: true
```

<!-- Architecture test template (mirrors test/architecture/domain_import_rules_test.dart) -->
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Presentation layer import_guard rules', () {
    const features = [
      'accounting', 'analytics', 'dual_ledger', 'family_sync', 'home', 'profile', 'settings',
    ];
    // Phase 4 scope: infrastructure/** + existing data/daos/** + data/tables/**.
    // data/repositories/** intentionally NOT denied here — out of scope per CONTEXT.md
    // <domain> 'In scope' list; scheduled for Phase 5+ MED scope.
    const requiredDeny = [
      'package:home_pocket/infrastructure/**',
      'package:home_pocket/data/daos/**',
      'package:home_pocket/data/tables/**',
    ];

    for (final feature in features) {
      group('feature: $feature', () {
        test('presentation yaml denies infrastructure/** + data/daos/** + data/tables/**', () {
          final path = 'lib/features/$feature/presentation/import_guard.yaml';
          final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
          final deny = (yaml['deny'] as YamlList).map((e) => e.toString()).toList();
          expect(deny, containsAll(requiredDeny),
              reason: 'Feature $feature presentation: deny list weakened (Phase 4 scope: infrastructure + data/daos + data/tables)');
          expect(yaml['inherit'], isTrue);
        });
      });
    }
  });
}
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Refactor family_sync — swap 9 infrastructure imports + split sync_providers + fold group_providers/avatar_sync_providers DI + rename active_group_provider/notification_navigation_provider + tighten yaml + atomic commit</name>
  <files>
    lib/features/family_sync/presentation/providers/repository_providers.dart, lib/features/family_sync/presentation/providers/repository_providers.g.dart, lib/features/family_sync/presentation/providers/sync_providers.dart, lib/features/family_sync/presentation/providers/state_sync.dart, lib/features/family_sync/presentation/providers/state_sync.g.dart, lib/features/family_sync/presentation/providers/group_providers.dart, lib/features/family_sync/presentation/providers/avatar_sync_providers.dart, lib/features/family_sync/presentation/providers/active_group_provider.dart, lib/features/family_sync/presentation/providers/state_active_group.dart, lib/features/family_sync/presentation/providers/state_active_group.g.dart, lib/features/family_sync/presentation/providers/notification_navigation_provider.dart, lib/features/family_sync/presentation/providers/state_notification_navigation.dart, lib/features/family_sync/presentation/providers/state_notification_navigation.g.dart, lib/features/family_sync/presentation/screens/create_group_screen.dart, lib/features/family_sync/presentation/screens/member_approval_screen.dart, lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart, lib/features/family_sync/presentation/import_guard.yaml
  </files>
  <read_first>
    - All files in `<files>` (full read each)
    - lib/application/family_sync/repository_providers.dart (Plan 04-01 scaffold — copy `app`-prefixed provider names verbatim: `appE2eeServiceProvider`, `appRelayApiClientProvider`, `appApnsPushMessagingClientProvider`, `appPushNotificationServiceProvider`, `appSyncQueueProvider`, `appWebsocketServiceProvider`)
    - lib/application/family_sync/notify_member_approval_use_case.dart
    - lib/application/family_sync/listen_to_push_notifications_use_case.dart
    - test/unit/features/family_sync/presentation/providers/sync_providers_characterization_test.dart (Plan 04-06 — verify keepAlive locks)
    - PATTERNS.md §6 (rename mapping table) and §8 (yaml tightening)
  </read_first>
  <behavior>
    - Test 1 (post-refactor): `grep "import.*infrastructure" lib/features/family_sync/presentation/` returns 0 matches
    - Test 2 (post-refactor): `lib/features/family_sync/presentation/providers/repository_providers.dart` imports from `package:home_pocket_app/application/family_sync/repository_providers.dart` (the application-side file) and references `app`-prefixed provider names
    - Test 3 (keepAlive preservation): `state_sync.dart` contains `@Riverpod(keepAlive: true)` on both `transactionChangeTracker` and `syncEngine`
    - Test 4 (keepAlive preservation): `state_active_group.dart` contains `@Riverpod(keepAlive: true)` on `activeGroup`
    - Test 5 (yaml tightened): `lib/features/family_sync/presentation/import_guard.yaml` deny contains `package:home_pocket/infrastructure/**`, `package:home_pocket/data/daos/**`, `package:home_pocket/data/tables/**`
    - Test 6 (no orphan files): `ls lib/features/family_sync/presentation/providers/` returns ONLY {repository_providers.dart, repository_providers.g.dart, state_sync.dart, state_sync.g.dart, state_active_group.dart, state_active_group.g.dart, state_notification_navigation.dart, state_notification_navigation.g.dart}
    - Test 7 (Plan 04-06 characterization tests still GREEN): `flutter test test/unit/features/family_sync/presentation/` exits 0
    - Test 8 (import_guard blocking gate): `dart run custom_lint` exits 0 (no LV findings)
  </behavior>
  <action>
    Execute as ONE atomic feature commit per CONTEXT.md D-20. The order within the commit:

    1. **Split sync_providers.dart** per CONTEXT.md D-06 + PATTERNS.md §6:
       - DI providers (PushSyncUseCase, PullSyncUseCase, ShadowBookService, ApplySyncOperationsUseCase, CheckGroupValidityUseCase, FullSyncUseCase, SyncOrchestrator, HandleMemberLeftUseCase, HandleGroupDissolvedUseCase) → MOVE to `lib/features/family_sync/presentation/providers/repository_providers.dart` (extending the existing file). Update each `ref.watch(relayApiClientProvider)` to use the `app`-prefixed application-layer provider: `ref.watch(appRelayApiClientProvider)` after adding `import 'package:home_pocket_app/application/family_sync/repository_providers.dart';`.
       - Stream/notifier providers (transactionChangeTracker line 118, syncEngine line 141, syncStatusStream line 154-156, groupMembers line 161-167) → MOVE to NEW file `lib/features/family_sync/presentation/providers/state_sync.dart`. **CRITICAL: copy `@Riverpod(keepAlive: true)` annotation verbatim on transactionChangeTracker and syncEngine**.
       - DELETE the old `lib/features/family_sync/presentation/providers/sync_providers.dart` (and `.g.dart`).
       - Run `flutter pub run build_runner build --delete-conflicting-outputs` to regen `.g.dart` for both new files.
       - Update all callers across `lib/`, `test/` from `import 'sync_providers.dart'` to the appropriate new file (DI consumers → `repository_providers.dart`; state consumers → `state_sync.dart`).

    2. **Fold group_providers.dart into repository_providers.dart** (per CONTEXT.md D-06 + PATTERNS.md §6: all 9 providers in current file are use-case DI — no notifier means no `state_group.dart` needed): copy contents into `repository_providers.dart`, delete `group_providers.dart` and its `.g.dart`. Update callers.

    3. **Fold avatar_sync_providers.dart DI into repository_providers.dart**: `syncAvatarUseCaseProvider` is DI → fold; delete file. Update callers.

    4. **Rename active_group_provider.dart → state_active_group.dart** (PRESERVE `@Riverpod(keepAlive: true)` on activeGroup line 13 verbatim):
       ```bash
       git mv lib/features/family_sync/presentation/providers/active_group_provider.dart lib/features/family_sync/presentation/providers/state_active_group.dart
       git mv lib/features/family_sync/presentation/providers/active_group_provider.g.dart lib/features/family_sync/presentation/providers/state_active_group.g.dart 2>/dev/null || true
       ```
       Edit renamed file to update `part 'active_group_provider.g.dart';` → `part 'state_active_group.g.dart';`. Run build_runner. Update callers.

    5. **Rename notification_navigation_provider.dart → state_notification_navigation.dart** with the same git mv + part-update + build_runner pattern. Replace its `infrastructure/sync/push_notification_service.dart` import (line 5) with `import 'package:home_pocket_app/application/family_sync/listen_to_push_notifications_use_case.dart';` and update call sites to use `ref.read(listenToPushNotificationsUseCaseProvider).execute()`.

    6. **Update repository_providers.dart**: replace lines 12-19 `import '../../../../infrastructure/{crypto,sync}/...';` (8 imports) with `import 'package:home_pocket_app/application/family_sync/repository_providers.dart';`. Update every `ref.watch(<name>Provider)` to `ref.watch(app<Name>Provider)` per Plan 04-01 Task 2 prefix convention. Verify `grep -rn "ref.watch(e2eeServiceProvider)" lib/features/family_sync/` returns 0 matches AFTER this task — all references must use `appE2eeServiceProvider`.

    7. **Update create_group_screen.dart**: replace lines 13-14 `import '../../../../infrastructure/{crypto,sync/websocket_service}.dart';` with `import 'package:home_pocket_app/application/family_sync/repository_providers.dart';` and update call sites to `app`-prefixed names.

    8. **Update member_approval_screen.dart**: replace lines 10-11 `infrastructure/{crypto/providers, sync/websocket_service}.dart` imports with `import 'package:home_pocket_app/application/family_sync/notify_member_approval_use_case.dart';` and update call site to `ref.read(notifyMemberApprovalUseCaseProvider).execute(memberId: ...)`.

    9. **Update family_sync_notification_route_listener.dart**: replace line 5 `infrastructure/sync/push_notification_service.dart` import with `import 'package:home_pocket_app/application/family_sync/listen_to_push_notifications_use_case.dart';` and update call sites accordingly.

    10. **Tighten lib/features/family_sync/presentation/import_guard.yaml**: replace existing 6-line partial deny with:
        ```yaml
        # Presentation layer — uses Application + Domain only. MUST NOT reach Infrastructure.
        # data/repositories/** access remains permitted in Phase 4 (Phase 5+ MED scope).
        deny:
          - package:home_pocket/infrastructure/**
          - package:home_pocket/data/daos/**
          - package:home_pocket/data/tables/**

        inherit: true
        ```

    11. Run `flutter pub run build_runner build --delete-conflicting-outputs`.
    12. Run `flutter analyze` — must exit 0.
    13. Run `dart run custom_lint` — must exit 0 (import_guard gate passes).
    14. Run `flutter test test/unit/features/family_sync/` — must pass GREEN (Plan 04-06 characterization tests verify keepAlive + behavior preservation).

    Then commit as ONE atomic commit per CONTEXT.md D-20:
    ```
    refactor(04-02): family_sync — route presentation through application/, restructure providers, tighten import_guard (HIGH-02, HIGH-04 family_sync portion)
    ```
  </action>
  <verify>
    <automated>grep -rn "import.*infrastructure" lib/features/family_sync/presentation/; flutter analyze 2>&amp;1 | tail -5; dart run custom_lint 2>&amp;1 | tail -5; flutter test test/unit/features/family_sync/ 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "import.*infrastructure" lib/features/family_sync/presentation/` returns 0 matches
    - `grep -rn "ref.watch(e2eeServiceProvider)" lib/features/family_sync/` returns 0 matches (consumers use `appE2eeServiceProvider` after Plan 04-01 Task 2 prefixing)
    - `ls lib/features/family_sync/presentation/providers/ | grep -v ".g.dart" | sort` returns ONLY: `repository_providers.dart, state_active_group.dart, state_notification_navigation.dart, state_sync.dart`
    - `grep -c "@Riverpod(keepAlive: true)" lib/features/family_sync/presentation/providers/state_sync.dart` returns ≥2 (transactionChangeTracker + syncEngine)
    - `grep -c "@Riverpod(keepAlive: true)" lib/features/family_sync/presentation/providers/state_active_group.dart` returns ≥1 (activeGroup)
    - `grep "package:home_pocket/infrastructure/\*\*" lib/features/family_sync/presentation/import_guard.yaml` returns at least 1 match
    - `grep "package:home_pocket/data/daos/\*\*" lib/features/family_sync/presentation/import_guard.yaml` returns at least 1 match
    - `flutter analyze` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test test/unit/features/family_sync/` exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
  </acceptance_criteria>
  <done>family_sync presentation refactored; sync_providers split; group/avatar folded; active_group + notification_navigation renamed; yaml tightened; all atomic in ONE commit; tests + custom_lint GREEN. NOTE: original (non-prefixed) infrastructure providers still exist in `lib/features/family_sync/presentation/providers/repository_providers.dart` from Plan 04-01 Task 2's coexistence pattern — they are deleted in Task 5 (final cleanup commit) once ALL features have migrated to `app`-prefixed names. **`/clear` recommended before next task.**</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Refactor accounting — swap ~9 infrastructure imports + fold use_case_providers + split voice_providers + rename category_reorder_notifier + tighten yaml + atomic commit</name>
  <files>
    lib/features/accounting/presentation/screens/transaction_confirm_screen.dart, lib/features/accounting/presentation/screens/voice_input_screen.dart, lib/features/accounting/presentation/screens/transaction_entry_screen.dart, lib/features/accounting/presentation/screens/category_selection_screen.dart, lib/features/accounting/presentation/screens/transaction_form_screen.dart, lib/features/accounting/presentation/widgets/transaction_list_tile.dart, lib/features/accounting/presentation/utils/category_display_utils.dart, lib/features/accounting/presentation/providers/repository_providers.dart, lib/features/accounting/presentation/providers/repository_providers.g.dart, lib/features/accounting/presentation/providers/use_case_providers.dart, lib/features/accounting/presentation/providers/voice_providers.dart, lib/features/accounting/presentation/providers/state_voice.dart, lib/features/accounting/presentation/providers/state_voice.g.dart, lib/features/accounting/presentation/providers/category_reorder_notifier.dart, lib/features/accounting/presentation/providers/state_category_reorder.dart, lib/features/accounting/presentation/providers/state_category_reorder.g.dart, lib/features/accounting/presentation/import_guard.yaml
  </files>
  <read_first>
    - All files in `<files>` (full read each)
    - lib/application/accounting/repository_providers.dart (Plan 04-01 scaffold — `appAppDatabaseProvider`, `appKeyManagerProvider`)
    - lib/application/i18n/formatter_service.dart (Plan 04-01)
    - lib/application/ml/repository_providers.dart (Plan 04-01 — `appMerchantDatabaseProvider` keepAlive)
    - lib/application/voice/start_speech_recognition_use_case.dart (Plan 04-01)
    - lib/application/accounting/category_service.dart (existing — verify it exposes methods replacing `infrastructure/category/category_service.dart` calls)
    - PATTERNS.md §6 (rename mapping table)
  </read_first>
  <behavior>
    - Test 1: `grep -rn "import.*infrastructure" lib/features/accounting/presentation/` returns 0 matches
    - Test 2: `transaction_confirm_screen.dart` no longer references `DateFormatter.formatDate(...)` directly; uses `ref.watch(formatterServiceProvider).formatDate(...)` instead
    - Test 3: `voice_input_screen.dart` no longer references `SpeechRecognitionService.start(...)`; uses `ref.read(startSpeechRecognitionUseCaseProvider).execute(localeId: ...)`
    - Test 4: `lib/features/accounting/presentation/providers/use_case_providers.dart` does NOT exist (folded into repository_providers.dart per CONTEXT.md D-13 commit 2 note)
    - Test 5: `state_voice.dart` exists; `voice_providers.dart` does NOT exist (split: DI to repository_providers, state to state_voice)
    - Test 6: `state_category_reorder.dart` exists; `category_reorder_notifier.dart` does NOT exist (pure rename)
    - Test 7: `lib/features/accounting/presentation/providers/repository_providers.dart` imports from `package:home_pocket_app/application/accounting/repository_providers.dart` (no `infrastructure/` imports) and consumers reference `appAppDatabaseProvider` / `appKeyManagerProvider`
    - Test 8: `lib/features/accounting/presentation/import_guard.yaml` deny contains `package:home_pocket/infrastructure/**`, `package:home_pocket/data/daos/**`, `package:home_pocket/data/tables/**`
    - Test 9: `merchantDatabaseProvider` is consumed via `ref.watch(appMerchantDatabaseProvider)` from `package:home_pocket_app/application/ml/repository_providers.dart` (NOT redefined in feature/)
    - Test 10: `flutter test test/unit/features/accounting/` exits 0
  </behavior>
  <action>
    Atomic feature commit per CONTEXT.md D-20. Steps:

    1. **Update transaction_confirm_screen.dart**: replace lines 11-12 (`infrastructure/i18n/formatters/{date,number}_formatter.dart` imports) with `import 'package:home_pocket_app/application/i18n/formatter_service.dart';`. Replace every `DateFormatter.formatX(...)` call with `ref.watch(formatterServiceProvider).formatX(...)` and every `NumberFormatter.formatY(...)` call with `ref.watch(formatterServiceProvider).formatY(...)`. (Use `ref.watch` not `ref.read` since formatter is const-cached and reactive isn't needed; either works but `watch` is canonical for in-build calls.)

    2. **Update voice_input_screen.dart**: replace lines 11-12 (formatters) per same pattern as step 1. Replace line 13 (`infrastructure/speech/speech_recognition_service.dart`) with `import 'package:home_pocket_app/application/voice/start_speech_recognition_use_case.dart';` and update call sites: `SpeechRecognitionService.start(...)` → `ref.read(startSpeechRecognitionUseCaseProvider).execute(localeId: ...)`. For stop: `service.stop()` → `ref.read(startSpeechRecognitionUseCaseProvider).stop()`.

    3. **Update transaction_entry_screen.dart**: replace line 7 (`infrastructure/i18n/formatters/date_formatter.dart`) per pattern in step 1.

    4. **Update transaction_list_tile.dart** (widget): replace line 4 (`infrastructure/i18n/formatters/date_formatter.dart`) per pattern in step 1. Note the widget receives `WidgetRef` via `ConsumerWidget` — if it's currently `StatelessWidget`, convert to `ConsumerWidget` (signature change).

    5. **Update category_selection_screen.dart**: replace line 7 (`infrastructure/category/category_service.dart`) with `import 'package:home_pocket_app/application/accounting/category_service.dart';` (existing application-layer file). Update any `CategoryService` references to use the application-layer class (likely identical class name; if so, only the import path changes).

    6. **Update transaction_form_screen.dart**: replace line 10 per same pattern as step 5.

    7. **Update category_display_utils.dart**: replace line 3 per same pattern as step 5.

    8. **Fold use_case_providers.dart into repository_providers.dart** per CONTEXT.md D-06: read remaining content of `use_case_providers.dart` (post-Plan 04-03 RLS deletion, the file is shorter), copy each `@riverpod` provider into `repository_providers.dart` preserving annotations, then DELETE `use_case_providers.dart` and its `.g.dart`. Update all callers across `lib/` and `test/`.

    9. **Split voice_providers.dart**: DI providers (voiceTextParser, fuzzyCategoryMatcher, parseVoiceInputUseCase, voiceSatisfactionEstimator) fold into `repository_providers.dart`. The `merchantDatabaseProvider` keepAlive (lines 16-19) is now provided by Plan 04-01's `lib/application/ml/repository_providers.dart` as `appMerchantDatabaseProvider` — REMOVE from feature side; consumers import from application/ml using the `app`-prefixed name. State portion (none currently in voice_providers.dart per PATTERNS.md §6 first row) — file may have no `state_voice.dart` content; create a minimal placeholder OR skip creating `state_voice.dart` if no state providers exist. **DECISION:** if no state providers exist, do NOT create `state_voice.dart` — only `repository_providers.dart` remains for accounting providers (per CONTEXT.md D-05: zero `state_*.dart` files allowed for features with no notifier providers). Adjust the `files_modified` list accordingly.

    10. **Rename category_reorder_notifier.dart → state_category_reorder.dart** (pure rename per PATTERNS.md §6):
        ```bash
        git mv lib/features/accounting/presentation/providers/category_reorder_notifier.dart lib/features/accounting/presentation/providers/state_category_reorder.dart
        git mv lib/features/accounting/presentation/providers/category_reorder_notifier.g.dart lib/features/accounting/presentation/providers/state_category_reorder.g.dart 2>/dev/null || true
        ```
        Edit renamed file: `part 'category_reorder_notifier.g.dart';` → `part 'state_category_reorder.g.dart';`. Run build_runner. Update callers.

    11. **Update repository_providers.dart**: replace lines 17-18 (`infrastructure/{crypto, security}/providers.dart` imports) with `import 'package:home_pocket_app/application/accounting/repository_providers.dart';`. Replace `ref.watch(appDatabaseProvider)` with `ref.watch(appAppDatabaseProvider)` (Plan 04-01 prefix) and similar for `keyManagerProvider` → `appKeyManagerProvider`.

    12. **Tighten lib/features/accounting/presentation/import_guard.yaml** per `<interfaces>` template (Phase 4 scope: infrastructure/** + existing data/daos/** + data/tables/**).

    13. Run build_runner; run `flutter analyze`; run `dart run custom_lint`; run `flutter test test/unit/features/accounting/`. All must pass.

    Then commit:
    ```
    refactor(04-02): accounting — route presentation through application/, fold use_case + voice DI, rename category_reorder, tighten import_guard (HIGH-02, HIGH-04)
    ```
  </action>
  <verify>
    <automated>grep -rn "import.*infrastructure" lib/features/accounting/presentation/; ls lib/features/accounting/presentation/providers/; flutter analyze 2>&amp;1 | tail -5; flutter test test/unit/features/accounting/ 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "import.*infrastructure" lib/features/accounting/presentation/` returns 0 matches
    - `lib/features/accounting/presentation/providers/use_case_providers.dart` does NOT exist
    - `lib/features/accounting/presentation/providers/voice_providers.dart` does NOT exist (DI folded; if no state providers existed, no state_voice.dart created either)
    - `lib/features/accounting/presentation/providers/category_reorder_notifier.dart` does NOT exist (renamed to state_category_reorder.dart)
    - `lib/features/accounting/presentation/providers/state_category_reorder.dart` exists
    - `grep "DateFormatter\." lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` returns 0 matches (replaced with formatterServiceProvider)
    - `grep "SpeechRecognitionService" lib/features/accounting/presentation/screens/voice_input_screen.dart` returns 0 matches
    - `grep "package:home_pocket/infrastructure/\*\*" lib/features/accounting/presentation/import_guard.yaml` returns at least 1 match
    - `grep "package:home_pocket/data/daos/\*\*" lib/features/accounting/presentation/import_guard.yaml` returns at least 1 match
    - `flutter analyze` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test test/unit/features/accounting/` exits 0
  </acceptance_criteria>
  <done>accounting presentation refactored; use_case + voice folded; category_reorder renamed; yaml tightened; all atomic; tests GREEN. **`/clear` recommended before next task.**</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Refactor settings — swap 2 imports + rename locale_provider + split settings_providers + fold backup_providers + appearance_section import + tighten yaml + atomic commit</name>
  <files>
    lib/features/settings/presentation/providers/locale_provider.dart, lib/features/settings/presentation/providers/state_locale.dart, lib/features/settings/presentation/providers/state_locale.g.dart, lib/features/settings/presentation/providers/settings_providers.dart, lib/features/settings/presentation/providers/state_settings.dart, lib/features/settings/presentation/providers/state_settings.g.dart, lib/features/settings/presentation/providers/backup_providers.dart, lib/features/settings/presentation/providers/repository_providers.dart, lib/features/settings/presentation/providers/repository_providers.g.dart, lib/features/settings/presentation/widgets/appearance_section.dart, lib/features/settings/presentation/import_guard.yaml
  </files>
  <read_first>
    - All files in `<files>` (full read each)
    - lib/application/settings/repository_providers.dart (Plan 04-01)
    - lib/application/i18n/locale_settings_view.dart (Plan 04-01 re-export)
    - PATTERNS.md §6 settings rows
  </read_first>
  <behavior>
    - Test 1: `grep -rn "import.*infrastructure" lib/features/settings/presentation/` returns 0 matches
    - Test 2: `state_locale.dart` exists; `locale_provider.dart` does NOT exist (renamed)
    - Test 3: `state_settings.dart` exists with notifier-only providers; `settings_providers.dart` may shrink (top-level `voiceLocaleIdFromLanguageCode` function may move to lib/shared/ OR stay)
    - Test 4: `backup_providers.dart` does NOT exist (folded into repository_providers.dart per CONTEXT.md D-06)
    - Test 5: `appearance_section.dart` line 5 import replaced with application-layer locale_settings_view import
    - Test 6: `lib/features/settings/presentation/import_guard.yaml` deny contains `package:home_pocket/infrastructure/**`, `package:home_pocket/data/daos/**`, `package:home_pocket/data/tables/**`
    - Test 7: `flutter test test/unit/features/settings/` exits 0
  </behavior>
  <action>
    Atomic feature commit per CONTEXT.md D-20. Steps:

    1. **Rename locale_provider.dart → state_locale.dart**: `git mv` + part-update + build_runner + update callers. Replace its line 6 (`infrastructure/i18n/models/locale_settings.dart`) with `import 'package:home_pocket_app/application/i18n/locale_settings_view.dart';`.

    2. **Update appearance_section.dart**: replace line 5 (`infrastructure/i18n/models/locale_settings.dart`) with `import 'package:home_pocket_app/application/i18n/locale_settings_view.dart';`.

    3. **Split settings_providers.dart per CONTEXT.md D-06 + PATTERNS.md §6**: `appSettings` (Future) and `voiceLocaleId` providers → MOVE to NEW `lib/features/settings/presentation/providers/state_settings.dart`. `voiceLocaleIdFromLanguageCode` is a public top-level function — KEEP in `settings_providers.dart` (rename to `lib/features/settings/presentation/utils/voice_locale_helpers.dart` is cleaner but per CONTEXT.md D-05 only `repository_providers.dart` and `state_*.dart` are allowed in `providers/`). **DECISION:** move `voiceLocaleIdFromLanguageCode` to `lib/features/settings/presentation/utils/voice_locale_helpers.dart` (new file), delete `settings_providers.dart`. Update all callers. Adjust `files_modified` to include the new utils file.

    4. **Fold backup_providers.dart into repository_providers.dart** per CONTEXT.md D-06: all 3 providers (exportBackupUseCase, importBackupUseCase, clearAllDataUseCase) are DI → fold; delete `backup_providers.dart` and its `.g.dart`. Update callers.

    5. **Update repository_providers.dart**: if it imports from infrastructure, replace with application-layer imports per Plan 04-01 scaffold (use `app`-prefixed names: `appAppDatabaseProvider`).

    6. **Tighten import_guard.yaml** per `<interfaces>` template (Phase 4 scope).

    7. Run build_runner; analyze; custom_lint; test. All must pass.

    Then commit:
    ```
    refactor(04-02): settings — rename locale_provider→state_locale, split settings, fold backup, route through application/ (HIGH-02, HIGH-04)
    ```
  </action>
  <verify>
    <automated>grep -rn "import.*infrastructure" lib/features/settings/presentation/; ls lib/features/settings/presentation/providers/; flutter test test/unit/features/settings/ 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "import.*infrastructure" lib/features/settings/presentation/` returns 0 matches
    - `lib/features/settings/presentation/providers/locale_provider.dart` does NOT exist
    - `lib/features/settings/presentation/providers/state_locale.dart` exists
    - `lib/features/settings/presentation/providers/backup_providers.dart` does NOT exist
    - `lib/features/settings/presentation/providers/state_settings.dart` exists OR settings notifier providers folded; either way `settings_providers.dart` final state is empty/deleted
    - `grep "package:home_pocket/infrastructure/\*\*" lib/features/settings/presentation/import_guard.yaml` returns at least 1 match
    - `grep "package:home_pocket/data/daos/\*\*" lib/features/settings/presentation/import_guard.yaml` returns at least 1 match
    - `flutter analyze` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test test/unit/features/settings/` exits 0
  </acceptance_criteria>
  <done>settings presentation refactored; locale renamed; settings split; backup folded; yaml tightened; tests GREEN. **`/clear` recommended before next task.**</done>
</task>

<task type="auto" tdd="true">
  <name>Task 4: Refactor analytics + profile + home + dual_ledger (4 small features in one task; per-feature commit)</name>
  <files>
    lib/features/analytics/presentation/providers/repository_providers.dart, lib/features/analytics/presentation/providers/repository_providers.g.dart, lib/features/analytics/presentation/providers/analytics_providers.dart, lib/features/analytics/presentation/providers/state_analytics.dart, lib/features/analytics/presentation/providers/state_analytics.g.dart, lib/features/analytics/presentation/screens/analytics_screen.dart, lib/features/analytics/presentation/import_guard.yaml, lib/features/profile/presentation/providers/user_profile_providers.dart, lib/features/profile/presentation/providers/state_user_profile.dart, lib/features/profile/presentation/providers/state_user_profile.g.dart, lib/features/profile/presentation/import_guard.yaml, lib/features/home/presentation/providers/home_providers.dart, lib/features/home/presentation/providers/state_home.dart, lib/features/home/presentation/providers/state_home.g.dart, lib/features/home/presentation/providers/today_transactions_provider.dart, lib/features/home/presentation/providers/state_today_transactions.dart, lib/features/home/presentation/providers/state_today_transactions.g.dart, lib/features/home/presentation/providers/shadow_books_provider.dart, lib/features/home/presentation/providers/state_shadow_books.dart, lib/features/home/presentation/providers/state_shadow_books.g.dart, lib/features/home/presentation/screens/home_screen.dart, lib/features/home/presentation/import_guard.yaml, lib/features/dual_ledger/presentation/providers/ledger_providers.dart, lib/features/dual_ledger/presentation/providers/state_ledger.dart, lib/features/dual_ledger/presentation/providers/state_ledger.g.dart, lib/features/dual_ledger/presentation/import_guard.yaml
  </files>
  <read_first>
    - All files in `<files>` (full read each)
    - lib/application/analytics/repository_providers.dart, lib/application/profile/repository_providers.dart, lib/application/home/repository_providers.dart, lib/application/dual_ledger/repository_providers.dart (Plan 04-01 scaffolds)
    - lib/application/i18n/formatter_service.dart (for analytics_screen formatter swap)
    - PATTERNS.md §6 rows for each feature
  </read_first>
  <behavior>
    - Test 1: `grep -rn "import.*infrastructure" lib/features/{analytics,profile,home,dual_ledger}/presentation/` returns 0 matches
    - Test 2 (analytics): `analytics_screen.dart` no longer references `DateFormatter.formatDate(...)` directly; uses `formatterServiceProvider`. `repository_providers.dart` no longer imports `infrastructure/security/providers`
    - Test 3 (profile): `user_profile_providers.dart` split into `state_user_profile.dart` (Future userProfile) + `repository_providers.dart` (DI: userProfileDao, userProfileRepository, getUserProfileUseCase, saveUserProfileUseCase)
    - Test 4 (home): `home_providers.dart`→`state_home.dart`, `today_transactions_provider.dart`→`state_today_transactions.dart`, `shadow_books_provider.dart`→`state_shadow_books.dart` (3 renames per CONTEXT.md D-06); `home_screen.dart` line 15 (`infrastructure/category/category_service.dart`) replaced with `application/accounting/category_service.dart`. `home_providers.dart` `selectedTabIndexProvider` (with `@Riverpod(keepAlive: true)` per PATTERNS.md §12 ground truth) PRESERVES the keepAlive annotation in its new home `state_home.dart`
    - Test 5 (dual_ledger): `ledger_providers.dart`→`state_ledger.dart` (pure rename); `LedgerView` class with `@Riverpod(keepAlive: true)` (line 8) preserved verbatim. The `@Riverpod(keepAlive: true)` on the `LedgerView` class generates `ledgerViewProvider` — Plan 04-05 will reconcile whether the HIGH-05 hard list entry `ledgerProvider` matches `ledgerViewProvider` (currently mismatched per PATTERNS.md §12)
    - Test 6: 4 yaml files tightened per `<interfaces>` template (Phase 4 scope: infrastructure/** + data/daos/** + data/tables/**)
    - Test 7: `flutter test test/unit/features/{analytics,profile,home,dual_ledger}/` exits 0
  </behavior>
  <action>
    4 atomic per-feature commits per CONTEXT.md D-20.

    **Sub-task 4a: analytics**
    1. Update `analytics_screen.dart`: replace line 7 (date_formatter) with formatterServiceProvider import; replace line 8 (`infrastructure/security/providers.dart`) with `import 'package:home_pocket_app/application/analytics/repository_providers.dart';` and reference `appAppDatabaseProvider`. Update call sites accordingly.
    2. Update `repository_providers.dart`: replace line 7 (`infrastructure/security/providers.dart`) with the application import.
    3. Split `analytics_providers.dart` per CONTEXT.md D-06: planner reads file and categorizes each provider as DI (fold) or notifier (move to `state_analytics.dart`). Default disposition: most analytics providers are async data → `state_analytics.dart`.
    4. Tighten `lib/features/analytics/presentation/import_guard.yaml` (Phase 4 scope).
    5. build_runner + analyze + custom_lint + tests.
    6. Commit: `refactor(04-02): analytics — route through application/, split providers, tighten import_guard (HIGH-02, HIGH-04)`

    **Sub-task 4b: profile**
    1. Split `user_profile_providers.dart`: DI providers (userProfileDao, userProfileRepository, getUserProfileUseCase, saveUserProfileUseCase) → existing/new `repository_providers.dart` (create if absent). State (`userProfile` Future) → new `state_user_profile.dart`.
    2. Replace line 8 (`infrastructure/security/providers.dart`) with `import 'package:home_pocket_app/application/profile/repository_providers.dart';` and reference `app`-prefixed names. Update call sites.
    3. Tighten `lib/features/profile/presentation/import_guard.yaml` (Phase 4 scope).
    4. build_runner + analyze + custom_lint + tests.
    5. Commit: `refactor(04-02): profile — split user_profile_providers, route through application/, tighten import_guard (HIGH-02, HIGH-04)`

    **Sub-task 4c: home**
    1. Update `home_screen.dart`: replace line 15 (`infrastructure/category/category_service.dart`) with `import 'package:home_pocket_app/application/accounting/category_service.dart';`. Update call sites (likely no change since application class likely has same name).
    2. Rename `home_providers.dart` → `state_home.dart` (PRESERVE `@Riverpod(keepAlive: true)` on selectedTabIndex per PATTERNS.md §12). Use `git mv` + part-update + build_runner + update callers.
    3. Rename `today_transactions_provider.dart` → `state_today_transactions.dart` (pure rename — async data is state). Same git mv pattern.
    4. Rename `shadow_books_provider.dart` → `state_shadow_books.dart` (pure rename). Same git mv pattern.
    5. Add new `repository_providers.dart` if any DI needed (likely empty or minimal — most home providers consume from accounting/dual_ledger DI).
    6. Tighten `lib/features/home/presentation/import_guard.yaml` (Phase 4 scope).
    7. build_runner + analyze + custom_lint + tests.
    8. Commit: `refactor(04-02): home — route through application/, rename providers to state_*, tighten import_guard (HIGH-02, HIGH-04)`

    **Sub-task 4d: dual_ledger**
    1. Rename `ledger_providers.dart` → `state_ledger.dart` (PRESERVE `@Riverpod(keepAlive: true)` on `LedgerView` line 8 verbatim). git mv + part-update + build_runner + update callers.
    2. Tighten `lib/features/dual_ledger/presentation/import_guard.yaml` (Phase 4 scope; currently exists per the ls output earlier).
    3. build_runner + analyze + custom_lint + tests.
    4. Commit: `refactor(04-02): dual_ledger — rename ledger_providers→state_ledger, tighten import_guard (HIGH-04)`

    NOTE: The `ledgerProvider` vs `ledgerViewProvider` name mismatch is left for Plan 04-05 to reconcile per CONTEXT.md D-07.4.
  </action>
  <verify>
    <automated>grep -rn "import.*infrastructure" lib/features/analytics/presentation/ lib/features/profile/presentation/ lib/features/home/presentation/ lib/features/dual_ledger/presentation/; flutter test test/unit/features/analytics/ test/unit/features/profile/ test/unit/features/home/ test/unit/features/dual_ledger/ 2>&amp;1 | tail -10</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "import.*infrastructure" lib/features/analytics/presentation/ lib/features/profile/presentation/ lib/features/home/presentation/ lib/features/dual_ledger/presentation/` returns 0 matches
    - `lib/features/dual_ledger/presentation/providers/ledger_providers.dart` does NOT exist
    - `lib/features/dual_ledger/presentation/providers/state_ledger.dart` exists with `@Riverpod(keepAlive: true)`
    - `lib/features/home/presentation/providers/home_providers.dart`, `today_transactions_provider.dart`, `shadow_books_provider.dart` all do NOT exist
    - `lib/features/home/presentation/providers/state_home.dart`, `state_today_transactions.dart`, `state_shadow_books.dart` all exist
    - `lib/features/profile/presentation/providers/state_user_profile.dart` exists; `user_profile_providers.dart` final state is `repository_providers.dart` only OR also state_user_profile.dart (no `user_profile_providers.dart` left)
    - All 4 import_guard.yaml files have `package:home_pocket/infrastructure/**` AND `package:home_pocket/data/daos/**` AND `package:home_pocket/data/tables/**` in deny
    - `flutter test test/unit/features/analytics/ test/unit/features/profile/ test/unit/features/home/ test/unit/features/dual_ledger/` exits 0
    - `dart run custom_lint` exits 0
  </acceptance_criteria>
  <done>4 features refactored as 4 atomic commits; renames complete; yamls tightened; tests GREEN. **`/clear` recommended before next task.**</done>
</task>

<task type="auto" tdd="true">
  <name>Task 5: Add architecture test `test/architecture/presentation_layer_rules_test.dart` + delete original (non-prefixed) infrastructure providers from feature/presentation/providers/repository_providers.dart files (final cleanup) + final coverage gate</name>
  <files>test/architecture/presentation_layer_rules_test.dart, lib/features/family_sync/presentation/providers/repository_providers.dart, lib/features/accounting/presentation/providers/repository_providers.dart</files>
  <read_first>
    - test/architecture/domain_import_rules_test.dart (template — Phase 3 D-03 analog)
    - All 7 lib/features/*/presentation/import_guard.yaml files (verify all are tightened with infrastructure/** + data/daos/** + data/tables/** deny)
    - lib/features/family_sync/presentation/providers/repository_providers.dart (verify Tasks 1-4 swapped consumers to `app`-prefixed names — original duplicates are now safe to delete)
    - lib/features/accounting/presentation/providers/repository_providers.dart (same)
    - PATTERNS.md §9 (architecture test template)
  </read_first>
  <behavior>
    - Test 1: For each of 7 features (accounting, analytics, dual_ledger, family_sync, home, profile, settings), `loadYaml('lib/features/<f>/presentation/import_guard.yaml')` returns a YamlMap with `deny` containing `package:home_pocket/infrastructure/**`, `package:home_pocket/data/daos/**`, AND `package:home_pocket/data/tables/**`
    - Test 2: For each of 7 features, the yaml file has `inherit: true`
    - Test 3: Test FAILS if any future PR weakens the deny list (e.g., removes `infrastructure/**` or adds an `allow` exception)
    - Test 4: `dual_ledger` is INCLUDED in the features list (CONTEXT.md note — dual_ledger has presentation/ but no domain/, so it's omitted from domain_import_rules_test.dart but MUST be in presentation_layer_rules_test.dart)
    - Test 5 (cleanup verification): `grep -c "@riverpod" lib/features/family_sync/presentation/providers/repository_providers.dart` returns count consistent with ONLY the feature-specific use-case providers (Push/Pull/Sync use cases) — the 6 sync-client provider definitions duplicated from Plan 04-01 Task 2 have been DELETED
    - Test 6 (cleanup verification): `grep -c "E2EEService e2eeService" lib/features/family_sync/presentation/providers/repository_providers.dart` returns 0 (the duplicate definition is gone; consumers reference `appE2eeServiceProvider` from application/)
  </behavior>
  <action>
    Two parts to this task: (a) cleanup of duplicate providers, (b) architecture test creation.

    **Part A — Cleanup of duplicate infrastructure providers (Warning 7 fix):**

    Per Plan 04-01 Task 2 prefixing decision, the application-layer providers (`appE2eeServiceProvider`, `appRelayApiClientProvider`, etc.) coexist with the original feature-side definitions during Wave 2/3 to avoid breaking consumers mid-refactor. After Tasks 1-4 swap ALL consumers to `app`-prefixed names, the original duplicates in `lib/features/family_sync/presentation/providers/repository_providers.dart` (and any other feature with hoisted providers per Plan 04-01 Task 2) become safe to delete.

    1. Verify zero remaining consumers of original (non-prefixed) names across `lib/`:
       ```bash
       for sym in e2eeServiceProvider relayApiClientProvider apnsPushMessagingClientProvider pushNotificationServiceProvider syncQueueManagerProvider webSocketServiceProvider merchantDatabaseProvider; do
         echo "=== $sym ==="
         grep -rn "ref\\.watch($sym)" lib/features/ test/
         grep -rn "ref\\.read($sym)" lib/features/ test/
       done
       ```
       Each `grep` MUST return 0 matches. If any match remains, return to the offending feature's task and update the consumer to the `app`-prefixed name.

    2. Delete the duplicate provider definitions from `lib/features/family_sync/presentation/providers/repository_providers.dart`:
       - Remove the `@riverpod E2EEService e2eeService(Ref ref) { ... }` definition
       - Remove `@riverpod RelayApiClient relayApiClient(Ref ref) { ... }`
       - Remove `@riverpod ApnsPushMessagingClient apnsPushMessagingClient(Ref ref) { ... }`
       - Remove `@riverpod PushNotificationService pushNotificationService(Ref ref) { ... }`
       - Remove `@riverpod SyncQueueManager syncQueueManager(Ref ref) { ... }`
       - Remove `@riverpod WebSocketService webSocketService(Ref ref) { ... }`
       - Remove `import '../../../../infrastructure/sync/...';` lines (now orphaned)

    3. Delete duplicate `merchantDatabaseProvider` definition from any remaining feature/presentation file (likely Plan-04-02 Task 2 already handled this when folding voice_providers.dart) — verify: `grep -rn "MerchantDatabase merchantDatabase" lib/features/` returns 0.

    4. For `lib/features/accounting/presentation/providers/repository_providers.dart`: similar cleanup — if Plan 04-01 Task 2 hoisted `appDatabaseProvider`/`keyManagerProvider` and Tasks 2-4 swapped consumers to `appAppDatabaseProvider`/`appKeyManagerProvider`, delete the original definitions.

    5. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `.g.dart` files cleanly.
    6. Run `flutter analyze` — must exit 0.
    7. Run `flutter test` — must pass GREEN.

    Commit (separate from architecture test for bisect clarity):
    ```
    refactor(04-02): delete duplicate infrastructure providers from feature/presentation now that consumers use app-prefixed application-layer providers (HIGH-02 cleanup)
    ```

    **Part B — Architecture test:**

    Create `test/architecture/presentation_layer_rules_test.dart` per `<interfaces>` template:

    ```dart
    import 'dart:io';
    import 'package:flutter_test/flutter_test.dart';
    import 'package:yaml/yaml.dart';

    void main() {
      group('Presentation layer import_guard rules', () {
        const features = [
          'accounting',
          'analytics',
          'dual_ledger',  // INCLUDED — has presentation/ even though no domain/
          'family_sync',
          'home',
          'profile',
          'settings',
        ];
        // Phase 4 scope: infrastructure/** + existing data/daos/** + data/tables/**.
        // data/repositories/** intentionally NOT denied here — out of scope per CONTEXT.md
        // <domain> 'In scope' list; scheduled for Phase 5+ MED scope.
        const requiredDeny = [
          'package:home_pocket/infrastructure/**',
          'package:home_pocket/data/daos/**',
          'package:home_pocket/data/tables/**',
        ];

        for (final feature in features) {
          group('feature: $feature', () {
            test('presentation yaml denies infrastructure/** + data/daos/** + data/tables/**', () {
              final path = 'lib/features/$feature/presentation/import_guard.yaml';
              final yaml = loadYaml(File(path).readAsStringSync()) as YamlMap;
              final deny = (yaml['deny'] as YamlList).map((e) => e.toString()).toList();
              expect(deny, containsAll(requiredDeny),
                  reason: 'Feature $feature presentation: deny list weakened (Phase 4 scope: infrastructure + data/daos + data/tables)');
              expect(yaml['inherit'], isTrue,
                  reason: 'Feature $feature presentation: inherit must be true');
            });
          });
        }
      });
    }
    ```

    Run `flutter test test/architecture/presentation_layer_rules_test.dart` — must pass GREEN. If any feature's yaml is missing required entries (a Tasks 1-4 omission), this test fails — fix the yaml in the offending feature's commit, then re-run.

    Then run the FINAL plan-04-02 coverage gate:
    ```bash
    dart run scripts/coverage_gate.dart \
      --files lib/features/accounting/presentation/screens/transaction_confirm_screen.dart,lib/features/accounting/presentation/screens/voice_input_screen.dart,lib/features/accounting/presentation/screens/transaction_entry_screen.dart,lib/features/accounting/presentation/screens/category_selection_screen.dart,lib/features/accounting/presentation/screens/transaction_form_screen.dart,lib/features/accounting/presentation/widgets/transaction_list_tile.dart,lib/features/accounting/presentation/utils/category_display_utils.dart,lib/features/accounting/presentation/providers/repository_providers.dart,lib/features/accounting/presentation/providers/state_category_reorder.dart,lib/features/analytics/presentation/screens/analytics_screen.dart,lib/features/analytics/presentation/providers/repository_providers.dart,lib/features/analytics/presentation/providers/state_analytics.dart,lib/features/dual_ledger/presentation/providers/state_ledger.dart,lib/features/family_sync/presentation/providers/repository_providers.dart,lib/features/family_sync/presentation/providers/state_sync.dart,lib/features/family_sync/presentation/providers/state_active_group.dart,lib/features/family_sync/presentation/providers/state_notification_navigation.dart,lib/features/family_sync/presentation/screens/create_group_screen.dart,lib/features/family_sync/presentation/screens/member_approval_screen.dart,lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart,lib/features/home/presentation/screens/home_screen.dart,lib/features/home/presentation/providers/state_home.dart,lib/features/home/presentation/providers/state_today_transactions.dart,lib/features/home/presentation/providers/state_shadow_books.dart,lib/features/profile/presentation/providers/repository_providers.dart,lib/features/profile/presentation/providers/state_user_profile.dart,lib/features/settings/presentation/providers/repository_providers.dart,lib/features/settings/presentation/providers/state_locale.dart,lib/features/settings/presentation/providers/state_settings.dart,lib/features/settings/presentation/widgets/appearance_section.dart \
      --threshold 80 \
      --lcov coverage/lcov_clean.info
    ```
    MUST exit 0.

    Then commit the architecture test:
    ```
    test(04-02): add presentation_layer_rules architecture test + close HIGH-02/04 (HIGH-02, HIGH-04)
    ```
  </action>
  <verify>
    <automated>flutter test test/architecture/presentation_layer_rules_test.dart 2>&amp;1 | tail -5; grep -rn "ref\\.watch(e2eeServiceProvider)" lib/features/ test/ | wc -l; dart run scripts/coverage_gate.dart --files lib/features/accounting/presentation/providers/repository_providers.dart,lib/features/family_sync/presentation/providers/state_sync.dart --threshold 80 --lcov coverage/lcov_clean.info 2>&amp;1 | tail -5</automated>
  </verify>
  <acceptance_criteria>
    - `test/architecture/presentation_layer_rules_test.dart` exists and contains all 7 features in its features list (including `dual_ledger`)
    - `flutter test test/architecture/presentation_layer_rules_test.dart` exits 0
    - `grep -rn "ref\\.watch(e2eeServiceProvider)" lib/features/ test/` returns 0 matches (consumers use `appE2eeServiceProvider`)
    - `grep -rn "ref\\.watch(relayApiClientProvider)" lib/features/ test/` returns 0 matches
    - `grep -c "E2EEService e2eeService" lib/features/family_sync/presentation/providers/repository_providers.dart` returns 0 (duplicate definition deleted)
    - `flutter analyze` exits 0
    - `dart run custom_lint` exits 0
    - `flutter test` (full suite) exits 0
    - `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
    - `dart run scripts/coverage_gate.dart --files <30 source files comma-separated> --threshold 80 --lcov coverage/lcov_clean.info` exits 0
  </acceptance_criteria>
  <done>Architecture test added and GREEN; duplicate (non-prefixed) infrastructure providers deleted from feature/presentation/; coverage_gate exits 0 on all touched files; HIGH-02 + HIGH-04 (structural) closed; HIGH-01 trivially verified (no open HIGH issues.json entries).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Presentation → Application | Tightened: previously presentation could reach Infrastructure directly; now restricted to Application + Domain only. Tightening reduces attack surface (presentation cannot bypass use-case layer to call sync clients / crypto / DB directly). |
| import_guard yaml deny rules | Hardened from 6-line partial deny to 3-entry blanket (`infrastructure/**` + retained `data/daos/**` + retained `data/tables/**`). Architecture test enforces the rule cannot be weakened in future PRs. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-04-02-01 | T (Tampering) | import_guard yaml | mitigate | `test/architecture/presentation_layer_rules_test.dart` blocks any future PR that weakens the deny list (removes `infrastructure/**` / `data/daos/**` / `data/tables/**` or adds bypass `allow:` entries). Test runs in CI on every PR; failure blocks merge. |
| T-04-02-02 | E (Elevation of privilege) | presentation→infrastructure path | mitigate | Removing 33 direct infrastructure imports from presentation eliminates the vector where a UI bug could be amplified by direct DB / sync-client / crypto access. All such access now routes through Application use cases that validate inputs and handle errors at the boundary. |
| T-04-02-03 | (n/a) | refactor | accept | Pure refactor — no behavior change. The 33 swap operations preserve call signatures (formatter methods, sync-client APIs, crypto operations). Existing tests + Plan 04-06 characterization tests verify behavior preservation. |
</threat_model>

<verification>
- 33 illegal infrastructure imports removed (`grep -rn "import.*infrastructure" lib/features/*/presentation/` returns 0)
- 7 import_guard.yaml files tightened to `infrastructure/**` + `data/daos/**` + `data/tables/**` deny (verified by architecture test)
- 12+ provider files renamed/folded per CONTEXT.md D-06
- 6 HIGH-05 keepAlive annotations preserved (transactionChangeTracker, syncEngine, activeGroup, ledgerView, selectedTabIndex, merchantDatabase via Plan 04-01)
- Duplicate (non-prefixed) infrastructure providers deleted from feature/presentation files (Warning 7 cleanup)
- Architecture test GREEN
- `flutter analyze` exits 0
- `dart run custom_lint` exits 0
- `flutter test` exits 0
- `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code lib/` exits 0
- coverage_gate.dart exits 0 against all 30+ source files in `files_modified`
</verification>

<success_criteria>
- HIGH-02 closed: zero presentation→infrastructure imports
- HIGH-04 (structural) closed: each feature has at most one `repository_providers.dart` + zero or more `state_*.dart`; no `voice_providers.dart`/`group_providers.dart`/etc. files left
- HIGH-01 trivially closed: zero open HIGH `issues.json` entries (none existed; verified)
- 6 HIGH-05 keepAlive annotations preserved
- Plan 04-05 (Wave 4) can now run its global-uniqueness + DI-consolidation + keepAlive-list + no-UnimplementedError tests against the new structure
</success_criteria>

<output>
After completion, create `.planning/phases/04-high-fixes/04-02-SUMMARY.md` documenting:
- The 7 atomic feature commits + 1 cleanup commit + 1 architecture test commit
- Mapping of file moves (table: old path → new path; status: rename | fold | delete)
- Confirmation grep returns 0 infrastructure imports in presentation/
- The `ledgerProvider` vs `ledgerViewProvider` mismatch (flagged for Plan 04-05 reconciliation per CONTEXT.md D-07.4)
- The `activeGroupMembersProvider` vs `groupMembers` mismatch (flagged for Plan 04-05 reconciliation per CONTEXT.md D-07.4)
- Confirmation that `data/repositories/**` access remains permitted in Phase 4 (Phase 5+ MED scope per D-01)
- Final coverage_gate.dart exit-0 evidence
</output>
</content>
</invoke>