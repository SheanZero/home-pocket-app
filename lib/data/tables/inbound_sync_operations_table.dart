import 'package:drift/drift.dart';

/// Durable inbound apply ledger and quarantine.
///
/// `operation_json` is populated only for quarantined rows and is protected by
/// the same SQLCipher database encryption as the rest of the family data.
@DataClassName('InboundSyncOperationData')
class InboundSyncOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get groupId => text()();
  TextColumn get messageId => text()();
  TextColumn get state => text()();
  TextColumn get operationJson => text().nullable()();
  TextColumn get errorCode => text().nullable()();
  BoolColumn get retryable => boolean().withDefault(const Constant(true))();
  IntColumn get payloadBytes => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {groupId, operationId};

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_inbound_sync_state_updated',
      columns: {#groupId, #state, #updatedAt},
    ),
    TableIndex(name: 'idx_inbound_sync_group', columns: {#groupId}),
  ];
}
