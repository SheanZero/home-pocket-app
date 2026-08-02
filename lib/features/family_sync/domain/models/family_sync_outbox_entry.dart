class FamilySyncOutboxEntry {
  const FamilySyncOutboxEntry({
    required this.operationId,
    required this.groupId,
    required this.entityType,
    required this.entityId,
    required this.revision,
    required this.operation,
    required this.isTombstone,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttemptAt,
  });

  final String operationId;
  final String groupId;
  final String entityType;
  final String entityId;
  final int revision;
  final Map<String, dynamic> operation;
  final bool isTombstone;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
}
