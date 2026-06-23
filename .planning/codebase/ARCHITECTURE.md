<!-- refreshed: 2026-06-23 -->
# Architecture

**Analysis Date:** 2026-06-23

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
├──────────────────┬──────────────────┬───────────────────────┤
│  Screens/Widgets │  Riverpod        │   Route Listeners     │
│ `lib/features/   │  Providers       │  `family_sync/.../    │
│  {f}/presentation│ `{f}/presentation│   widgets/...route_   │
│  /screens`       │  /providers`     │   listener.dart`      │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│            Application Layer (GLOBAL, use cases)             │
│         `lib/application/{domain}/...use_case.dart`          │
└─────────────────────────────────────────────────────────────┘
         │                                       │
         ▼                                       ▼
┌──────────────────────────────┐   ┌────────────────────────────┐
│  Domain Layer (interfaces)   │   │  Infrastructure Layer      │
│ `lib/features/{f}/domain/`   │   │ `lib/infrastructure/`      │
│  models/ + repositories/     │   │  crypto, ml, sync, i18n... │
└──────────────┬───────────────┘   └─────────────┬──────────────┘
               ▼                                  │
┌─────────────────────────────────────────────────────────────┐
│             Data Layer (CROSS-FEATURE, impls)               │
│  `lib/data/` — app_database.dart, tables/, daos/,           │
│  repositories/ (Drift + SQLCipher)                          │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry | Native bootstrap, init, run app | `lib/main.dart` |
| AppInitializer | 3-stage init (keys → DB → seed) | `lib/core/initialization/app_initializer.dart` |
| AppDatabase | Drift DB (schema v22), migrations | `lib/data/app_database.dart` |
| Tables | All Drift table definitions | `lib/data/tables/` |
| DAOs | Data access objects (SQL) | `lib/data/daos/` |
| Repository impls | Concrete data access | `lib/data/repositories/` |
| Use cases | Business logic units | `lib/application/{domain}/` |
| Domain models/interfaces | Freezed models + repo interfaces | `lib/features/{f}/domain/` |
| Crypto | Key mgmt, field encryption, hash chain | `lib/infrastructure/crypto/services/` |
| Nav shell | IndexedStack tab shell + FAB | `lib/features/home/presentation/screens/main_shell_screen.dart` |

## Pattern Overview

**Overall:** Clean Architecture (5 layers) with the "Thin Feature" variant.

**Key Characteristics:**
- Feature modules contain ONLY `domain/` (models + repo interfaces) and `presentation/` (screens, widgets, providers).
- Application (use cases) and Data (tables/DAOs/repo impls) live at GLOBAL roots, NOT inside features.
- Infrastructure holds technology/platform capabilities (crypto, ML, sync, i18n, speech).
- Local-first, offline-first, zero-knowledge: 4-layer encryption with SQLCipher at the base.

## Layers

**Presentation (`lib/features/{f}/presentation/`):**
- Purpose: UI and provider wiring.
- Contains: `screens/`, `widgets/`, `providers/` (Riverpod 3, `@riverpod` codegen).
- Depends on: Application use cases (via providers), Domain models.

**Application (`lib/application/{domain}/`):**
- Purpose: GLOBAL business logic — Use Cases + Services.
- Domains: accounting, analytics, currency, dual_ledger, family_sync, i18n, list, ml, profile, seed, settings, shopping_list, voice.
- Pattern: `*_use_case.dart` classes; providers wiring them live in feature `presentation/providers/`.

**Domain (`lib/features/{f}/domain/`):**
- Purpose: Independent core — `models/` (Freezed) + `repositories/` (interfaces only).
- Depends on: nothing (innermost). Enforced by `import_guard.yaml` + `domain_import_rules_test.dart`.

**Data (`lib/data/`):**
- Purpose: Shared, cross-feature persistence.
- Contains: `app_database.dart`, `tables/`, `daos/`, `repositories/` (impls of domain interfaces).
- Tech: Drift type-safe SQL over SQLCipher AES-256.

**Infrastructure (`lib/infrastructure/`):**
- Purpose: Technology/platform capability.
- Subdirs: `crypto/`, `ml/`, `sync/`, `i18n/`, `security/`, `speech/`, `voice/`, `category/`, `exchange_rate/`.

## Data Flow

### App Startup Path

1. `main()` — `WidgetsFlutterBinding.ensureInitialized()` + `ensureNativeLibrary()` (`lib/main.dart:39`)
2. `AppInitializer.initialize()` — Stage 1 master key + device key pair (`app_initializer.dart:47`)
3. Stage 2 — build encrypted `AppDatabase` via `createEncryptedExecutor` (`app_initializer.dart:88`)
4. Stage 3 — final `ProviderContainer` with `appDatabaseProvider` override + seeding (`app_initializer.dart:103`)
5. `bootWithInitializerForTesting` — `UncontrolledProviderScope` → `HomePocketApp` or `InitFailureApp` (`lib/main.dart:75`)
6. `HomePocketApp._initialize()` — `SeedAllUseCase`, ensure default book, init sync engine, profile onboarding gate (`lib/main.dart:109`)

### Transaction Write Path

1. Screen invokes use case via provider (`features/accounting/presentation/providers/repository_providers.dart`)
2. `CreateTransactionUseCase.execute()` (`lib/application/accounting/create_transaction_use_case.dart`)
3. Repository interface → impl (`lib/data/repositories/transaction_repository_impl.dart`)
4. DAO writes via Drift (`lib/data/daos/transaction_dao.dart`)
5. Field encryption + hash chain applied via `lib/infrastructure/crypto/services/`

**State Management:**
- Riverpod 3.1+ with `@riverpod` codegen (generator 4.x). Provider names strip the `Notifier` suffix.
- Side-effect listeners use `ref.listen` (navigation, snackbars), not `ref.watch`.

## Key Abstractions

**Use Case:**
- Purpose: Single business operation with explicit `execute()`.
- Examples: `lib/application/accounting/create_transaction_use_case.dart`, `ensure_default_book_use_case.dart`, `lib/application/seed/` (SeedAllUseCase).

**Repository (interface + impl split):**
- Interface: `lib/features/{f}/domain/repositories/*.dart`
- Impl: `lib/data/repositories/*_repository_impl.dart`

**Result:**
- Purpose: Success/error envelope.
- File: `lib/shared/utils/result.dart`

**Freezed Model:**
- Purpose: Immutable domain model (`copyWith`).
- Examples: `lib/features/accounting/domain/models/transaction.dart`, `book.dart`, `category.dart`.

## Entry Points

**App main:**
- Location: `lib/main.dart`
- Triggers: Flutter runtime.
- Responsibilities: native libs, AppInitializer, MaterialApp (theme, locale, MainShell/onboarding).

**Nav shell:**
- Location: `lib/features/home/presentation/screens/main_shell_screen.dart`
- Triggers: post-init from `HomePocketApp._buildHome`.
- Responsibilities: `IndexedStack` tab shell + central FAB; refreshes on sync completion.

## Architectural Constraints

- **Threading:** Dart single-isolate event loop; native DB and ML run via plugin platform channels.
- **Global state:** `ProviderContainer` is the single DI root; `appDatabaseProvider` injected as an override at init.
- **Routing:** No `go_router`. Built-in `Navigator` / `MaterialPageRoute` + `IndexedStack` tab shell.
- **Data-loss guard:** Never mint a new master key when an encrypted DB already exists (`app_initializer.dart:59`).
- **Layer dependencies:** Domain must not import Data. Enforced by `import_guard` (custom_lint) + `domain_import_rules_test.dart`.
- **Drift indices:** `customIndices` is decorative — explicit `CREATE INDEX` must be emitted in both `onCreate` and `onUpgrade` (`app_database.dart`).

## Anti-Patterns

### Logic inside a Feature module

**What happens:** Adding `application/`, `data/tables/`, or `data/daos/` under `lib/features/{f}/`.
**Why it's wrong:** Violates the Thin Feature rule; breaks cross-feature reuse and layer enforcement.
**Do this instead:** Use cases → `lib/application/{domain}/`; tables/DAOs/repo impls → `lib/data/`.

### Duplicate repository provider definitions

**What happens:** Defining the same repository provider in more than one place.
**Why it's wrong:** Multiple sources of truth; caught by `provider_graph_hygiene_test.dart` + riverpod_lint.
**Do this instead:** ONE `repository_providers.dart` per feature; use-case providers `ref.watch()` it.

### `ref.watch` for side effects

**What happens:** Driving navigation/snackbars from `ref.watch`.
**Why it's wrong:** Riverpod 3 dropped some watch-driven side-effect rebuilds for legacy StateNotifierProviders.
**Do this instead:** Use `ref.listen` (see `FamilySyncNotificationRouteListener`).

## Error Handling

**Strategy:** Staged init returns `InitResult.failure` with typed `InitFailureType`; UI shows `InitFailureApp`/error scaffold.

**Patterns:**
- `Result` envelope for use-case outcomes (`lib/shared/utils/result.dart`).
- Provider errors wrapped in `ProviderException` (Riverpod 3).

## Cross-Cutting Concerns

**Logging:** No `console`/`print` in production paths; `audit_logger` in `lib/infrastructure/security/`. Never log sensitive data.
**Validation:** At system boundaries (input + external data).
**Authentication:** Biometric lock + secure storage via `lib/infrastructure/security/`; Ed25519 device keys via `lib/infrastructure/crypto/services/key_manager.dart`.
**i18n:** `S.of(context)` for all UI text; `DateFormatter`/`NumberFormatter` in `lib/infrastructure/i18n/formatters/`.

---

*Architecture analysis: 2026-06-23*
