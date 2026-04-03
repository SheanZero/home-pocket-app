import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'shadow_book_service.dart';

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
/// On invalid: cleans shadow books + deactivates group locally.
/// Offline-tolerant: returns valid on network errors.
class CheckGroupValidityUseCase {
  CheckGroupValidityUseCase({
    required GroupRepository groupRepo,
    required RelayApiClient apiClient,
    required ShadowBookService shadowBookService,
  }) : _groupRepo = groupRepo,
       _apiClient = apiClient,
       _shadowBookService = shadowBookService;

  final GroupRepository _groupRepo;
  final RelayApiClient _apiClient;
  final ShadowBookService _shadowBookService;

  DateTime? _lastCheckTime;
  GroupValidityResult? _cachedResult;
  static const _cacheDuration = Duration(minutes: 5);

  Future<GroupValidityResult> execute({bool forceCheck = false}) async {
    if (!forceCheck && _cachedResult != null && _lastCheckTime != null) {
      if (DateTime.now().difference(_lastCheckTime!) < _cacheDuration) {
        return _cachedResult!;
      }
    }

    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      return _cache(const GroupValidityResult.noGroup());
    }

    try {
      await _apiClient.checkGroup();
      return _cache(const GroupValidityResult.valid());
    } on RelayApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 403) {
        await _shadowBookService.cleanSyncData(group.groupId);
        await _groupRepo.deactivateGroup(group.groupId);
        _invalidate();
        return GroupValidityResult.invalid(
          e.statusCode == 404 ? 'Group dissolved' : 'Removed from group',
        );
      }
      // Other API errors → offline tolerance
      return _cache(const GroupValidityResult.valid());
    } catch (_) {
      // Network error → offline tolerance
      return _cache(const GroupValidityResult.valid());
    }
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
