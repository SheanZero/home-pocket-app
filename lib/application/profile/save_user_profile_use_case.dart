import 'package:ulid/ulid.dart';

import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/sync/avatar_semantic_staging_store.dart';
import '../family_sync/avatar_semantic_staging_maintenance.dart';
import '../family_sync/profile_sync_operation_mapper.dart';
import '../../shared/constants/avatar_icon_ids.dart';
import '../../shared/constants/warm_emojis.dart';

enum SaveProfileError { nameRequired, nameTooLong, invalidEmoji }

typedef ProfileSavedCallback = void Function();

class SaveProfileResult {
  const SaveProfileResult.success(this.profile)
    : error = null,
      isSuccess = true;

  const SaveProfileResult.failure(this.error)
    : profile = null,
      isSuccess = false;

  final UserProfile? profile;
  final SaveProfileError? error;
  final bool isSuccess;
}

class SaveUserProfileUseCase {
  SaveUserProfileUseCase(
    this._repository, {
    this._deviceIdResolver,
    this._avatarStagingStore,
  });

  final UserProfileRepository _repository;
  final Future<String?> Function()? _deviceIdResolver;
  final AvatarSemanticStagingStore? _avatarStagingStore;

  Future<SaveProfileResult> execute({
    String? id,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? oldAvatarImagePath,
    ProfileSavedCallback? onSaved,
  }) async {
    final trimmedDisplayName = displayName.trim();
    if (trimmedDisplayName.isEmpty) {
      return const SaveProfileResult.failure(SaveProfileError.nameRequired);
    }
    if (trimmedDisplayName.length > 50) {
      return const SaveProfileResult.failure(SaveProfileError.nameTooLong);
    }
    if (!warmEmojis.contains(avatarEmoji) && !isAvatarIconId(avatarEmoji)) {
      return const SaveProfileResult.failure(SaveProfileError.invalidEmoji);
    }

    final stagingStore = _avatarStagingStore;
    AvatarStagedBlob? stagedAvatar;
    Future<SaveProfileResult> persist() async {
      final now = DateTime.now();
      final existing = id != null ? await _repository.find() : null;
      var persistedAvatarPath = avatarImagePath;
      if (stagingStore != null && avatarImagePath != null) {
        final staged = await stagingStore.stageSource(avatarImagePath);
        stagedAvatar = staged;
        persistedAvatarPath = staged.path;
      }
      final profile = UserProfile(
        id: id ?? Ulid().toString(),
        displayName: trimmedDisplayName,
        avatarEmoji: avatarEmoji,
        avatarImagePath: persistedAvatarPath,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final durable = _repository is DurableFamilySyncUserProfileRepository
          ? _repository
          : null;
      final originDeviceId = await _deviceIdResolver?.call() ?? '';
      final saved = durable != null && originDeviceId.isNotEmpty
          ? await durable.saveWithFamilySyncOutbox(
              profile,
              originDeviceId: originDeviceId,
              buildOperations: (normalized) =>
                  ProfileSyncOperationMapper.buildOperations(
                    normalized,
                    deviceId: originDeviceId,
                    stagedAvatar: stagedAvatar,
                  ),
            )
          : profile;
      if (durable == null || originDeviceId.isEmpty) {
        await _repository.save(profile);
      }

      // Local-first: the profile write is authoritative on this device. Family
      // sync is a best-effort, retryable follow-up and must never make the local
      // save appear to fail.
      try {
        onSaved?.call();
      } catch (_) {
        // SyncEngine/SyncScheduler owns retry and error reporting.
      }

      return SaveProfileResult.success(saved);
    }

    final isNewProfileWithoutImage =
        id == null && avatarImagePath == null && oldAvatarImagePath == null;
    if (stagingStore == null || isNewProfileWithoutImage) return persist();
    // oldAvatarImagePath may be a picker path or a content-addressed managed
    // path. Never compare/delete it directly: liveness comes from the committed
    // profile plus semantic outbox reference snapshot after [persist].
    return AvatarSemanticStagingMaintenance(
      stagingStore: stagingStore,
      userProfileRepository: _repository,
    ).runMutationAndCleanup(persist, stagedBlobOnFailure: () => stagedAvatar);
  }
}
