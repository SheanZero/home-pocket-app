import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
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
  String bookId = 'book1',
  String categoryId = 'cat_food',
  String? merchant,
  String? note,
  LedgerType ledgerType = LedgerType.daily,
  DateTime? timestamp,
}) {
  return Transaction(
    id: id,
    bookId: bookId,
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

/// Minimal Book fixture for shadow-book stubs.
Book _stubBook(String id) => Book(
      id: id,
      name: 'Shadow $id',
      currency: 'JPY',
      deviceId: 'device-$id',
      createdAt: DateTime(2026, 1, 1),
      isShadow: true,
    );

// Build a ProviderContainer with standard overrides for listTransactionsProvider tests.
ProviderContainer _makeContainer(
  _MockGetListTransactionsUseCase mockUseCase, {
  ListFilterState? filterState,
  bool isGroupMode = false,
  List<ShadowBookInfo> shadows = const [],
}) {
  return ProviderContainer.test(
    overrides: [
      getListTransactionsUseCaseProvider.overrideWithValue(mockUseCase),
      currentLocaleProvider.overrideWith((ref) async => const Locale('ja')),
      isGroupModeProvider.overrideWithValue(isGroupMode),
      shadowBooksProvider.overrideWith((_) async => shadows),
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
    registerFallbackValue(SortField.timestamp);
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
        ledgerType: LedgerType.joy,
      );
      when(() => mock.execute(any())).thenAnswer(
        (_) async => Result.success([soulTx]),
      );

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          ledgerType: LedgerType.joy,
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
      expect(params.filter.ledgerType, equals(LedgerType.joy),
          reason: 'FILTER-02: ledgerType forwarded to use case');
    });

    test(
        'categoryIds Dart-side filter (FILTER-03 D-01): '
        'only transactions matching categoryIds are returned', () async {
      final mock = _MockGetListTransactionsUseCase();
      final matching = _makeTransaction(id: 'tx-match', categoryId: 'cat_transport');
      final notMatching = _makeTransaction(id: 'tx-no-match', categoryId: 'cat_food');
      when(() => mock.execute(any())).thenAnswer(
        (_) async => Result.success([matching, notMatching]),
      );

      final container = _makeContainer(
        mock,
        filterState: ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          categoryIds: {'cat_transport'},
        ),
      );

      final result = await waitForFirstValue<List<TaggedTransaction>>(
        container,
        listTransactionsProvider(bookId: 'book1'),
      );

      expect(result.hasValue, isTrue);
      // D-01: category filtering is Dart-side; use case receives null categoryId
      final captured = verify(() => mock.execute(captureAny())).captured;
      final params = captured.first as GetListParams;
      expect(params.filter.categoryIds, equals({'cat_transport'}),
          reason: 'FILTER-03 D-01: categoryIds present in filter state');
      // Dart-side filter should keep only matching transaction
      expect(result.value!.length, equals(1),
          reason: 'FILTER-03: Dart-side filter keeps only matching tx');
      expect(result.value!.first.transaction.categoryId, equals('cat_transport'));
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

  // ---------------------------------------------------------------------------
  // Phase 29: family-mode FAM-01/02/03/04
  // ---------------------------------------------------------------------------
  // All tests in this group are RED until state_list_transactions.dart is
  // updated in Plan 02/03 to fan-out over shadow books and fill memberTag.
  // ---------------------------------------------------------------------------

  group('Phase 29: family-mode FAM-01/02/03/04', () {
    test(
      'FAM-01: group mode bookIds includes own + shadow book IDs',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');
        final shadowTx = _makeTransaction(id: 'shadow-tx', bookId: 'shadow-1');

        // Use case is called with merged bookIds — returns rows from both books
        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx, shadowTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        // RED: provider currently passes only ['book1'] to use case;
        // after Plan 02 it will pass ['book1', 'shadow-1']
        expect(
          result.value!,
          hasLength(2),
          reason: 'FAM-01: group mode includes own + shadow rows',
        );

        // Verify the use case was called with both book IDs
        final captured = verify(() => mock.execute(captureAny())).captured;
        final params = captured.first as GetListParams;
        expect(
          params.bookIds,
          containsAll(['book1', 'shadow-1']),
          reason: 'FAM-01: bookIds must include shadow book ID in group mode',
        );
      },
    );

    test(
      'FAM-02: shadow-book rows have memberTag non-null',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');
        final shadowTx = _makeTransaction(id: 'shadow-tx', bookId: 'shadow-1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx, shadowTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        final list = result.value!;

        // RED: provider always returns memberTag == null until Plan 02 lands
        final shadowRows = list.where(
          (t) => t.transaction.bookId == 'shadow-1',
        );
        expect(
          shadowRows.every((t) => t.memberTag != null),
          isTrue,
          reason: 'FAM-02: shadow-book rows must have memberTag != null',
        );
      },
    );

    test(
      'FAM-02/D-01: own-book rows have memberTag null',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');
        final shadowTx = _makeTransaction(id: 'shadow-tx', bookId: 'shadow-1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx, shadowTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        final list = result.value!;

        // Own-book rows must always have memberTag == null (D-01)
        // This test may pass before implementation if list only has own rows
        final ownRows = list.where((t) => t.transaction.bookId == 'book1');
        expect(
          ownRows.every((t) => t.memberTag == null),
          isTrue,
          reason: 'FAM-02/D-01: own-book rows must have memberTag == null',
        );
      },
    );

    test(
      'FAM-03: member filter narrows to selected shadow book SQL',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        // Use case returns only shadow-1 rows when memberBookId is set
        final shadowTx = _makeTransaction(id: 'shadow-tx', bookId: 'shadow-1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([shadowTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
            memberBookId: 'shadow-1',
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        // RED: provider currently ignores memberBookId; Plan 02 will pass only
        // effectiveBookIds = ['shadow-1'] to the use case
        expect(
          result.value!.every((t) => t.transaction.bookId == 'shadow-1'),
          isTrue,
          reason: 'FAM-03: member filter must narrow to selected shadow book',
        );

        final captured = verify(() => mock.execute(captureAny())).captured;
        final params = captured.first as GetListParams;
        expect(
          params.bookIds,
          equals(['shadow-1']),
          reason: 'FAM-03: only shadow-1 in bookIds when memberFilter active',
        );
      },
    );

    test(
      'FAM-04: Mine-only = setMemberFilter(ownBookId) shows only own rows',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        // Use case returns only own rows when memberBookId == ownBookId
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
            memberBookId: 'book1', // Mine-only = own bookId
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        // RED: provider currently ignores memberBookId; Plan 02 will narrow to own book
        expect(
          result.value!.every((t) => t.transaction.bookId == 'book1'),
          isTrue,
          reason: 'FAM-04: Mine-only must show only own-book rows',
        );

        final captured = verify(() => mock.execute(captureAny())).captured;
        final params = captured.first as GetListParams;
        expect(
          params.bookIds,
          equals(['book1']),
          reason: 'FAM-04: only own bookId in bookIds when Mine-only active',
        );
      },
    );

    test(
      'CR-01: stale memberBookId (not in bookIds) falls back to full book set, '
      'never empty',
      () async {
        // Regression for code review CR-01: a memberBookId left over from group
        // mode (e.g. member removed from group, or returned to solo) must NOT
        // collapse effectiveBookIds to const [] — that makes the use case reject
        // an empty bookIds list and strands the user on an error screen with no
        // filter chip to recover. Stale member filter == no member filter.
        final mock = _MockGetListTransactionsUseCase();
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx]),
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mock,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
            memberBookId: 'shadow-removed', // no longer in the group
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue,
            reason: 'CR-01: stale member filter must not produce an error state');

        final captured = verify(() => mock.execute(captureAny())).captured;
        final params = captured.first as GetListParams;
        expect(
          params.bookIds,
          equals(['book1', 'shadow-1']),
          reason: 'CR-01: stale memberBookId must fall back to the full book '
              'set (own + shadows), never an empty list',
        );
      },
    );

    test(
      'D-04: solo mode returns own-book rows only, all memberTags null',
      () async {
        final mock = _MockGetListTransactionsUseCase();
        final ownTx = _makeTransaction(id: 'own-tx', bookId: 'book1');

        when(() => mock.execute(any())).thenAnswer(
          (_) async => Result.success([ownTx]),
        );

        // Solo mode — no shadow books
        final container = _makeContainer(
          mock,
          isGroupMode: false,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
          ),
        );

        final result = await waitForFirstValue<List<TaggedTransaction>>(
          container,
          listTransactionsProvider(bookId: 'book1'),
        );

        expect(result.hasValue, isTrue);
        final list = result.value!;
        // Solo mode: all rows are own rows and all memberTags are null (D-04)
        expect(
          list.every((t) => t.memberTag == null),
          isTrue,
          reason: 'D-04: solo mode all memberTags must be null',
        );
        // Use case was called with only own bookId
        final captured = verify(() => mock.execute(captureAny())).captured;
        final params = captured.first as GetListParams;
        expect(
          params.bookIds,
          equals(['book1']),
          reason: 'D-04: solo mode passes only own bookId',
        );
      },
    );
  });
}
