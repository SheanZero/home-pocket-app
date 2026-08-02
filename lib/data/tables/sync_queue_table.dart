import 'package:drift/drift.dart';

/// Sync queue table — offline queue for pending sync operations.
@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get encryptedPayload => text()(); // base64 encoded
  IntColumn get keyEpoch => integer().withDefault(const Constant(1))();
  TextColumn get vectorClock => text()(); // JSON encoded
  IntColumn get operationCount => integer()();
  // SQLCipher-local delivery receipts for minimal bill tombstones. This is
  // never sent to the relay and contains only entityId + revision.
  TextColumn get withdrawalReceipts => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get nextRetryAt => integer().nullable()();
  IntColumn get failedAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_sync_queue_created', columns: {#createdAt}),
    TableIndex(
      name: 'idx_sync_queue_state_retry',
      columns: {#state, #nextRetryAt},
    ),
  ];
}
