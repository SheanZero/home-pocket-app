import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/domain/models/list_sort_config.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockTransactionRepository mockRepo;
  late GetListTransactionsUseCase useCase;

  final baseFilter = ListFilterState.initial();

  setUpAll(() {
    // Register fallback values for mocktail `any(named:)` matchers
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(SortField.timestamp);
    registerFallbackValue(SortDirection.desc);
  });

  setUp(() {
    mockRepo = _MockTransactionRepository();
    useCase = GetListTransactionsUseCase(transactionRepository: mockRepo);
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
      timestamp: DateTime(2026, 5, 29),
      currentHash: 'hash_$id',
      createdAt: DateTime(2026, 5, 29),
    );
  }

  group('GetListTransactionsUseCase', () {
    // SC#3: empty bookIds guard
    test('returns error when bookIds is empty', () async {
      final result = await useCase.execute(
        GetListParams(bookIds: [], filter: baseFilter),
      );

      expect(result.isError, isTrue);
      verifyNever(
        () => mockRepo.findByBookIds(
          any(),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      );
    });

    // SC#3 + SORT-02: valid params forwarded to repo with default sort
    // Note: default sort changed from updatedAt to timestamp in quick task 260531-oqn.
    test('execute() forwards params to repository with default timestamp/desc sort',
        () async {
      final txList = [makeTransaction('tx1', 100)];
      when(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) async => txList);

      final result = await useCase.execute(
        GetListParams(bookIds: ['b1'], filter: baseFilter),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 1);

      verify(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: SortField.timestamp,
          sortDirection: SortDirection.desc,
        ),
      ).called(1);
    });

    // SORT-01: SortField.timestamp forwarding
    test('SORT-01: execute() forwards sortField=timestamp to repository',
        () async {
      when(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) async => []);

      final filter = baseFilter.copyWith(
        sortConfig: const ListSortConfig(sortField: SortField.timestamp),
      );

      await useCase.execute(GetListParams(bookIds: ['b1'], filter: filter));

      verify(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: SortField.timestamp,
          sortDirection: any(named: 'sortDirection'),
        ),
      ).called(1);
    });

    // SORT-03: SortField.amount forwarding
    test('SORT-03: execute() forwards sortField=amount to repository', () async {
      when(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) async => []);

      final filter = baseFilter.copyWith(
        sortConfig: const ListSortConfig(sortField: SortField.amount),
      );

      await useCase.execute(GetListParams(bookIds: ['b1'], filter: filter));

      verify(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: SortField.amount,
          sortDirection: any(named: 'sortDirection'),
        ),
      ).called(1);
    });

    // SORT-04: SortDirection.asc forwarding
    test('SORT-04: execute() forwards sortDirection=asc to repository', () async {
      when(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) async => []);

      final filter = baseFilter.copyWith(
        sortConfig: const ListSortConfig(sortDirection: SortDirection.asc),
      );

      await useCase.execute(GetListParams(bookIds: ['b1'], filter: filter));

      verify(
        () => mockRepo.findByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: SortDirection.asc,
        ),
      ).called(1);
    });

    // SC#4: Freezed copyWith immutability
    test('SC#4: ListSortConfig.copyWith creates new object, original unchanged',
        () {
      const original = ListSortConfig(sortField: SortField.timestamp);
      final copy = original.copyWith(sortField: SortField.amount);

      expect(identical(original, copy), isFalse);
      expect(original.sortField, SortField.timestamp);
      expect(copy.sortField, SortField.amount);
    });

    // D-03: watch() throws ArgumentError synchronously on empty bookIds
    test('watch() throws ArgumentError when bookIds is empty', () {
      expect(
        () => useCase.watch(GetListParams(bookIds: [], filter: baseFilter)),
        throwsArgumentError,
      );
    });

    // watch() valid path: returns stream from repo.watchByBookIds
    test('watch() returns stream from repository for valid bookIds', () async {
      when(
        () => mockRepo.watchByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).thenAnswer((_) => Stream.value([]));

      final stream = useCase.watch(
        GetListParams(bookIds: ['b1'], filter: baseFilter),
      );

      expect(stream, isNotNull);
      final result = await stream.first;
      expect(result, isEmpty);

      verify(
        () => mockRepo.watchByBookIds(
          ['b1'],
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          sortField: any(named: 'sortField'),
          sortDirection: any(named: 'sortDirection'),
        ),
      ).called(1);
    });
  });
}
