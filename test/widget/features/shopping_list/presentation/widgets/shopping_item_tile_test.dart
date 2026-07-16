// Widget tests for ShoppingItemTile — rendering, toggle, attribution, actions, and drag.
//
// Covers: SHOP-02, SHOP-03, DONE-01, single-item management, reorder, SYNC-04
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
  Locale locale = const Locale('en'),
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
        locale: locale,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverReorderableList(
                onReorderItem: (_, _) {},
                itemCount: 1,
                itemBuilder: (ctx, i) => ShoppingItemTile(
                  key: ValueKey('tile-$i'),
                  item: item,
                  index: i,
                  isActive: isActive,
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

void main() {
  late MockDeleteShoppingItemUseCase mockDelete;
  late MockToggleItemCompletedUseCase mockToggle;

  setUp(() {
    mockDelete = MockDeleteShoppingItemUseCase();
    mockToggle = MockToggleItemCompletedUseCase();

    // Default no-op stubs
    when(
      () => mockDelete.execute(any()),
    ).thenAnswer((_) async => Result.success(null));
    when(
      () => mockToggle.execute(any()),
    ).thenAnswer((_) async => Result.success(_makeItem()));
  });

  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(<String>[]);
  });

  group('ShoppingItemTile — SHOP-02: renders item.name as primary text', () {
    testWidgets('tile displays item.name as Text widget', (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

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

    testWidgets('daily ledger: badge fill = palette.dailyLight', (
      tester,
    ) async {
      final item = _makeItem(ledgerType: LedgerType.daily);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(
        hasBadgeFill(tester, AppPalette.light.dailyLight),
        isTrue,
        reason: 'daily tile must render a dailyLight ledger badge',
      );
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('null ledger: no ledger badge rendered', (tester) async {
      final item = _makeItem(ledgerType: null);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.text('Daily'), findsNothing);
      expect(find.text('Joy'), findsNothing);
    });

    testWidgets('joy ledger: badge fill = palette.joyLight', (tester) async {
      final item = _makeItem(ledgerType: LedgerType.joy);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(
        hasBadgeFill(tester, AppPalette.light.joyLight),
        isTrue,
        reason: 'joy tile must render a joyLight ledger badge',
      );
      expect(find.text('Joy'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — DONE-01: leading circle toggles completion (EC2)', () {
    testWidgets('tap leading circle calls toggle.execute(item.id)', (
      tester,
    ) async {
      final item = _makeItem(id: 'item-tap-test');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      // EC2 D-domain#1: the circle has a stable ValueKey('toggle-<id>').
      await tester.tap(find.byKey(const ValueKey('toggle-item-tap-test')));
      await tester.pump();

      verify(() => mockToggle.execute('item-tap-test')).called(1);
    });

    testWidgets(
      'tap leading circle on a COMPLETED item restores it (un-complete) '
      '(quick-260609-pmc-06)',
      (tester) async {
        final item = _makeItem(id: 'item-done-tap', isCompleted: true);
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
      },
    );

    testWidgets('tapping the tile body does NOT toggle (opens edit instead)', (
      tester,
    ) async {
      final item = _makeItem(id: 'item-body-test');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      // Tap the item name (body) — EC2 D-domain#3 routes this to edit, not toggle.
      await tester.tap(find.text('Test Item'));
      await tester.pump();

      verifyNever(() => mockToggle.execute(any()));
    });
  });

  group('ShoppingItemTile — EC2 D-domain#3: tile body opens edit form', () {
    testWidgets('tapping the tile body navigates to ShoppingItemFormScreen', (
      tester,
    ) async {
      final item = _makeItem(id: 'item-edit-nav');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      await tester.tap(find.text('Test Item'));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemFormScreen), findsOneWidget);
    });
  });

  group('ShoppingItemTile — EC2 D-1: no chevron + trailing quantity badge', () {
    testWidgets('edit chevron is removed', (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('quantity > 1 shows the number (no ×) in trailing area', (
      tester,
    ) async {
      final item = _makeItem(quantity: 3);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('×'), findsNothing);
    });

    testWidgets('quantity == 1 still shows the number 1 (always shown)', (
      tester,
    ) async {
      final item = _makeItem(quantity: 1);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.text('1'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — v15 ledger badge replaces 私有 marker', () {
    // Default test locale resolves to 'en' (first supported locale). The v15
    // port removes the 私有 lock marker in favour of the ledger badge.
    testWidgets('private item shows the ledger badge, NOT a 私有 lock marker', (
      tester,
    ) async {
      final item = _makeItem(listType: 'private', ledgerType: LedgerType.daily);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Private'), findsNothing);
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('public item shows NO 私有 marker', (tester) async {
      final item = _makeItem(listType: 'public');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(find.byIcon(Icons.lock_outline), findsNothing);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('ledger badge IS present — Daily/Joy badge text (v15)', (
      tester,
    ) async {
      final dailyItem = _makeItem(ledgerType: LedgerType.daily);
      await _pumpTile(
        tester,
        item: dailyItem,
        delete: mockDelete,
        toggle: mockToggle,
      );
      expect(find.text('Daily'), findsOneWidget);

      final joyItem = _makeItem(ledgerType: LedgerType.joy);
      await _pumpTile(
        tester,
        item: joyItem,
        delete: mockDelete,
        toggle: mockToggle,
      );
      expect(find.text('Joy'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — readable geometry and checked state', () {
    testWidgets('row is 68px high and the checkbox keeps a compact tap lane', (
      tester,
    ) async {
      final item = _makeItem(id: 'compact-item');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(
        tester.getSize(find.byKey(const Key('shopping_item_content'))).height,
        68,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('shopping-check-compact-item')),
        ),
        const Size(28, 28),
      );
    });

    testWidgets(
      'completed Joy checkbox keeps the Joy fill and lower-right white check',
      (tester) async {
        final item = _makeItem(
          id: 'checked-item',
          ledgerType: LedgerType.joy,
          isCompleted: true,
        );
        await _pumpTile(
          tester,
          item: item,
          delete: mockDelete,
          toggle: mockToggle,
          isActive: false,
        );

        final checkbox = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('shopping-check-checked-item')),
        );
        final decoration = checkbox.decoration! as BoxDecoration;
        expect(decoration.color, AppPalette.light.joy);
        expect((decoration.border! as Border).top.color, AppPalette.light.joy);
        final check = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(check.color, AppPalette.light.card);
        expect(check.size, 18);

        final checkTransform = tester.widget<Transform>(
          find.byKey(const ValueKey('shopping-check-icon-checked-item')),
        );
        final translation = checkTransform.transform.getTranslation();
        expect(translation.x, 5);
        expect(translation.y, 2);
      },
    );

    testWidgets('completed Daily checkbox keeps the Daily fill', (
      tester,
    ) async {
      final item = _makeItem(
        id: 'checked-daily-item',
        ledgerType: LedgerType.daily,
        isCompleted: true,
      );
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        isActive: false,
      );

      final checkbox = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('shopping-check-checked-daily-item')),
      );
      final decoration = checkbox.decoration! as BoxDecoration;
      expect(decoration.color, AppPalette.light.daily);
      expect((decoration.border! as Border).top.color, AppPalette.light.daily);
      expect(decoration.color, isNot(AppPalette.light.joy));
    });
  });

  group('ShoppingItemTile — swipe delete', () {
    testWidgets('Dismissible remains endToStart', (tester) async {
      final item = _makeItem();
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(
        dismissible.direction,
        equals(DismissDirection.endToStart),
        reason: 'Single-item swipe delete remains available',
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
      },
    );

    testWidgets('public tile with null addedByBookId has no attribution chip', (
      tester,
    ) async {
      final item = _makeItem(listType: 'public', addedByBookId: null);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );
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
      },
    );
  });

  group('ShoppingItemTile — V15 long-press actions and handle drag', () {
    testWidgets('body long-press shows four zh actions with red delete', (
      tester,
    ) async {
      final item = _makeItem(id: 'menu-item');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        locale: const Locale('zh'),
      );

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-menu-item')),
      );
      await tester.pumpAndSettle();

      expect(find.text('修改'), findsOneWidget);
      expect(find.text('置顶'), findsOneWidget);
      expect(find.text('置底'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      final deleteText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('shopping_action_delete')),
          matching: find.text('删除'),
        ),
      );
      expect(deleteText.style?.color, AppPalette.light.error);
    });

    testWidgets('completed item menu only offers edit and delete', (
      tester,
    ) async {
      final item = _makeItem(id: 'completed-menu', isCompleted: true);
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
        isActive: false,
      );

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-completed-menu')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopping_action_edit')), findsOneWidget);
      expect(find.byKey(const Key('shopping_action_delete')), findsOneWidget);
      expect(find.byKey(const Key('shopping_action_top')), findsNothing);
      expect(find.byKey(const Key('shopping_action_bottom')), findsNothing);
    });

    testWidgets('delete action confirms before invoking the delete use case', (
      tester,
    ) async {
      final item = _makeItem(id: 'menu-delete');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-menu-delete')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shopping_action_delete')));
      await tester.pumpAndSettle();

      verifyNever(() => mockDelete.execute(any()));
      expect(find.text('Delete this item?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => mockDelete.execute('menu-delete')).called(1);
    });

    testWidgets('edit action opens ShoppingItemFormScreen', (tester) async {
      final item = _makeItem(id: 'menu-edit');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-menu-edit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shopping_action_edit')));
      await tester.pumpAndSettle();

      expect(find.byType(ShoppingItemFormScreen), findsOneWidget);
    });

    testWidgets('move-to-top action persists the visible active order', (
      tester,
    ) async {
      final mockReorder = MockReorderShoppingItemsUseCase();
      when(
        () => mockReorder.applyOrder(any()),
      ).thenAnswer((_) async => Result.success(null));
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
          reorderShoppingItemsUseCaseProvider.overrideWithValue(mockReorder),
          filteredShoppingItemsProvider.overrideWith(
            (_) => Stream.value(siblings),
          ),
        ],
      );
      ProviderScope.containerOf(
        tester.element(find.byType(ShoppingItemTile)),
      ).listen(filteredShoppingItemsProvider, (_, _) {});
      await tester.pump();

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-target')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shopping_action_top')));
      await tester.pump();

      verify(() => mockReorder.applyOrder(['target', 'a', 'b', 'c'])).called(1);
    });

    testWidgets('move-to-bottom action persists the visible active order', (
      tester,
    ) async {
      final mockReorder = MockReorderShoppingItemsUseCase();
      when(
        () => mockReorder.applyOrder(any()),
      ).thenAnswer((_) async => Result.success(null));
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
          reorderShoppingItemsUseCaseProvider.overrideWithValue(mockReorder),
          filteredShoppingItemsProvider.overrideWith(
            (_) => Stream.value(siblings),
          ),
        ],
      );
      ProviderScope.containerOf(
        tester.element(find.byType(ShoppingItemTile)),
      ).listen(filteredShoppingItemsProvider, (_, _) {});
      await tester.pump();

      await tester.longPress(
        find.byKey(const ValueKey('shopping-item-body-target')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shopping_action_bottom')));
      await tester.pump();

      verify(() => mockReorder.applyOrder(['a', 'b', 'target'])).called(1);
    });

    testWidgets('active drag indicator is the only delayed drag listener', (
      tester,
    ) async {
      final item = _makeItem(id: 'drag-item');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      expect(
        find.byKey(const ValueKey('shopping-drag-handle-drag-item')),
        findsOneWidget,
      );
      expect(find.byType(ReorderableDelayedDragStartListener), findsOneWidget);
    });

    testWidgets('long-pressing the handle does not open the action sheet', (
      tester,
    ) async {
      final item = _makeItem(id: 'handle-only');
      await _pumpTile(
        tester,
        item: item,
        delete: mockDelete,
        toggle: mockToggle,
      );

      await tester.longPress(
        find.byKey(const ValueKey('shopping-drag-handle-handle-only')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopping_action_edit')), findsNothing);
      expect(find.byKey(const Key('shopping_action_delete')), findsNothing);
    });

    testWidgets(
      'completed tile leaves copy, badge, and glyph at full opacity',
      (tester) async {
        final item = _makeItem(id: 'done-style', isCompleted: true);
        await _pumpTile(
          tester,
          item: item,
          delete: mockDelete,
          toggle: mockToggle,
          isActive: false,
        );

        for (final key in [
          const ValueKey('shopping-copy-done-style'),
          const ValueKey('shopping-ledger-badge-done-style'),
          const ValueKey('shopping-drag-glyph-done-style'),
        ]) {
          final region = find.byKey(key);
          expect(region, findsOneWidget);
          expect(
            tester.widget(region),
            isNot(isA<AnimatedOpacity>()),
            reason: 'Completed subregions must not apply a second fade',
          );
          expect(
            find.ancestor(of: region, matching: find.byType(AnimatedOpacity)),
            findsNothing,
            reason: 'The completed card owns the single 0.58 opacity layer',
          );
        }

        final badge = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(
                  const ValueKey('shopping-ledger-badge-done-style'),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (badge.decoration! as BoxDecoration).color,
          AppPalette.light.backgroundMuted,
        );

        final badgeText = tester.widget<Text>(find.text('Daily'));
        expect(badgeText.style?.color, AppPalette.light.textSecondary);

        final dragIcon = tester.widget<Icon>(find.byIcon(Icons.drag_indicator));
        expect(dragIcon.color, AppPalette.light.textPrimary);
      },
    );
  });
}
