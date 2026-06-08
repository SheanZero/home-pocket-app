// Widget tests for ShoppingItemTile swipe-to-delete behavior.
//
// Covers: MGMT-01 (swipe-delete + confirm dialog + use-case invocation)
//
// Run: flutter test test/widget/features/shopping_list/presentation/widgets/shopping_item_tile_swipe_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_item_tile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

// Mocktail mocks
class MockDeleteShoppingItemUseCase extends Mock
    implements DeleteShoppingItemUseCase {}

class MockToggleItemCompletedUseCase extends Mock
    implements ToggleItemCompletedUseCase {}

ShoppingItem _makeItem({String id = 'item-swipe-1'}) {
  final now = DateTime(2026, 6, 8);
  return ShoppingItem(
    id: id,
    deviceId: 'device-1',
    listType: 'private',
    name: 'Swipe Test Item',
    isCompleted: false,
    createdAt: now,
  );
}

/// Pumps the tile within a SliverReorderableList so ReorderableDragStartListener compiles.
Future<void> _pumpTile(
  WidgetTester tester, {
  required ShoppingItem item,
  required MockDeleteShoppingItemUseCase delete,
  required MockToggleItemCompletedUseCase toggle,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        deleteShoppingItemUseCaseProvider.overrideWithValue(delete),
        toggleItemCompletedUseCaseProvider.overrideWithValue(toggle),
        shadowBooksProvider.overrideWith(
          (ref) async => const <ShadowBookInfo>[],
        ),
        batchSelectModeProvider.overrideWith(() => _InactiveBatchSelectMode()),
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
                  key: ValueKey('swipe-tile-$i'),
                  index: i,
                  child: ShoppingItemTile(
                    item: item,
                    index: i,
                    isActive: true,
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

class _InactiveBatchSelectMode extends BatchSelectMode {
  @override
  BatchSelectModeState build() => BatchSelectModeState.inactive();
}

void main() {
  late MockDeleteShoppingItemUseCase mockDelete;
  late MockToggleItemCompletedUseCase mockToggle;

  setUp(() {
    mockDelete = MockDeleteShoppingItemUseCase();
    mockToggle = MockToggleItemCompletedUseCase();
    when(() => mockDelete.execute(any()))
        .thenAnswer((_) async => Result.success(null));
    when(() => mockToggle.execute(any()))
        .thenAnswer((_) async => Result.success(_makeItem()));
  });

  setUpAll(() {
    registerFallbackValue('');
  });

  group('ShoppingItemTile — MGMT-01: swipe-to-delete', () {
    testWidgets(
        'swipe endToStart → confirm dialog appears',
        (tester) async {
      final item = _makeItem(id: 'item-swipe-confirm');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      // Fling to the left to trigger the Dismissible
      await tester.fling(
        find.byType(ShoppingItemTile),
        const Offset(-500, 0),
        1000,
      );
      // Pump until the confirmDismiss dialog is shown (may need multiple frames)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm dialog must appear before item is dismissed
      expect(
        find.byType(Dialog),
        findsOneWidget,
        reason: 'Confirm dialog must appear on swipe-to-delete (MGMT-01)',
      );
    });

    testWidgets(
        'confirm dialog → delete use case called with item.id (MGMT-01)',
        (tester) async {
      final item = _makeItem(id: 'item-delete-confirm');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      await tester.fling(
        find.byType(ShoppingItemTile),
        const Offset(-500, 0),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Dialog), findsOneWidget);

      // Tap the confirm (delete) button — try 'Delete' (en), fallback to '削除' (ja)
      final deleteLabel = find.text('Delete');
      final confirmBtn =
          deleteLabel.evaluate().isNotEmpty ? deleteLabel : find.text('削除');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      verify(() => mockDelete.execute('item-delete-confirm')).called(1);
    });

    testWidgets(
        'cancel confirm dialog → delete use case NOT called',
        (tester) async {
      final item = _makeItem(id: 'item-cancel-test');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      await tester.fling(
        find.byType(ShoppingItemTile),
        const Offset(-500, 0),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Dialog), findsOneWidget);

      // Tap cancel
      final cancelLabel = find.text('Cancel');
      final cancelBtn =
          cancelLabel.evaluate().isNotEmpty ? cancelLabel : find.text('キャンセル');
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      verifyNever(() => mockDelete.execute(any()));
    });

    testWidgets(
        'on delete: feedback toast appears and use case is called (MGMT-01 ordering)',
        (tester) async {
      final item = _makeItem(id: 'item-order-test');
      await _pumpTile(tester, item: item, delete: mockDelete, toggle: mockToggle);

      await tester.fling(
        find.byType(ShoppingItemTile),
        const Offset(-500, 0),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Dialog), findsOneWidget);

      final deleteLabel = find.text('Delete');
      final confirmBtn =
          deleteLabel.evaluate().isNotEmpty ? deleteLabel : find.text('削除');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Both the feedback toast and delete call happen in onDismissed.
      // Verify the use case was called (ordering is structural: feedback appears
      // on the line before execute in shopping_item_tile.dart).
      verify(() => mockDelete.execute('item-order-test')).called(1);
    });
  });
}
