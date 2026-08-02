import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/sync_queue_dao.dart';
import 'package:home_pocket/data/repositories/sync_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

void main() {
  late AppDatabase database;
  late SyncRepository repository;
  late _MockRelayApiClient apiClient;
  late DateTime now;
  late SyncQueueManager manager;

  setUp(() {
    database = AppDatabase.forTesting();
    repository = SyncRepositoryImpl(dao: SyncQueueDao(database));
    apiClient = _MockRelayApiClient();
    now = DateTime.utc(2026, 8, 1, 12);
    manager = SyncQueueManager(
      syncRepository: repository,
      apiClient: apiClient,
      now: () => now,
    );
  });

  tearDown(() => database.close());

  Future<void> enqueue() => manager.enqueue(
    id: 'sync-stable',
    groupId: 'group-1',
    encryptedPayload: 'opaque-ciphertext',
    vectorClock: const {'device-a': 7},
    operationCount: 2,
    keyEpoch: 4,
  );

  void stubFailure(Object error) {
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenThrow(error);
  }

  test('fifth transient failure becomes retained dead letter', () async {
    stubFailure(
      const RelayApiException(statusCode: 503, message: 'server unavailable'),
    );
    await enqueue();

    for (var attempt = 1; attempt <= SyncQueueManager.maxRetries; attempt++) {
      await manager.drainQueue();
      final entry = await repository.getEntry('sync-stable');
      expect(entry, isNotNull);
      expect(entry!.retryCount, attempt);
      if (attempt < SyncQueueManager.maxRetries) {
        expect(entry.state, SyncQueueEntryState.retrying);
        now = entry.nextRetryAt!;
      }
    }

    final retained = await repository.getEntry('sync-stable');
    expect(retained!.state, SyncQueueEntryState.deadLetter);
    expect(retained.failedAt, isNotNull);
    expect(
      await manager.getSummary(),
      const SyncQueueSummary(deadLetterCount: 1),
    );
  });

  test(
    'permanent authorization error becomes dead letter immediately',
    () async {
      stubFailure(
        const RelayApiException(
          statusCode: 403,
          message: 'revoked payload note=private amount=999',
        ),
      );
      await enqueue();

      await manager.drainQueue();

      final entry = await repository.getEntry('sync-stable');
      expect(entry!.state, SyncQueueEntryState.deadLetter);
      expect(entry.retryCount, 1);
      expect(entry.lastErrorCode, SyncQueueErrorCode.authorizationRevoked.name);
      expect(entry.lastErrorCode, isNot(contains('private')));
      expect(entry.lastErrorCode, isNot(contains('999')));
    },
  );

  test(
    'initial permanent push failure is dead-lettered during enqueue',
    () async {
      await manager.enqueue(
        id: 'sync-initial-rejected',
        groupId: 'group-1',
        encryptedPayload: 'opaque-ciphertext',
        vectorClock: const {'device-a': 7},
        operationCount: 2,
        keyEpoch: 4,
        initialFailure: const RelayApiException(
          statusCode: 422,
          message: 'untrusted server detail amount=999',
        ),
      );

      final entry = await repository.getEntry('sync-initial-rejected');
      expect(entry!.state, SyncQueueEntryState.deadLetter);
      expect(entry.retryCount, 1);
      expect(entry.lastErrorCode, SyncQueueErrorCode.invalidRequest.name);
    },
  );

  test('transient retries use persisted exponential backoff', () async {
    stubFailure(
      const RelayApiException(statusCode: 503, message: 'server unavailable'),
    );
    await enqueue();

    await manager.drainQueue();
    final first = await repository.getEntry('sync-stable');
    expect(first!.state, SyncQueueEntryState.retrying);
    expect(first.nextRetryAt, now.add(SyncQueueManager.baseRetryDelay));

    await manager.drainQueue();
    verify(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).called(1);

    now = first.nextRetryAt!;
    await manager.drainQueue();
    final second = await repository.getEntry('sync-stable');
    expect(second!.nextRetryAt, now.add(SyncQueueManager.baseRetryDelay * 2));
  });

  test('dead letters and metadata survive manager restart', () async {
    stubFailure(
      const RelayApiException(statusCode: 422, message: 'invalid operation'),
    );
    await enqueue();
    await manager.drainQueue();

    final restarted = SyncQueueManager(
      syncRepository: SyncRepositoryImpl(dao: SyncQueueDao(database)),
      apiClient: _MockRelayApiClient(),
      now: () => now,
    );

    expect(
      await restarted.getSummary(),
      const SyncQueueSummary(deadLetterCount: 1),
    );
    final entry = (await restarted.getDeadLetters()).single;
    expect(entry.id, 'sync-stable');
    expect(entry.keyEpoch, 4);
    expect(entry.vectorClock, '{"device-a":7}');
  });

  test('withdrawal receipts survive a real SQLCipher queue restart', () async {
    await manager.enqueue(
      id: 'withdrawal-restart',
      groupId: 'group-1',
      encryptedPayload: 'opaque-withdrawal',
      vectorClock: const {'device-a': 10},
      operationCount: 1,
      withdrawalReceipts: const [
        SyncWithdrawalReceipt(entityId: 'tx-private', revision: 10),
      ],
    );
    final persisted = await repository.getEntry('withdrawal-restart');
    expect(persisted!.withdrawalReceipts.single.entityId, 'tx-private');
    expect(persisted.withdrawalReceipts.single.revision, 10);

    final restartedClient = _MockRelayApiClient();
    when(
      () => restartedClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenAnswer((_) async => {'recipientCount': 1});
    final confirmed = <SyncWithdrawalReceipt>[];
    final restarted = SyncQueueManager(
      syncRepository: SyncRepositoryImpl(dao: SyncQueueDao(database)),
      apiClient: restartedClient,
      now: () => now,
      onWithdrawalsDelivered: (receipts) async => confirmed.addAll(receipts),
    );

    expect(await restarted.drainQueue(), 1);
    expect(confirmed.single.entityId, 'tx-private');
    expect(await repository.getEntry('withdrawal-restart'), isNull);
  });

  test(
    'manual retry preserves envelope and deletes only after success',
    () async {
      stubFailure(
        const RelayApiException(
          statusCode: 403,
          message: 'temporarily revoked',
        ),
      );
      await enqueue();
      await manager.drainQueue();

      reset(apiClient);
      when(
        () => apiClient.pushSync(
          groupId: any(named: 'groupId'),
          syncId: any(named: 'syncId'),
          payload: any(named: 'payload'),
          vectorClock: any(named: 'vectorClock'),
          operationCount: any(named: 'operationCount'),
          keyEpoch: any(named: 'keyEpoch'),
        ),
      ).thenAnswer((_) async => {'recipientCount': 1});

      expect(await manager.retryOne('sync-stable'), isTrue);
      verify(
        () => apiClient.pushSync(
          groupId: 'group-1',
          syncId: 'sync-stable',
          payload: 'opaque-ciphertext',
          vectorClock: const {'device-a': 7},
          operationCount: 2,
          keyEpoch: 4,
        ),
      ).called(1);
      expect(await repository.getEntry('sync-stable'), isNull);
    },
  );

  test('discard removes only the explicitly selected entry', () async {
    await manager.enqueue(
      id: 'sync-stable',
      groupId: 'group-1',
      encryptedPayload: 'opaque-ciphertext',
      vectorClock: const {'device-a': 7},
      operationCount: 2,
      keyEpoch: 4,
      initialFailure: const RelayApiException(
        statusCode: 403,
        message: 'revoked',
      ),
    );
    await manager.enqueue(
      id: 'sync-other',
      groupId: 'group-1',
      encryptedPayload: 'ciphertext-2',
      vectorClock: const {},
      operationCount: 1,
    );

    await manager.discard('sync-stable');

    expect(await repository.getEntry('sync-stable'), isNull);
    expect(await repository.getEntry('sync-other'), isNotNull);
  });

  test('discard refuses to remove an entry that is still retryable', () async {
    await enqueue();

    await manager.discard('sync-stable');

    expect(await repository.getEntry('sync-stable'), isNotNull);
  });

  test(
    'epoch transition discards only retired ciphertext for the same group',
    () async {
      await manager.enqueue(
        id: 'retired-group-1',
        groupId: 'group-1',
        encryptedPayload: 'cipher-epoch-4',
        vectorClock: const {},
        operationCount: 1,
        keyEpoch: 4,
      );
      await manager.enqueue(
        id: 'current-group-1',
        groupId: 'group-1',
        encryptedPayload: 'cipher-epoch-5',
        vectorClock: const {},
        operationCount: 1,
        keyEpoch: 5,
      );
      await manager.enqueue(
        id: 'other-group',
        groupId: 'group-2',
        encryptedPayload: 'cipher-other-group',
        vectorClock: const {},
        operationCount: 1,
        keyEpoch: 4,
      );

      expect(
        await manager.discardRetiredEpochCiphertext(
          groupId: 'group-1',
          currentKeyEpoch: 5,
        ),
        1,
      );
      expect(await repository.getEntry('retired-group-1'), isNull);
      expect(await repository.getEntry('current-group-1'), isNotNull);
      expect(await repository.getEntry('other-group'), isNotNull);
    },
  );

  test('epoch cleanup waits for an in-flight queue relay decision', () async {
    await manager.enqueue(
      id: 'in-flight-old-epoch',
      groupId: 'group-1',
      encryptedPayload: 'cipher-epoch-4',
      vectorClock: const {},
      operationCount: 1,
      keyEpoch: 4,
    );
    final relayGate = Completer<void>();
    final events = <String>[];
    when(
      () => apiClient.pushSync(
        groupId: any(named: 'groupId'),
        syncId: any(named: 'syncId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
        keyEpoch: any(named: 'keyEpoch'),
      ),
    ).thenAnswer((_) async {
      events.add('relay-start');
      await relayGate.future;
      events.add('relay-ack');
      return {'recipientCount': 1};
    });

    final drain = manager.drainQueue();
    await Future<void>.delayed(Duration.zero);
    final cleanup = manager
        .discardRetiredEpochCiphertext(groupId: 'group-1', currentKeyEpoch: 5)
        .then((_) => events.add('cleanup-complete'));
    await Future<void>.delayed(Duration.zero);

    expect(events, ['relay-start']);
    relayGate.complete();
    await Future.wait([drain, cleanup]);
    expect(events, ['relay-start', 'relay-ack', 'cleanup-complete']);
    expect(await repository.getEntry('in-flight-old-epoch'), isNull);
  });

  test('retired ciphertext cannot be enqueued after epoch cleanup', () async {
    expect(
      await manager.discardRetiredEpochCiphertext(
        groupId: 'group-1',
        currentKeyEpoch: 5,
      ),
      0,
    );

    await expectLater(
      manager.enqueue(
        id: 'late-old-epoch',
        groupId: 'group-1',
        encryptedPayload: 'cipher-epoch-4',
        vectorClock: const {},
        operationCount: 1,
        keyEpoch: 4,
      ),
      throwsStateError,
    );
    expect(await repository.getEntry('late-old-epoch'), isNull);
  });
}
