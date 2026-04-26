import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

sealed class RegenerateInviteResult {
  const RegenerateInviteResult();

  const factory RegenerateInviteResult.success({
    required String inviteCode,
    required int expiresAt,
  }) = RegenerateInviteSuccess;

  const factory RegenerateInviteResult.error(String message) =
      RegenerateInviteError;
}

class RegenerateInviteSuccess extends RegenerateInviteResult {
  const RegenerateInviteSuccess({
    required this.inviteCode,
    required this.expiresAt,
  });

  final String inviteCode;
  final int expiresAt;
}

class RegenerateInviteError extends RegenerateInviteResult {
  const RegenerateInviteError(this.message);

  final String message;
}

class RegenerateInviteUseCase {
  RegenerateInviteUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  Future<RegenerateInviteResult> execute(String groupId) async {
    try {
      final response = await _apiClient.regenerateInvite(groupId);
      final inviteCode = response['inviteCode'] as String;
      final expiresAt = response['expiresAt'] as int;

      await _groupRepository.updateInviteCode(
        groupId,
        inviteCode,
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
      );

      return RegenerateInviteResult.success(
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    } on RelayApiException catch (error) {
      return RegenerateInviteResult.error(error.message);
    } catch (error) {
      return RegenerateInviteResult.error(
        'Failed to regenerate invite: $error',
      );
    }
  }
}
