import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> find();
  Future<void> save(UserProfile profile);
  Future<void> delete(String id);
}

typedef ProfileFamilySyncOperationsFactory =
    Future<List<Map<String, dynamic>>> Function(UserProfile normalizedProfile);

/// Database snapshot of every durable reference that may still need an
/// app-owned outbound Avatar blob.
class AvatarSemanticReferencesSnapshot {
  AvatarSemanticReferencesSnapshot({
    required this.profileAvatarImagePath,
    required Iterable<String> outboxBlobKeys,
  }) : outboxBlobKeys = Set.unmodifiable(outboxBlobKeys);

  final String? profileAvatarImagePath;
  final Set<String> outboxBlobKeys;
}

abstract class DurableFamilySyncUserProfileRepository
    implements UserProfileRepository {
  /// Reads the current profile and every Avatar semantic outbox locator from
  /// one database snapshot so storage maintenance cannot infer liveness from
  /// a stale save result.
  Future<AvatarSemanticReferencesSnapshot> loadAvatarSemanticReferences();

  Future<UserProfile> saveWithFamilySyncOutbox(
    UserProfile profile, {
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  });

  /// Replaces one exact, permanently unreadable Avatar semantic with a newer
  /// explicit removal. The profile write and replacement outbox operations are
  /// committed together. Returns null when the profile changed concurrently.
  Future<UserProfile?> supersedeInvalidAvatarWithRemoval({
    required int expectedRevision,
    required String expectedOriginDeviceId,
    required String originDeviceId,
    required ProfileFamilySyncOperationsFactory buildOperations,
  });
}
