import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/confirm_member_use_case.dart';
import '../../../../application/family_sync/create_group_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../../../application/family_sync/check_group_use_case.dart';
import '../../../../application/family_sync/deactivate_group_use_case.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/regenerate_invite_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import 'avatar_sync_providers.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});

final confirmJoinUseCaseProvider = Provider<ConfirmJoinUseCase>((ref) {
  return ConfirmJoinUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final renameGroupUseCaseProvider = Provider<RenameGroupUseCase>((ref) {
  return RenameGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final confirmMemberUseCaseProvider = Provider<ConfirmMemberUseCase>((ref) {
  return ConfirmMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
    syncAvatar: ref.watch(syncAvatarUseCaseProvider),
  );
});

final leaveGroupUseCaseProvider = Provider<LeaveGroupUseCase>((ref) {
  return LeaveGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
});

final deactivateGroupUseCaseProvider = Provider<DeactivateGroupUseCase>((ref) {
  return DeactivateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
});

final regenerateInviteUseCaseProvider = Provider<RegenerateInviteUseCase>((
  ref,
) {
  return RegenerateInviteUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});
