import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/list/presentation/providers/state_calendar_totals.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

ProviderContainer _makeContainer(_MockAnalyticsRepository mockRepo) {
  return ProviderContainer.test(
    overrides: [
      analyticsRepositoryProvider.overrideWithValue(mockRepo),
    ],
  );
}

void main() {
  group('calendarDailyTotalsProvider', () {
    test('SC#2: expense-only basis — stub returns one DailyTotal', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => [
          DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1200),
        ],
      );

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map[DateTime(2026, 5, 3)], equals(1200));
      expect(map.length, equals(1));
    });

    test(
      '_dayKey normalization: map lookup succeeds regardless of time component',
      () async {
        final mockRepo = _MockAnalyticsRepository();
        // DAO returns a DailyTotal with a non-midnight time component
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 3, 12, 30), totalAmount: 1200),
          ],
        );

        final container = _makeContainer(mockRepo);
        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasValue, isTrue);
        final map = result.requireValue;
        // Normalized key lookup must succeed: DateTime(2026,5,3,12,30) → _dayKey → DateTime(2026,5,3)
        expect(map[DateTime(2026, 5, 3)], equals(1200));
      },
    );

    test('empty month: map is empty and fold yields 0', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map, isEmpty);
      expect(map.values.fold(0, (a, b) => a + b), equals(0));
    });

    test('D-11: month total fold equals sum of per-day values', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => [
          DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1000),
          DailyTotal(date: DateTime(2026, 5, 5), totalAmount: 2000),
          DailyTotal(date: DateTime(2026, 5, 10), totalAmount: 3000),
        ],
      );

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map.values.fold(0, (a, b) => a + b), equals(6000));
    });

    test(
      'ProviderException wraps repository error (StateError)',
      () async {
        final mockRepo = _MockAnalyticsRepository();
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenThrow(StateError('db error'));

        final container = _makeContainer(mockRepo);

        await expectLater(
          waitForFirstValue<Map<DateTime, int>>(
            container,
            calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
          ).then(
            (v) =>
                v.hasError
                    ? throw v.error!
                    : fail('Expected error but got value'),
          ),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isA<StateError>(),
            ),
          ),
        );
      },
    );
  });
}
