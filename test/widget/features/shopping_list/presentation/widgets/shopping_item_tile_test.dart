// Widget tests for ShoppingItemTile — rendering, toggle, attribution chip, batch guard.
//
// Covers: SHOP-02, SHOP-03, DONE-01, MGMT-03, SYNC-04
//
// Run: flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/reorder_shopping_items_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_reorder.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_item_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// Mocktail mocks for the use cases referenced by the tile
class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

class MockReorderShoppingItemsUseCase extends Mock
    implements ReorderShoppingItemsUseCase {}

/// Minimal ShoppingItem fixture for widget tests.
ShoppingItem _makeItem({
  String id = 'item-1',
  String listType = 'public',
  LedgerType? ledgerType = LedgerType.daily,
  bool isCompleted = false,
  String? addedByBookId,
  int? estimatedPrice,
  int quantity = 1,
  int sortOrder = 0,
}) {
  final now = DateTime(2026, 6, 8, 10, 0);
  return ShoppingItem(
    id: id,
    deviceId: 'device-1',
    listType: listType,
    name: 'Test Item',
    ledgerType: ledgerType,
    isCompleted: isCompleted,
    addedByBookId: addedByBookId,
    estimatedPrice: estimatedPrice,
    quantity: quantity,
    sortOrder: sortOrder,
    createdAt: now,
  );
}

/// Minimal Book fixture — only `id` is accessed by the attribution chip lookup.
Book _makeBook(String id) => Book(
      id: id,
      name: 'Alice Book',
      currency: 'JPY',
      deviceId: 'device-x',
      createdAt: DateTime(2026),
      ownerDeviceId: 'device-x',
      ownerDeviceName: 'Alice Device',
    );

/// Pumps a [ShoppingItemTile] inside a minimal [SliverReorderableList] so
/// [ReorderableDragStartListener] is satisfied.
///
/// [extraOverrides] may override any of the defaults below, including
/// [shadowBooksProvider]. Entries in [extraOverrides] are placed AFTER the
/// defaults, so Riverpod will see them as a duplicate. To avoid that, pass
/// a [shadowBooksOverride] parameter instead.
Future<void> _pumpTile(
  WidgetTester tester, {
  required ShoppingItem item,
  required MockDeleteShoppingItemUseCase delete,
  required MockToggleItemCompletedUseCase toggle,
  Override? shadowBooksOverride,
  List<Override> extraOverrides = const [],
  bool isActive = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deleteShoppingItemUseCaseProvider.overrideWithValue(delete),
        toggleItemCompletedUseCaseProvider.overrideWithValue(toggle),
        shadowBooksOverride ??
            shadowBooksProvider.overrideWith(
              (ref) async => const <ShadowBookInfo>[],
            ),
        ...extraOverrides,
      ],
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverReorderableList(
                onReorderItem: (_, _) {},
                itemCount: 1,
                itemBuilder: (ctx, i) => ReorderableDelayedDragStartListener(
                  key: ValueKey('tile-$i'),
                  index: i,
                  child: ShoppingItemTile(
                    item: item,
                    index: i,
                    isActive: isActive,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Fixed-state [BatchSelectMode] notifier for injection in tests.
class _FixedBatchSelectMode extends BatchSelectMode {
  _FixedBatchSelectMode(this._fixedState);
  final BatchSelectModeState _fixedState;

  @override
  BatchSelectModeState build() => _fixedState;
}

/// Fixed-state [ShoppingReorderMode] notifier for injection in tests (EC2 D-2).
class _FixedReorderMode extends ShoppingReorderMode {
  _FixedReorderMode(this._fixed);
  final bool _fixed;

  @override
  bool build() => _fixed;
}

void main() {
  late MockDeleteShoppingItemUseCase mockDelete;
  late MockToggleItemCompletedUseCase mockToggle;

  setUp(() {
    mockDelete = MockDeleteShoppingItemUseCase();
    mockToggle = MockToggleItemCompletedUseCase();

    // Default no-op stubs
    when(() => mockDelete.execute(any()))
        .thenAnswer((_) async => Result.success(null));
    when(() => mockToggle.execute(any()))
        .thenAnswer((_) async => Result.success(_makeItem()));
  });

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(<String>[]);
  });

  group('ShoppingItemTile — SHOP-02: renders item.name as primary text', () {
    testWidgets('tile displays item.name as Text widget', (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.text('Test Item'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — SHOP-03: ledger accent via badge (v15 port)', () {
    // The old 4px left accent bar was replaced by the ledger badge
    // (dailyLight/joyLight fill) + the ledger-coloured check circle.
    bool hasBadgeFill(WidgetTester tester, Color fill) {
      final containers = tester.widgetList<Container>(find.byType(Container));
      return containers.any((c) {
        final deco = c.decoration;
        return deco is BoxDecoration && deco.color == fill;
      });
    }

    testWidgets('daily ledger: badge fill = palette.dailyLight', (tester) async {
      final item = _makeItem(ledgerType: LedgerType.daily);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(hasBadgeFill(tester, AppPalette.light.dailyLight), isTrue,
          reason: 'daily tile must render a dailyLight ledger badge');
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('null ledger: no ledger badge rendered', (tester) async {
      final item = _makeItem(ledgerType: null);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.text('Daily'), findsNothing);
      expect(find.text('Joy'), findsNothing);
    });

    testWidgets('joy ledger: badge fill = palette.joyLight', (tester) async {
      final item = _makeItem(ledgerType: LedgerType.joy);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(hasBadgeFill(tester, AppPalette.light.joyLight), isTrue,
          reason: 'joy tile must render a joyLight ledger badge');
      expect(find.text('Joy'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — DONE-01: leading circle toggles completion (EC2)', () {
    testWidgets('tap leading circle calls toggle.execute(item.id)',
        (tester) async {
      final item = _makeItem(id: 'item-tap-test');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      // EC2 D-domain#1: the circle has a stable ValueKey('toggle-<id>').
      await tester.tap(find.byKey(const ValueKey('toggle-item-tap-test')));
      await tester.pump();

      verify(() => mockToggle.execute('item-tap-test')).called(1);
    });

    testWidgets(
        'tap leading circle on a COMPLETED item restores it (un-complete) '
        '(quick-260609-pmc-06)',
        (tester) async {
      final item =
          _makeItem(id: 'item-done-tap', isCompleted: true);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        isActive: false,
      );

      await tester.tap(find.byKey(const ValueKey('toggle-item-done-tap')));
      await tester.pump();

      // The toggle use case flips isCompleted=false + clears completedAt.
      verify(() => mockToggle.execute('item-done-tap')).called(1);
    });

    testWidgets('tapping the tile body does NOT toggle (opens edit instead)',
        (tester) async {
      final item = _makeItem(id: 'item-body-test');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      // Tap the item name (body) — EC2 D-domain#3 routes this to edit, not toggle.
      await tester.tap(find.text('Test Item'));
      await tester.pump();

      verifyNever(() => mockToggle.execute(any()));
    });
  });

  group('ShoppingItemTile — EC2 D-domain#3: tile body opens edit form', () {
    testWidgets('tapping the tile body navigates to ShoppingItemFormScreen',
        (tester) async {
      final item = _makeItem(id: 'item-edit-nav');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      await tester.tap(find.text('Test Item'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemFormScreen), findsOneWidget);
    });
  });

  group('ShoppingItemTile — EC2 D-1: no chevron + trailing quantity badge', () {
    testWidgets('edit chevron is removed', (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('quantity > 1 shows the number (no ×) in trailing area',
        (tester) async {
      final item = _makeItem(quantity: 3);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('quantity == 1 still shows the number 1 (always shown)',
        (tester) async {
      final item = _makeItem(quantity: 1);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.text('1'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — v15 ledger badge replaces 私有 marker', () {
    // Default test locale resolves to 'en' (first supported locale). The v15
    // port removes the 私有 lock marker in favour of the ledger badge.
    testWidgets('private item shows the ledger badge, NOT a 私有 lock marker',
        (tester) async {
      final item = _makeItem(listType: 'private', ledgerType: LedgerType.daily);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Private'), findsNothing);
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('public item shows NO 私有 marker', (tester) async {
      final item = _makeItem(listType: 'public');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('ledger badge IS present — Daily/Joy badge text (v15)',
        (tester) async {
      final dailyItem = _makeItem(ledgerType: LedgerType.daily);
      await _pumpTile(tester,
          item: dailyItem, delete: mockDelete, toggle: mockToggle);
      expect(find.text('Daily'), findsOneWidget);

      final joyItem = _makeItem(ledgerType: LedgerType.joy);
      await _pumpTile(tester,
          item: joyItem, delete: mockDelete, toggle: mockToggle);
      expect(find.text('Joy'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — EC2 D-2: drag handle gated on reorder mode', () {
    testWidgets('default (reorder mode off) → no drag handle', (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.byIcon(Icons.reorder), findsNothing);
    });

    testWidgets('reorder mode on (active item) → drag handle visible',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
        ],
      );

      // quick-260609-pmc-05: handle is Icons.reorder (three lines), and its
      // long-press Tooltip ("重新排序") was removed because it fired on the
      // drag long-press. No Tooltip should carry the reorder-item message.
      expect(find.byIcon(Icons.reorder), findsOneWidget);
      final ctx = tester.element(find.byType(ShoppingItemTile));
      expect(find.byTooltip(S.of(ctx).shoppingReorderItem), findsNothing);
    });

    testWidgets('reorder mode on → tapping circle does NOT toggle',
        (tester) async {
      final item = _makeItem(id: 'item-reorder-lock');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('toggle-item-reorder-lock')));
      await tester.pump();

      verifyNever(() => mockToggle.execute(any()));
    });

    testWidgets('reorder mode on → Dismissible direction is none (swipe locked)',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
        ],
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, equals(DismissDirection.none));
    });
  });

  group('ShoppingItemTile — MGMT-03: swipe disabled in batch mode', () {
    testWidgets(
        'batchSelectModeProvider.state.isActive=true → Dismissible.direction is none',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          batchSelectModeProvider.overrideWith(
            () => _FixedBatchSelectMode(
              const BatchSelectModeState(isActive: true, selectedIds: {}),
            ),
          ),
        ],
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(
        dismissible.direction,
        equals(DismissDirection.none),
        reason: 'Swipe must be disabled in batch mode (MGMT-03)',
      );
    });

    testWidgets(
        'batch mode inactive → Dismissible.direction is endToStart',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(
        dismissible.direction,
        equals(DismissDirection.endToStart),
        reason: 'Swipe should be enabled when batch mode is inactive',
      );
    });
  });

  group('ShoppingItemTile — SYNC-04: attribution chip', () {
    testWidgets(
        'public tile with resolvable addedByBookId shows attribution chip',
        (tester) async {
      const bookId = 'shadow-book-42';
      final item = _makeItem(listType: 'public', addedByBookId: bookId);

      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        shadowBooksOverride: shadowBooksProvider.overrideWith(
          (_) async => [
            ShadowBookInfo(
              book: _makeBook(bookId),
              memberDisplayName: 'Alice',
              memberAvatarEmoji: '🐱',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('🐱 Alice'),
        findsOneWidget,
        reason: 'Attribution chip must show emoji + name (SYNC-04)',
      );
    });

    testWidgets('public tile with null addedByBookId has no attribution chip',
        (tester) async {
      final item = _makeItem(listType: 'public', addedByBookId: null);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);
      await tester.pumpAndSettle();

      expect(find.textContaining('🐱'), findsNothing);
    });

    testWidgets(
        'private tile with addedByBookId does NOT show attribution chip (T-38-04-01)',
        (tester) async {
      const bookId = 'shadow-book-42';
      final item = _makeItem(listType: 'private', addedByBookId: bookId);

      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        shadowBooksOverride: shadowBooksProvider.overrideWith(
          (_) async => [
            ShadowBookInfo(
              book: _makeBook(bookId),
              memberDisplayName: 'Alice',
              memberAvatarEmoji: '🐱',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // T-38-04-01: private tiles must NEVER show attribution chip
      expect(
        find.text('🐱 Alice'),
        findsNothing,
        reason: 'Private tiles must not show attribution chip (T-38-04-01)',
      );
    });
  });

  group('ShoppingItemTile — reorder mode move buttons (quick-260609-pmc Fix 4)', () {
    testWidgets(
        'reorder mode on (active item) → vertical_align_top and vertical_align_bottom visible',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
        ],
      );

      expect(find.byIcon(Icons.vertical_align_top), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_bottom), findsOneWidget);
    });

    testWidgets(
        'reorder mode off → no move-to-top or move-to-bottom buttons',
        (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.byIcon(Icons.vertical_align_top), findsNothing);
      expect(find.byIcon(Icons.vertical_align_bottom), findsNothing);
    });

    testWidgets(
        'tap move-to-top persists the full active order with this item first '
        '(quick-260609-pmc-04: contiguous re-sequence, completed items excluded)',
        (tester) async {
      final mockReorder = MockReorderShoppingItemsUseCase();
      when(() => mockReorder.applyOrder(any()))
          .thenAnswer((_) async => Result.success(null));

      // Display order: a, b, target, c (+ a completed item that must be excluded).
      final item = _makeItem(id: 'target');
      final siblings = [
        _makeItem(id: 'a'),
        _makeItem(id: 'b'),
        item,
        _makeItem(id: 'c'),
        _makeItem(id: 'done', isCompleted: true),
      ];
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
          reorderShoppingItemsUseCaseProvider.overrideWithValue(mockReorder),
          filteredShoppingItemsProvider.overrideWith(
            (ref) => Stream.value(siblings),
          ),
        ],
      );
      // Pre-warm the lazy StreamProvider so its value is available when the
      // button's onTap reads it synchronously (a bare ref.read at tap time
      // would otherwise see AsyncLoading → null).
      ProviderScope.containerOf(tester.element(find.byType(ShoppingItemTile)))
          .listen(filteredShoppingItemsProvider, (_, _) {});
      await tester.pump(); // let the stream emit

      await tester.tap(find.byIcon(Icons.vertical_align_top));
      await tester.pump();

      verify(() => mockReorder.applyOrder(['target', 'a', 'b', 'c']))
          .called(1);
    });

    testWidgets(
        'tap move-to-bottom persists the full active order with this item last '
        '(quick-260609-pmc-04: contiguous re-sequence, completed items excluded)',
        (tester) async {
      final mockReorder = MockReorderShoppingItemsUseCase();
      when(() => mockReorder.applyOrder(any()))
          .thenAnswer((_) async => Result.success(null));

      // Display order: a, target, b (+ a completed item that must be excluded).
      final item = _makeItem(id: 'target');
      final siblings = [
        _makeItem(id: 'a'),
        item,
        _makeItem(id: 'b'),
        _makeItem(id: 'done', isCompleted: true),
      ];
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
          reorderShoppingItemsUseCaseProvider.overrideWithValue(mockReorder),
          filteredShoppingItemsProvider.overrideWith(
            (ref) => Stream.value(siblings),
          ),
        ],
      );
      ProviderScope.containerOf(tester.element(find.byType(ShoppingItemTile)))
          .listen(filteredShoppingItemsProvider, (_, _) {});
      await tester.pump();

      await tester.tap(find.byIcon(Icons.vertical_align_bottom));
      await tester.pump();

      verify(() => mockReorder.applyOrder(['a', 'b', 'target'])).called(1);
    });

    testWidgets(
        'completed item in reorder mode → no move buttons (isActive=false)',
        (tester) async {
      final item = _makeItem(isCompleted: true);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        isActive: false,
        extraOverrides: [
          shoppingReorderModeProvider.overrideWith(
            () => _FixedReorderMode(true),
          ),
        ],
      );

      expect(find.byIcon(Icons.vertical_align_top), findsNothing);
      expect(find.byIcon(Icons.vertical_align_bottom), findsNothing);
    });
  });
}
