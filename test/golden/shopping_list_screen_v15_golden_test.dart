@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/clear_completed_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/reorder_shopping_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_list_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockDelete extends Mock implements DeleteShoppingItemUseCase {}

class _MockToggle extends Mock implements ToggleItemCompletedUseCase {}

class _MockReorder extends Mock implements ReorderShoppingItemsUseCase {}

class _MockClear extends Mock implements ClearCompletedItemsUseCase {}

ShoppingItem _item(
  String id,
  String name, {
  String categoryId = 'category_food',
  int quantity = 1,
  LedgerType ledgerType = LedgerType.daily,
  bool completed = false,
}) {
  return ShoppingItem(
    id: id,
    deviceId: 'golden-device',
    listType: 'private',
    name: name,
    categoryId: categoryId,
    quantity: quantity,
    ledgerType: ledgerType,
    isCompleted: completed,
    createdAt: DateTime(2026, 7, 15),
  );
}

void main() {
  testWidgets('V15 personal shopping screen — light ja', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = [
      _item('milk', '牛乳'),
      _item(
        'paper',
        'トイレットペーパー',
        categoryId: 'category_daily_goods',
        quantity: 12,
      ),
      _item('miso', '味噌', quantity: 1),
      _item('coffee', 'コーヒー豆', quantity: 200, ledgerType: LedgerType.joy),
      _item(
        'soap',
        '食器用洗剤',
        categoryId: 'category_daily_goods',
        completed: true,
      ),
      _item('treat', 'ご褒美スイーツ', ledgerType: LedgerType.joy, completed: true),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredShoppingItemsProvider.overrideWith(
            (_) => Stream.value(items),
          ),
          deleteShoppingItemUseCaseProvider.overrideWithValue(_MockDelete()),
          toggleItemCompletedUseCaseProvider.overrideWithValue(_MockToggle()),
          reorderShoppingItemsUseCaseProvider.overrideWithValue(_MockReorder()),
          clearCompletedItemsUseCaseProvider.overrideWithValue(_MockClear()),
          shadowBooksProvider.overrideWith((_) async => const []),
          isGroupModeProvider.overrideWith((_) => false),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          theme: AppTheme.light,
          home: const ShoppingListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ShoppingListScreen),
      matchesGoldenFile('goldens/shopping_list_screen_v15_light_ja.png'),
    );
  });
}
