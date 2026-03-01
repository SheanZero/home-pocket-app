/// Abstract repository interface for sync operations.
abstract class SyncRepository {
  /// Add an entry to the offline sync queue.
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
  });

  /// Get pending queue entries up to [limit].
  Future<List<SyncQueueEntry>> getPending({int limit = 50});

  /// Delete a queue entry by ID (after successful push).
  Future<void> deleteEntry(String id);

  /// Increment retry count for a failed entry.
  Future<void> incrementRetry(String id);

  /// Clear all queue entries (on unpair).
  Future<void> clearAll();
}

/// Represents a single entry in the sync queue.
class SyncQueueEntry {
  SyncQueueEntry({
    required this.id,
    required this.groupId,
    required this.encryptedPayload,
    required this.vectorClock,
    required this.operationCount,
    required this.retryCount,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String encryptedPayload;
  final String vectorClock;
  final int operationCount;
  final int retryCount;
  final DateTime createdAt;

  @Deprecated('Use groupId instead.')
  String get pairId => groupId;

  @Deprecated('targetDeviceId is removed for group fan-out.')
  String get targetDeviceId => '';
}
