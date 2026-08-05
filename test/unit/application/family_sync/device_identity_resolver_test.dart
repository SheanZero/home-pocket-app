import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/device_identity_resolver.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockKeyManager keyManager;
  late DeviceIdentityResolver resolver;

  setUp(() {
    keyManager = MockKeyManager();
    resolver = DeviceIdentityResolver(keyManager);
  });

  test(
    'returns the persisted identity without generating a replacement',
    () async {
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => keyManager.getPublicKey(),
      ).thenAnswer((_) async => 'public-key');

      final identity = await resolver.resolve();

      expect(identity, isNotNull);
      expect(identity!.deviceId, 'device-1');
      expect(identity.publicKey, 'public-key');
      expect(identity.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      verifyNever(() => keyManager.hasKeyPair());
      verifyNever(() => keyManager.generateDeviceKeyPair());
    },
  );

  test('generates and returns a key pair when no key pair exists', () async {
    final generated = DeviceKeyPair(
      publicKey: 'generated-public-key',
      deviceId: 'generated-device',
      createdAt: DateTime(2026, 8, 6),
    );
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => null);
    when(() => keyManager.hasKeyPair()).thenAnswer((_) async => false);
    when(
      () => keyManager.generateDeviceKeyPair(),
    ).thenAnswer((_) async => generated);

    final identity = await resolver.resolve();

    expect(identity, same(generated));
    expect(identity!.createdAt, DateTime(2026, 8, 6));
    verify(() => keyManager.generateDeviceKeyPair()).called(1);
  });

  test(
    'preserves an incomplete existing key pair instead of overwriting it',
    () async {
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(() => keyManager.getPublicKey()).thenAnswer((_) async => null);
      when(() => keyManager.hasKeyPair()).thenAnswer((_) async => true);

      final identity = await resolver.resolve();

      expect(identity, isNull);
      verifyNever(() => keyManager.generateDeviceKeyPair());
    },
  );

  test('propagates identity-store failures unchanged', () async {
    final error = StateError('device id unavailable');
    when(() => keyManager.getDeviceId()).thenThrow(error);

    expect(resolver.resolve(), throwsA(same(error)));
    verifyNever(() => keyManager.generateDeviceKeyPair());
  });
}
