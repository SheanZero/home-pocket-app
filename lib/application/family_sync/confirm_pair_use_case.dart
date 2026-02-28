import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'full_sync_use_case.dart';

/// Result of confirming a pair.
sealed class ConfirmPairResult {
  const ConfirmPairResult();

  const factory ConfirmPairResult.success() = ConfirmPairSuccess;
  const factory ConfirmPairResult.error(String message) = ConfirmPairError;
}

class ConfirmPairSuccess extends ConfirmPairResult {
  const ConfirmPairSuccess();
}

class ConfirmPairError extends ConfirmPairResult {
  const ConfirmPairError(this.message);

  final String message;
}

/// Confirms a pairing request (Device A side).
///
/// Flow:
/// 1. Confirm pair on server (accept or reject)
/// 2. If accepted: activate pair locally + initialize E2EE
/// 3. Trigger full sync to push all existing transactions to partner
class ConfirmPairUseCase {
  ConfirmPairUseCase({
    required RelayApiClient apiClient,
    required PairRepository pairRepo,
    required FullSyncUseCase fullSync,
  })  : _apiClient = apiClient,
        _pairRepo = pairRepo,
        _fullSync = fullSync;

  final RelayApiClient _apiClient;
  final PairRepository _pairRepo;
  final FullSyncUseCase _fullSync;

  Future<ConfirmPairResult> execute({
    required String pairId,
    required String bookId,
    required bool accept,
  }) async {
    try {
      final response = await _apiClient.confirmPair(
        pairId: pairId,
        accept: accept,
      );

      if (!accept) {
        return const ConfirmPairResult.success();
      }

      final partnerDeviceId = response['partnerDeviceId'] as String?;
      final partnerPublicKey = response['partnerPublicKey'] as String?;
      final partnerDeviceName = response['partnerDeviceName'] as String?;

      if (partnerDeviceId == null ||
          partnerPublicKey == null ||
          partnerDeviceName == null) {
        return const ConfirmPairResult.error(
          'Server did not return partner info',
        );
      }

      // Activate pair locally (pending -> active)
      await _pairRepo.activatePair(
        pairId: pairId,
        bookId: bookId,
        partnerDeviceId: partnerDeviceId,
        partnerPublicKey: partnerPublicKey,
        partnerDeviceName: partnerDeviceName,
      );

      // Initialize E2EE shared secret for this partner
      // (Not stored persistently - will be re-derived when needed)

      // Trigger full sync to push all existing local transactions
      await _fullSync.execute(bookId);

      return const ConfirmPairResult.success();
    } on RelayApiException catch (e) {
      return ConfirmPairResult.error(e.message);
    } catch (e) {
      return ConfirmPairResult.error(e.toString());
    }
  }
}
