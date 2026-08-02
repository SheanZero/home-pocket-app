import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockRelayApiClient apiClient;
  late _MockE2EEService e2eeService;
  late _MockGroupRepository groupRepository;
  late _MockSyncQueueManager queueManager;
  late _MockKeyManager keyManager;
  late int appliedCount;

  PullSyncUseCase buildUseCase({int maxPages = 50}) => PullSyncUseCase(
    apiClient: apiClient,
    e2eeService: e2eeService,
    groupRepo: groupRepository,
    queueManager: queueManager,
    keyManager: keyManager,
    maxPagesPerExecution: maxPages,
    applyOperations: (operations, {groupId}) async {
      appliedCount += operations.length;
    },
  );

  setUp(() {
    apiClient = _MockRelayApiClient();
    e2eeService = _MockE2EEService();
    groupRepository = _MockGroupRepository();
    queueManager = _MockSyncQueueManager();
    keyManager = _MockKeyManager();
    appliedCount = 0;

    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => _activeGroup());
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
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
            'entityType': 'bill',
            'entityId': 'bill-1',
            'data': {'id': 'bill-1'},
          },
        ],
      }),
    );
    when(
      () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
    ).thenAnswer((_) async => {'acked': true});
    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
  });

  test('drains more than 100 messages across hasMore pages', () async {
    final pages = <Map<String, dynamic>>[
      {
        'messages': List.generate(100, (index) => _dataMessage('p1-$index')),
        'hasMore': true,
      },
      {
        'messages': [_dataMessage('p2-0')],
        'hasMore': false,
      },
    ];
    when(() => apiClient.pullSync()).thenAnswer((_) async => pages.removeAt(0));

    final result = await buildUseCase().execute();

    expect(result, isA<PullSyncSuccess>());
    final success = result as PullSyncSuccess;
    expect(success.appliedCount, 101);
    expect(success.ackedCount, 101);
    expect(success.pageCount, 2);
    expect(appliedCount, 101);
    verify(() => apiClient.pullSync()).called(2);
    verify(
      () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
    ).called(2);
    verify(() => queueManager.drainQueue()).called(1);
  });

  test(
    'accepts the server full-page false positive then an empty final page',
    () async {
      final pages = <Map<String, dynamic>>[
        {
          'messages': [_dataMessage('page-1')],
          'hasMore': true,
        },
        {'messages': <Object>[], 'hasMore': false},
      ];
      when(
        () => apiClient.pullSync(),
      ).thenAnswer((_) async => pages.removeAt(0));

      final result = await buildUseCase().execute() as PullSyncSuccess;

      expect(result.appliedCount, 1);
      expect(result.ackedCount, 1);
      expect(result.pageCount, 2);
    },
  );

  test('rejects an empty page that claims more data', () async {
    when(
      () => apiClient.pullSync(),
    ).thenAnswer((_) async => {'messages': <Object>[], 'hasMore': true});

    final result = await buildUseCase().execute();

    expect(result, isA<PullSyncError>());
    expect((result as PullSyncError).message, contains('empty page'));
    verifyNever(() => queueManager.drainQueue());
  });

  test(
    'stops with an explicit deferred result when a page makes no progress',
    () async {
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [_dataMessage('future-key', keyEpoch: 2)],
          'hasMore': true,
        },
      );

      final result = await buildUseCase().execute();

      expect(result, isA<PullSyncDeferred>());
      final deferred = result as PullSyncDeferred;
      expect(deferred.reason, PullSyncDeferredReason.noProgress);
      expect(deferred.unacknowledgedMessageIds, ['future-key']);
      expect(deferred.appliedCount, 0);
      expect(deferred.ackedCount, 0);
      expect(deferred.pageCount, 1);
      verify(() => apiClient.pullSync()).called(1);
      verifyNever(
        () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
      );
      verifyNever(() => queueManager.drainQueue());
    },
  );

  test(
    'old-epoch local-only photo metadata is neither decrypted nor ACKed',
    () async {
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [_dataMessage('old-photo', keyEpoch: 0)],
          'hasMore': false,
        },
      );

      final result = await buildUseCase().execute();

      expect(result, isA<PullSyncDeferred>());
      expect(appliedCount, 0);
      verifyNever(
        () => e2eeService.decryptFromGroup(
          encryptedPayload: any(named: 'encryptedPayload'),
          groupKeyBase64: any(named: 'groupKeyBase64'),
        ),
      );
      verifyNever(
        () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
      );
    },
  );

  test(
    'page two failure reports only work durably ACKed on page one',
    () async {
      var calls = 0;
      when(() => apiClient.pullSync()).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return {
            'messages': [_dataMessage('page-1')],
            'hasMore': true,
          };
        }
        throw const RelayApiException(statusCode: 503, message: 'offline');
      });

      final result = await buildUseCase().execute();

      expect(result, isA<PullSyncError>());
      final error = result as PullSyncError;
      expect(error.message, 'offline');
      expect(error.appliedCount, 1);
      expect(error.ackedCount, 1);
      expect(error.pageCount, 1);
      verifyNever(() => queueManager.drainQueue());
    },
  );

  test(
    'stops at the total page limit without marking reconciliation complete',
    () async {
      var sequence = 0;
      when(() => apiClient.pullSync()).thenAnswer(
        (_) async => {
          'messages': [_dataMessage('page-${sequence++}')],
          'hasMore': true,
        },
      );

      final result = await buildUseCase(maxPages: 2).execute();

      expect(result, isA<PullSyncDeferred>());
      final deferred = result as PullSyncDeferred;
      expect(deferred.reason, PullSyncDeferredReason.pageLimitReached);
      expect(deferred.appliedCount, 2);
      expect(deferred.ackedCount, 2);
      expect(deferred.pageCount, 2);
      verify(() => apiClient.pullSync()).called(2);
      verifyNever(() => queueManager.drainQueue());
    },
  );

  group('RelayPullResponse', () {
    test('parses hasMore and preserves typed messages', () {
      final response = RelayPullResponse.fromJson({
        'messages': [_dataMessage('message-1')],
        'hasMore': true,
      });

      expect(response.hasMore, isTrue);
      expect(response.messages.single['messageId'], 'message-1');
    });

    test('rejects a server page larger than the protocol limit', () {
      expect(
        () => RelayPullResponse.fromJson({
          'messages': List.generate(101, (index) => _dataMessage('$index')),
          'hasMore': false,
        }),
        throwsFormatException,
      );
    });
  });
}

GroupInfo _activeGroup() => GroupInfo(
  groupId: 'group-1',
  status: GroupStatus.active,
  groupName: 'Family',
  role: 'owner',
  groupKey: 'group-key',
  members: const [],
  createdAt: DateTime(2026),
);

Map<String, dynamic> _dataMessage(String messageId, {int keyEpoch = 1}) => {
  'messageId': messageId,
  'fromDeviceId': 'sender-1',
  'keyEpoch': keyEpoch,
  'payload': jsonEncode({
    'v': 2,
    't': 'D',
    'e': keyEpoch,
    'p': 'ciphertext-$messageId',
  }),
};
