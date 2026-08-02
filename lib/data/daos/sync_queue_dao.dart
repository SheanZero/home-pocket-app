import 'package:drift/drift.dart';

import '../app_database.dart';

/// Data access object for the SyncQueue table.
class SyncQueueDao {
  SyncQueueDao(this._db);

  final AppDatabase _db;

  Future<void> insert(SyncQueueCompanion entry) async {
    await _db.into(_db.syncQueue).insert(entry);
  }

  /// Get pending queue entries, ordered by creation time, up to [limit].
  Future<List<SyncQueueData>> getPending({int limit = 50}) async {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.state.isNotValue('deadLetter'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<List<SyncQueueData>> getReady({
    required DateTime now,
    int limit = 50,
  }) async {
    final nowMs = now.millisecondsSinceEpoch;
    return (_db.select(_db.syncQueue)
          ..where(
            (t) =>
                t.state.isNotValue('deadLetter') &
                (t.nextRetryAt.isNull() |
                    t.nextRetryAt.isSmallerOrEqualValue(nowMs)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<SyncQueueData?> getById(String id) {
    return (_db.select(
      _db.syncQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<SyncQueueData>> getDeadLetters({int limit = 50}) {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.state.equals('deadLetter'))
          ..orderBy([(t) => OrderingTerm.desc(t.failedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteById(String id) async {
    await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteRetiredEpochEntries({
    required String groupId,
    required int currentKeyEpoch,
  }) {
    return (_db.delete(_db.syncQueue)..where(
          (t) =>
              t.groupId.equals(groupId) &
              t.keyEpoch.isNotValue(currentKeyEpoch),
        ))
        .go();
  }

  Future<void> storeWithdrawalReceipts(String id, String receiptsJson) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(withdrawalReceipts: Value(receiptsJson)),
    );
  }

  Future<void> markRetrying({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime nextRetryAt,
  }) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(retryCount),
        state: const Value('retrying'),
        lastErrorCode: Value(errorCode),
        nextRetryAt: Value(nextRetryAt.millisecondsSinceEpoch),
        failedAt: const Value(null),
      ),
    );
  }

  Future<void> markDeadLetter({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime failedAt,
  }) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(
        retryCount: Value(retryCount),
        state: const Value('deadLetter'),
        lastErrorCode: Value(errorCode),
        nextRetryAt: const Value(null),
        failedAt: Value(failedAt.millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> resetForRetry(String id) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
      const SyncQueueCompanion(
        retryCount: Value(0),
        state: Value('pending'),
        lastErrorCode: Value(null),
        nextRetryAt: Value(null),
        failedAt: Value(null),
      ),
    );
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.syncQueue).go();
  }

  Future<int> countPending() async {
    final countExpr = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)
      ..addColumns([countExpr])
      ..where(_db.syncQueue.state.isNotValue('deadLetter'));
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }

  Stream<List<SyncQueueData>> watchAll() => _db.select(_db.syncQueue).watch();
}
