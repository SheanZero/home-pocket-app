import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

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
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
  }) : _apiClient = apiClient,
       _e2eeService = e2eeService,
       _groupRepo = groupRepo,
       _queueManager = queueManager;

  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;

  static const _uuid = Uuid();

  /// Push a list of CRDT operations (as JSON-encoded maps).
  Future<PushSyncResult> execute({
    required List<Map<String, dynamic>> operations,
    required Map<String, int> vectorClock,
  }) async {
    try {
      final group = await _groupRepo.getActiveGroup();
      if (group == null) return const PushSyncResult.noPair();
      if (group.groupKey == null) {
        return const PushSyncResult.error('Group key missing');
      }

      // Serialize operations
      final payload = jsonEncode(operations);

      // E2EE encrypt
      final encryptedPayload = _e2eeService.encryptForGroup(
        plaintext: payload,
        groupKeyBase64: group.groupKey!,
      );

      // Try push to server
      try {
        await _apiClient.pushGroupSync(
          groupId: group.groupId,
          payload: encryptedPayload,
          vectorClock: vectorClock,
          operationCount: operations.length,
        );
        return PushSyncResult.success(operations.length);
      } catch (_) {
        // Network failure: queue offline
        await _queueManager.enqueue(
          id: _uuid.v4(),
          groupId: group.groupId,
          encryptedPayload: encryptedPayload,
          vectorClock: vectorClock,
          operationCount: operations.length,
        );
        return PushSyncResult.queued(operations.length);
      }
    } catch (e) {
      return PushSyncResult.error(e.toString());
    }
  }
}
