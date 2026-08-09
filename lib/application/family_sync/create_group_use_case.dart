import 'dart:io';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'device_identity_resolver.dart';
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
    required this._apiClient,
    required KeyManager keyManager,
    required this._groupRepository,
    required this._e2eeService,
    this._onDeviceRegistered,
  }) : _deviceIdentityResolver = DeviceIdentityResolver(keyManager);

  final RelayApiClient _apiClient;
  final DeviceIdentityResolver _deviceIdentityResolver;
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
      final eligibility = await _localEligibility();
      if (eligibility case _CreateBlocked(:final result)) return result;
      return await _createForEligibleGroup(
        currentGroup: (eligibility as _CreateEligible).currentGroup,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        groupName: groupName,
        avatarImageHash: avatarImageHash,
      );
    } on _ExistingOwnerGroupNotRecovered {
      return const CreateGroupResult.error(
        'The existing owner group could not be recovered',
        kind: GroupOperationErrorKind.membershipConflict,
      );
    } on _IncompleteServerGroupResponse catch (error) {
      return CreateGroupResult.error(error.message);
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

  Future<_CreateEligibility> _localEligibility() async {
    try {
      final currentGroup = await _groupRepository.getCurrentGroup();
      if (currentGroup != null && currentGroup.role != 'owner') {
        return const _CreateBlocked(
          CreateGroupResult.error(
            'A family group is already active or awaiting confirmation',
            kind: GroupOperationErrorKind.membershipConflict,
          ),
        );
      }
      return _CreateEligible(currentGroup);
    } on StateError {
      return const _CreateBlocked(
        CreateGroupResult.error(
          'Conflicting local family groups require recovery',
          kind: GroupOperationErrorKind.membershipConflict,
        ),
      );
    }
  }

  Future<CreateGroupResult> _createForEligibleGroup({
    required GroupInfo? currentGroup,
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    required String? avatarImageHash,
  }) async {
    final identity = await _deviceIdentityResolver.resolve();
    if (identity == null) {
      return const CreateGroupResult.error('Device key not initialized');
    }
    await _registerDevice(identity);
    final serverGroup = await _resolveServerGroup(
      currentGroup: currentGroup,
      deviceId: identity.deviceId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      groupName: groupName,
      avatarImageHash: avatarImageHash,
    );
    final authoritativeGroupName = serverGroup.recovered
        ? serverGroup.groupName
        : await _readServerGroupName(serverGroup.groupId) ?? groupName;
    await _persistGroup(
      serverGroup: serverGroup,
      groupName: authoritativeGroupName,
    );
    return CreateGroupResult.success(
      groupId: serverGroup.groupId,
      inviteCode: serverGroup.inviteCode,
      expiresAt: serverGroup.expiresAt,
      groupName: authoritativeGroupName,
    );
  }

  Future<void> _registerDevice(DeviceKeyPair identity) async {
    await _apiClient.registerDevice(
      deviceId: identity.deviceId,
      publicKey: identity.publicKey,
      deviceName: Platform.localHostname,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
    await _onDeviceRegistered?.call();
  }

  Future<_ResolvedServerGroup> _resolveServerGroup({
    required GroupInfo? currentGroup,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    required String? avatarImageHash,
  }) async {
    var recovered = await _recoverExistingOwnerGroup(
      deviceId: deviceId,
      expectedGroupId: currentGroup?.groupId,
    );
    if (currentGroup != null && recovered == null) {
      throw const _ExistingOwnerGroupNotRecovered();
    }
    Map<String, dynamic>? response;
    if (recovered == null) {
      final attempt = await _createOrRecoverAfterTransportFailure(
        deviceId: deviceId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        groupName: groupName,
        avatarImageHash: avatarImageHash,
      );
      response = attempt.response;
      recovered = attempt.recovered;
    }
    final groupId = recovered?.groupId ?? response?['groupId'] as String?;
    final inviteCode =
        recovered?.inviteCode ?? response?['inviteCode'] as String?;
    final expiresAt =
        recovered?.expiresAt ?? (response?['expiresAt'] as num?)?.toInt();
    if (groupId == null || inviteCode == null || expiresAt == null) {
      throw _IncompleteServerGroupResponse(
        groupId: groupId,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    }
    return _ResolvedServerGroup(
      groupId: groupId,
      groupName: recovered?.groupName ?? groupName,
      inviteCode: inviteCode,
      expiresAt: expiresAt,
      recovered: recovered != null,
    );
  }

  Future<_CreateAttempt> _createOrRecoverAfterTransportFailure({
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    required String? avatarImageHash,
  }) async {
    try {
      return _CreateAttempt.response(
        await _apiClient.createGroup(
          groupName: groupName,
          displayName: displayName,
          avatarEmoji: avatarEmoji,
          avatarImageHash: avatarImageHash,
        ),
      );
    } on RelayApiException {
      rethrow;
    } catch (_) {
      // Transport failures are ambiguous: the server may already have
      // committed the request. Resolve the authoritative state first.
      final recovered = await _recoverExistingOwnerGroup(deviceId: deviceId);
      if (recovered == null) rethrow;
      return _CreateAttempt.recovered(recovered);
    }
  }

  Future<void> _persistGroup({
    required _ResolvedServerGroup serverGroup,
    required String groupName,
  }) async {
    final existing = await _groupRepository.getGroupById(serverGroup.groupId);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      serverGroup.expiresAt * 1000,
    );
    if (existing?.status == GroupStatus.active) {
      await _groupRepository.updateInviteCode(
        serverGroup.groupId,
        serverGroup.inviteCode,
        expiresAt,
      );
      if (existing!.groupName != groupName) {
        await _groupRepository.updateGroupName(serverGroup.groupId, groupName);
      }
      return;
    }
    await _groupRepository.savePendingGroup(
      groupId: serverGroup.groupId,
      groupName: groupName,
      inviteCode: serverGroup.inviteCode,
      inviteExpiresAt: expiresAt,
      groupKey: existing?.groupKey?.isNotEmpty == true
          ? existing!.groupKey!
          : _e2eeService.generateGroupKey(),
    );
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
}

class _ExistingGroupNotOwned implements Exception {
  const _ExistingGroupNotOwned();
}

sealed class _CreateEligibility {
  const _CreateEligibility();
}

class _CreateEligible extends _CreateEligibility {
  const _CreateEligible(this.currentGroup);

  final GroupInfo? currentGroup;
}

class _CreateBlocked extends _CreateEligibility {
  const _CreateBlocked(this.result);

  final CreateGroupResult result;
}

class _ExistingOwnerGroupNotRecovered implements Exception {
  const _ExistingOwnerGroupNotRecovered();
}

class _IncompleteServerGroupResponse implements Exception {
  const _IncompleteServerGroupResponse({
    required this.groupId,
    required this.inviteCode,
    required this.expiresAt,
  });

  final String? groupId;
  final String? inviteCode;
  final int? expiresAt;

  String get message =>
      'Server returned incomplete response: '
      'groupId=$groupId, inviteCode=$inviteCode, expiresAt=$expiresAt';
}

class _CreateAttempt {
  const _CreateAttempt.response(this.response) : recovered = null;
  const _CreateAttempt.recovered(this.recovered) : response = null;

  final Map<String, dynamic>? response;
  final _RecoveredOwnerGroup? recovered;
}

class _ResolvedServerGroup {
  const _ResolvedServerGroup({
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    required this.expiresAt,
    required this.recovered,
  });

  final String groupId;
  final String groupName;
  final String inviteCode;
  final int expiresAt;
  final bool recovered;
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
