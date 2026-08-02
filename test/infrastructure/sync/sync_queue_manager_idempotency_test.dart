import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MemorySyncRepository
    implements SyncRepository, SyncWithdrawalReceiptStore {
  final entries = <SyncQueueEntry>[];
  final receiptsById = <String, List<SyncWithdrawalReceipt>>{};

  @override
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
    int keyEpoch = 1,
  }) async {
    entries.add(
      SyncQueueEntry(
        id: id,
        groupId: groupId,
        encryptedPayload: encryptedPayload,
        vectorClock: vectorClock,
        operationCount: operationCount,
        keyEpoch: keyEpoch,
        retryCount: 0,
        createdAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<void> clearAll() async => entries.clear();

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((entry) => entry.id == id);
    receiptsById.remove(id);
  }

  @override
  Future<List<SyncQueueEntry>> getPending({int limit = 50}) async =>
      entries.take(limit).toList();

  @override
  Future<List<SyncQueueEntry>> getReady({
    required DateTime now,
    int limit = 50,
  }) async => entries
      .where((entry) => entry.state != SyncQueueEntryState.deadLetter)
      .map(_withReceipts)
      .take(limit)
      .toList();

  @override
  Future<SyncQueueEntry?> getEntry(String id) async {
    final entry = entries.where((entry) => entry.id == id).firstOrNull;
    return entry == null ? null : _withReceipts(entry);
  }

  @override
  Future<void> storeWithdrawalReceipts(
    String queueId,
    List<SyncWithdrawalReceipt> receipts,
  ) async {
    receiptsById[queueId] = List.of(receipts);
  }

  SyncQueueEntry _withReceipts(SyncQueueEntry entry) => SyncQueueEntry(
    id: entry.id,
    groupId: entry.groupId,
    encryptedPayload: entry.encryptedPayload,
    vectorClock: entry.vectorClock,
    operationCount: entry.operationCount,
    keyEpoch: entry.keyEpoch,
    withdrawalReceipts: receiptsById[entry.id] ?? const [],
    retryCount: entry.retryCount,
    state: entry.state,
    lastErrorCode: entry.lastErrorCode,
    nextRetryAt: entry.nextRetryAt,
    failedAt: entry.failedAt,
    createdAt: entry.createdAt,
  );

  @override
  Future<List<SyncQueueEntry>> getDeadLetters({int limit = 50}) async => entries
      .where((entry) => entry.state == SyncQueueEntryState.deadLetter)
      .take(limit)
      .toList();

  @override
  Future<int> getPendingCount() async => entries.length;

  @override
  Future<void> markRetrying({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime nextRetryAt,
  }) async {}

  @override
  Future<void> markDeadLetter({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime failedAt,
  }) async {}

  @override
  Future<void> resetForRetry(String id) async {}

  @override
  Future<SyncQueueSummary> getSummary() async =>
      SyncQueueSummary(pendingCount: entries.length);

  @override
  Stream<SyncQueueSummary> watchSummary() =>
      Stream.value(SyncQueueSummary(pendingCount: entries.length));
}

void main() {
  test(
    'queue restart retries with the persisted entry id as sync id',
    () async {
      final repository = _MemorySyncRepository();
      final firstClient = _MockRelayApiClient();
      final firstManager = SyncQueueManager(
        syncRepository: repository,
        apiClient: firstClient,
      );
      await firstManager.enqueue(
        id: 'sync-stable-after-restart',
        groupId: 'group-1',
        encryptedPayload: 'ciphertext',
        vectorClock: const {'device-a': 4},
        operationCount: 2,
        keyEpoch: 3,
      );

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
      final restartedManager = SyncQueueManager(
        syncRepository: repository,
        apiClient: restartedClient,
      );

      expect(await restartedManager.drainQueue(), 1);
      verify(
        () => restartedClient.pushSync(
          groupId: 'group-1',
          syncId: 'sync-stable-after-restart',
          payload: 'ciphertext',
          vectorClock: const {'device-a': 4},
          operationCount: 2,
          keyEpoch: 3,
        ),
      ).called(1);
      expect(repository.entries, isEmpty);
    },
  );

  test(
    'queue restart confirms persisted withdrawal receipt after flush',
    () async {
      final repository = _MemorySyncRepository();
      final firstManager = SyncQueueManager(
        syncRepository: repository,
        apiClient: _MockRelayApiClient(),
      );
      await firstManager.enqueue(
        id: 'withdraw-after-restart',
        groupId: 'group-1',
        encryptedPayload: 'opaque-ciphertext',
        vectorClock: const {'device-a': 10},
        operationCount: 1,
        withdrawalReceipts: const [
          SyncWithdrawalReceipt(entityId: 'tx-private', revision: 10),
        ],
      );

      final delivered = <SyncWithdrawalReceipt>[];
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
      final restartedManager = SyncQueueManager(
        syncRepository: repository,
        apiClient: restartedClient,
        onWithdrawalsDelivered: (receipts) async => delivered.addAll(receipts),
      );

      expect(await restartedManager.drainQueue(), 1);
      expect(delivered, hasLength(1));
      expect(delivered.single.entityId, 'tx-private');
      expect(delivered.single.revision, 10);
      expect(repository.entries, isEmpty);
    },
  );
}
