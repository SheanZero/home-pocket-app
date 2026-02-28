import 'dart:convert';

import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

/// Result of pulling sync data.
sealed class PullSyncResult {
  const PullSyncResult();

  const factory PullSyncResult.success(int appliedCount) = PullSyncSuccess;
  const factory PullSyncResult.noNewData() = PullSyncNoNewData;
  const factory PullSyncResult.noPair() = PullSyncNoPair;
  const factory PullSyncResult.error(String message) = PullSyncError;
}

class PullSyncSuccess extends PullSyncResult {
  const PullSyncSuccess(this.appliedCount);
  final int appliedCount;
}

class PullSyncNoNewData extends PullSyncResult {
  const PullSyncNoNewData();
}

class PullSyncNoPair extends PullSyncResult {
  const PullSyncNoPair();
}

class PullSyncError extends PullSyncResult {
  const PullSyncError(this.message);
  final String message;
}

/// Callback for applying decrypted sync operations.
typedef ApplyOperationsCallback = Future<void> Function(
    List<Map<String, dynamic>> operations);

/// Pulls pending sync messages from the relay server and applies them.
///
/// Flow:
/// 1. Get active pair info
/// 2. Pull messages since last sync cursor (server timestamp)
/// 3. Decrypt each message
/// 4. Apply operations via callback
/// 5. ACK messages on server (triggers deletion)
/// 6. Update sync cursor using server's createdAt (NOT client clock)
/// 7. Drain offline queue
class PullSyncUseCase {
  PullSyncUseCase({
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required PairRepository pairRepo,
    required SyncQueueManager queueManager,
    required ApplyOperationsCallback applyOperations,
  })  : _apiClient = apiClient,
        _e2eeService = e2eeService,
        _pairRepo = pairRepo,
        _queueManager = queueManager,
        _applyOperations = applyOperations;

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final PairRepository _pairRepo;
  final SyncQueueManager _queueManager;
  final ApplyOperationsCallback _applyOperations;

  Future<PullSyncResult> execute() async {
    try {
      final pair = await _pairRepo.getActivePair();
      if (pair == null) return const PullSyncResult.noPair();

      if (pair.partnerPublicKey == null) {
        return const PullSyncResult.error('Partner public key missing');
      }

      // Use server timestamp as cursor (not client clock)
      final lastSyncCursor = pair.lastSyncAt?.millisecondsSinceEpoch;
      final sinceSeconds =
          lastSyncCursor != null ? lastSyncCursor ~/ 1000 : null;

      // Pull messages from server
      final response = await _apiClient.pullSync(since: sinceSeconds);
      final messages =
          (response['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (messages.isEmpty) return const PullSyncResult.noNewData();

      var appliedCount = 0;
      int? lastServerTimestamp;

      // Decrypt and apply each message
      for (final msg in messages) {
        final payload = msg['payload'] as String;
        final createdAt = msg['createdAt'] as int;

        final plaintext = await _e2eeService.decrypt(
          ciphertext: payload,
          senderPublicKey: pair.partnerPublicKey!,
        );

        final operations =
            (jsonDecode(plaintext) as List).cast<Map<String, dynamic>>();
        await _applyOperations(operations);
        appliedCount += operations.length;
        lastServerTimestamp = createdAt;
      }

      // ACK messages (server physically deletes them)
      final messageIds =
          messages.map((m) => m['messageId'] as String).toList();
      await _apiClient.ackSync(messageIds: messageIds);

      // Update sync cursor using SERVER's createdAt, NOT DateTime.now()
      // This avoids clock skew causing missed messages.
      if (lastServerTimestamp != null) {
        await _pairRepo.updateLastSyncTime(
          DateTime.fromMillisecondsSinceEpoch(lastServerTimestamp * 1000),
        );
      }

      // Drain offline queue
      await _queueManager.drainQueue();

      return PullSyncResult.success(appliedCount);
    } on RelayApiException catch (e) {
      return PullSyncResult.error(e.message);
    } catch (e) {
      return PullSyncResult.error(e.toString());
    }
  }
}
