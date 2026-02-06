import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'delete_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late DeleteTransactionUseCase useCase;

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = DeleteTransactionUseCase(transactionRepository: mockRepo);
  });

  group('DeleteTransactionUseCase', () {
    test('soft-deletes an existing transaction', () async {
      when(mockRepo.findById('tx_001')).thenAnswer((_) async => Transaction(
            id: 'tx_001',
            bookId: 'book_001',
            deviceId: 'dev_local',
            amount: 1000,
            type: TransactionType.expense,
            categoryId: 'cat_food',
            ledgerType: LedgerType.survival,
            timestamp: DateTime(2026, 2, 6),
            currentHash: 'hash_001',
            createdAt: DateTime(2026, 2, 6),
          ));
      when(mockRepo.softDelete('tx_001')).thenAnswer((_) async {});

      final result = await useCase.execute('tx_001');

      expect(result.isSuccess, isTrue);
      verify(mockRepo.softDelete('tx_001')).called(1);
    });

    test('returns error when transaction not found', () async {
      when(mockRepo.findById('nonexistent')).thenAnswer((_) async => null);

      final result = await useCase.execute('nonexistent');

      expect(result.isError, isTrue);
      expect(result.error, contains('not found'));
      verifyNever(mockRepo.softDelete(any));
    });

    test('returns error when id is empty', () async {
      final result = await useCase.execute('');

      expect(result.isError, isTrue);
      verifyNever(mockRepo.findById(any));
    });
  });
}
