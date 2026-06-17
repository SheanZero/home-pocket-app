@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/joy_calendar_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [JoyCalendarCard] (小确幸日历, round-5 B card #4, Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja/zh/en × light/dark (6 collapsed-state masters)
/// - + inline-expand `_InlineDayPanel` state (D-08② / WR-04 fix site): tap day
///   15, override [joyDayTransactionsProvider] with that day's joy rows, settle
///   the `AnimatedSize` grow, then capture (1 master).
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);
final _anchor = DateTime(2026, 5);
final _expandDay = DateTime(2026, 5, 15);

/// Deterministic per-day joy counts across the month (cell depth = f(count)).
List<PerDayJoyCount> _fixtureCounts() => [
  PerDayJoyCount(date: DateTime(2026, 5, 3), count: 1),
  PerDayJoyCount(date: DateTime(2026, 5, 8), count: 2),
  PerDayJoyCount(date: DateTime(2026, 5, 15), count: 3),
  PerDayJoyCount(date: DateTime(2026, 5, 22), count: 1),
  PerDayJoyCount(date: DateTime(2026, 5, 27), count: 2),
];

Transaction _tx(String id, int amount, int joyFullness, String categoryId) =>
    Transaction(
      id: id,
      bookId: _bookId,
      deviceId: 'dev_local',
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      ledgerType: LedgerType.joy,
      timestamp: DateTime(2026, 5, 15, 12),
      currentHash: 'hash_$id',
      createdAt: DateTime(2026, 5, 15, 12),
    );

/// Day-15 joy rows for the inline expand panel.
List<Transaction> _fixtureDayTxns() => [
  _tx('tx_1', 3200, 9, 'cat_hobbies'),
  _tx('tx_2', 1800, 8, 'cat_social'),
];

Widget _wrap({
  required Locale locale,
  ThemeMode themeMode = ThemeMode.light,
  bool withExpand = false,
  double height = 460,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      perDayJoyCountsProvider(
        bookId: _bookId,
        anchor: _anchor,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => _fixtureCounts()),
      joyDayTransactionsProvider(
        bookId: _bookId,
        day: _expandDay,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => withExpand ? _fixtureDayTxns() : const []),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: height,
            child: SingleChildScrollView(
              child: JoyCalendarCard(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
                joyMetricVariant: JoyMetricVariant.all,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('JoyCalendarCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('collapsed — light $tag', (tester) async {
        await tester.pumpWidget(_wrap(locale: locale));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(JoyCalendarCard),
          matchesGoldenFile('goldens/joy_calendar_card_light_$tag.png'),
        );
      });

      testWidgets('collapsed — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(locale: locale, themeMode: ThemeMode.dark),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(JoyCalendarCard),
          matchesGoldenFile('goldens/joy_calendar_card_dark_$tag.png'),
        );
      });
    }

    // Inline-expand state (D-08② / WR-04): tap day 15 → _InlineDayPanel grows.
    testWidgets('inline expand — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), withExpand: true, height: 640),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('joy_day_15')));
      await tester.pumpAndSettle();

      // The inline panel must be present (the day select expanded the card).
      expect(
        find.byKey(const ValueKey('joy_calendar_inline_panel')),
        findsOneWidget,
      );

      await expectLater(
        find.byType(JoyCalendarCard),
        matchesGoldenFile('goldens/joy_calendar_card_expand_light_ja.png'),
      );
    });
  });
}
