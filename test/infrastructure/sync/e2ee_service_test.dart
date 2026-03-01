import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/key_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:mocktail/mocktail.dart';

class MockKeyRepository extends Mock implements KeyRepository {}

void main() {
  late MockKeyRepository ownerRepository;
  late MockKeyRepository memberRepository;
  late E2EEService ownerService;
  late E2EEService memberService;
  late String ownerPublicKeyBase64;
  late String memberPublicKeyBase64;

  setUp(() async {
    ownerRepository = MockKeyRepository();
    memberRepository = MockKeyRepository();

    final ed25519 = Ed25519();
    final ownerKeyPair = await ed25519.newKeyPair();
    final memberKeyPair = await ed25519.newKeyPair();
    final ownerPrivateSeed = await ownerKeyPair.extractPrivateKeyBytes();
    final memberPrivateSeed = await memberKeyPair.extractPrivateKeyBytes();
    final ownerPublicKey = await ownerKeyPair.extractPublicKey();
    final memberPublicKey = await memberKeyPair.extractPublicKey();

    ownerPublicKeyBase64 = base64Encode(ownerPublicKey.bytes);
    memberPublicKeyBase64 = base64Encode(memberPublicKey.bytes);

    when(
      () => ownerRepository.getPrivateKey(),
    ).thenAnswer((_) async => base64Encode(ownerPrivateSeed));
    when(
      () => memberRepository.getPrivateKey(),
    ).thenAnswer((_) async => base64Encode(memberPrivateSeed));

    ownerService = E2EEService(
      keyManager: KeyManager(repository: ownerRepository),
    );
    memberService = E2EEService(
      keyManager: KeyManager(repository: memberRepository),
    );
  });

  test('group key encrypt/decrypt round-trip', () {
    final groupKey = ownerService.generateGroupKey();
    const plaintext = '{"operations": []}';

    final encrypted = ownerService.encryptForGroup(
      plaintext: plaintext,
      groupKeyBase64: groupKey,
    );

    final decrypted = ownerService.decryptFromGroup(
      encryptedPayload: encrypted,
      groupKeyBase64: groupKey,
    );

    expect(decrypted, plaintext);
  });

  test('key exchange encrypt/decrypt round-trip', () async {
    final groupKey = ownerService.generateGroupKey();

    final encrypted = await ownerService.encryptGroupKeyForMember(
      groupKeyBase64: groupKey,
      memberDeviceId: 'member-device',
      memberPublicKey: memberPublicKeyBase64,
    );

    final decrypted = await memberService.decryptGroupKeyFromOwner(
      encryptedPayload: encrypted,
      ownerPublicKey: ownerPublicKeyBase64,
    );

    expect(decrypted, groupKey);
    expect(
      (jsonDecode(encrypted) as Map<String, dynamic>)['toDeviceId'],
      'member-device',
    );
  });

  test('detectPayloadType identifies v2 payloads and legacy payloads', () {
    expect(
      E2EEService.detectPayloadType('{"v":2,"t":"D","p":"base64data"}'),
      'v2_data',
    );
    expect(
      E2EEService.detectPayloadType('{"v":2,"t":"K","p":"base64data"}'),
      'v2_key',
    );
    expect(E2EEService.detectPayloadType('aGVsbG8gd29ybGQ='), 'v1');
  });
}
