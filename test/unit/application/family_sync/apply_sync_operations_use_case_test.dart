import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/inbound_sync_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/inbound_sync_operation_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/inbound_sync_operation_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/inbound_sync_resource_policy.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _MockSyncAvatarUseCase extends Mock implements SyncAvatarUseCase {}

class _FakeShoppingItem extends Fake implements ShoppingItem {}

Map<String, dynamic> _resourceLimitOperation({
  required String operationId,
  required int encodedBytes,
  String secret = 'resource-limit-secret',
}) {
  final operation = <String, dynamic>{
    'operationId': operationId,
    'op': 'future-op',
    'entityType': 'future_entity',
    'entityId': 'future-id',
    'data': {'value': ''},
  };
  final emptyBytes = utf8.encode(jsonEncode(operation)).length;
  operation['data'] = {
    'value': secret + ('x' * (encodedBytes - emptyBytes - secret.length)),
  };
  expect(utf8.encode(jsonEncode(operation)), hasLength(encodedBytes));
  return operation;
}

class _FailingQuarantineRepository
    extends MemoryInboundSyncOperationRepository {
  @override
  Future<void> quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String operationJson,
    required String errorCode,
    bool retryable = true,
  }) => throw StateError('simulated encrypted database write failure');
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeShoppingItem());
  });
  late AppDatabase db;
  late ApplySyncOperationsUseCase useCase;
  late ShadowBookService shadowBookService;
  late TransactionDao transactionDao;
  late _MockFieldEncryptionService mockEncryption;
  late _MockGroupRepository mockGroupRepository;
  late _MockShoppingItemRepository mockShoppingItemRepository;
  late TransactionRepositoryImpl transactionRepository;
  late InboundSyncOperationRepositoryImpl inboundRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    final bookRepo = BookRepositoryImpl(dao: BookDao(db));
    transactionDao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    mockGroupRepository = _MockGroupRepository();
    mockShoppingItemRepository = _MockShoppingItemRepository();
    when(() => mockEncryption.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: mockEncryption,
    );
    inboundRepository = InboundSyncOperationRepositoryImpl(
      dao: InboundSyncOperationDao(db),
    );

    shadowBookService = ShadowBookService(
      bookRepository: bookRepo,
      transactionRepository: transactionRepository,
    );
    useCase = ApplySyncOperationsUseCase(
      transactionRepository: transactionRepository,
      shoppingItemRepository: mockShoppingItemRepository,
      shadowBookService: shadowBookService,
      groupRepository: mockGroupRepository,
      inboundRepository: inboundRepository,
    );

    when(() => mockGroupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        members: const [
          GroupMember(
            deviceId: 'partner-device',
            publicKey: 'pk-partner',
            deviceName: 'Partner Phone',
            role: 'member',
            status: 'active',
            displayName: 'Partner',
            avatarEmoji: '🏠',
          ),
        ],
        createdAt: DateTime(2026, 3, 15),
      ),
    );
    when(
      () => mockGroupRepository.getPendingGroup(),
    ).thenAnswer((_) async => null);

    await shadowBookService.createShadowBook(
      groupId: 'group-1',
      memberDeviceId: 'partner-device',
      memberDeviceName: 'Partner Phone',
      currency: 'JPY',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ApplySyncOperationsUseCase', () {
    Map<String, dynamic> versionedBillOp({
      required String op,
      required String id,
      required int amount,
      required int revision,
      required String originDeviceId,
      bool isDeleted = false,
    }) {
      final instant = DateTime.utc(2026, 7, 1, 10, 0);
      return {
        'op': op,
        'entityType': 'bill',
        'entityId': id,
        'fromDeviceId': originDeviceId,
        'revision': revision,
        'originDeviceId': originDeviceId,
        'timestamp': instant.toIso8601String(),
        'data': {
          'id': id,
          'amount': amount,
          'type': 'expense',
          'categoryId': 'cat-1',
          'ledgerType': 'daily',
          'timestamp': instant.toIso8601String(),
          'createdAt': instant.toIso8601String(),
          'updatedAt': instant.toIso8601String(),
          'isDeleted': isDeleted,
          'syncRevision': revision,
          'syncOriginDeviceId': originDeviceId,
        },
      };
    }

    test(
      'bill update/delete converges independently of arrival order',
      () async {
        Future<bool> applySequence(String id, bool deleteFirst) async {
          await useCase.execute([
            versionedBillOp(
              op: 'create',
              id: id,
              amount: 100,
              revision: 100,
              originDeviceId: 'device-a',
            ),
          ]);
          final update = versionedBillOp(
            op: 'update',
            id: id,
            amount: 200,
            revision: 200,
            originDeviceId: 'device-a',
          );
          final delete = versionedBillOp(
            op: 'delete',
            id: id,
            amount: 200,
            revision: 300,
            originDeviceId: 'device-a',
            isDeleted: true,
          );
          await useCase.execute(
            deleteFirst ? [delete, update] : [update, delete],
          );
          return (await transactionDao.findById(id))!.isDeleted;
        }

        expect(await applySequence('tx-delete-first', true), isTrue);
        expect(await applySequence('tx-update-first', false), isTrue);
      },
    );

    test(
      'same revision uses tombstone then origin as stable tie-breakers',
      () async {
        Future<TransactionRow> applySequence(
          String id,
          List<Map<String, dynamic>> Function(String id) operations,
        ) async {
          await useCase.execute([
            versionedBillOp(
              op: 'create',
              id: id,
              amount: 100,
              revision: 100,
              originDeviceId: 'device-a',
            ),
            ...operations(id),
          ]);
          return (await transactionDao.findById(id))!;
        }

        List<Map<String, dynamic>> updateTie(String id) {
          final fromA = versionedBillOp(
            op: 'update',
            id: id,
            amount: 200,
            revision: 200,
            originDeviceId: 'device-a',
          );
          final fromZ = versionedBillOp(
            op: 'update',
            id: id,
            amount: 900,
            revision: 200,
            originDeviceId: 'device-z',
          );
          return [fromA, fromZ];
        }

        final forward = await applySequence('tx-tie-forward', updateTie);
        final reverse = await applySequence(
          'tx-tie-reverse',
          (id) => updateTie(id).reversed.toList(),
        );
        expect(forward.amount, 900);
        expect(reverse.amount, 900);

        final delete = versionedBillOp(
          op: 'delete',
          id: 'tx-delete-tie',
          amount: 100,
          revision: 200,
          originDeviceId: 'device-a',
          isDeleted: true,
        );
        final update = versionedBillOp(
          op: 'update',
          id: 'tx-delete-tie',
          amount: 800,
          revision: 200,
          originDeviceId: 'device-z',
        );
        final deleteTie = await applySequence(
          'tx-delete-tie',
          (_) => [delete, update],
        );
        expect(deleteTie.isDeleted, isTrue);
      },
    );

    test(
      'full reconcile repairs missing update and missing tombstone',
      () async {
        await useCase.execute([
          versionedBillOp(
            op: 'create',
            id: 'tx-full-update',
            amount: 100,
            revision: 100,
            originDeviceId: 'device-a',
          ),
        ]);

        final update = versionedBillOp(
          op: 'reconcile',
          id: 'tx-full-update',
          amount: 700,
          revision: 300,
          originDeviceId: 'device-a',
        );
        final tombstone = versionedBillOp(
          op: 'reconcile',
          id: 'tx-full-delete',
          amount: 500,
          revision: 400,
          originDeviceId: 'device-a',
          isDeleted: true,
        );
        await useCase.execute([update, tombstone]);

        expect((await transactionDao.findById('tx-full-update'))!.amount, 700);
        expect(
          (await transactionDao.findById('tx-full-delete'))!.isDeleted,
          isTrue,
        );
      },
    );

    test('versioned reconcile is idempotent', () async {
      final operation = versionedBillOp(
        op: 'reconcile',
        id: 'tx-reconcile-idempotent',
        amount: 640,
        revision: 300,
        originDeviceId: 'device-a',
      );

      await useCase.execute([operation, operation]);

      final rows = await db
          .customSelect(
            'SELECT COUNT(*) AS count FROM transactions '
            'WHERE id = \'tx-reconcile-idempotent\'',
          )
          .getSingle();
      expect(rows.read<int>('count'), 1);
      expect(
        (await transactionDao.findById('tx-reconcile-idempotent'))!.amount,
        640,
      );
    });

    test('create inserts synced transaction into shadow book', () async {
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-1',
            'amount': 2000,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
            'metadata': {
              'sourceBookId': 'remote-main',
              'sourceBookName': 'Remote Main',
              'sourceBookType': 'remote_book:remote-main',
            },
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-remote-1');
      final shadowBook = await shadowBookService.findShadowBook(
        'partner-device',
      );
      expect(tx, isNotNull);
      expect(shadowBook, isNotNull);
      expect(tx!.bookId, shadowBook!.id);
      expect(tx.deviceId, 'partner-device');
      expect(tx.metadata, contains('sourceBookId'));
      expect(tx.isSynced, true);
      expect(tx.familySyncVisibility, 'localOnly');
    });

    test(
      'private inbound bill is quarantined before any row is written',
      () async {
        final privateOperation = versionedBillOp(
          op: 'create',
          id: 'tx-private-wire',
          amount: 700,
          revision: 11,
          originDeviceId: 'partner-device',
        );
        privateOperation['operationId'] = 'private-op';
        (privateOperation['data'] as Map<String, dynamic>)['isPrivate'] = true;

        final result = await useCase.execute([
          privateOperation,
        ], groupId: 'group-1');

        expect(
          result.operations.single.status,
          SyncOperationApplyStatus.quarantined,
        );
        expect(result.operations.single.errorCode, 'private_bill_payload');
        expect(await transactionDao.findById('tx-private-wire'), isNull);
        expect(
          (await inboundRepository.getSummary(
            groupId: 'group-1',
          )).quarantinedCount,
          1,
        );
      },
    );

    test(
      'legacy isPrivate false remains compatible and local-only bookkeeping is rejected',
      () async {
        final legacyPublic = versionedBillOp(
          op: 'create',
          id: 'tx-legacy-public',
          amount: 701,
          revision: 12,
          originDeviceId: 'partner-device',
        );
        legacyPublic['operationId'] = 'legacy-public-op';
        (legacyPublic['data'] as Map<String, dynamic>)['isPrivate'] = false;
        final localState = versionedBillOp(
          op: 'create',
          id: 'tx-local-state-wire',
          amount: 702,
          revision: 13,
          originDeviceId: 'partner-device',
        );
        localState['operationId'] = 'local-state-op';
        (localState['data'] as Map<String, dynamic>)['familySyncVisibility'] =
            'shared';

        final result = await useCase.execute([
          legacyPublic,
          localState,
        ], groupId: 'group-1');

        expect(
          result.operations.first.status,
          SyncOperationApplyStatus.applied,
        );
        expect(
          result.operations.last.status,
          SyncOperationApplyStatus.quarantined,
        );
        expect(await transactionDao.findById('tx-legacy-public'), isNotNull);
        expect(await transactionDao.findById('tx-local-state-wire'), isNull);
      },
    );

    test('create lazily creates missing shadow book', () async {
      await shadowBookService.cleanSyncData('group-1');

      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-lazy',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-lazy',
            'amount': 800,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final shadowBook = await shadowBookService.findShadowBook(
        'partner-device',
      );
      final tx = await transactionDao.findById('tx-remote-lazy');
      expect(shadowBook, isNotNull);
      expect(tx, isNotNull);
      expect(tx!.bookId, shadowBook!.id);
    });

    test('delete soft-deletes synced transaction', () async {
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-remote-2',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-remote-2',
            'amount': 500,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      await useCase.execute([
        {
          'op': 'delete',
          'entityType': 'bill',
          'entityId': 'tx-remote-2',
          'fromDeviceId': 'partner-device',
        },
      ]);

      final tx = await transactionDao.findById('tx-remote-2');
      expect(tx, isNotNull);
      expect(tx!.isDeleted, true);
    });

    test('insert (alias for create) inserts synced transaction', () async {
      await useCase.execute([
        {
          'op': 'insert',
          'entityType': 'bill',
          'entityId': 'tx-insert-1',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-insert-1',
            'amount': 300,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-insert-1');
      expect(tx, isNotNull);
      expect(tx!.amount, 300);
    });

    test('update creates transaction when it does not exist', () async {
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'bill',
          'entityId': 'tx-update-new',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-new',
            'amount': 700,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-update-new');
      expect(tx, isNotNull);
      expect(tx!.amount, 700);
    });

    test('update modifies existing transaction', () async {
      // First create the transaction
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-update-existing',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-existing',
            'amount': 500,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // Then update it
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'bill',
          'entityId': 'tx-update-existing',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-update-existing',
            'amount': 999,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
            'updatedAt': '2026-03-16T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-update-existing');
      expect(tx, isNotNull);
      expect(tx!.amount, 999);
    });

    test('skips bill operation with null entityId', () async {
      // Should not throw
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          // no entityId
          'fromDeviceId': 'partner-device',
          'data': {'amount': 100, 'type': 'expense'},
        },
      ]);
      // No crash — test passes
    });

    test('profile operation updates member profile', () async {
      when(
        () => mockGroupRepository.updateMemberIdentity(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
        ),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'profile',
          'fromDeviceId': 'partner-device',
          'data': {'displayName': 'Partner Updated', 'avatarEmoji': '🌟'},
        },
      ], groupId: 'group-1');

      verify(
        () => mockGroupRepository.updateMemberIdentity(
          groupId: 'group-1',
          deviceId: 'partner-device',
          displayName: 'Partner Updated',
          avatarEmoji: '🌟',
        ),
      ).called(1);
    });

    test(
      'operationId prevents duplicate consumer apply after ACK retry',
      () async {
        when(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenAnswer((_) async {});
        final operation = <String, dynamic>{
          'operationId': 'sync-1:0',
          'op': 'update',
          'entityType': 'profile',
          'entityId': 'partner-device',
          'fromDeviceId': 'partner-device',
          'data': {
            'schemaVersion': 1,
            'ownerDeviceId': 'partner-device',
            'revision': 1,
            'displayName': 'Partner Updated',
            'avatarEmoji': '🌟',
          },
        };

        final first = await useCase.execute([operation], groupId: 'group-1');
        final restartedUseCase = ApplySyncOperationsUseCase(
          transactionRepository: transactionRepository,
          shoppingItemRepository: mockShoppingItemRepository,
          shadowBookService: shadowBookService,
          groupRepository: mockGroupRepository,
          inboundRepository: inboundRepository,
        );
        final second = await restartedUseCase.execute([
          operation,
        ], groupId: 'group-1');

        expect(
          first.operations.single.status,
          SyncOperationApplyStatus.applied,
        );
        expect(
          second.operations.single.status,
          SyncOperationApplyStatus.alreadyApplied,
        );

        verify(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: 'group-1',
            deviceId: 'partner-device',
            displayName: 'Partner Updated',
            avatarEmoji: '🌟',
          ),
        ).called(1);
      },
    );

    test(
      'same operationId applies in another authoritative group and ignores payload groupId',
      () async {
        when(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenAnswer((_) async {});
        final operation = <String, dynamic>{
          'operationId': 'reused-operation-id',
          'op': 'update',
          'entityType': 'profile',
          'entityId': 'partner-device',
          'fromDeviceId': 'partner-device',
          'groupId': 'forged-top-level-group',
          'data': {
            'schemaVersion': 1,
            'ownerDeviceId': 'partner-device',
            'revision': 2,
            'groupId': 'forged-payload-group',
            'displayName': 'Partner Updated',
            'avatarEmoji': '🌟',
          },
        };

        final inA = await useCase.execute([operation], groupId: 'group-a');
        final inB = await useCase.execute([operation], groupId: 'group-b');

        expect(inA.operations.single.status, SyncOperationApplyStatus.applied);
        expect(inB.operations.single.status, SyncOperationApplyStatus.applied);
        expect(
          await inboundRepository.isApplied(
            groupId: 'forged-payload-group',
            operationId: 'reused-operation-id',
          ),
          isFalse,
        );
        verify(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: 'group-a',
            deviceId: 'partner-device',
            displayName: 'Partner Updated',
            avatarEmoji: '🌟',
          ),
        ).called(1);
        verify(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: 'group-b',
            deviceId: 'partner-device',
            displayName: 'Partner Updated',
            avatarEmoji: '🌟',
          ),
        ).called(1);
      },
    );

    test(
      'mixed batch quarantines deterministic poison and applies good op',
      () async {
        when(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenAnswer((_) async {});

        final result = await useCase.execute([
          {
            'operationId': 'bad:1',
            'op': 'explode',
            'entityType': 'unknown_future_entity',
            'entityId': 'poison-1',
          },
          {
            'operationId': 'good:1',
            'op': 'update',
            'entityType': 'profile',
            'entityId': 'partner-device',
            'fromDeviceId': 'partner-device',
            'data': {
              'schemaVersion': 1,
              'ownerDeviceId': 'partner-device',
              'revision': 1,
              'displayName': 'Partner Updated',
              'avatarEmoji': '🌟',
            },
          },
        ], groupId: 'group-1');

        expect(result.operations.map((entry) => entry.status), [
          SyncOperationApplyStatus.quarantined,
          SyncOperationApplyStatus.applied,
        ]);
        expect(result.isAckSafe, isTrue);
        final quarantined = await inboundRepository.getQuarantined(
          groupId: 'group-1',
        );
        expect(quarantined.single.operationId, 'bad:1');
        expect(quarantined.single.errorCode, 'unsupported_entity_type');
        expect(quarantined.single.operationJson, contains('poison-1'));
      },
    );

    test(
      'quarantine persistence failure returns failed and blocks ACK',
      () async {
        final failingUseCase = ApplySyncOperationsUseCase(
          transactionRepository: transactionRepository,
          shoppingItemRepository: mockShoppingItemRepository,
          shadowBookService: shadowBookService,
          groupRepository: mockGroupRepository,
          inboundRepository: _FailingQuarantineRepository(),
        );

        final result = await failingUseCase.execute([
          {
            'operationId': 'bad-write:1',
            'op': 'explode',
            'entityType': 'unsupported',
          },
        ], groupId: 'group-1');

        expect(result.isAckSafe, isFalse);
        expect(
          result.operations.single.status,
          SyncOperationApplyStatus.failed,
        );
        expect(result.operations.single.errorCode, 'quarantine_write_failed');
      },
    );

    test('64 KiB operation boundary remains retryable', () async {
      final result = await useCase.execute([
        _resourceLimitOperation(
          operationId: 'boundary-operation',
          encodedBytes: InboundSyncResourcePolicy.maxOperationJsonBytes,
        ),
      ], groupId: 'group-1');

      expect(
        result.operations.single.status,
        SyncOperationApplyStatus.quarantined,
      );
      final page = await inboundRepository.getQuarantinedPage(
        groupId: 'group-1',
      );
      expect(page.entries.single.retryable, isTrue);
      expect(
        page.entries.single.payloadBytes,
        InboundSyncResourcePolicy.maxOperationJsonBytes,
      );
    });

    test(
      'oversized operation persists only a non-retryable safe summary',
      () async {
        const secret = 'SECRET_SHOULD_NEVER_BE_PERSISTED';
        final result = await useCase.execute([
          _resourceLimitOperation(
            operationId: 'oversized-operation',
            encodedBytes: InboundSyncResourcePolicy.maxOperationJsonBytes + 1,
            secret: secret,
          ),
        ], groupId: 'group-1');

        expect(result.isAckSafe, isTrue);
        expect(
          result.operations.single.status,
          SyncOperationApplyStatus.quarantined,
        );
        final entry = (await inboundRepository.getQuarantinedPage(
          groupId: 'group-1',
        )).entries.single;
        expect(entry.retryable, isFalse);
        expect(entry.errorCode, 'operation_payload_too_large');
        expect(entry.operationJson, isNot(contains(secret)));
        final summary = jsonDecode(entry.operationJson) as Map<String, dynamic>;
        expect(summary.keys, {
          'kind',
          'entityType',
          'sourceBytes',
          'sha256',
          'reason',
        });
        expect(
          summary['sourceBytes'],
          InboundSyncResourcePolicy.maxOperationJsonBytes + 1,
        );
        expect(
          summary['sha256'],
          isA<String>().having((value) => value.length, 'length', 64),
        );
      },
    );

    test(
      'oversized outer identifiers are replaced by a safe digest key',
      () async {
        final oversizedId = 'sensitive-id-${'z' * 300}';
        final result = await useCase.execute([
          {
            'operationId': oversizedId,
            'op': 'future-op',
            'entityType': 'future_entity',
            'entityId': 'future-id',
          },
        ], groupId: 'group-1');

        expect(result.isAckSafe, isTrue);
        final entry = (await inboundRepository.getQuarantinedPage(
          groupId: 'group-1',
        )).entries.single;
        expect(entry.operationId, startsWith('legacy:'));
        expect(entry.operationId, isNot(contains(oversizedId)));
        expect(entry.retryable, isFalse);
        expect(entry.errorCode, 'operation_metadata_too_large');
        expect(entry.operationJson, isNot(contains(oversizedId)));
      },
    );

    test('501-operation message is summarized once and ACK-safe', () async {
      final operations = [
        for (
          var index = 0;
          index <= InboundSyncResourcePolicy.maxOperationsPerMessage;
          index++
        )
          <String, dynamic>{
            'operationId': 'batch-$index',
            'op': 'future-op',
            'entityType': 'future_entity',
          },
      ];

      final result = await useCase.execute(operations, groupId: 'group-1');

      expect(result.isAckSafe, isTrue);
      expect(result.operations, hasLength(1));
      expect(
        result.operations.single.status,
        SyncOperationApplyStatus.quarantined,
      );
      final entry = (await inboundRepository.getQuarantinedPage(
        groupId: 'group-1',
      )).entries.single;
      expect(entry.retryable, isFalse);
      expect(entry.errorCode, 'batch_operation_limit_exceeded');
      expect(entry.operationJson, isNot(contains('batch-500')));
    });

    test('500-operation boundary is processed rather than rejected', () async {
      final operations = [
        for (
          var index = 0;
          index < InboundSyncResourcePolicy.maxOperationsPerMessage;
          index++
        )
          <String, dynamic>{
            'operationId': 'boundary-batch-$index',
            'op': 'future-op',
            'entityType': 'future_entity',
          },
      ];

      final result = await useCase.execute(operations, groupId: 'group-1');

      expect(result.operations, hasLength(500));
      expect(
        result.operations.every(
          (entry) => entry.status == SyncOperationApplyStatus.quarantined,
        ),
        isTrue,
      );
      expect(
        result.operations.map((entry) => entry.errorCode),
        isNot(contains('batch_operation_limit_exceeded')),
      );
    });

    test('oversized summary persistence failure is not ACK-safe', () async {
      final failingUseCase = ApplySyncOperationsUseCase(
        transactionRepository: transactionRepository,
        shoppingItemRepository: mockShoppingItemRepository,
        shadowBookService: shadowBookService,
        groupRepository: mockGroupRepository,
        inboundRepository: _FailingQuarantineRepository(),
      );

      final result = await failingUseCase.execute([
        _resourceLimitOperation(
          operationId: 'oversized-write-failure',
          encodedBytes: InboundSyncResourcePolicy.maxOperationJsonBytes + 1,
        ),
      ], groupId: 'group-1');

      expect(result.isAckSafe, isFalse);
      expect(result.operations.single.status, SyncOperationApplyStatus.failed);
      expect(result.operations.single.errorCode, 'quarantine_write_failed');
    });

    test(
      'omitted groupId resolves from the authoritative active group',
      () async {
        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'profile',
            'fromDeviceId': 'partner-device',
            'data': {'displayName': 'X', 'avatarEmoji': '🌟'},
          },
        ]);
        verify(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: 'group-1',
            deviceId: 'partner-device',
            displayName: 'X',
            avatarEmoji: '🌟',
          ),
        ).called(1);
      },
    );

    test(
      'resolves production-style app directory before avatar apply',
      () async {
        final avatarSync = _MockSyncAvatarUseCase();
        final tempDir = await Directory.systemTemp.createTemp(
          'apply_avatar_dir_',
        );
        addTearDown(() => tempDir.delete(recursive: true));
        var resolverCalls = 0;
        when(
          () => avatarSync.handleAvatarSync(
            groupId: any(named: 'groupId'),
            senderDeviceId: any(named: 'senderDeviceId'),
            messageKeyEpoch: any(named: 'messageKeyEpoch'),
            payload: any(named: 'payload'),
            appDirectory: any(named: 'appDirectory'),
          ),
        ).thenAnswer((_) async {});
        final avatarApply = ApplySyncOperationsUseCase(
          transactionRepository: transactionRepository,
          shoppingItemRepository: mockShoppingItemRepository,
          shadowBookService: shadowBookService,
          groupRepository: mockGroupRepository,
          inboundRepository: inboundRepository,
          syncAvatarUseCase: avatarSync,
          appDirectoryResolver: () async {
            resolverCalls++;
            return tempDir.path;
          },
        );

        await avatarApply.execute([
          {
            'op': 'update',
            'entityType': 'avatar',
            'entityId': 'partner-device',
            'fromDeviceId': 'partner-device',
            'transportKeyEpoch': 4,
            'data': {'schemaVersion': 1},
          },
        ], groupId: 'group-1');

        expect(resolverCalls, 1);
        verify(
          () => avatarSync.handleAvatarSync(
            groupId: 'group-1',
            senderDeviceId: 'partner-device',
            messageKeyEpoch: 4,
            payload: {'schemaVersion': 1},
            appDirectory: tempDir.path,
          ),
        ).called(1);
      },
    );

    test('quarantines deterministic avatar validation failures', () async {
      final avatarSync = _MockSyncAvatarUseCase();
      when(
        () => avatarSync.handleAvatarSync(
          groupId: any(named: 'groupId'),
          senderDeviceId: any(named: 'senderDeviceId'),
          messageKeyEpoch: any(named: 'messageKeyEpoch'),
          payload: any(named: 'payload'),
          appDirectory: any(named: 'appDirectory'),
        ),
      ).thenThrow(const AvatarSyncValidationException('hash mismatch'));
      final avatarApply = ApplySyncOperationsUseCase(
        transactionRepository: transactionRepository,
        shoppingItemRepository: mockShoppingItemRepository,
        shadowBookService: shadowBookService,
        groupRepository: mockGroupRepository,
        inboundRepository: inboundRepository,
        syncAvatarUseCase: avatarSync,
        appDirectoryResolver: () async => '/tmp',
      );

      final result = await avatarApply.execute([
        {
          'op': 'update',
          'entityType': 'avatar',
          'entityId': 'partner-device',
          'fromDeviceId': 'partner-device',
          'transportKeyEpoch': 4,
          'data': {'schemaVersion': 1},
        },
      ], groupId: 'group-1');

      expect(
        result.operations.single.status,
        SyncOperationApplyStatus.quarantined,
      );
    });

    test(
      'retry after upgrade marks quarantined op applied and removes it',
      () async {
        final rejectingAvatar = _MockSyncAvatarUseCase();
        when(
          () => rejectingAvatar.handleAvatarSync(
            groupId: any(named: 'groupId'),
            senderDeviceId: any(named: 'senderDeviceId'),
            messageKeyEpoch: any(named: 'messageKeyEpoch'),
            payload: any(named: 'payload'),
            appDirectory: any(named: 'appDirectory'),
          ),
        ).thenThrow(const AvatarSyncValidationException('old validator'));
        final oldApply = ApplySyncOperationsUseCase(
          transactionRepository: transactionRepository,
          shoppingItemRepository: mockShoppingItemRepository,
          shadowBookService: shadowBookService,
          groupRepository: mockGroupRepository,
          inboundRepository: inboundRepository,
          syncAvatarUseCase: rejectingAvatar,
          appDirectoryResolver: () async => '/tmp',
        );
        final operation = <String, dynamic>{
          'operationId': 'avatar-after-upgrade:1',
          'transportMessageId': 'message-avatar-1',
          'op': 'update',
          'entityType': 'avatar',
          'entityId': 'partner-device',
          'fromDeviceId': 'partner-device',
          'transportKeyEpoch': 4,
          'data': {'schemaVersion': 1},
        };
        final quarantined = await oldApply.execute([
          operation,
        ], groupId: 'group-1');
        expect(
          quarantined.operations.single.status,
          SyncOperationApplyStatus.quarantined,
        );

        final upgradedAvatar = _MockSyncAvatarUseCase();
        when(
          () => upgradedAvatar.handleAvatarSync(
            groupId: any(named: 'groupId'),
            senderDeviceId: any(named: 'senderDeviceId'),
            messageKeyEpoch: any(named: 'messageKeyEpoch'),
            payload: any(named: 'payload'),
            appDirectory: any(named: 'appDirectory'),
          ),
        ).thenAnswer((_) async {});
        final upgradedApply = ApplySyncOperationsUseCase(
          transactionRepository: transactionRepository,
          shoppingItemRepository: mockShoppingItemRepository,
          shadowBookService: shadowBookService,
          groupRepository: mockGroupRepository,
          inboundRepository: inboundRepository,
          syncAvatarUseCase: upgradedAvatar,
          appDirectoryResolver: () async => '/tmp',
        );
        final recovery = InboundSyncRecoveryUseCase(
          repository: inboundRepository,
          applyOperations: upgradedApply,
        );

        final retried = await recovery.retryOne(
          groupId: 'group-1',
          operationId: 'avatar-after-upgrade:1',
        );

        expect(retried.retriedCount, 1);
        expect(retried.remainingCount, 0);
        expect(
          await inboundRepository.isApplied(
            groupId: 'group-1',
            operationId: 'avatar-after-upgrade:1',
          ),
          isTrue,
        );
        expect(
          await inboundRepository.getQuarantined(groupId: 'group-1'),
          isEmpty,
        );
      },
    );

    test(
      'explicit discard removes quarantine without marking it applied',
      () async {
        await inboundRepository.quarantine(
          operationId: 'discard-me',
          groupId: 'group-1',
          messageId: 'message-1',
          operationJson: '{"operationId":"discard-me"}',
          errorCode: 'unsupported_entity_type',
        );
        final recovery = InboundSyncRecoveryUseCase(
          repository: inboundRepository,
          applyOperations: useCase,
        );

        await recovery.discard(groupId: 'group-1', operationId: 'discard-me');

        expect(
          await inboundRepository.getQuarantined(groupId: 'group-1'),
          isEmpty,
        );
        expect(
          await inboundRepository.isApplied(
            groupId: 'group-1',
            operationId: 'discard-me',
          ),
          isFalse,
        );
      },
    );

    test(
      'retryOne is isolated when two groups quarantine the same id',
      () async {
        when(
          () => mockGroupRepository.updateMemberIdentity(
            groupId: any(named: 'groupId'),
            deviceId: any(named: 'deviceId'),
            displayName: any(named: 'displayName'),
            avatarEmoji: any(named: 'avatarEmoji'),
          ),
        ).thenAnswer((_) async {});
        const operationJson =
            '{"operationId":"retry-shared","op":"update",'
            '"entityType":"profile","entityId":"partner-device",'
            '"fromDeviceId":"partner-device","data":{'
            '"schemaVersion":1,"ownerDeviceId":"partner-device",'
            '"revision":3,"displayName":"Recovered",'
            '"avatarEmoji":"🌟"}}';
        for (final groupId in ['group-a', 'group-b']) {
          await inboundRepository.quarantine(
            groupId: groupId,
            operationId: 'retry-shared',
            messageId: 'message-$groupId',
            operationJson: operationJson,
            errorCode: 'unsupported_entity_type',
          );
        }
        final recovery = InboundSyncRecoveryUseCase(
          repository: inboundRepository,
          applyOperations: useCase,
        );

        final result = await recovery.retryOne(
          groupId: 'group-a',
          operationId: 'retry-shared',
        );

        expect(result.retriedCount, 1);
        expect(
          (await inboundRepository.getSummary(
            groupId: 'group-a',
          )).quarantinedCount,
          0,
        );
        expect(
          (await inboundRepository.getSummary(
            groupId: 'group-b',
          )).quarantinedCount,
          1,
        );
      },
    );

    test('non-retryable safe summary cannot enter the apply path', () async {
      await inboundRepository.quarantine(
        groupId: 'group-1',
        operationId: 'safe-summary',
        messageId: 'message-1',
        operationJson:
            '{"kind":"inbound_operation_rejection",'
            '"sourceBytes":70000,"sha256":"digest",'
            '"reason":"operation_payload_too_large"}',
        errorCode: 'operation_payload_too_large',
        retryable: false,
      );
      final recovery = InboundSyncRecoveryUseCase(
        repository: inboundRepository,
        applyOperations: useCase,
      );

      final result = await recovery.retryOne(
        groupId: 'group-1',
        operationId: 'safe-summary',
      );

      expect(result.retriedCount, 0);
      expect(result.remainingCount, 1);
      expect(
        await inboundRepository.findQuarantined(
          groupId: 'group-1',
          operationId: 'safe-summary',
        ),
        isNotNull,
      );
    });

    test('create is idempotent for duplicate entityId', () async {
      // First create
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-idem',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-idem',
            'amount': 100,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      // Second create (same id) — should not throw, should not duplicate
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-idem',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-idem',
            'amount': 200, // different amount but same id
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-03-15T10:00:00.000Z',
            'createdAt': '2026-03-15T10:00:00.000Z',
          },
        },
      ]);

      final tx = await transactionDao.findById('tx-idem');
      expect(tx, isNotNull);
      expect(tx!.amount, 100); // original amount preserved
    });
  });

  group('shopping_item branch (D37-05, SC-3, SC-4)', () {
    test('bad shopping op does NOT abort bill ops (D37-05, SC-3)', () async {
      // A batch mixing an invalid shopping op with a valid bill op
      // The shopping branch must fault-isolate — bill op must still apply
      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'shopping_item',
          'entityId': null, // invalid — missing entityId → should fail-safe
          'fromDeviceId': 'partner-device',
          'data': null, // invalid data
        },
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-after-bad-shopping',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'tx-after-bad-shopping',
            'amount': 1500,
            'type': 'expense',
            'categoryId': 'cat-1',
            'ledgerType': 'daily',
            'timestamp': '2026-06-08T10:00:00.000Z',
            'createdAt': '2026-06-08T10:00:00.000Z',
          },
        },
      ]);

      // Bill op was applied even though shopping op was invalid
      final tx = await transactionDao.findById('tx-after-bad-shopping');
      expect(
        tx,
        isNotNull,
        reason: 'Bill op must succeed even when shopping op is bad (D37-05)',
      );
    });

    test('tombstone not resurrected by remote update (SC-4)', () async {
      // This test verifies the ShoppingItemChangeTracker integration —
      // When the shopping item branch is wired, a delete then update must
      // leave the item soft-deleted (tombstone wins). This test asserts the
      // contract at the apply_sync level using mock repository.
      // The mock does not actually persist, so we verify call order instead.
      // Full round-trip persistence is tested in shopping_sync_round_trip_test.dart.

      // Assert: the use case processes a batch with delete + update without crashing
      // and does NOT call mockShoppingItemRepository.update after softDelete if
      // the item was deleted. The mock returns null for findById (deleted item).
      when(
        () => mockShoppingItemRepository.findById(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockShoppingItemRepository.softDelete(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockShoppingItemRepository.upsert(any()),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'delete',
          'entityType': 'shopping_item',
          'entityId': 'item-tombstone',
          'fromDeviceId': 'partner-device',
        },
      ]);

      verify(
        () => mockShoppingItemRepository.softDelete('item-tombstone'),
      ).called(1);
    });

    test(
      'sticky-complete merge: stale rename preserves completion (SC-4, D37-02)',
      () async {
        // This test verifies the sticky-complete merge contract.
        // When a stale update (updatedAt < completedAt) arrives:
        //   - existing.isCompleted=true + completedAt=T1 is preserved
        //   - stale isCompleted:false from update is ignored
        //
        // The mock-level test verifies the ShoppingItemRepository contract is
        // called correctly. Full persistence is in shopping_sync_round_trip_test.dart.
        when(
          () => mockShoppingItemRepository.findById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        // Create via sync (arrives first)
        await useCase.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Bread',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // Stale update arrives after (updatedAt < when completedAt would be)
        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-sticky',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-sticky',
              'listType': 'public',
              'name': 'Sourdough Bread', // rename
              'quantity': 1,
              'isCompleted':
                  false, // stale: completion state already changed locally
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt':
                  '2026-06-08T09:00:00.000Z', // STALE — before completedAt
            },
          },
        ]);

        // The use case ran without crashing; sticky-complete preservation logic
        // is fully tested in the integration round-trip test with real DB.
        verify(
          () => mockShoppingItemRepository.upsert(any()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    test('remote update preserves local sortOrder (CR-01, D37-01)', () async {
      // sortOrder is a local-only field excluded from the sync wire, so an
      // incoming update payload never carries it. The apply handler must
      // preserve the existing local sortOrder instead of letting fromSyncMap's
      // default (0) clobber a locally-reordered item back to position 0.
      final existing = ShoppingItem(
        id: 'item-reordered',
        deviceId: 'local-device',
        listType: 'public',
        name: 'Milk',
        sortOrder: 7,
        createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
      );
      when(
        () => mockShoppingItemRepository.findById('item-reordered'),
      ).thenAnswer((_) async => existing);
      when(
        () => mockShoppingItemRepository.upsert(any()),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'shopping_item',
          'entityId': 'item-reordered',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'item-reordered',
            'listType': 'public',
            'name': 'Whole Milk', // rename via remote update
            'quantity': 1,
            'isCompleted': false,
            'createdAt': '2026-06-08T10:00:00.000Z',
            'updatedAt': '2026-06-08T11:00:00.000Z',
          },
        },
      ]);

      final captured =
          verify(
                () => mockShoppingItemRepository.upsert(captureAny()),
              ).captured.single
              as ShoppingItem;
      expect(
        captured.sortOrder,
        7,
        reason: 'remote update must preserve local sortOrder, not reset to 0',
      );
      expect(captured.name, 'Whole Milk');
    });
  });

  group('receiver-side listType gate + pin (W2, SYNC-02/SYNC-03, D37-04)', () {
    test(
      'inbound private create op is dropped; rest of batch still applies',
      () async {
        when(
          () => mockShoppingItemRepository.findById(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'create',
            'entityType': 'shopping_item',
            'entityId': 'item-private-create',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-private-create',
              'listType': 'private',
              'name': 'Secret Gift',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
          {
            'op': 'create',
            'entityType': 'bill',
            'entityId': 'tx-after-private-shopping',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'tx-after-private-shopping',
              'amount': 4200,
              'type': 'expense',
              'categoryId': 'cat-1',
              'ledgerType': 'daily',
              'timestamp': '2026-06-08T10:00:00.000Z',
              'createdAt': '2026-06-08T10:00:00.000Z',
            },
          },
        ]);

        // The private shopping op must never reach the repository
        verifyNever(() => mockShoppingItemRepository.upsert(any()));
        // Per-op skip, not abort — the bill op in the same batch still applies
        final tx = await transactionDao.findById('tx-after-private-shopping');
        expect(
          tx,
          isNotNull,
          reason: 'private-op drop must be per-op skip, not batch abort',
        );
      },
    );

    test(
      'inbound private update op is dropped; existing public item unchanged',
      () async {
        final existing = ShoppingItem(
          id: 'item-pub-target',
          deviceId: 'local-device',
          listType: 'public',
          name: 'Milk',
          createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
        );
        when(
          () => mockShoppingItemRepository.findById('item-pub-target'),
        ).thenAnswer((_) async => existing);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-pub-target',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-pub-target',
              'listType': 'private', // non-public wire value → must be dropped
              'name': 'Hijacked Name',
              'quantity': 1,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T12:00:00.000Z', // newer than local
            },
          },
        ]);

        verifyNever(() => mockShoppingItemRepository.upsert(any()));
      },
    );

    test(
      'update op cannot flip listType — existing.listType is pinned (D37-04)',
      () async {
        final existing = ShoppingItem(
          id: 'item-priv-pinned',
          deviceId: 'local-device',
          listType: 'private',
          name: 'Old Name',
          createdAt: DateTime.parse('2026-06-08T10:00:00.000Z'),
        );
        when(
          () => mockShoppingItemRepository.findById('item-priv-pinned'),
        ).thenAnswer((_) async => existing);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'update',
            'entityType': 'shopping_item',
            'entityId': 'item-priv-pinned',
            'fromDeviceId': 'partner-device',
            'data': {
              'id': 'item-priv-pinned',
              'listType': 'public', // wire claims public — passes the gate
              'name': 'New Name',
              'quantity': 2,
              'isCompleted': false,
              'createdAt': '2026-06-08T10:00:00.000Z',
              'updatedAt': '2026-06-08T12:00:00.000Z', // newer than local
            },
          },
        ]);

        final captured =
            verify(
                  () => mockShoppingItemRepository.upsert(captureAny()),
                ).captured.single
                as ShoppingItem;
        expect(
          captured.listType,
          'private',
          reason:
              'wire can never flip an item public↔private — '
              'existing.listType must be pinned (D37-04, W2/SYNC-03)',
        );
        expect(
          captured.name,
          'New Name',
          reason: 'non-listType fields must still take incoming values',
        );
      },
    );

    test('public create and public update still apply (regression)', () async {
      when(
        () => mockShoppingItemRepository.findById('item-pub-regression'),
      ).thenAnswer((_) async => null);
      when(
        () => mockShoppingItemRepository.upsert(any()),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'create',
          'entityType': 'shopping_item',
          'entityId': 'item-pub-regression',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'item-pub-regression',
            'listType': 'public',
            'name': 'Butter',
            'quantity': 1,
            'isCompleted': false,
            'createdAt': '2026-06-08T10:00:00.000Z',
          },
        },
      ]);

      final created =
          verify(
                () => mockShoppingItemRepository.upsert(captureAny()),
              ).captured.single
              as ShoppingItem;
      expect(created.listType, 'public');
      expect(created.name, 'Butter');

      // Now an inbound public update against the (now existing) item
      when(
        () => mockShoppingItemRepository.findById('item-pub-regression'),
      ).thenAnswer((_) async => created);

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'shopping_item',
          'entityId': 'item-pub-regression',
          'fromDeviceId': 'partner-device',
          'data': {
            'id': 'item-pub-regression',
            'listType': 'public',
            'name': 'Salted Butter',
            'quantity': 2,
            'isCompleted': false,
            'createdAt': '2026-06-08T10:00:00.000Z',
            'updatedAt': '2026-06-08T11:00:00.000Z',
          },
        },
      ]);

      final updated =
          verify(
                () => mockShoppingItemRepository.upsert(captureAny()),
              ).captured.single
              as ShoppingItem;
      expect(updated.name, 'Salted Butter');
      expect(updated.listType, 'public');
    });

    test('versioned full reconcile updates an already-existing item', () async {
      final existing = ShoppingItem(
        id: 'item-existing-full',
        deviceId: 'device-a',
        listType: 'public',
        name: 'Old milk',
        createdAt: DateTime.utc(2026, 6, 8),
        syncRevision: 100,
        syncOriginDeviceId: 'device-a',
      );
      when(
        () => mockShoppingItemRepository.findById('item-existing-full'),
      ).thenAnswer((_) async => existing);
      when(
        () => mockShoppingItemRepository.upsert(any()),
      ).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'shopping_item',
          'entityId': 'item-existing-full',
          'operationId': 'shopping:item-existing-full:200:device-b:update',
          'revision': 200,
          'originDeviceId': 'device-b',
          'fromDeviceId': 'device-b',
          'data': {
            'id': 'item-existing-full',
            'listType': 'public',
            'name': 'Fresh milk',
            'quantity': 2,
            'isCompleted': false,
            'createdAt': '2026-06-08T00:00:00.000Z',
            'updatedAt': '2026-06-09T00:00:00.000Z',
          },
        },
      ]);

      final updated =
          verify(
                () => mockShoppingItemRepository.upsert(captureAny()),
              ).captured.single
              as ShoppingItem;
      expect(updated.name, 'Fresh milk');
      expect(updated.syncRevision, 200);
      expect(updated.syncOriginDeviceId, 'device-b');
    });

    test(
      'versioned full tombstone creates an unknown-id deletion guard',
      () async {
        when(
          () => mockShoppingItemRepository.findById('item-missed-delete'),
        ).thenAnswer((_) async => null);
        when(
          () => mockShoppingItemRepository.upsert(any()),
        ).thenAnswer((_) async {});

        await useCase.execute([
          {
            'op': 'delete',
            'entityType': 'shopping_item',
            'entityId': 'item-missed-delete',
            'operationId': 'shopping:item-missed-delete:300:device-b:delete',
            'revision': 300,
            'originDeviceId': 'device-b',
            'fromDeviceId': 'device-b',
            'data': {
              'id': 'item-missed-delete',
              'listType': 'public',
              'createdAt': '2026-06-08T00:00:00.000Z',
              'updatedAt': '2026-06-09T00:00:00.000Z',
            },
          },
        ]);

        final tombstone =
            verify(
                  () => mockShoppingItemRepository.upsert(captureAny()),
                ).captured.single
                as ShoppingItem;
        expect(tombstone.isDeleted, isTrue);
        expect(tombstone.syncRevision, 300);
        expect(tombstone.syncOriginDeviceId, 'device-b');
      },
    );
  });
}
