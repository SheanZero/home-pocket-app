import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'full_sync_use_case.dart';
import 'sync_avatar_use_case.dart';

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

/// Confirms a pending member in the group and exchanges the group key.
///
/// Migrated from `features/family_sync/use_cases/` with optional avatar sync.
/// After confirming and running full sync, triggers a non-blocking avatar push
/// so the new member receives the owner's avatar.
class ConfirmMemberUseCase {
  ConfirmMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required E2EEService e2eeService,
    FullSyncUseCase? fullSync,
    SyncAvatarUseCase? syncAvatar,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService,
       _fullSync = fullSync,
       _syncAvatar = syncAvatar;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;
  final FullSyncUseCase? _fullSync;
  final SyncAvatarUseCase? _syncAvatar;

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

      // Non-blocking avatar push to share profile with new member
      _syncAvatar?.pushAvatarToMembers(groupId: groupId).ignore();

      return const ConfirmMemberResult.success();
    } on RelayApiException catch (error) {
      return ConfirmMemberResult.error(error.message);
    } catch (error) {
      return ConfirmMemberResult.error('Failed to confirm member: $error');
    }
  }
}
