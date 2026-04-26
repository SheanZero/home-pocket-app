import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

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

class CheckGroupError extends CheckGroupResult {
  const CheckGroupError(this.message);

  final String message;
}

class CheckGroupUseCase {
  CheckGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;

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

      final checkResult = await _apiClient.checkGroup();
      final groupExisted = checkResult['groupExisted'] as bool? ?? false;
      if (!groupExisted) {
        return const CheckGroupNotInGroup();
      }

      final groupId = checkResult['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) {
        return const CheckGroupError('Server returned an invalid group ID');
      }

      final statusResult = await _apiClient.getGroupStatus(groupId);
      final members = (statusResult['members'] as List<dynamic>? ?? const [])
          .map((member) => GroupMember.fromJson(member as Map<String, dynamic>))
          .toList();
      final inviteCode = statusResult['inviteCode'] as String?;
      final inviteExpiresAt = _parseInviteExpiry(
        statusResult['inviteExpiresAt'],
      );

      final localRole = _resolveRole(
        members: members,
        deviceId: identity.deviceId,
      );
      if (localRole == null) {
        return const CheckGroupError(
          'Server group snapshot missing local member',
        );
      }

      final existingGroup = await _groupRepository.getGroupById(groupId);
      if (existingGroup == null) {
        await _groupRepository.restoreActiveGroup(
          groupId: groupId,
          role: localRole,
          inviteCode: inviteCode,
          inviteExpiresAt: inviteExpiresAt,
          groupKey: null,
          members: members,
        );
      } else {
        if (existingGroup.status != GroupStatus.active) {
          await _groupRepository.confirmLocalGroup(groupId);
        }
        await _groupRepository.updateMembers(groupId, members);
        if (inviteCode != null && inviteExpiresAt != null) {
          await _groupRepository.updateInviteCode(
            groupId,
            inviteCode,
            inviteExpiresAt,
          );
        }
      }

      return CheckGroupInGroup(groupId: groupId);
    } on RelayApiException catch (error) {
      return CheckGroupError(error.message);
    } catch (error) {
      return CheckGroupError('Failed to check group: $error');
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

  String? _resolveRole({
    required List<GroupMember> members,
    required String deviceId,
  }) {
    for (final member in members) {
      if (member.deviceId == deviceId) {
        return member.role;
      }
    }

    return null;
  }
}
