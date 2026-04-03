import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/device_identity_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  TransactionRepository,
  BookRepository,
  CategoryRepository,
  DeviceIdentityRepository,
  HashChainService,
  ClassificationService,
  SyncTriggerService,
])
import 'create_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockTransactionRepo;
  late MockBookRepository mockBookRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockDeviceIdentityRepository mockDeviceIdentityRepo;
  late MockHashChainService mockHashChainService;
  late MockClassificationService mockClassificationService;
  late MockSyncTriggerService mockSyncTriggerService;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockBookRepo = MockBookRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockDeviceIdentityRepo = MockDeviceIdentityRepository();
    mockHashChainService = MockHashChainService();
    mockClassificationService = MockClassificationService();
    mockSyncTriggerService = MockSyncTriggerService();

    useCase = CreateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      bookRepository: mockBookRepo,
      categoryRepository: mockCategoryRepo,
      deviceIdentityRepository: mockDeviceIdentityRepo,
      hashChainService: mockHashChainService,
      classificationService: mockClassificationService,
      syncTriggerService: mockSyncTriggerService,
    );

    when(
      mockDeviceIdentityRepo.getDeviceId(),
    ).thenAnswer((_) async => 'device_test_001');

    // Default classification stub: survival
    when(
      mockClassificationService.classify(
        categoryId: anyNamed('categoryId'),
        merchant: anyNamed('merchant'),
        note: anyNamed('note'),
      ),
    ).thenAnswer(
      (_) async => const ClassificationResult(
        ledgerType: LedgerType.survival,
        confidence: 1.0,
        method: ClassificationMethod.rule,
        reason: 'Default stub',
      ),
    );
    when(
      mockSyncTriggerService.onTransactionCreated(any),
    ).thenAnswer((_) async {});
    when(mockBookRepo.findById(any)).thenAnswer(
      (_) async => Book(
        id: 'book_001',
        name: 'Main Book',
        currency: 'JPY',
        deviceId: 'device_test_001',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  group('CreateTransactionUseCase', () {
    final testCategory = Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: '#FF5722',
      level: 1,
      isSystem: true,
      sortOrder: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    test('successfully creates a transaction with hash chain', () async {
      when(
        mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => 'prev_hash_abc');
      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('computed_hash_xyz');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1500,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.amount, 1500);
      expect(result.data!.categoryId, 'cat_food');
      expect(result.data!.deviceId, 'device_test_001');
      expect(result.data!.currentHash, 'computed_hash_xyz');
      expect(result.data!.prevHash, 'prev_hash_abc');
      verify(mockTransactionRepo.insert(any)).called(1);
      // Sync trigger is fire-and-forget — wait for microtask to complete.
      await Future<void>.delayed(Duration.zero);
      verify(mockSyncTriggerService.onTransactionCreated(any)).called(1);
    });

    test(
      'pushes sync payload with source book metadata after successful create',
      () async {
        when(
          mockCategoryRepo.findById('cat_food'),
        ).thenAnswer((_) async => testCategory);
        when(
          mockTransactionRepo.getLatestHash('book_001'),
        ).thenAnswer((_) async => 'prev_hash_abc');
        when(
          mockHashChainService.calculateTransactionHash(
            transactionId: anyNamed('transactionId'),
            amount: anyNamed('amount'),
            timestamp: anyNamed('timestamp'),
            previousHash: anyNamed('previousHash'),
          ),
        ).thenReturn('computed_hash_xyz');
        when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

        await useCase.execute(
          CreateTransactionParams(
            bookId: 'book_001',
            amount: 1500,
            type: TransactionType.expense,
            categoryId: 'cat_food',
          ),
        );

        // Sync trigger is fire-and-forget — wait for microtask to complete.
        await Future<void>.delayed(Duration.zero);

        final captured =
            verify(
                  mockSyncTriggerService.onTransactionCreated(captureAny),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['metadata'], {
          'sourceBookId': 'book_001',
          'sourceBookName': 'Main Book',
          'sourceBookType': 'remote_book:book_001',
        });
      },
    );

    test('uses genesis hash when no previous transactions', () async {
      when(
        mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => null);
      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('genesis_hash');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.income,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isSuccess, isTrue);
      verify(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: '0' * 64,
        ),
      ).called(1);
    });

    test('returns error when amount is zero', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 0,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('amount'));
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('returns error when category does not exist', () async {
      when(
        mockCategoryRepo.findById('invalid_cat'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'invalid_cat',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('category'));
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('returns error when deviceId is unavailable', () async {
      when(
        mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(mockDeviceIdentityRepo.getDeviceId()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isError, isTrue);
      expect(result.error, contains('deviceId'));
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('returns error when bookId is empty', () async {
      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: '',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
        ),
      );

      expect(result.isError, isTrue);
      verifyNever(mockTransactionRepo.insert(any));
    });

    test('uses classification service to determine ledgerType', () async {
      when(
        mockClassificationService.classify(
          categoryId: anyNamed('categoryId'),
          merchant: anyNamed('merchant'),
          note: anyNamed('note'),
        ),
      ).thenAnswer(
        (_) async => const ClassificationResult(
          ledgerType: LedgerType.soul,
          confidence: 1.0,
          method: ClassificationMethod.rule,
          reason: 'Entertainment category',
        ),
      );
      when(mockCategoryRepo.findById('cat_entertainment')).thenAnswer(
        (_) async => Category(
          id: 'cat_entertainment',
          name: 'Entertainment',
          icon: 'movie',
          color: '#9C27B0',
          level: 1,
          isSystem: true,
          sortOrder: 4,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      when(
        mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => null);
      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('hash_soul');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      final result = await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 2000,
          type: TransactionType.expense,
          categoryId: 'cat_entertainment',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.ledgerType, LedgerType.soul);
    });

    test('passes merchant and note to classification service', () async {
      when(
        mockCategoryRepo.findById('cat_food'),
      ).thenAnswer((_) async => testCategory);
      when(
        mockTransactionRepo.getLatestHash('book_001'),
      ).thenAnswer((_) async => null);
      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('hash_123');
      when(mockTransactionRepo.insert(any)).thenAnswer((_) async {});

      await useCase.execute(
        CreateTransactionParams(
          bookId: 'book_001',
          amount: 500,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          merchant: 'Lawson',
          note: 'Quick lunch',
        ),
      );

      verify(
        mockClassificationService.classify(
          categoryId: 'cat_food',
          merchant: 'Lawson',
          note: 'Quick lunch',
        ),
      ).called(1);
    });
  });
}
