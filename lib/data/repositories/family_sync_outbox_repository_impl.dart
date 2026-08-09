import 'dart:convert';

import '../../features/family_sync/domain/models/family_sync_outbox_entry.dart';
import '../../features/family_sync/domain/repositories/family_sync_outbox_repository.dart';
import '../app_database.dart';
import '../daos/family_sync_outbox_dao.dart';

class FamilySyncOutboxRepositoryImpl implements FamilySyncOutboxRepository {
  FamilySyncOutboxRepositoryImpl({required this._dao});

  final FamilySyncOutboxDao _dao;

  @override
  Future<List<FamilySyncOutboxEntry>> getPendingForGroup(
    String groupId, {
    int limit = 50,
  }) async {
    final rows = await _dao.getPendingForGroup(groupId, limit: limit);
    return rows.map(_toModel).toList(growable: false);
  }

  @override
  Future<void> markAttempted(
    Iterable<FamilySyncOutboxEntry> entries, {
    required DateTime at,
  }) async {
    await _dao.attachedDatabase.transaction(() async {
      for (final entry in entries) {
        await _dao.markAttempted(
          operationId: entry.operationId,
          revision: entry.revision,
          at: at.toUtc().millisecondsSinceEpoch,
        );
      }
    });
  }

  @override
  Future<void> deleteAccepted(Iterable<FamilySyncOutboxEntry> entries) async {
    await _dao.attachedDatabase.transaction(() async {
      for (final entry in entries) {
        await _dao.deleteExact(
          operationId: entry.operationId,
          revision: entry.revision,
        );
      }
    });
  }

  @override
  Future<void> settleCovered({
    required String groupId,
    required Iterable<Map<String, dynamic>> operations,
  }) async {
    await _dao.attachedDatabase.transaction(() async {
      for (final operation in operations) {
        final entityType = operation['entityType'];
        final entityId = operation['entityId'];
        final revision = operation['revision'];
        if (entityType is! String ||
            entityType.isEmpty ||
            entityId is! String ||
            entityId.isEmpty ||
            revision is! num ||
            revision.toInt() <= 0) {
          continue;
        }
        await _dao.settleCovered(
          groupId: groupId,
          entityType: entityType,
          entityId: entityId,
          revision: revision.toInt(),
          includesTombstone: operation['op'] == 'delete',
        );
      }
    });
  }

  @override
  Future<void> clearGroup(String groupId) => _dao.clearGroup(groupId);

  FamilySyncOutboxEntry _toModel(FamilySyncOutboxData row) {
    final decoded = jsonDecode(row.operationJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid family sync outbox JSON');
    }
    return FamilySyncOutboxEntry(
      operationId: row.operationId,
      groupId: row.groupId,
      entityType: row.entityType,
      entityId: row.entityId,
      revision: row.revision,
      operation: decoded,
      isTombstone: row.isTombstone,
      attemptCount: row.attemptCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAt,
        isUtc: true,
      ),
      lastAttemptAt: row.lastAttemptAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row.lastAttemptAt!,
              isUtc: true,
            ),
    );
  }
}
