import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/per_category_breakdown_card.dart';

import '../../../../../helpers/test_localizations.dart';

const _locale = Locale('ja');
const _bookId = 'book_a';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 6, 1);

PerCategoryJoyBreakdownItem _item(String id, double avg, int count) =>
    PerCategoryJoyBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );

PerCategoryJoyBreakdown _breakdown({
  required List<PerCategoryJoyBreakdownItem> items,
  int otherCount = 0,
  int otherCategoryCount = 0,
}) {
  final qualifyingTotal = items.fold<int>(0, (s, r) => s + r.totalCount);
  return PerCategoryJoyBreakdown(
    items: items,
    totalCount: qualifyingTotal + otherCount,
    otherCount: otherCount,
    otherCategoryCount: otherCategoryCount,
  );
}

Widget _buildSubject({
  PerCategoryScope scope = PerCategoryScope.solo,
  required List<Override> overrides,
}) {
  return createLocalizedWidget(
    PerCategoryBreakdownCard(
      bookId: _bookId,
      startDate: _startDate,
      endDate: _endDate,
      locale: _locale,
      scope: scope,
    ),
    locale: _locale,
    overrides: overrides,
  );
}

void main() {
  testWidgets('loading state — shows placeholder, no row text', (tester) async {
    final completer = Completer<MetricResult<PerCategoryJoyBreakdown>>();
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) => completer.future),
        ],
      ),
    );

    // Pump a frame but do NOT settle (the future never completes).
    await tester.pump();

    // The card title is always present.
    expect(find.text('ときめき · カテゴリ'), findsOneWidget);
    // Loading body should not render Empty copy or any toggle affordance.
    expect(find.text('今期はカテゴリデータがありません'), findsNothing);
    expect(find.text('すべて表示'), findsNothing);
    expect(find.text('折りたたむ'), findsNothing);

    completer.complete(const Empty<PerCategoryJoyBreakdown>());
    await tester.pumpAndSettle();
  });

  testWidgets('empty state — shows analyticsPerCategoryEmpty body',
      (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith(
            (_) async => const Empty<PerCategoryJoyBreakdown>(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今期はカテゴリデータがありません'), findsOneWidget);
    expect(find.text('すべて表示'), findsNothing);
  });

  testWidgets('sub-min-N only — Other fold row visible', (tester) async {
    final breakdown = _breakdown(
      items: const [],
      otherCount: 5,
      otherCategoryCount: 2,
    );
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) async => Value(breakdown, 5)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // ja format: "その他：{totalCount} 件、{categoryCount} カテゴリ"
    expect(find.text('その他：5 件、2 カテゴリ'), findsOneWidget);
    // No Show all when no qualifying items.
    expect(find.text('すべて表示'), findsNothing);
  });

  testWidgets('value with 3 rows — no Show all affordance', (tester) async {
    final breakdown = _breakdown(
      items: [
        _item('cat_food', 8.5, 7),
        _item('cat_transport', 7.2, 4),
        _item('cat_housing', 6.4, 3),
      ],
    );
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) async => Value(breakdown, 14)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // ja row format: "{categoryName} · 平均 {avgSat} / {count} 件"
    expect(find.textContaining('平均 8.5 / 7 件'), findsOneWidget);
    expect(find.textContaining('平均 7.2 / 4 件'), findsOneWidget);
    expect(find.textContaining('平均 6.4 / 3 件'), findsOneWidget);
    // No expansion affordance with <=5 qualifying items.
    expect(find.text('すべて表示'), findsNothing);
    expect(find.text('折りたたむ'), findsNothing);
  });

  testWidgets('value with 7 rows — Show all expansion toggle', (tester) async {
    final breakdown = _breakdown(
      items: [
        _item('cat_food', 9.0, 8),
        _item('cat_transport', 8.5, 7),
        _item('cat_housing', 8.0, 6),
        _item('cat_entertainment', 7.5, 5),
        _item('cat_education', 7.0, 4),
        _item('cat_health', 6.5, 4),
        _item('cat_other', 6.0, 3),
      ],
    );
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) async => Value(breakdown, 37)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Initially: top-5 rows visible + Show all.
    expect(find.textContaining('平均 9.0 / 8 件'), findsOneWidget);
    expect(find.textContaining('平均 7.0 / 4 件'), findsOneWidget);
    // Rows 6 + 7 are hidden until expansion.
    expect(find.textContaining('平均 6.5 / 4 件'), findsNothing);
    expect(find.textContaining('平均 6.0 / 3 件'), findsNothing);
    expect(find.text('すべて表示'), findsOneWidget);
    expect(find.text('折りたたむ'), findsNothing);

    // Expand.
    await tester.tap(find.text('すべて表示'));
    await tester.pumpAndSettle();

    expect(find.textContaining('平均 6.5 / 4 件'), findsOneWidget);
    expect(find.textContaining('平均 6.0 / 3 件'), findsOneWidget);
    expect(find.text('折りたたむ'), findsOneWidget);
    expect(find.text('すべて表示'), findsNothing);

    // Collapse back.
    await tester.tap(find.text('折りたたむ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('平均 6.5 / 4 件'), findsNothing);
    expect(find.text('すべて表示'), findsOneWidget);
  });

  testWidgets('scope=family — uses family provider + family title',
      (tester) async {
    final breakdown = _breakdown(
      items: [
        _item('cat_food', 8.0, 6),
        _item('cat_transport', 7.5, 5),
      ],
    );
    await tester.pumpWidget(
      _buildSubject(
        scope: PerCategoryScope.family,
        overrides: [
          perCategoryJoyBreakdownFamilyProvider(
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) async => Value(breakdown, 11)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // ja family title: "ときめき · 家族のカテゴリ"
    expect(find.text('ときめき · 家族のカテゴリ'), findsOneWidget);
    // Solo title must NOT appear under family scope.
    expect(find.text('ときめき · カテゴリ'), findsNothing);
    expect(find.textContaining('平均 8.0 / 6 件'), findsOneWidget);
  });

  testWidgets('error state — AnalyticsCardErrorState rendered', (tester) async {
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith(
            (_) => Future.error(StateError('boom')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
  });

  testWidgets('value with 6 qualifying + otherCount=3 — Other + Show all',
      (tester) async {
    final breakdown = _breakdown(
      items: [
        _item('cat_food', 9.0, 8),
        _item('cat_transport', 8.5, 7),
        _item('cat_housing', 8.0, 6),
        _item('cat_entertainment', 7.5, 5),
        _item('cat_education', 7.0, 4),
        _item('cat_health', 6.5, 4),
      ],
      otherCount: 3,
      otherCategoryCount: 2,
    );
    await tester.pumpWidget(
      _buildSubject(
        overrides: [
          perCategoryJoyBreakdownProvider(
            bookId: _bookId,
            startDate: _startDate,
            endDate: _endDate,
          ).overrideWith((_) async => Value(breakdown, 37)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Top 5 visible; row 6 hidden until expansion.
    expect(find.textContaining('平均 9.0 / 8 件'), findsOneWidget);
    expect(find.textContaining('平均 6.5 / 4 件'), findsNothing);
    // Other row visible regardless of expansion state.
    expect(find.text('その他：3 件、2 カテゴリ'), findsOneWidget);
    // Show all visible.
    expect(find.text('すべて表示'), findsOneWidget);
  });
}
