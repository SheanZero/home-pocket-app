import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/drain_family_sync_outbox_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/family_sync_outbox_entry.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/family_sync_outbox_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MemoryOutbox implements FamilySyncOutboxRepository {
  _MemoryOutbox(this.entries, {this.throwOnFirstDelete = false});

  final List<FamilySyncOutboxEntry> entries;
  bool throwOnFirstDelete;
  int attemptWrites = 0;

  @override
  Future<List<FamilySyncOutboxEntry>> getPendingForGroup(
    String groupId, {
    int limit = 50,
  }) async => entries
      .where((entry) => entry.groupId == groupId)
      .take(limit)
      .toList(growable: false);

  @override
  Future<void> markAttempted(
    Iterable<FamilySyncOutboxEntry> entries, {
    required DateTime at,
  }) async {
    attemptWrites += entries.length;
  }

  @override
  Future<void> deleteAccepted(Iterable<FamilySyncOutboxEntry> accepted) async {
    if (throwOnFirstDelete) {
      throwOnFirstDelete = false;
      throw StateError('simulated crash before outbox delete');
    }
    final ids = accepted.map((entry) => entry.operationId).toSet();
    entries.removeWhere((entry) => ids.contains(entry.operationId));
  }

  @override
  Future<void> settleCovered({
    required String groupId,
    required Iterable<Map<String, dynamic>> operations,
  }) async {}

  @override
  Future<void> clearGroup(String groupId) async {
    entries.removeWhere((entry) => entry.groupId == groupId);
  }
}

FamilySyncOutboxEntry _entry({
  String groupId = 'group-a',
  String entityId = 'tx-1',
  int revision = 100,
  String entityType = 'bill',
  String operationType = 'update',
  bool isTombstone = false,
}) {
  final operationId = 'outbox:$groupId:$entityType:$entityId:$revision';
  return FamilySyncOutboxEntry(
    operationId: operationId,
    groupId: groupId,
    entityType: entityType,
    entityId: entityId,
    revision: revision,
    operation: {
      'op': operationType,
      'entityType': entityType,
      'entityId': entityId,
      'operationId': operationId,
      'revision': revision,
      'originDeviceId': 'device-a',
      'data': {
        'id': entityId,
        'syncRevision': revision,
        if (isTombstone) 'isDeleted': true,
      },
      'timestamp': '2026-08-02T00:00:00.000Z',
    },
    isTombstone: isTombstone,
    attemptCount: 0,
    createdAt: DateTime.utc(2026, 8, 2),
  );
}

GroupInfo _group(String id) => GroupInfo(
  groupId: id,
  status: GroupStatus.active,
  groupName: 'Family',
  role: 'owner',
  groupKey: 'key',
  members: const [],
  createdAt: DateTime.utc(2026, 8, 2),
);

void main() {
  late _MockGroupRepository groupRepository;
  late _MockPushSyncUseCase pushSync;

  setUp(() {
    groupRepository = _MockGroupRepository();
    pushSync = _MockPushSyncUseCase();
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => _group('group-a'));
  });

  DrainFamilySyncOutboxUseCase build(_MemoryOutbox outbox) =>
      DrainFamilySyncOutboxUseCase(
        outboxRepository: outbox,
        groupRepository: groupRepository,
        pushSync: pushSync,
      );

  test('direct success deletes only after expected-group push', () async {
    final outbox = _MemoryOutbox([_entry()]);
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        expectedGroupId: 'group-a',
        enqueueOnFailure: false,
      ),
    ).thenAnswer((_) async => const PushSyncResult.success(1));

    expect(await build(outbox).execute(), 1);
    expect(outbox.entries, isEmpty);
    expect(outbox.attemptWrites, 1);
  });

  test(
    'durable offline queue hand-off retains semantic outbox until relay ACK',
    () async {
      final outbox = _MemoryOutbox([_entry()]);
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((_) async => const PushSyncResult.queued(1));

      expect(await build(outbox).execute(), 0);
      expect(outbox.entries, hasLength(1));
    },
  );

  test(
    'retired-epoch bill and shopping tombstones resend with stable ids then settle on ACK',
    () async {
      final outbox = _MemoryOutbox([
        _entry(
          entityId: 'tx-withdrawn',
          revision: 201,
          operationType: 'delete',
          isTombstone: true,
        ),
        _entry(
          entityId: 'shopping-deleted',
          revision: 202,
          entityType: 'shopping_item',
          operationType: 'delete',
          isTombstone: true,
        ),
      ]);
      final attemptedIds = <List<String>>[];
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        attemptedIds.add(
          operations
              .map((operation) => operation['operationId'] as String)
              .toList(growable: false),
        );
        return attemptedIds.length == 1
            ? const PushSyncResult.queued(2)
            : const PushSyncResult.success(2);
      });

      expect(await build(outbox).execute(), 0);
      expect(outbox.entries, hasLength(2));

      // A reconstructed use case models restart after the new epoch key is
      // installed. The SQLCipher source survives and carries identical ids.
      expect(await build(outbox).execute(), 2);
      expect(outbox.entries, isEmpty);
      expect(attemptedIds, [
        [
          'outbox:group-a:bill:tx-withdrawn:201',
          'outbox:group-a:shopping_item:shopping-deleted:202',
        ],
        [
          'outbox:group-a:bill:tx-withdrawn:201',
          'outbox:group-a:shopping_item:shopping-deleted:202',
        ],
      ]);
    },
  );

  test(
    'concurrent drains share one relay attempt and one settlement',
    () async {
      final outbox = _MemoryOutbox([_entry()]);
      final relayGate = Completer<void>();
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((_) async {
        await relayGate.future;
        return const PushSyncResult.success(1);
      });
      final drainer = build(outbox);

      final first = drainer.execute();
      final concurrent = drainer.execute();
      relayGate.complete();

      expect(await Future.wait([first, concurrent]), [1, 1]);
      expect(outbox.entries, isEmpty);
      expect(outbox.attemptWrites, 1);
      verify(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).called(1);
    },
  );

  test('push error retains durable state for the next process', () async {
    final outbox = _MemoryOutbox([_entry()]);
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
        expectedGroupId: 'group-a',
        enqueueOnFailure: false,
      ),
    ).thenAnswer((_) async => const PushSyncResult.error('offline'));

    expect(await build(outbox).execute(), 0);
    expect(outbox.entries, hasLength(1));
  });

  test(
    'bad avatar is retained without blocking a later shopping operation',
    () async {
      final outbox = _MemoryOutbox([
        _entry(entityType: 'avatar', entityId: 'device-a'),
        _entry(entityType: 'shopping_item', entityId: 'shopping-a'),
      ]);
      final drainer = DrainFamilySyncOutboxUseCase(
        outboxRepository: outbox,
        groupRepository: groupRepository,
        pushSync: pushSync,
        operationMaterializer: (operation) async {
          if (operation['entityType'] == 'avatar') {
            throw StateError('source changed');
          }
          return operation;
        },
      );
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((_) async => const PushSyncResult.success(1));

      expect(await drainer.execute(), 1);
      expect(outbox.entries, hasLength(1));
      expect(outbox.entries.single.entityType, 'avatar');
      final pushed =
          verify(
                () => pushSync.execute(
                  operations: captureAny(named: 'operations'),
                  vectorClock: any(named: 'vectorClock'),
                  expectedGroupId: 'group-a',
                  enqueueOnFailure: false,
                ),
              ).captured.single
              as List<Map<String, dynamic>>;
      expect(pushed.single['entityType'], 'shopping_item');
    },
  );

  test(
    'permanent avatar failure is atomically superseded then removal is sent',
    () async {
      final badAvatar = _entry(
        entityId: 'device-a',
        entityType: 'avatar',
        revision: 300,
      );
      final shopping = _entry(
        entityId: 'shopping-1',
        entityType: 'shopping_item',
        revision: 301,
      );
      final removedAvatar = _entry(
        entityId: 'device-a',
        entityType: 'avatar',
        revision: 302,
      );
      final outbox = _MemoryOutbox([badAvatar, shopping]);
      final batches = <List<String>>[];
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        batches.add(
          operations
              .map((operation) => operation['entityType'] as String)
              .toList(growable: false),
        );
        return PushSyncResult.success(operations.length);
      });

      final drainer = DrainFamilySyncOutboxUseCase(
        outboxRepository: outbox,
        groupRepository: groupRepository,
        pushSync: pushSync,
        operationMaterializer: (operation) async {
          if (operation['entityType'] == 'avatar' &&
              operation['revision'] == 300) {
            throw StateError('permanent invalid semantic source');
          }
          return operation;
        },
        onMaterializationFailure: (entry, _) async {
          if (entry.operationId != badAvatar.operationId) {
            return FamilySyncOutboxFailureDisposition.retry;
          }
          outbox.entries
            ..removeWhere(
              (candidate) => candidate.operationId == badAvatar.operationId,
            )
            ..add(removedAvatar);
          return FamilySyncOutboxFailureDisposition.superseded;
        },
      );

      expect(await drainer.execute(), 2);
      expect(outbox.entries, isEmpty);
      expect(batches, [
        ['shopping_item'],
        ['avatar'],
      ]);
    },
  );

  test(
    'crash after server response retries the same stable operationId',
    () async {
      final outbox = _MemoryOutbox([_entry()], throwOnFirstDelete: true);
      final pushedIds = <String>[];
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: 'group-a',
          enqueueOnFailure: false,
        ),
      ).thenAnswer((invocation) async {
        final operations =
            invocation.namedArguments[#operations]
                as List<Map<String, dynamic>>;
        pushedIds.add(operations.single['operationId'] as String);
        return const PushSyncResult.success(1);
      });
      final drainer = build(outbox);

      await expectLater(drainer.execute(), throwsStateError);
      expect(outbox.entries, hasLength(1));
      expect(await drainer.execute(), 1);
      expect(pushedIds, [
        'outbox:group-a:bill:tx-1:100',
        'outbox:group-a:bill:tx-1:100',
      ]);
    },
  );

  test(
    'entries from a retired group are never pushed to the active group',
    () async {
      final outbox = _MemoryOutbox([_entry(groupId: 'group-old')]);

      expect(await build(outbox).execute(), 0);
      expect(outbox.entries, hasLength(1));
      verifyNever(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: any(named: 'expectedGroupId'),
          enqueueOnFailure: any(named: 'enqueueOnFailure'),
        ),
      );
    },
  );
}
