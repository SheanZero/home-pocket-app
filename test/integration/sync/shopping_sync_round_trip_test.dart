import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late AppDatabase db;
  late ShoppingItemDao shoppingItemDao;
  late ShoppingItemRepositoryImpl shoppingItemRepo;
  late ApplySyncOperationsUseCase applyOps;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();

    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockGroupRepository.getPendingGroup()).thenAnswer(
      (_) async => null,
    );

    shoppingItemDao = ShoppingItemDao(db);
    shoppingItemRepo = ShoppingItemRepositoryImpl(
      dao: shoppingItemDao,
      encryptionService: mockEncryption,
    );

    // Still need the bill/shadow infrastructure for ApplySyncOperationsUseCase
    final bookDao = BookDao(db);
    final txDao = TransactionDao(db);
    final bookRepo = BookRepositoryImpl(dao: bookDao);
    final txRepo = TransactionRepositoryImpl(
      dao: txDao,
      encryptionService: mockEncryption,
    );
    final shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: txRepo,
    );

    applyOps = ApplySyncOperationsUseCase(
      transactionRepository: txRepo,
      shoppingItemRepository: shoppingItemRepo,
      shadowBookService: shadowBookService,
      groupRepository: mockGroupRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Shopping sync round trip', () {
    test(
      'public item from member A appears in watchByListType stream (SYNC-06, SC-5)',
      () async {
        // Subscribe to stream BEFORE applying sync op.
        // Drift's .watch() emits an initial snapshot immediately (empty list), then
        // re-emits after every write. We skip(1) to skip the initial empty state and
        // wait for the post-write emission — demonstrating reactive delivery WITHOUT
        // ref.invalidate (v1.4 GAP-2 lesson; SYNC-06, SC-5).
        final streamFuture = shoppingItemRepo
            .watchByListType('public')
            .skip(1) // skip initial empty emission; wait for post-write re-emission
            .first
            .timeout(const Duration(seconds: 5));

        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-1',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-1',
              'listType': 'public',
              'name': 'Milk',
              'quantity': 2,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        final items = await streamFuture;
        expect(
          items.any((i) => i.id == 'item-1'),
          isTrue,
          reason:
              'Public item from member A must appear in watchByListType stream '
              'WITHOUT manual ref.invalidate (SYNC-06, SC-5)',
        );
      },
    );

    test(
      'private item NEVER appears in watchByListType("public") stream (SYNC-02, SC-5)',
      () async {
        // Apply the private item write first, then check the stream state.
        // The private item IS written to the DB (upsert via apply handler),
        // but the SQL WHERE clause `WHERE list_type = 'public'` excludes it.
        // This verifies the privacy gate holds at the DAO level (SYNC-02).
        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'private-item-1',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'private-item-1',
              'listType': 'private',
              'name': 'Secret Gift',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        final items = await shoppingItemRepo.watchByListType('public').first;
        expect(
          items.any((i) => i.id == 'private-item-1'),
          isFalse,
          reason:
              'Private item from remote member must NEVER appear in public '
              'watch stream (SYNC-02, SC-5)',
        );
      },
    );

    test(
      'tombstone not resurrected: apply create → delete → update → item stays deleted (SC-4)',
      () async {
        // 1. Create
        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-tombstone',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-tombstone',
              'listType': 'public',
              'name': 'Bread',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // 2. Delete (tombstone)
        await applyOps.execute([
          {
            'op': 'delete',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-tombstone',
            'fromDeviceId': 'partner-device',
          },
        ]);

        // 3. Stale update arrives (should not resurrect tombstone)
        await applyOps.execute([
          {
            'op': 'update',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-tombstone',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-tombstone',
              'listType': 'public',
              'name': 'Sourdough Bread',
              'quantity': 2,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T10:05:00.000Z',
            },
          },
        ]);

        // Tombstone must survive — item stays deleted
        final item = await shoppingItemRepo.findById('item-tombstone');
        expect(item, isNotNull);
        expect(
          item!.isDeleted,
          isTrue,
          reason: 'Tombstone must NOT be resurrected by a remote update op (SC-4)',
        );
      },
    );

    test(
      'sticky-complete merge: stale rename does NOT un-check completed item (D-03, SC-4)',
      () async {
        // T1 (later) = when the item was completed locally
        // T0 (earlier) = when the stale remote update was made
        // The update arrived with T0 < T1 and isCompleted=false — must NOT un-check.
        final t1 = DateTime(2026, 6, 8, 10, 0); // completion time (newer)
        final t0 = DateTime(2026, 6, 8, 9, 0); // stale update time (older)

        // 1. Create item with isCompleted=true and completedAt=T1
        await applyOps.execute([
          {
            'op': 'create',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Eggs',
              'quantity': 1,
              'isCompleted': true,
              'completedAt': t1.toUtc().toIso8601String(),
              'createdAt': '2026-06-08T08:00:00.000Z',
              'updatedAt': t1.toUtc().toIso8601String(),
            },
          },
        ]);

        // 2. Apply stale update: updatedAt=T0 (older than completedAt=T1), isCompleted=false
        //    This simulates a rename that arrived out-of-order (D-03/D37-02 sticky-complete)
        await applyOps.execute([
          {
            'op': 'update',
            'entityType': kShoppingItemEntityType,
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Free Range Eggs', // stale rename
              'quantity': 1,
              'isCompleted': false, // stale — must NOT override local completion
              'createdAt': '2026-06-08T08:00:00.000Z',
              'updatedAt': t0.toUtc().toIso8601String(), // T0 < T1 → stale
            },
          },
        ]);

        // Completion state must be preserved (sticky-complete: T1 > T0)
        final item = await shoppingItemRepo.findById('item-sticky');
        expect(item, isNotNull);
        expect(
          item!.isCompleted,
          isTrue,
          reason:
              'Stale remote rename must NOT un-check a locally-completed item '
              '(D-03/D37-02 sticky-complete merge, SC-4)',
        );
      },
    );
  });
}
