import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/application/use_cases/create_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'create_transaction_use_case_test.mocks.dart';

@GenerateMocks([
  TransactionRepository,
  CategoryRepository,
  HashChainService,
])
void main() {
  late CreateTransactionUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockHashChainService mockHashChainService;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockHashChainService = MockHashChainService();

    useCase = CreateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      categoryRepository: mockCategoryRepo,
      hashChainService: mockHashChainService,
    );
  });

  group('CreateTransactionUseCase', () {
    test('should create transaction successfully', () async {
      // Arrange
      final category = Category(
        id: 'cat_food',
        name: '餐饮',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime.now(),
      );

      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => category);

      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('calculated_hash');

      when(mockTransactionRepo.getLatestHash('book_001'))
          .thenAnswer((_) async => 'prev_hash');

      when(mockTransactionRepo.insert(any)).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.amount, 10000);

      verify(mockTransactionRepo.insert(any)).called(1);
    });

    test('should create transaction with note', () async {
      // Arrange
      final category = Category(
        id: 'cat_food',
        name: '餐饮',
        icon: 'restaurant',
        color: '#FF5722',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 1,
        createdAt: DateTime.now(),
      );

      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => category);

      when(
        mockHashChainService.calculateTransactionHash(
          transactionId: anyNamed('transactionId'),
          amount: anyNamed('amount'),
          timestamp: anyNamed('timestamp'),
          previousHash: anyNamed('previousHash'),
        ),
      ).thenReturn('calculated_hash');

      when(mockTransactionRepo.getLatestHash('book_001'))
          .thenAnswer((_) async => null);

      when(mockTransactionRepo.insert(any)).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        note: 'Test note',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.note, 'Test note');
      // Note: Encryption is handled by Repository layer during insert
    });

    test('should return error if category not found', () async {
      // Arrange
      when(mockCategoryRepo.findById('invalid_cat'))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'invalid_cat',
        ledgerType: LedgerType.survival,
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.error, contains('Category not found'));
      verifyNever(mockTransactionRepo.insert(any));
    });
  });
}
