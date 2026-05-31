import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/domain/models/list_sort_config.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

void main() {
  group('listFilterProvider', () {
    test('initial state has all 7 ListFilterState fields (SC#1)', () {
      final container = ProviderContainer.test();
      final state = container.read(listFilterProvider);

      expect(state, isA<ListFilterState>());
      expect(state.selectedYear, equals(DateTime.now().year));
      expect(state.selectedMonth, equals(DateTime.now().month));
      expect(state.activeDayFilter, isNull);
      expect(state.sortConfig, equals(const ListSortConfig()));
      expect(state.ledgerType, isNull);
      expect(state.categoryIds, isEmpty);
      expect(state.searchQuery, equals(''));
      expect(state.memberBookId, isNull);
    });

    test('initial state equals ListFilterState.initial()', () {
      final container = ProviderContainer.test();
      final state = container.read(listFilterProvider);
      expect(state, equals(ListFilterState.initial()));
    });

    test('selectMonth sets year, month and resets activeDayFilter to null', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      // First set a day filter to ensure it gets cleared
      notifier.selectDay(DateTime(2026, 3, 15));
      expect(container.read(listFilterProvider).activeDayFilter, isNotNull);

      // Now select a different month — day filter must reset
      notifier.selectMonth(2026, 3);
      final state = container.read(listFilterProvider);

      expect(state.selectedYear, equals(2026));
      expect(state.selectedMonth, equals(3));
      expect(state.activeDayFilter, isNull);
    });

    test('selectDay sets activeDayFilter to specified DateTime', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);
      final day = DateTime(2026, 3, 15);

      notifier.selectDay(day);
      final state = container.read(listFilterProvider);

      expect(state.activeDayFilter, equals(day));
    });

    test('selectDay with null clears activeDayFilter', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.selectDay(DateTime(2026, 3, 15));
      notifier.selectDay(null);

      expect(container.read(listFilterProvider).activeDayFilter, isNull);
    });

    test(
      'selectDay(null) clears day filter but preserves all other filter fields (D-05)',
      () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        // Set all non-day filters to non-default values
        notifier.setLedgerFilter(LedgerType.soul);
        notifier.setCategories({'cat_food'});
        notifier.setSearch('ランチ');
        notifier.setMemberFilter('book_member_01');
        notifier.selectDay(DateTime(2025, 6, 10));

        // Clear ONLY the day filter
        notifier.selectDay(null);
        final state = container.read(listFilterProvider);

        // Day filter cleared
        expect(state.activeDayFilter, isNull);
        // All other filters preserved (D-05 requirement)
        expect(state.ledgerType, equals(LedgerType.soul));
        expect(state.categoryIds, equals({'cat_food'}));
        expect(state.searchQuery, equals('ランチ'));
        expect(state.memberBookId, equals('book_member_01'));
      },
    );

    test('setSort updates sortConfig', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);
      const newSort = ListSortConfig(
        sortField: SortField.amount,
        sortDirection: SortDirection.asc,
      );

      notifier.setSort(newSort);
      final state = container.read(listFilterProvider);

      expect(state.sortConfig, equals(newSort));
    });

    test('setLedgerFilter sets ledgerType to soul', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setLedgerFilter(LedgerType.soul);
      final state = container.read(listFilterProvider);

      expect(state.ledgerType, equals(LedgerType.soul));
    });

    test('setLedgerFilter with null clears ledgerType', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setLedgerFilter(LedgerType.soul);
      notifier.setLedgerFilter(null);

      expect(container.read(listFilterProvider).ledgerType, isNull);
    });

    test('setCategories sets categoryIds (D-01)', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setCategories({'cat_food'});
      final state = container.read(listFilterProvider);

      expect(state.categoryIds, equals({'cat_food'}));
    });

    test('setCategories with empty set clears categoryIds (D-01)', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setCategories({'cat_food'});
      notifier.setCategories({});

      expect(container.read(listFilterProvider).categoryIds, isEmpty);
    });

    test('setSearch updates searchQuery', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setSearch('食費');
      final state = container.read(listFilterProvider);

      expect(state.searchQuery, equals('食費'));
    });

    test('setMemberFilter sets memberBookId', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setMemberFilter('book_member_01');
      final state = container.read(listFilterProvider);

      expect(state.memberBookId, equals('book_member_01'));
    });

    test('setMemberFilter with null clears memberBookId', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);

      notifier.setMemberFilter('book_member_01');
      notifier.setMemberFilter(null);

      expect(container.read(listFilterProvider).memberBookId, isNull);
    });

    group('clearAll (FILTER-04)', () {
      test('clearAll resets all fields to ListFilterState.initial()', () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        // Set all filter fields to non-default values
        notifier.selectMonth(2025, 6);
        notifier.selectDay(DateTime(2025, 6, 10));
        notifier.setLedgerFilter(LedgerType.soul);
        notifier.setCategories({'cat_food'});
        notifier.setSearch('ランチ');
        notifier.setMemberFilter('book_abc');
        notifier.setSort(
          const ListSortConfig(
            sortField: SortField.amount,
            sortDirection: SortDirection.asc,
          ),
        );

        // Verify all were set
        final before = container.read(listFilterProvider);
        expect(before.selectedYear, equals(2025));
        expect(before.ledgerType, equals(LedgerType.soul));
        expect(before.searchQuery, equals('ランチ'));

        // Now clear all
        notifier.clearAll();
        final state = container.read(listFilterProvider);

        expect(state, equals(ListFilterState.initial()));
      });

      test('clearAll resets searchQuery to empty string (FILTER-04 explicit)',
          () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        notifier.setSearch('食費');
        notifier.clearAll();

        expect(container.read(listFilterProvider).searchQuery, equals(''));
      });

      test('clearAll resets ledgerType to null (FILTER-04 explicit)', () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        notifier.setLedgerFilter(LedgerType.survival);
        notifier.clearAll();

        expect(container.read(listFilterProvider).ledgerType, isNull);
      });

      test('clearAll resets categoryIds to empty Set (FILTER-04 explicit)', () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        notifier.setCategories({'cat_transport'});
        notifier.clearAll();

        expect(container.read(listFilterProvider).categoryIds, isEmpty);
      });

      test('clearAll resets activeDayFilter to null (FILTER-04 explicit)', () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        notifier.selectDay(DateTime(2026, 1, 20));
        notifier.clearAll();

        expect(container.read(listFilterProvider).activeDayFilter, isNull);
      });

      test('clearAll resets memberBookId to null (FILTER-04 explicit)', () {
        final container = ProviderContainer.test();
        final notifier = container.read(listFilterProvider.notifier);

        notifier.setMemberFilter('book_xyz');
        notifier.clearAll();

        expect(container.read(listFilterProvider).memberBookId, isNull);
      });
    });

    test('mutators produce new state via copyWith (immutability)', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);
      final stateBefore = container.read(listFilterProvider);

      notifier.setSearch('test');
      final stateAfter = container.read(listFilterProvider);

      // State object must be different (immutable update)
      expect(identical(stateBefore, stateAfter), isFalse);
      // Original object unchanged
      expect(stateBefore.searchQuery, equals(''));
      expect(stateAfter.searchQuery, equals('test'));
    });
  });
}
