import 'package:drift/drift.dart';

@DataClassName('GroupData')
class Groups extends Table {
  TextColumn get groupId => text()();
  TextColumn get status => text()();
  TextColumn get role => text()();
  TextColumn get groupName => text().withDefault(const Constant(''))();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get inviteExpiresAt => integer().nullable()();
  TextColumn get groupKey => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_groups_status', columns: {#status}),
  ];
}
