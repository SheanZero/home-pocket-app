// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$biometricServiceHash() => r'18210c094d1a72ed9598598ff121847f2a12ad88';

/// Biometric authentication service.
///
/// Uses `keepAlive: true` to ensure the service persists across
/// widget rebuilds, preserving the `_failedAttempts` counter state.
///
/// Copied from [biometricService].
@ProviderFor(biometricService)
final biometricServiceProvider = Provider<BiometricService>.internal(
  biometricService,
  name: r'biometricServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BiometricServiceRef = ProviderRef<BiometricService>;
String _$biometricAvailabilityHash() =>
    r'b34f08de89a68dabbf6c2f5bf5f031b87e7e647d';

/// Check biometric availability for the current device.
///
/// Copied from [biometricAvailability].
@ProviderFor(biometricAvailability)
final biometricAvailabilityProvider =
    AutoDisposeFutureProvider<BiometricAvailability>.internal(
      biometricAvailability,
      name: r'biometricAvailabilityProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$biometricAvailabilityHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BiometricAvailabilityRef =
    AutoDisposeFutureProviderRef<BiometricAvailability>;
String _$secureStorageServiceHash() =>
    r'f44bb5666baebf64786c7d88095a3ba1b215b1d2';

/// Secure storage service — iOS Keychain / Android Keystore wrapper.
///
/// Copied from [secureStorageService].
@ProviderFor(secureStorageService)
final secureStorageServiceProvider =
    AutoDisposeProvider<SecureStorageService>.internal(
      secureStorageService,
      name: r'secureStorageServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$secureStorageServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecureStorageServiceRef = AutoDisposeProviderRef<SecureStorageService>;
String _$auditLoggerHash() => r'd20d2dbc362170585bc01c438bb4783c1bf1eb73';

/// Audit logger — depends on AppDatabase and SecureStorageService.
///
/// NOTE: This provider requires [appDatabaseProvider] to be defined
/// elsewhere (e.g. in app initialization). For now, it uses
/// constructor injection and should be wired during app startup.
///
/// Copied from [auditLogger].
@ProviderFor(auditLogger)
final auditLoggerProvider = AutoDisposeProvider<AuditLogger>.internal(
  auditLogger,
  name: r'auditLoggerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$auditLoggerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuditLoggerRef = AutoDisposeProviderRef<AuditLogger>;
String _$appDatabaseHash() => r'f6a5a69f8759ef73fd1fc22c5bd65764f0ab79d9';

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
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
