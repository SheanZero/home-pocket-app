<!-- refreshed: 2026-06-23 -->
# Architecture

**Analysis Date:** 2026-06-23

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
├──────────────────┬──────────────────┬───────────────────────┤
│  features/*/      │  features/*/     │  features/*/          │
│  presentation/    │  presentation/   │  presentation/        │
│  screens/         │  widgets/        │  providers/           │
│  `lib/features/<feat>/presentation/`                         │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│   Use Cases + cross-feature services (GLOBAL, not in feats)  │
│   `lib/application/<domain>/`                                │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                           │
│   Freezed models + repository INTERFACES (leafmost)          │
│   `lib/features/<feat>/domain/{models,repositories}/`        │
└─────────────────────────────────────────────────────────────┘
         ▲                                        ▲
         │ implements                             │ uses
┌────────┴───────────────────┐      ┌─────────────┴──────────────┐
│        Data Layer          │◄─────│     Infrastructure Layer   │
│  tables/ daos/ repositories│      │  crypto/ ml/ sync/ security/│
│  `lib/data/`               │      │  i18n/ `lib/infrastructure/`│
└────────────┬───────────────┘      └────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  Drift + SQLCipher encrypted SQLite (schema v22)             │
│  `lib/data/app_database.dart`                                │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry / bootstrap | Load native libs, run AppInitializer, mount root widget | `lib/main.dart` |
| AppInitializer | Ordered startup: master key → device key → database → seed | `lib/core/initialization/app_initializer.dart` |
| AppDatabase | Drift database, all DAOs, schema/migrations (v22) | `lib/data/app_database.dart` |
| Repository impls | Encrypt/decrypt fields, map Drift rows ↔ domain models | `lib/data/repositories/*_impl.dart` |
| Use cases | Single-purpose business operations | `lib/application/<domain>/*_use_case.dart` |
| Domain models | Immutable Freezed entities + repo interfaces | `lib/features/<feat>/domain/` |
| Riverpod providers | Wire use cases ↔ repositories ↔ UI state | `lib/features/<feat>/presentation/providers/` |
| Main shell | IndexedStack tab host + FAB add-entry | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| Crypto services | Key mgmt, field encryption, hash chain | `lib/infrastructure/crypto/services/` |

## Pattern Overview

**Overall:** Clean Architecture with 5 layers + "Thin Feature" module pattern.

**Key Characteristics:**
- Dependency rule: outer layers depend on inner; Domain depends on nothing. `Presentation → Application → Domain ← Data ← Infrastructure`.
- Repository pattern: interfaces in feature `domain/repositories/`, implementations in shared `lib/data/repositories/`.
- Local-first, zero-knowledge: all persistence flows through SQLCipher; sensitive fields additionally encrypted via `FieldEncryptionService`.
- Code generation everywhere: Riverpod (`@riverpod`), Freezed (`@freezed`), Drift. Never hand-edit `.g.dart` / `.freezed.dart`.
- Layer boundaries enforced by tooling (`import_guard` custom_lint + architecture tests), not just convention.

## Layers

**Presentation:**
- Purpose: UI screens, widgets, and Riverpod providers wiring use cases to UI.
- Location: `lib/features/<feat>/presentation/`
- Contains: `screens/`, `widgets/`, `providers/` (state + `repository_providers.dart`)
- Depends on: Application, Domain
- Used by: Flutter framework (root widget tree)

**Application:**
- Purpose: GLOBAL business logic — use cases and cross-feature services.
- Location: `lib/application/<domain>/` (NOT inside features)
- Contains: `*_use_case.dart`, domain services, `repository_providers.dart`
- Depends on: Domain (repository interfaces)
- Used by: Presentation providers via `ref.watch()`

**Domain:**
- Purpose: Independent core — immutable models and repository contracts.
- Location: `lib/features/<feat>/domain/{models,repositories}/`
- Contains: Freezed models, repository interfaces only
- Depends on: nothing (leafmost in graph)
- Used by: Application, Data (implements interfaces)

**Data:**
- Purpose: Shared cross-feature data access.
- Location: `lib/data/`
- Contains: `tables/` (Drift), `daos/`, `repositories/` (impls)
- Depends on: Domain (implements interfaces), Infrastructure (crypto)
- Used by: Application (via repository providers)

**Infrastructure:**
- Purpose: Technology/platform capabilities.
- Location: `lib/infrastructure/`
- Contains: `crypto/`, `ml/`, `sync/`, `security/`, `i18n/`, `speech/`, `voice/`, `exchange_rate/`, `category/`
- Depends on: nothing app-specific (platform SDKs)
- Used by: Data, Application

## Data Flow

### Primary Write Path (create transaction)

1. UI triggers add-entry from shell FAB (`lib/features/home/presentation/screens/main_shell_screen.dart:200`)
2. Provider reads `CreateTransactionUseCase` (`lib/application/accounting/create_transaction_use_case.dart`)
3. Use case calls `TransactionRepository` interface (`lib/features/accounting/domain/repositories/transaction_repository.dart`)
4. Impl encrypts `note` via `FieldEncryptionService`, then delegates to DAO (`lib/data/repositories/transaction_repository_impl.dart:24`)
5. DAO writes encrypted row to SQLCipher database (`lib/data/daos/transaction_dao.dart`)

### Startup / Initialization Path

1. `main()` → `ensureNativeLibrary()` → `_boot()` (`lib/main.dart`)
2. `AppInitializer.initialize()` runs staged setup (`lib/core/initialization/app_initializer.dart`)
3. Stage 1: master key + device key pair (with data-loss guard if DB exists but key missing)
4. Stage 2: build encrypted `AppDatabase`, run seed runner
5. Root mounts `UncontrolledProviderScope` or `InitFailureScreen` on failure

**State Management:**
- Riverpod 3.1+ with `@riverpod` codegen. One `repository_providers.dart` per feature is the single source of truth.
- Side-effects (navigation, snackbars) use `ref.listen`, never `ref.watch`.

## Key Abstractions

**Repository (interface + impl):**
- Purpose: Decouple business logic from Drift/encryption details.
- Examples: `lib/features/accounting/domain/repositories/transaction_repository.dart` (interface), `lib/data/repositories/transaction_repository_impl.dart` (impl)
- Pattern: Repository pattern; impls own row↔model mapping and field encryption.

**Use Case:**
- Purpose: One business operation per class.
- Examples: `lib/application/accounting/create_transaction_use_case.dart`, `lib/application/analytics/get_monthly_report_use_case.dart`
- Pattern: Constructor-injected repository dependencies; wired via provider in feature presentation.

**Freezed Model:**
- Purpose: Immutable domain entity with `copyWith`.
- Examples: `lib/features/accounting/domain/models/transaction.dart`, `book.dart`, `category.dart`
- Pattern: `@freezed` + generated `.freezed.dart`/`.g.dart`.

## Entry Points

**App bootstrap:**
- Location: `lib/main.dart`
- Triggers: Flutter runtime
- Responsibilities: native lib load, run `AppInitializer`, mount provider scope + theme + l10n

**Tab shell:**
- Location: `lib/features/home/presentation/screens/main_shell_screen.dart`
- Triggers: post-init root widget
- Responsibilities: `IndexedStack` over Home/List/Analytics/Shopping tabs + central FAB add-entry, `Navigator`-based push for sub-screens

## Architectural Constraints

- **Routing:** No `go_router`. Navigation via built-in `Navigator` + `MaterialPageRoute`; tab switching via `IndexedStack` + `selectedTabIndexProvider`.
- **Layer dependencies:** Domain must not import Data/Infrastructure/Application/Presentation/Flutter. Enforced by `import_guard.yaml` (per-directory deny/allow) + `test/architecture/domain_import_rules_test.dart`.
- **Single repository provider:** Never duplicate repository provider definitions — enforced by `test/architecture/provider_graph_hygiene_test.dart` + `riverpod_lint`.
- **Crypto isolation:** All crypto MUST go through `lib/infrastructure/crypto/`. Never access `flutter_secure_storage` directly or implement custom crypto.
- **Init order:** KeyManager → Database → other services (DB requires keys). Skipping `AppInitializer` is a structural error.
- **Generated files:** `.g.dart` / `.freezed.dart` are never hand-edited; AUDIT-10 CI catches stale generated output.

## Anti-Patterns

### Business logic / application code inside a feature

**What happens:** Placing `application/`, `data/tables/`, or `data/daos/` under `lib/features/<feat>/`.
**Why it's wrong:** Violates the "Thin Feature" rule; couples features and breaks the global application layer.
**Do this instead:** Put use cases in `lib/application/<domain>/`, data access in `lib/data/`. Features hold only `domain/` + `presentation/`.

### Side-effects driven by ref.watch

**What happens:** Triggering navigation/snackbars from `ref.watch` on a provider.
**Why it's wrong:** Riverpod 3 dropped some watch-driven side-effect rebuilds for legacy `StateNotifierProvider`s, so effects silently stop firing.
**Do this instead:** Use `ref.listen` (see `FamilySyncNotificationRouteListener` in the shell).

### Duplicate repository provider definitions

**What happens:** Defining the same repository provider in multiple files.
**Why it's wrong:** Creates divergent instances and ambiguous wiring.
**Do this instead:** One `repository_providers.dart` per feature; reference via `ref.watch()`. See `lib/features/accounting/presentation/providers/repository_providers.dart`.

## Error Handling

**Strategy:** Fail-loud at boundaries; result types for init.

**Patterns:**
- Initialization returns a Freezed `InitResult.failure(...)` (`lib/core/initialization/init_result.dart`) rendered by `InitFailureScreen`, rather than throwing into the widget tree.
- Data-loss guard: missing master key with existing encrypted DB returns `masterKeyMissingWithData` instead of minting a new key.
- Provider errors are wrapped in `ProviderException` (Riverpod 3); inner exception on `.exception`.

## Cross-Cutting Concerns

**Logging:** `avoid_print` lint enforced; production logging-privacy checked by `test/architecture/production_logging_privacy_test.dart`. Never log sensitive data.
**Validation:** Boundary validation in use cases / repository impls (e.g. `_time_window_validation.dart` in analytics).
**Authentication:** Biometric lock + secure storage via `lib/infrastructure/security/`; device identity via Ed25519 key pair in `lib/infrastructure/crypto/`.
**i18n:** All UI text via `S.of(context)`; dates/currency via `DateFormatter`/`NumberFormatter` (`lib/infrastructure/i18n/formatters/`). CJK hardcode scan in `test/architecture/hardcoded_cjk_ui_scan_test.dart`.

---

*Architecture analysis: 2026-06-23*
