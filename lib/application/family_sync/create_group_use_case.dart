import 'dart:io';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'group_operation_error.dart';

sealed class CreateGroupResult {
  const CreateGroupResult();

  const factory CreateGroupResult.success({
    required String groupId,
    required String inviteCode,
    required int expiresAt,
    String? groupName,
  }) = CreateGroupSuccess;

  const factory CreateGroupResult.error(
    String message, {
    GroupOperationErrorKind kind,
  }) = CreateGroupError;
}

class CreateGroupSuccess extends CreateGroupResult {
  const CreateGroupSuccess({
    required this.groupId,
    required this.inviteCode,
    required this.expiresAt,
    this.groupName,
  });

  final String groupId;
  final String inviteCode;
  final int expiresAt;
  final String? groupName;
}

class CreateGroupError extends CreateGroupResult
    implements GroupOperationFailure {
  const CreateGroupError(
    this.message, {
    this.kind = GroupOperationErrorKind.general,
  });

  @override
  final String message;
  @override
  final GroupOperationErrorKind kind;
}

/// Creates a new family group with profile information.
///
/// Migrated from `features/family_sync/use_cases/` with added profile fields.
class CreateGroupUseCase {
  CreateGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
    required E2EEService e2eeService,
    Future<void> Function()? onDeviceRegistered,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService,
       _onDeviceRegistered = onDeviceRegistered;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;
  final Future<void> Function()? _onDeviceRegistered;

  Future<CreateGroupResult> execute({
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    String? avatarImageHash,
  }) async {
    try {
      GroupInfo? currentGroup;
      try {
        currentGroup = await _groupRepository.getCurrentGroup();
        if (currentGroup != null && currentGroup.role != 'owner') {
          return const CreateGroupResult.error(
            'A family group is already active or awaiting confirmation',
            kind: GroupOperationErrorKind.membershipConflict,
          );
        }
      } on StateError {
        return const CreateGroupResult.error(
          'Conflicting local family groups require recovery',
          kind: GroupOperationErrorKind.membershipConflict,
        );
      }

      final identity = await _ensureDeviceIdentity();
      if (identity == null) {
        return const CreateGroupResult.error('Device key not initialized');
      }

      await _apiClient.registerDevice(
        deviceId: identity.deviceId,
        publicKey: identity.publicKey,
        deviceName: Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
      await _onDeviceRegistered?.call();

      // A prior create request may have reached the server while its response
      // was lost. Recover that owner group before issuing another mutation.
      var recovered = await _recoverExistingOwnerGroup(
        deviceId: identity.deviceId,
        expectedGroupId: currentGroup?.groupId,
      );
      if (currentGroup != null && recovered == null) {
        return const CreateGroupResult.error(
          'The existing owner group could not be recovered',
          kind: GroupOperationErrorKind.membershipConflict,
        );
      }
      Map<String, dynamic>? response;
      if (recovered == null) {
        try {
          response = await _apiClient.createGroup(
            groupName: groupName,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            avatarImageHash: avatarImageHash,
          );
        } on RelayApiException {
          rethrow;
        } catch (_) {
          // Transport failures are ambiguous: the server may already have
          // committed the request. Resolve the authoritative state first.
          recovered = await _recoverExistingOwnerGroup(
            deviceId: identity.deviceId,
          );
          if (recovered == null) rethrow;
        }
      }

      final groupId = recovered?.groupId ?? response?['groupId'] as String?;
      final inviteCode =
          recovered?.inviteCode ?? response?['inviteCode'] as String?;
      final expiresAt =
          recovered?.expiresAt ?? (response?['expiresAt'] as num?)?.toInt();

      if (groupId == null || inviteCode == null || expiresAt == null) {
        return CreateGroupResult.error(
          'Server returned incomplete response: '
          'groupId=$groupId, inviteCode=$inviteCode, expiresAt=$expiresAt',
        );
      }

      var authoritativeGroupName = recovered?.groupName ?? groupName;
      if (recovered == null) {
        authoritativeGroupName =
            await _readServerGroupName(groupId) ?? groupName;
      }

      final existingLocalGroup = await _groupRepository.getGroupById(groupId);
      final groupKey = existingLocalGroup?.groupKey?.isNotEmpty == true
          ? existingLocalGroup!.groupKey!
          : _e2eeService.generateGroupKey();

      final inviteExpiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
      );
      if (existingLocalGroup?.status == GroupStatus.active) {
        await _groupRepository.updateInviteCode(
          groupId,
          inviteCode,
          inviteExpiresAt,
        );
        if (existingLocalGroup!.groupName != authoritativeGroupName) {
          await _groupRepository.updateGroupName(
            groupId,
            authoritativeGroupName,
          );
        }
      } else {
        await _groupRepository.savePendingGroup(
          groupId: groupId,
          groupName: authoritativeGroupName,
          inviteCode: inviteCode,
          inviteExpiresAt: inviteExpiresAt,
          groupKey: groupKey,
        );
      }

      return CreateGroupResult.success(
        groupId: groupId,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
        groupName: authoritativeGroupName,
      );
    } on _ExistingGroupNotOwned {
      return const CreateGroupResult.error(
        'A family group is already active or awaiting confirmation',
        kind: GroupOperationErrorKind.membershipConflict,
      );
    } on RelayApiException catch (error) {
      if (isSingleGroupConflict(error)) {
        return CreateGroupResult.error(
          error.message,
          kind: GroupOperationErrorKind.membershipConflict,
        );
      }
      return CreateGroupResult.error(error.message);
    } catch (error) {
      final failure = groupOperationFailureFrom(
        error,
        fallbackMessage: 'Failed to create group',
      );
      return CreateGroupResult.error(failure.message, kind: failure.kind);
    }
  }

  Future<_RecoveredOwnerGroup?> _recoverExistingOwnerGroup({
    required String deviceId,
    String? expectedGroupId,
  }) async {
    try {
      final check = await _apiClient.checkGroup();
      if (check['groupExisted'] != true) return null;

      final groupId = check['groupId'] as String?;
      if (groupId == null || groupId.isEmpty) return null;
      if (expectedGroupId != null && groupId != expectedGroupId) return null;

      final status = await _apiClient.getGroupStatus(groupId);
      final rawMembers = status['members'];
      var isOwner = false;
      if (rawMembers is List) {
        for (final rawMember in rawMembers) {
          if (rawMember is Map &&
              rawMember['deviceId'] == deviceId &&
              rawMember['role'] == 'owner') {
            isOwner = true;
            break;
          }
        }
      }
      if (!isOwner) throw const _ExistingGroupNotOwned();

      var inviteCode = status['inviteCode'] as String?;
      var expiresAt = (status['inviteExpiresAt'] as num?)?.toInt();
      if (expectedGroupId != null) {
        final refreshedInvite = await _apiClient.regenerateInvite(groupId);
        inviteCode = refreshedInvite['inviteCode'] as String?;
        expiresAt = (refreshedInvite['expiresAt'] as num?)?.toInt();
      }
      final groupName = status['groupName'] as String?;
      if (inviteCode == null ||
          inviteCode.isEmpty ||
          expiresAt == null ||
          expiresAt <= 0 ||
          groupName == null ||
          groupName.isEmpty) {
        return null;
      }

      return _RecoveredOwnerGroup(
        groupId: groupId,
        groupName: groupName,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    } on _ExistingGroupNotOwned {
      rethrow;
    } catch (_) {
      if (expectedGroupId != null) rethrow;
      return null;
    }
  }

  Future<String?> _readServerGroupName(String groupId) async {
    try {
      final status = await _apiClient.getGroupStatus(groupId);
      final groupName = status['groupName'] as String?;
      return groupName == null || groupName.isEmpty ? null : groupName;
    } catch (_) {
      return null;
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
}

class _ExistingGroupNotOwned implements Exception {
  const _ExistingGroupNotOwned();
}

class _RecoveredOwnerGroup {
  const _RecoveredOwnerGroup({
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    required this.expiresAt,
  });

  final String groupId;
  final String groupName;
  final String inviteCode;
  final int expiresAt;
}
