import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/shopping_list/update_shopping_item_use_case.dart';
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
  late _MockSyncEngine syncEngine;
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
    syncEngine = _MockSyncEngine();
    useCase = UpdateShoppingItemUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(() => mockRepo.findById('item-1')).thenAnswer((_) async => publicItem);
    when(
      () => mockRepo.findById('item-2'),
    ).thenAnswer((_) async => privateItem);
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
      final syncingUseCase = UpdateShoppingItemUseCase(
        shoppingItemRepository: mockRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      await syncingUseCase.execute(
        const UpdateShoppingItemParams(itemId: 'item-1', name: 'Oat Milk'),
      );

      expect(tracker.pendingCount, 1);
      verify(() => syncEngine.onTransactionChanged()).called(1);
    });

    test('private update does NOT enqueue tracker op (D37-06)', () async {
      final params = UpdateShoppingItemParams(
        itemId: 'item-2',
        name: 'Top Secret Gift',
      );

      await useCase.execute(params);

      expect(tracker.pendingCount, 0);
    });

    test('private non-durable update does not trigger sync', () async {
      final privateUseCase = UpdateShoppingItemUseCase(
        shoppingItemRepository: mockRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      final result = await privateUseCase.execute(
        const UpdateShoppingItemParams(itemId: 'item-2', name: 'Still Secret'),
      );

      expect(result.isSuccess, isTrue);
      expect(tracker.pendingCount, 0);
      verifyNever(() => syncEngine.onTransactionChanged());
    });

    test(
      'durable public update returns normalized row and skips legacy path',
      () async {
        final durableRepo = _MockDurableShoppingItemRepository();
        final normalized = publicItem.copyWith(syncRevision: 7);
        when(
          () => durableRepo.findById('item-1'),
        ).thenAnswer((_) async => publicItem);
        when(
          () => durableRepo.updateWithFamilySyncOutbox(
            any(),
            originDeviceId: 'resolved-device',
          ),
        ).thenAnswer((_) async => normalized);
        final durableUseCase = UpdateShoppingItemUseCase(
          shoppingItemRepository: durableRepo,
          changeTracker: tracker,
          syncEngine: syncEngine,
          deviceIdResolver: () async => 'resolved-device',
        );

        final result = await durableUseCase.execute(
          const UpdateShoppingItemParams(itemId: 'item-1', name: 'Oat Milk'),
        );

        expect(result.data, normalized);
        verify(
          () => durableRepo.updateWithFamilySyncOutbox(
            any(),
            originDeviceId: 'resolved-device',
          ),
        ).called(1);
        verifyNever(() => durableRepo.update(any()));
        expect(tracker.pendingCount, 0);
        verify(() => syncEngine.onTransactionChanged()).called(1);
      },
    );

    test('durable update falls back to existing device ID', () async {
      final durableRepo = _MockDurableShoppingItemRepository();
      when(
        () => durableRepo.findById('item-1'),
      ).thenAnswer((_) async => publicItem);
      when(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).thenAnswer((_) async => publicItem);
      final durableUseCase = UpdateShoppingItemUseCase(
        shoppingItemRepository: durableRepo,
        deviceIdResolver: () async => null,
      );

      await durableUseCase.execute(
        const UpdateShoppingItemParams(itemId: 'item-1'),
      );

      verify(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).called(1);
    });

    test('durable private update skips legacy tracking and sync', () async {
      final durableRepo = _MockDurableShoppingItemRepository();
      when(
        () => durableRepo.findById('item-2'),
      ).thenAnswer((_) async => privateItem);
      when(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as ShoppingItem,
      );
      final durableUseCase = UpdateShoppingItemUseCase(
        shoppingItemRepository: durableRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      final result = await durableUseCase.execute(
        const UpdateShoppingItemParams(itemId: 'item-2', name: 'Still Secret'),
      );

      expect(result.isSuccess, isTrue);
      verify(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).called(1);
      verifyNever(() => durableRepo.update(any()));
      expect(tracker.pendingCount, 0);
      verifyNever(() => syncEngine.onTransactionChanged());
    });

    test('failed persistence does not trigger sync', () async {
      when(() => mockRepo.update(any())).thenThrow(StateError('write failed'));
      final syncingUseCase = UpdateShoppingItemUseCase(
        shoppingItemRepository: mockRepo,
        syncEngine: syncEngine,
      );

      await expectLater(
        syncingUseCase.execute(
          const UpdateShoppingItemParams(itemId: 'item-1', name: 'Oat Milk'),
        ),
        throwsStateError,
      );

      verifyNever(() => syncEngine.onTransactionChanged());
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
