import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

class SyncQueueRecoveryResult {
  const SyncQueueRecoveryResult({
    required this.sentCount,
    required this.summary,
    required this.reconcileSuggested,
  });

  final int sentCount;
  final SyncQueueSummary summary;

  /// Dead-letter recovery can require F-06/F-14 reconciliation. This is a
  /// recommendation only; it never marks reconciliation as completed.
  final bool reconcileSuggested;
}

class SyncQueueAutomaticResolutionResult {
  const SyncQueueAutomaticResolutionResult({
    required this.retriedCount,
    required this.discardedCount,
    required this.summary,
  });

  final int retriedCount;
  final int discardedCount;
  final SyncQueueSummary summary;
}

/// Explicit recovery operations for outbound sync dead letters.
class SyncQueueRecoveryUseCase {
  SyncQueueRecoveryUseCase({required this._queueManager});

  final SyncQueueManager _queueManager;

  Stream<SyncQueueSummary> watchSummary() => _queueManager.watchSummary();

  Future<List<SyncQueueEntry>> getDeadLetters() =>
      _queueManager.getDeadLetters();

  /// Resolves dead letters according to their persisted, non-sensitive error
  /// classification. Transient/unknown failures get another background retry;
  /// requests the relay can never accept are removed from the ciphertext queue.
  /// Their semantic mutations remain in the durable family outbox and can be
  /// rebuilt by the normal reconciliation pipeline.
  Future<SyncQueueAutomaticResolutionResult> resolveAutomatically() async {
    final entries = await _queueManager.getDeadLetters(limit: 10000);
    var retried = 0;
    var discarded = 0;
    for (final entry in entries) {
      if (_isPermanent(entry.lastErrorCode)) {
        await _queueManager.discard(entry.id);
        discarded++;
      } else if (await _queueManager.retryOne(entry.id)) {
        retried++;
      }
    }
    return SyncQueueAutomaticResolutionResult(
      retriedCount: retried,
      discardedCount: discarded,
      summary: await _queueManager.getSummary(),
    );
  }

  Future<SyncQueueRecoveryResult> retryOne(String id) async {
    final existed = (await _queueManager.getDeadLetters(
      limit: 10000,
    )).any((entry) => entry.id == id);
    final sent = await _queueManager.retryOne(id);
    return SyncQueueRecoveryResult(
      sentCount: sent ? 1 : 0,
      summary: await _queueManager.getSummary(),
      reconcileSuggested: existed,
    );
  }

  Future<SyncQueueRecoveryResult> retryAll() async {
    final before = await _queueManager.getSummary();
    final sent = await _queueManager.retryAll();
    return SyncQueueRecoveryResult(
      sentCount: sent,
      summary: await _queueManager.getSummary(),
      reconcileSuggested: before.deadLetterCount > 0,
    );
  }

  Future<void> discard(String id) => _queueManager.discard(id);

  Future<void> discardAll() => _queueManager.discardAllDeadLetters();

  bool _isPermanent(String? errorCode) {
    return errorCode == SyncQueueErrorCode.authorizationRevoked.name ||
        errorCode == SyncQueueErrorCode.invalidKeyEpoch.name ||
        errorCode == SyncQueueErrorCode.invalidRequest.name ||
        errorCode == SyncQueueErrorCode.protocolRejected.name;
  }
}
