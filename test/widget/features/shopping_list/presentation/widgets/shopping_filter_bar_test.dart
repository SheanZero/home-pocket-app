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
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_reorder.dart';
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

    // EC2 D-2: trailing reorder toggle renders ≡ by default and toggles the
    // shoppingReorderModeProvider on tap (switching the icon to ✓).
    testWidgets(
      'EC2 D-2: trailing ≡ enters reorder mode and becomes ✓',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        // Default (non-reorder): reorder entry icon present, exit icon absent.
        expect(find.byIcon(Icons.reorder), findsOneWidget);
        expect(find.byIcon(Icons.check), findsNothing);
        expect(container.read(shoppingReorderModeProvider), isFalse);

        // Tap ≡ → reorder mode true, icon becomes ✓.
        await tester.tap(find.byIcon(Icons.reorder));
        await tester.pumpAndSettle();

        expect(container.read(shoppingReorderModeProvider), isTrue);
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.byIcon(Icons.reorder), findsNothing);
      },
    );

    // EC2 D-2: reorder mode does NOT add drag_indicator prefixes to chips.
    testWidgets(
      'EC2 D-2: reorder mode does NOT add drag_indicator to chip prefixes',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        // No drag_indicator in normal mode.
        expect(find.byIcon(Icons.drag_indicator), findsNothing);

        container.read(shoppingReorderModeProvider.notifier).toggle();
        await tester.pumpAndSettle();

        // Reorder mode must NOT add drag_indicator to any chip (Fix 1).
        // The trailing reorder toggle uses Icons.reorder (not drag_indicator),
        // so zero drag_indicator icons should appear in the entire filter bar.
        expect(find.byIcon(Icons.drag_indicator), findsNothing);
      },
    );
  });

  group('ShoppingFilterBar — 私有 chip', () {
    // FILTER-PRIVATE-01: chip renders with correct label in ja locale.
    testWidgets(
      'FILTER-PRIVATE-01: 私有 chip renders with correct label in ja locale',
      (tester) async {
        await _pumpFilterBar(tester);

        expect(find.byKey(const Key('shopping_filter_private_chip')), findsOneWidget);
        expect(find.text('私有'), findsOneWidget);
      },
    );

    // FILTER-PRIVATE-02: tapping chip when inactive sets showPrivateOnly=true.
    testWidgets(
      'FILTER-PRIVATE-02: tapping 私有 chip sets showPrivateOnly=true',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
        await tester.pumpAndSettle();

        expect(
          container.read(shoppingFilterProvider).showPrivateOnly,
          isTrue,
          reason: 'Tapping inactive chip must set showPrivateOnly to true',
        );
      },
    );

    // FILTER-PRIVATE-03: tapping active chip deactivates (toggle off).
    testWidgets(
      'FILTER-PRIVATE-03: tapping active 私有 chip deactivates showPrivateOnly',
      (tester) async {
        final container = await _pumpFilterBar(tester);

        // Pre-set showPrivateOnly = true
        container.read(shoppingFilterProvider.notifier).setPrivateFilter(true);
        await tester.pumpAndSettle();

        // Tap the active chip to toggle off
        await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
        await tester.pumpAndSettle();

        expect(
          container.read(shoppingFilterProvider).showPrivateOnly,
          isFalse,
          reason: 'Tapping active chip must toggle showPrivateOnly to false',
        );
      },
    );

    // FILTER-PRIVATE-04: chip present regardless of group mode.
    testWidgets(
      'FILTER-PRIVATE-04: 私有 chip present regardless of group mode (solo)',
      (tester) async {
        // No isGroupModeProvider override — defaults to solo (false).
        await _pumpFilterBar(tester);

        expect(
          find.byKey(const Key('shopping_filter_private_chip')),
          findsOneWidget,
          reason: 'Chip must render in solo mode (no group)',
        );
      },
    );
  });
}
