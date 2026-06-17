@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/category_drill_down.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/analytics/presentation/screens/category_drill_down_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [CategoryDrillDownScreen] (read-only drill list, D-08①,
/// Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja light + ja dark + zh/en light spot-check (4 masters)
///
/// The screen reads the active window from `selectedTimeWindowProvider` (keepAlive
/// session state — never threaded via route) and the drill rows from
/// `categoryDrillDownProvider`. Both are overridden with deterministic fixtures;
/// the list renders read-only `ListTransactionTile(readOnly: true)` rows.
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette.

const _bookId = 'book_a';
const _l1CategoryId = 'cat_food';

/// The fixed month window the test pins (range = 2026-05).
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

class _FixedTimeWindow extends SelectedTimeWindow {
  _FixedTimeWindow();

  @override
  TimeWindow build() => TimeWindow.month(year: 2026, month: 5);
}

Transaction _tx(
  String id,
  int amount,
  String categoryId, {
  LedgerType ledgerType = LedgerType.daily,
  int joyFullness = 2,
  String? merchant,
}) => Transaction(
  id: id,
  bookId: _bookId,
  deviceId: 'dev_local',
  amount: amount,
  type: TransactionType.expense,
  categoryId: categoryId,
  ledgerType: ledgerType,
  timestamp: DateTime(2026, 5, 18, 12),
  currentHash: 'hash_$id',
  createdAt: DateTime(2026, 5, 18, 12),
  merchant: merchant,
  joyFullness: joyFullness,
);

CategoryDrillDown _fixtureDrill() {
  final txns = [
    _tx('tx_1', 4200, 'cat_food_lunch', merchant: 'Cafe Mori'),
    _tx('tx_2', 2800, 'cat_food', merchant: 'Supermarket'),
    _tx(
      'tx_3',
      1500,
      'cat_food_snack',
      ledgerType: LedgerType.joy,
      joyFullness: 8,
      merchant: 'Bakery',
    ),
  ];
  final subtotal = txns.fold<int>(0, (s, t) => s + t.amount);
  return CategoryDrillDown(
    transactions: txns,
    subtotal: subtotal,
    count: txns.length,
    avgPerDay: 280,
  );
}

Widget _wrap({required Locale locale, ThemeMode themeMode = ThemeMode.light}) {
  return ProviderScope(
    overrides: [
      selectedTimeWindowProvider.overrideWith(_FixedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      categoryDrillDownProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        l1CategoryId: _l1CategoryId,
      ).overrideWith((_) async => _fixtureDrill()),
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
      home: const CategoryDrillDownScreen(
        bookId: _bookId,
        l1CategoryId: _l1CategoryId,
      ),
    ),
  );
}

void main() {
  group('CategoryDrillDownScreen golden', () {
    testWidgets('drill list — light ja', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('ja')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDrillDownScreen),
        matchesGoldenFile('goldens/category_drill_down_screen_light_ja.png'),
      );
    });

    testWidgets('drill list — dark ja', (tester) async {
      await tester.pumpWidget(
        _wrap(locale: const Locale('ja'), themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDrillDownScreen),
        matchesGoldenFile('goldens/category_drill_down_screen_dark_ja.png'),
      );
    });

    testWidgets('drill list — light zh', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('zh')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDrillDownScreen),
        matchesGoldenFile('goldens/category_drill_down_screen_light_zh.png'),
      );
    });

    testWidgets('drill list — light en', (tester) async {
      await tester.pumpWidget(_wrap(locale: const Locale('en')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDrillDownScreen),
        matchesGoldenFile('goldens/category_drill_down_screen_light_en.png'),
      );
    });
  });
}
