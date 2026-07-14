# Codebase Structure

**Analysis Date:** 2026-07-14

## Directory Layout

```
home-pocket-app/
├── lib/                      # Flutter application source (5-layer Clean Architecture)
│   ├── main.dart             # Entry point + boot gate (onboarding/app-lock/shell)
│   ├── core/                 # config/, constants/, initialization/, state/, theme/
│   ├── infrastructure/       # Tech/platform: crypto/, ml/, sync/, security/, i18n/, speech/, voice/, category/, exchange_rate/, platform/
│   ├── application/          # Global business logic (Use Cases + Services), per domain
│   ├── data/                 # app_database.dart + tables/, daos/, repositories/
│   ├── features/             # Feature modules ("Thin Feature": domain/ + presentation/ only)
│   ├── shared/               # widgets/, extensions/, utils/ (cross-feature helpers)
│   ├── l10n/                 # ARB source files (ja, zh, en)
│   └── generated/            # flutter gen-l10n output (S class); tracked-yet-gitignored
├── test/                     # Unit + widget + architecture tests
│   └── architecture/         # Layer/import/invariant guardrail tests
├── integration_test/         # Integration tests
├── docs/arch/                # ARCH / MOD / ADR architecture docs
├── doc/worklog/              # Task worklogs + PROJECT_DEVELOPMENT_PLAN.md
├── android/ · ios/           # Native platform projects
├── assets/                   # Fonts, images, ML models
├── pubspec.yaml              # Dependencies + pins
├── build.yaml · l10n.yaml    # Code-gen + localization config
└── analysis_options.yaml     # Analyzer + lint config
```

## Directory Purposes

**`lib/core/`:**
- Purpose: App-wide wiring not tied to a single feature.
- Contains: `config/` (legal_urls), `constants/` (app_info, feature_flags), `initialization/` (AppInitializer, InitResult), `state/` (data_reset_signal), `theme/` (palettes, text styles, app_theme).
- Key files: `initialization/app_initializer.dart`, `theme/app_palette.dart`.

**`lib/infrastructure/`:**
- Purpose: Technology/platform capability wrappers (bottom layer).
- Contains: `crypto/`, `ml/`, `sync/`, `security/`, `i18n/`, `speech/`, `voice/`, `category/`, `exchange_rate/`, `platform/`.
- Key files: `crypto/database/encrypted_database.dart`, `crypto/services/key_manager.dart`, `i18n/formatters/date_formatter.dart`.

**`lib/application/`:**
- Purpose: Global business logic — Use Cases and services.
- Contains: one subdir per domain (accounting, analytics, currency, family_sync, i18n, list, profile, security, seed, settings, shopping_list, voice).
- Key files: `accounting/create_transaction_use_case.dart`, `accounting/ensure_default_book_use_case.dart`, `seed/` use cases.

**`lib/data/`:**
- Purpose: All persistence.
- Contains: `app_database.dart` (Drift, schemaVersion 23), `tables/` (all table defs), `daos/` (all DAOs), `repositories/` (all `*_impl.dart`).
- Key files: `app_database.dart`, `repositories/transaction_repository_impl.dart`, `repositories/unit_of_work_impl.dart`.

**`lib/features/{feature}/`:**
- Purpose: Feature module. Contains ONLY `domain/` and `presentation/`.
- `domain/`: `models/` + `repositories/` (interfaces only — no impls).
- `presentation/`: `screens/`, `widgets/`, `providers/` (+ optional `utils/`).
- Features: accounting, analytics, applock, currency, dual_ledger, family_sync, home, list, onboarding, profile, settings, shopping_list, voice.

**`lib/shared/`:**
- Purpose: Cross-feature helpers.
- Contains: `widgets/`, `utils/` (result.dart, invalidate_all_data_providers.dart), `constants/`.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: `main()`, `_boot()`, `bootWithInitializerForTesting`, `HomePocketApp` root + boot gates.
- `lib/features/home/presentation/screens/main_shell_screen.dart`: `IndexedStack` tab shell + bottom nav + FAB.

**Configuration:**
- `pubspec.yaml`: dependencies + pins (intl 0.20.2, sqlcipher_flutter_libs ^0.6.x, file_picker/package_info_plus/share_plus trio).
- `build.yaml`, `l10n.yaml`, `analysis_options.yaml`, `custom_lint`/import_guard yamls (`lib/*/import_guard.yaml`).

**Core Logic:**
- Boot: `lib/core/initialization/app_initializer.dart`.
- Database: `lib/data/app_database.dart`.
- Use cases: `lib/application/{domain}/`.

**Testing:**
- `test/` (unit + widget), `test/architecture/` (guardrails), `integration_test/`.
- Layer enforcement: `test/architecture/layer_import_rules_test.dart`.

## Naming Conventions

**Files:**
- Dart source: `snake_case.dart` (e.g. `create_transaction_use_case.dart`).
- Use cases: `*_use_case.dart`. Services: `*_service.dart`. Repo impls: `*_repository_impl.dart`. DAOs: `*_dao.dart`. Tables: `*_table.dart`. Providers: `repository_providers.dart` / `state_*.dart`.
- Generated: `*.g.dart` (riverpod/drift), `*.freezed.dart` (freezed) — never hand-edit.

**Directories:**
- `snake_case`, organized by domain/feature not by type inside features.

**Drift indices:**
- `idx_{table}_{columns}` using `TableIndex(name:, columns: {#col})` symbol syntax.

**Architecture docs (`docs/arch/`):**
- `ARCH-{NNN}_{Name}.md`, `MOD-{NNN}_{Name}.md`, `ADR-{NNN}_{Name}.md` (PascalCase name). Always take next sequential number and update INDEX.md.

## Where to Add New Code

**New Use Case / business logic:**
- Primary code: `lib/application/{domain}/{name}_use_case.dart`.
- Provider wiring: feature's `presentation/providers/repository_providers.dart`.

**New feature UI:**
- Screens: `lib/features/{feature}/presentation/screens/`.
- Widgets: `lib/features/{feature}/presentation/widgets/`.
- Providers: `lib/features/{feature}/presentation/providers/`.

**New domain model / repository interface:**
- `lib/features/{feature}/domain/models/` and `.../domain/repositories/`.

**New persistence:**
- Table: `lib/data/tables/{name}_table.dart` (register in `app_database.dart`, bump `schemaVersion`, add migration + CREATE INDEX).
- DAO: `lib/data/daos/{name}_dao.dart`. Repo impl: `lib/data/repositories/{name}_repository_impl.dart`.

**New technology/platform capability:**
- `lib/infrastructure/{category}/` (e.g. crypto, ml, sync). NEVER inside a feature.

**Shared helper:**
- `lib/shared/utils/` or `lib/shared/widgets/`.

**Placement Decision Rule (from CLAUDE.md):**
1. Technology/platform → `lib/infrastructure/`
2. Business logic / Use Case → `lib/application/{domain}/`
3. Data access (tables, DAOs, repo impl) → `lib/data/`
4. Domain model or repo interface → `lib/features/{feature}/domain/`
5. UI → `lib/features/{feature}/presentation/`
6. Unsure → default to `lib/` (easier to refactor).

## Special Directories

**`lib/generated/`:**
- Purpose: `flutter gen-l10n` output (`S` localization class).
- Generated: Yes. Committed: Yes (tracked-yet-gitignored — use `git add -f` when adding S keys).

**`*.g.dart` / `*.freezed.dart`:**
- Purpose: Riverpod/Drift/Freezed codegen output.
- Generated: Yes (run `flutter pub run build_runner build --delete-conflicting-outputs`). Committed: Yes. Never hand-edit (AUDIT-10 CI catches stale files).

**`lib/l10n/`:**
- Purpose: ARB translation sources (ja default, zh, en). Update all 3 then `flutter gen-l10n`.

**`build/`, `coverage/`:**
- Generated build + coverage output. Not source.

---

*Structure analysis: 2026-07-14*
