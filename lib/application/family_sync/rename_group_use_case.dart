import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class RenameGroupResult {
  const RenameGroupResult();

  const factory RenameGroupResult.success(String groupName) =
      RenameGroupSuccess;

  const factory RenameGroupResult.error(String message) = RenameGroupError;
}

class RenameGroupSuccess extends RenameGroupResult {
  const RenameGroupSuccess(this.groupName);

  final String groupName;
}

class RenameGroupError extends RenameGroupResult {
  const RenameGroupError(this.message);

  final String message;
}

/// Renames a group with server-first update strategy.
///
/// Non-optimistic: calls server first, then updates local DB on success.
/// If server fails, local DB is NOT updated.
class RenameGroupUseCase {
  RenameGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  static const _maxNameLength = 50;

  Future<RenameGroupResult> execute({
    required String groupId,
    required String groupName,
  }) async {
    final trimmedName = groupName.trim();

    if (trimmedName.isEmpty) {
      return const RenameGroupResult.error('Group name cannot be empty');
    }

    if (trimmedName.length > _maxNameLength) {
      return const RenameGroupResult.error(
        'Group name cannot exceed 50 characters',
      );
    }

    try {
      await _apiClient.renameGroup(
        groupId: groupId,
        groupName: trimmedName,
      );

      await _groupRepository.updateGroupName(groupId, trimmedName);

      return RenameGroupResult.success(trimmedName);
    } on RelayApiException catch (error) {
      return RenameGroupResult.error(error.message);
    } catch (error) {
      return RenameGroupResult.error('Failed to rename group: $error');
    }
  }
}
