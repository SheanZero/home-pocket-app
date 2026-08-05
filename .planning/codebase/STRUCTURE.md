# Codebase Structure

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## Directory Layout

```text
home-pocket-app/
├── lib/main.dart                 # Flutter entry point and boot gates
├── lib/core/                     # initialization, config, constants, theme, state
├── lib/features/                 # thin feature modules: domain + presentation
├── lib/application/              # cross-feature use cases/services
├── lib/data/                     # Drift database, tables, DAOs, repositories
├── lib/infrastructure/           # crypto, sync, storage, ML, speech, i18n, platform
├── lib/shared/                   # reusable widgets, utils and constants
├── lib/l10n/                     # ja/zh/en ARB sources
├── lib/generated/                # generated localization/provider/database outputs
├── test/                         # unit, widget, golden and architecture tests
├── integration_test/             # end-to-end device tests
├── docs/arch/                    # architecture guides and ADRs
├── assets/ android/ ios/         # resources and native platform projects
└── pubspec.yaml                  # dependencies and Flutter metadata
```

## Directory Purposes

**`lib/core/`:** App-wide initialization/configuration (`lib/core/initialization/app_initializer.dart`), theme and constants.

**`lib/features/`:** Feature folders (`accounting`, `analytics`, `applock`, `currency`, `dual_ledger`, `family_sync`, `home`, `list`, `onboarding`, `profile`, `settings`, `shopping_list`, `voice`) with `domain/` and `presentation/`.

**`lib/application/`:** Domain-oriented use cases/services for accounting, analytics, currency, family sync, settings, security, seed, voice and shopping.

**`lib/data/`:** `app_database.dart` (schema 36), Drift `tables/`, `daos/`, and `*_repository_impl.dart` files.

**`lib/infrastructure/`:** Technical adapters grouped by capability: `crypto/`, `sync/`, `security/`, `storage/`, `speech/`, `voice/`, `ml/`, `i18n/`, `exchange_rate/`, `category/`.

**`lib/shared/`:** Cross-feature helpers such as `lib/shared/utils/result.dart`, provider invalidation, constants and reusable widgets.

**`test/`:** `unit/`, `widget/`, `golden/`, `infrastructure/`, `architecture/`; architecture tests enforce layer and privacy contracts.

## Key File Locations

**Entry Points:** `lib/main.dart`; shell at `lib/features/home/presentation/screens/main_shell_screen.dart`.

**Configuration:** `pubspec.yaml`, `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, and `lib/*/import_guard.yaml`.

**Core Logic:** `lib/application/`; database at `lib/data/app_database.dart`.

**Testing:** `test/` and `integration_test/`; import boundaries in `test/architecture/layer_import_rules_test.dart`.

## Naming Conventions

**Files:** Dart files use `snake_case.dart`; use cases end `_use_case.dart`, services `_service.dart`, repository implementations `_repository_impl.dart`, DAOs `_dao.dart`, and tables `_table.dart`.

**Directories:** `snake_case`, organized by feature/domain or technical capability.

**Generated:** `*.g.dart`, `*.freezed.dart`, and `lib/generated/` are generated and must not be hand-edited.

## Where to Add New Code

**New feature UI:** `lib/features/{feature}/presentation/screens/` or `widgets/`; providers in `presentation/providers/`.

**New use case:** `lib/application/{domain}/{name}_use_case.dart` with provider wiring in the owning feature's providers.

**New domain contract:** `lib/features/{feature}/domain/models/` or `domain/repositories/`.

**New persistence:** table in `lib/data/tables/`, DAO in `lib/data/daos/`, implementation in `lib/data/repositories/`; register/migrate in `lib/data/app_database.dart`.

**New technical capability:** `lib/infrastructure/{capability}/`.

**Tests:** mirror production concern under `test/unit/`, `test/widget/`, `test/infrastructure/`, or `test/architecture/`; add device flows under `integration_test/`.

## Special Directories

**`lib/l10n/`:** Source ARB translations for `ja`, `zh`, and `en`; update all locales together.
**`lib/generated/`:** Generated localization and codegen outputs; committed, regenerated via Flutter/build_runner.
**`assets/legal/`, `assets/fonts/`, `assets/ml/`:** Bundled legal documents, fonts and ML resources.
**`build/`, `coverage/`:** Generated artifacts; do not place source code here.

---

*Structure analysis: 2026-08-05*
