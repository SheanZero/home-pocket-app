import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/use_case_providers.dart';
import 'package:home_pocket/features/home/presentation/providers/today_transactions_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'today_transactions_provider_test.mocks.dart';

Transaction _makeTransaction(
  String id, {
  bool isDeleted = false,
  LedgerType ledgerType = LedgerType.survival,
}) {
  return Transaction(
    id: id,
    bookId: 'book_001',
    deviceId: 'dev_local',
    amount: 1000,
    type: TransactionType.expense,
    categoryId: 'cat_food',
    ledgerType: ledgerType,
    timestamp: DateTime.now(),
    currentHash: 'hash_$id',
    createdAt: DateTime.now(),
    isDeleted: isDeleted,
  );
}

void main() {
  group('todayTransactionsProvider', () {
    test('returns non-deleted transactions on success', () async {
      final mockRepo = MockTransactionRepository();
      final transactions = [
        _makeTransaction('tx1'),
        _makeTransaction('tx2', isDeleted: true),
        _makeTransaction('tx3'),
      ];

      when(
        mockRepo.findByBookId(
          any,
          ledgerType: anyNamed('ledgerType'),
          categoryId: anyNamed('categoryId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => transactions);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [
          getTransactionsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      expect(result.length, 2);
      expect(result.every((tx) => !tx.isDeleted), isTrue);
      expect(result.map((tx) => tx.id).toList(), ['tx1', 'tx3']);
    });

    test('returns empty list when no transactions exist', () async {
      final mockRepo = MockTransactionRepository();
      when(
        mockRepo.findByBookId(
          any,
          ledgerType: anyNamed('ledgerType'),
          categoryId: anyNamed('categoryId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [
          getTransactionsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      expect(result, isEmpty);
    });

    test('filters out all deleted transactions', () async {
      final mockRepo = MockTransactionRepository();
      final transactions = [
        _makeTransaction('tx1', isDeleted: true),
        _makeTransaction('tx2', isDeleted: true),
      ];

      when(
        mockRepo.findByBookId(
          any,
          ledgerType: anyNamed('ledgerType'),
          categoryId: anyNamed('categoryId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => transactions);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [
          getTransactionsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      expect(result, isEmpty);
    });

    test('passes correct date range parameters', () async {
      final mockRepo = MockTransactionRepository();
      when(
        mockRepo.findByBookId(
          any,
          ledgerType: anyNamed('ledgerType'),
          categoryId: anyNamed('categoryId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [
          getTransactionsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      final captured = verify(
        mockRepo.findByBookId(
          captureAny,
          ledgerType: captureAnyNamed('ledgerType'),
          categoryId: captureAnyNamed('categoryId'),
          startDate: captureAnyNamed('startDate'),
          endDate: captureAnyNamed('endDate'),
          limit: captureAnyNamed('limit'),
          offset: captureAnyNamed('offset'),
        ),
      ).captured;

      // captured[0] = bookId, captured[3] = startDate, captured[4] = endDate
      final bookId = captured[0] as String;
      final startDate = captured[3] as DateTime;
      final endDate = captured[4] as DateTime;

      expect(bookId, 'book_001');

      final now = DateTime.now();
      expect(startDate.year, now.year);
      expect(startDate.month, now.month);
      expect(startDate.day, now.day);
      expect(startDate.hour, 0);
      expect(startDate.minute, 0);
      expect(startDate.second, 0);

      expect(endDate.year, now.year);
      expect(endDate.month, now.month);
      expect(endDate.day, now.day);
      expect(endDate.hour, 23);
      expect(endDate.minute, 59);
      expect(endDate.second, 59);
    });

    test('throws exception on use case error', () async {
      final mockRepo = MockTransactionRepository();
      when(
        mockRepo.findByBookId(
          any,
          ledgerType: anyNamed('ledgerType'),
          categoryId: anyNamed('categoryId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [
          getTransactionsUseCaseProvider.overrideWithValue(useCase),
        ],
      );
      addTearDown(container.dispose);

      // Empty bookId triggers error in GetTransactionsUseCase
      expect(
        () => container.read(
          todayTransactionsProvider(bookId: '').future,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
