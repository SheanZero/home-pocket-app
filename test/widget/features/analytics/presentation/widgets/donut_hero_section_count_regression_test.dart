import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/donut_hero.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/test_localizations.dart';

/// Regression for the fl_chart `RenderPieChart.badgeWidgetPaint` RangeError
/// (260622-d5i follow-up). The donut gives sections a `badgeWidget` (the on-ring
/// L1 icon + %) only when the slice share ≥ 5%. fl_chart builds one badge child
/// per section (`toWidgets()`), but `badgeWidgetPaint` indexes the **animation-
/// lerped** `data.sections[counter]`. When the section COUNT GROWS, the first
/// post-change frame evaluates the implicit tween at the OLD (shorter) data while
/// the badge children are already the NEW (longer) list → `data.sections[counter]`
/// throws `RangeError`. Disabling the slice-morph animation keeps `data` equal to
/// the target every frame, so the child/section counts can never desync.
Category _cat(String id) => Category(
  id: id,
  name: id,
  icon: 'icon',
  color: '#000000',
  parentId: null,
  level: 1,
  createdAt: DateTime(2026),
);

CategoryBreakdown _bd(String id, int amount) => CategoryBreakdown(
  categoryId: id,
  categoryName: id,
  icon: 'icon',
  color: '#000000',
  amount: amount,
  percentage: 0,
  transactionCount: 1,
);

void main() {
  testWidgets(
    'regression(260622-d5i): growing the donut section count does not throw a '
    'fl_chart badge RangeError during the slice animation',
    (tester) async {
      final map = <String, Category>{
        for (var i = 0; i < 4; i++) 'cat_$i': _cat('cat_$i'),
      };

      // Start with ONE section at 100% share → it carries an on-ring badge.
      var rows = <CategoryBreakdown>[_bd('cat_0', 10000)];
      const total = 10000;
      late StateSetter setOuter;

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (ctx, setState) {
                  setOuter = setState;
                  return DonutHero(
                    breakdowns: rows,
                    total: total,
                    entryCount: rows.length,
                    month: 5,
                    joyL1Ids: const <String>{},
                    categoryMap: map,
                    bookId: 'book_001',
                  );
                },
              ),
            ),
          ),
          locale: const Locale('en'),
          overrides: [
            locale_providers.currentLocaleProvider.overrideWith(
              (_) async => const Locale('en'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // GROW to four sections (each ≥ 5% → each gets a badge widget).
      setOuter(() {
        rows = [
          _bd('cat_0', 4000),
          _bd('cat_1', 3000),
          _bd('cat_2', 2000),
          _bd('cat_3', 1000),
        ];
      });

      // Step across the (former) ~150ms morph window one frame at a time; the
      // very first post-change frame is where the desync paints.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 8));
        expect(
          tester.takeException(),
          isNull,
          reason: 'frame $i after the donut section count grew 1 → 4',
        );
      }

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
