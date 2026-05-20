import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_soul_breakdown.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/per_category_breakdown_card.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Golden tests for [PerCategoryBreakdownCard] (Plan 16-07).
///
/// Coverage:
/// - light theme, solo scope, ja locale (1 golden)
/// - dark theme, solo scope, ja locale (1 golden)
/// - light theme, family scope, ja locale (1 golden)
///
/// Per UI-SPEC §Theme Mode Coverage, both light + dark themes are required;
/// ja locale matches project golden precedent.

const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 6, 1);

PerCategorySoulBreakdownItem _item(String id, double avg, int count) =>
    PerCategorySoulBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );

/// Deterministic 5-category fixture with otherCount=2 — exercises top-5 surface
/// with an Other fold row (no Show all affordance because <=5 items qualify).
PerCategorySoulBreakdown _fixtureFiveWithOther() {
  final items = [
    _item('cat_food', 9.0, 8),
    _item('cat_transport', 8.5, 7),
    _item('cat_housing', 8.0, 6),
    _item('cat_entertainment', 7.5, 5),
    _item('cat_education', 7.0, 4),
  ];
  return PerCategorySoulBreakdown(
    items: items,
    totalCount: items.fold<int>(0, (s, r) => s + r.totalCount) + 2,
    otherCount: 2,
    otherCategoryCount: 1,
  );
}

Widget _wrap({
  required Locale locale,
  required List<Override> overrides,
  PerCategoryScope scope = PerCategoryScope.solo,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: overrides,
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
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 420,
            child: SingleChildScrollView(
              child: PerCategoryBreakdownCard(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
                locale: locale,
                scope: scope,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PerCategoryBreakdownCard golden', () {
    testWidgets('light theme — solo mode, ja locale', (tester) async {
      final breakdown = _fixtureFiveWithOther();
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          overrides: [
            perCategorySoulBreakdownProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith((_) async => Value(breakdown, breakdown.totalCount)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PerCategoryBreakdownCard),
        matchesGoldenFile('goldens/per_category_breakdown_card_light_ja.png'),
      );
    });

    testWidgets('dark theme — solo mode, ja locale', (tester) async {
      final breakdown = _fixtureFiveWithOther();
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          theme: ThemeData.dark(),
          overrides: [
            perCategorySoulBreakdownProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith((_) async => Value(breakdown, breakdown.totalCount)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PerCategoryBreakdownCard),
        matchesGoldenFile('goldens/per_category_breakdown_card_dark_ja.png'),
      );
    });

    testWidgets('light theme — group mode, family scope, ja locale',
        (tester) async {
      final breakdown = _fixtureFiveWithOther();
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          scope: PerCategoryScope.family,
          overrides: [
            perCategorySoulBreakdownFamilyProvider(
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith((_) async => Value(breakdown, breakdown.totalCount)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PerCategoryBreakdownCard),
        matchesGoldenFile(
          'goldens/per_category_breakdown_card_group_light_ja.png',
        ),
      );
    });
  });
}
