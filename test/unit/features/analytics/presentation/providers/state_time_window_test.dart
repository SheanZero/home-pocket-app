import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';

import '../../../../../helpers/test_provider_scope.dart';

void main() {
  group('selectedTimeWindowProvider', () {
    test('defaults to the current calendar month', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      final window = container.read(selectedTimeWindowProvider);
      final now = DateTime.now();

      expect(window, TimeWindow.month(year: now.year, month: now.month));
    });

    test('setWindow accepts a quarter window', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      const target = TimeWindow.quarter(year: 2026, quarter: 2);
      container.read(selectedTimeWindowProvider.notifier).setWindow(target);

      expect(container.read(selectedTimeWindowProvider), target);
    });

    test('setWindow accepts a custom date range', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      final target = TimeWindow.custom(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
      );
      container.read(selectedTimeWindowProvider.notifier).setWindow(target);

      expect(container.read(selectedTimeWindowProvider), target);
    });

    test('setting the same value twice preserves value equality', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      const target = TimeWindow.quarter(year: 2026, quarter: 2);
      final notifier = container.read(selectedTimeWindowProvider.notifier);

      notifier.setWindow(target);
      final first = container.read(selectedTimeWindowProvider);
      notifier.setWindow(target);
      final second = container.read(selectedTimeWindowProvider);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
