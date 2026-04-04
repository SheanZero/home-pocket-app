import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash_lib;

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';

/// Handles avatar synchronization between group members via E2EE.
///
/// Two operations:
/// 1. [pushAvatarToMembers] - reads local profile, encrypts avatar with
///    group key, and pushes to all members via sync
/// 2. [handleAvatarSync] - receives avatar data from a member, verifies
///    SHA-256 integrity, saves to local file, and updates member profile
class SyncAvatarUseCase {
  SyncAvatarUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required UserProfileRepository userProfileRepository,
    required E2EEService e2eeService,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _userProfileRepository = userProfileRepository,
       _e2eeService = e2eeService;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final UserProfileRepository _userProfileRepository;
  final E2EEService _e2eeService;

  /// Reads local profile avatar, encrypts with group key, and pushes via sync.
  ///
  /// Does nothing if:
  /// - Profile is not found
  /// - Profile has no avatar image
  /// - Group or group key is not available
  Future<void> pushAvatarToMembers({required String groupId}) async {
    final profile = await _userProfileRepository.find();
    if (profile == null || profile.avatarImagePath == null) {
      return;
    }

    final group = await _groupRepository.getGroupById(groupId);
    if (group?.groupKey == null) {
      return;
    }

    final avatarFile = File(profile.avatarImagePath!);
    if (!avatarFile.existsSync()) {
      return;
    }

    final avatarBytes = await avatarFile.readAsBytes();
    final avatarHash = hash_lib.sha256.convert(avatarBytes).toString();

    final payload = jsonEncode({
      'type': 'avatar_sync',
      'displayName': profile.displayName,
      'avatarEmoji': profile.avatarEmoji,
      'avatarImageBase64': base64Encode(avatarBytes),
      'avatarImageHash': avatarHash,
    });

    // encryptForGroup is SYNCHRONOUS - do NOT await
    final encrypted = _e2eeService.encryptForGroup(
      plaintext: payload,
      groupKeyBase64: group!.groupKey!,
    );

    await _apiClient.pushSync(
      groupId: groupId,
      payload: encrypted,
      vectorClock: const {},
      operationCount: 0,
    );
  }

  /// Receives avatar data from a member, verifies integrity, and saves locally.
  ///
  /// [appDirectory] is the app documents directory path. Pass it explicitly
  /// to enable testability (production code uses `getApplicationDocumentsDirectory()`).
  ///
  /// Throws [StateError] if SHA-256 hash verification fails.
  Future<void> handleAvatarSync({
    required String groupId,
    required String senderDeviceId,
    required Map<String, dynamic> payload,
    required String appDirectory,
  }) async {
    final displayName = payload['displayName'] as String? ?? '';
    final avatarEmoji = payload['avatarEmoji'] as String? ?? '';
    final avatarImageBase64 = payload['avatarImageBase64'] as String?;
    final avatarImageHash = payload['avatarImageHash'] as String?;

    String? savedPath;
    String? verifiedHash;

    if (avatarImageBase64 != null && avatarImageHash != null) {
      final avatarBytes = base64Decode(avatarImageBase64);

      final computedHash = hash_lib.sha256.convert(avatarBytes).toString();
      if (computedHash != avatarImageHash) {
        throw StateError(
          'Avatar SHA-256 mismatch: expected $avatarImageHash, '
          'got $computedHash',
        );
      }

      final avatarsDir = Directory('$appDirectory/avatars');
      if (!avatarsDir.existsSync()) {
        await avatarsDir.create(recursive: true);
      }

      final avatarFile = File('${avatarsDir.path}/$senderDeviceId.jpg');
      await avatarFile.writeAsBytes(avatarBytes);

      savedPath = avatarFile.path;
      verifiedHash = avatarImageHash;
    }

    await _groupRepository.updateMemberProfile(
      groupId: groupId,
      deviceId: senderDeviceId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      avatarImagePath: savedPath,
      avatarImageHash: verifiedHash,
    );
  }
}
