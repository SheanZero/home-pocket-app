import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class ManageGroupInviteResult {
  const ManageGroupInviteResult();
}

class ManageGroupInviteSuccess extends ManageGroupInviteResult {
  const ManageGroupInviteSuccess({
    required this.inviteCode,
    required this.expiresAt,
    required this.wasRegenerated,
  });

  final String inviteCode;
  final DateTime expiresAt;
  final bool wasRegenerated;
}

class ManageGroupInviteForbidden extends ManageGroupInviteResult {
  const ManageGroupInviteForbidden();
}

class ManageGroupInviteError extends ManageGroupInviteResult {
  const ManageGroupInviteError(this.message);

  final String message;
}

/// Resolves the invite an owner should present to a prospective member.
///
/// A locally cached invite remains authoritative until it expires. The server
/// is only asked to rotate it when it is missing, expired, or the owner
/// explicitly requests a refresh. Server success is persisted before the new
/// code is returned so UI and later shares cannot observe different values.
class ManageGroupInviteUseCase {
  ManageGroupInviteUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    DateTime Function()? now,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _now = now ?? DateTime.now;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final DateTime Function() _now;

  Future<ManageGroupInviteResult> execute({
    required String groupId,
    bool forceRefresh = false,
  }) async {
    try {
      final group = await _groupRepository.getGroupById(groupId);
      if (group == null) {
        return const ManageGroupInviteError('Group not found');
      }
      if (group.role != 'owner') {
        return const ManageGroupInviteForbidden();
      }
      if (group.status != GroupStatus.active) {
        return const ManageGroupInviteError('Group is not active');
      }

      final now = _now();
      final currentCode = group.inviteCode?.trim();
      final currentExpiry = group.inviteExpiresAt;
      final canReuse =
          !forceRefresh &&
          currentCode != null &&
          currentCode.isNotEmpty &&
          currentExpiry != null &&
          currentExpiry.isAfter(now);

      if (canReuse) {
        return ManageGroupInviteSuccess(
          inviteCode: currentCode,
          expiresAt: currentExpiry,
          wasRegenerated: false,
        );
      }

      final response = await _apiClient.regenerateInvite(groupId);
      final inviteCode = response['inviteCode']?.toString().trim() ?? '';
      final expiresAtSeconds = response['expiresAt'];
      if (inviteCode.isEmpty || expiresAtSeconds is! num) {
        return const ManageGroupInviteError(
          'Server returned an invalid invite',
        );
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        expiresAtSeconds.toInt() * 1000,
      );
      if (!expiresAt.isAfter(now)) {
        return const ManageGroupInviteError(
          'Server returned an expired invite',
        );
      }

      await _groupRepository.updateInviteCode(groupId, inviteCode, expiresAt);
      return ManageGroupInviteSuccess(
        inviteCode: inviteCode,
        expiresAt: expiresAt,
        wasRegenerated: true,
      );
    } on RelayApiException catch (error) {
      return ManageGroupInviteError(error.message);
    } catch (error) {
      return ManageGroupInviteError(error.toString());
    }
  }
}
