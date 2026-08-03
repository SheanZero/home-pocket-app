import 'dart:convert';

import '../../features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'apply_sync_operations_use_case.dart';

class InboundSyncRetryResult {
  const InboundSyncRetryResult({
    required this.retriedCount,
    required this.remainingCount,
  });

  final int retriedCount;
  final int remainingCount;
}

class InboundSyncAutomaticResolutionResult {
  const InboundSyncAutomaticResolutionResult({
    required this.retriedCount,
    required this.discardedCount,
    required this.remainingCount,
  });

  final int retriedCount;
  final int discardedCount;
  final int remainingCount;
}

/// Explicit recovery for deterministic inbound operations that were already
/// durably quarantined before their relay messages were ACKed.
class InboundSyncRecoveryUseCase {
  InboundSyncRecoveryUseCase({
    required InboundSyncOperationRepository repository,
    required ApplySyncOperationsUseCase applyOperations,
  }) : _repository = repository,
       _applyOperations = applyOperations;

  final InboundSyncOperationRepository _repository;
  final ApplySyncOperationsUseCase _applyOperations;

  Stream<InboundSyncSummary> watchSummary({required String groupId}) async* {
    await _repository.maintainQuarantine(groupId: groupId);
    yield* _repository.watchSummary(groupId: groupId);
  }

  Stream<List<InboundSyncQuarantineEntry>> watchQuarantined({
    required String groupId,
  }) async* {
    await _repository.maintainQuarantine(groupId: groupId);
    yield* _repository.watchQuarantined(groupId: groupId);
  }

  Future<List<InboundSyncQuarantineEntry>> getQuarantined({
    required String groupId,
  }) async => (await getQuarantinedPage(groupId: groupId)).entries;

  Future<InboundSyncQuarantinePage> getQuarantinedPage({
    required String groupId,
    int offset = 0,
  }) => _repository.getQuarantinedPage(groupId: groupId, offset: offset);

  Future<void> maintain({required String groupId}) =>
      _repository.maintainQuarantine(groupId: groupId);

  /// Resolves quarantined inbound operations without exposing protocol details
  /// or destructive choices to the user.
  ///
  /// Deterministically unsafe input is removed because retrying it cannot make
  /// it valid. Unsupported/unknown operations are retried and remain encrypted
  /// in quarantine when the current app version still cannot apply them.
  Future<InboundSyncAutomaticResolutionResult> resolveAutomatically({
    required String groupId,
  }) async {
    await maintain(groupId: groupId);
    final entries = await _allQuarantined(groupId: groupId);
    var retried = 0;
    var discarded = 0;

    for (final entry in entries) {
      if (!entry.retryable ||
          _isDeterministicallyUnsafe(entry.errorCode) ||
          !_containsOperationObject(entry.operationJson)) {
        await discard(groupId: groupId, operationId: entry.operationId);
        discarded++;
        continue;
      }

      final result = await retryOne(
        groupId: groupId,
        operationId: entry.operationId,
      );
      retried += result.retriedCount;
    }

    final remaining = await _repository.getSummary(groupId: groupId);
    return InboundSyncAutomaticResolutionResult(
      retriedCount: retried,
      discardedCount: discarded,
      remainingCount: remaining.quarantinedCount,
    );
  }

  Future<InboundSyncRetryResult> retryOne({
    required String groupId,
    required String operationId,
  }) async {
    final target = await _repository.findQuarantined(
      groupId: groupId,
      operationId: operationId,
    );
    if (target == null) {
      return InboundSyncRetryResult(
        retriedCount: 0,
        remainingCount: (await _repository.getSummary(
          groupId: groupId,
        )).quarantinedCount,
      );
    }
    if (!target.retryable) {
      return InboundSyncRetryResult(
        retriedCount: 0,
        remainingCount: (await _repository.getSummary(
          groupId: groupId,
        )).quarantinedCount,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(target.operationJson);
    } catch (_) {
      return InboundSyncRetryResult(
        retriedCount: 0,
        remainingCount: (await _repository.getSummary(
          groupId: groupId,
        )).quarantinedCount,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return InboundSyncRetryResult(
        retriedCount: 0,
        remainingCount: (await _repository.getSummary(
          groupId: groupId,
        )).quarantinedCount,
      );
    }

    final result = await _applyOperations.execute([decoded], groupId: groupId);
    final status = result.operations.single.status;
    final retried =
        status == SyncOperationApplyStatus.applied ||
        status == SyncOperationApplyStatus.alreadyApplied;
    return InboundSyncRetryResult(
      retriedCount: retried ? 1 : 0,
      remainingCount: (await _repository.getSummary(
        groupId: groupId,
      )).quarantinedCount,
    );
  }

  Future<InboundSyncRetryResult> retryAll({required String groupId}) async {
    final entries = await _allQuarantined(groupId: groupId);
    var retried = 0;
    for (final entry in entries.where((entry) => entry.retryable)) {
      final result = await retryOne(
        groupId: groupId,
        operationId: entry.operationId,
      );
      retried += result.retriedCount;
    }
    return InboundSyncRetryResult(
      retriedCount: retried,
      remainingCount: (await _repository.getSummary(
        groupId: groupId,
      )).quarantinedCount,
    );
  }

  Future<List<InboundSyncQuarantineEntry>> _allQuarantined({
    required String groupId,
  }) async {
    final entries = <InboundSyncQuarantineEntry>[];
    var offset = 0;
    while (true) {
      final page = await _repository.getQuarantinedPage(
        groupId: groupId,
        offset: offset,
      );
      entries.addAll(page.entries);
      if (!page.hasMore) break;
      offset += page.entries.length;
    }
    return entries;
  }

  Future<void> discard({
    required String groupId,
    required String operationId,
  }) =>
      _repository.discardQuarantine(groupId: groupId, operationId: operationId);

  Future<void> discardAll({required String groupId}) =>
      _repository.discardAllQuarantined(groupId: groupId);

  bool _containsOperationObject(String operationJson) {
    try {
      return jsonDecode(operationJson) is Map<String, dynamic>;
    } catch (_) {
      return false;
    }
  }

  bool _isDeterministicallyUnsafe(String errorCode) {
    return errorCode == 'operation_not_object' ||
        errorCode == 'avatar_validation_failed' ||
        errorCode == 'private_bill_payload' ||
        errorCode == 'missing_bill_sender' ||
        errorCode == 'incomplete_bill_state' ||
        errorCode.startsWith('invalid_');
  }
}
