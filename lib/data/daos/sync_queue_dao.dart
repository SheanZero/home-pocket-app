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
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  Future<void> deleteById(String id) async {
    await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementRetry(String id) async {
    final entry = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry != null) {
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(id))).write(
        SyncQueueCompanion(retryCount: Value(entry.retryCount + 1)),
      );
    }
  }

  Future<void> deleteAll() async {
    await _db.delete(_db.syncQueue).go();
  }
}
