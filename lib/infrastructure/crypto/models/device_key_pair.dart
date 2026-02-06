import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_key_pair.freezed.dart';

/// Device key pair model - UNIQUE definition.
///
/// Represents an Ed25519 key pair for this device.
/// All code that needs device key pair info MUST import from this file.
@freezed
abstract class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    /// Base64-encoded Ed25519 public key (32 bytes).
    required String publicKey,

    /// Device ID: Base64URL(SHA-256(publicKey))[0:16].
    required String deviceId,

    /// Timestamp when the key pair was generated.
    required DateTime createdAt,
  }) = _DeviceKeyPair;
}
