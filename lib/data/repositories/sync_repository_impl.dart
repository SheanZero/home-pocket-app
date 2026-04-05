import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../app_database.dart';
import '../daos/sync_queue_dao.dart';

/// Concrete implementation of [SyncRepository].
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({required SyncQueueDao dao}) : _dao = dao;

  final SyncQueueDao _dao;

  @override
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
  }) async {
    await _dao.insert(
      SyncQueueCompanion.insert(
        id: id,
        groupId: groupId,
        encryptedPayload: encryptedPayload,
        vectorClock: vectorClock,
        operationCount: operationCount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<List<SyncQueueEntry>> getPending({int limit = 50}) async {
    final rows = await _dao.getPending(limit: limit);
    return rows.map(_toEntry).toList();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _dao.deleteById(id);
  }

  @override
  Future<void> incrementRetry(String id) async {
    await _dao.incrementRetry(id);
  }

  @override
  Future<void> clearAll() async {
    await _dao.deleteAll();
  }

  @override
  Future<int> getPendingCount() async {
    return _dao.countPending();
  }

  SyncQueueEntry _toEntry(SyncQueueData data) {
    return SyncQueueEntry(
      id: data.id,
      groupId: data.groupId,
      encryptedPayload: data.encryptedPayload,
      vectorClock: data.vectorClock,
      operationCount: data.operationCount,
      retryCount: data.retryCount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
    );
  }
}
