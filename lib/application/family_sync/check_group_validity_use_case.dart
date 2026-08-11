import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'handle_group_dissolved_use_case.dart';

/// Result of checking whether the current group is still valid.
sealed class GroupValidityResult {
  const GroupValidityResult();

  const factory GroupValidityResult.valid() = GroupValid;
  const factory GroupValidityResult.noGroup() = GroupNoGroup;
  const factory GroupValidityResult.invalid(String reason) = GroupInvalid;
}

class GroupValid extends GroupValidityResult {
  const GroupValid();
}

class GroupNoGroup extends GroupValidityResult {
  const GroupNoGroup();
}

class GroupInvalid extends GroupValidityResult {
  const GroupInvalid(this.reason);
  final String reason;
}

/// Validates group membership before sync push.
///
/// Uses a 5-minute cache to avoid hammering the server on every transaction.
/// On invalid: cleans shadow books and removes local membership data.
/// Offline-tolerant: returns valid on network errors.
class CheckGroupValidityUseCase {
  CheckGroupValidityUseCase({
    required this._groupRepo,
    required this._apiClient,
    required this._invalidationCleanup,
  });

  final GroupRepository _groupRepo;
  final RelayApiClient _apiClient;
  final HandleGroupDissolvedUseCase _invalidationCleanup;

  DateTime? _lastCheckTime;
  GroupValidityResult? _cachedResult;
  static const _cacheDuration = Duration(minutes: 5);

  Future<GroupValidityResult> execute({bool forceCheck = false}) async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      _invalidate();
      return const GroupValidityResult.noGroup();
    }

    if (!forceCheck && _cachedResult != null && _lastCheckTime != null) {
      if (DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
        return _cachedResult!;
      }
    }

    try {
      final response = await _apiClient.checkGroup();
      final groupExisted = response['groupExisted'];
      if (groupExisted == false) {
        return _invalidateLocalGroup(
          group.groupId,
          'Device is no longer an active group member',
          cleanupMode: LocalGroupCleanupMode.deactivate,
        );
      }

      if (groupExisted != true) {
        // A malformed success response is not proof that membership was
        // revoked. Keep the local-first/offline-tolerant behavior.
        return _cache(const GroupValidityResult.valid());
      }

      final serverGroupId = response['groupId'];
      if (serverGroupId is! String || serverGroupId.isEmpty) {
        return _cache(const GroupValidityResult.valid());
      }
      if (serverGroupId != group.groupId) {
        return _invalidateLocalGroup(
          group.groupId,
          'Server membership points to a different group',
          cleanupMode: LocalGroupCleanupMode.deactivate,
        );
      }

      return _cache(const GroupValidityResult.valid());
    } on RelayApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 403) {
        return _invalidateLocalGroup(
          group.groupId,
          e.statusCode == 404 ? 'Group dissolved' : 'Removed from group',
          cleanupMode: e.statusCode == 404
              ? LocalGroupCleanupMode.delete
              : LocalGroupCleanupMode.deactivate,
        );
      }
      // Other API errors → offline tolerance
      return _cache(const GroupValidityResult.valid());
    } catch (_) {
      // Network error → offline tolerance
      return _cache(const GroupValidityResult.valid());
    }
  }

  /// Applies cleanup only after a signed relay endpoint has explicitly
  /// rejected this membership. Network failures and 5xx responses must never
  /// call this method.
  Future<GroupValidityResult> invalidateAfterAuthenticatedMembershipFailure({
    required String groupId,
    required int statusCode,
    required String reason,
  }) async {
    if (statusCode != 403 && statusCode != 404) {
      throw ArgumentError.value(
        statusCode,
        'statusCode',
        'Only authenticated membership failures may invalidate local data',
      );
    }
    final activeGroup = await _groupRepo.getActiveGroup();
    if (activeGroup == null || activeGroup.groupId != groupId) {
      _invalidate();
      return const GroupValidityResult.noGroup();
    }
    return _invalidateLocalGroup(
      groupId,
      reason,
      cleanupMode: statusCode == 404
          ? LocalGroupCleanupMode.delete
          : LocalGroupCleanupMode.deactivate,
    );
  }

  Future<GroupValidityResult> _invalidateLocalGroup(
    String groupId,
    String reason, {
    required LocalGroupCleanupMode cleanupMode,
  }) async {
    await _invalidationCleanup.execute(groupId: groupId, mode: cleanupMode);
    _invalidate();
    return GroupValidityResult.invalid(reason);
  }

  GroupValidityResult _cache(GroupValidityResult result) {
    _cachedResult = result;
    _lastCheckTime = DateTime.now();
    return result;
  }

  void _invalidate() {
    _cachedResult = null;
    _lastCheckTime = null;
  }
}
