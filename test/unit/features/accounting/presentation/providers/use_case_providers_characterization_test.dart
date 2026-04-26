import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/application/accounting/ensure_default_book_use_case.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/application/accounting/merchant_category_learning_service.dart';
import 'package:home_pocket/application/accounting/seed_categories_use_case.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/providers.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:home_pocket/application/dual_ledger/resolve_ledger_type_service.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/application/voice/record_category_correction_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_keyword_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/merchant_category_preference_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/providers/use_case_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}

class _MockTransactionRepository extends Mock implements TransactionRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockDeviceIdentityRepository extends Mock
    implements DeviceIdentityRepository {}

class _MockMerchantCategoryPreferenceRepository extends Mock
    implements MerchantCategoryPreferenceRepository {}

class _MockCategoryKeywordPreferenceRepository extends Mock
    implements CategoryKeywordPreferenceRepository {}

class _MockHashChainService extends Mock implements HashChainService {}

class _MockClassificationService extends Mock implements ClassificationService {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockTransactionChangeTracker extends Mock
    implements TransactionChangeTracker {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockCategoryRepository mockCategoryRepo;
  late _MockCategoryLedgerConfigRepository mockLedgerConfigRepo;
  late _MockTransactionRepository mockTransactionRepo;
  late _MockBookRepository mockBookRepo;
  late _MockDeviceIdentityRepository mockDeviceIdentityRepo;
  late _MockMerchantCategoryPreferenceRepository mockMerchantPrefRepo;
  late _MockCategoryKeywordPreferenceRepository mockKeywordPrefRepo;
  late _MockHashChainService mockHashChainService;
  late _MockClassificationService mockClassificationService;
  late _MockSyncEngine mockSyncEngine;
  late _MockTransactionChangeTracker mockChangeTracker;
  late ProviderContainer container;

  setUp(() {
    mockCategoryRepo = _MockCategoryRepository();
    mockLedgerConfigRepo = _MockCategoryLedgerConfigRepository();
    mockTransactionRepo = _MockTransactionRepository();
    mockBookRepo = _MockBookRepository();
    mockDeviceIdentityRepo = _MockDeviceIdentityRepository();
    mockMerchantPrefRepo = _MockMerchantCategoryPreferenceRepository();
    mockKeywordPrefRepo = _MockCategoryKeywordPreferenceRepository();
    mockHashChainService = _MockHashChainService();
    mockClassificationService = _MockClassificationService();
    mockSyncEngine = _MockSyncEngine();
    mockChangeTracker = _MockTransactionChangeTracker();

    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        categoryLedgerConfigRepositoryProvider.overrideWithValue(
          mockLedgerConfigRepo,
        ),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
        bookRepositoryProvider.overrideWithValue(mockBookRepo),
        deviceIdentityRepositoryProvider.overrideWithValue(
          mockDeviceIdentityRepo,
        ),
        merchantCategoryPreferenceRepositoryProvider.overrideWithValue(
          mockMerchantPrefRepo,
        ),
        categoryKeywordPreferenceRepositoryProvider.overrideWithValue(
          mockKeywordPrefRepo,
        ),
        hashChainServiceProvider.overrideWithValue(mockHashChainService),
        classificationServiceProvider.overrideWithValue(
          mockClassificationService,
        ),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        transactionChangeTrackerProvider.overrideWithValue(mockChangeTracker),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'accounting/use_case_providers characterization tests (pre-refactor behavior)',
    () {
      test('createTransactionUseCaseProvider constructs without error', () {
        final uc = container.read(createTransactionUseCaseProvider);
        expect(uc, isA<CreateTransactionUseCase>());
      });

      test('getTransactionsUseCaseProvider constructs without error', () {
        final uc = container.read(getTransactionsUseCaseProvider);
        expect(uc, isA<GetTransactionsUseCase>());
      });

      test('deleteTransactionUseCaseProvider constructs without error', () {
        final uc = container.read(deleteTransactionUseCaseProvider);
        expect(uc, isA<DeleteTransactionUseCase>());
      });

      test('seedCategoriesUseCaseProvider constructs without error', () {
        final uc = container.read(seedCategoriesUseCaseProvider);
        expect(uc, isA<SeedCategoriesUseCase>());
      });

      test('categoryServiceProvider constructs without error', () {
        final svc = container.read(categoryServiceProvider);
        expect(svc, isA<CategoryService>());
      });

      // PRE-DELETION behavior lock:
      // This test captures that resolveLedgerTypeServiceProvider currently
      // constructs without throwing. Plan 04-03 deletes this provider entirely;
      // this test MUST be deleted in Plan 04-03 commit 4 (acceptable churn).
      // ignore: deprecated_member_use_from_same_package
      test(
        'resolveLedgerTypeServiceProvider constructs without throwing (PRE-deletion)',
        () {
          // ignore: deprecated_member_use_from_same_package
          final svc = container.read(resolveLedgerTypeServiceProvider);
          // ignore: deprecated_member_use_from_same_package
          expect(svc, isA<ResolveLedgerTypeService>());
        },
      );

      test('ensureDefaultBookUseCaseProvider constructs without error', () {
        final uc = container.read(ensureDefaultBookUseCaseProvider);
        expect(uc, isA<EnsureDefaultBookUseCase>());
      });

      test(
        'merchantCategoryLearningServiceProvider constructs without error',
        () {
          final svc = container.read(merchantCategoryLearningServiceProvider);
          expect(svc, isA<MerchantCategoryLearningService>());
        },
      );

      test(
        'recordCategoryCorrectionUseCaseProvider constructs without error',
        () {
          final uc = container.read(recordCategoryCorrectionUseCaseProvider);
          expect(uc, isA<RecordCategoryCorrectionUseCase>());
        },
      );

      test('all use case providers return non-null instances', () {
        expect(container.read(createTransactionUseCaseProvider), isNotNull);
        expect(container.read(getTransactionsUseCaseProvider), isNotNull);
        expect(container.read(deleteTransactionUseCaseProvider), isNotNull);
        expect(container.read(seedCategoriesUseCaseProvider), isNotNull);
        expect(container.read(categoryServiceProvider), isNotNull);
        expect(container.read(ensureDefaultBookUseCaseProvider), isNotNull);
        expect(
          container.read(merchantCategoryLearningServiceProvider),
          isNotNull,
        );
        expect(
          container.read(recordCategoryCorrectionUseCaseProvider),
          isNotNull,
        );
      });
    },
  );
}
