import 'dart:io';

import '../../../infrastructure/crypto/models/device_key_pair.dart';
import '../../../infrastructure/crypto/services/key_manager.dart';
import '../../../infrastructure/sync/relay_api_client.dart';
import '../domain/models/group_member.dart';
import '../domain/repositories/group_repository.dart';

sealed class JoinGroupResult {
  const JoinGroupResult();

  const factory JoinGroupResult.success({
    required String groupId,
    required List<GroupMember> members,
  }) = JoinGroupSuccess;

  const factory JoinGroupResult.error(String message) = JoinGroupError;
}

class JoinGroupSuccess extends JoinGroupResult {
  const JoinGroupSuccess({required this.groupId, required this.members});

  final String groupId;
  final List<GroupMember> members;
}

class JoinGroupError extends JoinGroupResult {
  const JoinGroupError(this.message);

  final String message;
}

class JoinGroupUseCase {
  JoinGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;

  Future<JoinGroupResult> execute(String inviteCode) async {
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

      final response = await _apiClient.joinGroup(inviteCode: inviteCode);
      final groupId = response['groupId'] as String;
      final bookId = response['bookId'] as String;
      final members = (response['members'] as List<dynamic>)
          .map((member) => GroupMember.fromJson(member as Map<String, dynamic>))
          .toList();

      await _groupRepository.saveConfirmingGroup(
        groupId: groupId,
        bookId: bookId,
        members: members,
      );

      return JoinGroupResult.success(groupId: groupId, members: members);
    } on RelayApiException catch (error) {
      if (error.isNotFound) {
        return const JoinGroupResult.error('Invite code not found or expired');
      }
      if (error.isConflict) {
        return const JoinGroupResult.error('Already a member of this group');
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
