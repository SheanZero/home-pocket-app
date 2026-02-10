import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/app_database.dart';
import 'audit_logger.dart';
import 'biometric_service.dart';
import 'secure_storage_service.dart';

part 'providers.g.dart';

/// Single source of truth for secure storage instance + platform options.
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
});

/// Biometric authentication service.
///
/// Uses `keepAlive: true` to ensure the service persists across
/// widget rebuilds, preserving the `_failedAttempts` counter state.
@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) {
  return BiometricService();
}

/// Check biometric availability for the current device.
@riverpod
Future<BiometricAvailability> biometricAvailability(Ref ref) async {
  final service = ref.watch(biometricServiceProvider);
  return service.checkAvailability();
}

/// Secure storage service — iOS Keychain / Android Keystore wrapper.
@riverpod
SecureStorageService secureStorageService(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage: storage);
}

/// Audit logger — depends on AppDatabase and SecureStorageService.
///
/// NOTE: This provider requires [appDatabaseProvider] to be defined
/// elsewhere (e.g. in app initialization). For now, it uses
/// constructor injection and should be wired during app startup.
@riverpod
AuditLogger auditLogger(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final storageService = ref.watch(secureStorageServiceProvider);
  return AuditLogger(database: database, storageService: storageService);
}

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
@riverpod
AppDatabase appDatabase(Ref ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden during app initialization.\n'
    'See AppInitializer pattern in lib/main.dart or the docstring above.',
  );
}
