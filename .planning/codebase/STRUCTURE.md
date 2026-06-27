# Codebase Structure

**Analysis Date:** 2026-06-27

## Directory Layout

```
lib/
├── main.dart                 # Bootstrap + root widget (HomePocketApp)
├── core/                     # config/init/theme cross-cutting (NOT feature code)
│   ├── constants/            # feature_flags.dart
│   ├── initialization/       # app_initializer.dart, init_result.dart, init_failure_screen.dart
│   └── theme/                # app_palette, app_theme, app_text_styles, ring/joy palettes
├── infrastructure/           # Technology/platform capability (Thin Feature: NEVER in features/)
│   ├── crypto/               # key_manager, field_encryption, hash_chain, encrypted DB executor
│   ├── ml/                   # merchant_name_normalizer.dart
│   ├── category/             # category_locale_service.dart
│   ├── exchange_rate/        # FX rate fetching
│   ├── i18n/                 # date_formatter, number_formatter, locale settings
│   ├── security/             # biometric_service, secure_storage, audit_logger
│   ├── speech/               # speech_recognition_service.dart
│   ├── voice/                # ja/zh/en numeral state machines + dictionaries
│   └── sync/                 # crdt, bluetooth, nfc, wifi P2P
├── application/              # GLOBAL business logic (Use Cases + services), per domain
│   ├── accounting/  analytics/  currency/  family_sync/  i18n/
│   ├── list/  profile/  seed/  settings/  shopping_list/
│   └── voice/                # parse + recognition/ (merchant_recognizer, category_recognizer)
├── data/                     # Shared cross-feature data layer
│   ├── app_database.dart     # @DriftDatabase, schemaVersion 22, migrations
│   ├── tables/               # ALL 15 Drift table definitions
│   ├── daos/                 # ALL 14 DAOs
│   └── repositories/         # ALL 15 repository implementations
├── features/                 # Feature modules (Thin Feature: domain/ + presentation/ only)
│   ├── accounting/  analytics/  currency/  dual_ledger/  family_sync/
│   ├── home/  list/  profile/  settings/  shopping_list/  voice/
├── shared/                   # widgets/, extensions/, utils/, constants/
├── l10n/                     # ARB source (ja default, zh, en)
├── generated/                # generated localizations (app_localizations.dart)
└── import_guard.yaml         # project-wide deny rules (dart:mirrors, sqlite3_flutter_libs)
```

## Directory Purposes

**`lib/features/{feature}/`:**
- `domain/`: ONLY `models/` (Freezed) and `repositories/` (interfaces). No data/app/infra code.
- `presentation/`: `screens/`, `widgets/`, `providers/` (state + repository wiring).
- Each layer dir carries an `import_guard.yaml` enforcing dependency direction.

**`lib/application/{domain}/`:**
- Use Case classes (`*_use_case.dart`) + cross-feature services. 61 use cases total.
- Domains map loosely to features but live GLOBALLY here (not nested in features).

**`lib/data/`:**
- Single home for all tables, DAOs, repo impls — cross-feature by design.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: bootstrap, `HomePocketApp`, shell/onboarding routing.
- `lib/core/initialization/app_initializer.dart`: ordered init + data-loss guard.
- `lib/features/home/presentation/screens/main_shell_screen.dart`: IndexedStack tab shell + FAB (Navigator/MaterialPageRoute, NO go_router).

**Configuration:**
- `lib/core/constants/feature_flags.dart`
- `lib/data/app_database.dart` (`schemaVersion => 22`)
- `l10n.yaml` (output class `S`, dir `lib/generated`)

**Core Logic:**
- Voice recognition: `lib/application/voice/recognition/{merchant,category}_recognizer.dart`
- Reconciliation: `lib/features/voice/domain/services/recognition_reconciler.dart`
- Merchant match data: `lib/data/tables/merchants_table.dart`, `merchant_match_keys_table.dart` (schema v22, Phase 49)

**Testing:**
- `test/` (arch tests, golden tests, helpers like `test/helpers/test_provider_scope.dart`)

## Naming Conventions

**Files:** `snake_case.dart`. Use cases `*_use_case.dart`; repo impls `*_repository_impl.dart`; DAOs `*_dao.dart`; tables `*_table.dart`; Riverpod state `state_*.dart`; generated `*.g.dart` / `*.freezed.dart`.

**Drift tables:** Table class PascalCase plural (`Merchants`, `Transactions`); indices `idx_{table}_{columns}` via `TableIndex(name:..., columns:{#col})`.

**Riverpod providers:** `@riverpod`-generated; provider name strips `Notifier` suffix (`LocaleNotifier` → `localeProvider`).

**Directories:** feature/domain-oriented, not type-oriented.

## Where to Add New Code

**New Feature:**
- Domain interfaces + models: `lib/features/{feature}/domain/`
- UI: `lib/features/{feature}/presentation/{screens,widgets,providers}/`
- Use cases: `lib/application/{feature}/`
- Persistence: `lib/data/tables/`, `lib/data/daos/`, `lib/data/repositories/`

**New Database Table:**
- `lib/data/tables/{name}_table.dart`, register in `app_database.dart` `@DriftDatabase`, bump `schemaVersion`, add `onUpgrade` migration + explicit `CREATE INDEX`.

**New Technology Wrapper:** `lib/infrastructure/{capability}/`.

**Shared widget/util:** `lib/shared/{widgets,utils,extensions}/`.

**Placement rule (from CLAUDE.md):** Technology → infrastructure; business logic → application; data access → data; domain model/interface → features/domain; UI → features/presentation; unsure → default to `lib/`.

## Special Directories

**`lib/generated/`:**
- Purpose: generated localizations (`app_localizations.dart`).
- Generated: Yes (`flutter gen-l10n`). Committed: Yes (gitignored-yet-tracked; force-add edits with `git add -f`).

**`*.g.dart` / `*.freezed.dart`:**
- Generated by build_runner. Never hand-edit. Regenerate after editing `@riverpod`/`@freezed`/Drift tables/ARB and after merge/rebase/pull.

---

*Structure analysis: 2026-06-27*
