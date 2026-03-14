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

  test('pushes encrypted operations to the active group', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',

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
        payload: 'encrypted-payload',
        vectorClock: const {'device-1': 1},
        operationCount: 1,
      ),
    ).called(1);
  });

  test('queues the payload when the push fails', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',

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
      ),
    ).called(1);
  });

  test('wraps operations in protocol envelope before encryption', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',

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
}
