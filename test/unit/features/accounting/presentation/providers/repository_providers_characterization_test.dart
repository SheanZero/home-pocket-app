import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late AppDatabase testDatabase;
  late _MockKeyManager mockKeyManager;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase.forTesting();
    mockKeyManager = _MockKeyManager();

    // Stub methods used by DeviceIdentityRepositoryImpl
    when(
      () => mockKeyManager.getDeviceId(),
    ).thenAnswer((_) async => 'device-1');
    when(
      () => mockKeyManager.getPublicKey(),
    ).thenAnswer((_) async => 'pub-key');

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDatabase),
        keyManagerProvider.overrideWithValue(mockKeyManager),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group(
    'accounting/repository_providers characterization tests (pre-refactor behavior)',
    () {
      test('bookRepositoryProvider constructs BookRepository', () {
        final repo = container.read(bookRepositoryProvider);
        expect(repo, isA<BookRepository>());
      });

      test('categoryRepositoryProvider constructs CategoryRepository', () {
        final repo = container.read(categoryRepositoryProvider);
        expect(repo, isA<CategoryRepository>());
      });

      test(
        'categoryLedgerConfigRepositoryProvider constructs CategoryLedgerConfigRepository',
        () {
          final repo = container.read(categoryLedgerConfigRepositoryProvider);
          expect(repo, isA<CategoryLedgerConfigRepository>());
        },
      );

      test(
        'transactionRepositoryProvider constructs TransactionRepository',
        () {
          final repo = container.read(transactionRepositoryProvider);
          expect(repo, isA<TransactionRepository>());
        },
      );

      test(
        'merchantCategoryPreferenceRepositoryProvider constructs MerchantCategoryPreferenceRepository',
        () {
          final repo = container.read(
            merchantCategoryPreferenceRepositoryProvider,
          );
          expect(repo, isA<MerchantCategoryPreferenceRepository>());
        },
      );

      test(
        'categoryKeywordPreferenceRepositoryProvider constructs CategoryKeywordPreferenceRepository',
        () {
          final repo = container.read(
            categoryKeywordPreferenceRepositoryProvider,
          );
          expect(repo, isA<CategoryKeywordPreferenceRepository>());
        },
      );

      test(
        'deviceIdentityRepositoryProvider constructs DeviceIdentityRepository',
        () {
          final repo = container.read(deviceIdentityRepositoryProvider);
          expect(repo, isA<DeviceIdentityRepository>());
        },
      );

      test('all 7 repository providers return non-null instances', () {
        expect(container.read(bookRepositoryProvider), isNotNull);
        expect(container.read(categoryRepositoryProvider), isNotNull);
        expect(
          container.read(categoryLedgerConfigRepositoryProvider),
          isNotNull,
        );
        expect(container.read(transactionRepositoryProvider), isNotNull);
        expect(
          container.read(merchantCategoryPreferenceRepositoryProvider),
          isNotNull,
        );
        expect(
          container.read(categoryKeywordPreferenceRepositoryProvider),
          isNotNull,
        );
        expect(container.read(deviceIdentityRepositoryProvider), isNotNull);
      });
    },
  );
}
