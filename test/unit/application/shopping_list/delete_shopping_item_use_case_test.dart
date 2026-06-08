import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

void main() {
  late _MockShoppingItemRepository mockRepo;
  late ShoppingItemChangeTracker tracker;
  late DeleteShoppingItemUseCase useCase;

  final publicItem = ShoppingItem(
    id: 'item-pub',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Milk',
    createdAt: DateTime(2026, 6, 8),
  );

  final privateItem = ShoppingItem(
    id: 'item-priv',
    deviceId: 'device-1',
    listType: 'private',
    name: 'Secret',
    createdAt: DateTime(2026, 6, 8),
  );

  setUpAll(() {
    registerFallbackValue('fallback-id');
  });

  setUp(() {
    mockRepo = _MockShoppingItemRepository();
    tracker = ShoppingItemChangeTracker();
    useCase = DeleteShoppingItemUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(() => mockRepo.findById('item-pub')).thenAnswer((_) async => publicItem);
    when(
      () => mockRepo.findById('item-priv'),
    ).thenAnswer((_) async => privateItem);
    when(() => mockRepo.findById(any())).thenAnswer((_) async => null);
    when(() => mockRepo.softDelete(any())).thenAnswer((_) async {});
  });

  group('DeleteShoppingItemUseCase', () {
    test('softDelete called with correct itemId (MGMT-01)', () async {
      final result = await useCase.execute('item-pub');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.softDelete('item-pub')).called(1);
    });

    test(
      'public delete enqueues tombstone tracker op (MGMT-01, SYNC-01)',
      () async {
        await useCase.execute('item-pub');

        expect(tracker.pendingCount, 1);
      },
    );

    test(
      'private delete does NOT enqueue tracker op (D37-06, MGMT-01)',
      () async {
        await useCase.execute('item-priv');

        expect(tracker.pendingCount, 0);
      },
    );

    test('itemId not found returns Result.error (MGMT-02)', () async {
      final result = await useCase.execute('missing-item');

      expect(result.isSuccess, isFalse);
      expect(result.error, isNotNull);
    });

    test('empty itemId returns Result.error', () async {
      final result = await useCase.execute('');

      expect(result.isSuccess, isFalse);
    });
  });
}
