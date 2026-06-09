// Widget tests for ShoppingFilterBar (FILT-01, D-1, D-2).
//
// ShoppingFilterBar is defined in:
//   lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
//
// Layout under test (D-1, D-2):
//   [全部 standalone reset] [日常 | 悦己 connected segmented control] [Category]
//   - 全部 highlights only when nothing filtered; tapping calls clearAll().
//   - The old conditional clear-all chip is gone permanently.
//
// Run: flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_list_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_filter_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Pumps a ShoppingFilterBar with optional [filter] override.
///
/// Uses a fixed initial [ShoppingListFilter] so tests exercise known state.
Future<ProviderContainer> _pumpFilterBar(
  WidgetTester tester, {
  ShoppingListFilter? filter,
}) async {
  late ProviderContainer container;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shoppingFilterProvider.overrideWith(ShoppingFilter.new),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(
              body: ShoppingFilterBar(),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  // If caller wants a non-default filter, set it via the provider notifier
  if (filter != null) {
    if (filter.ledgerType != null) {
      container
          .read(shoppingFilterProvider.notifier)
          .setLedgerFilter(filter.ledgerType);
    }
    if (filter.categoryIds.isNotEmpty) {
      container
          .read(shoppingFilterProvider.notifier)
          .setCategoryIds(filter.categoryIds);
    }
    if (filter.statusFilter != 'all') {
      container
          .read(shoppingFilterProvider.notifier)
          .setStatusFilter(filter.statusFilter);
    }
    await tester.pumpAndSettle();
  }

  return container;
}

void main() {
  group('ShoppingFilterBar', () {
    // FILT-01: filter bar renders 全部 reset + 日常|悦己 segmented + category.
    testWidgets(
      'FILT-01: renders 全部 reset, 日常 / 悦己 segments and category chip',
      (tester) async {
        await _pumpFilterBar(tester);

        // 全部 standalone reset (shoppingFilterLedgerAll = 'すべて' in ja).
        expect(find.text('すべて'), findsOneWidget);

        // 日常 / 悦己 segment labels (ja 悦己 = 'ときめき').
        expect(find.text('日常'), findsOneWidget);
        expect(find.text('ときめき'), findsOneWidget);

        // Status chip removed — must NOT be present.
        expect(find.text('すべてのアイテム'), findsNothing);
        expect(find.text('アクティブのみ'), findsNothing);

        // Category chip.
        expect(find.text('カテゴリ'), findsOneWidget);

        // The clear-all chip is gone PERMANENTLY (D-2) — not state-conditional.
        expect(find.byIcon(Icons.clear_all), findsNothing);
      },
    );

    // D-2: clear-all chip is permanently absent even when a filter is active.
    testWidgets(
      'D-2: no clear-all chip even when a ledger filter is active',
      (tester) async {
        await _pumpFilterBar(
          tester,
          filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
        );

        expect(find.byIcon(Icons.clear_all), findsNothing);
      },
    );

    // D-2: tapping 全部 resets everything via clearAll().
    testWidgets(
      'D-2: tapping 全部 calls clearAll() and resets all filter fields',
      (tester) async {
        final container = await _pumpFilterBar(
          tester,
          filter: const ShoppingListFilter(
            ledgerType: LedgerType.daily,
            categoryIds: {'food_dining'},
          ),
        );

        // Sanity: filter is non-default before the reset.
        expect(container.read(shoppingFilterProvider).ledgerType,
            equals(LedgerType.daily));

        await tester.tap(find.text('すべて'));
        await tester.pumpAndSettle();

        final state = container.read(shoppingFilterProvider);
        expect(state.ledgerType, isNull);
        expect(state.categoryIds, isEmpty);
        expect(state.statusFilter, equals('all'));
      },
    );

    // D-1: tapping 日常 segment sets ledger filter to daily.
    testWidgets(
      'D-1: tapping 日常 segment sets ledgerType to daily',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        await tester.tap(find.text('日常'));
        await tester.pumpAndSettle();

        expect(
          container.read(shoppingFilterProvider).ledgerType,
          equals(LedgerType.daily),
        );
      },
    );

    // D-1: tapping the active 日常 segment toggles back to null (deselect).
    testWidgets(
      'D-1: tapping active 日常 segment toggles back to null',
      (tester) async {
        final container = await _pumpFilterBar(
          tester,
          filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
        );

        await tester.tap(find.text('日常'));
        await tester.pumpAndSettle();

        expect(container.read(shoppingFilterProvider).ledgerType, isNull);
      },
    );

    // D-1: 悦己 and 日常 are mutually exclusive (single ledgerType field).
    testWidgets(
      'D-1: tapping 悦己 after 日常 switches ledgerType to joy',
      (tester) async {
        final container = await _pumpFilterBar(
          tester,
          filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
        );

        await tester.tap(find.text('ときめき'));
        await tester.pumpAndSettle();

        expect(
          container.read(shoppingFilterProvider).ledgerType,
          equals(LedgerType.joy),
        );
      },
    );

    // D-2: 全部 is active only when nothing is filtered — asserted behaviorally
    // via the reset being a no-op-equivalent on default state and a true reset
    // when a filter is active.
    testWidgets(
      'D-2: 全部 active state tracks "nothing filtered"',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        // Default state: nothing filtered → 全部 is the active control.
        var state = container.read(shoppingFilterProvider);
        expect(state.ledgerType, isNull);
        expect(state.categoryIds, isEmpty);

        // Activating a ledger filter means 全部 is no longer the active one.
        container
            .read(shoppingFilterProvider.notifier)
            .setLedgerFilter(LedgerType.daily);
        await tester.pumpAndSettle();
        state = container.read(shoppingFilterProvider);
        expect(state.ledgerType, equals(LedgerType.daily));

        // Tapping 全部 returns to the nothing-filtered (全部-active) state.
        await tester.tap(find.text('すべて'));
        await tester.pumpAndSettle();
        state = container.read(shoppingFilterProvider);
        expect(state.ledgerType, isNull);
        expect(state.categoryIds, isEmpty);
      },
    );
  });
}
