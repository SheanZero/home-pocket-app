// Widget tests for ShoppingFilterBar — v15 filter card (D-02 port).
//
// ShoppingFilterBar is defined in:
//   lib/features/shopping_list/presentation/widgets/shopping_filter_bar.dart
//
// Layout under test:
//   Row 1: [scope segment (group only)] [すべて | 日常 | ときめき ledger segment]
//   Row 2: ( 私有 chip ) ( カテゴリ chip )
//   - Ledger segment writes shoppingFilterProvider.ledgerType (null/daily/joy).
//   - The reorder (並べ替え) toggle moved to the screen's 買うもの header — it
//     is NOT part of the filter card anymore.
//
// Run: flutter test test/widget/features/shopping_list/presentation/widgets/shopping_filter_bar_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_list_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_filter_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Pumps a ShoppingFilterBar with optional [filter] override.
Future<ProviderContainer> _pumpFilterBar(
  WidgetTester tester, {
  ShoppingListFilter? filter,
  bool isGroupMode = false,
}) async {
  late ProviderContainer container;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shoppingFilterProvider.overrideWith(ShoppingFilter.new),
        isGroupModeProvider.overrideWith((ref) => isGroupMode),
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
    await tester.pumpAndSettle();
  }

  return container;
}

void main() {
  group('ShoppingFilterBar — v15 filter card', () {
    testWidgets(
      'renders すべて / 日常 / ときめき ledger segment + 私有 + カテゴリ chips',
      (tester) async {
        await _pumpFilterBar(tester);

        // Ledger segment labels (ja).
        expect(find.text('すべて'), findsOneWidget); // ledger "all"
        expect(find.text('日常'), findsOneWidget);
        expect(find.text('ときめき'), findsOneWidget);

        // Secondary chips.
        expect(find.text('私有'), findsOneWidget);
        expect(find.text('カテゴリ'), findsOneWidget);

        // Removed status chip must NOT be present.
        expect(find.text('すべてのアイテム'), findsNothing);
        expect(find.text('アクティブのみ'), findsNothing);

        // Reorder toggle moved to the screen header — not in the filter card.
        expect(find.byIcon(Icons.reorder), findsNothing);
        expect(find.byIcon(Icons.check), findsNothing);
      },
    );

    testWidgets('group mode adds the scope segment (全部 / 個人)',
        (tester) async {
      await _pumpFilterBar(tester, isGroupMode: true);

      // Scope segment now uses 全部 / 個人 (v15 screenshot) — 私有 is reserved
      // for the row-2 chip only, resolving the old double-私有 label.
      expect(find.text('全部'), findsOneWidget); // scope "all"
      expect(find.text('個人'), findsOneWidget); // scope "private" (personal)
      // ledger "all" すべて appears once; scope no longer duplicates it.
      expect(find.text('すべて'), findsOneWidget);
      // 私有 now appears ONLY as the secondary chip.
      expect(find.text('私有'), findsOneWidget);
    });

    testWidgets('tapping 日常 sets ledgerType to daily', (tester) async {
      final container = await _pumpFilterBar(tester);

      await tester.tap(find.text('日常'));
      await tester.pumpAndSettle();

      expect(
        container.read(shoppingFilterProvider).ledgerType,
        equals(LedgerType.daily),
      );
    });

    testWidgets('tapping ときめき sets ledgerType to joy', (tester) async {
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
    });

    testWidgets('tapping ledger すべて clears the ledger filter to null',
        (tester) async {
      final container = await _pumpFilterBar(
        tester,
        filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
      );
      expect(container.read(shoppingFilterProvider).ledgerType,
          equals(LedgerType.daily));

      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle();

      expect(container.read(shoppingFilterProvider).ledgerType, isNull);
    });
  });

  group('ShoppingFilterBar — 私有 chip', () {
    testWidgets('私有 chip renders with correct label and key (ja)',
        (tester) async {
      await _pumpFilterBar(tester);

      expect(find.byKey(const Key('shopping_filter_private_chip')),
          findsOneWidget);
      expect(find.text('私有'), findsOneWidget);
    });

    testWidgets('tapping 私有 chip sets showPrivateOnly=true', (tester) async {
      final container = await _pumpFilterBar(tester);

      await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
      await tester.pumpAndSettle();

      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isTrue,
      );
    });

    testWidgets('tapping active 私有 chip deactivates showPrivateOnly',
        (tester) async {
      final container = await _pumpFilterBar(tester);

      container.read(shoppingFilterProvider.notifier).setPrivateFilter(true);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
      await tester.pumpAndSettle();

      expect(
        container.read(shoppingFilterProvider).showPrivateOnly,
        isFalse,
      );
    });

    testWidgets('私有 chip present in solo mode (no group)', (tester) async {
      await _pumpFilterBar(tester);

      expect(
        find.byKey(const Key('shopping_filter_private_chip')),
        findsOneWidget,
      );
    });
  });
}
