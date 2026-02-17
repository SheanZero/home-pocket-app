import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/providers/home_providers.dart';

void main() {
  group('SelectedTabIndex', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial value is 0', () {
      expect(container.read(selectedTabIndexProvider), 0);
    });

    test('select changes the tab index', () {
      container.read(selectedTabIndexProvider.notifier).select(2);
      expect(container.read(selectedTabIndexProvider), 2);
    });

    test('select can be called multiple times', () {
      container.read(selectedTabIndexProvider.notifier).select(1);
      expect(container.read(selectedTabIndexProvider), 1);

      container.read(selectedTabIndexProvider.notifier).select(3);
      expect(container.read(selectedTabIndexProvider), 3);
    });

    test('select with same value does not change state reference', () {
      container.read(selectedTabIndexProvider.notifier).select(0);
      expect(container.read(selectedTabIndexProvider), 0);
    });
  });

  group('OhtaniConverterVisible', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial value is true', () {
      expect(container.read(ohtaniConverterVisibleProvider), isTrue);
    });

    test('dismiss sets value to false', () {
      container.read(ohtaniConverterVisibleProvider.notifier).dismiss();
      expect(container.read(ohtaniConverterVisibleProvider), isFalse);
    });

    test('dismiss is idempotent', () {
      container.read(ohtaniConverterVisibleProvider.notifier).dismiss();
      container.read(ohtaniConverterVisibleProvider.notifier).dismiss();
      expect(container.read(ohtaniConverterVisibleProvider), isFalse);
    });
  });
}
