# Codebase Structure

**Analysis Date:** 2026-06-23

## Directory Layout

```
home-pocket-app/
├── lib/
│   ├── main.dart            # App entry point + root widget
│   ├── core/               # config/, constants/, initialization/, theme/
│   ├── application/        # GLOBAL business logic (use cases + services)
│   ├── data/              # app_database.dart, tables/, daos/, repositories/
│   ├── features/          # Thin feature modules (domain/ + presentation/)
│   ├── infrastructure/    # crypto/, ml/, sync/, security/, i18n/, speech/, voice/
│   ├── shared/            # widgets/, utils/, constants/, extensions/
│   ├── l10n/              # ARB source files
│   ├── generated/         # Generated localizations (S class)
│   └── import_guard.yaml  # Layer-import deny rules
├── test/                  # Mirrors lib/ + helpers/, arch tests
├── docs/arch/             # ARCH/MOD/ADR architecture docs
├── doc/worklog/           # Task worklogs + PROJECT_DEVELOPMENT_PLAN.md
├── android/ · ios/        # Native platform projects
├── assets/                # Bundled assets (ML models, etc.)
├── pubspec.yaml           # Dependencies + version
├── l10n.yaml              # gen-l10n config (output class S)
└── build.yaml             # build_runner config
```

## Directory Purposes

**lib/core/:**
- Purpose: app-wide non-feature wiring
- Contains: `initialization/` (AppInitializer, InitResult), `theme/` (AppPalette, AppTheme, text styles), `constants/`
- Key files: `core/initialization/app_initializer.dart`, `core/theme/app_palette.dart`

**lib/application/:**
- Purpose: GLOBAL business logic, organized by domain
- Contains: `accounting/`, `dual_ledger/`, `analytics/`, `ocr` (under ml/), `settings/`, `family_sync/`, `voice/`, `currency/`, `shopping_list/`, `seed/`, `i18n/`, `list/`, `profile/`
- Key files: `application/accounting/create_transaction_use_case.dart`, `application/dual_ledger/classification_service.dart`

**lib/data/:**
- Purpose: shared cross-feature persistence
- Contains: `app_database.dart`, `tables/` (all Drift tables), `daos/` (all DAOs), `repositories/` (all `*_impl.dart`)
- Key files: `data/app_database.dart` (schema v21)

**lib/features/{feature}/:**
- Purpose: feature modules (Thin Feature pattern)
- Contains: ONLY `domain/{models,repositories}` and `presentation/{screens,widgets,providers}`
- Features: accounting, analytics, currency, dual_ledger, family_sync, home, list, profile, settings, shopping_list

**lib/infrastructure/:**
- Purpose: technology/platform capabilities
- Contains: `crypto/`, `ml/`, `sync/`, `security/`, `i18n/`, `speech/`, `voice/`, `category/`, `exchange_rate/`
- Key files: `infrastructure/crypto/database/encrypted_database.dart`, `infrastructure/crypto/services/hash_chain_service.dart`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: bootstrap, root `HomePocketApp`, routing to shell/onboarding
- `lib/features/home/presentation/screens/main_shell_screen.dart`: tab shell host

**Configuration:**
- `pubspec.yaml`: dependencies (pinned trio, sqlcipher libs)
- `l10n.yaml`: localization output (`S`, `lib/generated`)
- `build.yaml`: build_runner settings
- `lib/import_guard.yaml`: layer + denied-package rules

**Core Logic:**
- `lib/application/`: all use cases and services
- `lib/data/repositories/`: repository implementations

**Testing:**
- `test/`: mirrors `lib/` tree
- `test/helpers/test_provider_scope.dart`: Riverpod 3 test helpers

## Naming Conventions

**Files:**
- snake_case Dart files: `create_transaction_use_case.dart`
- Use cases: `*_use_case.dart`; services: `*_service.dart`
- Repository interfaces: `*_repository.dart`; impls: `*_repository_impl.dart`
- DAOs: `*_dao.dart`; tables: `*_table.dart` (plural table class, e.g. `Transactions`)
- Generated siblings: `*.g.dart`, `*.freezed.dart` (never hand-edit)
- Riverpod provider files: often `state_*.dart` and `repository_providers.dart`

**Directories:**
- Feature dirs: snake_case domain noun (`shopping_list/`, `dual_ledger/`)
- Drift index naming: `idx_{table}_{columns}`

## Where to Add New Code

**New Feature:**
- Domain models + repo interfaces: `lib/features/{feature}/domain/`
- UI + providers: `lib/features/{feature}/presentation/`
- Business logic: `lib/application/{feature}/` (NOT inside the feature)
- Tests: `test/features/{feature}/` and `test/application/{feature}/`

**New Persistence:**
- Table: `lib/data/tables/{name}_table.dart` → register in `app_database.dart`, bump `schemaVersion`, add migration + explicit `CREATE INDEX`
- DAO: `lib/data/daos/{name}_dao.dart`
- Repository impl: `lib/data/repositories/{name}_repository_impl.dart`

**New Technology/Platform capability:**
- `lib/infrastructure/{capability}/` (all crypto MUST live under `lib/infrastructure/crypto/`)

**Utilities:**
- Shared helpers: `lib/shared/utils/` (e.g. `result.dart`, `currency_conversion.dart`)
- Shared widgets: `lib/shared/widgets/`

**When unsure:**
- Default to `lib/` root level (safer, easier to refactor) — per project placement rule

## Special Directories

**lib/generated/:**
- Purpose: generated localizations (`S` class)
- Generated: Yes (via `flutter gen-l10n`)
- Committed: Yes — but gitignored-yet-tracked; use `git add -f` when adding S keys

**build/, coverage/, .dart_tool/:**
- Purpose: build artifacts and coverage output
- Generated: Yes
- Committed: No

**docs/arch/:**
- Purpose: ARCH/MOD/ADR architecture records (sequential numbering, append-only ADRs)
- Committed: Yes

---

*Structure analysis: 2026-06-23*
