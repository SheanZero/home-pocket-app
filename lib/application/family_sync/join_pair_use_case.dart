import 'dart:io';

import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

/// Result of joining a pair.
sealed class JoinPairResult {
  const JoinPairResult();

  const factory JoinPairResult.success({
    required String pairId,
    required String partnerDeviceName,
  }) = JoinPairSuccess;

  const factory JoinPairResult.error(String message) = JoinPairError;
}

class JoinPairSuccess extends JoinPairResult {
  const JoinPairSuccess({
    required this.pairId,
    required this.partnerDeviceName,
  });

  final String pairId;
  final String partnerDeviceName;
}

class JoinPairError extends JoinPairResult {
  const JoinPairError(this.message);

  final String message;
}

/// Joins an existing pair using a short code (Device B side).
///
/// Flow:
/// 1. Register device with server (idempotent, unauthenticated)
/// 2. Join pair on server with code
/// 3. Save as confirming pair locally (not active yet)
///
/// After this, Device B waits for Device A to confirm.
/// On push notification `pair_confirmed`, confirmLocalPair() is called.
class JoinPairUseCase {
  JoinPairUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required PairRepository pairRepo,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _pairRepo = pairRepo;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final PairRepository _pairRepo;

  Future<JoinPairResult> execute(String pairCode) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      final publicKey = await _keyManager.getPublicKey();

      if (deviceId == null || publicKey == null) {
        return const JoinPairResult.error('Device key not initialized');
      }

      final deviceName = Platform.localHostname;

      // 1. Register device (idempotent, no auth required)
      await _apiClient.registerDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 2. Join pair on server
      final response = await _apiClient.joinPair(
        pairCode: pairCode,
        publicKey: publicKey,
        deviceName: deviceName,
      );

      final pairId = response['pairId'] as String;
      final partnerDeviceId = response['partnerDeviceId'] as String;
      final partnerPublicKey = response['partnerPublicKey'] as String;
      final partnerDeviceName = response['partnerDeviceName'] as String;

      // 3. Save as confirming pair (getActivePair() won't return this)
      await _pairRepo.saveConfirmingPair(
        pairId: pairId,
        bookId: '', // bookId is associated with the pair on server side
        partnerDeviceId: partnerDeviceId,
        partnerPublicKey: partnerPublicKey,
        partnerDeviceName: partnerDeviceName,
      );

      return JoinPairResult.success(
        pairId: pairId,
        partnerDeviceName: partnerDeviceName,
      );
    } on RelayApiException catch (e) {
      if (e.isNotFound) {
        return const JoinPairResult.error(
          'Pair code not found or expired',
        );
      }
      return JoinPairResult.error(e.message);
    } catch (e) {
      return JoinPairResult.error(e.toString());
    }
  }
}
