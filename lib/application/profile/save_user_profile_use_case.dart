import 'dart:io';

import 'package:ulid/ulid.dart';

import '../../features/profile/domain/models/user_profile.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../shared/constants/warm_emojis.dart';

enum SaveProfileError { nameRequired, nameTooLong, invalidEmoji }

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
  SaveUserProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<SaveProfileResult> execute({
    String? id,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? oldAvatarImagePath,
  }) async {
    final trimmedDisplayName = displayName.trim();
    if (trimmedDisplayName.isEmpty) {
      return const SaveProfileResult.failure(SaveProfileError.nameRequired);
    }
    if (trimmedDisplayName.length > 50) {
      return const SaveProfileResult.failure(SaveProfileError.nameTooLong);
    }
    if (!warmEmojis.contains(avatarEmoji)) {
      return const SaveProfileResult.failure(SaveProfileError.invalidEmoji);
    }

    final now = DateTime.now();
    final existing = id != null ? await _repository.find() : null;
    final profile = UserProfile(
      id: id ?? Ulid().toString(),
      displayName: trimmedDisplayName,
      avatarEmoji: avatarEmoji,
      avatarImagePath: avatarImagePath,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _repository.save(profile);

    if (oldAvatarImagePath != null && oldAvatarImagePath != avatarImagePath) {
      try {
        final oldFile = File(oldAvatarImagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {
        // Best effort cleanup only.
      }
    }

    return SaveProfileResult.success(profile);
  }
}
