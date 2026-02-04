import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:home_pocket/features/accounting/application/use_cases/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

import 'get_transactions_use_case_test.mocks.dart';

@GenerateMocks([
  TransactionRepository,
  FieldEncryptionService,
])
void main() {
  late GetTransactionsUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockFieldEncryptionService mockFieldEncryption;

  setUp(() {
    mockTransactionRepo = MockTransactionRepository();
    mockFieldEncryption = MockFieldEncryptionService();

    useCase = GetTransactionsUseCase(
      transactionRepository: mockTransactionRepo,
      fieldEncryptionService: mockFieldEncryption,
    );
  });

  group('GetTransactionsUseCase', () {
    test('should return transactions for book', () async {
      // Arrange
      final transactions = [
        Transaction.create(
          bookId: 'book_001',
          deviceId: 'device_001',
          amount: 10000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
        ),
        Transaction.create(
          bookId: 'book_001',
          deviceId: 'device_001',
          amount: 5000,
          type: TransactionType.expense,
          categoryId: 'cat_transport',
          ledgerType: LedgerType.survival,
        ),
      ];

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: null,
        endDate: null,
        categoryIds: null,
        ledgerType: null,
        limit: 100,
        offset: 0,
      )).thenAnswer((_) async => transactions);

      // Act
      final result = await useCase.execute(bookId: 'book_001');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.length, 2);
    });

    test('should filter by date range', () async {
      // Arrange
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 1, 15),
      );

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: startDate,
        endDate: endDate,
        categoryIds: null,
        ledgerType: null,
        limit: 100,
        offset: 0,
      )).thenAnswer((_) async => [transaction]);

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.id, transaction.id);
    });

    test('should decrypt encrypted notes', () async {
      // Arrange
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        note: 'encrypted_note',
      );

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: null,
        endDate: null,
        categoryIds: null,
        ledgerType: null,
        limit: 100,
        offset: 0,
      )).thenAnswer((_) async => [transaction]);

      when(mockFieldEncryption.decryptField('encrypted_note'))
          .thenAnswer((_) async => 'Decrypted note');

      // Act
      final result = await useCase.execute(bookId: 'book_001');

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.first.note, 'Decrypted note');
      verify(mockFieldEncryption.decryptField('encrypted_note')).called(1);
    });

    test('should filter by category', () async {
      // Arrange
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
      );

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: null,
        endDate: null,
        categoryIds: ['cat_food'],
        ledgerType: null,
        limit: 100,
        offset: 0,
      )).thenAnswer((_) async => [transaction]);

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        categoryIds: ['cat_food'],
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
    });

    test('should filter by ledger type', () async {
      // Arrange
      final transaction = Transaction.create(
        bookId: 'book_001',
        deviceId: 'device_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
      );

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: null,
        endDate: null,
        categoryIds: null,
        ledgerType: LedgerType.survival,
        limit: 100,
        offset: 0,
      )).thenAnswer((_) async => [transaction]);

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        ledgerType: LedgerType.survival,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);
      expect(result.data!.first.ledgerType, LedgerType.survival);
    });

    test('should support pagination', () async {
      // Arrange
      final transactions = List.generate(
        10,
        (i) => Transaction.create(
          bookId: 'book_001',
          deviceId: 'device_001',
          amount: 1000 * (i + 1),
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
        ),
      );

      when(mockTransactionRepo.findByBook(
        bookId: 'book_001',
        startDate: null,
        endDate: null,
        categoryIds: null,
        ledgerType: null,
        limit: 10,
        offset: 20,
      )).thenAnswer((_) async => transactions);

      // Act
      final result = await useCase.execute(
        bookId: 'book_001',
        limit: 10,
        offset: 20,
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 10);
    });
  });
}
