import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';

/// Resolves the device identity used when a family-sync flow registers.
///
/// An existing key pair with incomplete public identity is deliberately not
/// replaced: regenerating it would invalidate locally held encrypted data.
class DeviceIdentityResolver {
  DeviceIdentityResolver(this._keyManager);

  final KeyManager _keyManager;

  Future<DeviceKeyPair?> resolve() async {
    final existingDeviceId = await _keyManager.getDeviceId();
    final existingPublicKey = await _keyManager.getPublicKey();

    if (existingDeviceId != null && existingPublicKey != null) {
      return DeviceKeyPair(
        publicKey: existingPublicKey,
        deviceId: existingDeviceId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    if (!await _keyManager.hasKeyPair()) {
      return _keyManager.generateDeviceKeyPair();
    }

    return null;
  }
}
