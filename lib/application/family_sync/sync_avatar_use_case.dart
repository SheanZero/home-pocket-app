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
import '../../infrastructure/sync/avatar_mime_type.dart';
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
    required this._pushSync,
    required this._groupRepository,
    required UserProfileRepository userProfileRepository,
    required this._keyManager,
    AvatarSemanticStagingStore? stagingStore,
  }) : _userProfileRepository = userProfileRepository,
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
    final mimeType = detectAvatarMimeType(bytes);
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
      final mimeType = detectAvatarMimeType(bytes);
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
    final context = await _validateIncomingAvatarContext(
      groupId: groupId,
      senderDeviceId: senderDeviceId,
      messageKeyEpoch: messageKeyEpoch,
      payload: payload,
      envelopeRevision: envelopeRevision,
      originDeviceId: originDeviceId,
    );
    final candidate = _validateAvatarCandidate(payload, context);
    if (context.versionedRepository != null &&
        !candidate.isNewerThan(context.sender)) {
      return;
    }
    final stored = await _storeIncomingAvatar(
      payload: payload,
      senderDeviceId: senderDeviceId,
      appDirectory: appDirectory,
      removed: candidate.removed,
    );
    final applied = await _applyIncomingAvatar(
      context: context,
      candidate: candidate,
      stored: stored,
    );
    if (!applied) return;
    await _deleteReplacedAvatarBestEffort(
      previousPath: context.sender.avatarImagePath,
      currentPath: stored.path,
      appDirectory: appDirectory,
    );
  }

  Future<_IncomingAvatarContext> _validateIncomingAvatarContext({
    required String groupId,
    required String senderDeviceId,
    required int messageKeyEpoch,
    required Map<String, dynamic> payload,
    required int? envelopeRevision,
    required String? originDeviceId,
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
        envelopeRevision != null &&
            payloadRevision != null &&
            envelopeRevision != payloadRevision) {
      throw const AvatarSyncValidationException('invalid avatar revision');
    }
    final resolvedOrigin = originDeviceId ?? senderDeviceId;
    if (resolvedOrigin != senderDeviceId) {
      throw const AvatarSyncValidationException(
        'avatar origin does not match the authenticated sender',
      );
    }
    return _IncomingAvatarContext(
      groupId: groupId,
      senderDeviceId: senderDeviceId,
      sender: sender,
      revision: revision,
      originDeviceId: resolvedOrigin,
      versionedRepository: _groupRepository is VersionedGroupMemberRepository
          ? _groupRepository as VersionedGroupMemberRepository
          : null,
    );
  }

  _AvatarCandidate _validateAvatarCandidate(
    Map<String, dynamic> payload,
    _IncomingAvatarContext context,
  ) {
    final displayName = payload['displayName'];
    final avatarEmoji = payload['avatarEmoji'];
    if (displayName is! String || avatarEmoji is! String) {
      throw const AvatarSyncValidationException(
        'avatar identity fields are invalid',
      );
    }
    final removed = payload['removed'] == true;
    final digest = removed
        ? 'removed'
        : payload['sha256'] is String
        ? payload['sha256'] as String
        : '';
    if (payload['avatarContentHash'] case final declared?
        when declared != digest) {
      throw const AvatarSyncValidationException(
        'avatar content identity is invalid',
      );
    }
    return _AvatarCandidate(
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      removed: removed,
      version: MemberContentVersion(
        revision: context.revision,
        originDeviceId: context.originDeviceId,
        contentDigest: digest,
      ),
    );
  }

  Future<_StoredAvatar> _storeIncomingAvatar({
    required Map<String, dynamic> payload,
    required String senderDeviceId,
    required String appDirectory,
    required bool removed,
  }) async {
    if (removed) return const _StoredAvatar();
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
    final bytes = _decodeAndVerifyAvatar(
      encodedBytes: encodedBytes,
      declaredLength: declaredLength,
      declaredHash: declaredHash,
      mimeType: mimeType,
    );
    final avatarFile = await _writeVerifiedAvatar(
      appDirectory: appDirectory,
      senderDeviceId: senderDeviceId,
      mimeType: mimeType,
      declaredLength: declaredLength,
      declaredHash: declaredHash,
      bytes: bytes,
    );
    return _StoredAvatar(
      path: avatarFile.file.path,
      hash: declaredHash,
      newlyCreated: avatarFile.newlyCreated,
    );
  }

  List<int> _decodeAndVerifyAvatar({
    required String encodedBytes,
    required int declaredLength,
    required String declaredHash,
    required String mimeType,
  }) {
    final List<int> bytes;
    try {
      bytes = base64Decode(encodedBytes);
    } on FormatException {
      throw const AvatarSyncValidationException(
        'avatar bytes are not valid base64',
      );
    }
    if (bytes.length != declaredLength ||
        detectAvatarMimeType(bytes) != mimeType ||
        hash_lib.sha256.convert(bytes).toString() != declaredHash) {
      throw const AvatarSyncValidationException(
        'avatar content integrity check failed',
      );
    }
    return bytes;
  }

  Future<_WrittenAvatar> _writeVerifiedAvatar({
    required String appDirectory,
    required String senderDeviceId,
    required String mimeType,
    required int declaredLength,
    required String declaredHash,
    required List<int> bytes,
  }) async {
    final avatarsDir = Directory(path_lib.join(appDirectory, 'avatars'));
    await avatarsDir.create(recursive: true);
    final ownerToken = hash_lib.sha256
        .convert(utf8.encode(senderDeviceId))
        .toString();
    final destination = File(
      path_lib.join(
        avatarsDir.path,
        '${ownerToken}_${declaredHash.substring(0, 16)}.${_extensionByMime[mimeType]!}',
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
      return _WrittenAvatar(destination, newlyCreated: null);
    }
    final temporary = File(
      path_lib.join(
        avatarsDir.path,
        '.$ownerToken.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      if (await temporary.length() != declaredLength) {
        throw const AvatarSyncValidationException(
          'temporary avatar write was incomplete',
        );
      }
      await temporary.rename(destination.path);
      return _WrittenAvatar(destination, newlyCreated: destination);
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

  Future<bool> _applyIncomingAvatar({
    required _IncomingAvatarContext context,
    required _AvatarCandidate candidate,
    required _StoredAvatar stored,
  }) async {
    final versioned = context.versionedRepository;
    if (versioned == null) {
      await _groupRepository.updateMemberProfile(
        groupId: context.groupId,
        deviceId: context.senderDeviceId,
        displayName: candidate.displayName,
        avatarEmoji: candidate.avatarEmoji,
        avatarImagePath: stored.path,
        avatarImageHash: stored.hash,
      );
      return true;
    }
    try {
      final applied = await versioned.applyMemberAvatarVersioned(
        groupId: context.groupId,
        deviceId: context.senderDeviceId,
        avatarImagePath: stored.path,
        avatarImageHash: stored.hash,
        version: candidate.version,
      );
      if (!applied) await _deleteFileBestEffort(stored.newlyCreated);
      return applied;
    } catch (_) {
      await _deleteFileBestEffort(stored.newlyCreated);
      rethrow;
    }
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

class _IncomingAvatarContext {
  const _IncomingAvatarContext({
    required this.groupId,
    required this.senderDeviceId,
    required this.sender,
    required this.revision,
    required this.originDeviceId,
    required this.versionedRepository,
  });

  final String groupId;
  final String senderDeviceId;
  final GroupMember sender;
  final int revision;
  final String originDeviceId;
  final VersionedGroupMemberRepository? versionedRepository;
}

class _AvatarCandidate {
  const _AvatarCandidate({
    required this.displayName,
    required this.avatarEmoji,
    required this.removed,
    required this.version,
  });

  final String displayName;
  final String avatarEmoji;
  final bool removed;
  final MemberContentVersion version;

  bool isNewerThan(GroupMember sender) => version.isStrictlyNewerThan(
    MemberContentVersion(
      revision: sender.avatarRevision,
      originDeviceId: sender.avatarOriginDeviceId,
      contentDigest: sender.avatarContentHash,
    ),
  );
}

class _StoredAvatar {
  const _StoredAvatar({this.path, this.hash, this.newlyCreated});

  final String? path;
  final String? hash;
  final File? newlyCreated;
}

class _WrittenAvatar {
  const _WrittenAvatar(this.file, {required this.newlyCreated});

  final File file;
  final File? newlyCreated;
}
