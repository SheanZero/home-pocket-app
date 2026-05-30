import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/domain/models/tagged_transaction.dart';
import 'package:home_pocket/features/list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_transactions.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Transaction _makeTransaction({
  String id = 'tx-1',
  String categoryId = 'cat_food',
  String? merchant,
  String? note,
  LedgerType ledgerType = LedgerType.survival,
  DateTime? timestamp,
}) {
  return Transaction(
    id: id,
    bookId: 'book1',
    deviceId: 'device1',
    amount: 1000,
    type: TransactionType.expense,
    categoryId: categoryId,
    ledgerType: ledgerType,
    timestamp: timestamp ?? DateTime(2026, 5, 15, 12, 0),
    currentHash: 'hash-$id',
    createdAt: DateTime(2026, 5, 15),
    note: note,
    merchant: merchant,
  );
}

// Build a ProviderContainer with standard overrides for listTransactionsProvider tests.
ProviderContainer _makeContainer(
  _MockGetListTransactionsUseCase mockUseCase, {
  ListFilterState? filterState,
}) {
  return ProviderContainer.test(
    overrides: [
      getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
      currentLocaleProvider.overrideWith((ref) async => const Locale('ja')),
      if (filterState != null)
        listFilterProvider.overrideWith(
          () => _FixedListFilter(filterState),
        ),
    ],
  );
}

class _FixedListFilter extends ListFilter {
  _FixedListFilter(this._fixed);
  final ListFilterState _fixed;

  @override
  ListFilterState build() => _fixed;
}

void main() {
  setUpAll(() {
    registerFallbackValue(SortField.updatedAt);
    registerFallbackValue(SortDirection.desc);
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const GetListParams(
      bookIds: ['book1'],
      filter: ListFilterState(
        selectedYear: 2026,
        selectedMonth: 5,
      ),
    ));
  });

  group('listTransactionsProvider', () {
    test('returns List<TaggedTransaction> wrapping each Transaction (SC#3 return type)',
        () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction();
      when(() => mock.execute(any())).thenAnswer(
        (_) async => Result.success([tx]),
      );

      final container = _makeContainer(mock);
      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      final list = result.value!;
      expect(list, hasLength(1));
      expect(list.first, isA<TaggedTransaction>());
      expect(list.first.transaction, equals(tx));
      expect(list.first.memberTag, isNull); // Phase 29 seam
    });

    test(
        'text search matches localized category name (FILTER-01): '
        'cat_food + searchQuery=食費 → returned', () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(categoryId: 'cat_food');
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          searchQuery: '食費',
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      expect(result.value!, hasLength(1),
          reason:
              'cat_food should match localized name 食費 via CategoryLocalizationService');
    });

    test(
        'text search does NOT match raw categoryId (FILTER-01 correctness): '
        'cat_food + searchQuery=food → NOT returned', () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(categoryId: 'cat_food');
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          searchQuery: 'food',
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      // 'food' matches raw categoryId but NOT the Japanese localized name
      // If CategoryLocalizationService is used correctly, cat_food → 食費 (ja)
      // which does not contain 'food'
      expect(result.value!, isEmpty,
          reason:
              'Provider must use CategoryLocalizationService — raw categoryId must not leak through');
    });

    test('text search by merchant (FILTER-01): merchant match', () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(merchant: 'スターバックス');
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          searchQuery: 'スターバック',
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      expect(result.value!, hasLength(1),
          reason: 'スターバックス contains スターバック');
    });

    test('text search by note (FILTER-01): note match', () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(note: '誕生日プレゼント');
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          searchQuery: '誕生日',
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      expect(result.value!, hasLength(1),
          reason: '誕生日プレゼント contains 誕生日');
    });

    test('null note handled gracefully (D-06): no crash, not returned',
        () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(note: null);
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          searchQuery: 'test',
        ),
      );

      // Must not throw; transaction with null note should simply not match
      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue,
          reason: 'null note must not cause an exception');
      // cat_food in ja = 食費, does not contain 'test'; merchant is null; note is null
      expect(result.value!, isEmpty);
    });

    test(
        'AND-composition with ledger filter (FILTER-02 + FILTER-04): '
        'use case receives ledgerType; text search applied Dart-side', () async {
      final mock = _MockGetListTransactionsUseCase();
      // Use case already returns pre-filtered (soul-only) transactions;
      // we verify text search then AND-composes
      final soulTx = _makeTransaction(
        id: 'soul-tx',
        categoryId: 'cat_food',
        ledgerType: LedgerType.soul,
      );
      when(() => mock.execute(any())).thenAnswer(
        (_) async => Result.success([soulTx]),
      );

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          ledgerType: LedgerType.soul,
          searchQuery: '食費', // matches cat_food → 食費 (ja)
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      expect(result.value!, hasLength(1));
      // Verify use case was called with the ledgerType filter
      final captured = verify(() => mock.execute(captureAny())).captured;
      final params = captured.first as GetListParams;
      expect(params.filter.ledgerType, equals(LedgerType.soul),
          reason: 'FILTER-02: ledgerType forwarded to use case');
    });

    test(
        'categoryId filter forwarded to use case (FILTER-03): '
        'use case receives non-null categoryId', () async {
      final mock = _MockGetListTransactionsUseCase();
      final tx = _makeTransaction(categoryId: 'cat_transport');
      when(() => mock.execute(any())).thenAnswer((_) async => Result.success([tx]));

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          categoryId: 'cat_transport',
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      final captured = verify(() => mock.execute(captureAny())).captured;
      final params = captured.first as GetListParams;
      expect(params.filter.categoryId, equals('cat_transport'),
          reason: 'FILTER-03: categoryId forwarded to use case');
    });

    test(
        'day filter applies year+month+day check (activeDayFilter)', () async {
      final mock = _MockGetListTransactionsUseCase();
      final targetDay = DateTime(2026, 5, 15);
      final inDay = _makeTransaction(
        id: 'tx-match',
        timestamp: DateTime(2026, 5, 15, 10, 0),
      );
      final outOfDay = _makeTransaction(
        id: 'tx-no-match',
        timestamp: DateTime(2026, 5, 16, 10, 0),
      );
      when(() => mock.execute(any())).thenAnswer(
        (_) async => Result.success([inDay, outOfDay]),
      );

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          activeDayFilter: targetDay,
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      expect(result.value!, hasLength(1));
      expect(result.value!.first.transaction.id, equals('tx-match'),
          reason:
              'Day filter uses year+month+day — only May 15 tx retained');
    });
  });
}
