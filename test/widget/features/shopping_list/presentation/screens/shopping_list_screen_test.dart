// Widget tests for ShoppingListScreen shell.
//
// Covers: SC2, DONE-03, single-item management, and direct reorder
//
// Run: flutter test test/widget/features/shopping_list/presentation/screens/shopping_list_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/clear_completed_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/reorder_shopping_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_list_screen.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_batch_action_bar.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_selection_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// Mocks

class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

class MockReorderShoppingItemsUseCase extends Mock
    implements ReorderShoppingItemsUseCase {}

class MockClearCompletedItemsUseCase extends Mock
    implements ClearCompletedItemsUseCase {}

// Fixtures

ShoppingItem _makeItem({
  String id = 'item-1',
  String listType = 'private',
  LedgerType? ledgerType = LedgerType.daily,
  bool isCompleted = false,
  String name = 'Test Item',
}) {
  final now = DateTime(2026, 6, 8, 10, 0);
  return ShoppingItem(
    id: id,
    deviceId: 'device-1',
    listType: listType,
    name: name,
    ledgerType: ledgerType,
    isCompleted: isCompleted,
    createdAt: now,
  );
}

/// Pumps [ShoppingListScreen] with provider overrides.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required List<ShoppingItem> items,
  MockDeleteShoppingItemUseCase? delete,
  MockToggleItemCompletedUseCase? toggle,
  MockReorderShoppingItemsUseCase? reorder,
  MockClearCompletedItemsUseCase? clearCompleted,
  VoidCallback? onSettingsTap,
  List<Override> extraOverrides = const [],
}) async {
  final deleteUC = delete ?? MockDeleteShoppingItemUseCase();
  final toggleUC = toggle ?? MockToggleItemCompletedUseCase();
  final reorderUC = reorder ?? MockReorderShoppingItemsUseCase();
  final clearUC = clearCompleted ?? MockClearCompletedItemsUseCase();

  when(
    () => deleteUC.execute(any()),
  ).thenAnswer((_) async => Result.success(null));
  when(
    () => toggleUC.execute(any()),
  ).thenAnswer((_) async => Result.success(null));
  when(
    () => clearUC.execute(any()),
  ).thenAnswer((_) async => Result.success(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Provide a stream of items for filteredShoppingItemsProvider
        filteredShoppingItemsProvider.overrideWith(
          (ref) => Stream.value(items),
        ),
        deleteShoppingItemUseCaseProvider.overrideWithValue(deleteUC),
        toggleItemCompletedUseCaseProvider.overrideWithValue(toggleUC),
        reorderShoppingItemsUseCaseProvider.overrideWithValue(reorderUC),
        clearCompletedItemsUseCaseProvider.overrideWithValue(clearUC),
        // Stub providers that require DB/crypto (not needed for shell tests)
        shadowBooksProvider.overrideWith(
          (ref) async => const <ShadowBookInfo>[],
        ),
        // isGroupModeProvider is sync bool (not async)
        isGroupModeProvider.overrideWith((ref) => false),
        ...extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ShoppingListScreen(onSettingsTap: onSettingsTap)),
      ),
    ),
  );
  // Pump to settle stream
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue('private');
    registerFallbackValue(<String>[]);
  });

  group('ShoppingListScreen — main header', () {
    testWidgets('matches the shared title geometry and opens settings', (
      tester,
    ) async {
      var settingsTaps = 0;
      await _pumpScreen(
        tester,
        items: const [],
        onSettingsTap: () => settingsTaps++,
      );

      final header = find.byKey(const Key('shopping-main-header'));
      final title = find.byKey(const Key('shopping-main-title'));
      final settings = find.byKey(const Key('shopping-settings-button'));
      final filter = find.byKey(const Key('shopping_filter_surface'));

      expect(find.byType(AppBar), findsNothing);
      expect(tester.getSize(header).height, 46);
      expect(tester.getTopLeft(header).dx, 20);
      expect(tester.getTopLeft(title).dx, 20);
      expect(
        tester.widget<Text>(title).style?.fontSize,
        AppTypography.pageTitle,
      );
      expect(
        tester.widget<Text>(title).style?.height,
        AppTypography.pageTitleLineHeight / AppTypography.pageTitle,
      );
      expect(tester.getSize(settings), const Size(40, 40));
      expect(
        tester.getSize(find.byIcon(Icons.settings_outlined)),
        const Size(24, 24),
      );
      expect(
        tester.getTopLeft(filter).dy - tester.getBottomLeft(header).dy,
        13,
      );

      await tester.tap(settings);
      expect(settingsTaps, 1);
    });
  });

  group('ShoppingListScreen — loading state (SC2)', () {
    testWidgets('shows CircularProgressIndicator while stream is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredShoppingItemsProvider.overrideWith((ref) => Stream.empty()),
            shadowBooksProvider.overrideWith(
              (ref) async => const <ShadowBookInfo>[],
            ),
            isGroupModeProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Scaffold(body: ShoppingListScreen()),
          ),
        ),
      );
      // Only pump once — the stream has not emitted so we're still in loading
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ShoppingListScreen — empty state (SC2)', () {
    testWidgets('shows ShoppingEmptyState when both sections are empty', (
      tester,
    ) async {
      await _pumpScreen(tester, items: const []);
      // ShoppingEmptyState should be visible — renders with a shopping bag icon
      expect(find.byIcon(Icons.shopping_bag_outlined), findsAny);
    });
  });

  group('ShoppingListScreen — completed section (DONE-03)', () {
    testWidgets('renders completed item text when completed items present', (
      tester,
    ) async {
      final completedItem = _makeItem(
        id: 'c-1',
        isCompleted: true,
        name: 'Completed Item',
      );
      await _pumpScreen(tester, items: [completedItem]);
      expect(find.text('Completed Item'), findsOneWidget);
    });

    testWidgets('completed card owns one uniform 0.58 opacity layer', (
      tester,
    ) async {
      final completedItem = _makeItem(
        id: 'c-opacity',
        isCompleted: true,
        name: 'Muted completed item',
      );
      await _pumpScreen(tester, items: [completedItem]);

      const opacityKey = ValueKey('completed-item-opacity-c-opacity');
      const cardKey = ValueKey('completed-item-card-c-opacity');
      final opacity = tester.widget<AnimatedOpacity>(find.byKey(opacityKey));

      expect(opacity.opacity, 0.58);
      expect(
        find.descendant(
          of: find.byKey(opacityKey),
          matching: find.byKey(cardKey),
        ),
        findsOneWidget,
      );
    });

    testWidgets('completed items render as separate cards with an 8px gap', (
      tester,
    ) async {
      final items = [
        _makeItem(id: 'c-1', isCompleted: true, name: 'Done One'),
        _makeItem(id: 'c-2', isCompleted: true, name: 'Done Two'),
      ];
      await _pumpScreen(tester, items: items);

      const firstKey = ValueKey('completed-item-card-c-1');
      const secondKey = ValueKey('completed-item-card-c-2');
      final first = tester.getRect(find.byKey(firstKey));
      final second = tester.getRect(find.byKey(secondKey));

      expect(first.left, 20);
      expect(first.right, 800 - 20);
      expect(second.top - first.bottom, 8);
    });

    testWidgets(
      'does not show completed-section divider when no completed items',
      (tester) async {
        final activeItem = _makeItem(
          id: 'a-1',
          isCompleted: false,
          name: 'Active Item',
        );
        await _pumpScreen(tester, items: [activeItem]);
        // Completed divider label should NOT appear
        expect(find.text('Completed'), findsNothing);
        expect(find.text('完了済み'), findsNothing);
        expect(find.text('已完成'), findsNothing);
      },
    );
  });

  group('ShoppingListScreen — single-item management', () {
    testWidgets('renders active items in list', (tester) async {
      final a1 = _makeItem(id: 'a-1', name: 'Active 1');
      final a2 = _makeItem(id: 'a-2', name: 'Active 2');
      await _pumpScreen(tester, items: [a1, a2]);

      expect(find.text('Active 1'), findsOneWidget);
      expect(find.text('Active 2'), findsOneWidget);
    });

    testWidgets(
      'legacy batch state never exposes selection header or delete bar',
      (tester) async {
        final activeItem = _makeItem(id: 'a-1', isCompleted: false);
        await _pumpScreen(
          tester,
          items: [activeItem],
          extraOverrides: [
            batchSelectModeProvider.overrideWith(
              () => _FixedBatchNotifier(
                BatchSelectModeState(
                  isActive: true,
                  selectedIds: const {'a-1'},
                ),
              ),
            ),
          ],
        );

        expect(find.byType(ShoppingBatchActionBar), findsNothing);
        expect(find.byType(ShoppingSelectionHeader), findsNothing);
      },
    );
  });

  group('ShoppingListScreen — reorderable list (D38-02)', () {
    testWidgets('renders CustomScrollView for non-empty list', (tester) async {
      final a1 = _makeItem(id: 'a-1', name: 'Item One');
      await _pumpScreen(tester, items: [a1]);

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('normal mode shows both active and completed items '
        '(quick-260609-pmc-07 baseline)', (tester) async {
      final items = [
        _makeItem(id: 'a-1', name: 'Active One'),
        _makeItem(id: 'c-1', name: 'Done One', isCompleted: true),
      ];
      await _pumpScreen(tester, items: items);

      expect(find.text('Active One'), findsOneWidget);
      expect(find.text('Done One'), findsOneWidget);
    });

    testWidgets('has no standalone reorder button', (tester) async {
      final activeItem = _makeItem(id: 'a-1', name: 'Active One');
      await _pumpScreen(tester, items: [activeItem]);

      expect(find.byKey(const Key('shopping_reorder_toggle')), findsNothing);
    });

    testWidgets('only the active item trailing handle owns delayed drag', (
      tester,
    ) async {
      final items = [
        _makeItem(id: 'a-1', name: 'Active One'),
        _makeItem(id: 'c-1', name: 'Done One', isCompleted: true),
      ];
      await _pumpScreen(tester, items: items);

      expect(
        find.byKey(const ValueKey('shopping-drag-handle-a-1')),
        findsOneWidget,
      );
      expect(find.byType(ReorderableDelayedDragStartListener), findsOneWidget);
      expect(find.text('Done One'), findsOneWidget);
    });

    testWidgets('reorder callback persists the active item order', (
      tester,
    ) async {
      final reorder = MockReorderShoppingItemsUseCase();
      when(
        () => reorder.applyOrder(any()),
      ).thenAnswer((_) async => Result.success(null));
      final items = [
        _makeItem(id: 'a-1', name: 'First'),
        _makeItem(id: 'a-2', name: 'Second'),
      ];
      await _pumpScreen(tester, items: items, reorder: reorder);

      final list = tester.widget<SliverReorderableList>(
        find.byType(SliverReorderableList),
      );
      list.onReorderItem?.call(0, 1);
      await tester.pump();

      verify(() => reorder.applyOrder(['a-2', 'a-1'])).called(1);
    });
  });
}

/// Fixed-state [BatchSelectMode] notifier for use in tests.
class _FixedBatchNotifier extends BatchSelectMode {
  _FixedBatchNotifier(this._fixedState);
  final BatchSelectModeState _fixedState;

  @override
  BatchSelectModeState build() => _fixedState;
}
