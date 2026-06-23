<!-- refreshed: 2026-06-23 -->
# Architecture

**Analysis Date:** 2026-06-23

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
├──────────────────┬──────────────────┬───────────────────────┤
│  Feature screens │  Feature widgets │  Riverpod providers   │
│ `lib/features/   │ `lib/features/   │ `lib/features/{f}/    │
│  {f}/presentation│  {f}/presentation│  presentation/        │
│  /screens`       │  /widgets`       │  providers`           │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
│  Use Cases + domain services (GLOBAL, not per-feature)      │
│  `lib/application/{domain}/`                                 │
└────────┬────────────────────────────────────────────────────┘
         │ depends on interfaces
         ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                           │
│  Freezed models + repository interfaces                      │
│  `lib/features/{f}/domain/{models,repositories}`             │
└────────▲────────────────────────────────────────────────────┘
         │ implemented by
┌────────┴────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  Drift tables, DAOs, repository implementations              │
│  `lib/data/{tables,daos,repositories}` + `app_database.dart` │
└────────┬────────────────────────────────────────────────────┘
         │ uses
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  crypto/ ml/ sync/ security/ i18n/ speech/ exchange_rate/    │
│  `lib/infrastructure/`                                       │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry / bootstrap | Load native libs, run AppInitializer, mount root widget | `lib/main.dart` |
| AppInitializer | Staged init: master key → device key → database → seed | `lib/core/initialization/app_initializer.dart` |
| AppDatabase | Drift database, all table registration, schema version | `lib/data/app_database.dart` |
| Use Cases | Single-purpose business operations (CRUD, classification) | `lib/application/{domain}/*_use_case.dart` |
| Domain services | Cross-cutting business logic (classification, learning) | `lib/application/{domain}/*_service.dart` |
| Repository interfaces | Data-access contracts owned by domain | `lib/features/{f}/domain/repositories/` |
| Repository impls | Drift-backed concrete data access | `lib/data/repositories/*_impl.dart` |
| DAOs | Type-safe SQL queries per table | `lib/data/daos/` |
| Crypto infrastructure | Key management, field encryption, hash chain, DB encryption | `lib/infrastructure/crypto/` |
| Root shell | Tab navigation host (IndexedStack + bottom nav) | `lib/features/home/presentation/screens/main_shell_screen.dart` |

## Pattern Overview

**Overall:** Clean Architecture (5 layers) with the "Thin Feature" variant — the Application, Data, and Infrastructure layers are project-global, while `features/` hold only Domain + Presentation.

**Key Characteristics:**
- Dependency rule: outer layers depend on inner; Domain depends on nothing
- Repository pattern: interfaces in Domain, implementations in `lib/data/`
- Use Case classes encapsulate each business operation; providers wire them in Presentation
- Riverpod 3 (`@riverpod` codegen) for all dependency injection and state
- Freezed for immutable models; Drift + SQLCipher for encrypted persistence

## Layers

**Presentation:**
- Purpose: UI rendering, user interaction, provider wiring
- Location: `lib/features/{feature}/presentation/`
- Contains: `screens/`, `widgets/`, `providers/`
- Depends on: Application (use cases), Domain (models)
- Used by: Root shell / Flutter framework

**Application:**
- Purpose: business logic, orchestration of repositories + infrastructure
- Location: `lib/application/{domain}/` (GLOBAL — never inside `features/`)
- Contains: Use Case classes, domain services, repository provider wiring
- Depends on: Domain interfaces, Infrastructure services
- Used by: Presentation providers

**Domain:**
- Purpose: business entities and data-access contracts
- Location: `lib/features/{feature}/domain/`
- Contains: ONLY `models/` (Freezed) + `repositories/` (interfaces)
- Depends on: nothing (independent)
- Used by: Application, Data

**Data:**
- Purpose: persistence and concrete repositories
- Location: `lib/data/`
- Contains: `app_database.dart`, `tables/`, `daos/`, `repositories/`
- Depends on: Domain interfaces, Infrastructure (crypto executor)
- Used by: Application (via interfaces)

**Infrastructure:**
- Purpose: technology/platform capabilities
- Location: `lib/infrastructure/`
- Contains: `crypto/`, `ml/`, `sync/`, `security/`, `i18n/`, `speech/`, `voice/`, `category/`, `exchange_rate/`
- Depends on: external packages, platform
- Used by: Data, Application

## Data Flow

### Primary Request Path (create transaction)

1. Screen invokes use-case provider via `ref.read` (`lib/features/accounting/presentation/`)
2. `CreateTransactionUseCase.execute()` validates input + verifies category (`lib/application/accounting/create_transaction_use_case.dart`)
3. Classification service assigns ledger type; hash chain link computed (`lib/application/dual_ledger/classification_service.dart`, `lib/infrastructure/crypto/services/hash_chain_service.dart`)
4. `TransactionRepository.create()` persists via DAO (`lib/data/repositories/transaction_repository_impl.dart` → `lib/data/daos/transaction_dao.dart`)
5. Change tracker enqueues sync delta (`lib/application/family_sync/transaction_change_tracker.dart`)

### App Boot Path

1. `main()` ensures bindings + loads native SQLCipher library (`lib/main.dart`)
2. `AppInitializer.initialize()` runs staged init (`lib/core/initialization/app_initializer.dart`)
3. Master key + device key pair via keychain (`lib/infrastructure/crypto/`)
4. Encrypted database created; `InitResult.success(container)` returned
5. `HomePocketApp._initialize()` runs seeding, ensures default book, wires sync engine, then routes to onboarding or `MainShellScreen`

**State Management:**
- Riverpod 3 `ProviderContainer` is created in AppInitializer and injected via `UncontrolledProviderScope`
- Async state through `AsyncValue`; provider names strip the `Notifier` suffix

## Key Abstractions

**Use Case:**
- Purpose: one business operation with explicit params object
- Examples: `lib/application/accounting/create_transaction_use_case.dart`, `get_transactions_use_case.dart`
- Pattern: constructor-injected repositories; `execute()` returns `Result<T>`

**Repository:**
- Purpose: storage-agnostic data access
- Interface examples: `lib/features/accounting/domain/repositories/transaction_repository.dart`
- Impl examples: `lib/data/repositories/transaction_repository_impl.dart`

**Result<T>:**
- Purpose: explicit success/error envelope instead of throwing
- Location: `lib/shared/utils/result.dart`

## Entry Points

**main():**
- Location: `lib/main.dart`
- Triggers: app launch
- Responsibilities: native lib load, bootstrap via AppInitializer, mount root or failure screen

**MainShellScreen:**
- Location: `lib/features/home/presentation/screens/main_shell_screen.dart`
- Triggers: successful init + completed profile onboarding
- Responsibilities: hosts tabs via `IndexedStack`, bottom nav, central FAB add-entry

## Architectural Constraints

- **Threading:** single-threaded Dart event loop; Drift runs queries on its own isolate executor
- **Global state:** `ProviderContainer` from AppInitializer is the single DI root; `appDatabaseProvider` overridden with the encrypted instance
- **Circular imports:** none enforced-against; import_guard + arch tests block Domain→Data violations
- **Encryption non-negotiable:** all crypto MUST route through `lib/infrastructure/crypto/`; `sqlite3_flutter_libs` denied by `lib/import_guard.yaml`
- **Navigation:** plain `Navigator`/`MaterialPageRoute` + `IndexedStack` shell (no GoRouter in code despite legacy doc references)

## Anti-Patterns

### Application code inside a feature

**What happens:** placing use cases or services under `lib/features/{f}/application/`
**Why it's wrong:** violates the Thin Feature rule; Application is global
**Do this instead:** put business logic in `lib/application/{domain}/` (see existing `lib/application/accounting/`)

### Domain importing Data

**What happens:** a model or repository interface imports a Drift table or DAO
**Why it's wrong:** breaks the dependency rule; Domain must stay independent
**Do this instead:** depend only on interfaces; implement them in `lib/data/repositories/` (enforced by `domain_import_rules_test.dart` + import_guard custom_lint)

### Duplicate repository providers

**What happens:** defining the same repository provider in more than one place
**Why it's wrong:** breaks single-source-of-truth and provider graph hygiene
**Do this instead:** one `repository_providers.dart` per feature (enforced by `provider_graph_hygiene_test.dart`)

## Error Handling

**Strategy:** `Result<T>` envelope for business operations; staged `InitResult` failure types for boot.

**Patterns:**
- Use Cases return `Result<T>` (`isSuccess`/`error`/`data`)
- Boot failures classified by `InitFailureType` and rendered via `InitFailureApp`
- Data-loss guard: never mint a new master key when an encrypted DB already exists

## Cross-Cutting Concerns

**Logging:** no `print`/`console`; sensitive data never logged (crypto rule)
**Validation:** input validated inside Use Cases before persistence
**Authentication:** biometric lock + secure storage via `lib/infrastructure/security/`
**i18n:** all UI text through `S.of(context)`; formatting via `lib/infrastructure/i18n/formatters/`

---

*Architecture analysis: 2026-06-23*
