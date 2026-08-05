import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/repository_providers.dart'
    as app_accounting;
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/currency/repository_providers.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart'
    show pushNotificationServiceProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart'
    show syncEngineProvider;
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockTransactionRepository mockTransactionRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late _MockBookRepository mockBookRepo;
  late _MockSettingsRepository mockSettingsRepo;
  late _MockExchangeRateRepository mockExchangeRateRepo;
  late _MockUserProfileRepository mockUserProfileRepo;
  late AppDatabase testDb;
  late ProviderContainer container;

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    mockCategoryRepo = _MockCategoryRepository();
    mockBookRepo = _MockBookRepository();
    mockSettingsRepo = _MockSettingsRepository();
    mockExchangeRateRepo = _MockExchangeRateRepository();
    mockUserProfileRepo = _MockUserProfileRepository();
    testDb = AppDatabase.forTesting();

    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        bookRepositoryProvider.overrideWithValue(mockBookRepo),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        appExchangeRateRepositoryProvider.overrideWithValue(
          mockExchangeRateRepo,
        ),
        userProfileRepositoryProvider.overrideWithValue(mockUserProfileRepo),
        // unitOfWorkProvider reaches the shared AppDatabase for its Drift
        // transaction scope.
        appDatabaseProvider.overrideWithValue(testDb),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDb.close();
  });

  group(
    'settings/backup_providers characterization tests (pre-refactor: all DI providers)',
    () {
      test('exportBackupUseCaseProvider constructs ExportBackupUseCase', () {
        final uc = container.read(exportBackupUseCaseProvider);
        expect(uc, isA<ExportBackupUseCase>());
      });

      test('importBackupUseCaseProvider constructs ImportBackupUseCase', () {
        final uc = container.read(importBackupUseCaseProvider);
        expect(uc, isA<ImportBackupUseCase>());
      });

      test('clearAllDataUseCaseProvider constructs ClearAllDataUseCase', () {
        final uc = container.read(clearAllDataUseCaseProvider);
        expect(uc, isA<ClearAllDataUseCase>());
      });

      test('all 3 backup use case providers return non-null instances', () {
        expect(container.read(exportBackupUseCaseProvider), isNotNull);
        expect(container.read(importBackupUseCaseProvider), isNotNull);
        expect(container.read(clearAllDataUseCaseProvider), isNotNull);
      });

      test(
        'clear-all provider suspends push and sync before a database failure',
        () async {
          final temp = await Directory.systemTemp.createTemp(
            'home-pocket-provider-wipe-',
          );
          addTearDown(() => temp.delete(recursive: true));
          final documents = Directory('${temp.path}/documents')..createSync();
          final support = Directory('${temp.path}/support')..createSync();
          const channel = MethodChannel('plugins.flutter.io/path_provider');
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(channel, (call) async {
            return switch (call.method) {
              'getApplicationDocumentsDirectory' => documents.path,
              'getApplicationSupportDirectory' => support.path,
              _ => null,
            };
          });
          addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

          final database = _MockAppDatabase();
          final secureStorage = _MockSecureStorageService();
          final pushNotifications = _MockPushNotificationService();
          final syncEngine = _MockSyncEngine();
          when(
            database.wipeLocalUserData,
          ).thenAnswer((_) async => throw StateError('database unavailable'));
          when(
            pushNotifications.clearIdentityBoundState,
          ).thenAnswer((_) async {});
          when(syncEngine.suspendForLocalDataWipe).thenAnswer((_) async {});

          final providerContainer = ProviderContainer.test(
            overrides: [
              app_accounting.appAppDatabaseProvider.overrideWithValue(database),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
              secureStorageServiceProvider.overrideWithValue(secureStorage),
              pushNotificationServiceProvider.overrideWithValue(
                pushNotifications,
              ),
              syncEngineProvider.overrideWithValue(syncEngine),
            ],
          );

          final result = await providerContainer
              .read(clearAllDataUseCaseProvider)
              .execute();

          expect(result.isError, isTrue);
          expect(result.error, contains('database unavailable'));
          verifyInOrder([
            pushNotifications.clearIdentityBoundState,
            syncEngine.suspendForLocalDataWipe,
            database.wipeLocalUserData,
          ]);
        },
      );
    },
  );
}
