import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/family_sync_outbox_dao.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/family_sync_outbox_repository_impl.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_sync_mapper.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

Transaction _transaction({
  String id = 'tx-1',
  int revision = 100,
  bool isPrivate = false,
  bool isDeleted = false,
  FamilySyncVisibility visibility = FamilySyncVisibility.shared,
}) {
  final now = DateTime.utc(2026, 8, 2);
  return Transaction(
    id: id,
    bookId: 'book-1',
    deviceId: 'device-1',
    amount: 1200,
    type: TransactionType.expense,
    categoryId: 'cat-food',
    ledgerType: LedgerType.daily,
    timestamp: now,
    currentHash: 'hash-$revision',
    createdAt: now,
    updatedAt: now,
    entrySource: EntrySource.manual,
    syncRevision: revision,
    syncOriginDeviceId: 'device-1',
    isPrivate: isPrivate,
    isDeleted: isDeleted,
    familySyncVisibility: visibility,
    familySharedRevision: visibility == FamilySyncVisibility.localOnly
        ? 0
        : revision,
  );
}

Map<String, dynamic> _live(Transaction transaction) =>
    TransactionSyncMapper.toCreateOperation(
      transaction,
      sourceBookId: transaction.bookId,
      sourceBookName: 'Book',
      sourceBookType: 'remote_book:${transaction.bookId}',
    );

Future<void> _activateGroup(AppDatabase db, String groupId) {
  return db.customStatement(
    '''
      INSERT INTO groups (group_id, status, role, created_at)
      VALUES (?, 'active', 'owner', ?)
    ''',
    [groupId, DateTime.now().millisecondsSinceEpoch],
  );
}

void main() {
  late AppDatabase db;
  late TransactionRepositoryImpl repository;
  late FamilySyncOutboxRepositoryImpl outbox;

  setUp(() async {
    db = AppDatabase.forTesting();
    final encryption = _MockFieldEncryptionService();
    when(() => encryption.encryptField(any())).thenAnswer(
      (call) async => 'encrypted:${call.positionalArguments.single}',
    );
    when(
      () => encryption.decryptField(any()),
    ).thenAnswer((call) async => call.positionalArguments.single as String);
    repository = TransactionRepositoryImpl(
      dao: TransactionDao(db),
      encryptionService: encryption,
    );
    outbox = FamilySyncOutboxRepositoryImpl(dao: FamilySyncOutboxDao(db));
    await _activateGroup(db, 'group-a');
  });

  tearDown(() => db.close());

  test(
    'business row and live operation survive service reconstruction',
    () async {
      final transaction = _transaction();

      expect(
        await repository.insertWithFamilySyncOutbox(
          transaction,
          operation: _live(transaction),
        ),
        isTrue,
      );

      final restartedOutbox = FamilySyncOutboxRepositoryImpl(
        dao: FamilySyncOutboxDao(db),
      );
      final pending = await restartedOutbox.getPendingForGroup('group-a');
      expect(await TransactionDao(db).findById(transaction.id), isNotNull);
      expect(pending, hasLength(1));
      expect(pending.single.operationId, 'outbox:group-a:bill:tx-1:100');
      expect(
        pending.single.operation['operationId'],
        pending.single.operationId,
      );
    },
  );

  test('outbox failure rolls the inserted business row back', () async {
    await db.customStatement('''
      CREATE TRIGGER fail_family_outbox
      BEFORE INSERT ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced outbox failure'); END
    ''');
    final transaction = _transaction();

    await expectLater(
      repository.insertWithFamilySyncOutbox(
        transaction,
        operation: _live(transaction),
      ),
      throwsA(anything),
    );

    expect(await TransactionDao(db).findById(transaction.id), isNull);
    expect(await outbox.getPendingForGroup('group-a'), isEmpty);
  });

  test('business-row failure leaves no outbox row', () async {
    final transaction = _transaction();
    await repository.insert(transaction);

    await expectLater(
      repository.insertWithFamilySyncOutbox(
        transaction,
        operation: _live(transaction),
      ),
      throwsA(anything),
    );

    expect(await outbox.getPendingForGroup('group-a'), isEmpty);
  });

  test('newer revision coalesces and same-revision tombstone wins', () async {
    final original = _transaction();
    await repository.insertWithFamilySyncOutbox(
      original,
      operation: _live(original),
    );
    final updated = _transaction(revision: 200);
    await repository.updateWithFamilySyncOutbox(
      updated,
      operation: TransactionSyncMapper.toUpdateOperation(
        updated,
        sourceBookId: updated.bookId,
        sourceBookName: 'Book',
        sourceBookType: 'remote_book:${updated.bookId}',
      ),
    );
    final tombstone = _transaction(
      revision: 200,
      isPrivate: true,
      visibility: FamilySyncVisibility.withdrawalPending,
    );
    await repository.updateWithFamilySyncOutbox(
      tombstone,
      operation: TransactionSyncMapper.toWithdrawalOperation(tombstone),
    );

    final pending = await outbox.getPendingForGroup('group-a');
    expect(pending, hasLength(1));
    expect(pending.single.revision, 200);
    expect(pending.single.isTombstone, isTrue);
    expect(pending.single.operation['data'], {
      'isDeleted': true,
      'syncRevision': 200,
      'syncOriginDeviceId': 'device-1',
    });
  });

  test(
    'no active group and local-only mutations never enter an outbox',
    () async {
      await db.customStatement("UPDATE groups SET status = 'inactive'");
      final public = _transaction();
      expect(
        await repository.insertWithFamilySyncOutbox(
          public,
          operation: _live(public),
        ),
        isFalse,
      );
      expect(await outbox.getPendingForGroup('group-a'), isEmpty);

      await db.customStatement("UPDATE groups SET status = 'active'");
      final private = _transaction(
        id: 'tx-private',
        isPrivate: true,
        visibility: FamilySyncVisibility.localOnly,
      );
      expect(await repository.insertWithFamilySyncOutbox(private), isFalse);
      expect(await outbox.getPendingForGroup('group-a'), isEmpty);
    },
  );

  test(
    'full-sync settlement cannot erase a newer or withdrawal revision',
    () async {
      final original = _transaction(revision: 200);
      await repository.insertWithFamilySyncOutbox(
        original,
        operation: _live(original),
      );

      await outbox.settleCovered(
        groupId: 'group-a',
        operations: [_live(_transaction(revision: 100))],
      );
      expect(await outbox.getPendingForGroup('group-a'), hasLength(1));

      final tombstone = _transaction(
        revision: 200,
        isPrivate: true,
        visibility: FamilySyncVisibility.withdrawalPending,
      );
      await repository.updateWithFamilySyncOutbox(
        tombstone,
        operation: TransactionSyncMapper.toWithdrawalOperation(tombstone),
      );
      await outbox.settleCovered(
        groupId: 'group-a',
        operations: [_live(_transaction(revision: 200))],
      );
      expect(
        (await outbox.getPendingForGroup('group-a')).single.isTombstone,
        isTrue,
      );
    },
  );

  test('private to public creates a live durable operation', () async {
    final private = _transaction(
      isPrivate: true,
      visibility: FamilySyncVisibility.localOnly,
    );
    await repository.insertWithFamilySyncOutbox(private);
    final shared = _transaction(revision: 200);

    expect(
      await repository.updateWithFamilySyncOutbox(
        shared,
        operation: TransactionSyncMapper.toUpdateOperation(
          shared,
          sourceBookId: shared.bookId,
          sourceBookName: 'Book',
          sourceBookType: 'remote_book:${shared.bookId}',
        ),
      ),
      isTrue,
    );

    final pending = await outbox.getPendingForGroup('group-a');
    expect(pending.single.operation['op'], 'update');
    expect(pending.single.isTombstone, isFalse);
  });

  test(
    'delete commits the soft-deleted row with a minimal tombstone',
    () async {
      final original = _transaction();
      await repository.insertWithFamilySyncOutbox(
        original,
        operation: _live(original),
      );
      final deleted = _transaction(
        revision: 200,
        isDeleted: true,
        visibility: FamilySyncVisibility.withdrawalPending,
      );

      await repository.updateWithFamilySyncOutbox(
        deleted,
        operation: TransactionSyncMapper.toDeleteOperation(
          deleted,
          sourceBookId: deleted.bookId,
          sourceBookName: 'Book',
          sourceBookType: 'remote_book:${deleted.bookId}',
        ),
      );

      expect((await TransactionDao(db).findById('tx-1'))!.isDeleted, isTrue);
      final pending = (await outbox.getPendingForGroup('group-a')).single;
      expect(pending.isTombstone, isTrue);
      expect(
        (pending.operation['data'] as Map<String, dynamic>).keys,
        unorderedEquals({'isDeleted', 'syncRevision', 'syncOriginDeviceId'}),
      );
    },
  );

  test(
    'outbox update failure rolls business update back to prior revision',
    () async {
      final original = _transaction();
      await repository.insertWithFamilySyncOutbox(
        original,
        operation: _live(original),
      );
      await db.customStatement('''
      CREATE TRIGGER fail_family_outbox_update
      BEFORE UPDATE ON family_sync_outbox
      BEGIN SELECT RAISE(ABORT, 'forced outbox update failure'); END
    ''');
      final updated = _transaction(revision: 200);

      await expectLater(
        repository.updateWithFamilySyncOutbox(
          updated,
          operation: TransactionSyncMapper.toUpdateOperation(
            updated,
            sourceBookId: updated.bookId,
            sourceBookName: 'Book',
            sourceBookType: 'remote_book:${updated.bookId}',
          ),
        ),
        throwsA(anything),
      );

      expect((await TransactionDao(db).findById('tx-1'))!.syncRevision, 100);
      expect((await outbox.getPendingForGroup('group-a')).single.revision, 100);
    },
  );

  test(
    'unsafe Phase 6 fixture rolls back instead of becoming a source',
    () async {
      final transaction = _transaction();
      final unsafe = {
        ..._live(transaction),
        'data': {'id': transaction.id, 'isPrivate': true, 'note': 'secret'},
      };

      await expectLater(
        repository.insertWithFamilySyncOutbox(transaction, operation: unsafe),
        throwsFormatException,
      );
      expect(await TransactionDao(db).findById(transaction.id), isNull);
      expect(await outbox.getPendingForGroup('group-a'), isEmpty);
    },
  );

  test('deactivation clears only the retired group outbox', () async {
    final transaction = _transaction();
    await repository.insertWithFamilySyncOutbox(
      transaction,
      operation: _live(transaction),
    );
    final groups = GroupRepositoryImpl(
      groupDao: GroupDao(db),
      memberDao: GroupMemberDao(db),
    );

    await groups.deactivateGroup('group-a');
    await groups.restoreActiveGroup(
      groupId: 'group-b',
      role: 'owner',
      groupKey: 'new-key',
      members: const [],
    );

    expect(await outbox.getPendingForGroup('group-a'), isEmpty);
    expect(await outbox.getPendingForGroup('group-b'), isEmpty);
  });
}
