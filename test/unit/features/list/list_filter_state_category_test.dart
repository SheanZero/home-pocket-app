// TDD RED: Tests for D-01 — ListFilterState.categoryIds Set<String> field
// These tests will FAIL until:
//   1. list_filter_state.dart is updated (categoryId → categoryIds Set<String>)
//   2. state_list_filter.dart is updated (setCategories + toggleCategory)
//   3. build_runner regenerates .freezed.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';

void main() {
  group('D-01 ListFilterState.categoryIds (Set<String>)', () {
    test('initial state has categoryIds as empty Set', () {
      final container = ProviderContainer.test();
      final state = container.read(listFilterProvider);
      // D-01: field is now Set<String> not String?
      expect(state.categoryIds, isA<Set<String>>());
      expect(state.categoryIds, isEmpty);
    });

    test('ListFilterState.initial() has empty categoryIds', () {
      final initial = ListFilterState.initial();
      expect(initial.categoryIds, isEmpty);
    });

    test('copyWith produces new instance (immutability)', () {
      final state = ListFilterState.initial();
      final updated = state.copyWith(categoryIds: {'cat_food'});
      expect(identical(state, updated), isFalse);
      expect(state.categoryIds, isEmpty);
      expect(updated.categoryIds, equals({'cat_food'}));
    });
  });

  group('setCategories mutator', () {
    test('setCategories stores the provided Set', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier)
          .setCategories({'cat_food', 'cat_transport'});
      expect(
        container.read(listFilterProvider).categoryIds,
        equals({'cat_food', 'cat_transport'}),
      );
    });

    test('setCategories with empty set clears the filter', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier)
        ..setCategories({'cat_food'})
        ..setCategories({});
      expect(container.read(listFilterProvider).categoryIds, isEmpty);
    });

    test('setCategories produces new state via copyWith (immutability)', () {
      final container = ProviderContainer.test();
      final before = container.read(listFilterProvider);
      container.read(listFilterProvider.notifier).setCategories({'cat_food'});
      final after = container.read(listFilterProvider);
      expect(identical(before, after), isFalse);
      expect(before.categoryIds, isEmpty);
    });
  });

  group('toggleCategory mutator', () {
    test('toggleCategory adds id when not present', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier).toggleCategory('cat_food');
      expect(
        container.read(listFilterProvider).categoryIds,
        contains('cat_food'),
      );
    });

    test('toggleCategory removes id when already present', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier)
        ..setCategories({'cat_food'})
        ..toggleCategory('cat_food');
      expect(container.read(listFilterProvider).categoryIds, isEmpty);
    });

    test('toggleCategory can add multiple different ids', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);
      notifier
        ..toggleCategory('cat_food')
        ..toggleCategory('cat_transport');
      expect(
        container.read(listFilterProvider).categoryIds,
        equals({'cat_food', 'cat_transport'}),
      );
    });

    test('toggleCategory removing one does not affect others', () {
      final container = ProviderContainer.test();
      final notifier = container.read(listFilterProvider.notifier);
      notifier
        ..setCategories({'cat_food', 'cat_transport'})
        ..toggleCategory('cat_food');
      expect(
        container.read(listFilterProvider).categoryIds,
        equals({'cat_transport'}),
      );
    });
  });

  group('clearAll resets categoryIds', () {
    test('clearAll resets categoryIds to empty Set (FILTER-04)', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier)
        ..setCategories({'cat_food', 'cat_transport'})
        ..clearAll();
      expect(container.read(listFilterProvider).categoryIds, isEmpty);
    });
  });
}
