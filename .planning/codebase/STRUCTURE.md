# Codebase Structure

**Analysis Date:** 2026-05-21

## Directory Layout

```
home-pocket-app/
├── lib/                        # Flutter application source
│   ├── main.dart               # Entry point, bootstrap, HomePocketApp widget
│   ├── core/                   # App-wide config, theme, initialization
│   │   ├── initialization/     # AppInitializer, InitResult, init_failure_screen
│   │   └── theme/              # AppTheme, AppColors, AppTextStyles, AppThemeColors
│   ├── data/                   # GLOBAL data layer (Drift + SQLCipher)
│   │   ├── app_database.dart   # Drift @DriftDatabase root (schema v17, 11 tables)
│   │   ├── tables/             # ALL table definitions (one file per table)
│   │   ├── daos/               # ALL data access objects
│   │   └── repositories/       # ALL repository implementations (*_repository_impl.dart)
│   ├── infrastructure/         # Platform-capability layer (NEVER in features/)
│   │   ├── category/           # CategoryLocaleService
│   │   ├── crypto/             # Encryption: database/, models/, repositories/, services/
│   │   ├── i18n/               # Formatters: DateFormatter, NumberFormatter, JoyCumulativeFormatter
│   │   ├── ml/                 # MerchantDatabase, TFLite classifier
│   │   ├── security/           # BiometricService, SecureStorageService, AuditLogger
│   │   ├── speech/             # SpeechRecognitionService
│   │   └── sync/               # WebSocket, APNS, relay API, E2EE, sync lifecycle
│   ├── application/            # GLOBAL application layer (Use Cases + Services)
│   │   ├── accounting/         # Transaction CRUD, CategoryService, SeedCategories, EnsureBook
│   │   ├── analytics/          # 12+ analytics use cases + DemoDataService
│   │   ├── dual_ledger/        # ClassificationService, RuleEngine
│   │   ├── family_sync/        # SyncEngine, SyncOrchestrator, all sync use cases
│   │   ├── i18n/               # FormatterService
│   │   ├── ml/                 # LookupMerchantUseCase
│   │   ├── profile/            # GetUserProfileUseCase, SaveUserProfileUseCase
│   │   ├── settings/           # ExportBackup, ImportBackup, ClearAllData
│   │   └── voice/              # ParseVoiceInput, StartSpeechRecognition, VoiceTextParser
│   ├── features/               # Feature modules (Thin Feature — domain + presentation only)
│   │   ├── accounting/
│   │   │   ├── domain/         # models/ (Transaction, Book, Category, ...) + repositories/
│   │   │   └── presentation/   # screens/, widgets/, providers/
│   │   ├── analytics/
│   │   │   ├── domain/         # models/ (HappinessReport, LedgerSnapshot, ...) + repositories/
│   │   │   └── presentation/   # screens/, widgets/, providers/
│   │   ├── dual_ledger/
│   │   │   └── presentation/   # widgets/ (SoulCelebrationOverlay)
│   │   ├── family_sync/
│   │   │   ├── domain/         # models/ (GroupInfo, GroupMember, SyncStatus) + repositories/
│   │   │   └── presentation/   # screens/, widgets/, providers/
│   │   ├── home/
│   │   │   ├── domain/         # (minimal — home has thin domain)
│   │   │   └── presentation/   # screens/ (HomeScreen, MainShellScreen), widgets/, providers/
│   │   ├── profile/
│   │   │   ├── domain/         # models/ (UserProfile) + repositories/
│   │   │   └── presentation/   # screens/, widgets/, providers/
│   │   └── settings/
│   │       ├── domain/         # models/ (AppSettings, BackupData) + repositories/
│   │       └── presentation/   # screens/, widgets/, providers/
│   ├── shared/                 # Cross-feature pure utilities
│   │   ├── constants/          # default_categories.dart, warm_emojis.dart
│   │   └── utils/              # result.dart (Result<T> type)
│   ├── l10n/                   # ARB source files (app_ja.arb, app_zh.arb, app_en.arb)
│   └── generated/              # flutter gen-l10n output — DO NOT EDIT
│       └── app_localizations.dart  # S accessor class + per-locale files
├── test/                       # Mirror of lib/ + architecture + integration tests
│   ├── architecture/           # AST/lint-level structural tests
│   ├── unit/                   # Unit tests (mirrors lib/ structure)
│   ├── widget/                 # Widget tests (mirrors lib/ structure)
│   ├── golden/                 # Golden image tests
│   │   └── goldens/            # PNG reference images
│   ├── integration/            # Integration tests (sync flows)
│   ├── application/            # Legacy integration-level app tests
│   ├── features/               # Legacy feature integration tests
│   ├── infrastructure/         # Infrastructure unit tests
│   ├── data/                   # Data layer unit tests (daos, repos, migrations)
│   ├── scripts/                # Test utility scripts
│   └── helpers/                # Shared test helpers (fixtures, providers, localizations)
├── docs/arch/                  # Architecture documentation
│   ├── 01-core-architecture/   # ARCH-{NNN}_*.md (001..008)
│   ├── 02-module-specs/        # MOD-{NNN}_*.md (001..009)
│   ├── 03-adr/                 # ADR-{NNN}_*.md (001..016, 016 = latest ratified)
│   ├── 04-basic/               # BASIC-003 i18n infra doc
│   ├── 05-UI/                  # UI specs
│   └── README.md               # Arch docs index
├── .planning/                  # GSD project management
│   ├── STATE.md                # Current project state
│   ├── PROJECT.md              # Project overview
│   ├── ROADMAP.md              # High-level roadmap
│   ├── MILESTONES.md           # Milestone index
│   ├── RETROSPECTIVE.md        # Retrospective notes
│   ├── milestones/             # Per-milestone archives
│   │   ├── v1.0-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md
│   │   ├── v1.1-{REQUIREMENTS,ROADMAP}.md
│   │   ├── v1.2-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md
│   │   ├── v1.0-phases/        # Phases 1–8 archived
│   │   ├── v1.1-phases/        # Phases 9–12 archived
│   │   └── v1.2-phases/        # Phases 13–17 (13–17 complete — awaiting /gsd:new-milestone)
│   ├── codebase/               # Codebase analysis docs (this doc set)
│   ├── phases/                 # Active (current milestone) phase plans
│   ├── quick/                  # Quick-task work (quick/260518-* home polish etc.)
│   ├── audit/                  # Audit reports
│   └── research/               # Research notes
├── ios/                        # iOS native project (Podfile with SQLCipher patches)
├── android/                    # Android native project
├── pubspec.yaml                # Flutter dependencies (pinned: intl 0.20.2, file_picker ^11.0.2, etc.)
├── l10n.yaml                   # flutter gen-l10n config → output class S, dir lib/generated
├── analysis_options.yaml       # Dart analyzer + custom_lint (import_guard, riverpod_lint)
└── CLAUDE.md                   # Project-level Claude instructions
```

## Directory Purposes

**`lib/core/`:**
- Purpose: App-wide non-feature infrastructure
- Contains: `initialization/` (AppInitializer, InitResult, InitFailureScreen), `theme/` (AppTheme.light/dark, AppColors, AppTextStyles with tabular figures for amounts, AppThemeColors)
- Key files: `lib/core/initialization/app_initializer.dart`, `lib/core/theme/app_text_styles.dart`

**`lib/data/`:**
- Purpose: Single shared data layer — ALL tables, DAOs, and repository implementations live here regardless of feature ownership
- Contains: `app_database.dart` (Drift `@DriftDatabase`, schema v17, 11 tables), `tables/` (one file per Drift table), `daos/` (typed SQL query objects), `repositories/` (concrete `*_repository_impl.dart` classes)
- Key files: `lib/data/app_database.dart`, `lib/data/repositories/transaction_repository_impl.dart`, `lib/data/repositories/analytics_repository_impl.dart`

**`lib/infrastructure/`:**
- Purpose: Platform/technology capabilities — never accessed directly from features
- Contains: crypto sub-tree (KeyManager, FieldEncryptionService, HashChainService, encrypted DB executor), ml/ (MerchantDatabase 500+ merchants, TFLite), i18n/ (locale-aware formatters), sync/ (WebSocket, APNS, relay API, E2EE), security/ (biometric, secure storage, audit log), speech/ (ASR wrapper), category/ (locale service)
- Key files: `lib/infrastructure/crypto/services/key_manager.dart`, `lib/infrastructure/crypto/services/field_encryption_service.dart`, `lib/infrastructure/i18n/formatters/date_formatter.dart`, `lib/infrastructure/i18n/formatters/number_formatter.dart`, `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart`

**`lib/application/`:**
- Purpose: All business logic Use Cases and orchestrating services, globally scoped
- Key files: `lib/application/analytics/get_happiness_report_use_case.dart`, `lib/application/accounting/create_transaction_use_case.dart`, `lib/application/dual_ledger/classification_service.dart`, `lib/application/family_sync/sync_engine.dart`

**`lib/features/`:**
- Purpose: Thin feature modules — UI + domain contracts only
- Rule: Each feature contains ONLY `domain/` (models + repository interfaces) and `presentation/` (screens/widgets/providers). No Use Cases, no DAOs, no table definitions, no infrastructure.
- Key features: `accounting`, `analytics`, `home`, `settings`, `family_sync`, `profile`, `dual_ledger`

**`lib/shared/`:**
- Purpose: Pure cross-feature utilities with no business logic dependencies
- Contains: `constants/default_categories.dart` (seeded category list), `constants/warm_emojis.dart`, `utils/result.dart` (`Result<T>` sealed class)

**`lib/l10n/`:**
- Purpose: ARB translation source files — always edit these, never `lib/generated/`
- Contains: `app_ja.arb` (Japanese, default), `app_zh.arb` (Chinese), `app_en.arb` (English) — 487 keys each at v1.2 close

**`lib/generated/`:**
- Purpose: Output of `flutter gen-l10n` — DO NOT edit
- Contains: `app_localizations.dart` (`S` class + delegates), `app_localizations_ja.dart`, `app_localizations_zh.dart`, `app_localizations_en.dart`

**`test/architecture/`:**
- Purpose: Structural invariant tests that fail if layer contracts are violated
- Key files: `domain_import_rules_test.dart`, `provider_graph_hygiene_test.dart`, `presentation_layer_rules_test.dart`, `hardcoded_cjk_ui_scan_test.dart`, `arb_key_parity_test.dart`, `production_logging_privacy_test.dart`, `audit_yml_invariants_test.dart`

**`test/helpers/`:**
- Purpose: Shared test utilities
- Key files: `test/helpers/test_provider_scope.dart` (`waitForFirstValue<T>`, `ProviderContainer.test()`), `test/helpers/test_localizations.dart`, `test/helpers/happiness_test_fixtures.dart`

**`test/golden/goldens/`:**
- Purpose: PNG reference images for golden tests
- Naming: `{widget}_{state}_{locale}.png`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: App bootstrap, `HomePocketApp`, `bootWithInitializerForTesting`
- `lib/features/home/presentation/screens/main_shell_screen.dart`: Bottom nav shell

**Configuration:**
- `pubspec.yaml`: All Flutter/Dart dependencies with pins
- `l10n.yaml`: `flutter gen-l10n` configuration
- `analysis_options.yaml`: Analyzer rules + custom_lint plugins
- `lib/data/import_guard.yaml`: Data layer import boundary rules
- `lib/infrastructure/import_guard.yaml`: Infrastructure import boundary rules
- `lib/features/accounting/domain/models/import_guard.yaml`: Domain import boundary rules

**Core Logic:**
- `lib/core/initialization/app_initializer.dart`: 3-stage init (Key → DB → Seed)
- `lib/data/app_database.dart`: Drift database root (schema v17)
- `lib/application/dual_ledger/classification_service.dart`: 3-layer ledger classifier
- `lib/application/family_sync/sync_engine.dart`: P2P sync orchestration
- `lib/infrastructure/crypto/services/key_manager.dart`: Ed25519 key management
- `lib/infrastructure/crypto/database/encrypted_database.dart`: SQLCipher executor factory

**Analytics Use Cases (all at `lib/application/analytics/`):**
- `get_happiness_report_use_case.dart`
- `get_best_joy_moment_use_case.dart`
- `get_budget_progress_use_case.dart`
- `get_expense_trend_use_case.dart`
- `get_family_happiness_use_case.dart`
- `get_largest_monthly_expense_use_case.dart`
- `get_monthly_joy_target_recommendation_use_case.dart`
- `get_monthly_report_use_case.dart`
- `get_per_category_soul_breakdown_across_books_use_case.dart`
- `get_per_category_soul_breakdown_use_case.dart`
- `get_satisfaction_distribution_use_case.dart`
- `get_soul_vs_survival_snapshot_across_books_use_case.dart`
- `get_soul_vs_survival_snapshot_use_case.dart`

**Analytics Providers (all at `lib/features/analytics/presentation/providers/`):**
- `state_time_window.dart` — `selectedTimeWindowProvider` (session-scoped)
- `state_joy_metric_variant.dart` — `selectedJoyMetricVariantProvider` (session-scoped, enum: `all`/`manualOnly`)
- `state_analytics.dart` — `monthlyReportProvider`, `expenseTrendProvider`, `satisfactionDistributionProvider`, `earliestTransactionMonthProvider`
- `state_happiness.dart` — `happinessReportProvider`, `bestJoyMomentProvider`, `monthlyJoyTargetRecommendationProvider`, `largestMonthlyExpenseProvider`, `familyHappinessProvider`
- `state_ledger_snapshot.dart` — `perCategorySoulBreakdownProvider`, `perCategorySoulBreakdownFamilyProvider`, `soulVsSurvivalSnapshotProvider`, `soulVsSurvivalSnapshotFamilyProvider`

**Settings Providers:**
- `lib/features/settings/presentation/providers/state_locale.dart` — `currentLocaleProvider`
- `lib/features/settings/presentation/providers/state_settings.dart` — `appSettingsProvider`

**Testing:**
- `test/helpers/test_provider_scope.dart`: `waitForFirstValue<T>`, `ProviderContainer.test()` helpers

## Naming Conventions

**Files:**
- Dart source: `snake_case.dart` (e.g., `transaction_repository_impl.dart`)
- Tests: mirror source path, suffix `_test.dart` (e.g., `test/unit/application/analytics/get_happiness_report_use_case_test.dart`)
- Generated: `{name}.g.dart` (Riverpod/Drift/json_serializable), `{name}.freezed.dart` (Freezed) — never hand-edit
- Golden images: `test/golden/goldens/{widget}_{state}_{locale}.png`

**Directories:**
- Application use cases: `snake_case` domain name (e.g., `dual_ledger`, `family_sync`)
- Feature directories: `snake_case` feature name (e.g., `home`, `accounting`, `family_sync`)

**Riverpod Providers:**
- State providers: `state_{domain}.dart` (e.g., `state_time_window.dart`, `state_joy_metric_variant.dart`, `state_happiness.dart`, `state_ledger_snapshot.dart`, `state_locale.dart`, `state_settings.dart`, `state_sync.dart`)
- Repository wiring: exactly one `repository_providers.dart` per feature in `lib/features/{f}/presentation/providers/` — also one per application subdomain in `lib/application/{domain}/`
- Provider name generated from class name with `Notifier` suffix stripped: `class SelectedTimeWindow` → `selectedTimeWindowProvider`

**Domain Models:**
- Freezed classes: `PascalCase` with `@freezed` (e.g., `Transaction`, `HappinessReport`, `LedgerSnapshot`)
- Repository interfaces: `I{Entity}Repository` convention (e.g., `ITransactionRepository` in `lib/features/accounting/domain/repositories/transaction_repository.dart`)

**Drift:**
- Table class: `PascalCase` (e.g., `Transactions`, `AuditLogs`)
- Index: `idx_{table}_{columns}` (e.g., `idx_transactions_book_id`)
- Use `TableIndex` with Symbol syntax: `{#bookId}` — NOT `Index()` constructor

**Architecture Docs:**
- Core arch: `docs/arch/01-core-architecture/ARCH-{NNN}_{PascalCase}.md` (next = ARCH-009)
- Module specs: `docs/arch/02-module-specs/MOD-{NNN}_{PascalCase}.md`
- ADRs: `docs/arch/03-adr/ADR-{NNN}_{PascalCase}.md` (latest ratified = ADR-016)

## Where to Add New Code

**New Use Case:**
- Implementation: `lib/application/{domain}/your_new_use_case.dart`
- Provider wiring: add to `lib/application/{domain}/repository_providers.dart`
- Tests: `test/unit/application/{domain}/your_new_use_case_test.dart`

**New Repository:**
- Interface: `lib/features/{f}/domain/repositories/your_repository.dart`
- Implementation: `lib/data/repositories/your_repository_impl.dart`
- Provider: add to `lib/features/{f}/presentation/providers/repository_providers.dart` (one source of truth)
- Tests: `test/unit/data/repositories/your_repository_impl_test.dart`

**New Feature:**
- Domain models: `lib/features/{f}/domain/models/your_model.dart` (add `@freezed`)
- Domain repo interface: `lib/features/{f}/domain/repositories/your_repository.dart`
- Presentation screen: `lib/features/{f}/presentation/screens/your_screen.dart`
- Presentation providers: `lib/features/{f}/presentation/providers/state_{domain}.dart` + `repository_providers.dart`
- Application Use Case: `lib/application/{domain}/your_use_case.dart`
- Tests: mirror all paths under `test/unit/` and `test/widget/`

**New Drift Table:**
- Table: `lib/data/tables/your_table.dart`
- DAO: `lib/data/daos/your_dao.dart`
- Register in: `lib/data/app_database.dart` `@DriftDatabase(tables: [...])` list + bump `schemaVersion`
- Add migration step in `app_database.dart` `MigrationStrategy.onUpgrade`

**New Translation Key:**
- Add to ALL THREE ARBs: `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb`
- Run `flutter gen-l10n` to regenerate `lib/generated/`
- `test/architecture/arb_key_parity_test.dart` enforces key-count parity

**New Screen with Amount Display:**
- Use `AppTextStyles.amountLarge`/`amountMedium`/`amountSmall` from `lib/core/theme/app_text_styles.dart` — never generic `TextStyle` for monetary values (includes `FontFeature.tabularFigures()`)

**New Widget with Nullable BookId:**
- Pattern: `final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;`
- Never hardcode defaults — use nullable parameter + provider fallback

## Special Directories

**`lib/generated/`:**
- Purpose: `flutter gen-l10n` output — `S` accessor class + per-locale implementations
- Generated: Yes
- Committed: Yes (required for CI)

**`.g.dart` and `.freezed.dart` files:**
- Purpose: Riverpod, Drift, json_serializable, Freezed code generation output
- Generated: Yes (run `flutter pub run build_runner build --delete-conflicting-outputs`)
- Committed: Yes (CI checks for staleness via AUDIT-10)

**`.planning/`:**
- Purpose: GSD project management artifacts — state, roadmap, milestones, phase plans
- Generated: No
- Committed: Yes

**`test/golden/goldens/`:**
- Purpose: PNG reference images for golden widget tests
- Generated: Yes (via `flutter test --update-goldens`)
- Committed: Yes

## Phase Numbering Convention

Phases are numbered continuously across milestones:
- Phases 1–8: v1.0 milestone (`/.planning/milestones/v1.0-phases/`)
- Phases 9–12: v1.1 milestone (`/.planning/milestones/v1.1-phases/`)
- Phases 13–17: v1.2 milestone (`/.planning/milestones/v1.2-phases/`) — all complete, awaiting `/gsd:new-milestone`
- Phases 18+: next milestone (not yet opened)

---

*Structure analysis: 2026-05-21*
