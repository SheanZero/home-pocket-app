import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/shopping_list/clear_completed_items_use_case.dart';
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
  late ClearCompletedItemsUseCase useCase;

  final completedPublicItem1 = ShoppingItem(
    id: 'pub-done-1',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Milk',
    isCompleted: true,
    isDeleted: false,
    createdAt: DateTime(2026, 6, 8),
  );

  final completedPublicItem2 = ShoppingItem(
    id: 'pub-done-2',
    deviceId: 'device-1',
    listType: 'public',
    name: 'Eggs',
    isCompleted: true,
    isDeleted: false,
    createdAt: DateTime(2026, 6, 8),
  );

  final completedPrivateItem = ShoppingItem(
    id: 'priv-done-1',
    deviceId: 'device-1',
    listType: 'private',
    name: 'Secret',
    isCompleted: true,
    isDeleted: false,
    createdAt: DateTime(2026, 6, 8),
  );

  setUp(() {
    mockRepo = _MockShoppingItemRepository();
    tracker = ShoppingItemChangeTracker();
    useCase = ClearCompletedItemsUseCase(
      shoppingItemRepository: mockRepo,
      changeTracker: tracker,
    );

    when(
      () => mockRepo.softDeleteAllCompleted('public'),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.softDeleteAllCompleted('private'),
    ).thenAnswer((_) async {});
    when(() => mockRepo.watchByListType('public')).thenAnswer(
      (_) => Stream.value([completedPublicItem1, completedPublicItem2]),
    );
    when(
      () => mockRepo.watchByListType('private'),
    ).thenAnswer((_) => Stream.value([completedPrivateItem]));
  });

  group('ClearCompletedItemsUseCase', () {
    test(
      'softDeleteAllCompleted called with correct listType (DONE-03, SC-2)',
      () async {
        final result = await useCase.execute('public');

        expect(result.isSuccess, isTrue);
        verify(() => mockRepo.softDeleteAllCompleted('public')).called(1);
      },
    );

    test(
      'private clearCompleted does NOT enqueue tracker ops (D37-06)',
      () async {
        await useCase.execute('private');

        expect(tracker.pendingCount, 0);
      },
    );

    test(
      'public clearCompleted enqueues one tracker op per completed item (SC-2, SYNC-01)',
      () async {
        // 2 completed public items stubbed
        await useCase.execute('public');

        expect(tracker.pendingCount, 2);
      },
    );

    test('private list soft-delete calls repo with private listType', () async {
      final result = await useCase.execute('private');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.softDeleteAllCompleted('private')).called(1);
    });

    test('durable private clear stays local-only', () async {
      final durableRepo = _MockDurableShoppingItemRepository();
      final syncEngine = _MockSyncEngine();
      var resolverCalled = false;
      when(
        () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
          'private',
          originDeviceId: '',
        ),
      ).thenAnswer((_) async => [completedPrivateItem]);
      final privateUseCase = ClearCompletedItemsUseCase(
        shoppingItemRepository: durableRepo,
        syncEngine: syncEngine,
        deviceIdResolver: () async {
          resolverCalled = true;
          throw StateError('private clears must not read sync identity');
        },
      );

      final result = await privateUseCase.execute('private');

      expect(result.isSuccess, isTrue);
      expect(resolverCalled, isFalse);
      verifyNever(() => syncEngine.onTransactionChanged());
    });

    test('all clears completed items from both persisted list types', () async {
      final result = await useCase.execute('all');

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.softDeleteAllCompleted('private')).called(1);
      verify(() => mockRepo.softDeleteAllCompleted('public')).called(1);
      expect(tracker.pendingCount, 2);
      verifyNever(() => mockRepo.softDeleteAllCompleted('all'));
    });

    test(
      'all uses durable outbox writes for private and public segments',
      () async {
        final durableRepo = _MockDurableShoppingItemRepository();
        when(
          () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
            'private',
            originDeviceId: 'device-1',
          ),
        ).thenAnswer((_) async => [completedPrivateItem]);
        when(
          () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
            'public',
            originDeviceId: 'device-1',
          ),
        ).thenAnswer((_) async => [completedPublicItem1, completedPublicItem2]);
        final durableUseCase = ClearCompletedItemsUseCase(
          shoppingItemRepository: durableRepo,
          deviceIdResolver: () async => 'device-1',
        );

        final result = await durableUseCase.execute('all');

        expect(result.isSuccess, isTrue);
        verify(
          () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
            'private',
            originDeviceId: 'device-1',
          ),
        ).called(1);
        verify(
          () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
            'public',
            originDeviceId: 'device-1',
          ),
        ).called(1);
        verifyNever(
          () => durableRepo.softDeleteAllCompletedWithFamilySyncOutbox(
            'all',
            originDeviceId: any(named: 'originDeviceId'),
          ),
        );
      },
    );
  });
}
