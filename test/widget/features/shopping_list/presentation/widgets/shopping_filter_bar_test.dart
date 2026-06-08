// Widget tests for ShoppingFilterBar (FILT-01, FILT-03).
//
// ShoppingFilterBar is defined in:
//   lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
//
// Tests:
//   FILT-01: filter bar renders ledger chips (All/日常/悦己) and status chip
//   FILT-03: clear-all chip visible when any filter active; tapping calls clearAll()
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
        shoppingFilterProvider.overrideWith(() {
          final n = ShoppingFilter();
          // We set the initial state after the provider is built via a listener,
          // but it is simpler to just pump with a known override.
          return n;
        }),
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
    // FILT-01: filter bar renders ledger chips and status chip
    testWidgets(
      'FILT-01: renders All / 日常 / 悦己 ledger chips and status chip',
      (tester) async {
        await _pumpFilterBar(tester);

        // Ledger: "All" chip should appear (shoppingFilterLedgerAll = 'すべて' in ja)
        expect(find.text('すべて'), findsWidgets);

        // Ledger: 日常 chip
        expect(find.text('日常'), findsOneWidget);

        // Ledger: 悦己 chip (ja = 'ときめき')
        expect(find.text('ときめき'), findsOneWidget);

        // Status chip (ja = 'すべてのアイテム' for all / 'アクティブのみ' for active)
        // Initial state: statusFilter='all' → 'すべてのアイテム'
        expect(find.text('すべてのアイテム'), findsOneWidget);

        // Category chip
        expect(find.text('カテゴリ'), findsOneWidget);

        // No clear-all chip on initial state (no active filters)
        expect(find.byIcon(Icons.clear_all), findsNothing);
      },
    );

    // FILT-03: clear-all chip appears when ledger filter is active; tapping calls clearAll
    testWidgets(
      'FILT-03: clear-all chip visible when ledger filter active, tap calls clearAll()',
      (tester) async {
        final container = await _pumpFilterBar(
          tester,
          filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
        );

        // Clear-all chip should be visible
        expect(find.byIcon(Icons.clear_all), findsOneWidget);

        // Tap the clear-all chip
        await tester.tap(find.byIcon(Icons.clear_all));
        await tester.pumpAndSettle();

        // Filter should be reset
        final state = container.read(shoppingFilterProvider);
        expect(state.ledgerType, isNull);
        expect(state.categoryIds, isEmpty);
        expect(state.statusFilter, equals('all'));
      },
    );

    // FILT-03: clear-all not shown when no filter active
    testWidgets(
      'FILT-03: clear-all chip hidden when no filter active',
      (tester) async {
        await _pumpFilterBar(tester);

        expect(find.byIcon(Icons.clear_all), findsNothing);
      },
    );

    // Tapping 日常 chip sets ledger filter to daily
    testWidgets(
      'tapping 日常 chip sets ledgerType to daily',
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

    // Tapping active 日常 chip clears ledger filter (toggle)
    testWidgets(
      'tapping active 日常 chip toggles back to null (clear)',
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
  });
}
