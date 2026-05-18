// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_dao.dart';

// ignore_for_file: type=lint
mixin _$GroupMemberDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupMembersTable get groupMembers => attachedDatabase.groupMembers;
  GroupMemberDaoManager get managers => GroupMemberDaoManager(this);
}

class GroupMemberDaoManager {
  final _$GroupMemberDaoMixin _db;
  GroupMemberDaoManager(this._db);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db.attachedDatabase, _db.groupMembers);
}
