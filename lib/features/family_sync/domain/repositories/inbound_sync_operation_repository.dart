import '../models/inbound_sync_resource_policy.dart';

/// A deterministic inbound operation that could not be applied by this app
/// version. Retryable rows keep bounded raw JSON inside SQLCipher so a later
/// app version can retry them; resource-limit rejections keep only a bounded,
/// non-retryable digest summary and never expose family data in logs or UI.
class InboundSyncQuarantineEntry {
  const InboundSyncQuarantineEntry({
    required this.operationId,
    required this.groupId,
    required this.messageId,
    required this.operationJson,
    required this.errorCode,
    this.retryable = true,
    this.payloadBytes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String operationId;
  final String groupId;
  final String messageId;
  final String operationJson;
  final String errorCode;
  final bool retryable;
  final int payloadBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class InboundSyncSummary {
  const InboundSyncSummary({
    this.quarantinedCount = 0,
    this.quarantinedPayloadBytes = 0,
  });

  final int quarantinedCount;
  final int quarantinedPayloadBytes;
  bool get needsAttention => quarantinedCount > 0;

  @override
  bool operator ==(Object other) =>
      other is InboundSyncSummary &&
      other.quarantinedCount == quarantinedCount &&
      other.quarantinedPayloadBytes == quarantinedPayloadBytes;

  @override
  int get hashCode => Object.hash(quarantinedCount, quarantinedPayloadBytes);
}

class InboundSyncQuarantinePage {
  const InboundSyncQuarantinePage({
    required this.entries,
    required this.hasMore,
  });

  final List<InboundSyncQuarantineEntry> entries;
  final bool hasMore;
}

abstract class InboundSyncOperationRepository {
  Future<bool> isApplied({
    required String groupId,
    required String operationId,
  });

  Future<void> markApplied({
    required String operationId,
    required String groupId,
    required String messageId,
  });

  Future<void> quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String operationJson,
    required String errorCode,
    bool retryable = true,
  });

  Future<List<InboundSyncQuarantineEntry>> getQuarantined({
    required String groupId,
    int limit = 50,
  });

  Future<InboundSyncQuarantinePage> getQuarantinedPage({
    required String groupId,
    int offset = 0,
    int limit = InboundSyncResourcePolicy.quarantinePageSize,
  });

  Future<InboundSyncQuarantineEntry?> findQuarantined({
    required String groupId,
    required String operationId,
  });

  Future<void> discardQuarantine({
    required String groupId,
    required String operationId,
  });

  Future<void> discardAllQuarantined({required String groupId});

  Future<InboundSyncSummary> getSummary({required String groupId});

  Stream<InboundSyncSummary> watchSummary({required String groupId});

  Stream<List<InboundSyncQuarantineEntry>> watchQuarantined({
    required String groupId,
    int limit = 50,
  });

  Future<void> deleteGroupLedger({required String groupId});

  Future<void> maintainQuarantine({required String groupId});
}
