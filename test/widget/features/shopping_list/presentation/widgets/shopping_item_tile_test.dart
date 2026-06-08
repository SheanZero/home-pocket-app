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
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_item_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// Mocktail mocks for the two use cases referenced by the tile
class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

/// Minimal ShoppingItem fixture for widget tests.
ShoppingItem _makeItem({
  String id = 'item-1',
  String listType = 'public',
  LedgerType? ledgerType = LedgerType.daily,
  bool isCompleted = false,
  String? addedByBookId,
  int? estimatedPrice,
  int quantity = 1,
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
                onReorder: (_, _) {},
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
  });

  group('ShoppingItemTile — SHOP-02: renders item.name as primary text', () {
    testWidgets('tile displays item.name as Text widget', (tester) async {
      final item = _makeItem();
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      expect(find.text('Test Item'), findsOneWidget);
    });
  });

  group('ShoppingItemTile — SHOP-03: left-border accent colour', () {
    testWidgets('daily ledger: left border color = palette.daily', (tester) async {
      final item = _makeItem(ledgerType: LedgerType.daily);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      final containers = tester.widgetList<Container>(find.byType(Container));
      final expected = AppPalette.light.daily;
      final found = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.border is Border) {
          final left = (deco.border! as Border).left;
          return left.color == expected && left.width == 4;
        }
        return false;
      });
      expect(found, isTrue,
          reason: 'Container with left BorderSide(color:daily, width:4) not found');
    });

    testWidgets('null ledger: left border color = palette.borderList', (tester) async {
      final item = _makeItem(ledgerType: null);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      final containers = tester.widgetList<Container>(find.byType(Container));
      final expected = AppPalette.light.borderList;
      final found = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.border is Border) {
          final left = (deco.border! as Border).left;
          return left.color == expected && left.width == 4;
        }
        return false;
      });
      expect(found, isTrue,
          reason: 'Container with left BorderSide(color:borderList, width:4) not found');
    });

    testWidgets('joy ledger: left border color = palette.joy', (tester) async {
      final item = _makeItem(ledgerType: LedgerType.joy);
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      final containers = tester.widgetList<Container>(find.byType(Container));
      final expected = AppPalette.light.joy;
      final found = containers.any((c) {
        final deco = c.decoration;
        if (deco is BoxDecoration && deco.border is Border) {
          final left = (deco.border! as Border).left;
          return left.color == expected && left.width == 4;
        }
        return false;
      });
      expect(found, isTrue,
          reason: 'Container with left BorderSide(color:joy, width:4) not found');
    });
  });

  group('ShoppingItemTile — DONE-01: tap calls toggleItemCompletedUseCase', () {
    testWidgets('tap row body calls execute(item.id)', (tester) async {
      final item = _makeItem(id: 'item-tap-test');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      // Tap the outer GestureDetector (first is the tile's tap target)
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      verify(() => mockToggle.execute('item-tap-test')).called(1);
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
}
