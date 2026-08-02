import '../models/family_sync_outbox_entry.dart';

abstract class FamilySyncOutboxRepository {
  Future<List<FamilySyncOutboxEntry>> getPendingForGroup(
    String groupId, {
    int limit = 50,
  });

  Future<void> markAttempted(
    Iterable<FamilySyncOutboxEntry> entries, {
    required DateTime at,
  });

  /// Removes only the exact revisions accepted by direct push or durable queue.
  Future<void> deleteAccepted(Iterable<FamilySyncOutboxEntry> entries);

  /// Settles outbox rows covered by a successful/queued full-sync chunk.
  /// Newer revisions and same-revision tombstones are preserved.
  Future<void> settleCovered({
    required String groupId,
    required Iterable<Map<String, dynamic>> operations,
  });

  Future<void> clearGroup(String groupId);
}
