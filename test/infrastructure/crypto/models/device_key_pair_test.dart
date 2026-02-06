import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';

void main() {
  group('DeviceKeyPair', () {
    test('creates instance with required fields', () {
      final now = DateTime(2026, 2, 6);
      final keyPair = DeviceKeyPair(
        publicKey: 'dGVzdF9wdWJsaWNfa2V5',
        deviceId: 'abc123def456ghij',
        createdAt: now,
      );

      expect(keyPair.publicKey, 'dGVzdF9wdWJsaWNfa2V5');
      expect(keyPair.deviceId, 'abc123def456ghij');
      expect(keyPair.createdAt, now);
    });

    test('supports equality comparison', () {
      final now = DateTime(2026, 2, 6);
      final a = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );
      final b = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('supports copyWith', () {
      final now = DateTime(2026, 2, 6);
      final original = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: now,
      );
      final copied = original.copyWith(deviceId: 'device2');

      expect(copied.publicKey, 'key1');
      expect(copied.deviceId, 'device2');
      expect(copied.createdAt, now);
    });

    test('different instances are not equal', () {
      final a = DeviceKeyPair(
        publicKey: 'key1',
        deviceId: 'device1',
        createdAt: DateTime(2026, 2, 6),
      );
      final b = DeviceKeyPair(
        publicKey: 'key2',
        deviceId: 'device2',
        createdAt: DateTime(2026, 2, 7),
      );

      expect(a, isNot(equals(b)));
    });
  });
}
