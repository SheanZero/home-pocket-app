import 'package:drift/drift.dart';

@DataClassName('GroupMemberData')
class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get deviceId => text()();
  TextColumn get publicKey => text()();
  TextColumn get deviceName => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get avatarEmoji => text().withDefault(const Constant('🏠'))();
  TextColumn get avatarImagePath => text().nullable()();
  TextColumn get avatarImageHash => text().nullable()();
  IntColumn get profileRevision => integer().withDefault(const Constant(0))();
  TextColumn get profileOriginDeviceId =>
      text().withDefault(const Constant(''))();
  TextColumn get profileDigest => text().withDefault(const Constant(''))();
  IntColumn get avatarRevision => integer().withDefault(const Constant(0))();
  TextColumn get avatarOriginDeviceId =>
      text().withDefault(const Constant(''))();
  TextColumn get avatarContentHash => text().withDefault(const Constant(''))();
  IntColumn get joinedAt => integer().nullable()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get removedAt => integer().nullable()();
  TextColumn get removalReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {groupId, deviceId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_group_members_group_id', columns: {#groupId}),
    TableIndex(name: 'idx_group_members_status', columns: {#status}),
  ];
}
