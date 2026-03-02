import '../../../infrastructure/sync/relay_api_client.dart';
import '../domain/repositories/group_repository.dart';

sealed class RemoveMemberResult {
  const RemoveMemberResult();

  const factory RemoveMemberResult.success() = RemoveMemberSuccess;
  const factory RemoveMemberResult.error(String message) = RemoveMemberError;
}

class RemoveMemberSuccess extends RemoveMemberResult {
  const RemoveMemberSuccess();
}

class RemoveMemberError extends RemoveMemberResult {
  const RemoveMemberError(this.message);

  final String message;
}

class RemoveMemberUseCase {
  RemoveMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  Future<RemoveMemberResult> execute({
    required String groupId,
    required String deviceId,
  }) async {
    try {
      await _apiClient.removeMember(groupId: groupId, deviceId: deviceId);
      final group = await _groupRepository.getGroupById(groupId);
      if (group != null) {
        final remainingMembers = group.members
            .where((member) => member.deviceId != deviceId)
            .toList();
        await _groupRepository.updateMembers(groupId, remainingMembers);
      }
      return const RemoveMemberResult.success();
    } on RelayApiException catch (error) {
      return RemoveMemberResult.error(error.message);
    } catch (error) {
      return RemoveMemberResult.error('Failed to remove member: $error');
    }
  }
}
