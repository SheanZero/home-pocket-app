import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/inbound_sync_resource_policy.dart';
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
  late List<String?> appliedGroupIds;
  late bool failApply;
  late PullSyncUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    e2eeService = MockE2EEService();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    keyManager = MockKeyManager();
    appliedOperations = [];
    appliedGroupIds = [];
    failApply = false;
    useCase = PullSyncUseCase(
      apiClient: apiClient,
      e2eeService: e2eeService,
      groupRepo: groupRepository,
      queueManager: queueManager,
      keyManager: keyManager,
      applyOperations: (operations, {groupId}) async {
        if (failApply) throw StateError('avatar write failed');
        appliedOperations.add(operations);
        appliedGroupIds.add(groupId);
      },
    );

    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
    when(
      () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
    ).thenAnswer((_) async => {'acked': 1});
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'member-1');
  });

  test('preserves authenticated membership status on pull errors', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Family',
        status: GroupStatus.active,
        role: 'member',
        groupKey: 'group-key',
        members: const [],
        createdAt: DateTime.utc(2026),
      ),
    );
    when(
      () => apiClient.pullSync(),
    ).thenThrow(const RelayApiException(statusCode: 403, message: 'removed'));

    final result = await useCase.execute();

    expect(
      result,
      isA<PullSyncError>().having(
        (error) => error.statusCode,
        'statusCode',
        403,
      ),
    );
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
          groupName: 'Test Family',
          status: GroupStatus.confirming,
          role: 'member',
          members: const [
            GroupMember(
              deviceId: 'owner-1',
              publicKey: 'owner-public-key',
              deviceName: 'Owner phone',
              role: 'owner',
              status: 'active',
              displayName: 'Owner',
              avatarEmoji: '🏠',
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );
      when(() => apiClient.pullSync()).thenAnswer(
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
        () => groupRepository.storeGroupKeyForEpoch(
          any(),
          groupKeyBase64: any(named: 'groupKeyBase64'),
          keyEpoch: any(named: 'keyEpoch'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => null);

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'group-key',
          keyEpoch: 1,
        ),
      ).called(1);
      verify(() => apiClient.ackSync(messageIds: ['msg-1'])).called(1);
    },
  );

  test('does not decrypt or ACK a key envelope for another device', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    when(() => groupRepository.getPendingGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.confirming,
        role: 'member',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'owner-public-key',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
        ],
        createdAt: DateTime(2026),
      ),
    );
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'wrong-target',
            'fromDeviceId': 'owner-1',
            'keyEpoch': 2,
            'payload': jsonEncode({
              'v': 2,
              't': 'K',
              'e': 2,
              'toDeviceId': 'member-2',
              'p': 'sealed-key',
            }),
          },
        ],
      },
    );

    final result = await useCase.execute();

    expect(result, isA<PullSyncDeferred>());
    expect(
      (result as PullSyncDeferred).reason,
      PullSyncDeferredReason.noProgress,
    );
    verifyNever(
      () => e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: any(named: 'encryptedPayload'),
        ownerPublicKey: any(named: 'ownerPublicKey'),
      ),
    );
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test(
    'does not ACK a key envelope whose transport epoch is inconsistent',
    () async {
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => null);
      when(() => groupRepository.getPendingGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.confirming,
          role: 'member',
          members: const [
            GroupMember(
              deviceId: 'owner-1',
              publicKey: 'owner-public-key',
              deviceName: 'Owner phone',
              role: 'owner',
              status: 'active',
              displayName: 'Owner',
              avatarEmoji: '🏠',
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'wrong-epoch',
              'fromDeviceId': 'owner-1',
              'keyEpoch': 2,
              'payload': jsonEncode({
                'v': 2,
                't': 'K',
                'e': 3,
                'toDeviceId': 'member-1',
                'p': 'sealed-key',
              }),
            },
          ],
        },
      );

      final result = await useCase.execute();

      expect(result, isA<PullSyncDeferred>());
      expect(
        (result as PullSyncDeferred).reason,
        PullSyncDeferredReason.noProgress,
      );
      verifyNever(
        () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
      );
    },
  );

  test('does not ACK a key envelope that cannot be decrypted', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    when(() => groupRepository.getPendingGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.confirming,
        role: 'member',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'owner-public-key',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
        ],
        createdAt: DateTime(2026),
      ),
    );
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'bad-ciphertext',
            'fromDeviceId': 'owner-1',
            'keyEpoch': 1,
            'payload': jsonEncode({
              'v': 2,
              't': 'K',
              'e': 1,
              'toDeviceId': 'member-1',
              'p': 'invalid-sealed-key',
            }),
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: any(named: 'encryptedPayload'),
        ownerPublicKey: any(named: 'ownerPublicKey'),
      ),
    ).thenThrow(const FormatException('invalid envelope'));

    final result = await useCase.execute();

    expect(result, isA<PullSyncDeferred>());
    expect(
      (result as PullSyncDeferred).reason,
      PullSyncDeferredReason.noProgress,
    );
    verifyNever(
      () => groupRepository.storeGroupKeyForEpoch(
        any(),
        groupKeyBase64: any(named: 'groupKeyBase64'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    );
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test('applies v2 data payloads using the stored group key', () async {
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
    when(() => apiClient.pullSync()).thenAnswer(
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
    ).thenAnswer((_) async => true);

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single.first['fromDeviceId'], 'owner-1');
    expect(appliedGroupIds, ['group-1']);
    verifyNever(() => groupRepository.updateLastSyncTime(any()));
    verify(() => apiClient.ackSync(messageIds: ['msg-2'])).called(1);
  });

  test('future plaintext envelope version is deferred without ACK', () async {
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
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'future-envelope',
            'fromDeviceId': 'owner-1',
            'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
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
        'schema': 'home-pocket.sync',
        'version': 99,
        'operations': <Object?>[],
      }),
    );

    final result = await useCase.execute();

    expect(result, isA<PullSyncDeferred>());
    expect(
      (result as PullSyncDeferred).reason,
      PullSyncDeferredReason.unsupportedEnvelope,
    );
    expect(appliedOperations, isEmpty);
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test(
    'ACKs a mixed applied and durably quarantined operation batch',
    () async {
      String? authoritativeApplyGroupId;
      useCase = PullSyncUseCase(
        apiClient: apiClient,
        e2eeService: e2eeService,
        groupRepo: groupRepository,
        queueManager: queueManager,
        keyManager: keyManager,
        applyOperations: (operations, {groupId}) async {
          authoritativeApplyGroupId = groupId;
          return ApplySyncOperationsResult([
            const SyncOperationApplyResult(
              operationId: 'good:1',
              status: SyncOperationApplyStatus.applied,
            ),
            const SyncOperationApplyResult(
              operationId: 'bad:1',
              status: SyncOperationApplyStatus.quarantined,
              errorCode: 'unsupported_entity_type',
            ),
          ]);
        },
      );
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
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'mixed-message',
              'fromDeviceId': 'owner-1',
              'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
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
          'schema': 'home-pocket.sync',
          'version': 1,
          'operations': [
            {
              'operationId': 'good:1',
              'entityType': 'profile',
              'op': 'update',
              'groupId': 'forged-group',
              'data': {'groupId': 'forged-payload-group'},
            },
            {'operationId': 'bad:1', 'entityType': 'unknown', 'op': 'explode'},
          ],
        }),
      );

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      expect(authoritativeApplyGroupId, 'group-1');
      verify(() => apiClient.ackSync(messageIds: ['mixed-message'])).called(1);
    },
  );

  test(
    'ACKs an over-limit batch only after its safe summary is durable',
    () async {
      final plaintext = jsonEncode({
        'schema': 'home-pocket.sync',
        'version': 1,
        'operations': [
          for (
            var index = 0;
            index <= InboundSyncResourcePolicy.maxOperationsPerMessage;
            index++
          )
            {'operationId': 'operation-$index', 'entityType': 'future'},
        ],
      });
      useCase = PullSyncUseCase(
        apiClient: apiClient,
        e2eeService: e2eeService,
        groupRepo: groupRepository,
        queueManager: queueManager,
        keyManager: keyManager,
        applyOperations: (operations, {groupId}) async {
          fail('over-limit batches must be rejected before normalization');
        },
        rejectOperationsBatch:
            ({
              required groupId,
              required messageId,
              required sourceBytes,
              required digest,
            }) async {
              expect(groupId, 'group-1');
              expect(messageId, 'over-limit-message');
              expect(sourceBytes, utf8.encode(plaintext).length);
              expect(
                digest,
                hash_lib.sha256.convert(utf8.encode(plaintext)).toString(),
              );
              return const ApplySyncOperationsResult([
                SyncOperationApplyResult(
                  operationId: 'rejected-batch:digest',
                  status: SyncOperationApplyStatus.quarantined,
                  errorCode: 'batch_operation_limit_exceeded',
                ),
              ]);
            },
      );
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
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'over-limit-message',
              'fromDeviceId': 'owner-1',
              'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
            },
          ],
        },
      );
      when(
        () => e2eeService.decryptFromGroup(
          encryptedPayload: any(named: 'encryptedPayload'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      ).thenReturn(plaintext);

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => apiClient.ackSync(messageIds: ['over-limit-message']),
      ).called(1);
    },
  );

  test('does not ACK when an over-limit summary is not durable', () async {
    final plaintext = jsonEncode({
      'schema': 'home-pocket.sync',
      'version': 1,
      'operations': List<Object?>.filled(
        InboundSyncResourcePolicy.maxOperationsPerMessage + 1,
        null,
      ),
    });
    useCase = PullSyncUseCase(
      apiClient: apiClient,
      e2eeService: e2eeService,
      groupRepo: groupRepository,
      queueManager: queueManager,
      keyManager: keyManager,
      applyOperations: (operations, {groupId}) async {
        fail('over-limit batches must be rejected before normalization');
      },
      rejectOperationsBatch:
          ({
            required groupId,
            required messageId,
            required sourceBytes,
            required digest,
          }) async => const ApplySyncOperationsResult([
            SyncOperationApplyResult(
              operationId: 'rejected-batch:digest',
              status: SyncOperationApplyStatus.failed,
              errorCode: 'quarantine_write_failed',
            ),
          ]),
    );
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
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'over-limit-not-durable',
            'fromDeviceId': 'owner-1',
            'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptFromGroup(
        encryptedPayload: any(named: 'encryptedPayload'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    ).thenReturn(plaintext);

    final result = await useCase.execute();

    expect(result, isA<PullSyncDeferred>());
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test(
    'does not ACK when any operation has a transient apply failure',
    () async {
      useCase = PullSyncUseCase(
        apiClient: apiClient,
        e2eeService: e2eeService,
        groupRepo: groupRepository,
        queueManager: queueManager,
        keyManager: keyManager,
        applyOperations: (operations, {groupId}) async =>
            ApplySyncOperationsResult([
              const SyncOperationApplyResult(
                operationId: 'temporary:1',
                status: SyncOperationApplyStatus.failed,
                errorCode: 'apply_temporary_failure',
              ),
            ]),
      );
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
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'temporary-message',
              'fromDeviceId': 'owner-1',
              'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
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
          'schema': 'home-pocket.sync',
          'version': 1,
          'operations': [
            {
              'operationId': 'temporary:1',
              'entityType': 'bill',
              'op': 'update',
            },
          ],
        }),
      );

      final result = await useCase.execute();

      expect(result, isA<PullSyncDeferred>());
      verifyNever(
        () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
      );
    },
  );

  test(
    'redelivery after crash-before-ACK is ACKed as already applied',
    () async {
      final appliedIds = <String>{};
      var applyCalls = 0;
      useCase = PullSyncUseCase(
        apiClient: apiClient,
        e2eeService: e2eeService,
        groupRepo: groupRepository,
        queueManager: queueManager,
        keyManager: keyManager,
        applyOperations: (operations, {groupId}) async {
          applyCalls++;
          final id = operations.single['operationId'] as String;
          final alreadyApplied = !appliedIds.add(id);
          return ApplySyncOperationsResult([
            SyncOperationApplyResult(
              operationId: id,
              status: alreadyApplied
                  ? SyncOperationApplyStatus.alreadyApplied
                  : SyncOperationApplyStatus.applied,
            ),
          ]);
        },
      );
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
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'crash-window-message',
              'fromDeviceId': 'owner-1',
              'payload': jsonEncode({'v': 2, 't': 'D', 'p': 'ciphertext'}),
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
          'schema': 'home-pocket.sync',
          'version': 1,
          'operations': [
            {
              'operationId': 'stable-operation:1',
              'entityType': 'profile',
              'op': 'update',
            },
          ],
        }),
      );
      when(
        () => apiClient.ackSync(messageIds: ['crash-window-message']),
      ).thenThrow(
        const RelayApiException(statusCode: 503, message: 'temporary'),
      );

      final first = await useCase.execute();
      expect(first, isA<PullSyncError>());

      when(
        () => apiClient.ackSync(messageIds: ['crash-window-message']),
      ).thenAnswer((_) async => {'acked': 1});
      final second = await useCase.execute();

      expect(second, isA<PullSyncSuccess>());
      expect(applyCalls, 2);
      expect(appliedIds, {'stable-operation:1'});
      verify(
        () => apiClient.ackSync(messageIds: ['crash-window-message']),
      ).called(2);
    },
  );

  test('does not decrypt or ACK data from a different key epoch', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'member',
        groupKey: 'epoch-2-key',
        keyEpoch: 2,
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'msg-wrong-epoch',
            'fromDeviceId': 'owner-1',
            'keyEpoch': 3,
            'payload': jsonEncode({
              'v': 2,
              't': 'D',
              'e': 3,
              'p': 'encrypted-with-epoch-3',
            }),
          },
        ],
      },
    );

    final result = await useCase.execute();

    expect(result, isA<PullSyncDeferred>());
    expect(
      (result as PullSyncDeferred).reason,
      PullSyncDeferredReason.noProgress,
    );
    verifyNever(
      () => e2eeService.decryptFromGroup(
        encryptedPayload: any(named: 'encryptedPayload'),
        groupKeyBase64: any(named: 'groupKeyBase64'),
      ),
    );
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test('accepts and persists the owner key for a newer server epoch', () async {
    final waitingGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      keyEpoch: 2,
      members: const [
        GroupMember(
          deviceId: 'owner-1',
          publicKey: 'owner-public-key',
          deviceName: 'Owner phone',
          role: 'owner',
          status: 'active',
          displayName: 'Owner',
          avatarEmoji: '🏠',
        ),
      ],
      createdAt: DateTime(2026),
    );
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => waitingGroup);
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'msg-epoch-3-key',
            'fromDeviceId': 'owner-1',
            'keyEpoch': 3,
            'payload': jsonEncode({
              'v': 2,
              't': 'K',
              'e': 3,
              'toDeviceId': 'member-1',
              'p': 'sealed-epoch-3-key',
            }),
          },
        ],
      },
    );
    when(
      () => e2eeService.decryptGroupKeyFromOwner(
        encryptedPayload: any(named: 'encryptedPayload'),
        ownerPublicKey: 'owner-public-key',
      ),
    ).thenAnswer((_) async => 'epoch-3-key');
    when(
      () => groupRepository.storeGroupKeyForEpoch(
        'group-1',
        groupKeyBase64: 'epoch-3-key',
        keyEpoch: 3,
      ),
    ).thenAnswer((_) async {});
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async => waitingGroup.copyWith(keyEpoch: 3, groupKey: 'epoch-3-key'),
    );

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    verify(
      () => groupRepository.storeGroupKeyForEpoch(
        'group-1',
        groupKeyBase64: 'epoch-3-key',
        keyEpoch: 3,
      ),
    ).called(1);
    verify(() => apiClient.ackSync(messageIds: ['msg-epoch-3-key'])).called(1);
  });

  test(
    'owner accepts requested recovery key from an active non-owner member',
    () async {
      final waitingOwner = GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        keyEpoch: 4,
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'owner-public-key',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'member-public-key',
            deviceName: 'Member phone',
            role: 'member',
            status: 'active',
            displayName: 'Member',
            avatarEmoji: '🌿',
          ),
        ],
        createdAt: DateTime(2026),
      );
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'owner-1');
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => waitingOwner);
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'owner-recovery-response',
              'fromDeviceId': 'member-1',
              'keyEpoch': 4,
              'messageKind': 'group_key_response',
              'payload': jsonEncode({
                'v': 2,
                't': 'K',
                'e': 4,
                'requestId': 'owner-request',
                'toDeviceId': 'owner-1',
                'p': 'sealed-for-owner',
              }),
            },
          ],
        },
      );
      when(
        () => e2eeService.decryptGroupKeyFromOwner(
          encryptedPayload: any(named: 'encryptedPayload'),
          ownerPublicKey: 'member-public-key',
        ),
      ).thenAnswer((_) async => 'epoch-4-key');
      when(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-4-key',
          keyEpoch: 4,
        ),
      ).thenAnswer((_) async {});
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => waitingOwner.copyWith(groupKey: 'epoch-4-key'));

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-4-key',
          keyEpoch: 4,
        ),
      ).called(1);
      verify(
        () => apiClient.ackSync(messageIds: ['owner-recovery-response']),
      ).called(1);
    },
  );

  test(
    'accepts a server-backed transfer envelope from the now former owner',
    () async {
      final transferredGroup = GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        keyEpoch: 5,
        members: const [
          GroupMember(
            deviceId: 'owner-a',
            publicKey: 'old-owner-key',
            deviceName: 'Old owner',
            displayName: 'Old owner',
            avatarEmoji: '🏠',
            role: 'member',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'new-owner-key',
            deviceName: 'New owner',
            displayName: 'New owner',
            avatarEmoji: '🌿',
            role: 'owner',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026),
      );
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => transferredGroup);
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'transfer-key-1',
              'fromDeviceId': 'owner-a',
              'keyEpoch': 5,
              'messageKind': 'owner_transfer_key',
              'payload': jsonEncode({
                'v': 2,
                't': 'K',
                'e': 5,
                'requestId': 'transfer-request',
                'purpose': 'owner_transfer',
                'toDeviceId': 'member-1',
                'p': 'sealed-transfer-key',
              }),
            },
          ],
        },
      );
      when(
        () => e2eeService.decryptGroupKeyFromOwner(
          encryptedPayload: any(named: 'encryptedPayload'),
          ownerPublicKey: 'old-owner-key',
        ),
      ).thenAnswer((_) async => 'epoch-5-key');
      when(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-5-key',
          keyEpoch: 5,
        ),
      ).thenAnswer((_) async {});
      when(() => groupRepository.getGroupById('group-1')).thenAnswer(
        (_) async => transferredGroup.copyWith(groupKey: 'epoch-5-key'),
      );

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-5-key',
          keyEpoch: 5,
        ),
      ).called(1);
      verify(() => apiClient.ackSync(messageIds: ['transfer-key-1'])).called(1);
    },
  );

  test(
    'accepts a server-backed membership rotation key from the owner',
    () async {
      final rotatedGroup = GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'member',
        keyEpoch: 5,
        members: const [
          GroupMember(
            deviceId: 'owner-a',
            publicKey: 'owner-key',
            deviceName: 'Owner',
            displayName: 'Owner',
            avatarEmoji: '🏠',
            role: 'owner',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'member-key',
            deviceName: 'Member',
            displayName: 'Member',
            avatarEmoji: '🌿',
            role: 'member',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026),
      );
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => rotatedGroup);
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'member-rotation-key-1',
              'fromDeviceId': 'owner-a',
              'keyEpoch': 5,
              'messageKind': 'member_rotation_key',
              'payload': jsonEncode({
                'v': 2,
                't': 'K',
                'e': 5,
                'requestId': 'rotation-request',
                'purpose': 'member_remove',
                'toDeviceId': 'member-1',
                'p': 'sealed-rotation-key',
              }),
            },
          ],
        },
      );
      when(
        () => e2eeService.decryptGroupKeyFromOwner(
          encryptedPayload: any(named: 'encryptedPayload'),
          ownerPublicKey: 'owner-key',
        ),
      ).thenAnswer((_) async => 'epoch-5-key');
      when(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-5-key',
          keyEpoch: 5,
        ),
      ).thenAnswer((_) async {});
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => rotatedGroup.copyWith(groupKey: 'epoch-5-key'));

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      verify(
        () => groupRepository.storeGroupKeyForEpoch(
          'group-1',
          groupKeyBase64: 'epoch-5-key',
          keyEpoch: 5,
        ),
      ).called(1);
      verify(
        () => apiClient.ackSync(messageIds: ['member-rotation-key-1']),
      ).called(1);
    },
  );

  test('normalizes legacy sync operations to protocol format', () async {
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
    when(() => apiClient.pullSync()).thenAnswer(
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
    ).thenAnswer((_) async => true);

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single, hasLength(1));
    expect(
      appliedOperations.single.single,
      containsPair('operationId', 'relay:msg-legacy:0'),
    );
    expect(
      appliedOperations.single.single,
      containsPair('transportMessageId', 'msg-legacy'),
    );
    expect(appliedOperations.single.single, containsPair('entityType', 'bill'));
  });

  test('unwraps protocol sync envelope before applying operations', () async {
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
    when(() => apiClient.pullSync()).thenAnswer(
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
    ).thenAnswer((_) async => true);

    final result = await useCase.execute();

    expect(result, isA<PullSyncSuccess>());
    expect(appliedOperations, hasLength(1));
    expect(appliedOperations.single, hasLength(1));
    expect(
      appliedOperations.single.single,
      containsPair('operationId', 'relay:msg-envelope:0'),
    );
    expect(appliedOperations.single.single, containsPair('timestamp', 123));
    expect(appliedOperations.single.single, containsPair('entityType', 'bill'));
  });

  test('does not ACK when durable avatar application fails', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'member',
        groupKey: 'group-key',
        keyEpoch: 2,
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(() => apiClient.pullSync()).thenAnswer(
      (_) async => {
        'messages': [
          {
            'messageId': 'avatar-not-durable',
            'fromDeviceId': 'sender-device',
            'keyEpoch': 2,
            'payload': jsonEncode({
              'v': 2,
              't': 'D',
              'e': 2,
              'p': 'encrypted-avatar',
            }),
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
        'operations': [
          {
            'op': 'update',
            'entityType': 'avatar',
            'entityId': 'spoofed-device',
            'fromDeviceId': 'spoofed-device',
            'data': {'schemaVersion': 1},
          },
        ],
      }),
    );
    failApply = true;

    final result = await useCase.execute();

    expect(result, isA<PullSyncError>());
    verifyNever(() => apiClient.ackSync(messageIds: any(named: 'messageIds')));
  });

  test(
    'upgrades legacy top-level avatar payload into a v1 operation',
    () async {
      final bytes = <int>[0xff, 0xd8, 0xff, 1, 2, 0xff, 0xd9];
      when(() => groupRepository.getActiveGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',
          groupName: 'Test Family',
          status: GroupStatus.active,
          role: 'member',
          groupKey: 'group-key',
          members: const [],
          createdAt: DateTime(2026),
        ),
      );
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [
            {
              'messageId': 'legacy-avatar',
              'fromDeviceId': 'owner-1',
              'keyEpoch': 1,
              'createdAt': '2026-08-01T12:00:00.000Z',
              'payload': jsonEncode({
                'v': 2,
                't': 'D',
                'e': 1,
                'p': 'encrypted-avatar',
              }),
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
          'type': 'avatar_sync',
          'displayName': 'Owner',
          'avatarEmoji': '🏠',
          'avatarImageBase64': base64Encode(bytes),
          'avatarImageHash': hash_lib.sha256.convert(bytes).toString(),
        }),
      );

      final result = await useCase.execute();

      expect(result, isA<PullSyncSuccess>());
      final operation = appliedOperations.single.single;
      expect(operation['entityType'], 'avatar');
      expect(operation['entityId'], 'owner-1');
      expect(operation['fromDeviceId'], 'owner-1');
      expect(operation['transportKeyEpoch'], 1);
      expect(operation['operationId'], startsWith('legacy-avatar:owner-1:'));
      expect(operation['data'], containsPair('mimeType', 'image/jpeg'));
      verify(() => apiClient.ackSync(messageIds: ['legacy-avatar'])).called(1);
    },
  );
}
