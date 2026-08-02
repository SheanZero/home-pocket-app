import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/category_reference_sync_service.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/category_ledger_config_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_sync_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/category_sync_snapshot.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _Encryption extends Mock implements FieldEncryptionService {}

class _Groups extends Mock implements GroupRepository {}

class _Shopping extends Mock implements ShoppingItemRepository {}

void main() {
  late AppDatabase sourceDb;
  late AppDatabase receiverDb;
  late CategoryDao sourceCategoryDao;
  late CategoryDao receiverCategoryDao;
  late CategoryReferenceSyncService sourceCategories;
  late CategoryReferenceSyncService receiverCategories;
  late ApplySyncOperationsUseCase apply;

  setUp(() async {
    sourceDb = AppDatabase.forTesting();
    receiverDb = AppDatabase.forTesting();
    sourceCategoryDao = CategoryDao(sourceDb);
    receiverCategoryDao = CategoryDao(receiverDb);
    sourceCategories = CategoryReferenceSyncService(
      repository: CategorySyncRepositoryImpl(dao: sourceCategoryDao),
    );
    receiverCategories = CategoryReferenceSyncService(
      repository: CategorySyncRepositoryImpl(dao: receiverCategoryDao),
    );

    final encryption = _Encryption();
    when(
      () => encryption.encryptField(any()),
    ).thenAnswer((call) async => call.positionalArguments.first as String);
    when(
      () => encryption.decryptField(any()),
    ).thenAnswer((call) async => call.positionalArguments.first as String);
    final transactionRepository = TransactionRepositoryImpl(
      dao: TransactionDao(receiverDb),
      encryptionService: encryption,
    );
    final shadowBooks = ShadowBookService(
      bookRepository: BookRepositoryImpl(dao: BookDao(receiverDb)),
      transactionRepository: transactionRepository,
    );
    await shadowBooks.createShadowBook(
      groupId: 'group-1',
      memberDeviceId: 'device-a',
      memberDeviceName: 'Device A',
    );
    apply = ApplySyncOperationsUseCase(
      transactionRepository: transactionRepository,
      shoppingItemRepository: _Shopping(),
      shadowBookService: shadowBooks,
      groupRepository: _Groups(),
      inboundRepository: MemoryInboundSyncOperationRepository(),
      categoryReferenceSyncService: receiverCategories,
    );
  });

  tearDown(() async {
    await sourceDb.close();
    await receiverDb.close();
  });

  Future<Map<String, dynamic>> referencedBillOperation({
    int categoryRevision = 100,
  }) async {
    final createdAt = DateTime.utc(2026, 7, 1);
    await sourceCategoryDao.insertCategory(
      id: 'custom-parent',
      name: 'Family Food',
      icon: 'restaurant',
      color: '#123456',
      level: 1,
      createdAt: createdAt,
      sharedRevision: categoryRevision,
      sharedOriginDeviceId: 'device-a',
    );
    await sourceCategoryDao.insertCategory(
      id: 'custom-child',
      name: 'Weekend Brunch',
      icon: 'brunch_dining',
      color: '#654321',
      parentId: 'custom-parent',
      level: 2,
      createdAt: createdAt,
      sharedRevision: categoryRevision,
      sharedOriginDeviceId: 'device-a',
    );
    final transaction = Transaction(
      id: 'tx-custom',
      bookId: 'book-a',
      deviceId: 'device-a',
      amount: 1200,
      type: TransactionType.expense,
      categoryId: 'custom-child',
      ledgerType: LedgerType.joy,
      timestamp: createdAt,
      currentHash: 'hash',
      createdAt: createdAt,
      syncRevision: 200,
      syncOriginDeviceId: 'device-a',
      joyFullness: 8,
    );
    return sourceCategories.attachToBillOperation(
      transaction: transaction,
      operation: TransactionSyncMapper.toCreateOperation(
        transaction,
        sourceBookId: 'book-a',
        sourceBookName: 'Source',
        sourceBookType: 'remote_book:book-a',
      )..['fromDeviceId'] = 'device-a',
    );
  }

  test(
    'referenced custom L1/L2 snapshot and bill round-trip together',
    () async {
      final operation = await referencedBillOperation();
      operation['operationId'] = 'category-round-trip:0';
      final result = await apply.execute([operation], groupId: 'group-1');
      final duplicate = await apply.execute([operation], groupId: 'group-1');

      expect(result.isAckSafe, isTrue);
      expect(
        duplicate.operations.single.status,
        SyncOperationApplyStatus.alreadyApplied,
      );
      expect(
        (await receiverCategoryDao.findById('custom-parent'))?.name,
        'Family Food',
      );
      expect(
        (await receiverCategoryDao.findById('custom-child'))?.name,
        'Weekend Brunch',
      );
      final transaction = await TransactionDao(
        receiverDb,
      ).findById('tx-custom');
      expect(transaction?.categoryId, 'custom-child');
      expect(transaction?.ledgerType, 'joy');
      expect(transaction?.joyFullness, 8);
    },
  );

  test('newer update wins and older update cannot roll it back', () async {
    final newer = CategorySyncSnapshot(
      id: 'custom-1',
      name: 'New name',
      icon: 'new_icon',
      color: '#ABCDEF',
      parentId: null,
      level: 1,
      revision: 20,
      originDeviceId: 'device-b',
      isDeleted: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
      ledgerTypeHint: LedgerType.daily,
    );
    final older = CategorySyncSnapshot(
      id: 'custom-1',
      name: 'Old name',
      icon: 'old_icon',
      color: '#111111',
      parentId: null,
      level: 1,
      revision: 10,
      originDeviceId: 'device-a',
      isDeleted: false,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 1),
      ledgerTypeHint: LedgerType.daily,
    );
    await CategorySyncRepositoryImpl(
      dao: receiverCategoryDao,
    ).applyReferenceSnapshots([newer]);
    await CategorySyncRepositoryImpl(
      dao: receiverCategoryDao,
    ).applyReferenceSnapshots([older]);

    expect((await receiverCategoryDao.findById('custom-1'))?.name, 'New name');
  });

  test('producer carries updated shared semantics and tombstones', () async {
    await sourceCategoryDao.insertCategory(
      id: 'custom-mutated',
      name: 'Before',
      icon: 'before',
      color: '#111111',
      level: 1,
      createdAt: DateTime.utc(2026),
      sharedRevision: 1,
      sharedOriginDeviceId: 'device-a',
    );
    await sourceCategoryDao.updateCategory(
      id: 'custom-mutated',
      name: 'After',
      icon: 'after',
      color: '#222222',
      updatedAt: DateTime.utc(2026, 2),
    );
    final syncRepository = CategorySyncRepositoryImpl(dao: sourceCategoryDao);
    var snapshots = await syncRepository.buildReferenceSnapshots(
      categoryId: 'custom-mutated',
      fallbackOriginDeviceId: 'device-a',
      ledgerTypeHint: LedgerType.daily,
    );
    expect(snapshots.single.name, 'After');
    expect(
      snapshots.single.revision,
      DateTime.utc(2026, 2).microsecondsSinceEpoch,
    );

    await syncRepository.applyReferenceSnapshots([
      CategorySyncSnapshot(
        id: 'custom-mutated',
        name: 'After',
        icon: 'after',
        color: '#222222',
        parentId: null,
        level: 1,
        revision: snapshots.single.revision + 1,
        originDeviceId: 'device-a',
        isDeleted: true,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 3),
        ledgerTypeHint: LedgerType.daily,
      ),
    ]);
    snapshots = await syncRepository.buildReferenceSnapshots(
      categoryId: 'custom-mutated',
      fallbackOriginDeviceId: 'device-a',
      ledgerTypeHint: LedgerType.daily,
    );
    expect(snapshots.single.isDeleted, isTrue);
  });

  test(
    'tombstone hides selection but preserves historical display row',
    () async {
      final live = CategorySyncSnapshot(
        id: 'custom-deleted',
        name: 'Old shared name',
        icon: 'history',
        color: '#222222',
        parentId: null,
        level: 1,
        revision: 10,
        originDeviceId: 'device-a',
        isDeleted: false,
        createdAt: DateTime.utc(2026),
        updatedAt: null,
        ledgerTypeHint: LedgerType.joy,
      );
      final tombstone = CategorySyncSnapshot(
        id: live.id,
        name: live.name,
        icon: live.icon,
        color: live.color,
        parentId: null,
        level: 1,
        revision: 11,
        originDeviceId: 'device-a',
        isDeleted: true,
        createdAt: live.createdAt,
        updatedAt: DateTime.utc(2026, 2),
        ledgerTypeHint: LedgerType.joy,
      );
      final repository = CategorySyncRepositoryImpl(dao: receiverCategoryDao);
      await repository.applyReferenceSnapshots([live, tombstone]);

      expect(await receiverCategoryDao.findById(live.id), isNotNull);
      expect(
        (await receiverCategoryDao.findActive()).map((row) => row.id),
        isNot(contains(live.id)),
      );
    },
  );

  test(
    'incoming shared snapshot preserves personal archive, order, and ledger config',
    () async {
      await receiverCategoryDao.insertCategory(
        id: 'custom-local-pref',
        name: 'Before',
        icon: 'before',
        color: '#111111',
        level: 1,
        isArchived: true,
        sortOrder: 42,
        createdAt: DateTime.utc(2026),
        sharedRevision: 1,
        sharedOriginDeviceId: 'device-a',
      );
      final ledgerDao = CategoryLedgerConfigDao(receiverDb);
      await ledgerDao.upsert(
        categoryId: 'custom-local-pref',
        ledgerType: 'joy',
        updatedAt: DateTime.utc(2026),
      );
      await CategorySyncRepositoryImpl(
        dao: receiverCategoryDao,
      ).applyReferenceSnapshots([
        CategorySyncSnapshot(
          id: 'custom-local-pref',
          name: 'After',
          icon: 'after',
          color: '#FFFFFF',
          parentId: null,
          level: 1,
          revision: 2,
          originDeviceId: 'device-b',
          isDeleted: false,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026, 2),
          ledgerTypeHint: LedgerType.daily,
        ),
      ]);

      final row = await receiverCategoryDao.findById('custom-local-pref');
      expect(row?.name, 'After');
      expect(row?.isArchived, isTrue);
      expect(row?.sortOrder, 42);
      expect(
        (await ledgerDao.findById('custom-local-pref'))?.ledgerType,
        'joy',
      );
    },
  );

  test('system category is not copied into bill snapshots', () async {
    await sourceCategoryDao.insertCategory(
      id: 'cat_food',
      name: 'category_food',
      icon: 'restaurant',
      color: '#123456',
      level: 1,
      isSystem: true,
      createdAt: DateTime.utc(2026),
    );
    final tx = Transaction(
      id: 'tx-system',
      bookId: 'book',
      deviceId: 'device-a',
      amount: 1,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.daily,
      timestamp: DateTime.utc(2026),
      currentHash: 'hash',
      createdAt: DateTime.utc(2026),
    );
    final op = await sourceCategories.attachToBillOperation(
      transaction: tx,
      operation: TransactionSyncMapper.toCreateOperation(
        tx,
        sourceBookId: 'book',
        sourceBookName: 'book',
        sourceBookType: 'remote_book:book',
      ),
    );
    expect(
      (op['data'] as Map<String, dynamic>),
      isNot(contains('categorySnapshots')),
    );
  });

  test(
    'unknown parent gets hidden placeholder and duplicate operation is idempotent',
    () async {
      final data = {
        'categoryId': 'orphan-child',
        'categorySnapshots': [
          CategorySyncSnapshot(
            id: 'orphan-child',
            name: 'Orphan child',
            icon: 'child',
            color: '#123456',
            parentId: 'missing-parent',
            level: 2,
            revision: 1,
            originDeviceId: 'device-a',
            isDeleted: false,
            createdAt: DateTime.utc(2026),
            updatedAt: null,
            ledgerTypeHint: LedgerType.daily,
          ).toSyncMap(),
        ],
      };
      await receiverCategories.applyFromBillData(data);
      await receiverCategories.applyFromBillData(data);

      expect(await receiverCategoryDao.findById('orphan-child'), isNotNull);
      expect(
        (await receiverCategoryDao.findById('missing-parent'))?.sharedIsDeleted,
        isTrue,
      );
    },
  );
}
