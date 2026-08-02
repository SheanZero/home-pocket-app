import '../../features/family_sync/domain/models/family_sync_outbox_entry.dart';
import '../../features/family_sync/domain/repositories/family_sync_outbox_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'push_sync_use_case.dart';
import 'sync_vector_clock.dart';

typedef FamilySyncOutboxOperationMaterializer =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> operation);

enum FamilySyncOutboxFailureDisposition { retry, superseded }

typedef FamilySyncOutboxMaterializationFailureHandler =
    Future<FamilySyncOutboxFailureDisposition> Function(
      FamilySyncOutboxEntry entry,
      Object error,
    );

typedef FamilySyncOutboxEntriesSettledCallback =
    Future<void> Function(Iterable<FamilySyncOutboxEntry> entries);

/// Moves durable plaintext operations from SQLCipher to the relay. The outbox
/// row is removed only after the relay explicitly accepts the batch.
class DrainFamilySyncOutboxUseCase {
  DrainFamilySyncOutboxUseCase({
    required FamilySyncOutboxRepository outboxRepository,
    required GroupRepository groupRepository,
    required PushSyncUseCase pushSync,
    SyncQueueManager? queueManager,
    FamilySyncOutboxOperationMaterializer? operationMaterializer,
    FamilySyncOutboxMaterializationFailureHandler? onMaterializationFailure,
    FamilySyncOutboxEntriesSettledCallback? onEntriesSettled,
  }) : _outboxRepository = outboxRepository,
       _groupRepository = groupRepository,
       _pushSync = pushSync,
       _queueManager = queueManager,
       _operationMaterializer = operationMaterializer,
       _onMaterializationFailure = onMaterializationFailure,
       _onEntriesSettled = onEntriesSettled;

  final FamilySyncOutboxRepository _outboxRepository;
  final GroupRepository _groupRepository;
  final PushSyncUseCase _pushSync;
  final SyncQueueManager? _queueManager;
  final FamilySyncOutboxOperationMaterializer? _operationMaterializer;
  final FamilySyncOutboxMaterializationFailureHandler?
  _onMaterializationFailure;
  final FamilySyncOutboxEntriesSettledCallback? _onEntriesSettled;
  Future<int>? _inFlight;

  Future<int> execute() {
    final existing = _inFlight;
    if (existing != null) return existing;

    late final Future<int> tracked;
    tracked = _drain().whenComplete(() {
      if (identical(_inFlight, tracked)) _inFlight = null;
    });
    _inFlight = tracked;
    return tracked;
  }

  Future<int> _drain() async {
    final group = await _groupRepository.getActiveGroup();
    if (group == null) return 0;
    await _queueManager?.discardRetiredEpochCiphertext(
      groupId: group.groupId,
      currentKeyEpoch: group.keyEpoch,
    );

    var acceptedCount = 0;
    var recoveryPasses = 0;
    while (true) {
      final entries = await _outboxRepository.getPendingForGroup(group.groupId);
      if (entries.isEmpty) return acceptedCount;

      await _outboxRepository.markAttempted(entries, at: DateTime.now());
      final operations = <Map<String, dynamic>>[];
      final materializedEntries = <FamilySyncOutboxEntry>[];
      var hasSupersededEntry = false;
      for (final entry in entries) {
        try {
          operations.add(
            await _operationMaterializer?.call(entry.operation) ??
                entry.operation,
          );
          materializedEntries.add(entry);
        } catch (error) {
          // One local semantic source (currently only an Avatar blob) must not
          // poison unrelated bill/shopping/profile rows. The failed row stays
          // durable and is retried or compensated by its entity-specific
          // recovery owner.
          final disposition = await _handleMaterializationFailure(entry, error);
          hasSupersededEntry =
              hasSupersededEntry ||
              disposition == FamilySyncOutboxFailureDisposition.superseded;
        }
      }
      if (operations.isEmpty) {
        if (hasSupersededEntry && recoveryPasses < 4) {
          recoveryPasses++;
          continue;
        }
        return acceptedCount;
      }
      final result = await _pushSync.execute(
        operations: operations,
        vectorClock: buildSyncVectorClock(operations),
        expectedGroupId: group.groupId,
        enqueueOnFailure: false,
      );
      // The SQLCipher outbox is the semantic source of truth. Ciphertext being
      // queued locally is not a relay acknowledgement and must never settle
      // these rows; otherwise a key-epoch change can make the only remaining
      // copy undecryptable and permanently lose the mutation.
      if (result is! PushSyncSuccess) {
        return acceptedCount;
      }

      // Exact operationId+revision deletion is crash-safe: if a concurrent
      // mutation coalesced a newer revision, this cannot erase it.
      await _outboxRepository.deleteAccepted(materializedEntries);
      acceptedCount += materializedEntries.length;
      await _notifyEntriesSettled(materializedEntries);
      if (hasSupersededEntry && recoveryPasses < 4) {
        recoveryPasses++;
        continue;
      }
      if (entries.length < 50) return acceptedCount;
    }
  }

  Future<FamilySyncOutboxFailureDisposition> _handleMaterializationFailure(
    FamilySyncOutboxEntry entry,
    Object error,
  ) async {
    final handler = _onMaterializationFailure;
    if (handler == null) return FamilySyncOutboxFailureDisposition.retry;
    try {
      return await handler(entry, error);
    } catch (_) {
      // A failed compensating write leaves the original semantic row durable.
      return FamilySyncOutboxFailureDisposition.retry;
    }
  }

  Future<void> _notifyEntriesSettled(
    Iterable<FamilySyncOutboxEntry> entries,
  ) async {
    final callback = _onEntriesSettled;
    if (callback == null) return;
    try {
      await callback(entries);
    } catch (_) {
      // Relay ACK is authoritative. Storage maintenance is independently
      // retried and must not make an already settled semantic row reappear.
    }
  }
}
