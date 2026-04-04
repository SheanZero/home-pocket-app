import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class JoinGroupResult {
  const JoinGroupResult();

  const factory JoinGroupResult.verified({
    required String groupId,
    required String groupName,
    required String ownerDeviceId,
    required String ownerDisplayName,
    required String ownerAvatarEmoji,
    String? ownerAvatarImageHash,
  }) = JoinGroupVerified;

  const factory JoinGroupResult.error(String message) = JoinGroupError;
}

class JoinGroupVerified extends JoinGroupResult {
  const JoinGroupVerified({
    required this.groupId,
    required this.groupName,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.ownerAvatarEmoji,
    this.ownerAvatarImageHash,
  });

  final String groupId;
  final String groupName;
  final String ownerDeviceId;
  final String ownerDisplayName;
  final String ownerAvatarEmoji;
  final String? ownerAvatarImageHash;
}

class JoinGroupError extends JoinGroupResult {
  const JoinGroupError(this.message);

  final String message;
}

/// Verifies a group invite and returns group info for preview.
///
/// This is a verify-only use case: it does NOT save to local DB.
/// The actual DB save happens in [ConfirmJoinUseCase] after user confirms.
///
/// Migrated from `features/family_sync/use_cases/` with verify-only semantics
/// and profile fields.
class JoinGroupUseCase {
  JoinGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
  }) : _apiClient = apiClient,
       _keyManager = keyManager;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;

  Future<JoinGroupResult> execute({
    required String inviteCode,
    required String displayName,
    required String avatarEmoji,
    String? avatarImageHash,
  }) async {
    try {
      final identity = await _ensureDeviceIdentity();
      if (identity == null) {
        return const JoinGroupResult.error('Device key not initialized');
      }

      await _apiClient.registerDevice(
        deviceId: identity.deviceId,
        publicKey: identity.publicKey,
        deviceName: Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      final response = await _apiClient.joinGroup(
        inviteCode: inviteCode,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImageHash: avatarImageHash,
      );

      final groupId = response['groupId'] as String;
      final groupName = response['groupName'] as String? ?? '';
      final members = response['members'] as List<dynamic>;

      // Find the owner member for preview
      final ownerJson = members.cast<Map<String, dynamic>>().firstWhere(
        (member) => member['role'] == 'owner',
        orElse: () => members.first as Map<String, dynamic>,
      );

      return JoinGroupResult.verified(
        groupId: groupId,
        groupName: groupName,
        ownerDeviceId: ownerJson['deviceId'] as String,
        ownerDisplayName: ownerJson['displayName'] as String? ?? '',
        ownerAvatarEmoji: ownerJson['avatarEmoji'] as String? ?? '',
        ownerAvatarImageHash: ownerJson['avatarImageHash'] as String?,
      );
    } on RelayApiException catch (error) {
      if (error.isNotFound) {
        return const JoinGroupResult.error(
          'Invite code not found or expired',
        );
      }
      if (error.isConflict) {
        return const JoinGroupResult.error(
          'Already a member of this group',
        );
      }
      return JoinGroupResult.error(error.message);
    } catch (error) {
      return JoinGroupResult.error('Failed to join group: $error');
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
