import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../data/app_database.dart';
import '../../infrastructure/crypto/providers.dart';
import '../../infrastructure/crypto/repositories/master_key_repository.dart';
import '../../infrastructure/security/providers.dart';
import 'init_result.dart';

typedef ProviderContainerFactory =
    ProviderContainer Function({List<Override> overrides});

typedef AppDatabaseFactory =
    Future<AppDatabase> Function(MasterKeyRepository masterKeyRepo);

/// Loads the selected sqlite3 Native Asset without opening a database.
typedef NativeLibraryReadiness = Future<void> Function();

/// Whether an encrypted database already exists on disk. Injected so the
/// data-loss guard stays unit-testable without touching path_provider.
typedef EncryptedDatabaseExists = Future<bool> Function();

typedef SeedRunner = Future<void> Function(ProviderContainer container);

/// Cold-start hook that resumes a pending local privacy wipe using the final
/// database-backed container, before device identity and normal bootstrap.
typedef PendingPrivacyWipeResumer =
    Future<void> Function(ProviderContainer container);

class AppInitializer {
  AppInitializer({
    required this._containerFactory,
    required this._databaseFactory,
    required this._databaseExists,
    required this._seedRunner,
    required this.ensureNativeLibrary,
    this._pendingPrivacyWipeResumer,
  });

  final ProviderContainerFactory _containerFactory;
  final AppDatabaseFactory _databaseFactory;
  final EncryptedDatabaseExists _databaseExists;
  final SeedRunner _seedRunner;
  final NativeLibraryReadiness ensureNativeLibrary;
  final PendingPrivacyWipeResumer? _pendingPrivacyWipeResumer;

  Future<InitResult> initialize() async {
    // Initialize intl date formatting data for all locales so that
    // table_calendar day-of-week headers and DateFormatter render correctly
    // in ja/zh/en. Must run before any DateFormatter or NumberFormatter usage.
    await initializeDateFormatting();

    ProviderContainer? initContainer;
    try {
      // Stage 1: Native library. Load the sqlite3 Native Asset before the
      // first ProviderContainer can reach secure storage or database setup.
      try {
        await ensureNativeLibrary();
      } catch (e, st) {
        return InitResult.failure(
          type: InitFailureType.database,
          error: e,
          stackTrace: st,
        );
      }

      // Stage 2: Master key. Device identity is intentionally deferred until
      // a pending privacy wipe has resumed and deleted its durable journal.
      initContainer = _containerFactory();
      final masterKeyRepo = initContainer.read(masterKeyRepositoryProvider);
      late final bool databaseExistedAtLaunch;

      try {
        final hasMasterKey = await masterKeyRepo.hasMasterKey();
        // Capture this before the database factory can create a fresh file.
        // A missing database defines a new installation identity even when
        // iOS Keychain (or restored Android secure storage) retained the old
        // device key pair across uninstall/reinstall.
        databaseExistedAtLaunch = await _databaseExists();
        if (!hasMasterKey) {
          // CRITICAL data-loss guard: a missing master key normally means
          // "first launch", but if an encrypted database already exists the key
          // read failed for another reason (locked device, changed keychain
          // access group, transient keychain error). Generating a new random
          // key here would permanently orphan the existing data, so fail loud
          // instead of overwriting the key.
          if (databaseExistedAtLaunch) {
            return InitResult.failure(
              type: InitFailureType.masterKeyMissingWithData,
              error: const MasterKeyMissingWithExistingDataError(),
            );
          }
          await masterKeyRepo.initializeMasterKey();
        }
      } catch (e, st) {
        return InitResult.failure(
          type: InitFailureType.masterKey,
          error: e,
          stackTrace: st,
        );
      }

      // Stage 2b: Reinstall identity boundary. Rotate only a retained identity;
      // genuine first launch still creates its first identity after pending
      // wipe recovery below. Doing the reinstall rotation before opening the
      // new database makes a failed/partial secure-storage write retryable on
      // the next launch instead of leaving a fresh database that looks old.
      if (!databaseExistedAtLaunch) {
        try {
          final keyManager = initContainer.read(keyManagerProvider);
          if (await keyManager.hasKeyPair()) {
            await keyManager.clearKeys();
            await keyManager.generateDeviceKeyPair();
          }
        } catch (e, st) {
          return InitResult.failure(
            type: InitFailureType.masterKey,
            error: e,
            stackTrace: st,
          );
        }
      }

      // Stage 3: Database
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

      // Stage 4: Final container + pending privacy-wipe recovery. Nothing in
      // normal bootstrap may recreate identity, seed data, start sync/push, or
      // expose routes until this hook succeeds.
      initContainer.dispose();
      initContainer = null;

      final container = _containerFactory(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );

      final resumePendingPrivacyWipe = _pendingPrivacyWipeResumer;
      if (resumePendingPrivacyWipe != null) {
        try {
          await resumePendingPrivacyWipe(container);
        } catch (e, st) {
          container.dispose();
          await database.close();
          return InitResult.failure(
            type: InitFailureType.privacyWipe,
            error: e,
            stackTrace: st,
          );
        }
      }

      // Stage 5: Fresh/current device identity, only after wipe recovery.
      try {
        final keyManager = container.read(keyManagerProvider);
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
        container.dispose();
        await database.close();
        return InitResult.failure(
          type: InitFailureType.masterKey,
          error: e,
          stackTrace: st,
        );
      }

      // Stage 6: Normal seeding.
      try {
        await _seedRunner(container);
      } catch (e, st) {
        container.dispose();
        await database.close();
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
