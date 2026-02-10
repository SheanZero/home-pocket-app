/// Abstract repository for current device identity.
abstract class DeviceIdentityRepository {
  /// Returns current device ID, or null when unavailable.
  Future<String?> getDeviceId();
}
