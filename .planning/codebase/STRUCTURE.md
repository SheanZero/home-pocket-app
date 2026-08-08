# Codebase Structure

**Analysis Date:** 2026-08-08

## Directory Layout

```text
home-pocket-app/
├── lib/                 # Flutter application source
│   ├── application/     # Cross-feature use cases/services
│   ├── core/            # Bootstrap, router, theme, config, state
│   ├── data/            # Drift database, tables, DAOs, repositories
│   ├── features/        # Feature domain and presentation slices
│   ├── infrastructure/  # Crypto, storage, sync, network, platform adapters
│   ├── l10n/             # ja/zh/en ARB sources
│   ├── generated/        # Generated localization/provider outputs
│   └── shared/           # Reusable widgets, constants, utilities
├── test/                 # Unit, widget, integration, architecture, golden tests
├── integration_test/     # Device-level integration scenarios
├── docs/arch/            # Numbered architecture and ADR documents
└── .planning/            # GSD planning, milestones and codebase maps
```

## Directory Purposes

**`lib/features/`:** Each feature usually contains `domain/models`, `domain/repositories`, and `presentation` screens/widgets/providers. Add feature behavior here, keeping persistence in `lib/data`.

**`lib/application/`:** Shared workflows such as accounting, family sync, security, settings, voice and seeding. Place orchestration spanning multiple features here.

**`lib/data/`:** `app_database.dart`, `tables/`, `daos/`, and `repositories/` form the Drift persistence layer. Add schema changes with migrations and tests.

**`lib/infrastructure/`:** Technical implementations grouped by capability (`crypto`, `security`, `storage`, `sync`, `network`, `speech`, `voice`, `ml`, `i18n`).

**`lib/core/`:** Startup and app-wide concerns: `initialization/`, `config/`, `state/`, `theme/`, and constants.

**`lib/shared/`:** Cross-feature widgets/utilities that do not belong to a single domain.

**`test/`:** Mirrors source concerns across `unit/`, `widget/`, `integration/`, `infrastructure/`, `architecture/`, and `golden/`; shared fixtures/helpers live in `test/fixtures` and `test/helpers`.

## Key File Locations

**Entry Points:** `lib/main.dart`; `lib/core/initialization/app_initializer.dart`; feature screens under `lib/features/*/presentation/screens`.

**Configuration:** `pubspec.yaml`, `analysis_options.yaml`, `lib/core/config`, `lib/l10n/*.arb`, and platform folders `ios/`/`android/`.

**Core Logic:** `lib/application/`; domain contracts in `lib/features/*/domain`; `lib/data/repositories`.

**Testing:** `test/unit`, `test/widget`, `test/integration`, `test/architecture`, `test/golden`, and `integration_test`.

## Naming Conventions

**Files:** snake_case Dart filenames; suffixes communicate role (`*_screen.dart`, `*_widget.dart`, `*_repository.dart`, `*_use_case.dart`, `*_provider.dart`, `*_table.dart`, `*_dao.dart`). Generated siblings use `.g.dart`/`.freezed.dart`.

**Directories:** lowercase snake_case; feature directories are nouns (`accounting`, `family_sync`, `shopping_list`).

**Types and providers:** PascalCase classes; camelCase methods/fields; Riverpod annotations generate lower camelCase provider names.

## Where to Add New Code

**New Feature:** Create `lib/features/{feature}/domain/models`, `domain/repositories`, and `presentation/{screens,widgets,providers}`. Put cross-feature orchestration in `lib/application/{feature}`.

**New Component/Module:** UI implementation belongs in the owning feature’s `presentation/widgets`; technical adapters belong in `lib/infrastructure/{capability}`; persistence belongs in `lib/data/tables`, `daos`, and `repositories`.

**Utilities:** Feature-specific helpers stay beside the feature; broadly reusable helpers go in `lib/shared/utils` and constants in `lib/shared/constants`.

**Tests:** Co-locate by concern under matching `test/unit`, `test/widget`, `test/infrastructure`, or `test/integration` paths; add visual baselines under `test/golden/goldens`.

## Special Directories

**`lib/generated/`:** Generated localization outputs; do not hand-edit. Regenerate via `flutter gen-l10n`.

**`*.g.dart` / `*.freezed.dart`:** Generated Riverpod, Drift and Freezed artifacts; regenerate with build_runner after source changes.

**`.planning/`:** Planning artifacts consumed by GSD; preserve milestone/state consistency.

**`docs/arch/`:** Versioned architecture docs and ADR indexes; add new docs using the next sequential number.

---

*Structure analysis: 2026-08-08*
