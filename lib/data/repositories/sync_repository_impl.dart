import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../app_database.dart';
import '../daos/sync_queue_dao.dart';

/// Concrete implementation of [SyncRepository].
class SyncRepositoryImpl
    implements SyncRepository, SyncWithdrawalReceiptStore, SyncEpochQueueStore {
  SyncRepositoryImpl({required SyncQueueDao dao}) : _dao = dao;

  final SyncQueueDao _dao;

  @override
  Future<void> enqueue({
    required String id,
    required String groupId,
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
    int keyEpoch = 1,
  }) async {
    await _dao.insert(
      SyncQueueCompanion.insert(
        id: id,
        groupId: groupId,
        encryptedPayload: encryptedPayload,
        keyEpoch: Value(keyEpoch),
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
  Future<List<SyncQueueEntry>> getReady({
    required DateTime now,
    int limit = 50,
  }) async {
    final rows = await _dao.getReady(now: now, limit: limit);
    return rows.map(_toEntry).toList();
  }

  @override
  Future<SyncQueueEntry?> getEntry(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toEntry(row);
  }

  @override
  Future<List<SyncQueueEntry>> getDeadLetters({int limit = 50}) async {
    final rows = await _dao.getDeadLetters(limit: limit);
    return rows.map(_toEntry).toList();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _dao.deleteById(id);
  }

  @override
  Future<int> deleteRetiredEpochEntries({
    required String groupId,
    required int currentKeyEpoch,
  }) {
    return _dao.deleteRetiredEpochEntries(
      groupId: groupId,
      currentKeyEpoch: currentKeyEpoch,
    );
  }

  @override
  Future<void> storeWithdrawalReceipts(
    String queueId,
    List<SyncWithdrawalReceipt> receipts,
  ) async {
    await _dao.storeWithdrawalReceipts(
      queueId,
      jsonEncode(receipts.map((receipt) => receipt.toJson()).toList()),
    );
  }

  @override
  Future<void> markRetrying({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime nextRetryAt,
  }) async {
    await _dao.markRetrying(
      id: id,
      retryCount: retryCount,
      errorCode: errorCode,
      nextRetryAt: nextRetryAt,
    );
  }

  @override
  Future<void> markDeadLetter({
    required String id,
    required int retryCount,
    required String errorCode,
    required DateTime failedAt,
  }) async {
    await _dao.markDeadLetter(
      id: id,
      retryCount: retryCount,
      errorCode: errorCode,
      failedAt: failedAt,
    );
  }

  @override
  Future<void> resetForRetry(String id) => _dao.resetForRetry(id);

  @override
  Future<void> clearAll() async {
    await _dao.deleteAll();
  }

  @override
  Future<int> getPendingCount() async {
    return _dao.countPending();
  }

  @override
  Future<SyncQueueSummary> getSummary() async {
    final rows = await _dao.watchAll().first;
    return _toSummary(rows);
  }

  @override
  Stream<SyncQueueSummary> watchSummary() {
    return _dao.watchAll().map(_toSummary).distinct();
  }

  SyncQueueSummary _toSummary(List<SyncQueueData> rows) {
    var pending = 0;
    var deadLetters = 0;
    for (final row in rows) {
      if (row.state == 'deadLetter') {
        deadLetters++;
      } else {
        pending++;
      }
    }
    return SyncQueueSummary(
      pendingCount: pending,
      deadLetterCount: deadLetters,
    );
  }

  SyncQueueEntry _toEntry(SyncQueueData data) {
    return SyncQueueEntry(
      id: data.id,
      groupId: data.groupId,
      encryptedPayload: data.encryptedPayload,
      vectorClock: data.vectorClock,
      operationCount: data.operationCount,
      keyEpoch: data.keyEpoch,
      withdrawalReceipts: _decodeWithdrawalReceipts(data.withdrawalReceipts),
      retryCount: data.retryCount,
      state: switch (data.state) {
        'retrying' => SyncQueueEntryState.retrying,
        'deadLetter' => SyncQueueEntryState.deadLetter,
        _ => SyncQueueEntryState.pending,
      },
      lastErrorCode: data.lastErrorCode,
      nextRetryAt: data.nextRetryAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(data.nextRetryAt!, isUtc: true),
      failedAt: data.failedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(data.failedAt!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
    );
  }

  List<SyncWithdrawalReceipt> _decodeWithdrawalReceipts(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final values = jsonDecode(encoded);
      if (values is! List) return const [];
      return values
          .map(SyncWithdrawalReceipt.fromJson)
          .whereType<SyncWithdrawalReceipt>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
