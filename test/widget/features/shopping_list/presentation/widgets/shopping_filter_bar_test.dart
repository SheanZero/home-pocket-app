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
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_list_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_category_filter_sheet.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_filter_bar.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_segmented_control.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

final _categoryFixtures = [
  Category(
    id: 'food',
    name: 'category_food',
    icon: 'restaurant',
    color: '#E85A4F',
    level: 1,
    isSystem: true,
    sortOrder: 1,
    createdAt: DateTime(2026, 4, 3),
  ),
  Category(
    id: 'convenience',
    name: 'コンビニ',
    icon: 'shopping_basket',
    color: '#E85A4F',
    parentId: 'food',
    level: 2,
    sortOrder: 1,
    createdAt: DateTime(2026, 4, 3),
  ),
  Category(
    id: 'supermarket',
    name: 'スーパー',
    icon: 'shopping_basket',
    color: '#E85A4F',
    parentId: 'food',
    level: 2,
    sortOrder: 2,
    createdAt: DateTime(2026, 4, 3),
  ),
];

/// Pumps a ShoppingFilterBar with optional [filter] override.
Future<ProviderContainer> _pumpFilterBar(
  WidgetTester tester, {
  ShoppingListFilter? filter,
  bool isGroupMode = false,
  CategoryRepository? categoryRepository,
}) async {
  late ProviderContainer container;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        shoppingFilterProvider.overrideWith(ShoppingFilter.new),
        isGroupModeProvider.overrideWith((ref) => isGroupMode),
        locale_providers.currentLocaleProvider.overrideWith(
          (_) async => const Locale('ja'),
        ),
        if (categoryRepository != null)
          categoryRepositoryProvider.overrideWithValue(categoryRepository),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(body: ShoppingFilterBar()),
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
    testWidgets('renders ledger segment plus private and category filters', (
      tester,
    ) async {
      await _pumpFilterBar(tester);

      // Ledger segment labels (ja).
      expect(find.text('すべて'), findsOneWidget); // ledger "all"
      expect(find.text('日常'), findsOneWidget);
      expect(find.text('ときめき'), findsOneWidget);

      expect(find.byType(ShoppingSegmentedControl<String>), findsOneWidget);
      expect(
        find.byKey(const Key('shopping_filter_private_chip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopping_filter_category_chip')),
        findsOneWidget,
      );
      expect(find.text('私有'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);

      // Removed status chip must NOT be present.
      expect(find.text('すべてのアイテム'), findsNothing);
      expect(find.text('アクティブのみ'), findsNothing);

      // Reorder toggle moved to the screen header — not in the filter card.
      expect(find.byIcon(Icons.reorder), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('group mode adds the scope segment (全部 / 個人)', (tester) async {
      await _pumpFilterBar(tester, isGroupMode: true);

      // Family mode stacks the range segment above the ledger segment.
      expect(find.text('全部'), findsOneWidget); // scope "all"
      expect(find.text('個人'), findsOneWidget); // scope "private" (personal)
      expect(find.text('すべて'), findsOneWidget);
      expect(find.byType(ShoppingSegmentedControl<String>), findsNWidgets(2));
      expect(find.text('私有'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
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

    testWidgets('tapping ledger すべて clears the ledger filter to null', (
      tester,
    ) async {
      final container = await _pumpFilterBar(
        tester,
        filter: const ShoppingListFilter(ledgerType: LedgerType.daily),
      );
      expect(
        container.read(shoppingFilterProvider).ledgerType,
        equals(LedgerType.daily),
      );

      await tester.tap(find.text('すべて'));
      await tester.pumpAndSettle();

      expect(container.read(shoppingFilterProvider).ledgerType, isNull);
    });
  });

  group('ShoppingFilterBar — private filter', () {
    testWidgets('tapping private enables private-only filtering', (
      tester,
    ) async {
      final container = await _pumpFilterBar(tester);

      await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
      await tester.pumpAndSettle();

      expect(container.read(shoppingFilterProvider).showPrivateOnly, isTrue);
    });

    testWidgets('tapping active private filter disables it', (tester) async {
      final container = await _pumpFilterBar(tester);
      container.read(shoppingFilterProvider.notifier).setPrivateFilter(true);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopping_filter_private_chip')));
      await tester.pumpAndSettle();

      expect(container.read(shoppingFilterProvider).showPrivateOnly, isFalse);
    });
  });

  group('ShoppingFilterBar — category filter', () {
    testWidgets('opens the category sheet and applies all L2 leaf ids', (
      tester,
    ) async {
      final categoryRepository = _MockCategoryRepository();
      when(
        categoryRepository.findActive,
      ).thenAnswer((_) async => _categoryFixtures);
      final container = await _pumpFilterBar(
        tester,
        categoryRepository: categoryRepository,
      );

      await tester.tap(find.byKey(const Key('shopping_filter_category_chip')));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingCategoryFilterSheet), findsOneWidget);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingCategoryFilterSheet), findsNothing);
      expect(
        container.read(shoppingFilterProvider).categoryIds,
        equals({'convenience', 'supermarket'}),
      );
    });
  });
}
