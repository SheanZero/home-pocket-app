import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'get_transactions_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late GetTransactionsUseCase useCase;

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
  });

  Transaction makeTransaction(String id, int amount) {
    return Transaction(
      id: id,
      bookId: 'book_001',
      deviceId: 'dev_local',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: DateTime(2026, 2, 6),
      currentHash: 'hash_$id',
      createdAt: DateTime(2026, 2, 6),
    );
  }

  group('GetTransactionsUseCase', () {
    test('returns transactions for a book', () async {
      final txList = [makeTransaction('tx1', 100), makeTransaction('tx2', 200)];
      when(mockRepo.findByBookId(
        'book_001',
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => txList);

      final result = await useCase.execute(
        GetTransactionsParams(bookId: 'book_001'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
    });

    test('passes filter parameters to repository', () async {
      when(mockRepo.findByBookId(
        'book_001',
        ledgerType: LedgerType.survival,
        categoryId: 'cat_food',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        limit: 50,
        offset: 10,
      )).thenAnswer((_) async => []);

      await useCase.execute(
        GetTransactionsParams(
          bookId: 'book_001',
          ledgerType: LedgerType.survival,
          categoryId: 'cat_food',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 2, 1),
          limit: 50,
          offset: 10,
        ),
      );

      verify(mockRepo.findByBookId(
        'book_001',
        ledgerType: LedgerType.survival,
        categoryId: 'cat_food',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
        limit: 50,
        offset: 10,
      )).called(1);
    });

    test('returns error when bookId is empty', () async {
      final result = await useCase.execute(
        GetTransactionsParams(bookId: ''),
      );

      expect(result.isError, isTrue);
      verifyNever(mockRepo.findByBookId(any));
    });
  });
}
