import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

void main() {
  late _MockShoppingItemRepository mockRepo;
  late ShoppingItemChangeTracker tracker;
  late UpdateShoppingItemUseCase useCase;

  final publicItem = ShoppingItem(
    id: 'item-1',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Milk',
    createdAt: DateTime(2026, 6, 8),
  );

  final privateItem = ShoppingItem(
    id: 'item-2',
    deviceId: 'device-1',
    listType: 'private',
    name: 'Secret Gift',
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
    useCase = UpdateShoppingItemUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(() => mockRepo.findById('item-1')).thenAnswer((_) async => publicItem);
    when(() => mockRepo.findById('item-2')).thenAnswer((_) async => privateItem);
    when(() => mockRepo.update(any())).thenAnswer((_) async {});
  });

  group('UpdateShoppingItemUseCase', () {
    test(
      'listType change returns Result.error with "Invariant" in message (D37-04, SC-2, SYNC-03)',
      () async {
        final params = UpdateShoppingItemParams(
          itemId: 'item-1',
          listType: 'private', // attempt to change from 'public' to 'private'
        );

        final result = await useCase.execute(params);

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invariant'));
      },
    );

    test('name update succeeds and calls repo.update (ITEM-04)', () async {
      final params = UpdateShoppingItemParams(
        itemId: 'item-1',
        name: 'Oat Milk',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.update(any())).called(1);
    });

    test('public update enqueues tracker op (SYNC-01)', () async {
      final params = UpdateShoppingItemParams(
        itemId: 'item-1',
        name: 'Oat Milk',
      );

      await useCase.execute(params);

      expect(tracker.pendingCount, 1);
    });

    test('private update does NOT enqueue tracker op (D37-06)', () async {
      final params = UpdateShoppingItemParams(
        itemId: 'item-2',
        name: 'Top Secret Gift',
      );

      await useCase.execute(params);

      expect(tracker.pendingCount, 0);
    });

    test('item not found returns Result.error', () async {
      when(() => mockRepo.findById('missing')).thenAnswer((_) async => null);

      final params = UpdateShoppingItemParams(
        itemId: 'missing',
        name: 'New Name',
      );

      final result = await useCase.execute(params);

      expect(result.isSuccess, isFalse);
    });
  });
}
