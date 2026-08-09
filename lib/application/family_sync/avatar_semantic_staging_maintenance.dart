import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/sync/avatar_semantic_staging_store.dart';

/// Coordinates app-owned Avatar blob mutations with reference-safe cleanup.
class AvatarSemanticStagingMaintenance {
  AvatarSemanticStagingMaintenance({
    required this._stagingStore,
    required this._userProfileRepository,
  });

  final AvatarSemanticStagingStore _stagingStore;
  final UserProfileRepository _userProfileRepository;

  /// Keeps staging, the durable profile/outbox commit, and post-commit cleanup
  /// in one store-local critical section.
  Future<T> runMutationAndCleanup<T>(
    Future<T> Function() mutation, {
    AvatarStagedBlob? Function()? stagedBlobOnFailure,
  }) {
    return _stagingStore.runReferenceCriticalSection(() async {
      try {
        final result = await mutation();
        await _cleanupCurrentReferencesBestEffort();
        return result;
      } catch (error, stackTrace) {
        final staged = stagedBlobOnFailure?.call();
        if (staged != null && staged.wasCreated) {
          await _compensateNewBlobBestEffort(staged.key);
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  /// Best-effort cleanup used after exact ACK, supersession, and FullSync
  /// settlement. It serializes with every local Avatar save using this store.
  Future<void> cleanupCurrentReferences() {
    return _stagingStore.runReferenceCriticalSection(
      _cleanupCurrentReferencesBestEffort,
    );
  }

  Future<void> _cleanupCurrentReferencesBestEffort() async {
    try {
      final retained = await _loadCurrentRetainedBlobKeys();
      await _stagingStore.garbageCollect(retainedBlobKeys: retained);
    } catch (_) {
      // Durable references remain authoritative. A later save, drain, or full
      // sync settlement retries bounded maintenance.
    }
  }

  Future<void> _compensateNewBlobBestEffort(String blobKey) async {
    try {
      final retained = await _loadCurrentRetainedBlobKeys();
      await _stagingStore.deleteBlobIfUnreferenced(
        blobKey: blobKey,
        retainedBlobKeys: retained,
      );
    } catch (_) {
      // The original database failure remains authoritative. Startup/resume
      // maintenance retries an orphan after the normal retention/quota bound.
    }
  }

  Future<Set<String>> _loadCurrentRetainedBlobKeys() async {
    final repository = _userProfileRepository;
    final AvatarSemanticReferencesSnapshot references;
    if (repository is DurableFamilySyncUserProfileRepository) {
      references = await repository.loadAvatarSemanticReferences();
    } else {
      final profile = await repository.find();
      references = AvatarSemanticReferencesSnapshot(
        profileAvatarImagePath: profile?.avatarImagePath,
        outboxBlobKeys: const {},
      );
    }
    final retained = <String>{...references.outboxBlobKeys};
    final profileKey = await _stagingStore.keyForManagedPath(
      references.profileAvatarImagePath,
    );
    if (profileKey != null) retained.add(profileKey);
    return retained;
  }
}
