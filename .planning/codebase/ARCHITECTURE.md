<!-- refreshed: 2026-08-05 -->
# Architecture

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## System Overview

```text
Flutter runtime (`lib/main.dart`)
        │ staged boot and ProviderContainer
        ▼
Presentation: `lib/features/*/presentation/`
        │ Riverpod providers and UI invoke
        ▼
Application: `lib/application/`
        │ use cases depend on domain contracts
        ▼
Domain: `lib/features/*/domain/` ◄── Data: `lib/data/`
                                      │ Drift DAOs/repositories
                                      ▼
Infrastructure: `lib/infrastructure/`
 (crypto, sync, ML, speech, storage, i18n, platform APIs)
                                      │
                                      ▼
                         SQLCipher-backed Drift database
                         `lib/data/app_database.dart` (schema 36)
```

## Component Responsibilities

| Component | Responsibility | File |
|---|---|---|
| Runtime/bootstrap | Native library loading, staged initialization, root app and gate lifecycle | `lib/main.dart` |
| Initialization | Master/device keys, encrypted database, seed and typed failure result | `lib/core/initialization/app_initializer.dart` |
| Presentation shell | Indexed tab shell, navigation, FAB and feature screens/widgets | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| Application services | Cross-feature use cases and orchestration | `lib/application/{domain}/` |
| Domain contracts | Framework-independent models and repository interfaces | `lib/features/{feature}/domain/` |
| Persistence | Drift tables, DAOs, migrations and repository implementations | `lib/data/` |
| Technical adapters | Encryption, secure storage, sync, speech, ML, exchange rates and formatters | `lib/infrastructure/` |

## Pattern Overview

**Overall:** Clean Architecture with thin feature modules and a Riverpod composition root.

**Key Characteristics:**
- Features contain domain contracts and presentation only; application, data and infrastructure remain global.
- Repositories are interfaces in `lib/features/*/domain/repositories/` and implementations in `lib/data/repositories/`.
- Riverpod 3 code generation wires providers; Freezed supplies immutable models; Drift provides typed encrypted persistence.
- Import boundaries are verified by `test/architecture/layer_import_rules_test.dart`, `domain_import_rules_test.dart`, and `presentation_layer_rules_test.dart`.

## Layers

**Presentation:** Flutter screens/widgets/providers under `lib/features/*/presentation/`; depends on application and domain.

**Application:** Use cases and services under `lib/application/`; depends on domain contracts and composition-root provider wiring.

**Domain:** Pure models, services and repository interfaces under `lib/features/*/domain/`; must not import Flutter, Drift or Riverpod.

**Data:** `lib/data/app_database.dart`, `tables/`, `daos/`, and `repositories/`; implements domain contracts and uses infrastructure encryption.

**Infrastructure:** `lib/infrastructure/crypto/`, `sync/`, `security/`, `storage/`, `speech/`, `voice/`, `ml/`, `i18n/`, `exchange_rate/`; wraps platform/technical dependencies.

## Data Flow

### Primary Transaction Request

1. A screen such as `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` invokes a provider.
2. Provider resolves a use case such as `lib/application/accounting/create_transaction_use_case.dart`.
3. Use case calls a domain repository contract.
4. `lib/data/repositories/transaction_repository_impl.dart` delegates to `lib/data/daos/transaction_dao.dart` and `lib/data/app_database.dart`.
5. SQLCipher and field encryption are supplied by `lib/infrastructure/crypto/`.

### Boot Flow

1. `main()` in `lib/main.dart` ensures Flutter/native libraries and calls `AppInitializer.initialize()`.
2. `lib/core/initialization/app_initializer.dart` prepares keys, encrypted Drift executor and seed data.
3. An `UncontrolledProviderScope` mounts the initialized container; onboarding and app-lock gates render before `MainShellScreen`.
4. Data reset/import re-bootstrap the root and invalidate providers via `lib/shared/utils/invalidate_all_data_providers.dart`.

**State Management:** Riverpod providers own feature/application state; boot-captured `bookId` is threaded through widget constructors. Side effects use `ref.listen`.

## Key Abstractions

- **Use case:** `execute()` units in `lib/application/`.
- **Repository:** interface/implementation pairs in `lib/features/*/domain/repositories/` and `lib/data/repositories/`.
- **Result:** explicit success/error boundary type in `lib/shared/utils/result.dart`.
- **Database/DAO:** encrypted Drift access through `lib/data/app_database.dart` and `lib/data/daos/`.

## Entry Points

**App bootstrap:** `lib/main.dart` (`main`, `_boot`, `bootWithInitializerForTesting`).

**Feature shell:** `lib/features/home/presentation/screens/main_shell_screen.dart`.

**Test bootstrap:** `bootWithInitializerForTesting` in `lib/main.dart` allows injected initializer and runner.

## Architectural Constraints

- Single-threaded Dart event loop; asynchronous I/O and native crypto/database work are awaited.
- Infrastructure must not depend on features, application or data; domain remains framework-independent.
- `bookId` is not a provider; pass it explicitly from the boot root.
- Routing uses Flutter `Navigator` and an `IndexedStack`; no GoRouter dependency is present.
- Generated `*.g.dart`/`*.freezed.dart` files are regenerated, never hand-edited.

## Anti-Patterns

### Feature-owned persistence or infrastructure
**What happens:** Tables, DAOs or adapters are added beneath `lib/features/`.
**Why it's wrong:** Violates thin-feature and import-boundary tests.
**Do this instead:** Put them in `lib/data/` or `lib/infrastructure/` and expose contracts from the feature domain.

### Provider-based active book identity
**What happens:** Code invents `currentBookIdProvider`.
**Why it's wrong:** Boot identity is captured in `lib/main.dart`.
**Do this instead:** Thread `bookId` through constructors and re-bootstrap after full data reset.

## Error Handling

**Strategy:** `Result<T>` for operation boundaries and typed `InitResult`/`InitFailureType` for boot failures. Provider failures are wrapped in Riverpod `ProviderException`.

**Patterns:** Never mint a new master key when encrypted data exists; render `lib/core/initialization/init_failure_screen.dart` for unrecoverable boot errors; keep logs privacy-scrubbed.

## Cross-Cutting Concerns

**Logging:** Privacy checks in `test/architecture/production_logging_privacy_test.dart`.
**Validation:** Boundary validation before persistence.
**Authentication:** PIN/biometric app-lock in `lib/features/applock/` and `lib/infrastructure/security/`.
**Encryption:** SQLCipher database, ChaCha20-Poly1305 fields, AES-GCM files and TLS/E2EE sync via `lib/infrastructure/crypto/` and `lib/infrastructure/sync/`.

---

*Architecture analysis: 2026-08-05*
