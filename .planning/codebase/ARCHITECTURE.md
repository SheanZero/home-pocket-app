<!-- refreshed: 2026-06-27 -->
# Architecture

**Analysis Date:** 2026-06-27

## System Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                      Presentation                            │
├──────────────────┬──────────────────┬───────────────────────┤
│  features/{f}/    │  Riverpod 3      │  MaterialApp +        │
│  presentation/    │  @riverpod       │  IndexedStack shell   │
│  `lib/features/`  │  providers       │  `main_shell_screen`  │
└────────┬─────────┴────────┬─────────┴──────────┬────────────┘
         │                  │                     │
         ▼                  ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      Application (Use Cases / Services)      │
│                `lib/application/{domain}/`                    │
└─────────────────────────────┬───────────────────────────────┘
         │ depends on              │ implemented by
         ▼                          ▼
┌──────────────────────────┐   ┌──────────────────────────────┐
│  Domain (interfaces +    │◄──│  Data (tables/daos/repo impl) │
│  models)                 │   │  `lib/data/`                  │
│  `lib/features/{f}/      │   └──────────────┬────────────────┘
│   domain/`               │                  │
└──────────────────────────┘                  ▼
                            ┌──────────────────────────────────┐
                            │  Infrastructure                  │
                            │  crypto / ml / sync / speech /   │
                            │  voice / security / i18n         │
                            │  `lib/infrastructure/`           │
                            └──────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Bootstrap | Load native libs, run AppInitializer, mount root widget | `lib/main.dart` |
| AppInitializer | Ordered init: master key → device key → DB → container | `lib/core/initialization/app_initializer.dart` |
| Root widget | Theme/locale wiring, seed run, onboarding/shell routing | `lib/main.dart` (`HomePocketApp`) |
| Tab shell | IndexedStack of Home/List/Analytics/Settings + FAB | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| Database | Drift `@DriftDatabase`, 15 tables, schema v22, migrations | `lib/data/app_database.dart` |
| Encryption | SQLCipher executor, encrypted DB existence guard | `lib/infrastructure/crypto/database/encrypted_database.dart` |
| Repositories | Concrete data access over DAOs | `lib/data/repositories/*_impl.dart` |
| Use Cases | Global business logic per domain | `lib/application/{domain}/*_use_case.dart` |

## Pattern Overview

**Overall:** 5-layer Clean Architecture with a "Thin Feature" rule.

**Key Characteristics:**
- Domain (interfaces + models) is independent; outer layers depend inward.
- Application layer is GLOBAL at `lib/application/`, never nested inside a feature.
- Features hold ONLY `domain/` (models + repository interfaces) and `presentation/`.
- Infrastructure owns all technology/platform capability (crypto, ML, sync, speech, voice numerals, security, i18n formatters).
- `import_guard.yaml` files at each layer enforce dependency direction (via custom_lint + arch tests).

## Layers

**Presentation:**
- Purpose: UI + Riverpod state wiring.
- Location: `lib/features/{feature}/presentation/` (screens/, widgets/, providers/).
- Depends on: Application use cases via providers.
- Used by: the Flutter runtime / `MaterialApp`.

**Application:**
- Purpose: Use Cases + cross-feature business services.
- Location: `lib/application/{domain}/` — accounting, analytics, currency, family_sync, i18n, list, profile, seed, settings, shopping_list, voice.
- Depends on: Domain repository interfaces + Infrastructure.
- 61 use case classes total.

**Domain:**
- Purpose: Repository interfaces + immutable models (Freezed).
- Location: `lib/features/{feature}/domain/` (ONLY models/ + repositories/).
- Depends on: nothing (independent core).

**Data:**
- Purpose: Drift tables, DAOs, repository implementations.
- Location: `lib/data/` — `tables/` (15), `daos/` (14), `repositories/` (15 impls), `app_database.dart`.
- Implements: Domain repository interfaces.

**Infrastructure:**
- Purpose: Technology wrappers.
- Location: `lib/infrastructure/` — crypto, ml, category, exchange_rate, i18n, security, speech, voice, sync.

## Data Flow

### Primary Write Path (manual / voice entry)

1. User taps FAB → `MainShellScreen` pushes `ManualOneStepScreen` (`main_shell_screen.dart:166+` IndexedStack + Navigator push).
2. Screen provider reads `createTransactionUseCaseProvider` (`lib/application/accounting/create_transaction_use_case.dart`).
3. Use case calls `TransactionRepository` interface (`lib/features/accounting/domain/repositories/`).
4. Impl `transaction_repository_impl.dart` writes via `transaction_dao.dart` to the encrypted Drift DB.
5. Sync queue row enqueued; `SyncEngine` (started in `main.dart`) propagates to family peers.

### Voice Recognition Flow (v1.9, phases 49–52)

1. `voice_input_screen.dart` (in `features/accounting/presentation/screens/`) drives PTT via mixins (`voice_ptt_session_mixin`, `voice_locale_readiness_mixin`, `voice_recognition_event_handler_mixin`).
2. Speech text comes from `lib/infrastructure/speech/speech_recognition_service.dart`; numerals parsed by `lib/infrastructure/voice/*_numeral_state_machine.dart` (ja/zh) + `english_number_words.dart`.
3. `ParseVoiceInputUseCase` (`lib/application/voice/`) parses amount/merchant/category.
4. Two INDEPENDENT recognizers run: `MerchantRecognizer` and `CategoryRecognizer` (`lib/application/voice/recognition/`). MerchantRecognizer takes ONLY a `MerchantRepository` (DECOUP-01) and ranks over the `merchant_match_keys` table (Phase 49, schema v22).
5. `RecognitionReconciler` (`lib/features/voice/domain/services/`) merges results; the orchestrator applies the D-03 0.85 auto-fill floor — recognizers stay floor-agnostic.
6. Category auto-stamp comes ONLY from the floor-gated `categoryMatch` (never `merchantCategoryId` fallback — Phase 51 CR-01).

**State Management:** Riverpod 3 with `@riverpod` codegen. Side-effect listeners use `ref.listen` (e.g. `FamilySyncNotificationRouteListener`, sync-status refresh in `main_shell_screen.dart`), never `ref.watch`.

## Key Abstractions

**Repository (interface in Domain, impl in Data):**
- Interfaces: `lib/features/{feature}/domain/repositories/`.
- Impls: `lib/data/repositories/*_impl.dart` (15).
- Wired once per feature in `presentation/providers/repository_providers.dart`.

**Use Case:**
- Classes in `lib/application/{domain}/`; providers that wire them live in the feature's `presentation/providers/`.

**Freezed model:**
- Immutable domain models; mutate only via `copyWith`. Examples: `voice_parse_result.dart`, `recognition_outcome.dart`, `merchant_candidate.dart`.

## Entry Points

**`lib/main.dart`:**
- Triggers: app launch.
- Responsibilities: `ensureNativeLibrary()` → `AppInitializer.initialize()` → mount `UncontrolledProviderScope(HomePocketApp)` or `InitFailureApp` fallback.

**`HomePocketApp._initialize()` (`lib/main.dart`):**
- Runs `SeedAllUseCase` (ordering contract, Phase 23 D-14), ensures default book, starts `SyncEngine`, wires push notifications, decides onboarding vs `MainShellScreen`.

## Architectural Constraints

- **Threading:** Single Dart isolate / event loop; native DB calls via Drift executor.
- **Init order (CRITICAL):** KeyManager → Database → other services (DB requires keys). Data-loss guard: never mint a new master key when an encrypted DB already exists on disk (`app_initializer.dart` + `encryptedDatabaseExists`).
- **Global state:** `ProviderContainer` is the single composition root; no module-level mutable singletons.
- **Layer enforcement:** `import_guard.yaml` per layer (custom_lint) + arch tests (`domain_import_rules_test.dart`, `provider_graph_hygiene_test.dart`); `dart:mirrors` and `sqlite3_flutter_libs` denied project-wide.

## Anti-Patterns

### Repository provider duplication
**What happens:** Defining the same repository provider in more than one file.
**Why it's wrong:** Splits the source of truth; breaks `provider_graph_hygiene_test.dart`.
**Do this instead:** ONE `repository_providers.dart` per feature; use-case providers reference repos via `ref.watch()`.

### Application logic inside a feature
**What happens:** Adding `application/`, `infrastructure/`, `data/tables/`, or `data/daos/` under `lib/features/{f}/`.
**Why it's wrong:** Violates the Thin Feature rule and dependency direction.
**Do this instead:** Place use cases in `lib/application/{domain}/`, data access in `lib/data/`.

### Merchant fallback for voice category
**What happens:** Stamping category via `?? merchantCategoryId` regardless of confidence.
**Why it's wrong:** Bypasses the 0.85 floor (ADR-012), mis-classifies low-confidence merchants.
**Do this instead:** Auto-stamp only from floor-gated `categoryMatch` (Phase 51 CR-01, `22c62958`).

### Relying on `customIndices` for Drift indexes
**What happens:** Declaring `customIndices` and assuming Drift creates them.
**Why it's wrong:** Drift's migrator does NOT consume that getter — no index is created.
**Do this instead:** Emit explicit `CREATE INDEX IF NOT EXISTS` in onCreate AND onUpgrade (see `_createMerchantIndexes` / `_createShoppingItemIndexes` in `app_database.dart`).

## Error Handling

**Strategy:** Result-style returns for use cases (`isSuccess`/`data`/`error`); fail-loud init via `InitResult.failure` (`init_result.dart`) rendering `InitFailureApp`.

**Patterns:**
- Init failures surface a dedicated retry screen, never a crash.
- Riverpod 3 wraps provider-thrown errors in `ProviderException` (`.exception` holds the inner error).

## Cross-Cutting Concerns

**Logging:** No raw logging of sensitive utterances/keys (V7 no-log discipline); audit trail via `audit_logger`.
**Validation:** At system boundaries (voice transcript, currency, user input).
**Authentication:** Biometric lock + secure storage (`lib/infrastructure/security/`); Ed25519 device keys + master key (`lib/infrastructure/crypto/`).

---

*Architecture analysis: 2026-06-27*
