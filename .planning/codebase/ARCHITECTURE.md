<!-- refreshed: 2026-07-05 -->
# Architecture

**Analysis Date:** 2026-07-05

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
│                Application (Use Cases / Services)            │
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
                            │  voice / security / i18n /       │
                            │  exchange_rate / category        │
                            │  `lib/infrastructure/`           │
                            └──────────────────────────────────┘
```

**Boot gate chain** (`HomePocketApp._buildHome`, `lib/main.dart`): the root widget renders exactly one screen per frame, decided by four sequential gates:

```text
error? ─▶ InitFailure/Error scaffold
  │no
  ▼
!initialized? ─▶ CircularProgressIndicator (loading)
  │no
  ▼
needsOnboarding? ─▶ OnboardingFlowScreen
  │no
  ▼
isLocked? ─▶ AppLockScreen (PIN / biometric)
  │no
  ▼
MainShellScreen(bookId)   ← the tab shell
```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Bootstrap | Load native libs, run AppInitializer, mount root widget | `lib/main.dart` |
| AppInitializer | Ordered init: master key → device key → DB → container | `lib/core/initialization/app_initializer.dart` |
| Root widget | Theme/locale wiring, seed run, onboarding + app-lock gate routing, privacy mask | `lib/main.dart` (`HomePocketApp`) |
| Tab shell | IndexedStack of Home/List/Analytics/Shopping + center-FAB bottom bar | `lib/features/home/presentation/screens/main_shell_screen.dart` |
| Database | Drift `@DriftDatabase`, 15 tables, schema v23, migrations | `lib/data/app_database.dart` |
| Encryption | SQLCipher executor, encrypted DB existence guard | `lib/infrastructure/crypto/database/encrypted_database.dart` |
| App-lock observer | Lifecycle relock + app-switcher privacy mask | `lib/infrastructure/security/app_lock_lifecycle_observer.dart` |
| Repositories | Concrete data access over DAOs | `lib/data/repositories/*_impl.dart` |
| Use Cases | Global business logic per domain | `lib/application/{domain}/*_use_case.dart` |

## Pattern Overview

**Overall:** 5-layer Clean Architecture with a "Thin Feature" rule.

**Key Characteristics:**
- Domain (interfaces + models) is independent; outer layers depend inward.
- Application layer is GLOBAL at `lib/application/`, never nested inside a feature.
- Features hold ONLY `domain/` (models + repository interfaces) and `presentation/`.
- Infrastructure owns all technology/platform capability (crypto, ML, sync, speech, voice numerals, security, i18n formatters, exchange-rate client, category locale).
- Layer direction is enforced by an **arch test that resolves relative imports** (`test/architecture/layer_import_rules_test.dart`), NOT by the `import_guard.yaml` deny rules — see Architectural Constraints.

## Layers

**Presentation:**
- Purpose: UI + Riverpod state wiring.
- Location: `lib/features/{feature}/presentation/` (screens/, widgets/, providers/, sometimes utils/).
- Depends on: Application use cases via providers.
- Used by: the Flutter runtime / `MaterialApp`.

**Application:**
- Purpose: Use Cases + cross-feature business services.
- Location: `lib/application/{domain}/` — 12 domains: accounting, analytics, currency, family_sync, i18n, list, profile, security, seed, settings, shopping_list, voice.
- Depends on: Domain repository interfaces + Infrastructure.
- 61 use case classes total (`*_use_case.dart`), plus services (e.g. `app_lock_service.dart`, `sync_engine.dart`, `voice_text_parser.dart`).

**Domain:**
- Purpose: Repository interfaces + immutable models (Freezed).
- Location: `lib/features/{feature}/domain/` (ONLY models/ + repositories/, sometimes services/ for pure logic like the voice reconciler).
- Depends on: nothing (independent core). 16 repository interfaces.

**Data:**
- Purpose: Drift tables, DAOs, repository implementations.
- Location: `lib/data/` — `tables/` (15), `daos/` (14), `repositories/` (16 impls), `app_database.dart`.
- Implements: Domain repository interfaces.

**Infrastructure:**
- Purpose: Technology wrappers.
- Location: `lib/infrastructure/` — crypto, ml, category, exchange_rate, i18n, security, speech, voice, sync.
- Note: crypto keeps its OWN repository interface+impl pairs under `crypto/repositories/` (master_key, key, encryption) rather than in `lib/data/` — a deliberate exception so key/encryption access stays inside the crypto boundary.

## Data Flow

### Primary Write Path (manual / voice entry)

1. User taps center FAB in `HomeBottomNavBar` → `MainShellScreen` calls `openAddEntry()` (`main_shell_screen.dart:193+`), pushing `ManualOneStepScreen` via `Navigator`/`MaterialPageRoute` (long-press = continuous mode; on the shopping tab the FAB instead pushes `ShoppingItemFormScreen`).
2. Screen provider reads `createTransactionUseCaseProvider` (`lib/application/accounting/create_transaction_use_case.dart`).
3. Use case calls the `TransactionRepository` interface (`lib/features/accounting/domain/repositories/`).
4. Impl `transaction_repository_impl.dart` writes via `transaction_dao.dart` to the encrypted Drift DB.
5. A sync-queue row is enqueued; `SyncEngine` (started in `main.dart`) propagates to family peers.

### Voice Recognition Flow (v1.9+, phases 49–52, repair threading fc167982/791edd44)

1. `voice_input_screen.dart` (in `features/accounting/presentation/screens/`) drives push-to-talk via three mixins: `voice_ptt_session_mixin`, `voice_locale_readiness_mixin`, `voice_recognition_event_handler_mixin`.
2. Speech text comes from `lib/infrastructure/speech/speech_recognition_service.dart`; numerals parsed by `lib/infrastructure/voice/*_numeral_state_machine.dart` (ja/zh) + `application/voice/english_number_words.dart`.
3. `ParseVoiceInputUseCase` (`lib/application/voice/parse_voice_input_use_case.dart`) parses amount/merchant/category. It also computes an `amountRepairCandidate` via `VoiceTextParser.detectConcatRepairCandidate` (concatenated-digit repair, e.g. `5312 → 53102`) and threads ranked `alternates` from the category outcome.
4. Two INDEPENDENT recognizers run: `MerchantRecognizer` and `CategoryRecognizer` (`lib/application/voice/recognition/`). MerchantRecognizer takes ONLY a `MerchantRepository` (DECOUP-01) and ranks over the `merchant_match_keys` table (Phase 49, schema v22+).
5. `RecognitionReconciler` (`lib/features/voice/domain/services/recognition_reconciler.dart`) merges results; the orchestrator applies the D-03 0.85 auto-fill floor — recognizers stay floor-agnostic.
6. Category auto-stamp comes ONLY from the floor-gated `categoryMatch` (never a `merchantCategoryId` fallback — Phase 51 CR-01). The result is a `VoiceParseResult` (Freezed) carrying `amountRepairCandidate` + `alternates` for the presentation layer's repair chips.

### Re-bootstrap After Destructive Data Reset

1. A Settings action (clear-all-data / import-backup) fires `dataResetSignalProvider` (`lib/core/state/data_reset_signal.dart`).
2. `HomePocketApp.build` listens via `ref.listen` (never `ref.watch`) and calls `_reinitializeAfterDataReset()`.
3. That re-runs seed + ensure-default-book, calls `invalidateAllDataProviders(ref)`, re-reads the onboarding + app-lock gate flags, and rebuilds the shell with the fresh `bookId` — no app restart. The gate is finished by flipping a `setState` flag, never `pushReplacement` (keeps the `'/'` Builder attached — see `[[boot-gate-completion-must-flip-flag-not-pushreplacement]]`).

**State Management:** Riverpod 3 with `@riverpod` codegen. Side-effect listeners use `ref.listen` (data-reset signal, `FamilySyncNotificationRouteListener`, sync-status refresh), never `ref.watch`. The privacy mask and relock are driven by synchronous `ValueNotifier`/field caches so they paint in the same frame the app goes inactive (before the OS app-switcher snapshot).

## Key Abstractions

**Repository (interface in Domain, impl in Data):**
- Interfaces: `lib/features/{feature}/domain/repositories/` (16).
- Impls: `lib/data/repositories/*_impl.dart` (16).
- Wired once per feature in `presentation/providers/repository_providers.dart`.
- Exception: crypto repositories live entirely inside `lib/infrastructure/crypto/repositories/` (interface + impl together).

**Use Case:**
- Classes in `lib/application/{domain}/`; providers that wire them live in the feature's `presentation/providers/`.

**Freezed model:**
- Immutable domain models; mutate only via `copyWith`. Examples: `voice_parse_result.dart`, `recognition_outcome.dart`, `merchant_candidate.dart`, `rate_result.dart` (moved to `lib/features/currency/domain/models/`), `app_settings.dart`, `backup_data.dart`.

**Result<T>:**
- Lightweight success/error envelope (`lib/shared/utils/result.dart`): `data`/`error`/`isSuccess`. Use cases return this rather than throwing.

## Entry Points

**`lib/main.dart`:**
- Triggers: app launch.
- Responsibilities: `ensureNativeLibrary()` → `AppInitializer.initialize()` → mount `UncontrolledProviderScope(HomePocketApp)` or `InitFailureApp` fallback. `bootWithInitializerForTesting` is the testable seam.

**`HomePocketApp._initialize()` (`lib/main.dart`):**
- Runs `SeedAllUseCase` (ordering contract, Phase 23 D-14), ensures default book, starts `SyncEngine`, registers `AppLockLifecycleObserver`, wires push notifications, and captures the onboarding + app-lock gate flags (`_needsOnboarding`, `_lockConfigured`, `_isLocked`, `_biometricUnlockEnabled`).

## Architectural Constraints

- **Threading:** Single Dart isolate / event loop; native DB calls via the Drift executor.
- **Init order (CRITICAL):** master key → device key pair → Database → container (DB requires keys). Data-loss guard: if no master key exists but an encrypted DB is already on disk, init fails with `masterKeyMissingWithData` rather than minting a new key (`app_initializer.dart` + `encryptedDatabaseExists`).
- **Global state:** `ProviderContainer` is the single composition root; no module-level mutable singletons. `appDatabaseProvider` is overridden with the constructed database.
- **Active bookId is NOT a provider:** it is a boot-captured `String? _bookId` field in `HomePocketApp`, threaded as a constructor param into `MainShellScreen` and downward (`[[bookid-not-a-provider]]`). CLAUDE.md's `currentBookIdProvider` example is stale.
- **Layer enforcement (CORRECTED):** the per-layer `import_guard.yaml` deny rules match import URIs against `package:home_pocket/...` prefixes verbatim, but this repo enforces `prefer_relative_imports`, so **every deny-mode guard is inert for intra-project imports**. Real enforcement is `test/architecture/layer_import_rules_test.dart`, which resolves relative imports to lib-rooted paths and asserts three rules (infrastructure ⇏ application/feature-presentation; application ⇏ presentation; domain independent). Its allowlist is EMPTY — reverse layer dependencies were removed in P1-2 (commit `e811a219`). The `import_guard.yaml` deny rules DO still work for real `package:` imports — `dart:mirrors` and `package:sqlite3_flutter_libs/**` remain effectively denied. `presentation_layer_rules_test.dart` separately asserts the YAML deny lists are not weakened.
- **Tolerated inward edge:** infrastructure may import `lib/data/` (e.g. `security/providers.dart` → `data/app_database.dart` for the audit logger); the layer test does not forbid infrastructure→data.

## Anti-Patterns

### Trusting `import_guard.yaml` deny rules for intra-project layering
**What happens:** Assuming a `deny: [package:home_pocket/data/**]` entry blocks a relative `import '../../data/...'`.
**Why it's wrong:** custom_lint matches the literal `package:` URI; relative imports slip through, so the guard enforces nothing intra-project.
**Do this instead:** Rely on `layer_import_rules_test.dart` (resolves relative imports). Add a justified path to its `_allowlist` only for a sanctioned exception.

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

### Finishing a boot gate with `pushReplacement`
**What happens:** Onboarding/app-lock completes by pushing the shell onto the root navigator.
**Why it's wrong:** Detaches the `'/'` Builder, breaking the `_reinitializeAfterDataReset` refresh path.
**Do this instead:** Flip the gate's `setState` flag (`_completeOnboarding`, `_completeUnlock`) so the live Builder renders the shell (`[[boot-gate-completion-must-flip-flag-not-pushreplacement]]`).

### Relying on `customIndices` for Drift indexes
**What happens:** Declaring `customIndices` and assuming Drift creates them.
**Why it's wrong:** Drift's migrator does NOT consume that getter — no index is created.
**Do this instead:** Emit explicit `CREATE INDEX IF NOT EXISTS` in onCreate AND onUpgrade (v23 backfilled all declared indices — commit `2cb07b08`).

## Error Handling

**Strategy:** `Result<T>`-style returns for use cases (`isSuccess`/`data`/`error`); fail-loud init via `InitResult.failure` (`init_result.dart`) rendering `InitFailureApp` with a retry.

**Patterns:**
- Init failures surface a dedicated retry screen, never a crash; typed `InitFailureType` (masterKey, masterKeyMissingWithData, database, …).
- Riverpod 3 wraps provider-thrown errors in `ProviderException` (`.exception` holds the inner error).

## Cross-Cutting Concerns

**Logging:** No raw logging of sensitive utterances/keys (no-log discipline); audit trail via `audit_logger`. `avoid_print` lint is on.
**Validation:** At system boundaries (voice transcript, currency, backup import, user input).
**Authentication:** App-lock (PIN via `pin_kdf` + Argon2id, biometric) gate before the shell (`lib/features/applock/`, `lib/infrastructure/security/`); Ed25519 device keys + master key (`lib/infrastructure/crypto/`).
**Privacy:** Opaque `PrivacyMask` overlay painted above `MaterialApp` on app-inactive, driven synchronously to beat the OS app-switcher snapshot.

---

*Architecture analysis: 2026-07-05*
