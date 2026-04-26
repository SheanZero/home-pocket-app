import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/get_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show getTransactionsUseCaseProvider;
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock implements TransactionRepository {}

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
      final mockRepo = _MockTransactionRepository();
      final transactions = [
        _makeTransaction('tx1'),
        _makeTransaction('tx2', isDeleted: true),
        _makeTransaction('tx3'),
      ];

      when(
        () => mockRepo.findByBookId(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => transactions);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [getTransactionsUseCaseProvider.overrideWithValue(useCase)],
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
      final mockRepo = _MockTransactionRepository();
      when(
        () => mockRepo.findByBookId(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [getTransactionsUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      expect(result, isEmpty);
    });

    test('filters out all deleted transactions', () async {
      final mockRepo = _MockTransactionRepository();
      final transactions = [
        _makeTransaction('tx1', isDeleted: true),
        _makeTransaction('tx2', isDeleted: true),
      ];

      when(
        () => mockRepo.findByBookId(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => transactions);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [getTransactionsUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      expect(result, isEmpty);
    });

    test('passes correct date range parameters', () async {
      final mockRepo = _MockTransactionRepository();
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, now.day);
      final expectedEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      when(
        () => mockRepo.findByBookId(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [getTransactionsUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);

      await container.read(
        todayTransactionsProvider(bookId: 'book_001').future,
      );

      verify(
        () => mockRepo.findByBookId(
          'book_001',
          startDate: expectedStart,
          endDate: expectedEnd,
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).called(1);
    });

    test('throws exception on use case error', () async {
      final mockRepo = _MockTransactionRepository();
      when(
        () => mockRepo.findByBookId(
          any(),
          ledgerType: any(named: 'ledgerType'),
          categoryId: any(named: 'categoryId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      final useCase = GetTransactionsUseCase(transactionRepository: mockRepo);
      final container = ProviderContainer(
        overrides: [getTransactionsUseCaseProvider.overrideWithValue(useCase)],
      );
      addTearDown(container.dispose);

      // Empty bookId triggers error in GetTransactionsUseCase
      expect(
        () => container.read(todayTransactionsProvider(bookId: '').future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
