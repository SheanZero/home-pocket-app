import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/listen_to_push_notifications_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show transactionRepositoryProvider;
import 'package:home_pocket/features/applock/presentation/screens/app_lock_screen.dart';
import 'package:home_pocket/features/applock/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_notification_navigation.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/home/presentation/screens/main_shell_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/infrastructure/crypto/database/encrypted_database.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart' as crypto;
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/device_test_crypto.dart';

// E2E-ONBOARDING / E2E-LEDGER / E2E-BACKUP / E2E-APP-LOCK / E2E-SQLCIPHER

class _DeviceKeyManager extends Fake implements KeyManager {
  @override
  Future<bool> hasKeyPair() async => true;

  @override
  Future<String?> getDeviceId() async => 'device-e2e';
}

class _DeviceSyncEngine extends Fake implements SyncEngine {
  final _status = StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> get statusStream => _status.stream;

  @override
  SyncStatus get currentStatus => const SyncStatus(state: SyncState.noGroup);

  @override
  void configureLifecycleHandlers({
    required JoinRequestLifecycleHandler onJoinRequest,
    required MemberLeftLifecycleHandler onMemberLeft,
    required GroupDissolvedLifecycleHandler onGroupDissolved,
  }) {}

  @override
  void connectPushNotifications(PushNotificationService pushService) {}

  @override
  Future<void> initialize() async {}

  @override
  void onTransactionChanged() {}

  @override
  void dispose() {
    _status.close();
  }
}

class _DevicePushService extends Fake implements PushNotificationService {
  @override
  Future<String?> initialize() async => null;
}

class _NoopPushNavigationUseCase extends Fake
    implements ListenToPushNotificationsUseCase {
  @override
  Stream<PushNavigationIntent> execute() => const Stream.empty();

  @override
  PushNavigationIntent? takePendingIntent() => null;
}

class _MemorySecureStorageService extends Fake implements SecureStorageService {
  String? pinHash;

  @override
  Future<String?> getPinHash() async => pinHash;

  @override
  Future<void> setPinHash(String value) async => pinHash = value;

  @override
  Future<void> deletePinHash() async => pinHash = null;
}

ProviderContainer _createContainer({
  required AppDatabase database,
  required SharedPreferences preferences,
  required DeviceTestMasterKeyRepository masterKey,
  required _MemorySecureStorageService secureStorage,
}) {
  final syncEngine = _DeviceSyncEngine();
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      crypto.masterKeyRepositoryProvider.overrideWithValue(masterKey),
      crypto.keyManagerProvider.overrideWithValue(_DeviceKeyManager()),
      sharedPreferencesProvider.overrideWith((_) async => preferences),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: preferences),
      ),
      secureStorageServiceProvider.overrideWithValue(secureStorage),
      biometricAvailabilityProvider.overrideWith(
        (_) async => BiometricAvailability.notSupported,
      ),
      syncEngineProvider.overrideWithValue(syncEngine),
      syncStatusStreamProvider.overrideWith(
        (_) => Stream.value(const SyncStatus(state: SyncState.noGroup)),
      ),
      pushNotificationServiceProvider.overrideWithValue(_DevicePushService()),
      familySyncNotificationNavigationProvider.overrideWith(
        (_) => FamilySyncNotificationNavigationController(
          _NoopPushNavigationUseCase(),
        ),
      ),
      currentLocaleProvider.overrideWith((_) async => const Locale('ja')),
    ],
  );
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpApp(
  WidgetTester tester,
  ProviderContainer container, {
  required String bootId,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: app.HomePocketApp(key: ValueKey('device-e2e-$bootId')),
    ),
  );
}

Future<void> _unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(ensureNativeLibrary);

  testWidgets(
    'fresh onboarding -> ledger -> encrypted backup restore -> cold PIN boot',
    (tester) async {
      SharedPreferences.setMockInitialValues(const {'language': 'ja'});
      final preferences = await SharedPreferences.getInstance();
      final masterKey = DeviceTestMasterKeyRepository();
      final secureStorage = _MemorySecureStorageService();
      final root = Directory(
        '${(await getTemporaryDirectory()).path}/home-pocket-device-e2e-'
        '${DateTime.now().microsecondsSinceEpoch}',
      );
      await root.create(recursive: true);
      final databaseFile = File('${root.path}/critical-journey.db');

      AppDatabase? database;
      ProviderContainer? container;
      try {
        database = AppDatabase(
          await createEncryptedExecutorAtFileForTesting(
            masterKey,
            databaseFile,
          ),
        );
        container = _createContainer(
          database: database,
          preferences: preferences,
          masterKey: masterKey,
          secureStorage: secureStorage,
        );

        await _pumpApp(tester, container, bootId: 'fresh');
        await _pumpUntilFound(tester, find.byType(OnboardingFlowScreen));

        await tester.tap(find.widgetWithText(TextButton, 'スキップ').first);
        await _pumpUntilFound(tester, find.byType(OnboardingSettingsScreen));
        await tester.enterText(find.byType(TextField).first, '端末テスト');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(
          find.byKey(const ValueKey('onboarding-confirm-label')),
        );
        await _pumpUntilFound(tester, find.byType(MainShellScreen));

        final shell = tester.widget<MainShellScreen>(
          find.byType(MainShellScreen),
        );
        final bookId = shell.bookId;

        await tester.tap(find.byKey(const ValueKey('home-bottom-nav-fab')));
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('manual-one-step-screen')),
        );
        await _pumpUntilFound(
          tester,
          find.byKey(const ValueKey('smart-key-action')),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byKey(const ValueKey('smart-key-1')));
        await tester.tap(find.byKey(const ValueKey('smart-key-2')));
        await tester.tap(find.byKey(const ValueKey('smart-key-3')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byKey(const ValueKey('smart-key-action')));
        await _pumpUntilFound(tester, find.byType(MainShellScreen));

        final transactionRepository = container.read(
          transactionRepositoryProvider,
        );
        final created = await transactionRepository.findAllByBook(bookId);
        expect(created, hasLength(1));
        expect(created.single.amount, 123);

        await _unmountApp(tester);

        final exported = await container
            .read(exportBackupUseCaseProvider)
            .execute(
              bookId: bookId,
              password: 'device-e2e-password',
              deviceId: 'device-e2e',
              appVersion: 'device-e2e',
              outputDirectory: root,
            );
        expect(exported.isSuccess, isTrue);
        final backupFile = exported.data;
        expect(backupFile, isNotNull);
        expect(await backupFile!.exists(), isTrue);
        expect(await backupFile.length(), greaterThan(0));

        await transactionRepository.deleteAllByBook(bookId);
        expect(await transactionRepository.findAllByBook(bookId), isEmpty);

        final imported = await container
            .read(importBackupUseCaseProvider)
            .execute(backupFile: backupFile, password: 'device-e2e-password');
        expect(imported.isSuccess, isTrue);
        final restored = await transactionRepository.findAllByBook(bookId);
        expect(restored, hasLength(1));
        expect(restored.single.amount, 123);

        final appLock = container.read(appLockServiceProvider);
        await appLock.setPin('1234');
        await appLock.enableLock();

        container.dispose();
        container = null;
        await database.close();
        database = null;

        database = AppDatabase(
          await createEncryptedExecutorAtFileForTesting(
            masterKey,
            databaseFile,
          ),
        );
        final cipherRows = await database
            .customSelect('PRAGMA cipher_version')
            .get();
        expect(cipherRows, isNotEmpty);
        expect(cipherRows.single.data.values.single.toString(), isNotEmpty);

        container = _createContainer(
          database: database,
          preferences: preferences,
          masterKey: masterKey,
          secureStorage: secureStorage,
        );
        await _pumpApp(tester, container, bootId: 'cold-reopen');
        await _pumpUntilFound(tester, find.byType(AppLockScreen));

        for (final digit in ['1', '2', '3', '4']) {
          await tester.tap(find.text(digit));
          await tester.pump(const Duration(milliseconds: 80));
        }
        await _pumpUntilFound(
          tester,
          find.byType(MainShellScreen),
          timeout: const Duration(seconds: 20),
        );

        final reopenedTransactions = await container
            .read(transactionRepositoryProvider)
            .findAllByBook(bookId);
        expect(reopenedTransactions, hasLength(1));
        expect(reopenedTransactions.single.amount, 123);
      } finally {
        await _unmountApp(tester);
        container?.dispose();
        await database?.close();
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
