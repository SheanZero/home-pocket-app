import 'dart:convert';

import 'package:home_pocket/features/family_sync/domain/models/inbound_sync_resource_policy.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';

/// Non-production fallback used by isolated use-case tests and integrations
/// that construct the application service without a database provider.
class MemoryInboundSyncOperationRepository
    implements InboundSyncOperationRepository {
  final Set<(String, String)> _applied = <(String, String)>{};
  final Map<(String, String), InboundSyncQuarantineEntry> _quarantined = {};

  @override
  Future<bool> isApplied({
    required String groupId,
    required String operationId,
  }) async => _applied.contains((groupId, operationId));

  @override
  Future<void> markApplied({
    required String operationId,
    required String groupId,
    required String messageId,
  }) async {
    final key = (groupId, operationId);
    _applied.add(key);
    _quarantined.remove(key);
  }

  @override
  Future<void> quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String operationJson,
    required String errorCode,
    bool retryable = true,
  }) async {
    final now = DateTime.now().toUtc();
    _cleanupExpired(groupId, now);
    final payloadBytes = utf8.encode(operationJson).length;
    final payloadLimit = retryable
        ? InboundSyncResourcePolicy.maxOperationJsonBytes
        : InboundSyncResourcePolicy.maxSafeSummaryJsonBytes;
    if (payloadBytes > payloadLimit) {
      throw ArgumentError.value(payloadBytes, 'operationJson');
    }
    final key = (groupId, operationId);
    if (_applied.contains(key)) return;
    final existing = _quarantined[key];
    _quarantined[key] = InboundSyncQuarantineEntry(
      operationId: operationId,
      groupId: groupId,
      messageId: messageId,
      operationJson: operationJson,
      errorCode: errorCode,
      retryable: retryable,
      payloadBytes: payloadBytes,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    _prune(groupId);
  }

  @override
  Future<List<InboundSyncQuarantineEntry>> getQuarantined({
    required String groupId,
    int limit = 50,
  }) async =>
      (await getQuarantinedPage(groupId: groupId, limit: limit)).entries;

  @override
  Future<InboundSyncQuarantinePage> getQuarantinedPage({
    required String groupId,
    int offset = 0,
    int limit = InboundSyncResourcePolicy.quarantinePageSize,
  }) async {
    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit.clamp(
      1,
      InboundSyncResourcePolicy.quarantinePageSize,
    );
    final rows =
        _quarantined.values.where((entry) => entry.groupId == groupId).toList()
          ..sort((a, b) {
            final updated = b.updatedAt.compareTo(a.updatedAt);
            return updated != 0
                ? updated
                : a.operationId.compareTo(b.operationId);
          });
    final available = safeOffset >= rows.length
        ? const <InboundSyncQuarantineEntry>[]
        : rows.skip(safeOffset).take(safeLimit + 1).toList();
    return InboundSyncQuarantinePage(
      entries: available.take(safeLimit).toList(growable: false),
      hasMore: available.length > safeLimit,
    );
  }

  @override
  Future<InboundSyncQuarantineEntry?> findQuarantined({
    required String groupId,
    required String operationId,
  }) async => _quarantined[(groupId, operationId)];

  @override
  Future<void> discardQuarantine({
    required String groupId,
    required String operationId,
  }) async {
    _quarantined.remove((groupId, operationId));
  }

  @override
  Future<void> discardAllQuarantined({required String groupId}) async {
    _quarantined.removeWhere((key, _) => key.$1 == groupId);
  }

  @override
  Future<InboundSyncSummary> getSummary({required String groupId}) async =>
      InboundSyncSummary(
        quarantinedCount: _quarantined.values
            .where((entry) => entry.groupId == groupId)
            .length,
        quarantinedPayloadBytes: _quarantined.values
            .where((entry) => entry.groupId == groupId)
            .fold(0, (total, entry) => total + entry.payloadBytes),
      );

  @override
  Stream<InboundSyncSummary> watchSummary({required String groupId}) =>
      Stream.fromFuture(getSummary(groupId: groupId));

  @override
  Stream<List<InboundSyncQuarantineEntry>> watchQuarantined({
    required String groupId,
    int limit = 50,
  }) => Stream.fromFuture(getQuarantined(groupId: groupId, limit: limit));

  @override
  Future<void> deleteGroupLedger({required String groupId}) async {
    _applied.removeWhere((key) => key.$1 == groupId);
    _quarantined.removeWhere((key, _) => key.$1 == groupId);
  }

  @override
  Future<void> maintainQuarantine({required String groupId}) async {
    _cleanupExpired(groupId, DateTime.now().toUtc());
    _prune(groupId);
  }

  void _cleanupExpired(String groupId, DateTime now) {
    final cutoff = now.subtract(InboundSyncResourcePolicy.quarantineTtl);
    _quarantined.removeWhere(
      (_, entry) =>
          entry.groupId == groupId && entry.updatedAt.isBefore(cutoff),
    );
  }

  void _prune(String groupId) {
    final rows =
        _quarantined.entries
            .where((entry) => entry.value.groupId == groupId)
            .toList()
          ..sort((a, b) {
            final updated = a.value.updatedAt.compareTo(b.value.updatedAt);
            return updated != 0
                ? updated
                : a.value.operationId.compareTo(b.value.operationId);
          });
    var count = rows.length;
    var bytes = rows.fold(0, (total, row) => total + row.value.payloadBytes);
    for (final row in rows) {
      if (count <= InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup &&
          bytes <=
              InboundSyncResourcePolicy.maxQuarantinePayloadBytesPerGroup) {
        break;
      }
      _quarantined.remove(row.key);
      count--;
      bytes -= row.value.payloadBytes;
    }
  }
}
