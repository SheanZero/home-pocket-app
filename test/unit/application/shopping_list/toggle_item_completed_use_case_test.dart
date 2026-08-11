import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/shopping_list/toggle_item_completed_use_case.dart';
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
    syncEngine = _MockSyncEngine();
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
        when(() => mockRepo.update(any())).thenAnswer((inv) async {
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
        when(() => mockRepo.update(any())).thenAnswer((inv) async {
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
      final syncingUseCase = ToggleItemCompletedUseCase(
        shoppingItemRepository: mockRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      await syncingUseCase.execute('item-pub');

      expect(tracker.pendingCount, 1);
      verify(() => syncEngine.onTransactionChanged()).called(1);
    });

    test('private non-durable toggle does not track or trigger sync', () async {
      final privateItem = incompletePublicItem.copyWith(
        id: 'item-private',
        listType: 'private',
      );
      when(
        () => mockRepo.findById('item-private'),
      ).thenAnswer((_) async => privateItem);
      final privateUseCase = ToggleItemCompletedUseCase(
        shoppingItemRepository: mockRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      final result = await privateUseCase.execute('item-private');

      expect(result.isSuccess, isTrue);
      expect(tracker.pendingCount, 0);
      verifyNever(() => syncEngine.onTransactionChanged());
    });

    test(
      'durable public toggle returns normalized row and skips legacy path',
      () async {
        final durableRepo = _MockDurableShoppingItemRepository();
        final normalized = incompletePublicItem.copyWith(
          isCompleted: true,
          completedAt: DateTime(2026, 6, 9),
          syncRevision: 8,
        );
        when(
          () => durableRepo.findById('item-pub'),
        ).thenAnswer((_) async => incompletePublicItem);
        when(
          () => durableRepo.updateWithFamilySyncOutbox(
            any(),
            originDeviceId: 'resolved-device',
          ),
        ).thenAnswer((_) async => normalized);
        final durableUseCase = ToggleItemCompletedUseCase(
          shoppingItemRepository: durableRepo,
          changeTracker: tracker,
          syncEngine: syncEngine,
          deviceIdResolver: () async => 'resolved-device',
        );

        final result = await durableUseCase.execute('item-pub');

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

    test('durable toggle falls back to existing device ID', () async {
      final durableRepo = _MockDurableShoppingItemRepository();
      when(
        () => durableRepo.findById('item-pub'),
      ).thenAnswer((_) async => incompletePublicItem);
      when(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).thenAnswer((_) async => incompletePublicItem);
      final durableUseCase = ToggleItemCompletedUseCase(
        shoppingItemRepository: durableRepo,
        deviceIdResolver: () async => null,
      );

      await durableUseCase.execute('item-pub');

      verify(
        () => durableRepo.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).called(1);
    });

    test('durable private toggle skips legacy tracking and sync', () async {
      final privateItem = incompletePublicItem.copyWith(
        id: 'item-private',
        listType: 'private',
      );
      final durableRepo = _MockDurableShoppingItemRepository();
      when(
        () => durableRepo.findById('item-private'),
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
      final durableUseCase = ToggleItemCompletedUseCase(
        shoppingItemRepository: durableRepo,
        changeTracker: tracker,
        syncEngine: syncEngine,
      );

      final result = await durableUseCase.execute('item-private');

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

    test(
      'durable private toggle does not resolve sync device identity',
      () async {
        final privateItem = incompletePublicItem.copyWith(
          id: 'item-private-local',
          listType: 'private',
        );
        final durableRepo = _MockDurableShoppingItemRepository();
        var resolverCalled = false;
        when(
          () => durableRepo.findById('item-private-local'),
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
        final privateUseCase = ToggleItemCompletedUseCase(
          shoppingItemRepository: durableRepo,
          deviceIdResolver: () async {
            resolverCalled = true;
            throw StateError('private updates must not read sync identity');
          },
        );

        final result = await privateUseCase.execute('item-private-local');

        expect(result.isSuccess, isTrue);
        expect(resolverCalled, isFalse);
        verify(
          () => durableRepo.updateWithFamilySyncOutbox(
            any(),
            originDeviceId: 'device-1',
          ),
        ).called(1);
      },
    );

    test('failed persistence does not trigger sync', () async {
      when(() => mockRepo.update(any())).thenThrow(StateError('write failed'));
      final syncingUseCase = ToggleItemCompletedUseCase(
        shoppingItemRepository: mockRepo,
        syncEngine: syncEngine,
      );

      await expectLater(syncingUseCase.execute('item-pub'), throwsStateError);

      verifyNever(() => syncEngine.onTransactionChanged());
    });

    test('item not found returns Result.error', () async {
      when(() => mockRepo.findById('missing')).thenAnswer((_) async => null);

      final result = await useCase.execute('missing');

      expect(result.isSuccess, isFalse);
    });
  });
}
