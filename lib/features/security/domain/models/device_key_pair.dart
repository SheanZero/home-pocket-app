import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_key_pair.freezed.dart';

@freezed
class DeviceKeyPair with _$DeviceKeyPair {
  const factory DeviceKeyPair({
    required String publicKey,  // Base64编码的Ed25519公钥
    required String deviceId,   // SHA-256哈希前16字符
    required DateTime createdAt,
  }) = _DeviceKeyPair;
}
