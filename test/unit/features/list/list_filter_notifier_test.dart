// Wave 0 test stubs for D-01 mutator contract (setCategories / toggleCategory).
// These tests are in RED state — they depend on the live implementation in
// lib/features/list/presentation/providers/state_list_filter.dart which was
// updated in 28-01 with setCategories and toggleCategory.
//
// Run: flutter test test/unit/features/list/list_filter_notifier_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';

void main() {
  group('ListFilter D-01 mutators — setCategories / toggleCategory', () {
    test('setCategories stores the provided Set', () {
      final container = ProviderContainer.test();
      container
          .read(listFilterProvider.notifier)
          .setCategories({'cat_food', 'cat_transport'});
      expect(
        container.read(listFilterProvider).categoryIds,
        equals({'cat_food', 'cat_transport'}),
      );
    });

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
      expect(
        container.read(listFilterProvider).categoryIds,
        isEmpty,
      );
    });

    test('clearAll resets categoryIds to empty Set', () {
      final container = ProviderContainer.test();
      container.read(listFilterProvider.notifier)
        ..setCategories({'cat_food'})
        ..clearAll();
      expect(
        container.read(listFilterProvider).categoryIds,
        isEmpty,
      );
    });

    test('setCategories produces new state via copyWith (immutability)', () {
      final container = ProviderContainer.test();
      final before = container.read(listFilterProvider);
      container
          .read(listFilterProvider.notifier)
          .setCategories({'cat_food'});
      final after = container.read(listFilterProvider);
      expect(identical(before, after), isFalse);
      expect(before.categoryIds, isEmpty);
    });
  });
}
