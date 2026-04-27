import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../infrastructure/crypto/providers.dart';
import '../../infrastructure/crypto/repositories/master_key_repository.dart';
import '../../infrastructure/security/providers.dart';
import 'init_result.dart';

typedef ProviderContainerFactory =
    ProviderContainer Function({List<Override> overrides});

typedef AppDatabaseFactory =
    Future<AppDatabase> Function(MasterKeyRepository masterKeyRepo);

typedef SeedRunner = Future<void> Function(ProviderContainer container);

class AppInitializer {
  AppInitializer({
    required ProviderContainerFactory containerFactory,
    required AppDatabaseFactory databaseFactory,
    required SeedRunner seedRunner,
  }) : _containerFactory = containerFactory,
       _databaseFactory = databaseFactory,
       _seedRunner = seedRunner;

  final ProviderContainerFactory _containerFactory;
  final AppDatabaseFactory _databaseFactory;
  final SeedRunner _seedRunner;

  Future<InitResult> initialize() async {
    ProviderContainer? initContainer;
    try {
      // Stage 1: Master key + device key pair
      initContainer = _containerFactory();
      final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);

      try {
        if (!await masterKeyRepo.hasMasterKey()) {
          await masterKeyRepo.initializeMasterKey();
        }

        final keyManager = initContainer.read(keyManagerProvider);
        if (!await keyManager.hasKeyPair()) {
          await keyManager.generateDeviceKeyPair();
        }

        final deviceId = await keyManager.getDeviceId();
        if (deviceId == null || deviceId.isEmpty) {
          throw StateError(
            'Device ID is not available after key initialization.',
          );
        }
      } catch (e, st) {
        return InitResult.failure(
          type: InitFailureType.masterKey,
          error: e,
          stackTrace: st,
        );
      }

      // Stage 2: Database
      final AppDatabase database;
      try {
        database = await _databaseFactory(masterKeyRepo);
      } catch (e, st) {
        return InitResult.failure(
          type: InitFailureType.database,
          error: e,
          stackTrace: st,
        );
      }

      // Stage 3: Final container + seeding
      initContainer.dispose();
      initContainer = null;

      final container = _containerFactory(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );

      try {
        await _seedRunner(container);
      } catch (e, st) {
        return InitResult.failure(
          type: InitFailureType.seed,
          error: e,
          stackTrace: st,
        );
      }

      return InitResult.success(container: container);
    } catch (e, st) {
      return InitResult.failure(
        type: InitFailureType.unknown,
        error: e,
        stackTrace: st,
      );
    } finally {
      initContainer?.dispose();
    }
  }
}
