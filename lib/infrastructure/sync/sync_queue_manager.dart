import 'dart:convert';

import '../../features/family_sync/domain/repositories/sync_repository.dart';
import 'relay_api_client.dart';

typedef WithdrawalDeliveryCallback =
    Future<void> Function(List<SyncWithdrawalReceipt> receipts);

/// Manages the offline sync queue, draining entries to the relay server.
///
/// Entries are added when a push fails due to network issues.
/// The queue is drained on app resume and after successful pulls.
class SyncQueueManager {
  SyncQueueManager({
    required SyncRepository syncRepository,
    required RelayApiClient apiClient,
    WithdrawalDeliveryCallback? onWithdrawalsDelivered,
    DateTime Function()? now,
  }) : _syncRepository = syncRepository,
       _apiClient = apiClient,
       _onWithdrawalsDelivered = onWithdrawalsDelivered,
       _now = now ?? DateTime.now;

  final SyncRepository _syncRepository;
  final RelayApiClient _apiClient;
  final WithdrawalDeliveryCallback? _onWithdrawalsDelivered;
  final DateTime Function() _now;
  final Map<String, int> _minimumKeyEpochByGroup = {};
  Future<void> _queueMutationTail = Future<void>.value();

  static const maxBatchSize = 50;
  static const maxRetries = 5;
  static const baseRetryDelay = Duration(seconds: 30);
  static const maxRetryDelay = Duration(hours: 1);

  /// Add an entry to the offline queue.
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required Map<String, int> vectorClock,
    required int operationCount,
    int keyEpoch = 1,
    List<SyncWithdrawalReceipt> withdrawalReceipts = const [],
    Object? initialFailure,
  }) => _serializeQueueMutation(() async {
    final minimumEpoch = _minimumKeyEpochByGroup[groupId];
    if (minimumEpoch != null && keyEpoch < minimumEpoch) {
      throw StateError('Cannot queue ciphertext from a retired key epoch');
    }
    await _syncRepository.enqueue(
      id: id,
      groupId: groupId,
      encryptedPayload: encryptedPayload,
      vectorClock: jsonEncode(vectorClock),
      operationCount: operationCount,
      keyEpoch: keyEpoch,
    );
    if (withdrawalReceipts.isNotEmpty &&
        _syncRepository is SyncWithdrawalReceiptStore) {
      await (_syncRepository as SyncWithdrawalReceiptStore)
          .storeWithdrawalReceipts(id, withdrawalReceipts);
    }
    if (initialFailure != null) {
      final entry = await _syncRepository.getEntry(id);
      if (entry != null) await _recordFailure(entry, initialFailure);
    }
  });

  /// Drain the queue by sending pending entries to the server.
  ///
  /// Returns the number of successfully sent entries.
  Future<int> drainQueue() => _serializeQueueMutation(_drainQueue);

  Future<int> _drainQueue() async {
    final entries = await _syncRepository.getReady(
      now: _now(),
      limit: maxBatchSize,
    );
    var sent = 0;

    for (final entry in entries) {
      if (await _attempt(entry)) sent++;
    }

    return sent;
  }

  /// Clear all queued entries (e.g., on unpair).
  Future<void> clearQueue() =>
      _serializeQueueMutation(_syncRepository.clearAll);

  /// Removes ciphertext that the relay can no longer accept after a key epoch
  /// commit, without touching the SQLCipher semantic outbox.
  Future<int> discardRetiredEpochCiphertext({
    required String groupId,
    required int currentKeyEpoch,
  }) {
    final previousFloor = _minimumKeyEpochByGroup[groupId] ?? 0;
    if (currentKeyEpoch > previousFloor) {
      _minimumKeyEpochByGroup[groupId] = currentKeyEpoch;
    }
    return _serializeQueueMutation(() async {
      final repository = _syncRepository;
      if (repository is! SyncEpochQueueStore) return 0;
      return (repository as SyncEpochQueueStore).deleteRetiredEpochEntries(
        groupId: groupId,
        currentKeyEpoch: currentKeyEpoch,
      );
    });
  }

  /// Get number of pending entries in the queue.
  Future<int> getPendingCount() async {
    return _syncRepository.getPendingCount();
  }

  Future<SyncQueueSummary> getSummary() => _syncRepository.getSummary();

  Stream<SyncQueueSummary> watchSummary() => _syncRepository.watchSummary();

  Future<List<SyncQueueEntry>> getDeadLetters({int limit = maxBatchSize}) {
    return _syncRepository.getDeadLetters(limit: limit);
  }

  Future<bool> retryOne(String id) async {
    final existing = await _syncRepository.getEntry(id);
    if (existing == null) return false;
    await _syncRepository.resetForRetry(id);
    final reset = await _syncRepository.getEntry(id);
    return reset != null && await _attempt(reset);
  }

  Future<int> retryAll() async {
    final deadLetters = await _syncRepository.getDeadLetters(limit: 10000);
    var sent = 0;
    for (final entry in deadLetters) {
      if (await retryOne(entry.id)) sent++;
    }
    return sent;
  }

  /// Explicit destructive recovery action. Callers must obtain user consent.
  Future<void> discard(String id) async {
    final entry = await _syncRepository.getEntry(id);
    if (entry?.state != SyncQueueEntryState.deadLetter) return;
    await _syncRepository.deleteEntry(id);
  }

  Future<void> discardAllDeadLetters() async {
    final entries = await _syncRepository.getDeadLetters(limit: 10000);
    for (final entry in entries) {
      await _syncRepository.deleteEntry(entry.id);
    }
  }

  Future<bool> _attempt(SyncQueueEntry entry) async {
    try {
      final vectorClock =
          (jsonDecode(entry.vectorClock) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          );
      await _apiClient.pushSync(
        groupId: entry.groupId,
        syncId: entry.id,
        payload: entry.encryptedPayload,
        vectorClock: vectorClock,
        operationCount: entry.operationCount,
        keyEpoch: entry.keyEpoch,
      );
      await confirmWithdrawalReceipts(entry.withdrawalReceipts);
      await _syncRepository.deleteEntry(entry.id);
      return true;
    } catch (error) {
      await _recordFailure(entry, error);
      return false;
    }
  }

  /// Shared success path for immediate pushes and restarted queue drains.
  /// A callback failure deliberately keeps/retries the queue row: repeating a
  /// stable tombstone is safer than falsely settling local privacy state.
  Future<void> confirmWithdrawalReceipts(
    List<SyncWithdrawalReceipt> receipts,
  ) async {
    if (receipts.isEmpty) return;
    await _onWithdrawalsDelivered?.call(receipts);
  }

  Future<T> _serializeQueueMutation<T>(Future<T> Function() operation) {
    final previous = _queueMutationTail;
    final current = previous.then<T>(
      (_) => operation(),
      onError: (_, _) => operation(),
    );
    _queueMutationTail = current.then<void>((_) {}, onError: (_, _) {});
    return current;
  }

  Future<void> _recordFailure(SyncQueueEntry entry, Object error) async {
    final classification = classifySyncQueueFailure(error);
    final retryCount = entry.retryCount + 1;
    final now = _now().toUtc();
    if (classification.isPermanent || retryCount >= maxRetries) {
      await _syncRepository.markDeadLetter(
        id: entry.id,
        retryCount: retryCount,
        errorCode: classification.code.name,
        failedAt: now,
      );
      return;
    }

    final multiplier = 1 << (retryCount - 1);
    final proposed = baseRetryDelay * multiplier;
    final delay = proposed > maxRetryDelay ? maxRetryDelay : proposed;
    await _syncRepository.markRetrying(
      id: entry.id,
      retryCount: retryCount,
      errorCode: classification.code.name,
      nextRetryAt: now.add(delay),
    );
  }
}

enum SyncQueueErrorCode {
  networkUnavailable,
  requestTimeout,
  rateLimited,
  serverUnavailable,
  authorizationRevoked,
  invalidKeyEpoch,
  invalidRequest,
  protocolRejected,
}

class SyncQueueFailureClassification {
  const SyncQueueFailureClassification({
    required this.code,
    required this.isPermanent,
  });

  final SyncQueueErrorCode code;
  final bool isPermanent;
}

/// Converts arbitrary failures into a fixed, non-sensitive persisted code.
/// Server messages and encrypted payload content never cross this boundary.
SyncQueueFailureClassification classifySyncQueueFailure(Object error) {
  if (error is RelayApiException) {
    if (error.statusCode == 408) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.requestTimeout,
        isPermanent: false,
      );
    }
    if (error.statusCode == 429) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.rateLimited,
        isPermanent: false,
      );
    }
    if (error.statusCode >= 500) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.serverUnavailable,
        isPermanent: false,
      );
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.authorizationRevoked,
        isPermanent: true,
      );
    }
    final normalizedCode = error.code?.toLowerCase() ?? '';
    if (normalizedCode.contains('epoch') || normalizedCode.contains('key')) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.invalidKeyEpoch,
        isPermanent: true,
      );
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const SyncQueueFailureClassification(
        code: SyncQueueErrorCode.invalidRequest,
        isPermanent: true,
      );
    }
    return const SyncQueueFailureClassification(
      code: SyncQueueErrorCode.protocolRejected,
      isPermanent: true,
    );
  }
  return const SyncQueueFailureClassification(
    code: SyncQueueErrorCode.networkUnavailable,
    isPermanent: false,
  );
}
