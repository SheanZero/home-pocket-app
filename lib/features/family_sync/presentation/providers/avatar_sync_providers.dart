import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/sync_avatar_use_case.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import 'repository_providers.dart';

final syncAvatarUseCaseProvider = Provider<SyncAvatarUseCase>((ref) {
  return SyncAvatarUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
});
