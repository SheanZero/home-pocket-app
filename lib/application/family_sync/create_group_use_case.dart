import 'dart:io';

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class CreateGroupResult {
  const CreateGroupResult();

  const factory CreateGroupResult.success({
    required String groupId,
    required String inviteCode,
    required int expiresAt,
  }) = CreateGroupSuccess;

  const factory CreateGroupResult.error(String message) = CreateGroupError;
}

class CreateGroupSuccess extends CreateGroupResult {
  const CreateGroupSuccess({
    required this.groupId,
    required this.inviteCode,
    required this.expiresAt,
  });

  final String groupId;
  final String inviteCode;
  final int expiresAt;
}

class CreateGroupError extends CreateGroupResult {
  const CreateGroupError(this.message);

  final String message;
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
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;

  Future<CreateGroupResult> execute({
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    String? avatarImageHash,
  }) async {
    try {
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

      final response = await _apiClient.createGroup(
        groupName: groupName,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImageHash: avatarImageHash,
      );

      final groupId = response['groupId'] as String?;
      final inviteCode = response['inviteCode'] as String?;
      final expiresAt = response['expiresAt'] as int?;

      if (groupId == null || inviteCode == null || expiresAt == null) {
        return CreateGroupResult.error(
          'Server returned incomplete response: '
          'groupId=$groupId, inviteCode=$inviteCode, expiresAt=$expiresAt',
        );
      }

      final groupKey = _e2eeService.generateGroupKey();

      await _groupRepository.savePendingGroup(
        groupId: groupId,
        groupName: groupName,
        inviteCode: inviteCode,
        inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
        groupKey: groupKey,
      );

      return CreateGroupResult.success(
        groupId: groupId,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    } on RelayApiException catch (error) {
      return CreateGroupResult.error(error.message);
    } catch (error) {
      return CreateGroupResult.error('Failed to create group: $error');
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
