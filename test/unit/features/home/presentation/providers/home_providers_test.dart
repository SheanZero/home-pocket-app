import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/providers/state_home.dart';

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

  group('HomeSelectedMonth', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial value is the current month', () {
      final now = DateTime.now();
      final state = container.read(homeSelectedMonthProvider);

      expect(state.year, now.year);
      expect(state.month, now.month);
    });

    test('selectMonth sets year and month explicitly', () {
      container.read(homeSelectedMonthProvider.notifier).selectMonth(2025, 3);

      final state = container.read(homeSelectedMonthProvider);
      expect(state.year, 2025);
      expect(state.month, 3);
    });

    test('prevMonth navigates back, rolling over the year boundary', () {
      final notifier = container.read(homeSelectedMonthProvider.notifier);
      notifier.selectMonth(2026, 1);

      notifier.prevMonth();

      final state = container.read(homeSelectedMonthProvider);
      expect(state.year, 2025);
      expect(state.month, 12);
    });

    test('nextMonth advances, rolling over the year boundary', () {
      final notifier = container.read(homeSelectedMonthProvider.notifier);
      notifier.selectMonth(2024, 12);

      notifier.nextMonth();

      final state = container.read(homeSelectedMonthProvider);
      expect(state.year, 2025);
      expect(state.month, 1);
    });

    test('nextMonth is a no-op on the current real-world month (clamp)', () {
      final now = DateTime.now();
      final notifier = container.read(homeSelectedMonthProvider.notifier);
      notifier.selectMonth(now.year, now.month);

      notifier.nextMonth();

      final state = container.read(homeSelectedMonthProvider);
      expect(state.year, now.year);
      expect(state.month, now.month);
    });
  });
}
