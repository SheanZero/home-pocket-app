import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/crypto/providers.dart';
import '../../use_cases/check_group_use_case.dart';
import '../../use_cases/confirm_member_use_case.dart';
import '../../use_cases/create_group_use_case.dart';
import '../../use_cases/deactivate_group_use_case.dart';
import '../../use_cases/join_group_use_case.dart';
import '../../use_cases/leave_group_use_case.dart';
import '../../use_cases/remove_member_use_case.dart';
import '../../use_cases/regenerate_invite_use_case.dart';
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

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(
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
