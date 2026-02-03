import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/security/domain/models/device_key_pair.dart';

void main() {
  group('DeviceKeyPair', () {
    test('should create valid DeviceKeyPair', () {
      final now = DateTime.now();
      final keyPair = DeviceKeyPair(
        publicKey: 'test_public_key_base64',
        deviceId: 'abcd1234efgh5678',
        createdAt: now,
      );

      expect(keyPair.publicKey, 'test_public_key_base64');
      expect(keyPair.deviceId, 'abcd1234efgh5678');
      expect(keyPair.deviceId.length, 16);
      expect(keyPair.createdAt, now);
    });

    test('should be immutable', () {
      final keyPair = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'id1_12345678901',
        createdAt: DateTime.now(),
      );

      final copied = keyPair.copyWith(deviceId: 'id2_12345678902');

      expect(keyPair.deviceId, 'id1_12345678901');
      expect(copied.deviceId, 'id2_12345678902');
      expect(keyPair.publicKey, copied.publicKey);
    });

    test('should support equality comparison', () {
      final now = DateTime.now();
      final keyPair1 = DeviceKeyPair(
        publicKey: 'key',
        deviceId: 'id12345678901234',
        createdAt: now,
      );

      final keyPair2 = DeviceKeyPair(
        publicKey: 'key',
        deviceId: 'id12345678901234',
        createdAt: now,
      );

      expect(keyPair1, equals(keyPair2));
    });
  });
}
