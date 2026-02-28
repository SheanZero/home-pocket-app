import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/family_sync/confirm_pair_use_case.dart';
import '../../../../application/family_sync/create_pair_use_case.dart';
import '../../../../application/family_sync/join_pair_use_case.dart';
import '../../../../application/family_sync/unpair_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

part 'pair_providers.g.dart';

/// CreatePairUseCase provider.
@riverpod
CreatePairUseCase createPairUseCase(Ref ref) {
  return CreatePairUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    pairRepo: ref.watch(pairRepositoryProvider),
  );
}

/// JoinPairUseCase provider.
@riverpod
JoinPairUseCase joinPairUseCase(Ref ref) {
  return JoinPairUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    pairRepo: ref.watch(pairRepositoryProvider),
  );
}

/// ConfirmPairUseCase provider.
@riverpod
ConfirmPairUseCase confirmPairUseCase(Ref ref) {
  return ConfirmPairUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    pairRepo: ref.watch(pairRepositoryProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
  );
}

/// UnpairUseCase provider.
@riverpod
UnpairUseCase unpairUseCase(Ref ref) {
  return UnpairUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    pairRepo: ref.watch(pairRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
  );
}
