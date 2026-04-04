import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/group_members_table.dart';

part 'group_member_dao.g.dart';

@DriftAccessor(tables: [GroupMembers])
class GroupMemberDao extends DatabaseAccessor<AppDatabase>
    with _$GroupMemberDaoMixin {
  GroupMemberDao(super.db);

  Future<void> insertAll(List<GroupMembersCompanion> entries) async {
    await batch((batch) => batch.insertAll(groupMembers, entries));
  }

  Future<List<GroupMemberData>> findByGroupId(String groupId) => (select(
    groupMembers,
  )..where((table) => table.groupId.equals(groupId))).get();

  Future<void> updateStatus(String groupId, String deviceId, String status) =>
      (update(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) & table.deviceId.equals(deviceId),
          ))
          .write(GroupMembersCompanion(status: Value(status)));

  Future<void> deleteByGroupId(String groupId) => (delete(
    groupMembers,
  )..where((table) => table.groupId.equals(groupId))).go();

  Future<void> replaceAll(
    String groupId,
    List<GroupMembersCompanion> entries,
  ) async {
    await transaction(() async {
      await deleteByGroupId(groupId);
      await insertAll(entries);
    });
  }

  Future<void> updateMemberProfile({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  }) =>
      (update(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) & table.deviceId.equals(deviceId),
          ))
          .write(GroupMembersCompanion(
            displayName: Value(displayName),
            avatarEmoji: Value(avatarEmoji),
            avatarImagePath: Value(avatarImagePath),
            avatarImageHash: Value(avatarImageHash),
          ));
}
