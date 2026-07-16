import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_calendar_header.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class _JanuaryListFilter extends ListFilter {
  @override
  ListFilterState build() =>
      const ListFilterState(selectedYear: 2025, selectedMonth: 1);
}

/// Pumps CalendarHeaderWidget inside a ProviderScope + MaterialApp with i18n.
Future<void> _pumpCalendarHeader(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ja'),
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
    // list_screen_refresh_test.dart. This widget test has no custom header
    // actions to tap because CalendarHeaderWidget is pumped without ListScreen.

    testWidgets('SC#3: tap day selects it; tap same day again clears filter', (
      tester,
    ) async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final container = ProviderContainer.test(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(mockRepo),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
          ),
        ],
      );

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

    testWidgets('SC#4: summary row shows month total formatted as JPY', (
      tester,
    ) async {
      final now = DateTime.now();
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => [
          DailyTotal(
            date: DateTime(now.year, now.month, 3),
            totalAmount: 12345,
          ),
        ],
      );

      final container = ProviderContainer.test(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(mockRepo),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
          ),
        ],
      );

      await _pumpCalendarHeader(tester, container);

      // JPY 0 decimals: ¥12,345
      expect(find.text('¥12,345'), findsOneWidget);
    });

    testWidgets('calendar card uses readable global type and shadow', (
      tester,
    ) async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);
      final container = ProviderContainer.test(
        overrides: [
          listFilterProvider.overrideWith(() => _JanuaryListFilter()),
          analyticsRepositoryProvider.overrideWithValue(mockRepo),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
          ),
        ],
      );

      await _pumpCalendarHeader(tester, container);

      final card = tester.widget<Container>(
        find.byKey(const Key('list-calendar-card')),
      );
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
      expect(
        tester.widget<Text>(find.text('月')).style?.fontSize,
        AppTypography.compact,
      );
      expect(
        tester.widget<Text>(find.text('5').last).style?.fontSize,
        AppTypography.compact,
      );
      final thirties = tester.widgetList<Text>(find.text('30')).toList();
      expect(thirties, hasLength(2));
      expect(thirties.first.style?.fontSize, AppTypography.compact);
      expect(thirties.last.style?.fontSize, AppTypography.compact);
      expect(
        tester.widget<Text>(find.text('今月の合計')).style?.fontSize,
        AppTypography.supporting,
      );
      expect(
        tester.widget<Text>(find.text('¥0')).style?.fontSize,
        AppTypography.amountSmall,
      );
    });

    testWidgets(
      'calendar amount has enough line height to remain fully visible',
      (tester) async {
        final mockRepo = _MockAnalyticsRepository();
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2025, 1, 15), totalAmount: 1200),
          ],
        );
        final container = ProviderContainer.test(
          overrides: [
            listFilterProvider.overrideWith(() => _JanuaryListFilter()),
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
            appSettingsProvider.overrideWith(
              (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
            ),
          ],
        );

        await _pumpCalendarHeader(tester, container);

        final amount = find.text('1.2千');
        expect(amount, findsOneWidget);
        expect(
          tester.widget<Text>(amount).style?.fontSize,
          AppTypography.compact,
        );
        expect(
          tester.getSize(amount).height,
          greaterThanOrEqualTo(AppTypography.compactLineHeight),
        );
      },
    );

    testWidgets('V15 outside-month dates cannot select or switch the filter', (
      tester,
    ) async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);
      final container = ProviderContainer.test(
        overrides: [
          listFilterProvider.overrideWith(() => _JanuaryListFilter()),
          analyticsRepositoryProvider.overrideWithValue(mockRepo),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
          ),
        ],
      );

      await _pumpCalendarHeader(tester, container);

      // January 2025 starts on Wednesday, so the first visible 30 belongs to
      // December 2024; tapping it must be ignored.
      await tester.tap(find.text('30').first);
      await tester.pump();

      expect(container.read(listFilterProvider).activeDayFilter, isNull);
      expect(container.read(listFilterProvider).selectedMonth, 1);
    });
  });
}
