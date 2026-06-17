@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/cards/category_donut_card.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [CategoryDonutCard] (round-5 B card #2, Plan 47-05).
///
/// Coverage (GUARD-04 / 47-UI-SPEC §Golden Visual-Contract Matrix):
/// - ja/zh/en × light/dark (6 value-state masters)
/// - + WR-02 >10-L1 "Other"-slice state (1 master) — the neutral long-tail
///   rollup slice that reconciles to the TRUE total
/// - + empty state (1 master)
///
/// Wraps the PRODUCTION [AppTheme] so `context.palette` resolves the real
/// ADR-019 palette (critical: the WR-02 neutral "Other" swatch is
/// `palette.textTertiary`, palette-resolved — the golden must capture it).
/// The donut center count-up (`TweenAnimationBuilder<int>`, ~480ms) is settled
/// via `pumpAndSettle()` before capture (D-09), so the center lands on the TRUE
/// total.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 5, 31, 23, 59, 59);

Category _cat(String id, {String? parent, int level = 1}) => Category(
  id: id,
  name: id,
  icon: 'icon',
  color: '#000000',
  parentId: parent,
  level: level,
  createdAt: DateTime(2026),
);

CategoryBreakdown _bd(String id, int amount, double pct) => CategoryBreakdown(
  categoryId: id,
  categoryName: id,
  icon: 'icon',
  color: '#000000',
  amount: amount,
  percentage: pct,
  transactionCount: 1,
);

MonthlyReport _report(List<CategoryBreakdown> breakdowns, int total) =>
    MonthlyReport(
      year: 2026,
      month: 5,
      totalIncome: 0,
      totalExpenses: total,
      savings: 0,
      savingsRate: 0,
      dailyTotal: total,
      joyTotal: 0,
      categoryBreakdowns: breakdowns,
      dailyExpenses: const [],
    );

/// Deterministic 4-L1 fixture (≤10 categories → no Other row).
final _categoryMapFour = <String, Category>{
  'cat_food': _cat('cat_food'),
  'cat_transport': _cat('cat_transport'),
  'cat_hobbies': _cat('cat_hobbies'),
  'cat_education': _cat('cat_education'),
};

final _breakdownsFour = [
  _bd('cat_food', 60000, 50),
  _bd('cat_transport', 36000, 30),
  _bd('cat_hobbies', 18000, 15),
  _bd('cat_education', 6000, 5),
];

MonthlyReport _reportFour() => _report(_breakdownsFour, 120000);

/// >10-L1 "Other" state (WR-02): 12 L1 categories each ¥3,000 → donut keeps the
/// top 10 (¥30,000), residual long-tail ¥6,000 surfaces as the neutral "Other"
/// slice/row; TRUE total ¥36,000.
final _categoryMapMany = <String, Category>{
  for (var i = 0; i < 12; i++) 'cat_$i': _cat('cat_$i'),
};

final _breakdownsMany = [for (var i = 0; i < 12; i++) _bd('cat_$i', 3000, 0)];

MonthlyReport _reportMany() => _report(_breakdownsMany, 36000);

Widget _wrap({
  required Locale locale,
  required MonthlyReport report,
  required Map<String, Category> categoryMap,
  ThemeMode themeMode = ThemeMode.light,
  double height = 620,
}) {
  return ProviderScope(
    overrides: [
      locale_providers.currentLocaleProvider.overrideWith((_) async => locale),
      monthlyReportProvider(
        bookId: _bookId,
        startDate: _startDate,
        endDate: _endDate,
        joyMetricVariant: JoyMetricVariant.all,
      ).overrideWith((_) async => report),
      analyticsCategoriesMapProvider.overrideWith((_) async => categoryMap),
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
              child: CategoryDonutCard(
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
  group('CategoryDonutCard golden', () {
    for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
      final tag = locale.languageCode;
      testWidgets('value — light $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            report: _reportFour(),
            categoryMap: _categoryMapFour,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(CategoryDonutCard),
          matchesGoldenFile('goldens/category_donut_card_light_$tag.png'),
        );
      });

      testWidgets('value — dark $tag', (tester) async {
        await tester.pumpWidget(
          _wrap(
            locale: locale,
            report: _reportFour(),
            categoryMap: _categoryMapFour,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(CategoryDonutCard),
          matchesGoldenFile('goldens/category_donut_card_dark_$tag.png'),
        );
      });
    }

    // WR-02: >10-L1 "Other"-slice state — light ja + dark en spot-check.
    testWidgets('other slice — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          report: _reportMany(),
          categoryMap: _categoryMapMany,
          height: 900,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDonutCard),
        matchesGoldenFile('goldens/category_donut_card_other_light_ja.png'),
      );
    });

    testWidgets('other slice — dark en', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('en'),
          report: _reportMany(),
          categoryMap: _categoryMapMany,
          themeMode: ThemeMode.dark,
          height: 900,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDonutCard),
        matchesGoldenFile('goldens/category_donut_card_other_dark_en.png'),
      );
    });

    testWidgets('empty — light ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          report: _report(const [], 0),
          categoryMap: const {},
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CategoryDonutCard),
        matchesGoldenFile('goldens/category_donut_card_empty_light_ja.png'),
      );
    });
  });
}
