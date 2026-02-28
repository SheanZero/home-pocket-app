import 'package:drift/drift.dart';

/// Sync queue table — offline queue for pending sync operations.
@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get pairId => text()();
  TextColumn get targetDeviceId => text()();
  TextColumn get encryptedPayload => text()(); // base64 encoded
  TextColumn get vectorClock => text()(); // JSON encoded
  IntColumn get operationCount => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_sync_queue_created', columns: {#createdAt}),
  ];
}
