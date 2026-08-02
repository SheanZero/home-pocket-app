import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

class FamilySyncOutboxDao {
  FamilySyncOutboxDao(this._db);

  final AppDatabase _db;

  AppDatabase get attachedDatabase => _db;

  Future<bool> upsertOperation({
    required String groupId,
    required Map<String, dynamic> operation,
  }) async {
    final entityType = operation['entityType'];
    final entityId = operation['entityId'];
    final revisionValue = operation['revision'];
    final operationId = operation['operationId'];
    if (entityType is! String ||
        entityType.isEmpty ||
        entityId is! String ||
        entityId.isEmpty ||
        revisionValue is! num ||
        revisionValue.toInt() <= 0 ||
        operationId is! String ||
        operationId.isEmpty) {
      throw const FormatException('Invalid family sync outbox operation');
    }
    final revision = revisionValue.toInt();
    final isTombstone = operation['op'] == 'delete';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final affected = await _db.customUpdate(
      '''
        INSERT INTO family_sync_outbox (
          operation_id, group_id, entity_type, entity_id, revision,
          operation_json, is_tombstone, attempt_count, last_attempt_at,
          created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, NULL, ?)
        ON CONFLICT(group_id, entity_type, entity_id) DO UPDATE SET
          operation_id = excluded.operation_id,
          revision = excluded.revision,
          operation_json = excluded.operation_json,
          is_tombstone = excluded.is_tombstone,
          attempt_count = 0,
          last_attempt_at = NULL,
          created_at = excluded.created_at
        WHERE excluded.revision > family_sync_outbox.revision
           OR (excluded.revision = family_sync_outbox.revision
               AND excluded.is_tombstone = 1
               AND family_sync_outbox.is_tombstone = 0)
      ''',
      variables: [
        Variable<String>(operationId),
        Variable<String>(groupId),
        Variable<String>(entityType),
        Variable<String>(entityId),
        Variable<int>(revision),
        Variable<String>(jsonEncode(operation)),
        Variable<int>(isTombstone ? 1 : 0),
        Variable<int>(now),
      ],
      updates: {_db.familySyncOutbox},
    );
    return affected == 1;
  }

  Future<List<FamilySyncOutboxData>> getPendingForGroup(
    String groupId, {
    int limit = 50,
  }) {
    final query = _db.select(_db.familySyncOutbox)
      ..where((row) => row.groupId.equals(groupId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.createdAt),
        (row) => OrderingTerm.asc(row.operationId),
      ])
      ..limit(limit);
    return query.get();
  }

  Future<void> markAttempted({
    required String operationId,
    required int revision,
    required int at,
  }) async {
    await _db.customUpdate(
      '''
        UPDATE family_sync_outbox
        SET attempt_count = attempt_count + 1, last_attempt_at = ?
        WHERE operation_id = ? AND revision = ?
      ''',
      variables: [
        Variable<int>(at),
        Variable<String>(operationId),
        Variable<int>(revision),
      ],
      updates: {_db.familySyncOutbox},
    );
  }

  Future<void> deleteExact({
    required String operationId,
    required int revision,
  }) async {
    await _db.customUpdate(
      'DELETE FROM family_sync_outbox '
      'WHERE operation_id = ? AND revision = ?',
      variables: [Variable<String>(operationId), Variable<int>(revision)],
      updates: {_db.familySyncOutbox},
    );
  }

  Future<void> settleCovered({
    required String groupId,
    required String entityType,
    required String entityId,
    required int revision,
    required bool includesTombstone,
  }) async {
    await _db.customUpdate(
      '''
        DELETE FROM family_sync_outbox
        WHERE group_id = ? AND entity_type = ? AND entity_id = ?
          AND (
            revision < ?
            OR (revision = ? AND (is_tombstone = 0 OR ? = 1))
          )
      ''',
      variables: [
        Variable<String>(groupId),
        Variable<String>(entityType),
        Variable<String>(entityId),
        Variable<int>(revision),
        Variable<int>(revision),
        Variable<int>(includesTombstone ? 1 : 0),
      ],
      updates: {_db.familySyncOutbox},
    );
  }

  Future<void> clearGroup(String groupId) async {
    await (_db.delete(
      _db.familySyncOutbox,
    )..where((row) => row.groupId.equals(groupId))).go();
  }
}
