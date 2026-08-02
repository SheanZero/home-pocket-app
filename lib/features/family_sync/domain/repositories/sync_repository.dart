/// Abstract repository interface for sync operations.
abstract class SyncRepository {
  /// Add an entry to the offline sync queue.
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
    int keyEpoch = 1,
  });

  /// Get pending queue entries up to [limit].
  Future<List<SyncQueueEntry>> getPending({int limit = 50});

  /// Get entries whose retry delay has elapsed. Dead letters are excluded.
  Future<List<SyncQueueEntry>> getReady({
    required DateTime now,
    int limit = 50,
  });

  Future<SyncQueueEntry?> getEntry(String id);

  Future<List<SyncQueueEntry>> getDeadLetters({int limit = 50});

  /// Delete a queue entry by ID (after successful push).
  Future<void> deleteEntry(String id);

  Future<void> markRetrying({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime nextRetryAt,
  });

  Future<void> markDeadLetter({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime failedAt,
  });

  Future<void> resetForRetry(String id);

  /// Clear all queue entries (on unpair).
  Future<void> clearAll();

  /// Get the number of pending queue entries.
  Future<int> getPendingCount();

  Future<SyncQueueSummary> getSummary();

  Stream<SyncQueueSummary> watchSummary();
}

/// Optional v30 capability implemented by the SQLCipher-backed repository.
/// Kept separate from [SyncRepository.enqueue] so older in-memory test fakes
/// remain source compatible and simply retain pending withdrawals forever.
abstract interface class SyncWithdrawalReceiptStore {
  Future<void> storeWithdrawalReceipts(
    String queueId,
    List<SyncWithdrawalReceipt> receipts,
  );
}

/// Optional SQLCipher queue capability for key-epoch transitions.
///
/// Retired ciphertext can never be accepted by the relay after an epoch
/// commit. Removing it is safe only because semantic mutations remain in the
/// separate family outbox until an explicit relay acknowledgement.
abstract interface class SyncEpochQueueStore {
  Future<int> deleteRetiredEpochEntries({
    required String groupId,
    required int currentKeyEpoch,
  });
}

class SyncWithdrawalReceipt {
  const SyncWithdrawalReceipt({required this.entityId, required this.revision});

  final String entityId;
  final int revision;

  Map<String, dynamic> toJson() => {'entityId': entityId, 'revision': revision};

  static SyncWithdrawalReceipt? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final entityId = value['entityId'];
    final revision = value['revision'];
    if (entityId is! String ||
        entityId.isEmpty ||
        revision is! num ||
        revision.toInt() <= 0) {
      return null;
    }
    return SyncWithdrawalReceipt(
      entityId: entityId,
      revision: revision.toInt(),
    );
  }
}

enum SyncQueueEntryState { pending, retrying, deadLetter }

class SyncQueueSummary {
  const SyncQueueSummary({this.pendingCount = 0, this.deadLetterCount = 0});

  final int pendingCount;
  final int deadLetterCount;

  bool get needsAttention => deadLetterCount > 0;
  bool get reconcileSuggested => deadLetterCount > 0;

  @override
  bool operator ==(Object other) =>
      other is SyncQueueSummary &&
      other.pendingCount == pendingCount &&
      other.deadLetterCount == deadLetterCount;

  @override
  int get hashCode => Object.hash(pendingCount, deadLetterCount);
}

/// Represents a single entry in the sync queue.
class SyncQueueEntry {
  SyncQueueEntry({
    required this.id,
    required this.groupId,
    required this.encryptedPayload,
    required this.vectorClock,
    required this.operationCount,
    this.keyEpoch = 1,
    this.withdrawalReceipts = const [],
    required this.retryCount,
    this.state = SyncQueueEntryState.pending,
    this.lastErrorCode,
    this.nextRetryAt,
    this.failedAt,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String encryptedPayload;
  final String vectorClock;
  final int operationCount;
  final int keyEpoch;
  final List<SyncWithdrawalReceipt> withdrawalReceipts;
  final int retryCount;
  final SyncQueueEntryState state;
  final String? lastErrorCode;
  final DateTime? nextRetryAt;
  final DateTime? failedAt;
  final DateTime createdAt;

  @Deprecated('Use groupId instead.')
  String get pairId => groupId;

  @Deprecated('targetDeviceId is removed for group fan-out.')
  String get targetDeviceId => '';
}
