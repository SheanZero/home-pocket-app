// Widget tests for ShoppingListScreen shell.
//
// Covers: SC2, DONE-03, MGMT-02
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
  List<Override> extraOverrides = const [],
}) async {
  final deleteUC = delete ?? MockDeleteShoppingItemUseCase();
  final toggleUC = toggle ?? MockToggleItemCompletedUseCase();
  final reorderUC = reorder ?? MockReorderShoppingItemsUseCase();
  final clearUC = clearCompleted ?? MockClearCompletedItemsUseCase();

  when(() => deleteUC.execute(any()))
      .thenAnswer((_) async => Result.success(null));
  when(() => toggleUC.execute(any()))
      .thenAnswer((_) async => Result.success(null));
  when(() => clearUC.execute(any()))
      .thenAnswer((_) async => Result.success(null));

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
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: ShoppingListScreen()),
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
  });

  group('ShoppingListScreen — loading state (SC2)', () {
    testWidgets('shows CircularProgressIndicator while stream is loading',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredShoppingItemsProvider.overrideWith(
              (ref) => Stream.empty(),
            ),
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
    testWidgets('shows ShoppingEmptyState when both sections are empty',
        (tester) async {
      await _pumpScreen(tester, items: const []);
      // ShoppingEmptyState should be visible — renders with a shopping bag icon
      expect(find.byIcon(Icons.shopping_bag_outlined), findsAny);
    });
  });

  group('ShoppingListScreen — completed section (DONE-03)', () {
    testWidgets('renders completed item text when completed items present',
        (tester) async {
      final completedItem = _makeItem(
        id: 'c-1',
        isCompleted: true,
        name: 'Completed Item',
      );
      await _pumpScreen(tester, items: [completedItem]);
      expect(find.text('Completed Item'), findsOneWidget);
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
    });
  });

  group('ShoppingListScreen — batch mode chrome (MGMT-02)', () {
    testWidgets('renders active items in list', (tester) async {
      final a1 = _makeItem(id: 'a-1', name: 'Active 1');
      final a2 = _makeItem(id: 'a-2', name: 'Active 2');
      await _pumpScreen(tester, items: [a1, a2]);

      expect(find.text('Active 1'), findsOneWidget);
      expect(find.text('Active 2'), findsOneWidget);
    });

    testWidgets(
        'batch selection header visible when batchSelectModeProvider isActive',
        (tester) async {
      final activeItem = _makeItem(id: 'a-1', isCompleted: false);
      await _pumpScreen(
        tester,
        items: [activeItem],
        extraOverrides: [
          batchSelectModeProvider.overrideWith(
            () => _FixedBatchNotifier(
              BatchSelectModeState(isActive: true, selectedIds: const {'a-1'}),
            ),
          ),
        ],
      );

      // ShoppingSelectionHeader renders the selection count (locale-dependent)
      // and Cancel / Select All buttons — assert on widget type so the test
      // is locale-independent.
      expect(find.byType(ShoppingSelectionHeader), findsOneWidget);
    });

    testWidgets(
        'batch action bar visible when batchSelectModeProvider isActive',
        (tester) async {
      final activeItem = _makeItem(id: 'a-1', isCompleted: false);
      await _pumpScreen(
        tester,
        items: [activeItem],
        extraOverrides: [
          batchSelectModeProvider.overrideWith(
            () => _FixedBatchNotifier(
              BatchSelectModeState(isActive: true, selectedIds: const {'a-1'}),
            ),
          ),
        ],
      );

      // ShoppingBatchActionBar shows the selecting-count (locale-dependent) —
      // assert on widget type so the test is locale-independent.
      expect(find.byType(ShoppingBatchActionBar), findsOneWidget);
    });

    testWidgets(
        'batch chrome is hidden when batchSelectModeProvider isActive=false',
        (tester) async {
      final activeItem = _makeItem(id: 'a-1', isCompleted: false);
      await _pumpScreen(tester, items: [activeItem]);

      // With default batch state (inactive), the batch chrome must be absent.
      expect(find.byType(ShoppingBatchActionBar), findsNothing);
      expect(find.byType(ShoppingSelectionHeader), findsNothing);
    });
  });

  group('ShoppingListScreen — reorderable list (D38-02)', () {
    testWidgets('renders CustomScrollView for non-empty list', (tester) async {
      final a1 = _makeItem(id: 'a-1', name: 'Item One');
      await _pumpScreen(tester, items: [a1]);

      expect(find.byType(CustomScrollView), findsOneWidget);
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
