<!-- refreshed: 2026-08-08 -->
# Architecture

**Analysis Date:** 2026-08-08

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│ Flutter UI / feature presentation                           │
│ `lib/features/*/presentation`, `lib/shared/widgets`          │
└───────────────┬─────────────────────────────────────────────┘
                ▼
┌─────────────────────────────────────────────────────────────┐
│ Riverpod providers and application use cases                 │
│ `lib/application`, feature `presentation/providers`          │
└───────────────┬─────────────────────────────────────────────┘
                ▼
┌──────────────────────┬──────────────────────────────────────┐
│ Domain contracts      │ Infrastructure/platform services     │
│ `lib/features/*/domain`│ `lib/infrastructure`               │
└───────────────┬──────┴──────────────────────┬───────────────┘
                ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│ Drift repositories, DAOs and encrypted SQLCipher database    │
│ `lib/data`                                                    │
└─────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Bootstrap | Initializes keys, database, recovery, providers, then mounts app | `lib/main.dart`, `lib/core/initialization/app_initializer.dart` |
| Feature presentation | Screens, widgets, navigation-facing state and provider wiring | `lib/features/*/presentation` |
| Application | Cross-feature orchestration and business use cases | `lib/application` |
| Domain | Immutable models and repository interfaces independent of Flutter/Drift | `lib/features/*/domain` |
| Data | Drift tables/DAOs and repository implementations | `lib/data` |
| Infrastructure | Crypto, secure storage, networking, sync, speech and ML adapters | `lib/infrastructure` |
| Core/shared | Router, theme, initialization, constants and reusable widgets/utilities | `lib/core`, `lib/shared` |

## Pattern Overview

**Overall:** Clean Architecture with feature vertical slices and Riverpod dependency injection.

**Key Characteristics:**
- Presentation depends on application/domain contracts through generated Riverpod providers.
- Application coordinates use cases; data implements domain repositories using Drift DAOs.
- Infrastructure is isolated from features and application; encrypted persistence is local-first.
- Freezed models and generated Riverpod/Drift code are tracked outputs, not hand-edited.

## Layers

**Presentation:** Screens, widgets and state providers in `lib/features/{feature}/presentation`; depends on application/domain and localization.

**Application:** Use cases/services in `lib/application`; depends on domain contracts, repositories and infrastructure capabilities.

**Domain:** Models/repository interfaces in `lib/features/{feature}/domain`; no Flutter, Drift, Riverpod or platform SDK imports.

**Data:** Tables, DAOs and repository implementations in `lib/data`; depends on domain and technical infrastructure, never presentation.

**Infrastructure:** Technical adapters in `lib/infrastructure` (crypto, storage, sync, network, speech, ML); must not import features/application/data.

## Data Flow

### Primary Request Path

1. `lib/main.dart` calls `AppInitializer.initialize()` before `runApp()`.
2. `lib/core/initialization/app_initializer.dart` prepares master key, opens `AppDatabase`, resumes privacy wipe, creates device identity, and seeds data.
3. `HomePocketApp` in `lib/main.dart` seeds/ensures a book and configures sync lifecycle.
4. A feature screen reads a generated provider under `lib/features/*/presentation/providers`.
5. The provider constructs an application use case/repository; DAOs in `lib/data/daos` query/write `lib/data/app_database.dart`.
6. Riverpod invalidation/Drift streams rebuild widgets with localized output.

### Persistence and Sync Flow

Business mutations pass through application services and repository implementations such as `lib/data/repositories/transaction_repository_impl.dart`; family operations can be durably written to sync outbox tables in the same Drift transaction, then processed by `lib/infrastructure/sync`.

**State Management:** Riverpod 3 generated providers; immutable Freezed state; database streams for reactive records; `ProviderContainer` is injected through `UncontrolledProviderScope`.

## Key Abstractions

**Repository contracts:** Interfaces such as `lib/features/accounting/domain/repositories/transaction_repository.dart` decouple use cases from Drift.

**Generated provider graph:** Feature `repository_providers.dart` files (for example `lib/features/accounting/presentation/providers/repository_providers.dart`) compose DAOs, implementations and use cases.

**Encrypted database:** `lib/data/app_database.dart` owns schema/migrations; `lib/infrastructure/crypto/database/encrypted_database.dart` creates the SQLCipher executor.

**Result values:** `lib/shared/utils/result.dart` represents expected success/error outcomes without throwing through UI boundaries.

## Entry Points

**Application entry:** `lib/main.dart`; initializes Flutter, boots dependencies and mounts `HomePocketApp`.

**Database entry:** `lib/data/app_database.dart`; Drift schema version 36 and migration strategy.

**Feature entry:** Screens under `lib/features/*/presentation/screens`, reached from the shell/router assembled by the home/settings flows.

## Architectural Constraints

- **Threading:** Flutter UI isolate with asynchronous I/O; Drift/native database and platform services are awaited.
- **Global state:** Provider graph is scoped to the initialized `ProviderContainer`; lifecycle observer state is held by `HomePocketApp`.
- **Circular imports:** Layer import guards in `lib/*/import_guard.yaml` enforce boundaries.
- **Security:** SQLCipher database plus field/file/transport crypto; keys go through established key-manager/secure-storage services.

## Anti-Patterns

### UI-owned persistence

**What happens:** Widgets directly query Drift or construct infrastructure clients.
**Why it's wrong:** Violates layer boundaries and makes state untestable.
**Do this instead:** Add a domain contract, application use case, and provider in `lib/features/{feature}/presentation/providers`.

### Hand-editing generated code

**What happens:** Changes are made to `*.g.dart`, `*.freezed.dart`, or generated localization files.
**Why it's wrong:** Regeneration discards edits and creates inconsistent providers/models.
**Do this instead:** Edit source annotations/ARB and run build_runner or `flutter gen-l10n`.

## Error Handling

**Strategy:** Initialization returns typed `InitResult` failures; use cases return `Result` where expected errors are user-facing; unexpected failures propagate to provider error states.

**Patterns:** Database/key failures are staged and dispose resources; UI uses Riverpod `AsyncValue` and dedicated error widgets; destructive wipe validates schema classification before deleting.

## Cross-Cutting Concerns

**Logging:** Debug-only diagnostic logging; sensitive values are excluded.
**Validation:** Domain/application validation precedes repository writes; architecture tests enforce imports.
**Authentication:** App lock and device identity live in `lib/infrastructure/security` and are initialized before normal routes/sync.

---

*Architecture analysis: 2026-08-08*
