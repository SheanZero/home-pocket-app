import 'package:drift/drift.dart';

@DataClassName('GroupMemberData')
class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get deviceId => text()();
  TextColumn get publicKey => text()();
  TextColumn get deviceName => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {groupId, deviceId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_group_members_group_id', columns: {#groupId}),
    TableIndex(name: 'idx_group_members_status', columns: {#status}),
  ];
}
