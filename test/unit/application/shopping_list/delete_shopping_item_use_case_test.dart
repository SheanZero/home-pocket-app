import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/shopping_list/delete_shopping_item_use_case.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _MockDurableShoppingItemRepository extends Mock
    implements DurableFamilySyncShoppingItemRepository {}

class _MockSyncEngine extends Mock implements SyncEngine {}

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

    // any() registered first so specific stubs registered after it win (mocktail lastWhere)
    when(() => mockRepo.findById(any())).thenAnswer((_) async => null);
    when(
      () => mockRepo.findById('item-pub'),
    ).thenAnswer((_) async => publicItem);
    when(
      () => mockRepo.findById('item-priv'),
    ).thenAnswer((_) async => privateItem);
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

    test('durable private delete stays local-only', () async {
      final durableRepo = _MockDurableShoppingItemRepository();
      final syncEngine = _MockSyncEngine();
      var resolverCalled = false;
      when(
        () => durableRepo.findById('item-priv'),
      ).thenAnswer((_) async => privateItem);
      when(
        () => durableRepo.softDeleteWithFamilySyncOutbox(
          'item-priv',
          originDeviceId: 'device-1',
        ),
      ).thenAnswer((_) async => privateItem.copyWith(isDeleted: true));
      final privateUseCase = DeleteShoppingItemUseCase(
        shoppingItemRepository: durableRepo,
        syncEngine: syncEngine,
        deviceIdResolver: () async {
          resolverCalled = true;
          throw StateError('private deletes must not read sync identity');
        },
      );

      final result = await privateUseCase.execute('item-priv');

      expect(result.isSuccess, isTrue);
      expect(resolverCalled, isFalse);
      verifyNever(() => syncEngine.onTransactionChanged());
    });

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
