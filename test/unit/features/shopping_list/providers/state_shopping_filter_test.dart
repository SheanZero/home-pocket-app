import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_list_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';

void main() {
  group('ListType / ShoppingFilter providers', () {
    test('setListType resets shoppingFilterProvider to initial state (FILT-02/D5)',
        () {
      final container = ProviderContainer.test();

      // Put the filter into a non-initial state.
      container
          .read(shoppingFilterProvider.notifier)
          .setStatusFilter('active');
      expect(
        container.read(shoppingFilterProvider).statusFilter,
        'active',
        reason: 'Precondition: filter is non-initial',
      );

      // Switching the list type should reset the filter.
      container.read(listTypeProvider.notifier).setListType('public');

      expect(
        container.read(shoppingFilterProvider),
        ShoppingListFilter.initial(),
        reason: 'Filter must reset to initial on list type switch (D5/FILT-02)',
      );
      expect(
        container.read(listTypeProvider),
        'public',
        reason: 'List type must be updated to the new value',
      );
    });

    test(
        'listTypeProvider is keepAlive — not disposed after last subscriber removed',
        () {
      final container = ProviderContainer.test();

      // Read the provider to materialize it.
      final sub = container.listen(listTypeProvider, (_, _) {});
      container.read(listTypeProvider.notifier).setListType('public');

      // Close the only subscriber.
      sub.close();

      // With keepAlive: true the state is retained; reading it must not throw
      // and must return the last set value.
      expect(
        container.read(listTypeProvider),
        'public',
        reason:
            'listTypeProvider (keepAlive:true) must retain state after last subscriber closes',
      );
    });

    test(
        'shoppingFilterProvider is keepAlive — not disposed after last subscriber removed',
        () {
      final container = ProviderContainer.test();

      // Put the filter in a custom state.
      final sub = container.listen(shoppingFilterProvider, (_, _) {});
      container
          .read(shoppingFilterProvider.notifier)
          .setStatusFilter('active');

      // Close the only subscriber.
      sub.close();

      // With keepAlive: true the state must be retained.
      expect(
        container.read(shoppingFilterProvider).statusFilter,
        'active',
        reason:
            'shoppingFilterProvider (keepAlive:true) must retain state after last subscriber closes',
      );
    });

    test('ShoppingFilter.clearAll resets all filter fields', () {
      final container = ProviderContainer.test();

      container
          .read(shoppingFilterProvider.notifier)
          .setStatusFilter('active');
      container.read(shoppingFilterProvider.notifier).setCategoryIds({'cat-1'});
      container.read(shoppingFilterProvider.notifier).clearAll();

      expect(
        container.read(shoppingFilterProvider),
        ShoppingListFilter.initial(),
        reason: 'clearAll must reset to initial state',
      );
    });

    test('ShoppingFilter.setLedgerFilter updates ledger type', () {
      final container = ProviderContainer.test();
      container
          .read(shoppingFilterProvider.notifier)
          .setLedgerFilter(null);

      expect(
        container.read(shoppingFilterProvider).ledgerType,
        isNull,
        reason: 'setLedgerFilter(null) clears the ledger filter',
      );
    });

    test('setPrivateFilter(true) sets showPrivateOnly to true', () {
      final container = ProviderContainer.test();

      container
          .read(shoppingFilterProvider.notifier)
          .setPrivateFilter(true);

      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isTrue,
        reason: 'setPrivateFilter(true) must set showPrivateOnly to true',
      );
    });

    test('setPrivateFilter(false) sets showPrivateOnly to false', () {
      final container = ProviderContainer.test();

      // First set to true
      container
          .read(shoppingFilterProvider.notifier)
          .setPrivateFilter(true);
      // Then set to false
      container
          .read(shoppingFilterProvider.notifier)
          .setPrivateFilter(false);

      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isFalse,
        reason: 'setPrivateFilter(false) must set showPrivateOnly to false',
      );
    });

    test('clearAll() with showPrivateOnly=true resets to initial (showPrivateOnly=false)',
        () {
      final container = ProviderContainer.test();

      container
          .read(shoppingFilterProvider.notifier)
          .setPrivateFilter(true);
      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isTrue,
        reason: 'Precondition: showPrivateOnly is true before clearAll',
      );

      container.read(shoppingFilterProvider.notifier).clearAll();

      expect(
        container.read(shoppingFilterProvider),
        ShoppingListFilter.initial(),
        reason: 'clearAll must reset showPrivateOnly to false (via initial())',
      );
    });

    test('setListType() resets shoppingFilterProvider including showPrivateOnly',
        () {
      final container = ProviderContainer.test();

      // Set both a status filter and the private filter
      container
          .read(shoppingFilterProvider.notifier)
          .setStatusFilter('active');
      container
          .read(shoppingFilterProvider.notifier)
          .setPrivateFilter(true);
      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isTrue,
        reason: 'Precondition: showPrivateOnly is true before segment switch',
      );

      // Switching the list type should reset the filter (D5/FILT-02)
      container.read(listTypeProvider.notifier).setListType('public');

      expect(
        container.read(shoppingFilterProvider),
        ShoppingListFilter.initial(),
        reason:
            'setListType must reset shoppingFilterProvider to initial, including showPrivateOnly',
      );
      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isFalse,
        reason: 'showPrivateOnly must be false after list type switch',
      );
    });
  });
}
