import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;

import '../../features/profile/domain/models/user_profile.dart';
import '../../infrastructure/sync/avatar_semantic_staging_store.dart';

/// Builds restart-safe profile/avatar semantics. Avatar bytes and local paths
/// are intentionally absent; the outbox drainer hydrates bytes from the
/// current app-owned profile file only after its hash still matches.
class ProfileSyncOperationMapper {
  ProfileSyncOperationMapper._();

  static Future<List<Map<String, dynamic>>> buildOperations(
    UserProfile profile, {
    required String deviceId,
    AvatarStagedBlob? stagedAvatar,
  }) async {
    return [
      buildProfileOperation(profile, deviceId: deviceId),
      buildAvatarOperation(
        profile,
        deviceId: deviceId,
        stagedAvatar: stagedAvatar,
      ),
    ];
  }

  static Map<String, dynamic> buildProfileOperation(
    UserProfile profile, {
    required String deviceId,
  }) {
    final revision = profile.syncRevision > 0
        ? profile.syncRevision
        : profile.updatedAt.toUtc().microsecondsSinceEpoch;
    final origin = profile.syncOriginDeviceId.isNotEmpty
        ? profile.syncOriginDeviceId
        : deviceId;
    final profileDigest = hash_lib.sha256
        .convert(
          utf8.encode(jsonEncode([profile.displayName, profile.avatarEmoji])),
        )
        .toString();
    return <String, dynamic>{
      'op': 'update',
      'entityType': 'profile',
      'entityId': deviceId,
      'operationId': 'profile:$deviceId:$revision:$profileDigest',
      'profileDigest': profileDigest,
      'revision': revision,
      'originDeviceId': origin,
      'fromDeviceId': deviceId,
      'timestamp': profile.updatedAt.toUtc().toIso8601String(),
      'data': {
        'schemaVersion': 1,
        'ownerDeviceId': deviceId,
        'revision': revision,
        'profileDigest': profileDigest,
        'displayName': profile.displayName,
        'avatarEmoji': profile.avatarEmoji,
      },
    };
  }

  static Map<String, dynamic> buildAvatarOperation(
    UserProfile profile, {
    required String deviceId,
    AvatarStagedBlob? stagedAvatar,
  }) {
    final revision = profile.syncRevision > 0
        ? profile.syncRevision
        : profile.updatedAt.toUtc().microsecondsSinceEpoch;
    final origin = profile.syncOriginDeviceId.isNotEmpty
        ? profile.syncOriginDeviceId
        : deviceId;
    final avatarPath = profile.avatarImagePath;
    String contentHash = 'removed';
    if (avatarPath != null) {
      if (stagedAvatar == null) {
        throw const AvatarSemanticStagingException(
          code: 'avatar_not_staged',
          isPermanent: true,
        );
      }
      contentHash = stagedAvatar.contentHash;
    }
    return <String, dynamic>{
      'op': 'update',
      'entityType': 'avatar',
      'entityId': deviceId,
      'operationId': 'avatar:$deviceId:$revision:$contentHash',
      'revision': revision,
      'originDeviceId': origin,
      'fromDeviceId': deviceId,
      'timestamp': profile.updatedAt.toUtc().toIso8601String(),
      // This marker is local-only and is removed during hydration.
      if (avatarPath != null) 'requiresLocalAvatarHydration': true,
      if (stagedAvatar != null) 'avatarBlobKey': stagedAvatar.key,
      'data': {
        'schemaVersion': 1,
        'ownerDeviceId': deviceId,
        'displayName': profile.displayName,
        'avatarEmoji': profile.avatarEmoji,
        'revision': revision,
        'removed': avatarPath == null,
        'avatarContentHash': contentHash,
      },
    };
  }
}
