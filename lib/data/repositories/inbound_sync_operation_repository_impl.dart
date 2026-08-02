import '../../features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import '../app_database.dart';
import '../daos/inbound_sync_operation_dao.dart';

class InboundSyncOperationRepositoryImpl
    implements InboundSyncOperationRepository {
  InboundSyncOperationRepositoryImpl({required InboundSyncOperationDao dao})
    : _dao = dao;

  final InboundSyncOperationDao _dao;

  @override
  Future<bool> isApplied({
    required String groupId,
    required String operationId,
  }) => _dao.isApplied(groupId: groupId, operationId: operationId);

  @override
  Future<void> markApplied({
    required String operationId,
    required String groupId,
    required String messageId,
  }) => _dao.markApplied(
    operationId: operationId,
    groupId: groupId,
    messageId: messageId,
  );

  @override
  Future<void> quarantine({
    required String operationId,
    required String groupId,
    required String messageId,
    required String operationJson,
    required String errorCode,
    bool retryable = true,
  }) => _dao.quarantine(
    operationId: operationId,
    groupId: groupId,
    messageId: messageId,
    operationJson: operationJson,
    errorCode: errorCode,
    retryable: retryable,
  );

  @override
  Future<List<InboundSyncQuarantineEntry>> getQuarantined({
    required String groupId,
    int limit = 50,
  }) async {
    final rows = await _dao.getQuarantined(groupId: groupId, limit: limit);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<InboundSyncQuarantinePage> getQuarantinedPage({
    required String groupId,
    int offset = 0,
    int limit = 50,
  }) async {
    final page = await _dao.getQuarantinedPage(
      groupId: groupId,
      offset: offset,
      limit: limit,
    );
    return InboundSyncQuarantinePage(
      entries: page.entries.map(_toDomain).toList(growable: false),
      hasMore: page.hasMore,
    );
  }

  @override
  Future<InboundSyncQuarantineEntry?> findQuarantined({
    required String groupId,
    required String operationId,
  }) async {
    final row = await _dao.findQuarantined(
      groupId: groupId,
      operationId: operationId,
    );
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> discardQuarantine({
    required String groupId,
    required String operationId,
  }) => _dao.discardQuarantine(groupId: groupId, operationId: operationId);

  @override
  Future<void> discardAllQuarantined({required String groupId}) =>
      _dao.discardAllQuarantined(groupId: groupId);

  @override
  Future<InboundSyncSummary> getSummary({required String groupId}) =>
      _dao.getSummary(groupId: groupId);

  @override
  Stream<InboundSyncSummary> watchSummary({required String groupId}) =>
      _dao.watchSummary(groupId: groupId);

  @override
  Stream<List<InboundSyncQuarantineEntry>> watchQuarantined({
    required String groupId,
    int limit = 50,
  }) => _dao
      .watchQuarantined(groupId: groupId, limit: limit)
      .map((rows) => rows.map(_toDomain).toList());

  @override
  Future<void> deleteGroupLedger({required String groupId}) =>
      _dao.deleteGroupLedger(groupId: groupId);

  @override
  Future<void> maintainQuarantine({required String groupId}) =>
      _dao.maintainQuarantine(groupId: groupId);

  InboundSyncQuarantineEntry _toDomain(
    InboundSyncOperationData row,
  ) => InboundSyncQuarantineEntry(
    operationId: row.operationId,
    groupId: row.groupId,
    messageId: row.messageId,
    operationJson: row.operationJson ?? '{}',
    errorCode: row.errorCode ?? 'quarantine_record_corrupt',
    retryable: row.retryable && row.operationJson != null,
    payloadBytes: row.payloadBytes,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
  );
}
