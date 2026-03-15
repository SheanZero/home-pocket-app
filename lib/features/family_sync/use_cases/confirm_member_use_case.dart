import '../../../application/family_sync/full_sync_use_case.dart';
import '../../../infrastructure/sync/e2ee_service.dart';
import '../../../infrastructure/sync/relay_api_client.dart';
import '../domain/repositories/group_repository.dart';

sealed class ConfirmMemberResult {
  const ConfirmMemberResult();

  const factory ConfirmMemberResult.success() = ConfirmMemberSuccess;

  const factory ConfirmMemberResult.error(String message) = ConfirmMemberError;
}

class ConfirmMemberSuccess extends ConfirmMemberResult {
  const ConfirmMemberSuccess();
}

class ConfirmMemberError extends ConfirmMemberResult {
  const ConfirmMemberError(this.message);

  final String message;
}

class ConfirmMemberUseCase {
  ConfirmMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required E2EEService e2eeService,
    FullSyncUseCase? fullSync,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService,
       _fullSync = fullSync;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;
  final FullSyncUseCase? _fullSync;

  Future<ConfirmMemberResult> execute({
    required String groupId,
    required String deviceId,
  }) async {
    try {
      await _apiClient.confirmMember(groupId: groupId, deviceId: deviceId);
      await _groupRepository.activateMember(groupId, deviceId);

      final group = await _groupRepository.getGroupById(groupId);
      if (group?.groupKey != null) {
        final member = group!.members.firstWhere(
          (candidate) => candidate.deviceId == deviceId,
          orElse: () => throw StateError('Member not found locally'),
        );
        final keyExchangePayload = await _e2eeService.encryptGroupKeyForMember(
          groupKeyBase64: group.groupKey!,
          memberDeviceId: member.deviceId,
          memberPublicKey: member.publicKey,
        );

        await _apiClient.pushSync(
          groupId: groupId,
          payload: keyExchangePayload,
          vectorClock: const {},
          operationCount: 0,
        );
      }

      await _fullSync?.execute();

      return const ConfirmMemberResult.success();
    } on RelayApiException catch (error) {
      return ConfirmMemberResult.error(error.message);
    } catch (error) {
      return ConfirmMemberResult.error('Failed to confirm member: $error');
    }
  }
}
