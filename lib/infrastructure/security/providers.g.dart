// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Biometric authentication service.
///
/// Uses `keepAlive: true` to ensure the service persists across
/// widget rebuilds, preserving the `_failedAttempts` counter state.

@ProviderFor(biometricService)
final biometricServiceProvider = BiometricServiceProvider._();

/// Biometric authentication service.
///
/// Uses `keepAlive: true` to ensure the service persists across
/// widget rebuilds, preserving the `_failedAttempts` counter state.

final class BiometricServiceProvider
    extends
        $FunctionalProvider<
          BiometricService,
          BiometricService,
          BiometricService
        >
    with $Provider<BiometricService> {
  /// Biometric authentication service.
  ///
  /// Uses `keepAlive: true` to ensure the service persists across
  /// widget rebuilds, preserving the `_failedAttempts` counter state.
  BiometricServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricServiceHash();

  @$internal
  @override
  $ProviderElement<BiometricService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BiometricService create(Ref ref) {
    return biometricService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BiometricService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BiometricService>(value),
    );
  }
}

String _$biometricServiceHash() => r'18210c094d1a72ed9598598ff121847f2a12ad88';

/// Check biometric availability for the current device.

@ProviderFor(biometricAvailability)
final biometricAvailabilityProvider = BiometricAvailabilityProvider._();

/// Check biometric availability for the current device.

final class BiometricAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<BiometricAvailability>,
          BiometricAvailability,
          FutureOr<BiometricAvailability>
        >
    with
        $FutureModifier<BiometricAvailability>,
        $FutureProvider<BiometricAvailability> {
  /// Check biometric availability for the current device.
  BiometricAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricAvailabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<BiometricAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BiometricAvailability> create(Ref ref) {
    return biometricAvailability(ref);
  }
}

String _$biometricAvailabilityHash() =>
    r'b34f08de89a68dabbf6c2f5bf5f031b87e7e647d';

/// Secure storage service — iOS Keychain / Android Keystore wrapper.

@ProviderFor(secureStorageService)
final secureStorageServiceProvider = SecureStorageServiceProvider._();

/// Secure storage service — iOS Keychain / Android Keystore wrapper.

final class SecureStorageServiceProvider
    extends
        $FunctionalProvider<
          SecureStorageService,
          SecureStorageService,
          SecureStorageService
        >
    with $Provider<SecureStorageService> {
  /// Secure storage service — iOS Keychain / Android Keystore wrapper.
  SecureStorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secureStorageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secureStorageServiceHash();

  @$internal
  @override
  $ProviderElement<SecureStorageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SecureStorageService create(Ref ref) {
    return secureStorageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecureStorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecureStorageService>(value),
    );
  }
}

String _$secureStorageServiceHash() =>
    r'f44bb5666baebf64786c7d88095a3ba1b215b1d2';

/// Application-layer app-lock service — single source of truth for the lock
/// decision (D-01) and all PIN operations (LOCK-01/06).
///
/// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
/// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
/// biometric service (re-auth, D-05), and the settings repository (toggles).

@ProviderFor(appLockService)
final appLockServiceProvider = AppLockServiceProvider._();

/// Application-layer app-lock service — single source of truth for the lock
/// decision (D-01) and all PIN operations (LOCK-01/06).
///
/// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
/// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
/// biometric service (re-auth, D-05), and the settings repository (toggles).

final class AppLockServiceProvider
    extends $FunctionalProvider<AppLockService, AppLockService, AppLockService>
    with $Provider<AppLockService> {
  /// Application-layer app-lock service — single source of truth for the lock
  /// decision (D-01) and all PIN operations (LOCK-01/06).
  ///
  /// Consumed by the cold-start gate (Plan 11), lock screen (Plan 09), and the
  /// Settings security section (Plan 10). Wires the keychain (pinHash slot), the
  /// biometric service (re-auth, D-05), and the settings repository (toggles).
  AppLockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockServiceHash();

  @$internal
  @override
  $ProviderElement<AppLockService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppLockService create(Ref ref) {
    return appLockService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockService>(value),
    );
  }
}

String _$appLockServiceHash() => r'2170e8bfbef63e945e084abbeaf0e755ae63a0a2';

/// Audit logger — depends on AppDatabase and SecureStorageService.
///
/// NOTE: This provider requires [appDatabaseProvider] to be defined
/// elsewhere (e.g. in app initialization). For now, it uses
/// constructor injection and should be wired during app startup.

@ProviderFor(auditLogger)
final auditLoggerProvider = AuditLoggerProvider._();

/// Audit logger — depends on AppDatabase and SecureStorageService.
///
/// NOTE: This provider requires [appDatabaseProvider] to be defined
/// elsewhere (e.g. in app initialization). For now, it uses
/// constructor injection and should be wired during app startup.

final class AuditLoggerProvider
    extends $FunctionalProvider<AuditLogger, AuditLogger, AuditLogger>
    with $Provider<AuditLogger> {
  /// Audit logger — depends on AppDatabase and SecureStorageService.
  ///
  /// NOTE: This provider requires [appDatabaseProvider] to be defined
  /// elsewhere (e.g. in app initialization). For now, it uses
  /// constructor injection and should be wired during app startup.
  AuditLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLoggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLoggerHash();

  @$internal
  @override
  $ProviderElement<AuditLogger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditLogger create(Ref ref) {
    return auditLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditLogger>(value),
    );
  }
}

String _$auditLoggerHash() => r'd20d2dbc362170585bc01c438bb4783c1bf1eb73';

/// AppDatabase provider - PLACEHOLDER.
///
/// This provider MUST be overridden during app initialization.
/// The placeholder throws to ensure it's properly configured before use.
///
/// ## How to Replace
///
/// In your `AppInitializer` or `main.dart`, override this provider:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // 1. Get master key repository
///   final masterKeyRepo = MasterKeyRepositoryImpl(secureStorage: secureStorage);
///
///   // 2. Initialize master key if needed
///   if (!await masterKeyRepo.hasMasterKey()) {
///     await masterKeyRepo.initializeMasterKey();
///   }
///
///   // 3. Create encrypted database executor
///   final executor = await createEncryptedExecutor(masterKeyRepo);
///   final database = AppDatabase(executor);
///
///   // 4. Override the provider
///   runApp(
///     ProviderScope(
///       overrides: [appDatabaseProvider.overrideWithValue(database)],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ## Dependencies
///
/// - `MasterKeyRepository` from `lib/infrastructure/crypto/repositories/`
/// - `createEncryptedExecutor` from `lib/infrastructure/crypto/database/`
/// AppDatabase provider — concrete keepAlive: true.
///
/// Phase 3 / CRIT-03 fix: replaces the prior `UnimplementedError` placeholder.
/// AppInitializer.initialize() overrides this via `.overrideWithValue(database)`
/// on the production ProviderContainer. Tests use `createTestProviderScope`
/// (test/helpers/test_provider_scope.dart) which always overrides with
/// `AppDatabase.forTesting()`.
///
/// If reached without an override the wiring is broken — fail loud with a
/// diagnostic StateError pointing to AppInitializer.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// AppDatabase provider - PLACEHOLDER.
///
/// This provider MUST be overridden during app initialization.
/// The placeholder throws to ensure it's properly configured before use.
///
/// ## How to Replace
///
/// In your `AppInitializer` or `main.dart`, override this provider:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // 1. Get master key repository
///   final masterKeyRepo = MasterKeyRepositoryImpl(secureStorage: secureStorage);
///
///   // 2. Initialize master key if needed
///   if (!await masterKeyRepo.hasMasterKey()) {
///     await masterKeyRepo.initializeMasterKey();
///   }
///
///   // 3. Create encrypted database executor
///   final executor = await createEncryptedExecutor(masterKeyRepo);
///   final database = AppDatabase(executor);
///
///   // 4. Override the provider
///   runApp(
///     ProviderScope(
///       overrides: [appDatabaseProvider.overrideWithValue(database)],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
///
/// ## Dependencies
///
/// - `MasterKeyRepository` from `lib/infrastructure/crypto/repositories/`
/// - `createEncryptedExecutor` from `lib/infrastructure/crypto/database/`
/// AppDatabase provider — concrete keepAlive: true.
///
/// Phase 3 / CRIT-03 fix: replaces the prior `UnimplementedError` placeholder.
/// AppInitializer.initialize() overrides this via `.overrideWithValue(database)`
/// on the production ProviderContainer. Tests use `createTestProviderScope`
/// (test/helpers/test_provider_scope.dart) which always overrides with
/// `AppDatabase.forTesting()`.
///
/// If reached without an override the wiring is broken — fail loud with a
/// diagnostic StateError pointing to AppInitializer.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// AppDatabase provider - PLACEHOLDER.
  ///
  /// This provider MUST be overridden during app initialization.
  /// The placeholder throws to ensure it's properly configured before use.
  ///
  /// ## How to Replace
  ///
  /// In your `AppInitializer` or `main.dart`, override this provider:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   // 1. Get master key repository
  ///   final masterKeyRepo = MasterKeyRepositoryImpl(secureStorage: secureStorage);
  ///
  ///   // 2. Initialize master key if needed
  ///   if (!await masterKeyRepo.hasMasterKey()) {
  ///     await masterKeyRepo.initializeMasterKey();
  ///   }
  ///
  ///   // 3. Create encrypted database executor
  ///   final executor = await createEncryptedExecutor(masterKeyRepo);
  ///   final database = AppDatabase(executor);
  ///
  ///   // 4. Override the provider
  ///   runApp(
  ///     ProviderScope(
  ///       overrides: [appDatabaseProvider.overrideWithValue(database)],
  ///       child: const MyApp(),
  ///     ),
  ///   );
  /// }
  /// ```
  ///
  /// ## Dependencies
  ///
  /// - `MasterKeyRepository` from `lib/infrastructure/crypto/repositories/`
  /// - `createEncryptedExecutor` from `lib/infrastructure/crypto/database/`
  /// AppDatabase provider — concrete keepAlive: true.
  ///
  /// Phase 3 / CRIT-03 fix: replaces the prior `UnimplementedError` placeholder.
  /// AppInitializer.initialize() overrides this via `.overrideWithValue(database)`
  /// on the production ProviderContainer. Tests use `createTestProviderScope`
  /// (test/helpers/test_provider_scope.dart) which always overrides with
  /// `AppDatabase.forTesting()`.
  ///
  /// If reached without an override the wiring is broken — fail loud with a
  /// diagnostic StateError pointing to AppInitializer.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'88010833b86aa9a841ee56a0ccd57c65b66cf520';
