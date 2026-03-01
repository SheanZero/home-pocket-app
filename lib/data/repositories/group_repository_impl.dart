import 'package:drift/drift.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../app_database.dart';
import '../daos/group_dao.dart';
import '../daos/group_member_dao.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({
    required GroupDao groupDao,
    required GroupMemberDao memberDao,
  }) : _groupDao = groupDao,
       _memberDao = memberDao;

  final GroupDao _groupDao;
  final GroupMemberDao _memberDao;

  @override
  Future<void> savePendingGroup({
    required String groupId,
    required String bookId,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,
  }) async {
    await _groupDao.insert(
      GroupsCompanion.insert(
        groupId: groupId,
        bookId: bookId,
        status: 'pending',
        role: 'owner',
        inviteCode: Value(inviteCode),
        inviteExpiresAt: Value(inviteExpiresAt.millisecondsSinceEpoch),
        groupKey: Value(groupKey),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> saveConfirmingGroup({
    required String groupId,
    required String bookId,
    required List<GroupMember> members,
  }) async {
    await _groupDao.insert(
      GroupsCompanion.insert(
        groupId: groupId,
        bookId: bookId,
        status: 'confirming',
        role: 'member',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _memberDao.insertAll(_toCompanions(groupId, members));
  }

  @override
  Future<void> activateMember(String groupId, String deviceId) =>
      _memberDao.updateStatus(groupId, deviceId, 'active');

  @override
  Future<void> confirmLocalGroup(String groupId) => _groupDao.updateConfirmedAt(
    groupId,
    DateTime.now().millisecondsSinceEpoch,
  );

  @override
  Future<void> storeGroupKey(String groupId, String groupKeyBase64) =>
      _groupDao.updateGroupKey(groupId, groupKeyBase64);

  @override
  Future<GroupInfo?> getActiveGroup() async {
    final group = await _groupDao.findActive();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getPendingGroup() async {
    final group = await _groupDao.findPending();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getGroupById(String groupId) async {
    final group = await _groupDao.findByGroupId(groupId);
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<void> updateLastSyncTime(DateTime syncTime) async {
    final group = await _groupDao.findActive();
    if (group == null) return;
    await _groupDao.updateLastSyncAt(
      group.groupId,
      syncTime.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> updateMembers(String groupId, List<GroupMember> members) =>
      _memberDao.replaceAll(groupId, _toCompanions(groupId, members));

  @override
  Future<void> updateInviteCode(
    String groupId,
    String inviteCode,
    DateTime expiresAt,
  ) => _groupDao.updateInvite(
    groupId,
    inviteCode,
    expiresAt.millisecondsSinceEpoch,
  );

  @override
  Future<void> deactivateGroup(String groupId) =>
      _groupDao.updateStatus(groupId, 'inactive');

  List<GroupMembersCompanion> _toCompanions(
    String groupId,
    List<GroupMember> members,
  ) {
    return members
        .map(
          (member) => GroupMembersCompanion.insert(
            groupId: groupId,
            deviceId: member.deviceId,
            publicKey: member.publicKey,
            deviceName: member.deviceName,
            role: member.role,
            status: member.status,
          ),
        )
        .toList();
  }

  Future<GroupInfo> _toGroupInfo(GroupData group) async {
    final members = await _memberDao.findByGroupId(group.groupId);
    return GroupInfo(
      groupId: group.groupId,
      bookId: group.bookId,
      status: GroupStatus.values.byName(group.status),
      role: group.role,
      inviteCode: group.inviteCode,
      inviteExpiresAt: group.inviteExpiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.inviteExpiresAt!)
          : null,
      groupKey: group.groupKey,
      members: members
          .map(
            (member) => GroupMember(
              deviceId: member.deviceId,
              publicKey: member.publicKey,
              deviceName: member.deviceName,
              role: member.role,
              status: member.status,
            ),
          )
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(group.createdAt),
      confirmedAt: group.confirmedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.confirmedAt!)
          : null,
      lastSyncAt: group.lastSyncAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.lastSyncAt!)
          : null,
    );
  }
}
