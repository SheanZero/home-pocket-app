import 'package:drift/drift.dart';

/// SQLCipher-backed source of truth for outbound family transaction changes.
///
/// One row per group/entity is intentional: a newer Lamport revision replaces
/// an older one, while a same-revision tombstone wins over live state.
@DataClassName('FamilySyncOutboxData')
class FamilySyncOutbox extends Table {
  TextColumn get operationId => text()();
  TextColumn get groupId => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get revision => integer()();
  TextColumn get operationJson => text()();
  BoolColumn get isTombstone => boolean().withDefault(const Constant(false))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get lastAttemptAt => integer().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {operationId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, entityType, entityId},
  ];

  List<TableIndex> get customIndices => [
    TableIndex(
      name: 'idx_family_sync_outbox_group_created',
      columns: {#groupId, #createdAt},
    ),
  ];
}
