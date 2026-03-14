import '../models/group_info.dart';
import '../models/group_member.dart';

abstract class GroupRepository {
  Future<void> savePendingGroup({
    required String groupId,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,
  });

  Future<void> saveConfirmingGroup({
    required String groupId,
    required List<GroupMember> members,
  });

  Future<void> activateMember(String groupId, String deviceId);

  Future<void> confirmLocalGroup(String groupId);

  Future<void> storeGroupKey(String groupId, String groupKeyBase64);

  Future<GroupInfo?> getActiveGroup();

  Future<GroupInfo?> getPendingGroup();

  Future<GroupInfo?> getGroupById(String groupId);

  Future<void> updateLastSyncTime(DateTime syncTime);

  Future<void> updateMembers(String groupId, List<GroupMember> members);

  Future<void> updateInviteCode(
    String groupId,
    String inviteCode,
    DateTime expiresAt,
  );

  Future<void> deactivateGroup(String groupId);
}
