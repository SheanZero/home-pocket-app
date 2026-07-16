import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_calendar_compact_transaction_row.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/joy_calendar_heatmap.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
// May 2026: the 1st is a Friday (weekday 5), 31 days.
final _start = DateTime(2026, 5);
final _end = DateTime(2026, 5, 31, 23, 59, 59);
final _anchor = DateTime(2026, 5);

List<PerDayJoyCount> _counts() => [
  PerDayJoyCount(date: DateTime(2026, 5, 3), count: 1),
  PerDayJoyCount(date: DateTime(2026, 5, 12), count: 4),
  PerDayJoyCount(date: DateTime(2026, 5, 20), count: 2),
];

Transaction _tx(String id, DateTime ts) => Transaction(
  id: id,
  bookId: _bookId,
  deviceId: 'dev',
  amount: 1200,
  type: TransactionType.expense,
  categoryId: 'cat_hobbies',
  ledgerType: LedgerType.joy,
  timestamp: ts,
  currentHash: 'h',
  createdAt: ts,
  joyFullness: 7,
  entrySource: EntrySource.manual,
);

Widget _subject({
  AsyncValue<List<PerDayJoyCount>>? override,
  List<Transaction>? dayTxns,
}) {
  final value = override ?? AsyncValue.data(_counts());
  return createLocalizedWidget(
    SingleChildScrollView(
      child: JoyCalendarCard(
        bookId: _bookId,
        startDate: _start,
        endDate: _end,
        joyMetricVariant: JoyMetricVariant.all,
      ),
    ),
    locale: const Locale('zh'),
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('zh'),
      ),
      perDayJoyCountsProvider(
        bookId: _bookId,
        anchor: _anchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith(
        (_) => value.when(
          data: (d) async => d,
          loading: () => Completer<List<PerDayJoyCount>>().future,
          error: (e, _) async => throw StateError(e.toString()),
        ),
      ),
      // The inline-expand day read: any day → the supplied joy txns (default []).
      joyDayTransactionsProvider(
        bookId: _bookId,
        day: DateTime(2026, 5, 12),
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith(
        (_) async =>
            dayTxns ??
            [
              _tx('t1', DateTime(2026, 5, 12, 10)),
              _tx('t2', DateTime(2026, 5, 12, 14)),
            ],
      ),
      joyDayTransactionsProvider(
        bookId: _bookId,
        day: DateTime(2026, 5, 4),
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => const <Transaction>[]),
    ],
  );
}

void main() {
  testWidgets(
    'Test 1: 7-column month grid with correct weekday offset + day count; '
    'cell depth increases with joy count; 0-joy day = base color',
    (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      expect(find.byType(JoyCalendarHeatmap), findsOneWidget);

      final heatmap = tester.widget<JoyCalendarHeatmap>(
        find.byType(JoyCalendarHeatmap),
      );
      // May 2026 → 31 day cells exist (keyed by day-of-month).
      expect(find.byKey(const ValueKey('joy_day_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_day_31')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_day_32')), findsNothing);

      // The grid is 7 columns wide (a GridView with crossAxisCount 7).
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 7);
      expect(delegate.crossAxisSpacing, 1);
      expect(delegate.mainAxisSpacing, 1);

      // The widget received the per-day counts so depth = f(count).
      expect(heatmap.countByDay[12], 4);
      expect(heatmap.countByDay[3], 1);
      expect(heatmap.countByDay.containsKey(4), isFalse);
      expect(find.byKey(const ValueKey('joy_day_count_dot_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('joy_day_count_dot_4')), findsNothing);
    },
  );

  testWidgets(
    'Test 2: tap a day WITH joy → card expands INLINE (no route/sheet) showing '
    "that day's joy list; tapping updates selection",
    (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      // No inline panel before tapping.
      expect(
        find.byKey(const ValueKey('joy_calendar_inline_panel')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('joy_day_12')));
      await tester.pumpAndSettle();

      // Inline panel appears in place (no Navigator route, no bottom sheet).
      expect(
        find.byKey(const ValueKey('joy_calendar_inline_panel')),
        findsOneWidget,
      );
      // No bottom sheet / route was used — the panel grew in place (D-C1).
      expect(find.byType(BottomSheet), findsNothing);

      final heatmap = tester.widget<JoyCalendarHeatmap>(
        find.byType(JoyCalendarHeatmap),
      );
      expect(heatmap.selectedDay, DateTime(2026, 5, 12));
    },
  );

  testWidgets('Test 3: tap a 0-joy day → neutral inline empty copy, no throw', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('joy_day_4')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('joy_calendar_day_empty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('A9 tapping the selected day again collapses the panel', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    final day = find.byKey(const ValueKey('joy_day_12'));
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('joy_calendar_inline_panel')),
      findsOneWidget,
    );

    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('joy_calendar_inline_panel')),
      findsNothing,
    );
  });

  testWidgets('A9 expanded panel uses inset border and readable compact rows', (
    tester,
  ) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('joy_day_12')));
    await tester.pumpAndSettle();

    final panel = tester.widget<Container>(
      find.byKey(const ValueKey('joy_calendar_day_panel')),
    );
    expect(panel.margin, const EdgeInsets.fromLTRB(8, 10, 8, 0));
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.border?.top.style, BorderStyle.solid);

    expect(
      tester
          .getSize(find.byKey(const ValueKey('joy_calendar_compact_row_t1')))
          .height,
      JoyCalendarCompactTransactionRow.rowHeight,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('joy_calendar_compact_row_t2')))
          .height,
      JoyCalendarCompactTransactionRow.rowHeight,
    );
  });

  testWidgets('Test 4: ADR-016 §5 ambient — no streak/target/ranking copy '
      '(GUARD-02 readiness)', (tester) async {
    await tester.pumpWidget(_subject());
    await tester.pumpAndSettle();

    final forbidden = ['排名', '连续', '目标', '超支', '达成', 'streak', 'rank'];
    for (final token in forbidden) {
      expect(
        find.textContaining(token, findRichText: true),
        findsNothing,
        reason: 'forbidden token "$token" must not appear',
      );
    }
  });

  testWidgets('Test 5: empty month → grid renders all-empty, no throw', (
    tester,
  ) async {
    await tester.pumpWidget(_subject(override: const AsyncValue.data([])));
    await tester.pumpAndSettle();

    expect(find.byType(JoyCalendarHeatmap), findsOneWidget);
    expect(find.byKey(const ValueKey('joy_day_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test 6a: loading → SizedBox (no heatmap)', (tester) async {
    await tester.pumpWidget(_subject(override: const AsyncValue.loading()));
    await tester.pump();
    expect(find.byType(JoyCalendarHeatmap), findsNothing);
  });

  testWidgets('Test 6b: error → AnalyticsCardErrorState with retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _subject(override: AsyncValue.error('boom', StackTrace.empty)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  group('default-select-today', () {
    testWidgets(
      'A: anchor == current month → today auto-selected + inline panel '
      'auto-expanded (deterministic, y/m/d only)',
      (tester) async {
        await tester.pumpWidget(_currentMonthSubject());
        await tester.pumpAndSettle();

        // The inline panel is open without any tap (today auto-selected).
        expect(
          find.byKey(const ValueKey('joy_calendar_inline_panel')),
          findsOneWidget,
        );

        final heatmap = tester.widget<JoyCalendarHeatmap>(
          find.byType(JoyCalendarHeatmap),
        );
        final selected = heatmap.selectedDay;
        expect(selected, isNotNull);
        // Compare only y/m/d — _defaultSelectedDay reads its own DateTime.now(),
        // so a millisecond clock race against the test's now is possible.
        final now = DateTime.now();
        expect(selected!.year, now.year);
        expect(selected.month, now.month);
        expect(selected.day, now.day);
      },
    );

    testWidgets('B: anchor == a past month (May 2026) → nothing auto-selected '
        '(no ring, no inline panel)', (tester) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('joy_calendar_inline_panel')),
        findsNothing,
      );

      final heatmap = tester.widget<JoyCalendarHeatmap>(
        find.byType(JoyCalendarHeatmap),
      );
      expect(heatmap.selectedDay, isNull);
    });
  });
}

/// Builds the card with `endDate` in the CURRENT month so the card-derived
/// anchor (`DateTime(endDate.year, endDate.month)`) equals the current month,
/// driving `_defaultSelectedDay()` to auto-select today. Overrides are keyed on
/// the current month / today (pure y/m/d) to match the production code path.
Widget _currentMonthSubject() {
  final now = DateTime.now();
  final monthAnchor = DateTime(now.year, now.month);
  final today = DateTime(now.year, now.month, now.day);
  // A day in the current month, safely on or before today, used as endDate so
  // anchor resolves to the current month regardless of run date.
  final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

  return createLocalizedWidget(
    SingleChildScrollView(
      child: JoyCalendarCard(
        bookId: _bookId,
        startDate: monthAnchor,
        endDate: endDate,
        joyMetricVariant: JoyMetricVariant.all,
      ),
    ),
    locale: const Locale('zh'),
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('zh'),
      ),
      perDayJoyCountsProvider(
        bookId: _bookId,
        anchor: monthAnchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => [PerDayJoyCount(date: today, count: 2)]),
      joyDayTransactionsProvider(
        bookId: _bookId,
        day: today,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith(
        (_) async => [
          _tx('today1', DateTime(now.year, now.month, now.day, 10)),
          _tx('today2', DateTime(now.year, now.month, now.day, 14)),
        ],
      ),
    ],
  );
}
