import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockE2EEService extends Mock implements E2EEService {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

void main() {
  late MockRelayApiClient apiClient;
  late MockE2EEService e2eeService;
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late PushSyncUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    e2eeService = MockE2EEService();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    useCase = PushSyncUseCase(
      apiClient: apiClient,
      e2eeService: e2eeService,
      groupRepo: groupRepository,
      queueManager: queueManager,
    );
  });

  test(
    'expected group prevents retired-group outbox leaking to a new group',
    () async {
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-new',
          groupName: 'New Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'group-key',
          members: const [],
          createdAt: DateTime(2026),
        ),
      );

      final result = await useCase.execute(
        operations: [
          {
            'op': 'update',
            'entityType': 'bill',
            'entityId': 'tx-1',
            'operationId': 'outbox:group-old:bill:tx-1:1',
            'revision': 1,
            'originDeviceId': 'device-1',
            'data': {'id': 'tx-1', 'syncRevision': 1},
          },
        ],
        vectorClock: const {'device-1': 1},
        expectedGroupId: 'group-old',
      );

      expect(result, isA<PushSyncError>());
      verifyNever(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      );
    },
  );

  test('pushes encrypted operations to the active group', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => e2eeService.encryptForGroup(
        plaintext: any(named: 'plaintext'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn('encrypted-payload');
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
      ),
    ).thenAnswer((_) async => {'recipientCount': 2});

    final result = await useCase.execute(
      operations: [
        {'op': 'insert', 'table': 'transactions'},
      ],
      vectorClock: const {'device-1': 1},
    );

    expect(result, isA<PushSyncSuccess>());
    verify(
      () => apiClient.pushSync(
        groupId: 'group-1',
        syncId: any(named: 'syncId'),
        payload: 'encrypted-payload',
        vectorClock: const {'device-1': 1},
        operationCount: 1,
      ),
    ).called(1);
  });

  test(
    'drops an unsafe private bill before group lookup or encryption',
    () async {
      final result = await useCase.execute(
        operations: [
          {
            'op': 'create',
            'entityType': 'bill',
            'entityId': 'private-tx',
            'data': {'amount': 999, 'note': 'secret', 'isPrivate': true},
          },
        ],
        vectorClock: const {'device-1': 99},
      );

      expect(result, isA<PushSyncSuccess>());
      expect((result as PushSyncSuccess).operationCount, 0);
      verifyNever(() => groupRepository.getActiveGroup());
      verifyNever(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      );
      verifyNever(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          syncId: any(named: 'syncId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
        ),
      );
    },
  );

  test(
    'mixed batch removes private bill and recomputes vector clock',
    () async {
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'group-key',
          members: const [],
          createdAt: DateTime(2026),
        ),
      );
      String? plaintext;
      when(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      ).thenAnswer((invocation) {
        plaintext = invocation.namedArguments[#plaintext] as String;
        return 'encrypted-payload';
      });
      when(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          syncId: any(named: 'syncId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
        ),
      ).thenAnswer((_) async => {'recipientCount': 1});

      final result = await useCase.execute(
        operations: [
          {
            'op': 'update',
            'entityType': 'bill',
            'entityId': 'private-tx',
            'revision': 99,
            'originDeviceId': 'private-device',
            'data': {'isPrivate': true, 'amount': 999},
          },
          {
            'op': 'update',
            'entityType': 'bill',
            'entityId': 'public-tx',
            'revision': 2,
            'originDeviceId': 'public-device',
            'data': {'amount': 100, 'isDeleted': false},
          },
        ],
        vectorClock: const {'private-device': 99, 'public-device': 2},
      );

      expect((result as PushSyncSuccess).operationCount, 1);
      final envelope = jsonDecode(plaintext!) as Map<String, dynamic>;
      expect(envelope['vectorClock'], {'public-device': 2});
      final operations = envelope['operations'] as List<dynamic>;
      expect(operations, hasLength(1));
      expect(
        (operations.single as Map<String, dynamic>)['entityId'],
        'public-tx',
      );
    },
  );

  test('queues the payload when the push fails', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => e2eeService.encryptForGroup(
        plaintext: any(named: 'plaintext'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn('encrypted-payload');
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
      ),
    ).thenThrow(Exception('offline'));
    when(
      () => queueManager.enqueue(
        id: any(named: 'id'),
        groupId: any(named: 'groupId'),
        encryptedPayload: any(named: 'encryptedPayload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        initialFailure: any(named: 'initialFailure'),
      ),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      operations: [
        {'op': 'insert', 'table': 'transactions'},
      ],
      vectorClock: const {'device-1': 1},
    );

    expect(result, isA<PushSyncQueued>());
    verify(
      () => queueManager.enqueue(
        id: any(named: 'id'),
        groupId: 'group-1',
        encryptedPayload: 'encrypted-payload',
        vectorClock: const {'device-1': 1},
        operationCount: 1,
        initialFailure: any(named: 'initialFailure'),
      ),
    ).called(1);
  });

  test(
    'SQLCipher-outbox-backed push failure does not create a ciphertext duplicate',
    () async {
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'owner',
          groupKey: 'group-key',
          keyEpoch: 4,
          members: const [],
          createdAt: DateTime(2026),
        ),
      );
      when(
        () => e2eeService.encryptForGroup(
          plaintext: any(named: 'plaintext'),
          groupKeyBase64: 'group-key',
          keyEpoch: 4,
        ),
      ).thenReturn('encrypted-payload');
      when(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          syncId: any(named: 'syncId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
          keyEpoch: any(named: 'keyEpoch'),
        ),
      ).thenThrow(Exception('offline'));

      final result = await useCase.execute(
        operations: [
          {
            'op': 'update',
            'entityType': 'bill',
            'entityId': 'tx-1',
            'operationId': 'outbox:group-1:bill:tx-1:7',
            'revision': 7,
            'originDeviceId': 'device-1',
            'data': {'isDeleted': false},
          },
        ],
        vectorClock: const {'device-1': 7},
        expectedGroupId: 'group-1',
        enqueueOnFailure: false,
      );

      expect(result, isA<PushSyncError>());
      verifyNever(
        () => queueManager.enqueue(
          id: any(named: 'id'),
          groupId: any(named: 'groupId'),
          encryptedPayload: any(named: 'encryptedPayload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
          keyEpoch: any(named: 'keyEpoch'),
          withdrawalReceipts: any(named: 'withdrawalReceipts'),
          initialFailure: any(named: 'initialFailure'),
        ),
      );
    },
  );

  test('wraps operations in protocol envelope before encryption', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => e2eeService.encryptForGroup(
        plaintext: any(named: 'plaintext'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn('encrypted-payload');
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
      ),
    ).thenAnswer((_) async => {'recipientCount': 2});

    await useCase.execute(
      operations: [
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'data': {'id': 'tx-1'},
          'timestamp': 123,
        },
      ],
      vectorClock: const {'device-a': 5},
    );

    final plaintext =
        verify(
              () => e2eeService.encryptForGroup(
                plaintext: captureAny(named: 'plaintext'),
                groupKeyBase64: any(named: 'groupKeyBase64'),
              ),
            ).captured.last
            as String;

    final envelope = jsonDecode(plaintext) as Map<String, dynamic>;
    expect(envelope['syncType'], 'incremental');
    expect(envelope['syncId'], isA<String>());
    expect(envelope['operations'], hasLength(1));
    expect(envelope['vectorClock'], {'device-a': 5});
  });

  test('reuses one sync id for the attempted push and offline queue', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => e2eeService.encryptForGroup(
        plaintext: any(named: 'plaintext'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenReturn('encrypted-payload');
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenThrow(Exception('timeout after server accepted request'));
    when(
      () => queueManager.enqueue(
        id: any(named: 'id'),
        groupId: any(named: 'groupId'),
        encryptedPayload: any(named: 'encryptedPayload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
        initialFailure: any(named: 'initialFailure'),
      ),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      operations: [
        {
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'tx-1',
          'revision': 7,
          'originDeviceId': 'device-1',
          'data': {'amount': 100, 'isDeleted': false},
        },
      ],
      vectorClock: const {'device-1': 7},
    );

    expect(result, isA<PushSyncQueued>());
    final pushedSyncId =
        verify(
              () => apiClient.pushSync(
                groupId: 'group-1',
                syncId: captureAny(named: 'syncId'),
                payload: 'encrypted-payload',
                vectorClock: const {'device-1': 7},
                operationCount: 1,
                keyEpoch: 1,
              ),
            ).captured.single
            as String;
    final queuedSyncId =
        verify(
              () => queueManager.enqueue(
                id: captureAny(named: 'id'),
                groupId: 'group-1',
                encryptedPayload: 'encrypted-payload',
                vectorClock: const {'device-1': 7},
                operationCount: 1,
                keyEpoch: 1,
                initialFailure: any(named: 'initialFailure'),
              ),
            ).captured.single
            as String;
    expect(queuedSyncId, pushedSyncId);

    final plaintext =
        verify(
              () => e2eeService.encryptForGroup(
                plaintext: captureAny(named: 'plaintext'),
                groupKeyBase64: 'group-key',
                keyEpoch: 1,
              ),
            ).captured.single
            as String;
    final envelope = jsonDecode(plaintext) as Map<String, dynamic>;
    expect(envelope['syncId'], pushedSyncId);
    expect(
      (envelope['operations'] as List).single['operationId'],
      '$pushedSyncId:0',
    );
  });
}
