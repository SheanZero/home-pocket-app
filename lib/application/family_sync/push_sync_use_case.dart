import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../features/accounting/domain/models/transaction_family_sync_policy.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'group_operation_error.dart';
import 'sync_vector_clock.dart';

/// Result of pushing sync data.
sealed class PushSyncResult {
  const PushSyncResult();

  const factory PushSyncResult.success(int operationCount) = PushSyncSuccess;
  const factory PushSyncResult.queued(int operationCount) = PushSyncQueued;
  const factory PushSyncResult.noPair() = PushSyncNoPair;
  const factory PushSyncResult.error(String message) = PushSyncError;
}

class PushSyncSuccess extends PushSyncResult {
  const PushSyncSuccess(this.operationCount);
  final int operationCount;
}

class PushSyncQueued extends PushSyncResult {
  const PushSyncQueued(this.operationCount);
  final int operationCount;
}

class PushSyncNoPair extends PushSyncResult {
  const PushSyncNoPair();
}

class PushSyncError extends PushSyncResult {
  const PushSyncError(this.message);
  final String message;
}

/// Pushes local changes to the paired partner via the relay server.
///
/// Flow:
/// 1. Get active pair info
/// 2. Serialize operations to JSON
/// 3. Encrypt with E2EE
/// 4. Push to server (or queue on failure)
class PushSyncUseCase {
  PushSyncUseCase({
    required this._apiClient,
    required this._e2eeService,
    required this._groupRepo,
    required this._queueManager,
  });

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;

  static const _uuid = Uuid();

  /// Push a list of CRDT operations (as JSON-encoded maps).
  Future<PushSyncResult> execute({
    required List<Map<String, dynamic>> operations,
    required Map<String, int> vectorClock,
    String syncType = 'incremental',
    String? expectedGroupId,
    bool enqueueOnFailure = true,
  }) async {
    try {
      final safeOperations = operations
          .where(TransactionFamilySyncPolicy.isSafeOutboundOperation)
          .toList(growable: false);
      if (safeOperations.isEmpty) {
        return const PushSyncResult.success(0);
      }
      final effectiveVectorClock = safeOperations.length == operations.length
          ? vectorClock
          : buildSyncVectorClock(safeOperations);
      final withdrawalReceipts = _withdrawalReceipts(safeOperations);
      final group = await _groupRepo.getActiveGroup();
      if (group == null) return const PushSyncResult.noPair();
      if (expectedGroupId != null && group.groupId != expectedGroupId) {
        return const PushSyncResult.error('Active group changed');
      }
      if (group.groupKey == null) {
        return const PushSyncResult.error('Group key missing');
      }

      // The same non-sensitive id crosses every layer of one logical batch.
      // When offline queueing is enabled it becomes the queue primary key, so
      // timeout/restart retries reuse the server's signed idempotency key.
      final syncId = _uuid.v4();
      final idempotentOperations = safeOperations.indexed.map((entry) {
        final operation = Map<String, dynamic>.of(entry.$2);
        operation.putIfAbsent('operationId', () => '$syncId:${entry.$1}');
        return operation;
      }).toList();
      final payload = jsonEncode({
        'schema': 'home-pocket.sync',
        'version': 1,
        'syncType': syncType,
        'syncId': syncId,
        'operations': idempotentOperations,
        'vectorClock': effectiveVectorClock,
      });

      // E2EE encrypt
      final encryptedPayload = _e2eeService.encryptForGroup(
        plaintext: payload,
        groupKeyBase64: group.groupKey!,
        keyEpoch: group.keyEpoch,
      );

      // Try push to server
      try {
        await _apiClient.pushSync(
          groupId: group.groupId,
          syncId: syncId,
          payload: encryptedPayload,
          vectorClock: effectiveVectorClock,
          operationCount: safeOperations.length,
          keyEpoch: group.keyEpoch,
        );
        if (withdrawalReceipts.isNotEmpty) {
          await _queueManager.confirmWithdrawalReceipts(withdrawalReceipts);
        }
        return PushSyncResult.success(safeOperations.length);
      } catch (error) {
        if (!enqueueOnFailure) {
          // Callers backed by the SQLCipher semantic outbox retry from that
          // source. Creating another ciphertext-only retry row would permit
          // duplicate accumulation and would become stale after key rotation.
          return const PushSyncResult.error('Relay did not accept sync batch');
        }
        // Persist the original logical envelope. The queue manager classifies
        // transient vs. permanent failures without persisting server messages.
        await _queueManager.enqueue(
          id: syncId,
          groupId: group.groupId,
          encryptedPayload: encryptedPayload,
          vectorClock: effectiveVectorClock,
          operationCount: safeOperations.length,
          keyEpoch: group.keyEpoch,
          withdrawalReceipts: withdrawalReceipts,
          initialFailure: error,
        );
        return PushSyncResult.queued(safeOperations.length);
      }
    } catch (e) {
      final failure = groupOperationFailureFrom(
        e,
        fallbackMessage: 'Failed to push family sync data',
      );
      return PushSyncResult.error(failure.message);
    }
  }

  List<SyncWithdrawalReceipt> _withdrawalReceipts(
    List<Map<String, dynamic>> operations,
  ) {
    final receipts = <SyncWithdrawalReceipt>[];
    for (final operation in operations) {
      if (operation['entityType'] != 'bill' || operation['op'] != 'delete') {
        continue;
      }
      final entityId = operation['entityId'];
      final revision = operation['revision'];
      final data = operation['data'];
      if (entityId is String &&
          entityId.isNotEmpty &&
          revision is num &&
          revision.toInt() > 0 &&
          data is Map<String, dynamic> &&
          data['isDeleted'] == true) {
        receipts.add(
          SyncWithdrawalReceipt(entityId: entityId, revision: revision.toInt()),
        );
      }
    }
    return receipts;
  }
}
