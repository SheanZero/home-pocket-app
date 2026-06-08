import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
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
        // Prime the watch stream before applying sync op
        final streamFuture = shoppingItemRepo.watchByListType('public').first;

        await applyOps.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item', // kShoppingItemEntityType
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
          reason: 'Public item from member A must appear in watchByListType stream (SYNC-06)',
        );
      },
    );

    test(
      'private item NEVER appears in watchByListType("public") stream (SYNC-02, SC-5)',
      () async {
        await applyOps.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
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
          reason: 'Private item from remote member must NEVER appear in public watch stream (SYNC-02)',
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
            'entityType': 'shopping_item',
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
            'entityType': 'shopping_item',
            'entityId': 'item-tombstone',
            'fromDeviceId': 'partner-device',
          },
        ]);

        // 3. Stale update arrives (should not resurrect tombstone)
        await applyOps.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
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
  });
}
