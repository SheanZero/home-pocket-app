# Codebase Structure

**Analysis Date:** 2026-07-05

## Directory Layout

```
lib/
├── main.dart                 # Bootstrap + root widget (HomePocketApp), 4-gate boot chain
├── core/                     # config/init/theme/state cross-cutting (NOT feature code)
│   ├── config/               # legal_urls.dart
│   ├── constants/            # app_info.dart, feature_flags.dart
│   ├── initialization/       # app_initializer.dart, init_result.dart, init_failure_screen.dart
│   ├── state/                # data_reset_signal.dart (global re-bootstrap signal)
│   └── theme/                # app_palette, app_theme, app_text_styles, ring/joy palettes, text_scale_clamp
├── infrastructure/           # Technology/platform capability (Thin Feature: NEVER in features/)
│   ├── crypto/               # database/ (encrypted executor), models/, repositories/ (key+encryption), services/ (key_manager, field/backup crypto, hash_chain)
│   ├── ml/                   # merchant_name_normalizer.dart
│   ├── category/             # category_locale_service.dart
│   ├── exchange_rate/        # exchange_rate_api_client.dart, exchange_rate_cache_service.dart
│   ├── i18n/                 # formatters/ (date, number, joy_cumulative) + models/ (locale_settings)
│   ├── security/             # biometric_service, secure_storage, audit_logger, pin_kdf, app_lock_lifecycle_observer, providers, models/
│   ├── speech/               # speech_recognition_service.dart
│   ├── voice/                # ja/zh numeral state machines + japanese dictionary
│   └── sync/                 # websocket, relay/apns clients, push, e2ee, queue, scheduler, lifecycle
├── application/              # GLOBAL business logic (Use Cases + services), 12 domains
│   ├── accounting/  analytics/  currency/  family_sync/  i18n/
│   ├── list/  profile/  security/  seed/  settings/  shopping_list/
│   └── voice/                # parse + recognition/ (merchant_recognizer, category_recognizer)
├── data/                     # Shared cross-feature data layer
│   ├── app_database.dart     # @DriftDatabase, schemaVersion 23, migrations
│   ├── tables/               # ALL 15 Drift table definitions
│   ├── daos/                 # ALL 14 DAOs
│   └── repositories/         # ALL 16 repository implementations
├── features/                 # 13 feature modules (Thin Feature: domain/ + presentation/ only)
│   ├── accounting/  analytics/  applock/  currency/  dual_ledger/
│   ├── family_sync/  home/  list/  onboarding/  profile/
│   ├── settings/  shopping_list/  voice/
├── shared/                   # widgets/, utils/, constants/ (default categories/merchants/synonyms)
├── l10n/                     # ARB source (ja default, zh, en)
├── generated/                # generated localizations (app_localizations.dart)
└── import_guard.yaml         # project-wide deny rules (dart:mirrors, sqlite3_flutter_libs)
```

## Directory Purposes

**`lib/features/{feature}/`:**
- `domain/`: ONLY `models/` (Freezed) + `repositories/` (interfaces); occasionally `services/` for pure domain logic (e.g. `voice/domain/services/recognition_reconciler.dart`). No data/app/infra code.
- `presentation/`: `screens/`, `widgets/`, `providers/` (state + repository wiring), sometimes `utils/`.
- Each layer dir carries an `import_guard.yaml` (see caveat under Special Directories — these are declarative and largely inert intra-project; the real check is an arch test).

Features fall into three shapes:
- **domain + presentation:** accounting, analytics, family_sync, home, list, profile, settings, shopping_list.
- **presentation only (no domain):** applock (Phase 55 PIN/biometric lock), dual_ledger (just `joy_celebration_overlay.dart`), onboarding (flow/intro/lock-entry/settings screens).
- **domain only (no presentation):** currency (models `exchange_rate.dart`, `rate_result.dart` + repo interface), voice (models + `recognition_reconciler`). Voice's UI lives in `features/accounting/presentation/`.

**`lib/application/{domain}/`:**
- Use Case classes (`*_use_case.dart`, 61 total) + cross-feature services (`sync_engine.dart`, `app_lock_service.dart`, `voice_text_parser.dart`, …). Domains map loosely to features but live GLOBALLY here.

**`lib/data/`:**
- Single home for all tables, DAOs, and repo impls — cross-feature by design. Also holds cross-cutting impls with no feature domain dir (`device_identity_repository_impl.dart`, `unit_of_work_impl.dart`).

## Key File Locations

**Entry Points:**
- `lib/main.dart`: bootstrap, `HomePocketApp`, 4-gate boot chain (error → loading → onboarding → app-lock → shell), data-reset re-bootstrap.
- `lib/core/initialization/app_initializer.dart`: ordered init + data-loss guard.
- `lib/features/home/presentation/screens/main_shell_screen.dart`: IndexedStack tab shell (Home/List/Analytics/Shopping) + center-FAB `HomeBottomNavBar` (Navigator/MaterialPageRoute, NO go_router). Settings is reached via Home's `onSettingsTap` push, not a tab.

**Configuration:**
- `lib/core/constants/feature_flags.dart`, `lib/core/constants/app_info.dart`, `lib/core/config/legal_urls.dart`
- `lib/data/app_database.dart` (`schemaVersion => 23` — note: root CLAUDE.md's "21"/"v22" are stale)
- `l10n.yaml` (output class `S`, dir `lib/generated`); `analysis_options.yaml` (custom_lint plugin, `prefer_relative_imports`, `avoid_print`)

**Core Logic:**
- Voice recognition: `lib/application/voice/recognition/{merchant,category}_recognizer.dart`, parse in `lib/application/voice/parse_voice_input_use_case.dart`
- Reconciliation: `lib/features/voice/domain/services/recognition_reconciler.dart`
- Voice result model: `lib/features/voice/domain/models/voice_parse_result.dart` (`amountRepairCandidate`, `alternates`)
- Merchant match data: `lib/data/tables/merchants_table.dart`, `merchant_match_keys_table.dart`
- App-lock: `lib/features/applock/presentation/screens/app_lock_screen.dart`, `set_pin_screen.dart`; `lib/infrastructure/security/{pin_kdf,app_lock_lifecycle_observer}.dart`; `lib/application/security/app_lock_service.dart`
- Crypto: `lib/infrastructure/crypto/services/` (key_manager, field_encryption_service, backup_crypto_service, hash_chain_service)

**Testing:**
- `test/architecture/` — `layer_import_rules_test.dart` (real enforcement of layer directions on relative imports), `domain_import_rules_test.dart`, `presentation_layer_rules_test.dart`, `provider_graph_hygiene_test.dart`
- `test/helpers/test_provider_scope.dart` (`waitForFirstValue`, `ProviderContainer.test()`)

## Naming Conventions

**Files:** `snake_case.dart`. Use cases `*_use_case.dart`; repo impls `*_repository_impl.dart`; DAOs `*_dao.dart`; tables `*_table.dart`; Riverpod state `state_*.dart`; mixins `*_mixin.dart`; generated `*.g.dart` / `*.freezed.dart`.

**Drift tables:** Table class PascalCase plural (`Merchants`, `Transactions`); registered in `app_database.dart` `@DriftDatabase(tables: [...])`. Indices `idx_{table}_{columns}` via explicit `CREATE INDEX IF NOT EXISTS` in onCreate + onUpgrade (NOT the decorative `customIndices` getter).

**Riverpod providers:** `@riverpod`-generated; provider name strips the `Notifier` suffix (`LocaleNotifier` → `localeProvider`). Riverpod 3 imports split across `flutter_riverpod.dart` / `legacy.dart` / `misc.dart`.

**Directories:** feature/domain-oriented, not type-oriented.

## Where to Add New Code

**New Feature:**
- Domain interfaces + models: `lib/features/{feature}/domain/{repositories,models}/`
- UI: `lib/features/{feature}/presentation/{screens,widgets,providers}/`
- Use cases: `lib/application/{feature}/`
- Persistence: `lib/data/tables/`, `lib/data/daos/`, `lib/data/repositories/`
- A UI-only feature (like applock/onboarding) may skip `domain/`; a headless feature (like currency/voice) may skip `presentation/`.

**New Database Table:**
- `lib/data/tables/{name}_table.dart`, register in `app_database.dart` `@DriftDatabase`, bump `schemaVersion`, add an `onUpgrade` migration step + explicit `CREATE INDEX IF NOT EXISTS`.

**New Technology Wrapper:** `lib/infrastructure/{capability}/`. Keep it free of `lib/application/**` and feature-presentation imports (enforced by `layer_import_rules_test.dart`).

**Shared widget/util/constant:** `lib/shared/{widgets,utils,constants}/`.

**Placement rule (from CLAUDE.md):** Technology → infrastructure; business logic → application; data access → data; domain model/interface → features/domain; UI → features/presentation; unsure → default to `lib/`.

## Special Directories

**`lib/generated/`:**
- Purpose: generated localizations (`app_localizations.dart`).
- Generated: Yes (`flutter gen-l10n`). Committed: Yes (gitignored-yet-tracked; force-add edits with `git add -f`).

**`import_guard.yaml` files (per layer + root):**
- Declarative deny/inherit rules read by the custom_lint plugin. They match `package:home_pocket/...` URIs verbatim, so with `prefer_relative_imports` on they are **inert for intra-project imports**. They DO still deny real `package:` imports (`dart:mirrors`, `sqlite3_flutter_libs`). Layer-direction enforcement is the arch test `test/architecture/layer_import_rules_test.dart`, whose allowlist is empty.

**`*.g.dart` / `*.freezed.dart`:**
- Generated by build_runner. Never hand-edit. Regenerate after editing `@riverpod`/`@freezed`/Drift tables/ARB and after merge/rebase/pull.

---

*Structure analysis: 2026-07-05*
