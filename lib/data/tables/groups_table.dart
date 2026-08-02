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
  IntColumn get keyEpoch => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  /// Monotonic server control-plane revision (unrelated to data sync clocks).
  IntColumn get controlRevision => integer().withDefault(const Constant(0))();
  IntColumn get controlUpdatedAt => integer().nullable()();
  TextColumn get controlSnapshotDigest =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {groupId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_groups_status', columns: {#status}),
  ];
}
