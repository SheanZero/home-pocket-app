import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'control_snapshot_digest.dart';
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
       _keyManager = keyManager,
       _groupRepository = groupRepository,
       _membershipRotation = membershipRotation,
       _onDeviceRegistered = onDeviceRegistered;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;
  final MembershipRotationCoordinator? _membershipRotation;
  final Future<void> Function()? _onDeviceRegistered;

  Future<CheckGroupResult> execute() async {
    try {
      final identity = await _ensureDeviceIdentity();
      if (identity == null) {
        return const CheckGroupError('Device key not initialized');
      }

      await _apiClient.registerDevice(
        deviceId: identity.deviceId,
        publicKey: identity.publicKey,
        deviceName: Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      await _onDeviceRegistered?.call();

      final checkResult = await _apiClient.checkGroup();
      final groupExisted = checkResult['groupExisted'] as bool? ?? false;
      final membershipStatus = checkResult['membershipStatus'] as String?;
      if (membershipStatus != null &&
          membershipStatus != 'none' &&
          membershipStatus != 'pending' &&
          membershipStatus != 'active') {
        return const CheckGroupError(
          'Server returned an invalid membership status',
        );
      }

      if (membershipStatus == 'none') {
        if (await _membershipRotation?.resumeSelfLeaveIfPending() == true) {
          return const CheckGroupNotInGroup();
        }
        await _deactivateStaleLocalGroup();
        return const CheckGroupNotInGroup();
      }

      // Compatibility with servers deployed before membershipStatus was
      // introduced. New responses are authoritative; only legacy responses
      // fall back to a locally persisted pending request.
      if (membershipStatus == null && !groupExisted) {
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

      final groupId = checkResult['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) {
        return const CheckGroupError('Server returned an invalid group ID');
      }

      var statusResult = await _apiClient.getGroupStatus(groupId);
      if (await _membershipRotation?.recoverFromSnapshot(statusResult) ==
          true) {
        statusResult = await _apiClient.getGroupStatus(groupId);
      }
      final members = (statusResult['members'] as List<dynamic>? ?? const [])
          .map((member) => GroupMember.fromJson(member as Map<String, dynamic>))
          .toList();
      final inviteCode = statusResult['inviteCode'] as String?;
      final inviteExpiresAt = _parseInviteExpiry(
        statusResult['inviteExpiresAt'],
      );

      final localMember = _findLocalMember(
        members: members,
        deviceId: identity.deviceId,
      );
      if (localMember == null) {
        return const CheckGroupError(
          'Server group snapshot missing local member',
        );
      }

      final existingGroup = await _groupRepository.getGroupById(groupId);
      final authoritativeName = statusResult['groupName'] as String? ?? '';
      final authoritativeEpoch =
          (statusResult['keyEpoch'] as num?)?.toInt() ??
          existingGroup?.keyEpoch ??
          1;
      var effectiveGroup = existingGroup;
      if (existingGroup != null) {
        if (existingGroup.status == GroupStatus.active &&
            localMember.status == 'active') {
          final resolvedName = authoritativeName.trim().isEmpty
              ? existingGroup.groupName
              : authoritativeName;
          final revision = (statusResult['revision'] as num?)?.toInt();
          final revisioned = _groupRepository is RevisionedGroupRepository
              ? _groupRepository as RevisionedGroupRepository
              : null;
          final applied = revisioned != null && revision != null
              ? await revisioned.applyRevisionedAuthoritativeSnapshot(
                  groupId: groupId,
                  groupName: resolvedName,
                  role: localMember.role,
                  keyEpoch: authoritativeEpoch,
                  members: members,
                  revision: revision,
                  updatedAt:
                      DateTime.tryParse(
                        statusResult['updatedAt'] as String? ?? '',
                      ) ??
                      DateTime.fromMillisecondsSinceEpoch(0),
                  snapshotDigest: controlSnapshotDigest(
                    groupId: groupId,
                    groupName: resolvedName,
                    role: localMember.role,
                    keyEpoch: authoritativeEpoch,
                    members: members,
                  ),
                )
              : await _groupRepository.applyAuthoritativeSnapshot(
                  groupId: groupId,
                  groupName: resolvedName,
                  role: localMember.role,
                  keyEpoch: authoritativeEpoch,
                  members: members,
                );
          if (!applied && revisioned == null) {
            return const CheckGroupError(
              'Local group changed while applying server snapshot',
            );
          }
          effectiveGroup = existingGroup.copyWith(
            groupName: resolvedName,
            role: localMember.role,
            keyEpoch: authoritativeEpoch,
            groupKey: existingGroup.keyEpoch == authoritativeEpoch
                ? existingGroup.groupKey
                : null,
            members: members,
          );
        } else {
          if (authoritativeName.trim().isNotEmpty) {
            await _groupRepository.updateGroupName(groupId, authoritativeName);
          }
          await _groupRepository.updateMembers(groupId, members);
        }
        if (inviteCode != null && inviteExpiresAt != null) {
          await _groupRepository.updateInviteCode(
            groupId,
            inviteCode,
            inviteExpiresAt,
          );
        }
      } else {
        await _groupRepository.saveConfirmingGroup(
          groupId: groupId,
          groupName: statusResult['groupName'] as String? ?? '',
          members: members,
          role: localMember.role,
          keyEpoch: authoritativeEpoch,
        );
      }

      if (localMember.status != 'active') {
        if (existingGroup?.status == GroupStatus.active) {
          await _groupRepository.markGroupConfirming(groupId);
        }
        return CheckGroupPendingApproval(groupId: groupId);
      }

      final groupKey = effectiveGroup?.groupKey;
      if (groupKey == null || groupKey.isEmpty) {
        if (existingGroup?.status == GroupStatus.active) {
          await _groupRepository.markGroupConfirming(groupId);
        }
        return CheckGroupAwaitingKey(groupId: groupId);
      }

      if (effectiveGroup!.status != GroupStatus.active) {
        await _groupRepository.confirmLocalGroup(groupId);
      }

      return CheckGroupInGroup(groupId: groupId);
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

  Future<void> _deactivateStaleLocalGroup() async {
    final localGroup = await _groupRepository.getCurrentGroup();
    if (localGroup != null) {
      await _groupRepository.deactivateGroup(localGroup.groupId);
    }
  }

  Future<DeviceKeyPair?> _ensureDeviceIdentity() async {
    final existingDeviceId = await _keyManager.getDeviceId();
    final existingPublicKey = await _keyManager.getPublicKey();

    if (existingDeviceId != null && existingPublicKey != null) {
      return DeviceKeyPair(
        publicKey: existingPublicKey,
        deviceId: existingDeviceId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    if (!await _keyManager.hasKeyPair()) {
      return _keyManager.generateDeviceKeyPair();
    }

    return null;
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
