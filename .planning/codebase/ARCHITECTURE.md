<!-- refreshed: 2026-07-14 -->
# Architecture

**Analysis Date:** 2026-07-14

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                       Presentation                           │
│   `lib/features/{feature}/presentation/`                     │
├──────────────────┬──────────────────┬───────────────────────┤
│   screens/       │   widgets/       │    providers/         │
│  (Flutter UI)    │  (Flutter UI)    │  (Riverpod wiring)    │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                       Application                            │
│   `lib/application/{domain}/`  (Use Cases + Services)        │
└─────────────────────────────────────────────────────────────┘
         │                                        ▲
         ▼                                        │
┌──────────────────────────────┐   ┌─────────────────────────┐
│           Domain             │   │          Data           │
│ `lib/features/{f}/domain/`   │◄──│   `lib/data/`           │
│  models/ + repositories/     │   │  tables/ daos/ repos/   │
│  (interfaces only)           │   └────────────┬────────────┘
└──────────────────────────────┘                │
                                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                     Infrastructure                           │
│  `lib/infrastructure/`                                       │
│  crypto/ ml/ sync/ security/ i18n/ speech/ voice/ ...       │
└─────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Store: Drift + SQLCipher (encrypted SQLite)                 │
│  `lib/data/app_database.dart`  (schemaVersion 23)           │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| App entry / boot gate | Native lib load, initialize, onboarding + app-lock gate, shell mount | `lib/main.dart` |
| AppInitializer | Staged boot: master key → database → seed; returns `InitResult` | `lib/core/initialization/app_initializer.dart` |
| Tab shell | `IndexedStack` navigation host, custom bottom nav + FAB | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| AppDatabase | Drift database, table registration, migrations, index backfill | `lib/data/app_database.dart` |
| Use Cases | Global business logic (transaction CRUD, seeding, classification) | `lib/application/{domain}/*_use_case.dart` |
| Repository impls | Data access behind domain interfaces | `lib/data/repositories/*_impl.dart` |
| Repository interfaces | Domain contracts | `lib/features/{f}/domain/repositories/` |
| Crypto services | Key management, field encryption, hash chain, encrypted executor | `lib/infrastructure/crypto/` |

## Pattern Overview

**Overall:** 5-Layer Clean Architecture (Flutter) with a "Thin Feature" module pattern.

**Key Characteristics:**
- Layers: Presentation → Application → Domain ← Data ← Infrastructure. Domain is dependency-free; outer layers depend inward.
- Application and Infrastructure are GLOBAL (`lib/application/`, `lib/infrastructure/`), NOT nested inside features.
- Features hold ONLY `domain/` (models + repository interfaces) and `presentation/` (screens, widgets, providers).
- Repository Pattern: interfaces in `features/{f}/domain/repositories/`, implementations in `lib/data/repositories/`.
- Riverpod 3.x with `@riverpod` code generation for state and dependency wiring.
- Freezed for immutable models (`copyWith`, never mutation).
- Drift + SQLCipher for type-safe, encrypted persistence.

## Layers

**Presentation:**
- Purpose: Flutter UI and Riverpod provider wiring.
- Location: `lib/features/{feature}/presentation/{screens,widgets,providers}/`
- Depends on: Application (use cases), Domain (models).
- Used by: Flutter runtime via `MaterialApp` in `lib/main.dart`.

**Application:**
- Purpose: Global business logic — Use Cases and cross-cutting services.
- Location: `lib/application/{domain}/` (accounting, analytics, currency, family_sync, i18n, list, profile, security, seed, settings, shopping_list, voice).
- Contains: `*_use_case.dart`, `*_service.dart`, and composition-root `repository_providers.dart`.
- Depends on: Domain interfaces; wires Data impls only in `*_providers.dart` composition roots.

**Domain:**
- Purpose: Pure models and repository interfaces — no framework dependencies.
- Location: `lib/features/{feature}/domain/{models,repositories}/`
- Depends on: Nothing (independent).

**Data:**
- Purpose: All persistence — Drift tables, DAOs, repository implementations.
- Location: `lib/data/{tables,daos,repositories}/` + `lib/data/app_database.dart`.
- Depends on: Infrastructure (encryption), Domain (interfaces it implements).

**Infrastructure:**
- Purpose: Technology/platform capability wrappers.
- Location: `lib/infrastructure/{crypto,ml,sync,security,i18n,speech,voice,category,exchange_rate,platform}/`
- Used by: Data (DB encryption), Application, Presentation.

## Data Flow

### Primary Request Path (transaction create)

1. User acts in a presentation screen (`lib/features/accounting/presentation/screens/manual_one_step_screen.dart`).
2. Provider reads a Use Case (`createTransactionUseCaseProvider`) wired in `lib/features/accounting/presentation/providers/repository_providers.dart`.
3. Use Case executes business logic (`lib/application/accounting/create_transaction_use_case.dart`).
4. Use Case calls a repository interface, resolved to `lib/data/repositories/transaction_repository_impl.dart`.
5. Repo impl uses a DAO (`lib/data/daos/transaction_dao.dart`) against `AppDatabase` (`lib/data/app_database.dart`), field-encrypted via `lib/infrastructure/crypto/`.

### Boot / Initialization Flow

1. `main()` → `WidgetsFlutterBinding.ensureInitialized()` → `ensureNativeLibrary()` (`lib/main.dart:47`).
2. `AppInitializer.initialize()` runs staged boot (`lib/core/initialization/app_initializer.dart:39`):
   - Stage 1: master key + device key pair (data-loss guard: never mint a new key if an encrypted DB already exists).
   - Stage 2: database (`createEncryptedExecutor` → SQLCipher).
   - Stage 3: final `ProviderContainer` with `appDatabaseProvider` override + seeding.
3. Returns `InitResult` (`InitSuccess` / `InitFailure`); failure renders `InitFailureApp` (`lib/core/initialization/init_failure_screen.dart`).
4. `HomePocketApp._initialize()` seeds categories + ensures a default book, captures `_bookId`, then evaluates onboarding + app-lock gates (`lib/main.dart:174`).
5. `_buildHome` gate order: error → loading → onboarding → app-lock → `MainShellScreen(bookId: _bookId!)`.

**State Management:**
- Riverpod 3.x (`@riverpod` codegen). Side-effects (navigation, snackbars, re-bootstrap) use `ref.listen`, never `ref.watch`.
- Active `bookId` is a boot-captured `String? _bookId` in `lib/main.dart`, threaded as a constructor param down the widget tree — there is NO `currentBookIdProvider`.

## Key Abstractions

**Use Case:**
- Purpose: One unit of business logic with an `execute()` method.
- Examples: `lib/application/accounting/create_transaction_use_case.dart`, `ensure_default_book_use_case.dart`, `seed_categories_use_case.dart`.

**Repository (interface + impl):**
- Purpose: Storage-agnostic data access.
- Interface: `lib/features/{f}/domain/repositories/`. Impl: `lib/data/repositories/*_impl.dart`.

**Result<T>:**
- Purpose: Explicit success/error return without throwing across boundaries.
- File: `lib/shared/utils/result.dart` (`Result.success` / `Result.error`).

**AppDatabase / DAO:**
- Purpose: Type-safe SQL over encrypted SQLite.
- Files: `lib/data/app_database.dart`, `lib/data/daos/*.dart`.

## Entry Points

**App bootstrap:**
- Location: `lib/main.dart` (`main()` → `_boot()` → `bootWithInitializerForTesting`).
- Triggers: Flutter runtime.
- Responsibilities: native lib load, staged init, root `MaterialApp`, boot gates, shell mount.

**Test bootstrap:**
- Location: `lib/main.dart` (`bootWithInitializerForTesting`, `@visibleForTesting`).
- Triggers: widget/integration tests injecting a custom `AppInitializer` + `AppRunner`.

## Architectural Constraints

- **Threading:** Single-threaded Dart event loop; async via `Future`/`Stream`. Native crypto/DB work is offloaded through platform channels.
- **Global state:** Active `bookId` is boot-captured in `lib/main.dart` and threaded as a param (not a provider). Gate flags (`_isLocked`, `_needsOnboarding`) live in the root `_HomePocketAppState`.
- **Layer boundaries:** Enforced by `test/architecture/layer_import_rules_test.dart` (scans REAL imports, relative-normalized) for domain/application/infrastructure directions and application→data (only `*_providers.dart` composition roots may import `lib/data/`). `domain_import_rules_test.dart` and `presentation_layer_rules_test.dart` add further guards. NOTE: `import_guard.yaml` deny-mode rules are INERT for intra-project relative imports — do not treat a green `custom_lint` as layer-compliance evidence.
- **Routing:** Built-in `Navigator` / `MaterialPageRoute` + an `IndexedStack` tab shell. NO `go_router` dependency — do not assume GoRouter.
- **Boot-gate completion:** Gate-hosted full-screen flows (onboarding, app-lock) must finish via a gate-owned `setState` flag flip, NEVER root `pushReplacement` (which detaches `_buildHome` and breaks the data-reset refresh path).

## Anti-Patterns

### bookId as a provider

**What happens:** Code assumes a `currentBookIdProvider` (as CLAUDE.md's stale example shows).
**Why it's wrong:** There is no such provider; `bookId` is a boot-captured `String` threaded via constructor params.
**Do this instead:** Accept `bookId` as a constructor parameter; for full-wipe/import refresh, re-bootstrap the app root and call `invalidateAllDataProviders(ref)` (`lib/shared/utils/invalidate_all_data_providers.dart`).

### pushReplacement to leave a boot gate

**What happens:** Onboarding/app-lock completion navigates with `pushReplacement`.
**Why it's wrong:** Detaches the live `'/'` Builder, breaking `_reinitializeAfterDataReset`.
**Do this instead:** Flip the gate flag via `setState` (`_completeOnboarding` / `_completeUnlock` in `lib/main.dart`).

### Application logic inside a feature

**What happens:** Adding `application/`, `infrastructure/`, `data/tables/`, or `data/daos/` under `lib/features/{f}/`.
**Why it's wrong:** Violates the "Thin Feature" rule and layer boundaries.
**Do this instead:** Place use cases in `lib/application/{domain}/`, tech in `lib/infrastructure/`, persistence in `lib/data/`.

## Error Handling

**Strategy:** `Result<T>` at boundaries + typed `InitResult` (Freezed) for boot failures.

**Patterns:**
- Boot failures classified by `InitFailureType` (masterKey, masterKeyMissingWithData, database, seed) → `InitFailureApp` fallback screen.
- Data-loss guard: never mint a new master key when an encrypted DB exists (`app_initializer.dart:59`).
- Provider errors wrapped in `ProviderException` (Riverpod 3); tests unwrap via `.exception`.

## Cross-Cutting Concerns

**Logging:** Privacy-scrubbed; sensitive data never logged (enforced by `test/architecture/production_logging_privacy_test.dart`).
**Validation:** At system boundaries; input validated before persistence.
**Authentication:** App-lock gate (PIN + optional biometric) via `lib/features/applock/` and `lib/infrastructure/security/`; effective only when `appLockEnabled && pinHash != null`.
**Encryption:** 4-layer (SQLCipher DB, ChaCha20-Poly1305 field, AES-256-GCM file, TLS 1.3 + E2EE transport), all via `lib/infrastructure/crypto/`.

---

*Architecture analysis: 2026-07-14*
