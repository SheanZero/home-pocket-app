import 'dart:convert';

import '../../features/family_sync/domain/repositories/sync_repository.dart';
import 'relay_api_client.dart';

/// Manages the offline sync queue, draining entries to the relay server.
///
/// Entries are added when a push fails due to network issues.
/// The queue is drained on app resume and after successful pulls.
class SyncQueueManager {
  SyncQueueManager({
    required SyncRepository syncRepository,
    required RelayApiClient apiClient,
  }) : _syncRepository = syncRepository,
       _apiClient = apiClient;

  final SyncRepository _syncRepository;
  final RelayApiClient _apiClient;

  static const maxBatchSize = 50;
  static const maxRetries = 5;

  /// Add an entry to the offline queue.
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required Map<String, int> vectorClock,
    required int operationCount,
  }) async {
    await _syncRepository.enqueue(
      id: id,
      groupId: groupId,
      encryptedPayload: encryptedPayload,
      vectorClock: jsonEncode(vectorClock),
      operationCount: operationCount,
    );
  }

  /// Drain the queue by sending pending entries to the server.
  ///
  /// Returns the number of successfully sent entries.
  Future<int> drainQueue() async {
    final entries = await _syncRepository.getPending(limit: maxBatchSize);
    var sent = 0;

    for (final entry in entries) {
      if (entry.retryCount >= maxRetries) {
        await _syncRepository.deleteEntry(entry.id);
        continue;
      }

      try {
        final vectorClock =
            (jsonDecode(entry.vectorClock) as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as int),
            );

        await _apiClient.pushSync(
          groupId: entry.groupId,
          payload: entry.encryptedPayload,
          vectorClock: vectorClock,
          operationCount: entry.operationCount,
        );

        await _syncRepository.deleteEntry(entry.id);
        sent++;
      } on RelayApiException {
        await _syncRepository.incrementRetry(entry.id);
      } catch (_) {
        await _syncRepository.incrementRetry(entry.id);
      }
    }

    return sent;
  }

  /// Clear all queued entries (e.g., on unpair).
  Future<void> clearQueue() async {
    await _syncRepository.clearAll();
  }

  /// Get number of pending entries in the queue.
  Future<int> getPendingCount() async {
    return _syncRepository.getPendingCount();
  }
}
