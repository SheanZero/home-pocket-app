import '../../features/accounting/domain/repositories/device_identity_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';

/// Device identity repository backed by crypto key manager.
class DeviceIdentityRepositoryImpl implements DeviceIdentityRepository {
  DeviceIdentityRepositoryImpl({required KeyManager keyManager})
    : _keyManager = keyManager;

  final KeyManager _keyManager;

  @override
  Future<String?> getDeviceId() => _keyManager.getDeviceId();
}
