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

  Future<GroupMemberData?> findByGroupAndDevice(
    String groupId,
    String deviceId,
  ) =>
      (select(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) & table.deviceId.equals(deviceId),
          ))
          .getSingleOrNull();

  Stream<List<GroupMemberData>> watchByGroupId(String groupId) => (select(
    groupMembers,
  )..where((table) => table.groupId.equals(groupId))).watch();

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
          .write(
            GroupMembersCompanion(
              displayName: Value(displayName),
              avatarEmoji: Value(avatarEmoji),
              avatarImagePath: Value(avatarImagePath),
              avatarImageHash: Value(avatarImageHash),
            ),
          );

  Future<void> updateMemberIdentity({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
  }) =>
      (update(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) & table.deviceId.equals(deviceId),
          ))
          .write(
            GroupMembersCompanion(
              displayName: Value(displayName),
              avatarEmoji: Value(avatarEmoji),
            ),
          );

  Future<int> updateMemberIdentityVersioned({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required int revision,
    required String originDeviceId,
    required String digest,
  }) =>
      (update(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) &
                table.deviceId.equals(deviceId) &
                table.status.equals('active'),
          ))
          .write(
            GroupMembersCompanion(
              displayName: Value(displayName),
              avatarEmoji: Value(avatarEmoji),
              profileRevision: Value(revision),
              profileOriginDeviceId: Value(originDeviceId),
              profileDigest: Value(digest),
            ),
          );

  Future<int> updateMemberAvatarVersioned({
    required String groupId,
    required String deviceId,
    required String? avatarImagePath,
    required String? avatarImageHash,
    required int revision,
    required String originDeviceId,
    required String contentHash,
  }) =>
      (update(groupMembers)..where(
            (table) =>
                table.groupId.equals(groupId) &
                table.deviceId.equals(deviceId) &
                table.status.equals('active'),
          ))
          .write(
            GroupMembersCompanion(
              avatarImagePath: Value(avatarImagePath),
              avatarImageHash: Value(avatarImageHash),
              avatarRevision: Value(revision),
              avatarOriginDeviceId: Value(originDeviceId),
              avatarContentHash: Value(contentHash),
            ),
          );
}
