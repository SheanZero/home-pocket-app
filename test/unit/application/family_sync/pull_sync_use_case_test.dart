import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockE2EEService extends Mock implements E2EEService {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockRelayApiClient apiClient;
  late MockE2EEService e2eeService;
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late MockKeyManager keyManager;
  late List<List<Map<String, dynamic>>> appliedOperations;
  late PullSyncUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    e2eeService = MockE2EEService();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    keyManager = MockKeyManager();
    appliedOperations = [];
    useCase = PullSyncUseCase(
      apiClient: apiClient,
      e2eeService: e2eeService,
      groupRepo: groupRepository,
      queueManager: queueManager,
      keyManager: keyManager,
      applyOperations: (operations) async {
        appliedOperations.add(operations);
      },
    );

    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
    when(
      () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
    ).thenAnswer((_) async => {'acked': 1});
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'member-1');
  });

  test(
    'stores and ACKs a key-exchange payload for the target device',
    () async {
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => null);
      when(() => groupRepository.getPendingGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',

          status: GroupStatus.confirming,
          role: 'member',
          members: const [
            GroupMember(
              deviceId: 'owner-1',
              publicKey: 'owner-public-key',
              deviceName: 'Owner phone',
              role: 'owner',
              status: 'active',
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );
      when(() => apiClient.pullSync(since: any(named: 'since'))).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'msg-1',
              'fromDeviceId': 'owner-1',
              'payload': jsonEncode({
                'v': 2,
                't': 'K',
                'toDeviceId': 'member-1',
                'p': 'encrypted-box',
              }),
              'createdAt': '2026-01-01T00:00:01.000Z',
            },
          ],
        },
      );
      when(
        () => e2eeService.decryptGroupKeyFromOwner(
          encryptedPayload: any(named: 'encryptedPayload'),
          ownerPublicKey: any(named: 'ownerPublicKey'),
        ),
      ).thenAnswer((_) async => 'group-key');
      when(
        () => groupRepository.storeGroupKey(any(), any()),
      ).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => groupRepository.storeGroupKey('group-1', 'group-key'),
      ).called(1);
      verify(() => apiClient.ackSync(messageIds: ['msg-1'])).called(1);
    },
  );

  test('applies v2 data payloads using the stored group key', () async {
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
    when(() => apiClient.pullSync(since: any(named: 'since'))).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'msg-2',
            'fromDeviceId': 'owner-1',
            'payload': jsonEncode({
              'v': 2,
              't': 'D',
              'p': 'encrypted-secretbox',
            }),
            'createdAt': '2026-01-01T00:00:02.000Z',
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptFromGroup(
        encryptedPayload: any(named: 'encryptedPayload'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn(
      jsonEncode([
        {'op': 'insert', 'table': 'transactions'},
      ]),
    );
    when(
      () => groupRepository.updateLastSyncTime(any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single.first['fromDeviceId'], 'owner-1');
    verify(
      () => groupRepository.updateLastSyncTime(
        DateTime.parse('2026-01-01T00:00:02.000Z'),
      ),
    ).called(1);
    verify(() => apiClient.ackSync(messageIds: ['msg-2'])).called(1);
  });

  test('normalizes legacy sync operations to protocol format', () async {
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
    when(() => apiClient.pullSync(since: any(named: 'since'))).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'msg-legacy',
            'fromDeviceId': 'owner-1',
            'payload': jsonEncode({
              'v': 2,
              't': 'D',
              'p': 'encrypted-secretbox',
            }),
            'createdAt': '2026-01-01T00:00:03.000Z',
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptFromGroup(
        encryptedPayload: any(named: 'encryptedPayload'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn(
      jsonEncode([
        {
          'op': 'insert',
          'table': 'transactions',
          'data': {'id': 'tx-1', 'amount': 1000},
        },
      ]),
    );
    when(
      () => groupRepository.updateLastSyncTime(any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single, [
      {
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'tx-1',
        'data': {'id': 'tx-1', 'amount': 1000},
        'fromDeviceId': 'owner-1',
      },
    ]);
  });

  test('unwraps protocol sync envelope before applying operations', () async {
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
    when(() => apiClient.pullSync(since: any(named: 'since'))).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'msg-envelope',
            'fromDeviceId': 'owner-1',
            'payload': jsonEncode({
              'v': 2,
              't': 'D',
              'p': 'encrypted-secretbox',
            }),
            'createdAt': '2026-01-01T00:00:04.000Z',
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptFromGroup(
        encryptedPayload: any(named: 'encryptedPayload'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn(
      jsonEncode({
        'syncType': 'incremental',
        'syncId': 'sync-1',
        'operations': [
          {
            'op': 'create',
            'entityType': 'bill',
            'entityId': 'tx-1',
            'data': {'id': 'tx-1', 'amount': 1000},
            'timestamp': 123,
          },
        ],
        'vectorClock': {'device-a': 1},
      }),
    );
    when(
      () => groupRepository.updateLastSyncTime(any()),
    ).thenAnswer((_) async {});

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single, [
      {
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'tx-1',
        'data': {'id': 'tx-1', 'amount': 1000},
        'timestamp': 123,
        'fromDeviceId': 'owner-1',
      },
    ]);
  });
}
