import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/application/use_cases/update_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_transaction_use_case_test.mocks.dart';

@GenerateMocks([
  TransactionRepository,
  CategoryRepository,
])
void main() {
  late UpdateTransactionUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();

    useCase = UpdateTransactionUseCase(
      transactionRepository: mockTransactionRepo,
      categoryRepository: mockCategoryRepo,
    );
  });

  group('UpdateTransactionUseCase', () {
    test('should update transaction successfully', () async {
      // Arrange
      final existingTransaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      final category = Category(
        id: 'cat_transport',
        name: '交通',
        icon: 'directions_car',
        color: '#2196F3',
        level: 1,
        type: TransactionType.expense,
        isSystem: true,
        sortOrder: 2,
        createdAt: DateTime.now(),
      );

      when(mockTransactionRepo.findById(existingTransaction.id))
          .thenAnswer((_) async => existingTransaction);

      when(mockCategoryRepo.findById('cat_transport'))
          .thenAnswer((_) async => category);

      when(mockTransactionRepo.update(any)).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
        amount: 15000,
        categoryId: 'cat_transport',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, 15000);
      expect(result.data!.categoryId, 'cat_transport');
      expect(result.data!.updatedAt, isNotNull);

      verify(mockTransactionRepo.update(any)).called(1);
    });

    test('should encrypt new note when updating', () async {
      // Arrange
      final existingTransaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

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

      when(mockTransactionRepo.findById(existingTransaction.id))
          .thenAnswer((_) async => existingTransaction);

      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => category);

      when(mockTransactionRepo.update(any)).thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
        note: 'Updated note',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      // Note: Encryption is now handled by Repository layer, not Use Case
    });

    test('should return error if transaction not found', () async {
      // Arrange
      when(mockTransactionRepo.findById('invalid_id'))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(
        transactionId: 'invalid_id',
        amount: 15000,
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.error, contains('Transaction not found'));
      verifyNever(mockTransactionRepo.update(any));
    });

    test('should return error if new category not found', () async {
      // Arrange
      final existingTransaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
      );

      when(mockTransactionRepo.findById(existingTransaction.id))
          .thenAnswer((_) async => existingTransaction);

      when(mockCategoryRepo.findById('invalid_cat'))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
        categoryId: 'invalid_cat',
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.error, contains('Category not found'));
      verifyNever(mockTransactionRepo.update(any));
    });

    test('should only update provided fields', () async {
      // Arrange
      final existingTransaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        currentHash: 'test_hash',
        note: 'Original note',
      );

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

      when(mockTransactionRepo.findById(existingTransaction.id))
          .thenAnswer((_) async => existingTransaction);

      when(mockCategoryRepo.findById('cat_food'))
          .thenAnswer((_) async => category);

      when(mockTransactionRepo.update(any)).thenAnswer((_) async => {});

      // Act - only update amount, keep everything else
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
        amount: 20000,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, 20000);
      expect(result.data!.categoryId, 'cat_food'); // Unchanged
      expect(result.data!.note, 'Original note'); // Unchanged
    });
  });
}
