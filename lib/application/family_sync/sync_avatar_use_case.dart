import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:path/path.dart' as path_lib;

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/models/member_content_version.dart';
import '../../features/family_sync/domain/models/family_sync_outbox_entry.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/avatar_semantic_staging_store.dart';
import 'avatar_semantic_staging_maintenance.dart';
import 'profile_sync_operation_mapper.dart';
import 'push_sync_use_case.dart';

/// A pulled avatar operation was not safe to persist.
///
/// This exception intentionally crosses [ApplySyncOperationsUseCase]'s
/// per-operation isolation boundary. Pull must not ACK the relay message until
/// the avatar has passed validation, reached durable storage, and updated the
/// member snapshot.
class AvatarSyncValidationException implements Exception {
  const AvatarSyncValidationException(this.reason, {this.isPermanent = true});

  final String reason;
  final bool isPermanent;

  @override
  String toString() => 'AvatarSyncValidationException: $reason';
}

/// Synchronizes member avatars as ordinary versioned E2EE operations.
///
/// Keeping the avatar inside the standard `operations` envelope makes it use
/// the same offline queue, relay authentication and key-epoch protection as
/// every other family payload.
class SyncAvatarUseCase {
  SyncAvatarUseCase({
    required PushSyncUseCase pushSync,
    required GroupRepository groupRepository,
    required UserProfileRepository userProfileRepository,
    required KeyManager keyManager,
    AvatarSemanticStagingStore? stagingStore,
  }) : _pushSync = pushSync,
       _groupRepository = groupRepository,
       _userProfileRepository = userProfileRepository,
       _keyManager = keyManager,
       _stagingStore = stagingStore,
       _stagingMaintenance = stagingStore == null
           ? null
           : AvatarSemanticStagingMaintenance(
               stagingStore: stagingStore,
               userProfileRepository: userProfileRepository,
             );

  static const schemaVersion = 1;
  static const maxAvatarBytes = AvatarSemanticStagingStore.maxBlobBytes;

  final PushSyncUseCase _pushSync;
  final GroupRepository _groupRepository;
  final UserProfileRepository _userProfileRepository;
  final KeyManager _keyManager;
  final AvatarSemanticStagingStore? _stagingStore;
  final AvatarSemanticStagingMaintenance? _stagingMaintenance;

  /// Turns the safe avatar locator persisted in SQLCipher into a wire payload.
  /// The operation is rejected when the current profile/file no longer exactly
  /// matches the persisted hash and revision; callers must retain the outbox
  /// row and wait for a newer semantic snapshot instead of sending wrong bytes.
  Future<Map<String, dynamic>> materializeOutboxOperation(
    Map<String, dynamic> operation,
  ) async {
    if (operation['entityType'] != 'avatar' ||
        operation['requiresLocalAvatarHydration'] != true) {
      return Map<String, dynamic>.from(operation)
        ..remove('requiresLocalAvatarHydration');
    }
    final expectedRevision = (operation['revision'] as num?)?.toInt();
    final expectedOwner = operation['entityId'] as String?;
    final originalData = operation['data'] as Map<String, dynamic>?;
    final expectedHash = originalData?['avatarContentHash'] as String?;
    final blobKey = operation['avatarBlobKey'] as String?;
    if (blobKey != null) {
      final stagingStore = _stagingStore;
      if (stagingStore == null || expectedHash == null) {
        throw const AvatarSyncValidationException(
          'avatar staging owner is unavailable',
        );
      }
      final AvatarMaterializedBlob blob;
      try {
        blob = await stagingStore.materialize(
          blobKey: blobKey,
          expectedHash: expectedHash,
        );
      } on AvatarSemanticStagingException catch (error) {
        throw AvatarSyncValidationException(
          error.code,
          isPermanent: error.isPermanent,
        );
      }
      final hydratedData = Map<String, dynamic>.from(originalData!)
        ..['removed'] = false
        ..['mimeType'] = blob.mimeType
        ..['byteLength'] = blob.bytes.length
        ..['sha256'] = blob.contentHash
        ..['bytesBase64'] = base64Encode(blob.bytes);
      return Map<String, dynamic>.from(operation)
        ..remove('requiresLocalAvatarHydration')
        ..remove('avatarBlobKey')
        ..['data'] = hydratedData;
    }
    final profile = await _userProfileRepository.find();
    final avatarPath = profile?.avatarImagePath;
    final effectiveProfileRevision = profile == null
        ? 0
        : profile.syncRevision > 0
        ? profile.syncRevision
        : profile.updatedAt.toUtc().microsecondsSinceEpoch;
    final effectiveProfileOrigin = profile == null
        ? ''
        : profile.syncOriginDeviceId.isNotEmpty
        ? profile.syncOriginDeviceId
        : expectedOwner ?? '';
    if (profile == null ||
        avatarPath == null ||
        expectedRevision == null ||
        effectiveProfileRevision != expectedRevision ||
        effectiveProfileOrigin != operation['originDeviceId'] ||
        expectedOwner == null ||
        expectedHash == null) {
      throw const AvatarSyncValidationException(
        'local avatar semantic source changed',
      );
    }
    final file = File(avatarPath);
    if (!await file.exists()) {
      throw const AvatarSyncValidationException('local avatar file is missing');
    }
    final byteLength = await file.length();
    if (byteLength <= 0 || byteLength > maxAvatarBytes) {
      throw const AvatarSyncValidationException(
        'local avatar size is outside the allowed range',
      );
    }
    final bytes = await file.readAsBytes();
    final mimeType = _detectMimeType(bytes);
    final actualHash = hash_lib.sha256.convert(bytes).toString();
    if (mimeType == null || actualHash != expectedHash) {
      throw const AvatarSyncValidationException(
        'local avatar content no longer matches semantic source',
      );
    }
    final hydratedData = Map<String, dynamic>.from(originalData!)
      ..['removed'] = false
      ..['mimeType'] = mimeType
      ..['byteLength'] = bytes.length
      ..['sha256'] = actualHash
      ..['bytesBase64'] = base64Encode(bytes);
    return Map<String, dynamic>.from(operation)
      ..remove('requiresLocalAvatarHydration')
      ..['data'] = hydratedData;
  }

  /// Returns true only after a permanently unreadable Avatar semantic was
  /// atomically replaced by a higher-revision removal. Transient failures and
  /// stale callbacks retain the current outbox row for a later attempt.
  Future<bool> recoverOutboxMaterializationFailure(
    FamilySyncOutboxEntry entry,
    Object error,
  ) async {
    if (entry.entityType != 'avatar' ||
        error is! AvatarSyncValidationException ||
        !error.isPermanent) {
      return false;
    }
    final deviceId = await _keyManager.getDeviceId();
    final expectedOrigin = entry.operation['originDeviceId'];
    if (deviceId == null ||
        deviceId.isEmpty ||
        entry.entityId != deviceId ||
        expectedOrigin is! String ||
        expectedOrigin.isEmpty) {
      return false;
    }
    final recovered = await _supersedeInvalidAvatar(
      expectedRevision: entry.revision,
      expectedOriginDeviceId: expectedOrigin,
      deviceId: deviceId,
    );
    if (recovered == null) return false;
    await cleanupStagingAfterSettlement();
    return true;
  }

  /// Builds profile semantics for Full/Initial sync without allowing a local
  /// Avatar file failure to abort unrelated bills or shopping items.
  Future<List<Map<String, dynamic>>>
  buildCurrentProfileOperationsForFullSync() async {
    return _buildCurrentProfileOperationsForFullSync(allowRecovery: true);
  }

  Future<List<Map<String, dynamic>>> _buildCurrentProfileOperationsForFullSync({
    required bool allowRecovery,
  }) async {
    final profile = await _userProfileRepository.find();
    if (profile == null) return const [];
    final deviceId = await _keyManager.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return const [];
    }
    final profileOperation = ProfileSyncOperationMapper.buildProfileOperation(
      profile,
      deviceId: deviceId,
    );
    if (profile.avatarImagePath == null) {
      return [
        profileOperation,
        ProfileSyncOperationMapper.buildAvatarOperation(
          profile,
          deviceId: deviceId,
        ),
      ];
    }

    final stagingStore = _stagingStore;
    if (stagingStore == null) return [profileOperation];
    try {
      final staged = await stagingStore.stageSource(profile.avatarImagePath!);
      final avatarOperation = ProfileSyncOperationMapper.buildAvatarOperation(
        profile,
        deviceId: deviceId,
        stagedAvatar: staged,
      );
      return [
        profileOperation,
        await materializeOutboxOperation(avatarOperation),
      ];
    } catch (error) {
      final permanent =
          error is AvatarSemanticStagingException && error.isPermanent ||
          error is AvatarSyncValidationException && error.isPermanent;
      if (!allowRecovery || !permanent) return [profileOperation];
      final expectedRevision = profile.syncRevision > 0
          ? profile.syncRevision
          : profile.updatedAt.toUtc().microsecondsSinceEpoch;
      final expectedOrigin = profile.syncOriginDeviceId.isNotEmpty
          ? profile.syncOriginDeviceId
          : deviceId;
      final recovered = await _supersedeInvalidAvatar(
        expectedRevision: expectedRevision,
        expectedOriginDeviceId: expectedOrigin,
        deviceId: deviceId,
      );
      if (recovered == null) {
        // A concurrent save won the exact-version race. Re-read it once; an
        // older FullSync snapshot must never clear or settle the new Avatar.
        return _buildCurrentProfileOperationsForFullSync(allowRecovery: false);
      }
      await cleanupStagingAfterSettlement();
      return ProfileSyncOperationMapper.buildOperations(
        recovered,
        deviceId: deviceId,
      );
    }
  }

  Future<UserProfile?> _supersedeInvalidAvatar({
    required int expectedRevision,
    required String expectedOriginDeviceId,
    required String deviceId,
  }) async {
    final repository = _userProfileRepository;
    if (repository is! DurableFamilySyncUserProfileRepository) return null;
    return repository.supersedeInvalidAvatarWithRemoval(
      expectedRevision: expectedRevision,
      expectedOriginDeviceId: expectedOriginDeviceId,
      originDeviceId: deviceId,
      buildOperations: (normalized) =>
          ProfileSyncOperationMapper.buildOperations(
            normalized,
            deviceId: deviceId,
          ),
    );
  }

  /// Best-effort bounded maintenance after ACK or semantic supersession. The
  /// current profile's locator is always retained; no path or content leaves
  /// this storage boundary.
  Future<void> cleanupStagingAfterSettlement() async {
    await _stagingMaintenance?.cleanupCurrentReferences();
  }

  /// Pushes a deterministic avatar upsert/removal operation.
  ///
  /// Returns null when there is no active keyed family, no local profile, or
  /// no device identity. A network failure is returned as [PushSyncQueued],
  /// because [PushSyncUseCase] persists the encrypted operation for retry.
  Future<PushSyncResult?> pushAvatarToMembers({required String groupId}) async {
    final group = await _groupRepository.getGroupById(groupId);
    if (!_isActiveKeyedGroup(group)) return null;

    final profile = await _userProfileRepository.find();
    final deviceId = await _keyManager.getDeviceId();
    if (profile == null || deviceId == null || deviceId.isEmpty) return null;

    final data = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'ownerDeviceId': deviceId,
      'displayName': profile.displayName,
      'avatarEmoji': profile.avatarEmoji,
    };
    var contentIdentity = 'removed';

    final avatarPath = profile.avatarImagePath;
    if (avatarPath == null) {
      data['removed'] = true;
    } else {
      final avatarFile = File(avatarPath);
      if (!await avatarFile.exists()) {
        throw const AvatarSyncValidationException(
          'local avatar file is missing',
        );
      }
      final byteLength = await avatarFile.length();
      if (byteLength <= 0 || byteLength > maxAvatarBytes) {
        throw const AvatarSyncValidationException(
          'local avatar size is outside the allowed range',
        );
      }
      final bytes = await avatarFile.readAsBytes();
      final mimeType = _detectMimeType(bytes);
      if (mimeType == null) {
        throw const AvatarSyncValidationException(
          'local avatar format is not supported',
        );
      }
      final sha256 = hash_lib.sha256.convert(bytes).toString();
      contentIdentity = sha256;
      data
        ..['removed'] = false
        ..['mimeType'] = mimeType
        ..['byteLength'] = bytes.length
        ..['sha256'] = sha256
        ..['bytesBase64'] = base64Encode(bytes);
    }

    final versionedRepository =
        _groupRepository is VersionedGroupMemberRepository
        ? _groupRepository as VersionedGroupMemberRepository
        : null;
    final prepared = versionedRepository != null
        ? await versionedRepository.prepareLocalAvatarVersion(
            groupId: groupId,
            deviceId: deviceId,
            avatarImagePath: avatarPath,
            avatarImageHash: contentIdentity == 'removed'
                ? null
                : contentIdentity,
            contentDigest: contentIdentity,
            now: DateTime.now(),
          )
        : null;
    if (versionedRepository != null && prepared == null) {
      return null;
    }
    final revision =
        prepared?.revision ?? profile.updatedAt.toUtc().microsecondsSinceEpoch;
    final originDeviceId = prepared?.originDeviceId ?? deviceId;
    data
      ..['revision'] = revision
      ..['avatarContentHash'] = contentIdentity;

    final operation = <String, dynamic>{
      'op': 'update',
      'entityType': 'avatar',
      'entityId': deviceId,
      'operationId': 'avatar:$deviceId:$revision:$contentIdentity',
      'revision': revision,
      'originDeviceId': originDeviceId,
      'fromDeviceId': deviceId,
      'timestamp': profile.updatedAt.toUtc().toIso8601String(),
      'data': data,
    };

    return _pushSync.execute(operations: [operation], vectorClock: const {});
  }

  /// Validates and atomically stores a pulled avatar operation.
  ///
  /// The transport sender is authoritative. Payload owner IDs, group
  /// membership and key epoch must all agree before any filesystem or database
  /// mutation occurs.
  Future<void> handleAvatarSync({
    required String groupId,
    required String senderDeviceId,
    required int messageKeyEpoch,
    required Map<String, dynamic> payload,
    required String appDirectory,
    int? envelopeRevision,
    String? originDeviceId,
  }) async {
    final group = await _groupRepository.getGroupById(groupId);
    if (!_isActiveKeyedGroup(group) || group!.keyEpoch != messageKeyEpoch) {
      throw const AvatarSyncValidationException(
        'group or transport key epoch is not current',
      );
    }
    final sender = _activeMember(group.members, senderDeviceId);
    if (sender == null) {
      throw const AvatarSyncValidationException(
        'avatar sender is not an active group member',
      );
    }
    if (payload['schemaVersion'] != schemaVersion) {
      throw const AvatarSyncValidationException(
        'unsupported avatar schema version',
      );
    }
    if (payload['ownerDeviceId'] != senderDeviceId) {
      throw const AvatarSyncValidationException(
        'avatar owner does not match the authenticated sender',
      );
    }
    final payloadRevision = (payload['revision'] as num?)?.toInt();
    final revision = envelopeRevision ?? payloadRevision ?? 0;
    if (revision < 0 ||
        (envelopeRevision != null &&
            payloadRevision != null &&
            envelopeRevision != payloadRevision)) {
      throw const AvatarSyncValidationException('invalid avatar revision');
    }
    final resolvedOrigin = originDeviceId ?? senderDeviceId;
    if (resolvedOrigin != senderDeviceId) {
      throw const AvatarSyncValidationException(
        'avatar origin does not match the authenticated sender',
      );
    }

    final displayName = payload['displayName'];
    final avatarEmoji = payload['avatarEmoji'];
    if (displayName is! String || avatarEmoji is! String) {
      throw const AvatarSyncValidationException(
        'avatar identity fields are invalid',
      );
    }

    final removed = payload['removed'] == true;
    final declaredContentHash = payload['avatarContentHash'];
    final candidateDigest = removed
        ? 'removed'
        : payload['sha256'] is String
        ? payload['sha256'] as String
        : '';
    if (declaredContentHash != null && declaredContentHash != candidateDigest) {
      throw const AvatarSyncValidationException(
        'avatar content identity is invalid',
      );
    }
    final candidateVersion = MemberContentVersion(
      revision: revision,
      originDeviceId: resolvedOrigin,
      contentDigest: candidateDigest,
    );
    final currentVersion = MemberContentVersion(
      revision: sender.avatarRevision,
      originDeviceId: sender.avatarOriginDeviceId,
      contentDigest: sender.avatarContentHash,
    );
    final versionedRepository =
        _groupRepository is VersionedGroupMemberRepository
        ? _groupRepository as VersionedGroupMemberRepository
        : null;
    if (versionedRepository != null &&
        !candidateVersion.isStrictlyNewerThan(currentVersion)) {
      return;
    }

    String? savedPath;
    String? verifiedHash;
    File? newlyCreatedAvatar;
    if (!removed) {
      final mimeType = payload['mimeType'];
      final declaredLength = (payload['byteLength'] as num?)?.toInt();
      final declaredHash = payload['sha256'];
      final encodedBytes = payload['bytesBase64'];
      if (mimeType is! String ||
          !_extensionByMime.containsKey(mimeType) ||
          declaredLength == null ||
          declaredLength <= 0 ||
          declaredLength > maxAvatarBytes ||
          declaredHash is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(declaredHash) ||
          encodedBytes is! String ||
          encodedBytes.length > _maxEncodedLength) {
        throw const AvatarSyncValidationException('avatar metadata is invalid');
      }

      final List<int> avatarBytes;
      try {
        avatarBytes = base64Decode(encodedBytes);
      } on FormatException {
        throw const AvatarSyncValidationException(
          'avatar bytes are not valid base64',
        );
      }
      if (avatarBytes.length != declaredLength ||
          _detectMimeType(avatarBytes) != mimeType ||
          hash_lib.sha256.convert(avatarBytes).toString() != declaredHash) {
        throw const AvatarSyncValidationException(
          'avatar content integrity check failed',
        );
      }

      final avatarsDir = Directory(path_lib.join(appDirectory, 'avatars'));
      await avatarsDir.create(recursive: true);
      final ownerToken = hash_lib.sha256
          .convert(utf8.encode(senderDeviceId))
          .toString();
      final extension = _extensionByMime[mimeType]!;
      final destination = File(
        path_lib.join(
          avatarsDir.path,
          '${ownerToken}_${declaredHash.substring(0, 16)}.$extension',
        ),
      );
      if (!path_lib.isWithin(avatarsDir.path, destination.path)) {
        throw const AvatarSyncValidationException(
          'avatar destination escaped its storage directory',
        );
      }

      if (await destination.exists()) {
        final existingBytes = await destination.readAsBytes();
        if (existingBytes.length != declaredLength ||
            hash_lib.sha256.convert(existingBytes).toString() != declaredHash) {
          throw const AvatarSyncValidationException(
            'existing avatar file failed integrity verification',
          );
        }
      } else {
        final temporary = File(
          path_lib.join(
            avatarsDir.path,
            '.$ownerToken.${DateTime.now().microsecondsSinceEpoch}.tmp',
          ),
        );
        try {
          await temporary.writeAsBytes(avatarBytes, flush: true);
          if (await temporary.length() != declaredLength) {
            throw const AvatarSyncValidationException(
              'temporary avatar write was incomplete',
            );
          }
          await temporary.rename(destination.path);
          newlyCreatedAvatar = destination;
        } finally {
          if (await temporary.exists()) {
            try {
              await temporary.delete();
            } catch (_) {
              // Best-effort cleanup; never expose the temporary path to UI.
            }
          }
        }
      }
      savedPath = destination.path;
      verifiedHash = declaredHash;
    }

    if (versionedRepository != null) {
      try {
        final applied = await versionedRepository.applyMemberAvatarVersioned(
          groupId: groupId,
          deviceId: senderDeviceId,
          avatarImagePath: savedPath,
          avatarImageHash: verifiedHash,
          version: candidateVersion,
        );
        if (!applied) {
          await _deleteFileBestEffort(newlyCreatedAvatar);
          return;
        }
      } catch (_) {
        await _deleteFileBestEffort(newlyCreatedAvatar);
        rethrow;
      }
    } else {
      await _groupRepository.updateMemberProfile(
        groupId: groupId,
        deviceId: senderDeviceId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImagePath: savedPath,
        avatarImageHash: verifiedHash,
      );
    }

    await _deleteReplacedAvatarBestEffort(
      previousPath: sender.avatarImagePath,
      currentPath: savedPath,
      appDirectory: appDirectory,
    );
  }

  bool _isActiveKeyedGroup(GroupInfo? group) =>
      group != null &&
      group.status == GroupStatus.active &&
      group.groupKey != null &&
      group.groupKey!.isNotEmpty;

  GroupMember? _activeMember(List<GroupMember> members, String deviceId) {
    for (final member in members) {
      if (member.deviceId == deviceId && member.status == 'active') {
        return member;
      }
    }
    return null;
  }

  static const _extensionByMime = <String, String>{
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  static int get _maxEncodedLength => ((maxAvatarBytes + 2) ~/ 3) * 4 + 4;

  static String? _detectMimeType(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _deleteReplacedAvatarBestEffort({
    required String? previousPath,
    required String? currentPath,
    required String appDirectory,
  }) async {
    if (previousPath == null || previousPath == currentPath) return;
    final avatarsPath = path_lib.normalize(
      path_lib.absolute(path_lib.join(appDirectory, 'avatars')),
    );
    final normalizedPrevious = path_lib.normalize(
      path_lib.absolute(previousPath),
    );
    if (!path_lib.isWithin(avatarsPath, normalizedPrevious)) return;
    try {
      final previous = File(normalizedPrevious);
      if (await previous.exists()) await previous.delete();
    } catch (_) {
      // Local cleanup cannot invalidate an already committed member snapshot.
    }
  }

  Future<void> _deleteFileBestEffort(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Orphan cleanup must never roll back a successfully resolved merge.
    }
  }
}
