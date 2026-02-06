import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

/// Initializes core app services before the app starts
class AppInitializer {
  /// Initialize all required services
  ///
  /// This must be called before runApp() to ensure:
  /// - Database is ready
  /// - Encryption keys are loaded
  /// - Secure storage is initialized
  static Future<void> initialize(ProviderContainer container) async {
    try {
      // 1. Initialize key manager (loads or generates device keys)
      final keyManager = container.read(keyManagerProvider);
      final hasKeys = await keyManager.hasKeyPair();

      if (!hasKeys) {
        // Generate device key pair on first launch
        await keyManager.generateDeviceKeyPair();
      }

      // 2. Initialize database (ensures schema is up to date)
      final database = container.read(appDatabaseProvider);

      // Run a simple query to verify database is ready
      await database.customSelect('SELECT 1').get();

      print('✅ App initialization complete');
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print(stackTrace);
      rethrow;
    }
  }
}
