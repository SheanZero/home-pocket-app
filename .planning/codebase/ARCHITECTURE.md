# Architecture

**Analysis Date:** 2026-04-25

## Pattern Overview

**Overall:** Clean Architecture (5 Layers) — "Thin Feature" variant, where features are thin presentation slices and cross-cutting concerns live in global layers.

**Key Characteristics:**
- Strict layer separation: `Presentation → Application → Domain ← Data ← Infrastructure`
- Domain layer is pure (Dart-only models + repository interfaces, no Flutter, no Drift, no SDK imports)
- Cross-feature concerns (use cases, data persistence, infrastructure) live globally — never inside `lib/features/`
- Repository pattern decouples domain from data sources (Drift/SQLCipher, secure storage, network)
- Riverpod (`@riverpod` code-gen) used for dependency injection across all layers
- Freezed-based immutability for domain models, JSON serialization wired in
- Local-first, offline-first, encryption-first: SQLCipher AES-256, ChaCha20-Poly1305 field encryption, hash-chain integrity
- App boot sequence in `lib/main.dart` is explicit and ordered — no implicit DI container

## Layers

**Infrastructure Layer:**
- Purpose: Project-wide technology and platform capabilities (encryption, storage, sync transports, ML, formatters)
- Location: `lib/infrastructure/`
- Subdivisions:
  - `lib/infrastructure/crypto/` — `services/key_manager.dart`, `services/field_encryption_service.dart`, `services/hash_chain_service.dart`, `database/encrypted_database.dart`, `repositories/master_key_repository_impl.dart`, `repositories/key_repository_impl.dart`, `repositories/encryption_repository_impl.dart`, `models/device_key_pair.dart`, `models/chain_verification_result.dart`, `providers.dart`
  - `lib/infrastructure/security/` — `secure_storage_service.dart`, `biometric_service.dart`, `audit_logger.dart`, `models/audit_log_entry.dart`, `models/auth_result.dart`, `providers.dart`
  - `lib/infrastructure/sync/` — `websocket_service.dart`, `relay_api_client.dart`, `push_notification_service.dart`, `apns_push_messaging_client.dart`, `sync_scheduler.dart`, `sync_lifecycle_observer.dart`, `sync_queue_manager.dart`, `e2ee_service.dart`, `websocket_connection_state.dart`
  - `lib/infrastructure/ml/` — `merchant_database.dart`
  - `lib/infrastructure/i18n/` — `formatters/date_formatter.dart`, `formatters/number_formatter.dart`, `models/locale_settings.dart`
  - `lib/infrastructure/speech/` — `speech_recognition_service.dart`
  - `lib/infrastructure/category/` — `category_service.dart`
- Depends on: External SDKs (cryptography, drift, sqlcipher_flutter_libs, flutter_secure_storage, local_auth, web_socket_channel, firebase_messaging, speech_to_text), Domain models for Freezed annotations
- Used by: `lib/data/` (encryption services), `lib/application/` (sync, key services), `lib/features/*/presentation/` (formatters)

**Data Layer:**
- Purpose: Persistence — Drift table definitions, DAOs, and repository implementations for every domain repository interface
- Location: `lib/data/`
- Contains:
  - `lib/data/app_database.dart` — Drift `@DriftDatabase` aggregation (schema version 14, 11 tables, full migration ladder for v3→v14)
  - `lib/data/tables/` — All 11 Drift table definitions (`books_table.dart`, `categories_table.dart`, `transactions_table.dart`, `category_keyword_preferences_table.dart`, `category_ledger_configs_table.dart`, `groups_table.dart`, `group_members_table.dart`, `merchant_category_preferences_table.dart`, `sync_queue_table.dart`, `user_profiles_table.dart`, `audit_logs_table.dart`)
  - `lib/data/daos/` — Type-safe SQL accessors (`transaction_dao.dart`, `category_dao.dart`, `book_dao.dart`, `analytics_dao.dart`, `group_dao.dart`, `group_member_dao.dart`, `sync_queue_dao.dart`, etc.)
  - `lib/data/repositories/` — Concrete `*_repository_impl.dart` classes implementing domain interfaces (e.g., `transaction_repository_impl.dart`, `book_repository_impl.dart`, `category_repository_impl.dart`, `group_repository_impl.dart`, `sync_repository_impl.dart`, `analytics_repository_impl.dart`, `user_profile_repository_impl.dart`, `settings_repository_impl.dart`, `device_identity_repository_impl.dart`, `merchant_category_preference_repository_impl.dart`, `category_keyword_preference_repository_impl.dart`, `category_ledger_config_repository_impl.dart`)
- Depends on: Drift, `lib/features/*/domain/` (repository interfaces + models), `lib/infrastructure/crypto/services/field_encryption_service.dart` (for `note` field encryption in `TransactionRepositoryImpl`)
- Used by: `lib/application/` (use cases call repositories) and feature repository providers in `lib/features/*/presentation/providers/repository_providers.dart`

**Domain Layer:**
- Purpose: Business entities (Freezed models) and repository contracts — the pure core
- Location: `lib/features/{feature}/domain/`
- Contains: ONLY `models/` (Freezed `@freezed` classes with `.freezed.dart`/`.g.dart` parts) and `repositories/` (abstract Dart interfaces)
- Examples: `lib/features/accounting/domain/models/transaction.dart`, `lib/features/accounting/domain/repositories/transaction_repository.dart`, `lib/features/accounting/domain/models/category.dart`, `lib/features/family_sync/domain/models/group.dart`, `lib/features/settings/domain/models/app_settings.dart`
- Depends on: NOTHING from outer layers — only Dart core, `freezed_annotation`, `json_annotation`
- Used by: `lib/data/repositories/` (implements interfaces), `lib/application/` (consumes models), `lib/features/*/presentation/` (display models)

**Application Layer:**
- Purpose: Global business logic — Use Cases and cross-feature services. Lives at `lib/application/{domain}/`, NOT inside features (Thin Feature rule)
- Location: `lib/application/`
- Subdivisions:
  - `lib/application/accounting/` — `create_transaction_use_case.dart`, `get_transactions_use_case.dart`, `delete_transaction_use_case.dart`, `seed_categories_use_case.dart`, `ensure_default_book_use_case.dart`, `merchant_category_learning_service.dart`, `category_service.dart`
  - `lib/application/dual_ledger/` — `classification_service.dart`, `rule_engine.dart`, `resolve_ledger_type_service.dart`, `classification_result.dart`, `providers.dart` (use case wiring)
  - `lib/application/family_sync/` — `sync_engine.dart`, `sync_orchestrator.dart`, `push_sync_use_case.dart`, `pull_sync_use_case.dart`, `full_sync_use_case.dart`, `apply_sync_operations_use_case.dart`, `create_group_use_case.dart`, `join_group_use_case.dart`, `confirm_join_use_case.dart`, `confirm_member_use_case.dart`, `rename_group_use_case.dart`, `handle_group_dissolved_use_case.dart`, `handle_member_left_use_case.dart`, `check_group_validity_use_case.dart`, `transaction_change_tracker.dart`, `shadow_book_service.dart`, `sync_avatar_use_case.dart`
  - `lib/application/voice/` — `voice_text_parser.dart`, `parse_voice_input_use_case.dart`, `fuzzy_category_matcher.dart`, `voice_satisfaction_estimator.dart`, `record_category_correction_use_case.dart`, `levenshtein.dart`
  - `lib/application/analytics/` — `get_monthly_report_use_case.dart`, `get_expense_trend_use_case.dart`, `get_budget_progress_use_case.dart`, `demo_data_service.dart`
  - `lib/application/settings/` — `export_backup_use_case.dart`, `import_backup_use_case.dart`, `clear_all_data_use_case.dart`
  - `lib/application/profile/` — `get_user_profile_use_case.dart`, `save_user_profile_use_case.dart`
- Depends on: Domain interfaces (repositories) + Domain models, infrastructure services (e.g., `HashChainService`, `FieldEncryptionService`), `lib/shared/utils/result.dart` for error envelopes
- Used by: `lib/features/*/presentation/providers/use_case_providers.dart` (Riverpod wiring) — never directly imported from widgets

**Presentation Layer:**
- Purpose: UI screens, widgets, and Riverpod providers per feature
- Location: `lib/features/{feature}/presentation/`
- Contains: `screens/` (entry-level routes), `widgets/` (reusable feature widgets), `providers/` (Riverpod providers wiring repositories + use cases), occasionally `navigation/` and `utils/`
- Examples: `lib/features/accounting/presentation/screens/transaction_entry_screen.dart`, `lib/features/home/presentation/screens/main_shell_screen.dart`, `lib/features/family_sync/presentation/screens/group_management_screen.dart`
- Depends on: Application use cases (via providers), Domain models, Infrastructure formatters, Generated localizations (`S.of(context)`)
- Used by: `lib/main.dart` (root widget tree)

## Data Flow

**Transaction Creation (representative write path):**

1. UI screen `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` collects input via Riverpod-managed form state.
2. Screen calls `ref.read(createTransactionUseCaseProvider).execute(params)` — provider defined in `lib/features/accounting/presentation/providers/use_case_providers.dart`.
3. `CreateTransactionUseCase` (`lib/application/accounting/create_transaction_use_case.dart`) validates input, resolves ledger type via `ClassificationService`, computes hash chain link via `HashChainService`, and delegates persistence to `TransactionRepository`.
4. `TransactionRepositoryImpl` (`lib/data/repositories/transaction_repository_impl.dart`) encrypts the `note` field via `FieldEncryptionService` (ChaCha20-Poly1305), then calls `TransactionDao.insertTransaction(...)`.
5. `TransactionDao` (`lib/data/daos/transaction_dao.dart`) writes through Drift into the SQLCipher-encrypted `transactions` table (`lib/data/tables/transactions_table.dart`).
6. Use case notifies `SyncEngine` (`lib/application/family_sync/sync_engine.dart`) and `TransactionChangeTracker` so the change is queued for P2P relay sync.
7. UI Riverpod streams (e.g., `today_transactions_provider.dart`) re-emit and the screen rebuilds.

**Read Path (transactions list):**

1. `lib/features/home/presentation/providers/today_transactions_provider.dart` watches `transactionRepositoryProvider` + active book id.
2. Repository decrypts the `note` field on read and returns immutable `Transaction` Freezed objects.
3. Widgets consume via `ref.watch(...)` and render with `AppTextStyles.amountLarge` / `NumberFormatter` for locale-aware display.

**State Management:**
- Riverpod 2.6+ with `@riverpod` code generation — every provider has a generated `.g.dart` part file
- `ProviderContainer` is built in `lib/main.dart` with a manual `appDatabaseProvider.overrideWithValue(database)` injection (database is initialized before container)
- Top-level `UncontrolledProviderScope` wraps `HomePocketApp`
- Stream/AsyncValue used pervasively (e.g., `ref.watch(currentLocaleProvider)`, `ref.watch(appSettingsProvider)`)

## Key Abstractions

**Repository Interface (Domain) → Implementation (Data):**
- Purpose: Decouple business logic from persistence so Drift/SQLCipher can be swapped or mocked in tests
- Pattern: Abstract class in `lib/features/{f}/domain/repositories/*.dart` → concrete `*Impl` class in `lib/data/repositories/*_impl.dart`
- Examples:
  - `TransactionRepository` (`lib/features/accounting/domain/repositories/transaction_repository.dart`) → `TransactionRepositoryImpl` (`lib/data/repositories/transaction_repository_impl.dart`)
  - `BookRepository` (`lib/features/accounting/domain/repositories/book_repository.dart`) → `BookRepositoryImpl` (`lib/data/repositories/book_repository_impl.dart`)
  - `GroupRepository` (`lib/features/family_sync/domain/repositories/group_repository.dart`) → `GroupRepositoryImpl` (`lib/data/repositories/group_repository_impl.dart`)
  - `MasterKeyRepository` (`lib/infrastructure/crypto/repositories/master_key_repository.dart`) → `MasterKeyRepositoryImpl` (`lib/infrastructure/crypto/repositories/master_key_repository_impl.dart`) — note crypto repos live INSIDE infrastructure since they wrap secure storage, not Drift

**Use Case Class:**
- Purpose: Single-responsibility unit of business logic with explicit dependencies in the constructor
- Pattern: Class with constructor-injected repositories + an `execute(params)` (or domain-specific) method returning `Result<T>` from `lib/shared/utils/result.dart`
- Example: `CreateTransactionUseCase`, `EnsureDefaultBookUseCase`, `JoinGroupUseCase`, `ExportBackupUseCase`
- Located in `lib/application/{domain}/`

**Freezed Domain Model:**
- Purpose: Immutable data with `copyWith`, equality, and JSON serialization out of the box
- Pattern: `@freezed abstract class X with _$X { const factory X({...}) = _X; factory X.fromJson(...) => _$XFromJson(json); }`
- Examples: `Transaction` (`lib/features/accounting/domain/models/transaction.dart`), `Category` (`lib/features/accounting/domain/models/category.dart`), `AppSettings` (`lib/features/settings/domain/models/app_settings.dart`)

**Result<T> Envelope:**
- Purpose: Typed success/error return value for use cases — no exceptions across the application boundary
- Location: `lib/shared/utils/result.dart`
- Used by: All use cases in `lib/application/`

**Riverpod Provider (`@riverpod`):**
- Purpose: Dependency injection + reactive state
- Pattern: Annotated function/class generates a typed provider; consumers `ref.watch(xProvider)` or `ref.read(xProvider)`
- Two co-located files per feature: `presentation/providers/repository_providers.dart` and `presentation/providers/use_case_providers.dart`

## Entry Points

**App Entry (`main()`):**
- Location: `lib/main.dart`
- Triggers: Flutter framework on app launch
- Responsibilities (executed in strict order before `runApp`):
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. `await ensureNativeLibrary()` — loads SQLCipher native library before any DB access
  3. Create `initContainer = ProviderContainer()` (bootstrap container)
  4. Initialize master key via `masterKeyRepositoryProvider.initializeMasterKey()` if absent
  5. Initialize device key pair via `keyManagerProvider.generateDeviceKeyPair()` if absent; assert non-empty `deviceId`
  6. Build `AppDatabase`: either `NativeDatabase.memory()` (dev flag `_useInMemoryDatabase`) or `createEncryptedExecutor(masterKeyRepo)` (production, SQLCipher)
  7. Dispose `initContainer`; create real `container` with `overrides: [appDatabaseProvider.overrideWithValue(database)]`
  8. `runApp(UncontrolledProviderScope(container, child: HomePocketApp()))`

**App Initialization (post-runApp):**
- `_HomePocketAppState._initialize()` in `lib/main.dart` runs after first frame:
  - `ref.read(seedCategoriesUseCaseProvider).execute()` — seed default categories
  - `ref.read(ensureDefaultBookUseCaseProvider).execute()` — ensure a default book exists
  - `ref.read(syncEngineProvider).initialize()` — install lifecycle observers, open status streams
  - `ref.read(syncEngineProvider).connectPushNotifications(pushService)` — wire APNs/FCM → sync engine
  - `ref.read(getUserProfileUseCaseProvider).execute()` — decide between `ProfileOnboardingScreen` and `MainShellScreen`
- Note: There is currently no `lib/core/initialization/app_initializer.dart` — initialization logic is inline in `lib/main.dart` and `_HomePocketAppState`. If/when refactoring to a dedicated initializer class, place it under `lib/core/initialization/`.

**Initialization Order (CRITICAL):**
```
SQLCipher native lib → MasterKey → DeviceKeyPair (deviceId) → AppDatabase → ProviderContainer → runApp
                                                      ↓
                              (post-runApp) seedCategories → ensureDefaultBook → SyncEngine → push wiring → profile gate
```
Database creation MUST happen after master key initialization because `createEncryptedExecutor` derives the SQLCipher key via HKDF from the master key.

**UI Entry Widgets:**
- `HomePocketApp` (`lib/main.dart`) — root `MaterialApp` with theme, locale, localizations delegates
- `MainShellScreen` (`lib/features/home/presentation/screens/main_shell_screen.dart`) — bottom-nav shell after onboarding
- `ProfileOnboardingScreen` (`lib/features/profile/presentation/screens/profile_onboarding_screen.dart`) — first-run profile capture

**Routing:**
- `pubspec.yaml` does NOT currently include `go_router`. Navigation is performed via Flutter's built-in `Navigator` and conditional widget swaps in `_buildHome` (`lib/main.dart`). The CLAUDE.md reference to GoRouter reflects the target architecture — when GoRouter is added, place the router config under `lib/core/router/`.

## Error Handling

**Strategy:**
- Application layer use cases return `Result<T>` (`lib/shared/utils/result.dart`) — caller branches on `result.isSuccess`
- Repositories throw on infrastructure failures (DB exceptions, crypto exceptions); use cases catch and convert to `Result.error(message)`
- UI shows user-friendly errors via i18n (`S.of(context).initializationError(error)`) and a fallback `Scaffold` in `_buildHome`
- Crypto + master-key failures use named exceptions (e.g., `MasterKeyNotInitializedException` in `lib/infrastructure/crypto/database/encrypted_database.dart`)

**Patterns:**
- `try/catch` in `_HomePocketAppState._initialize()` captures bootstrap failures into `_error` state for the fallback screen
- `dev.log(..., name: 'AppInit' | 'DataFlow' | ...)` for structured local logging — never `print`
- Audit logging of security-sensitive operations through `lib/infrastructure/security/audit_logger.dart`

## Cross-Cutting Concerns

**Logging:** `dart:developer` `log()` with named channels (`AppInit`, `DataFlow`, etc.) — see `lib/main.dart` and `lib/data/repositories/transaction_repository_impl.dart`. No third-party logger. Sensitive values (encryption keys, plaintext where avoidable) are truncated via `_trunc(...)` helpers.

**Validation:** Use cases validate at the application boundary (e.g., `CreateTransactionUseCase` checks amount/category existence before persisting). Domain models are constructed via Freezed factories — required fields enforced at compile time.

**Authentication & Identity:**
- Device identity: Ed25519 key pair from `KeyManager` (`lib/infrastructure/crypto/services/key_manager.dart`)
- User unlock: Biometric via `BiometricService` (`lib/infrastructure/security/biometric_service.dart`)
- Secure storage: `flutter_secure_storage` wrapped in `SecureStorageService` (`lib/infrastructure/security/secure_storage_service.dart`) — direct SDK access is forbidden

**Encryption:**
- Database: SQLCipher AES-256-CBC, PBKDF2-HMAC-SHA512 256k iterations, key from HKDF (`lib/infrastructure/crypto/database/encrypted_database.dart`)
- Field: ChaCha20-Poly1305 via `FieldEncryptionService` (`lib/infrastructure/crypto/services/field_encryption_service.dart`) — applied transparently inside `TransactionRepositoryImpl` for the `note` column
- Integrity: SHA-256 hash chain via `HashChainService` (`lib/infrastructure/crypto/services/hash_chain_service.dart`) — every `Transaction` carries `prevHash` + `currentHash`

**Localization:**
- ARB-driven, generated class `S` in `lib/generated/app_localizations.dart`
- `S.of(context).<key>` everywhere, no hardcoded user-facing strings
- Locale source: `currentLocaleProvider` (`lib/features/settings/presentation/providers/locale_provider.dart`)
- Formatters: `DateFormatter` and `NumberFormatter` in `lib/infrastructure/i18n/formatters/`

**Theming:** `AppTheme.light` / `AppTheme.dark` from `lib/core/theme/app_theme.dart`; color tokens in `lib/core/theme/app_colors.dart` and `lib/core/theme/app_theme_colors.dart`; tabular-figure amount styles in `lib/core/theme/app_text_styles.dart`.

**Sync:** Push (APNs/FCM) → `SyncEngine` (`lib/application/family_sync/sync_engine.dart`) → relay over `WebSocketService` (`lib/infrastructure/sync/websocket_service.dart`) and `RelayApiClient` (`lib/infrastructure/sync/relay_api_client.dart`); E2EE on the wire via `E2EEService` (`lib/infrastructure/sync/e2ee_service.dart`).

---

*Architecture analysis: 2026-04-25*
