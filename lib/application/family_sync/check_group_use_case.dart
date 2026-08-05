import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'control_snapshot_digest.dart';
import 'device_identity_resolver.dart';
import 'group_operation_error.dart';
import 'membership_rotation_coordinator.dart';

sealed class CheckGroupResult {
  const CheckGroupResult();
}

class CheckGroupInGroup extends CheckGroupResult {
  const CheckGroupInGroup({required this.groupId});

  final String groupId;
}

class CheckGroupNotInGroup extends CheckGroupResult {
  const CheckGroupNotInGroup();
}

/// The device has submitted a join request but its server-side member record
/// has not been approved yet.
class CheckGroupPendingApproval extends CheckGroupResult {
  const CheckGroupPendingApproval({required this.groupId});

  final String groupId;
}

/// The server-side member is active, but this device cannot use the group
/// until it has received the owner's E2EE group key.
class CheckGroupAwaitingKey extends CheckGroupResult {
  const CheckGroupAwaitingKey({required this.groupId});

  final String groupId;
}

class CheckGroupError extends CheckGroupResult
    implements GroupOperationFailure {
  const CheckGroupError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

class CheckGroupUseCase {
  CheckGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
    MembershipRotationCoordinator? membershipRotation,
    Future<void> Function()? onDeviceRegistered,
  }) : _apiClient = apiClient,
       _deviceIdentityResolver = DeviceIdentityResolver(keyManager),
       _groupRepository = groupRepository,
       _membershipRotation = membershipRotation,
       _onDeviceRegistered = onDeviceRegistered;

  final RelayApiClient _apiClient;
  final DeviceIdentityResolver _deviceIdentityResolver;
  final GroupRepository _groupRepository;
  final MembershipRotationCoordinator? _membershipRotation;
  final Future<void> Function()? _onDeviceRegistered;

  Future<CheckGroupResult> execute() async {
    try {
      final identity = await _deviceIdentityResolver.resolve();
      if (identity == null) {
        return const CheckGroupError('Device key not initialized');
      }
      await _register(identity);
      return await _checkMembership(identity.deviceId);
    } on _LocalSnapshotRace {
      return const CheckGroupError(
        'Local group changed while applying server snapshot',
      );
    } on RelayApiException catch (error) {
      return CheckGroupError(error.message);
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to check group',
      );
      return CheckGroupError(failure.message, kind: failure.kind);
    }
  }

  Future<void> _register(DeviceKeyPair identity) async {
    await _apiClient.registerDevice(
      deviceId: identity.deviceId,
      publicKey: identity.publicKey,
      deviceName: Platform.localHostname,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    await _onDeviceRegistered?.call();
  }

  Future<CheckGroupResult> _checkMembership(String deviceId) async {
    final checkResult = await _apiClient.checkGroup();
    final membershipStatus = checkResult['membershipStatus'] as String?;
    if (!_isKnownMembershipStatus(membershipStatus)) {
      return const CheckGroupError(
        'Server returned an invalid membership status',
      );
    }
    if (membershipStatus == 'none') return _handleNoMembership();

    // Compatibility with servers deployed before membershipStatus was
    // introduced. New responses are authoritative; only legacy responses
    // fall back to a locally persisted pending request.
    final groupExisted = checkResult['groupExisted'] as bool? ?? false;
    if (membershipStatus == null && !groupExisted) {
      return _handleLegacyNoGroup();
    }

    final groupId = checkResult['groupId'] as String?;
    if (groupId == null || groupId.isEmpty) {
      return const CheckGroupError('Server returned an invalid group ID');
    }
    return _syncMembership(groupId: groupId, deviceId: deviceId);
  }

  bool _isKnownMembershipStatus(String? status) =>
      status == null ||
      status == 'none' ||
      status == 'pending' ||
      status == 'active';

  Future<CheckGroupResult> _handleNoMembership() async {
    if (await _membershipRotation?.resumeSelfLeaveIfPending() == true) {
      return const CheckGroupNotInGroup();
    }
    await _deactivateStaleLocalGroup();
    return const CheckGroupNotInGroup();
  }

  Future<CheckGroupResult> _handleLegacyNoGroup() async {
    if (await _membershipRotation?.resumeSelfLeaveIfPending() == true) {
      return const CheckGroupNotInGroup();
    }
    final pendingGroup = await _groupRepository.getPendingGroup();
    if (pendingGroup?.status == GroupStatus.confirming &&
        pendingGroup?.role == 'member') {
      return CheckGroupPendingApproval(groupId: pendingGroup!.groupId);
    }
    return const CheckGroupNotInGroup();
  }

  Future<CheckGroupResult> _syncMembership({
    required String groupId,
    required String deviceId,
  }) async {
    final statusResult = await _fetchGroupStatus(groupId);
    final members = _membersFrom(statusResult);
    final localMember = _findLocalMember(members: members, deviceId: deviceId);
    if (localMember == null) {
      return const CheckGroupError(
        'Server group snapshot missing local member',
      );
    }

    final existingGroup = await _groupRepository.getGroupById(groupId);
    final snapshot = _GroupMembershipSnapshot(
      groupId: groupId,
      groupName: statusResult['groupName'] as String? ?? '',
      keyEpoch:
          (statusResult['keyEpoch'] as num?)?.toInt() ??
          existingGroup?.keyEpoch ??
          1,
      members: members,
      localMember: localMember,
      inviteCode: statusResult['inviteCode'] as String?,
      inviteExpiresAt: _parseInviteExpiry(statusResult['inviteExpiresAt']),
      revision: (statusResult['revision'] as num?)?.toInt(),
      updatedAt: DateTime.tryParse(statusResult['updatedAt'] as String? ?? ''),
    );
    final effectiveGroup = await _persistSnapshot(
      snapshot: snapshot,
      existingGroup: existingGroup,
    );
    return _membershipResult(
      snapshot: snapshot,
      existingGroup: existingGroup,
      effectiveGroup: effectiveGroup,
    );
  }

  Future<Map<String, dynamic>> _fetchGroupStatus(String groupId) async {
    var status = await _apiClient.getGroupStatus(groupId);
    if (await _membershipRotation?.recoverFromSnapshot(status) == true) {
      status = await _apiClient.getGroupStatus(groupId);
    }
    return status;
  }

  List<GroupMember> _membersFrom(Map<String, dynamic> status) =>
      (status['members'] as List<dynamic>? ?? const [])
          .map((member) => GroupMember.fromJson(member as Map<String, dynamic>))
          .toList();

  Future<GroupInfo?> _persistSnapshot({
    required _GroupMembershipSnapshot snapshot,
    required GroupInfo? existingGroup,
  }) async {
    if (existingGroup == null) {
      await _groupRepository.saveConfirmingGroup(
        groupId: snapshot.groupId,
        groupName: snapshot.groupName,
        members: snapshot.members,
        role: snapshot.localMember.role,
        keyEpoch: snapshot.keyEpoch,
      );
      return null;
    }

    final effectiveGroup = await _updateExistingGroup(
      existingGroup: existingGroup,
      snapshot: snapshot,
    );
    if (snapshot.inviteCode != null && snapshot.inviteExpiresAt != null) {
      await _groupRepository.updateInviteCode(
        snapshot.groupId,
        snapshot.inviteCode!,
        snapshot.inviteExpiresAt!,
      );
    }
    return effectiveGroup;
  }

  Future<GroupInfo> _updateExistingGroup({
    required GroupInfo existingGroup,
    required _GroupMembershipSnapshot snapshot,
  }) async {
    if (existingGroup.status != GroupStatus.active ||
        snapshot.localMember.status != 'active') {
      if (snapshot.groupName.trim().isNotEmpty) {
        await _groupRepository.updateGroupName(
          snapshot.groupId,
          snapshot.groupName,
        );
      }
      await _groupRepository.updateMembers(snapshot.groupId, snapshot.members);
      return existingGroup;
    }

    final resolvedName = snapshot.groupName.trim().isEmpty
        ? existingGroup.groupName
        : snapshot.groupName;
    final applied = await _applyActiveSnapshot(
      snapshot.copyWith(groupName: resolvedName),
    );
    final revisioned = _groupRepository is RevisionedGroupRepository;
    if (!applied && !revisioned) {
      throw const _LocalSnapshotRace();
    }
    return existingGroup.copyWith(
      groupName: resolvedName,
      role: snapshot.localMember.role,
      keyEpoch: snapshot.keyEpoch,
      groupKey: existingGroup.keyEpoch == snapshot.keyEpoch
          ? existingGroup.groupKey
          : null,
      members: snapshot.members,
    );
  }

  Future<bool> _applyActiveSnapshot(_GroupMembershipSnapshot snapshot) async {
    final revisioned = _groupRepository is RevisionedGroupRepository
        ? _groupRepository as RevisionedGroupRepository
        : null;
    if (revisioned != null && snapshot.revision != null) {
      return revisioned.applyRevisionedAuthoritativeSnapshot(
        groupId: snapshot.groupId,
        groupName: snapshot.groupName,
        role: snapshot.localMember.role,
        keyEpoch: snapshot.keyEpoch,
        members: snapshot.members,
        revision: snapshot.revision!,
        updatedAt: snapshot.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        snapshotDigest: controlSnapshotDigest(
          groupId: snapshot.groupId,
          groupName: snapshot.groupName,
          role: snapshot.localMember.role,
          keyEpoch: snapshot.keyEpoch,
          members: snapshot.members,
        ),
      );
    }
    return _groupRepository.applyAuthoritativeSnapshot(
      groupId: snapshot.groupId,
      groupName: snapshot.groupName,
      role: snapshot.localMember.role,
      keyEpoch: snapshot.keyEpoch,
      members: snapshot.members,
    );
  }

  Future<CheckGroupResult> _membershipResult({
    required _GroupMembershipSnapshot snapshot,
    required GroupInfo? existingGroup,
    required GroupInfo? effectiveGroup,
  }) async {
    if (snapshot.localMember.status != 'active') {
      if (existingGroup?.status == GroupStatus.active) {
        await _groupRepository.markGroupConfirming(snapshot.groupId);
      }
      return CheckGroupPendingApproval(groupId: snapshot.groupId);
    }
    if (effectiveGroup?.groupKey case final key? when key.isNotEmpty) {
      if (effectiveGroup!.status != GroupStatus.active) {
        await _groupRepository.confirmLocalGroup(snapshot.groupId);
      }
      return CheckGroupInGroup(groupId: snapshot.groupId);
    }
    if (existingGroup?.status == GroupStatus.active) {
      await _groupRepository.markGroupConfirming(snapshot.groupId);
    }
    return CheckGroupAwaitingKey(groupId: snapshot.groupId);
  }

  Future<void> _deactivateStaleLocalGroup() async {
    final localGroup = await _groupRepository.getCurrentGroup();
    if (localGroup != null) {
      await _groupRepository.deactivateGroup(localGroup.groupId);
    }
  }

  DateTime? _parseInviteExpiry(Object? rawValue) {
    final timestamp = rawValue as int?;
    if (timestamp == null || timestamp <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  GroupMember? _findLocalMember({
    required List<GroupMember> members,
    required String deviceId,
  }) {
    for (final member in members) {
      if (member.deviceId == deviceId) {
        return member;
      }
    }

    return null;
  }
}

class _GroupMembershipSnapshot {
  const _GroupMembershipSnapshot({
    required this.groupId,
    required this.groupName,
    required this.keyEpoch,
    required this.members,
    required this.localMember,
    required this.inviteCode,
    required this.inviteExpiresAt,
    required this.revision,
    required this.updatedAt,
  });

  final String groupId;
  final String groupName;
  final int keyEpoch;
  final List<GroupMember> members;
  final GroupMember localMember;
  final String? inviteCode;
  final DateTime? inviteExpiresAt;
  final int? revision;
  final DateTime? updatedAt;

  _GroupMembershipSnapshot copyWith({String? groupName}) =>
      _GroupMembershipSnapshot(
        groupId: groupId,
        groupName: groupName ?? this.groupName,
        keyEpoch: keyEpoch,
        members: members,
        localMember: localMember,
        inviteCode: inviteCode,
        inviteExpiresAt: inviteExpiresAt,
        revision: revision,
        updatedAt: updatedAt,
      );
}

class _LocalSnapshotRace implements Exception {
  const _LocalSnapshotRace();
}
