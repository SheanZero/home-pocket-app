import 'dart:io';

import '../../features/family_sync/domain/repositories/pair_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

/// Result of creating a pairing request.
sealed class CreatePairResult {
  const CreatePairResult();

  const factory CreatePairResult.success({
    required String pairId,
    required String pairCode,
    required String qrData,
    required int expiresAt,
  }) = CreatePairSuccess;

  const factory CreatePairResult.error(String message) = CreatePairError;
}

class CreatePairSuccess extends CreatePairResult {
  const CreatePairSuccess({
    required this.pairId,
    required this.pairCode,
    required this.qrData,
    required this.expiresAt,
  });

  final String pairId;
  final String pairCode;
  final String qrData;
  final int expiresAt;
}

class CreatePairError extends CreatePairResult {
  const CreatePairError(this.message);

  final String message;
}

/// Creates a pairing request (Device A side).
///
/// Flow:
/// 1. Register device with server (idempotent, unauthenticated)
/// 2. Create pair request on server
/// 3. Save pending pair locally
class CreatePairUseCase {
  CreatePairUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required PairRepository pairRepo,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _pairRepo = pairRepo;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final PairRepository _pairRepo;

  Future<CreatePairResult> execute(String bookId) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      final publicKey = await _keyManager.getPublicKey();

      if (deviceId == null || publicKey == null) {
        return const CreatePairResult.error('Device key not initialized');
      }

      final deviceName = Platform.localHostname;

      // 1. Register device (idempotent, no auth required)
      await _apiClient.registerDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 2. Create pair on server
      final response = await _apiClient.createPair(
        bookId: bookId,
        publicKey: publicKey,
        deviceName: deviceName,
      );

      final pairId = response['pairId'] as String;
      final pairCode = response['pairCode'] as String;
      final qrData = response['qrData'] as String;
      final expiresAt = response['expiresAt'] as int;

      // 3. Save pending pair locally
      await _pairRepo.savePendingPair(
        pairId: pairId,
        bookId: bookId,
        pairCode: pairCode,
        expiresAt:
            DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
      );

      return CreatePairResult.success(
        pairId: pairId,
        pairCode: pairCode,
        qrData: qrData,
        expiresAt: expiresAt,
      );
    } on RelayApiException catch (e) {
      return CreatePairResult.error(e.message);
    } catch (e) {
      return CreatePairResult.error(e.toString());
    }
  }
}
