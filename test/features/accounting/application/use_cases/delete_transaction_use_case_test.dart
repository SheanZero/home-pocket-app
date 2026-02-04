import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:home_pocket/features/accounting/application/use_cases/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

import 'delete_transaction_use_case_test.mocks.dart';

@GenerateMocks([
  TransactionRepository,
])
void main() {
  late DeleteTransactionUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();

    useCase = DeleteTransactionUseCase(
      transactionRepository: mockTransactionRepo,
    );
  });

  group('DeleteTransactionUseCase', () {
    test('should delete transaction successfully', () async {
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

      when(mockTransactionRepo.delete(existingTransaction.id))
          .thenAnswer((_) async => {});

      // Act
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isTrue); // Returns true on success

      verify(mockTransactionRepo.findById(existingTransaction.id)).called(1);
      verify(mockTransactionRepo.delete(existingTransaction.id)).called(1);
    });

    test('should return error if transaction not found', () async {
      // Arrange
      when(mockTransactionRepo.findById('invalid_id'))
          .thenAnswer((_) async => null);

      // Act
      final result = await useCase.execute(
        transactionId: 'invalid_id',
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.error, contains('Transaction not found'));
      verifyNever(mockTransactionRepo.delete(any));
    });

    test('should handle repository errors gracefully', () async {
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

      when(mockTransactionRepo.delete(existingTransaction.id))
          .thenThrow(Exception('Database error'));

      // Act
      final result = await useCase.execute(
        transactionId: existingTransaction.id,
      );

      // Assert
      expect(result.isError, isTrue);
      expect(result.error, contains('Failed to delete transaction'));
    });
  });
}
