# Codebase Structure

**Analysis Date:** 2026-06-23

## Directory Layout

```
lib/
├── main.dart                  # App entry: native bootstrap, init, MaterialApp
├── core/                      # config, init, theme (project-wide app shell)
│   ├── constants/
│   ├── initialization/        # app_initializer.dart, init_result.dart, init_failure_screen.dart
│   └── theme/                 # app_palette.dart, app_theme.dart, app_text_styles.dart, *_palette.dart
├── infrastructure/            # Technology/platform capability (NEVER in features/)
│   ├── crypto/                # database/, models/, repositories/, services/ (key_manager, field_encryption, hash_chain)
│   ├── ml/                    # ML/OCR (tflite, merchant classifier)
│   ├── i18n/                  # formatters/ (date_formatter, number_formatter), models/
│   ├── sync/                  # CRDT, bluetooth, nfc, wifi sync tech
│   ├── security/              # biometric, secure_storage, audit_logger, models/
│   ├── speech/  voice/        # speech recognition + voice parsing
│   ├── category/  exchange_rate/
│   └── import_guard.yaml      # layer-dependency lint config
├── application/               # GLOBAL business logic (Use Cases + Services)
│   ├── accounting/            # create/delete/get transaction use cases, category services
│   ├── analytics/  currency/  dual_ledger/  family_sync/  i18n/  list/
│   ├── ml/  profile/  seed/  settings/  shopping_list/  voice/
├── data/                      # Shared CROSS-FEATURE data layer
│   ├── app_database.dart      # Drift DB, schemaVersion => 22
│   ├── tables/                # ALL Drift table definitions (15 tables)
│   ├── daos/                  # ALL data access objects
│   └── repositories/          # ALL repository implementations
├── features/                  # Feature modules ("Thin Feature" — domain/ + presentation/ only)
│   └── {feature}/
│       ├── domain/            # models/ (Freezed) + repositories/ (interfaces)
│       └── presentation/      # screens/, widgets/, providers/, utils/
├── shared/                    # Cross-cutting reusable code
│   ├── widgets/  utils/  constants/
├── l10n/                      # ARB source files (ja, zh, en)
└── generated/                 # Generated localizations (app_localizations.dart, class S)
```

## Directory Purposes

**`lib/core/`:**
- Purpose: App-wide shell — initialization sequencing, theme, constants.
- Key files: `initialization/app_initializer.dart`, `theme/app_palette.dart`, `theme/app_theme.dart`.

**`lib/infrastructure/`:**
- Purpose: Technology/platform capability. Never holds business logic.
- Contains: crypto, ml, sync, i18n, security, speech, voice, category, exchange_rate.

**`lib/application/`:**
- Purpose: GLOBAL use cases and services, organized by domain (one subdir per domain).
- Contains: `*_use_case.dart`, `*_service.dart`, plus `repository_providers.dart` per domain.

**`lib/data/`:**
- Purpose: Cross-feature persistence (Drift + SQLCipher).
- Key files: `app_database.dart` (schema v22), `tables/`, `daos/`, `repositories/`.

**`lib/features/{f}/`:**
- Purpose: Feature module. domain/ (models + repo interfaces), presentation/ (UI + providers).
- Features: accounting, analytics, currency, dual_ledger, family_sync, home, list, profile, settings, shopping_list.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App bootstrap and MaterialApp.
- `lib/features/home/presentation/screens/main_shell_screen.dart`: Tab shell + FAB.

**Configuration:**
- `pubspec.yaml`: deps (with pinned versions — see CLAUDE.md).
- `l10n.yaml`: output class `S`, dir `lib/generated`.
- `lib/infrastructure/import_guard.yaml` (+ per-layer `import_guard.yaml`): layer lint.

**Core Logic:**
- `lib/application/{domain}/*_use_case.dart`: business operations.
- `lib/data/app_database.dart`: DB schema + migrations.

**Testing:**
- `test/` (mirrors `lib/`); helpers in `test/helpers/` (e.g. `test_provider_scope.dart`).

## Naming Conventions

**Files:**
- snake_case: `create_transaction_use_case.dart`, `transaction_repository_impl.dart`.
- Generated: `*.g.dart` (codegen), `*.freezed.dart` (Freezed) — never hand-edit.
- Use cases end `_use_case.dart`; repo impls end `_repository_impl.dart`; DAOs end `_dao.dart`; tables end `_table.dart`.
- Riverpod provider files prefixed `state_` (e.g. `state_home.dart`) or `repository_providers.dart`.

**Directories:**
- snake_case, organized by domain/feature, then by layer concern (`domain/models`, `presentation/screens`).

**Drift indices:** `idx_{table}_{columns}`, `TableIndex` with `{#columnName}` Symbol syntax.

## Where to Add New Code

**New Feature:**
- Domain models/interfaces: `lib/features/{feature}/domain/`
- UI + providers: `lib/features/{feature}/presentation/`
- Use cases: `lib/application/{domain}/`
- Tables/DAOs/repo impls: `lib/data/` (NEVER inside features/)

**New Table:**
- Definition: `lib/data/tables/{name}_table.dart`
- DAO: `lib/data/daos/{name}_dao.dart`
- Register in `lib/data/app_database.dart`, bump `schemaVersion`, add migration + explicit `CREATE INDEX` in onCreate AND onUpgrade.

**New Technology/Platform capability:**
- `lib/infrastructure/{domain}/`

**Shared helper/widget:**
- `lib/shared/utils/` or `lib/shared/widgets/`

**New translation:**
- Update ALL 3 ARB files in `lib/l10n/`, then `flutter gen-l10n`. Access via `S.of(context)`.

## Special Directories

**`lib/generated/`:**
- Purpose: Generated l10n (`app_localizations.dart`, class `S`).
- Generated: Yes (`flutter gen-l10n`). Committed: Yes (gitignored-yet-tracked — use `git add -f`).

**`*.g.dart` / `*.freezed.dart`:**
- Purpose: Riverpod / Drift / Freezed codegen output.
- Generated: Yes (`build_runner`). Committed: Yes. Never hand-edit (AUDIT-10 catches stale files).

---

*Structure analysis: 2026-06-23*
