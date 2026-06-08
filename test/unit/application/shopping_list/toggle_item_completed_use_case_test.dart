import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

void main() {
  late _MockShoppingItemRepository mockRepo;
  late ShoppingItemChangeTracker tracker;
  late ToggleItemCompletedUseCase useCase;

  final completedAt = DateTime(2026, 6, 1);

  final incompletePublicItem = ShoppingItem(
    id: 'item-pub',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Milk',
    isCompleted: false,
    createdAt: DateTime(2026, 6, 8),
  );

  final completedPublicItem = ShoppingItem(
    id: 'item-pub-done',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Eggs',
    isCompleted: true,
    completedAt: completedAt,
    updatedAt: completedAt,
    createdAt: DateTime(2026, 6, 8),
  );

  setUpAll(() {
    registerFallbackValue(
      ShoppingItem(
        id: 'fallback-id',
        deviceId: 'device-1',
        listType: 'public',
        name: 'Fallback',
        createdAt: DateTime(2026, 6, 8),
      ),
    );
  });

  setUp(() {
    mockRepo = _MockShoppingItemRepository();
    tracker = ShoppingItemChangeTracker();
    useCase = ToggleItemCompletedUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(
      () => mockRepo.findById('item-pub'),
    ).thenAnswer((_) async => incompletePublicItem);
    when(
      () => mockRepo.findById('item-pub-done'),
    ).thenAnswer((_) async => completedPublicItem);
    when(() => mockRepo.update(any())).thenAnswer((_) async {});
  });

  group('ToggleItemCompletedUseCase', () {
    test(
      'toggle incomplete → completed: isCompleted=true, completedAt non-null (DONE-01)',
      () async {
        ShoppingItem? capturedItem;
        when(
          () => mockRepo.update(any()),
        ).thenAnswer((inv) async {
          capturedItem = inv.positionalArguments.first as ShoppingItem;
        });

        final result = await useCase.execute('item-pub');

        expect(result.isSuccess, isTrue);
        verify(() => mockRepo.update(any())).called(1);
        expect(capturedItem, isNotNull);
        expect(capturedItem!.isCompleted, isTrue);
        expect(capturedItem!.completedAt, isNotNull);
      },
    );

    test(
      'toggle completed → uncompleted: clears completedAt to null, fresh updatedAt (D37-02)',
      () async {
        ShoppingItem? capturedItem;
        when(
          () => mockRepo.update(any()),
        ).thenAnswer((inv) async {
          capturedItem = inv.positionalArguments.first as ShoppingItem;
        });

        final result = await useCase.execute('item-pub-done');

        expect(result.isSuccess, isTrue);
        verify(() => mockRepo.update(any())).called(1);
        expect(capturedItem, isNotNull);
        expect(capturedItem!.isCompleted, isFalse);
        // D37-02: deliberate un-complete MUST clear completedAt to null
        // so sticky-complete guard does NOT fire on remote devices
        expect(capturedItem!.completedAt, isNull);
        // Fresh updatedAt must be set
        expect(capturedItem!.updatedAt, isNotNull);
      },
    );

    test('public toggle enqueues tracker op (SYNC-01)', () async {
      await useCase.execute('item-pub');

      expect(tracker.pendingCount, 1);
    });

    test('item not found returns Result.error', () async {
      when(() => mockRepo.findById('missing')).thenAnswer((_) async => null);

      final result = await useCase.execute('missing');

      expect(result.isSuccess, isFalse);
    });
  });
}
