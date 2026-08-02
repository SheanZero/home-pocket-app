import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/family_sync/domain/models/inbound_sync_resource_policy.dart';
import '../../features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import '../app_database.dart';

class InboundSyncOperationDao {
  InboundSyncOperationDao(this._db, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<bool> isApplied({
    required String groupId,
    required String operationId,
  }) async {
    final row =
        await (_db.select(_db.inboundSyncOperations)..where(
              (table) =>
                  table.groupId.equals(groupId) &
                  table.operationId.equals(operationId),
            ))
            .getSingleOrNull();
    return row?.state == 'applied';
  }

  Future<void> markApplied({
    required String operationId,
    required String groupId,
    required String messageId,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _db
        .into(_db.inboundSyncOperations)
        .insertOnConflictUpdate(
          InboundSyncOperationsCompanion.insert(
            operationId: operationId,
            groupId: groupId,
            messageId: messageId,
            state: 'applied',
            operationJson: const Value(null),
            errorCode: const Value(null),
            retryable: const Value(true),
            payloadBytes: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String operationJson,
    required String errorCode,
    bool retryable = true,
  }) async {
    final payloadBytes = utf8.encode(operationJson).length;
    final payloadLimit = retryable
        ? InboundSyncResourcePolicy.maxOperationJsonBytes
        : InboundSyncResourcePolicy.maxSafeSummaryJsonBytes;
    if (payloadBytes > payloadLimit) {
      throw ArgumentError.value(
        payloadBytes,
        'operationJson',
        'quarantine record exceeds its UTF-8 byte limit',
      );
    }
    _requireBounded(
      groupId,
      InboundSyncResourcePolicy.maxGroupIdBytes,
      'groupId',
    );
    _requireBounded(
      operationId,
      InboundSyncResourcePolicy.maxOperationIdBytes,
      'operationId',
    );
    _requireBounded(
      messageId,
      InboundSyncResourcePolicy.maxMessageIdBytes,
      'messageId',
    );
    _requireBounded(
      errorCode,
      InboundSyncResourcePolicy.maxErrorCodeBytes,
      'errorCode',
    );
    final now = _now().toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _deleteExpired(groupId: groupId, now: now);
      final existing =
          await (_db.select(_db.inboundSyncOperations)..where(
                (table) =>
                    table.groupId.equals(groupId) &
                    table.operationId.equals(operationId),
              ))
              .getSingleOrNull();
      if (existing?.state == 'applied') return;
      if (existing?.state == 'quarantined') {
        await _deleteQuarantineRow(groupId: groupId, operationId: operationId);
      }
      await _pruneForInsert(groupId: groupId, incomingBytes: payloadBytes);
      await _db
          .into(_db.inboundSyncOperations)
          .insert(
            InboundSyncOperationsCompanion.insert(
              operationId: operationId,
              groupId: groupId,
              messageId: messageId,
              state: 'quarantined',
              operationJson: Value(operationJson),
              errorCode: Value(errorCode),
              retryable: Value(retryable),
              payloadBytes: Value(payloadBytes),
              createdAt: existing?.createdAt ?? now,
              updatedAt: now,
            ),
          );
    });
  }

  Future<List<InboundSyncOperationData>> getQuarantined({
    required String groupId,
    int limit = 50,
  }) async =>
      (await getQuarantinedPage(groupId: groupId, limit: limit)).entries;

  Future<({List<InboundSyncOperationData> entries, bool hasMore})>
  getQuarantinedPage({
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
        await (_db.select(_db.inboundSyncOperations)
              ..where(
                (table) =>
                    table.groupId.equals(groupId) &
                    table.state.equals('quarantined'),
              )
              ..orderBy([
                (table) => OrderingTerm.desc(table.updatedAt),
                (table) => OrderingTerm.asc(table.operationId),
              ])
              ..limit(safeLimit + 1, offset: safeOffset))
            .get();
    return (
      entries: rows.take(safeLimit).toList(growable: false),
      hasMore: rows.length > safeLimit,
    );
  }

  Future<InboundSyncOperationData?> findQuarantined({
    required String groupId,
    required String operationId,
  }) =>
      (_db.select(_db.inboundSyncOperations)..where(
            (table) =>
                table.groupId.equals(groupId) &
                table.operationId.equals(operationId) &
                table.state.equals('quarantined'),
          ))
          .getSingleOrNull();

  Stream<List<InboundSyncOperationData>> watchQuarantined({
    required String groupId,
    int limit = 50,
  }) =>
      (_db.select(_db.inboundSyncOperations)
            ..where(
              (table) =>
                  table.groupId.equals(groupId) &
                  table.state.equals('quarantined'),
            )
            ..orderBy([
              (table) => OrderingTerm.desc(table.updatedAt),
              (table) => OrderingTerm.asc(table.operationId),
            ])
            ..limit(
              limit.clamp(1, InboundSyncResourcePolicy.quarantinePageSize),
            ))
          .watch();

  Future<InboundSyncSummary> getSummary({required String groupId}) async {
    final row = await _summaryQuery(groupId).getSingle();
    return _readSummary(row);
  }

  Stream<InboundSyncSummary> watchSummary({required String groupId}) =>
      _summaryQuery(groupId).watchSingle().map(_readSummary).distinct();

  Selectable<QueryRow> _summaryQuery(String groupId) => _db.customSelect(
    '''
      SELECT COUNT(*) AS quarantined_count,
             COALESCE(SUM(payload_bytes), 0) AS quarantined_payload_bytes
      FROM inbound_sync_operations
      WHERE group_id = ? AND state = 'quarantined'
    ''',
    variables: [Variable<String>(groupId)],
    readsFrom: {_db.inboundSyncOperations},
  );

  InboundSyncSummary _readSummary(QueryRow row) => InboundSyncSummary(
    quarantinedCount: row.read<int>('quarantined_count'),
    quarantinedPayloadBytes: row.read<int>('quarantined_payload_bytes'),
  );

  Future<void> discardQuarantine({
    required String groupId,
    required String operationId,
  }) async {
    await (_db.delete(_db.inboundSyncOperations)..where(
          (table) =>
              table.groupId.equals(groupId) &
              table.operationId.equals(operationId) &
              table.state.equals('quarantined'),
        ))
        .go();
  }

  Future<void> discardAllQuarantined({required String groupId}) async {
    await (_db.delete(_db.inboundSyncOperations)..where(
          (table) =>
              table.groupId.equals(groupId) & table.state.equals('quarantined'),
        ))
        .go();
  }

  Future<void> deleteGroupLedger({required String groupId}) async {
    await (_db.delete(
      _db.inboundSyncOperations,
    )..where((table) => table.groupId.equals(groupId))).go();
  }

  Future<void> maintainQuarantine({required String groupId}) async {
    final now = _now().toUtc().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _deleteExpired(groupId: groupId, now: now);
      await _pruneForInsert(groupId: groupId, incomingBytes: 0, reserve: false);
    });
  }

  Future<void> _deleteExpired({
    required String groupId,
    required int now,
  }) async {
    final cutoff = now - InboundSyncResourcePolicy.quarantineTtl.inMilliseconds;
    await (_db.delete(_db.inboundSyncOperations)..where(
          (table) =>
              table.groupId.equals(groupId) &
              table.state.equals('quarantined') &
              table.updatedAt.isSmallerThanValue(cutoff),
        ))
        .go();
  }

  Future<void> _pruneForInsert({
    required String groupId,
    required int incomingBytes,
    bool reserve = true,
  }) async {
    final rows =
        await (_db.select(_db.inboundSyncOperations)
              ..where(
                (table) =>
                    table.groupId.equals(groupId) &
                    table.state.equals('quarantined'),
              )
              ..orderBy([
                (table) => OrderingTerm.asc(table.updatedAt),
                (table) => OrderingTerm.asc(table.operationId),
              ]))
            .get();
    var count = rows.length + (reserve ? 1 : 0);
    var bytes =
        rows.fold(0, (sum, row) => sum + row.payloadBytes) + incomingBytes;
    for (final row in rows) {
      if (count <= InboundSyncResourcePolicy.maxQuarantineEntriesPerGroup &&
          bytes <=
              InboundSyncResourcePolicy.maxQuarantinePayloadBytesPerGroup) {
        break;
      }
      await _deleteQuarantineRow(
        groupId: groupId,
        operationId: row.operationId,
      );
      count--;
      bytes -= row.payloadBytes;
    }
  }

  Future<void> _deleteQuarantineRow({
    required String groupId,
    required String operationId,
  }) =>
      (_db.delete(_db.inboundSyncOperations)..where(
            (table) =>
                table.groupId.equals(groupId) &
                table.operationId.equals(operationId) &
                table.state.equals('quarantined'),
          ))
          .go();

  void _requireBounded(String value, int maxBytes, String field) {
    final bytes = utf8.encode(value).length;
    if (bytes > maxBytes) {
      throw ArgumentError.value(bytes, field, 'UTF-8 byte limit exceeded');
    }
  }
}
