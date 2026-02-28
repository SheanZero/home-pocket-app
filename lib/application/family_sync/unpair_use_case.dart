import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

/// Result of unpairing.
sealed class UnpairResult {
  const UnpairResult();

  const factory UnpairResult.success() = UnpairSuccess;
  const factory UnpairResult.error(String message) = UnpairError;
}

class UnpairSuccess extends UnpairResult {
  const UnpairSuccess();
}

class UnpairError extends UnpairResult {
  const UnpairError(this.message);

  final String message;
}

/// Deactivates an existing pair.
///
/// Flow:
/// 1. Notify server to deactivate pairing
/// 2. Clear offline sync queue
/// 3. Deactivate pair locally
class UnpairUseCase {
  UnpairUseCase({
    required RelayApiClient apiClient,
    required PairRepository pairRepo,
    required SyncQueueManager queueManager,
  })  : _apiClient = apiClient,
        _pairRepo = pairRepo,
        _queueManager = queueManager;

  final RelayApiClient _apiClient;
  final PairRepository _pairRepo;
  final SyncQueueManager _queueManager;

  Future<UnpairResult> execute(String pairId) async {
    try {
      // 1. Notify server
      await _apiClient.unpair(pairId);

      // 2. Clear offline queue
      await _queueManager.clearQueue();

      // 3. Deactivate locally
      await _pairRepo.deactivatePair(pairId);

      return const UnpairResult.success();
    } on RelayApiException catch (e) {
      return UnpairResult.error(e.message);
    } catch (e) {
      return UnpairResult.error(e.toString());
    }
  }
}
