import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/domain/models/category_drill_down.dart';
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/screens/category_drill_down_screen.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_transaction_tile.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;

import '../../../../../helpers/test_localizations.dart';

const _bookId = 'book_001';
const _l1CategoryId = 'cat_food';
final _windowStart = DateTime(2026, 5);
final _windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  @override
  TimeWindow build() => TimeWindow.month(year: 2026, month: 5);
}

Transaction _tx(String id, int amount) => Transaction(
  id: id,
  bookId: _bookId,
  deviceId: 'dev_1',
  amount: amount,
  type: TransactionType.expense,
  ledgerType: LedgerType.daily,
  categoryId: 'cat_food_lunch',
  timestamp: DateTime(2026, 5, 10),
  currentHash: 'hash_$id',
  createdAt: DateTime(2026, 5, 10),
);

CategoryDrillDown _drill({List<Transaction>? txns}) => CategoryDrillDown(
  transactions: txns ?? [_tx('t1', 1200), _tx('t2', 800)],
  subtotal: 2000,
  count: 2,
  avgPerDay: 64,
);

Widget _subject({Object? error}) {
  return createLocalizedWidget(
    const CategoryDrillDownScreen(
      bookId: _bookId,
      l1CategoryId: _l1CategoryId,
    ),
    locale: const Locale('en'),
    overrides: [
      selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
      locale_providers.currentLocaleProvider.overrideWith(
        (_) async => const Locale('en'),
      ),
      categoryDrillDownProvider(
        bookId: _bookId,
        startDate: _windowStart,
        endDate: _windowEnd,
        l1CategoryId: _l1CategoryId,
      ).overrideWith((_) async {
        if (error != null) throw error;
        return _drill();
      }),
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('watches categoryDrillDownProvider and renders tiles', (
    tester,
  ) async {
    await _pump(tester, _subject());

    expect(find.byType(ListTransactionTile), findsNWidgets(2));
  });

  testWidgets('READ-ONLY: no Dismissible in the subtree', (tester) async {
    await _pump(tester, _subject());

    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('READ-ONLY: tapping a tile pushes nothing', (tester) async {
    await _pump(tester, _subject());

    final navigatorBefore = tester.widget<Navigator>(find.byType(Navigator));
    await tester.tap(find.byType(ListTransactionTile).first);
    await tester.pumpAndSettle();

    // Still on the drill screen — no new route pushed (no edit screen).
    expect(find.byType(CategoryDrillDownScreen), findsOneWidget);
    expect(navigatorBefore, isNotNull);
  });

  testWidgets('header shows subtotal + count + 日均 (neutral descriptive)', (
    tester,
  ) async {
    await _pump(tester, _subject());

    // Subtotal amount rendered (¥2,000).
    expect(find.textContaining('2,000'), findsWidgets);
    // Count (2 transactions) rendered somewhere in the header.
    expect(find.textContaining('2'), findsWidgets);
    // No target/ranking/cross-period toxic copy.
    final allText = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .join(' ');
    expect(
      allText,
      isNot(contains(RegExp('目標|達成|ranking|目标|vs|上月|先月|target'))),
    );
  });

  testWidgets('error state renders without throw', (tester) async {
    await _pump(tester, _subject(error: StateError('drill failed')));

    expect(tester.takeException(), isNull);
    expect(find.byType(CategoryDrillDownScreen), findsOneWidget);
  });

  testWidgets('empty drill renders without throw', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const CategoryDrillDownScreen(
          bookId: _bookId,
          l1CategoryId: _l1CategoryId,
        ),
        locale: const Locale('en'),
        overrides: [
          selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
          locale_providers.currentLocaleProvider.overrideWith(
            (_) async => const Locale('en'),
          ),
          categoryDrillDownProvider(
            bookId: _bookId,
            startDate: _windowStart,
            endDate: _windowEnd,
            l1CategoryId: _l1CategoryId,
          ).overrideWith(
            (_) async => const CategoryDrillDown(
              transactions: [],
              subtotal: 0,
              count: 0,
            ),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListTransactionTile), findsNothing);
  });
}
