import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_calendar_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

/// Pumps CalendarHeaderWidget inside a ProviderScope + MaterialApp with i18n.
Future<void> _pumpCalendarHeader(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CalendarHeaderWidget(
            bookId: 'book1',
            currencyCode: 'JPY',
            locale: const Locale('ja'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CalendarHeaderWidget', () {
    // SC#1: Month navigation chevrons have moved to ListScreen's AppBar.
    // Month navigation is covered by the ListScreen-level tests in
    // list_screen_refresh_test.dart. This widget test no longer has AppBar
    // chevrons to tap since CalendarHeaderWidget is pumped without a ListScreen.

    testWidgets('SC#3: tap day selects it; tap same day again clears filter',
        (tester) async {
      final mockRepo = _MockAnalyticsRepository();
      when(() => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => []);

      final container = ProviderContainer.test(overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockRepo),
      ]);

      await _pumpCalendarHeader(tester, container);

      // Tap text '5' — a day cell for day 5
      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(
        container.read(listFilterProvider).activeDayFilter?.day,
        equals(5),
      );

      // Tap same day again → clear
      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(container.read(listFilterProvider).activeDayFilter, isNull);
    });

    testWidgets('SC#4: summary row shows month total formatted as JPY',
        (tester) async {
      final now = DateTime.now();
      final mockRepo = _MockAnalyticsRepository();
      when(() => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => [
            DailyTotal(
              date: DateTime(now.year, now.month, 3),
              totalAmount: 12345,
            ),
          ]);

      final container = ProviderContainer.test(overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockRepo),
      ]);

      await _pumpCalendarHeader(tester, container);

      // JPY 0 decimals: ¥12,345
      expect(find.text('¥12,345'), findsOneWidget);
    });
  });
}
