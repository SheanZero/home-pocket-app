import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../infrastructure/crypto/services/key_manager.dart';

part 'current_device_provider.g.dart';

/// Provider for current device ID
///
/// Returns the device ID from KeyManager.
/// Each device has a unique cryptographic identity.
@riverpod
Future<String> currentDeviceId(Ref ref) async {
  final keyManager = ref.watch(keyManagerProvider);
  final deviceId = await keyManager.getDeviceId();

  if (deviceId == null) {
    throw Exception(
        'Device ID not found. Please initialize device key pair first.');
  }

  return deviceId;
}
