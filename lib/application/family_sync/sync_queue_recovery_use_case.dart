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

/// Explicit recovery operations for outbound sync dead letters.
class SyncQueueRecoveryUseCase {
  SyncQueueRecoveryUseCase({required SyncQueueManager queueManager})
    : _queueManager = queueManager;

  final SyncQueueManager _queueManager;

  Stream<SyncQueueSummary> watchSummary() => _queueManager.watchSummary();

  Future<List<SyncQueueEntry>> getDeadLetters() =>
      _queueManager.getDeadLetters();

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
}
