# Codebase Structure

**Analysis Date:** 2026-06-23

## Directory Layout

```
home-pocket-app/
├── lib/                      # Application source (Dart/Flutter)
│   ├── main.dart             # App entry point + bootstrap
│   ├── core/                 # config/constants, initialization, theme, router
│   ├── infrastructure/       # Tech/platform capabilities (NEVER in features/)
│   ├── application/          # GLOBAL business logic — use cases + services
│   ├── data/                 # Shared data layer (tables, daos, repo impls)
│   ├── features/             # Feature modules (Thin Feature: domain + presentation)
│   ├── shared/               # Cross-cutting widgets, extensions, utils, constants
│   ├── l10n/                 # ARB source files (ja, zh, en)
│   └── generated/            # Generated localization (S class) — gitignored-yet-tracked
├── test/                     # Unit/widget/golden/architecture/integration tests
├── integration_test/         # On-device integration tests
├── docs/arch/                # ARCH / MOD / ADR architecture docs
├── doc/worklog/              # Dev plan + task worklogs
├── ios/ android/             # Native platform projects
├── assets/                   # Bundled assets
├── scripts/ tool/            # Build/dev scripts
├── .planning/                # GSD planning artifacts (codebase/, phases, state)
├── pubspec.yaml              # Dependencies + version
├── l10n.yaml                 # l10n config (output class S, dir lib/generated)
├── build.yaml                # build_runner config
└── analysis_options.yaml     # Lints + custom_lint (import_guard)
```

## Directory Purposes

**`lib/infrastructure/`:**
- Purpose: Technology/platform capabilities, no business logic.
- Contains: `crypto/` (key_manager, field_encryption, hash_chain), `ml/`, `sync/` (crdt/websocket/relay/push), `security/` (biometric, secure storage, audit), `i18n/` (formatters), `speech/`, `voice/`, `exchange_rate/`, `category/`
- Key files: `crypto/services/key_manager.dart`, `crypto/services/field_encryption_service.dart`, `crypto/database/encrypted_database.dart`

**`lib/application/`:**
- Purpose: Global business logic — Use Cases + cross-feature services.
- Contains: domain subfolders — `accounting/`, `dual_ledger/`, `analytics/`, `ocr` (via voice/ml), `settings/`, `currency/`, `family_sync/`, `shopping_list/`, `list/`, `profile/`, `seed/`, `i18n/`, `voice/`, `ml/`
- Key files: `accounting/create_transaction_use_case.dart`, `dual_ledger/classification_service.dart`, `dual_ledger/rule_engine.dart`

**`lib/data/`:**
- Purpose: All shared data access.
- Contains: `tables/` (15 Drift tables), `daos/`, `repositories/` (15 impls)
- Key files: `app_database.dart` (schema v22), `daos/transaction_dao.dart`, `repositories/transaction_repository_impl.dart`

**`lib/features/<feat>/`:**
- Purpose: Feature module. Thin: ONLY `domain/` + `presentation/`.
- Contains: `domain/{models,repositories}/`, `presentation/{screens,widgets,providers}/`
- Features (11): `accounting`, `analytics`, `currency`, `dual_ledger`, `family_sync`, `home`, `list`, `profile`, `settings`, `shopping_list`
- Key files: `home/presentation/screens/main_shell_screen.dart`, `accounting/presentation/providers/repository_providers.dart`

**`lib/core/`:**
- Purpose: App-wide wiring.
- Contains: `constants/` (feature_flags), `initialization/` (app_initializer, init_result, init_failure_screen), `theme/` (app_palette, app_text_styles, app_theme + palettes)
- Key files: `initialization/app_initializer.dart`, `theme/app_palette.dart`

**`test/`:**
- Purpose: All test types.
- Contains: `unit/`, `widget/`, `golden/`, `architecture/`, `integration/`, `application/`, `infrastructure/`, `data/`, `features/`, `core/`, `helpers/`, `fixtures/`, `scripts/`
- Key files: `architecture/domain_import_rules_test.dart`, `architecture/provider_graph_hygiene_test.dart`, `helpers/test_provider_scope.dart`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: bootstrap, native lib load, provider scope mount
- `lib/features/home/presentation/screens/main_shell_screen.dart`: tab shell + FAB

**Configuration:**
- `pubspec.yaml`: deps (intl pinned 0.20.2, sqlcipher_flutter_libs)
- `l10n.yaml`: localization output config
- `build.yaml`: build_runner config
- `analysis_options.yaml`: lints + custom_lint (import_guard)

**Core Logic:**
- `lib/core/initialization/app_initializer.dart`: startup orchestration
- `lib/data/app_database.dart`: Drift database, schema v22, migrations
- `lib/application/dual_ledger/classification_service.dart`: 3-layer ledger classification

**Testing:**
- `test/architecture/`: enforced layer/convention guardrails
- `test/helpers/test_provider_scope.dart`: `waitForFirstValue`, `ProviderContainer.test()`

## Naming Conventions

**Files:**
- snake_case for all Dart files: `create_transaction_use_case.dart`
- Use cases: `<verb>_<noun>_use_case.dart` (e.g. `get_monthly_report_use_case.dart`)
- Repo interfaces: `<noun>_repository.dart`; impls: `<noun>_repository_impl.dart`
- Drift tables: `<noun>s_table.dart`; DAOs: `<noun>_dao.dart`
- Providers: `repository_providers.dart` (one per feature), `state_<topic>.dart` for state
- Generated: `<file>.g.dart`, `<file>.freezed.dart` (never hand-edited)
- Worklogs: `YYYYMMDD_HHMM_<task>.md`

**Directories:**
- snake_case feature names: `dual_ledger`, `shopping_list`
- Per-directory `import_guard.yaml` for layer boundary enforcement

**Drift indices:**
- `idx_{table}_{columns}` via `TableIndex(name:..., columns: {#col})`

## Where to Add New Code

**New Feature:**
- Domain models/interfaces: `lib/features/<feat>/domain/{models,repositories}/`
- UI + providers: `lib/features/<feat>/presentation/{screens,widgets,providers}/`
- Use cases: `lib/application/<domain>/`
- Tests: `test/features/<feat>/`, `test/application/<domain>/`

**New Data Access (table/DAO/repo impl):**
- Table: `lib/data/tables/<noun>s_table.dart` (register in `app_database.dart`, bump `schemaVersion`, add migration)
- DAO: `lib/data/daos/<noun>_dao.dart`
- Repo impl: `lib/data/repositories/<noun>_repository_impl.dart` (interface goes in feature domain)

**New Technology/Platform Capability:**
- `lib/infrastructure/<area>/` (crypto, ml, sync, security, i18n, ...)

**Shared Utilities:**
- `lib/shared/{widgets,utils,extensions,constants}/`

**Placement decision:** tech/platform → infrastructure; business logic → application; data access → data; domain model/interface → feature domain; UI → feature presentation; unsure → default to `lib/`.

## Special Directories

**`lib/generated/`:**
- Purpose: Generated localization (`S` class) from ARB files.
- Generated: Yes (via `flutter gen-l10n`)
- Committed: Tracked despite being gitignored — must `git add -f`; stale files break analyze.

**`build/`, `.dart_tool/`:**
- Purpose: Build output / tool cache.
- Generated: Yes. Committed: No.

**`.planning/`:**
- Purpose: GSD planning artifacts (this `codebase/` directory, phases, state).
- Committed: Yes (project convention).

---

*Structure analysis: 2026-06-23*
