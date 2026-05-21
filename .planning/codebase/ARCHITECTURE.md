<!-- refreshed: 2026-05-21 -->
# Architecture

**Analysis Date:** 2026-05-21

## System Overview

```text
┌────────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                         │
│  lib/features/{f}/presentation/  (screens, widgets, providers)     │
│                                                                    │
│  home │ accounting │ analytics │ settings │ family_sync │ profile  │
│  dual_ledger                                                       │
└──────────┬─────────────────────────────────────────────────────────┘
           │ ref.watch / ref.read (Riverpod)
           ▼
┌────────────────────────────────────────────────────────────────────┐
│                        Application Layer                           │
│  lib/application/{domain}/  (Use Cases + Services)                │
│                                                                    │
│  accounting │ analytics │ dual_ledger │ family_sync │ i18n         │
│  ml │ profile │ settings │ voice                                   │
└──────────┬─────────────────────────────────────────────────────────┘
           │ depends on domain interfaces
           ▼
┌────────────────────────────────────────────────────────────────────┐
│                          Domain Layer                              │
│  lib/features/{f}/domain/  (models/ + repositories/ interfaces)   │
│                                                                    │
│  accounting/domain │ analytics/domain │ family_sync/domain         │
│  settings/domain │ profile/domain                                  │
└──────────┬─────────────────────────────────────────────────────────┘
           ▲ (Data implements domain interfaces)
┌──────────┴─────────────────────────────────────────────────────────┐
│                           Data Layer                               │
│  lib/data/  (app_database.dart, tables/, daos/, repositories/)     │
│                                                                    │
│  Drift + SQLCipher — schema v17 — 11 tables                        │
└──────────┬─────────────────────────────────────────────────────────┘
           ▲ (Infrastructure implements/drives Data)
┌──────────┴─────────────────────────────────────────────────────────┐
│                      Infrastructure Layer                          │
│  lib/infrastructure/  (platform capabilities)                      │
│                                                                    │
│  crypto/ │ ml/ │ i18n/ │ sync/ │ security/ │ speech/ │ category/  │
└────────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | Primary Files |
|-----------|----------------|---------------|
| `lib/main.dart` | Bootstrap, `HomePocketApp` widget, locale wiring | `lib/main.dart` |
| `AppInitializer` | 3-stage init (KeyManager → Database → Seed) | `lib/core/initialization/app_initializer.dart` |
| `AppDatabase` | Drift database root, schema v17, migration ladder | `lib/data/app_database.dart` |
| `lib/core/theme/` | Material theme, `AppTextStyles`, `AppColors` | `lib/core/theme/app_theme.dart`, `app_text_styles.dart` |
| `lib/data/tables/` | All 11 Drift table definitions | `lib/data/tables/` |
| `lib/data/daos/` | All Drift DAOs (typed SQL queries) | `lib/data/daos/` |
| `lib/data/repositories/` | All repository implementations (cross-feature) | `lib/data/repositories/` |
| `lib/application/analytics/` | 12+ analytics use cases + Demo data service | `lib/application/analytics/` |
| `lib/application/accounting/` | Transaction CRUD, category seed, book init | `lib/application/accounting/` |
| `lib/application/dual_ledger/` | 3-layer classifier (Rule Engine → Merchant DB → ML) | `lib/application/dual_ledger/classification_service.dart`, `rule_engine.dart` |
| `lib/application/family_sync/` | Sync use cases, `SyncEngine`, `SyncOrchestrator` | `lib/application/family_sync/sync_engine.dart` |
| `lib/infrastructure/crypto/` | Encryption primitives — KeyManager, FieldEncryption, HashChain | `lib/infrastructure/crypto/services/` |
| `lib/infrastructure/sync/` | WebSocket, APNS, relay API client, E2EE | `lib/infrastructure/sync/` |
| `lib/infrastructure/i18n/` | DateFormatter, NumberFormatter, JoyCumulativeFormatter | `lib/infrastructure/i18n/formatters/` |
| `lib/infrastructure/security/` | BiometricService, SecureStorageService, AuditLogger | `lib/infrastructure/security/` |
| `lib/features/{f}/presentation/` | Screens, widgets, Riverpod providers (wiring only) | `lib/features/*/presentation/` |
| `lib/features/{f}/domain/` | Domain models (Freezed) + repository interfaces | `lib/features/*/domain/` |
| `lib/shared/` | Cross-feature utilities (Result type, constants, utils) | `lib/shared/` |
| `lib/generated/` | ARB-generated `S` localizations class (do not edit) | `lib/generated/app_localizations.dart` |

## Pattern Overview

**Overall:** 5-Layer Clean Architecture ("Thin Feature" variant)

**Key Characteristics:**
- Features are deliberately thin: `lib/features/{f}/` contains ONLY `domain/` (models + repo interfaces) and `presentation/` (screens/widgets/providers). No Use Cases, DAOs, or infrastructure code inside features.
- The Application layer is global at `lib/application/{domain}/`, not nested inside features.
- The Data layer is global at `lib/data/` — all table definitions, DAOs, and repository implementations live there regardless of which feature owns the domain interface.
- Dependency direction: Presentation → Application → Domain ← Data ← Infrastructure. Domain has zero outward dependencies.
- State management is Riverpod with `@riverpod` codegen; generated `.g.dart` files must never be hand-edited.

## Layers

**Infrastructure Layer:**
- Purpose: Raw platform/technology capabilities
- Location: `lib/infrastructure/`
- Contains: `crypto/` (KeyManager, FieldEncryptionService, HashChainService, encrypted DB executor), `ml/` (MerchantDatabase, TFLite classifier), `i18n/` (DateFormatter, NumberFormatter, JoyCumulativeFormatter), `sync/` (WebSocketService, APNSClient, RelayApiClient, E2EEService), `security/` (BiometricService, SecureStorageService, AuditLogger), `speech/` (SpeechRecognitionService), `category/` (CategoryLocaleService)
- Depends on: External packages only
- Used by: Application layer, Data layer (encrypted executor)

**Data Layer:**
- Purpose: All persistence — Drift schema, DAOs, and repository implementations
- Location: `lib/data/`
- Contains: `app_database.dart` (Drift root, schema v17, 11 tables), `tables/` (AuditLogs, Books, Categories, CategoryKeywordPreferences, CategoryLedgerConfigs, GroupMembers, Groups, MerchantCategoryPreferences, SyncQueue, Transactions, UserProfiles), `daos/` (typed query objects), `repositories/` (all `*_repository_impl.dart` files)
- Depends on: Infrastructure (crypto executor), Domain interfaces
- Used by: Application layer via injected repository interfaces

**Domain Layer:**
- Purpose: Core business entities and repository contracts — intentionally isolated
- Location: `lib/features/{f}/domain/`
- Contains: `models/` (Freezed data classes) and `repositories/` (abstract interface classes)
- Depends on: **Nothing** (no imports from Application, Data, or Infrastructure)
- Used by: Application layer (implements interfaces), Presentation layer (reads models)

**Application Layer:**
- Purpose: Use Cases and orchestrating services
- Location: `lib/application/{domain}/`
- Contains per subdomain: Use Case classes (each a plain Dart class with an `execute()` method) + `repository_providers.dart` (Riverpod providers wiring repositories to use cases)
- Subdomains: `accounting/`, `analytics/`, `dual_ledger/`, `family_sync/`, `i18n/`, `ml/`, `profile/`, `settings/`, `voice/`
- Depends on: Domain interfaces, Infrastructure services
- Used by: Presentation layer providers

**Presentation Layer:**
- Purpose: Flutter UI + Riverpod provider wiring
- Location: `lib/features/{f}/presentation/`
- Contains: `screens/`, `widgets/`, `providers/` (Riverpod state files named `state_{domain}.dart` + one `repository_providers.dart` per feature)
- Depends on: Application layer (via `ref.watch`), Domain models
- Used by: Nothing (leaf layer)

## Data Flow

### Primary Request Path (Transaction Entry)

1. User taps "Add Transaction" → `TransactionEntryScreen` (`lib/features/accounting/presentation/screens/transaction_entry_screen.dart`)
2. Screen calls `ref.read(createTransactionUseCaseProvider).execute(...)` — provider defined in `lib/features/accounting/presentation/providers/repository_providers.dart`
3. `CreateTransactionUseCase` (`lib/application/accounting/create_transaction_use_case.dart`) delegates to `ITransactionRepository` + runs `ClassificationService` (`lib/application/dual_ledger/classification_service.dart`) for ledger assignment
4. `ClassificationService` passes through Rule Engine → Merchant Database → ML Classifier (3-layer cascade)
5. `TransactionRepositoryImpl` (`lib/data/repositories/transaction_repository_impl.dart`) writes via `TransactionDao` (`lib/data/daos/transaction_dao.dart`) to Drift/SQLCipher
6. `SyncEngine` (`lib/application/family_sync/sync_engine.dart`) queues the change via `TransactionChangeTracker`

### App Initialization Flow

1. `main()` → `WidgetsFlutterBinding.ensureInitialized()` → `ensureNativeLibrary()` (`lib/main.dart`)
2. `AppInitializer.initialize()` (`lib/core/initialization/app_initializer.dart`):
   - **Stage 1:** `MasterKeyRepository.hasMasterKey()` / `initializeMasterKey()` → `KeyManager.generateDeviceKeyPair()` — returns `InitFailure(masterKey)` on error
   - **Stage 2:** `createEncryptedExecutor(masterKeyRepo)` → `AppDatabase(executor)` — returns `InitFailure(database)` on error
   - **Stage 3:** Final `ProviderContainer` with `appDatabaseProvider` override → seed runner
3. `bootWithInitializerForTesting()` wraps result in `UncontrolledProviderScope` or renders `InitFailureApp`
4. `HomePocketApp._initialize()`: seeds categories, ensures default book, initializes `SyncEngine`, wires push notifications, checks profile onboarding

### Analytics Request Path

1. `AnalyticsScreen` reads `selectedTimeWindowProvider` + `selectedJoyMetricVariantProvider` (session-scoped, no persistence)
2. Passes `(startDate, endDate, joyMetricVariant)` as named parameters to each analytics provider (e.g., `monthlyReportProvider(bookId: ..., startDate: ..., endDate: ..., joyMetricVariant: ...)`)
3. Providers delegate to Application layer Use Cases in `lib/application/analytics/`
4. Use Cases query `IAnalyticsRepository` → `AnalyticsRepositoryImpl` (`lib/data/repositories/analytics_repository_impl.dart`) → `AnalyticsDao` (`lib/data/daos/analytics_dao.dart`)
5. `JoyMetricVariant.manualOnly` maps to `entrySourceFilter: EntrySource.manual` at the provider/use-case boundary (D-15 pattern)

**State Management:**
- Session-scoped UI state: `@riverpod` codegen — auto-disposes unless `keepAlive: true`
- Persistent app state: `appSettingsProvider`, `currentLocaleProvider` (backed by `SettingsRepositoryImpl`)
- Navigation tab: `selectedTabIndexProvider` (`keepAlive: true`)
- Analytics window: `selectedTimeWindowProvider` (session-scoped, resets on cold start)
- Joy variant: `selectedJoyMetricVariantProvider` (session-scoped, resets on cold start — D-11)

## Key Abstractions

**Use Cases:**
- Purpose: Single-responsibility business operations
- Examples: `lib/application/accounting/create_transaction_use_case.dart`, `lib/application/analytics/get_happiness_report_use_case.dart`, `lib/application/family_sync/full_sync_use_case.dart`
- Pattern: Plain Dart class, single `execute(...)` method, injected dependencies via constructor

**Repository Interfaces:**
- Purpose: Decouple Application from Data storage details
- Examples: `lib/features/accounting/domain/repositories/transaction_repository.dart`, `lib/features/analytics/domain/repositories/` (via `lib/features/accounting/domain/repositories/`)
- Pattern: Abstract class with typed return values (often `Result<T>` from `lib/shared/utils/result.dart`)

**Freezed Models:**
- Purpose: Immutable domain data with `copyWith`
- Examples: `lib/features/accounting/domain/models/transaction.dart`, `lib/features/analytics/domain/models/happiness_report.dart`
- Pattern: `@freezed` annotation → `.freezed.dart` generated file → always use `copyWith`, never mutate

**MetricResult<T>:**
- Purpose: Discriminated union for analytics results (data present / empty / insufficient data)
- Examples: `lib/features/analytics/domain/models/metric_result.dart` — subtypes `Data<T>`, `Empty`, used across all analytics providers
- Pattern: Used instead of `T?` for analytics results that have meaningful empty-state semantics

**AnalyticsScreen Providers (Phase 15+17):**
- Purpose: Fan-out analytics queries keyed by `(startDate, endDate, joyMetricVariant)`
- Location: `lib/features/analytics/presentation/providers/state_analytics.dart`, `state_happiness.dart`, `state_ledger_snapshot.dart`
- Use Cases wired: `monthlyReport`, `expenseTrend`, `satisfactionDistribution`, `perCategorySoulBreakdown`, `perCategorySoulBreakdownFamily`, `soulVsSurvivalSnapshot`, `soulVsSurvivalSnapshotFamily`, `happinessReport`, `bestJoyMoment`, `monthlyJoyTargetRecommendation`, `largestMonthlyExpense`, `familyHappiness` (12 async providers total)

## Entry Points

**App Entry:**
- Location: `lib/main.dart`
- Triggers: Flutter framework `main()` on app start
- Responsibilities: native library init, `AppInitializer` orchestration, `UncontrolledProviderScope` mount

**Shell:**
- Location: `lib/features/home/presentation/screens/main_shell_screen.dart`
- Triggers: Rendered after successful initialization + profile check
- Responsibilities: Bottom nav tab host (Home, Accounting, Analytics, Settings, Family)

**Onboarding:**
- Location: `lib/features/profile/presentation/screens/profile_onboarding_screen.dart`
- Triggers: `getUserProfileUseCase.execute()` returns null after init
- Responsibilities: First-launch profile creation

## Joy Metric Semantics (ADR-016, ratified 2026-05-19)

The **Joy** metric for analytics display is:

```
Σ joy_contribution = Σ (soul_satisfaction × (amount / base)^0.88)
```

This is a cumulative sum (not a density ratio). ADR-013's Joy/¥ density is **superseded** for HomeHero ring and analytics KPI display. The HomeHero ring visualizes single-month accumulation only (isolation invariant enforced by `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`). `JoyCumulativeFormatter` (`lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart`) handles display formatting.

**HomeHero isolation invariant:** HomeHero providers (`state_home.dart`, `state_shadow_books.dart`, `state_today_transactions.dart`) do NOT read `selectedTimeWindowProvider` or `selectedJoyMetricVariantProvider`. They are always current-month, all-source. This is structural (D-15 / ADR-016 §3).

## Architectural Constraints

- **Threading:** Flutter single-threaded UI; Drift uses an isolate-based background executor for database I/O
- **Global state:** `AppDatabase` is singleton-per-run via `appDatabaseProvider`; `ProviderContainer` created once in `AppInitializer` and shared via `UncontrolledProviderScope`
- **Circular imports:** Prevented by `import_guard.yaml` files at layer boundaries + `domain_import_rules_test.dart` (`test/architecture/domain_import_rules_test.dart`)
- **Generated files:** `.g.dart` and `.freezed.dart` must never be hand-edited; run `flutter pub run build_runner build --delete-conflicting-outputs` after any annotation change
- **Riverpod 3 import split:** `flutter_riverpod.dart` (primary), `flutter_riverpod/legacy.dart` (StateNotifier), `flutter_riverpod/misc.dart` (Override, ProviderBase) — see CLAUDE.md for full table
- **Riverpod 3 upgrade blocked:** Riverpod 3 upgrade is tracked as FUTURE-TOOL-01 (blocked by `analyzer` conflict with `json_serializable`); codebase currently uses Riverpod 2.x with generator 4.x conventions
- **DB encryption mandatory:** `sqlcipher_flutter_libs` only — `sqlite3_flutter_libs` is explicitly rejected by `import_guard` deny rule and AUDIT-09 CI guardrail

## Anti-Patterns

### Use Cases inside Features

**What happens:** Placing business logic (Use Case classes) inside `lib/features/{f}/` instead of `lib/application/`
**Why it's wrong:** Violates the Thin Feature rule; creates duplicated logic and breaks the single Application layer
**Do this instead:** Create the Use Case in `lib/application/{domain}/your_use_case.dart`; wire its provider in `lib/features/{f}/presentation/providers/repository_providers.dart`

### Repository Provider Duplication

**What happens:** Defining the same repository provider in multiple provider files
**Why it's wrong:** Creates divergent state — each definition gets its own instance; causes test flakiness and production bugs
**Do this instead:** Define ONCE in `lib/features/{f}/presentation/providers/repository_providers.dart`; import from there everywhere else. Enforced by `test/architecture/provider_graph_hygiene_test.dart`

### Bare `container.read(provider.future)` in Tests

**What happens:** Calling `await container.read(asyncProvider.future)` without a subscription in auto-dispose provider tests
**Why it's wrong:** Riverpod 3 disposes the orphan read before build settles; masks real values/errors with `Bad state: disposed during loading`
**Do this instead:** Use `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart`

### Domain Importing Data

**What happens:** A file in `lib/features/{f}/domain/` imports from `lib/data/`
**Why it's wrong:** Reverses the dependency direction; Domain must be the innermost layer with no outward imports
**Do this instead:** Domain defines the interface; Data implements it. Enforced by `import_guard.yaml` + `test/architecture/domain_import_rules_test.dart`

## Error Handling

**Strategy:** `Result<T>` wrapper for use-case return values; `InitResult` (Freezed union) for initialization; `MetricResult<T>` for analytics with meaningful empty states

**Patterns:**
- Use cases return `Result<T>` (from `lib/shared/utils/result.dart`) — callers switch on `isSuccess`/`error`
- Initialization uses `InitResult.success(container)` / `InitResult.failure(type, error, stackTrace)` — `lib/core/initialization/init_result.dart`
- Analytics providers return `MetricResult<T>` subtypes (`Data<T>` / `Empty`) to differentiate "no data" from "query error"
- Presentation layer catches `AsyncError` states via `AsyncValue.when(error: ...)` in widgets

## Cross-Cutting Concerns

**Logging:** `AuditLogger` (`lib/infrastructure/security/audit_logger.dart`) for security-relevant events; no `print()` or `debugPrint()` in production code (enforced by `test/architecture/production_logging_privacy_test.dart`)
**Validation:** Time window validation in `lib/application/analytics/_time_window_validation.dart`; input validated at use-case boundary
**Authentication:** Biometric lock via `BiometricService` (`lib/infrastructure/security/biometric_service.dart`); all DB access gated by SQLCipher key derived by `KeyManager`
**i18n:** All UI text via `S.of(context)` (generated from ARB files at `lib/l10n/`); dates via `DateFormatter`; currency via `NumberFormatter` — no hardcoded CJK/Latin strings (enforced by `test/architecture/hardcoded_cjk_ui_scan_test.dart`)
**CI Guardrails:** `import_guard` (custom_lint), `riverpod_lint`, `coverde` per-file ≥70%, `very_good_coverage@v2` ≥70% global, `build_runner` clean-diff check, ARB parity (487 keys × 3 locales at v1.2 close), `sqlite3_flutter_libs` rejection

---

*Architecture analysis: 2026-05-21*
