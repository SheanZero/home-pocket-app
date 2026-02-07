import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/create_transaction_use_case.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  TransactionRepository,
  CategoryRepository,
  HashChainService,
  ClassificationService,
])
import 'create_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockHashChainService mockHashChainService;
  late MockClassificationService mockClassificationService;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockHashChainService = MockHashChainService();
    mockClassificationService = MockClassificationService();

    useCase = CreateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      categoryRepository: mockCategoryRepo,
      hashChainService: mockHashChainService,
      classificationService: mockClassificationService,
    );

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
  });

  group('CreateTransactionUseCase', () {
    final testCategory = Category(
      id: 'cat_food',
      name: 'Food',
      icon: 'restaurant',
      color: '#FF5722',
      level: 1,
      type: TransactionType.expense,
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
      expect(result.data!.currentHash, 'computed_hash_xyz');
      expect(result.data!.prevHash, 'prev_hash_abc');
      verify(mockTransactionRepo.insert(any)).called(1);
    });

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
      when(
        mockCategoryRepo.findById('cat_entertainment'),
      ).thenAnswer(
        (_) async => Category(
          id: 'cat_entertainment',
          name: 'Entertainment',
          icon: 'movie',
          color: '#9C27B0',
          level: 1,
          type: TransactionType.expense,
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
