import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockKeyManager extends Mock implements KeyManager {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient apiClient;
  late MockKeyManager keyManager;
  late MockGroupRepository groupRepository;
  late JoinGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
    groupRepository = MockGroupRepository();
    useCase = JoinGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
    );

    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');
    when(() => groupRepository.getCurrentGroup()).thenAnswer((_) async => null);
    when(
      () => apiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
  });

  test('verifies group and returns group info without saving to DB', () async {
    var tokenReplayCalls = 0;
    useCase = JoinGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
      onDeviceRegistered: () async => tokenReplayCalls++,
    );
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'groupName': 'Smith Family',
        'members': [
          {
            'deviceId': 'owner-device',
            'publicKey': 'owner-public-key',
            'deviceName': 'Owner phone',
            'role': 'owner',
            'status': 'active',
            'displayName': 'Papa',
            'avatarEmoji': '\u{1F468}',
            'avatarImageHash': 'hash123',
          },
        ],
      },
    );

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupVerified>());
    final verified = result as JoinGroupVerified;
    expect(verified.groupId, 'group-1');
    expect(verified.groupName, 'Smith Family');
    expect(verified.ownerDeviceId, 'owner-device');
    expect(verified.ownerDisplayName, 'Papa');
    expect(verified.ownerAvatarEmoji, '\u{1F468}');
    expect(verified.ownerAvatarImageHash, 'hash123');
    expect(tokenReplayCalls, 1);
  });

  test('passes optional avatarImageHash to API', () async {
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'groupName': 'Test Family',
        'members': [
          {
            'deviceId': 'owner-device',
            'publicKey': 'owner-key',
            'deviceName': 'Phone',
            'role': 'owner',
            'status': 'active',
            'displayName': 'Owner',
            'avatarEmoji': '\u{1F3E0}',
          },
        ],
      },
    );

    await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
      avatarImageHash: 'img-hash-456',
    );

    verify(
      () => apiClient.joinGroup(
        inviteCode: 'INV123',
        displayName: 'Mama',
        avatarEmoji: '\u{1F469}',
        avatarImageHash: 'img-hash-456',
      ),
    ).called(1);
  });

  test('generates keys if the device has not been initialized', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => null);
    when(() => keyManager.hasKeyPair()).thenAnswer((_) async => false);
    when(() => keyManager.generateDeviceKeyPair()).thenAnswer(
      (_) async => DeviceKeyPair(
        publicKey: 'generated-public-key',
        deviceId: 'generated-device',
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'groupName': 'Test Family',
        'members': [
          {
            'deviceId': 'owner-device',
            'publicKey': 'owner-key',
            'deviceName': 'Phone',
            'role': 'owner',
            'status': 'active',
            'displayName': 'Owner',
            'avatarEmoji': '\u{1F3E0}',
          },
        ],
      },
    );

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupVerified>());
    verify(() => keyManager.generateDeviceKeyPair()).called(1);
    verify(
      () => apiClient.registerDevice(
        deviceId: 'generated-device',
        publicKey: 'generated-public-key',
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).called(1);
  });

  test('maps not-found error to user-facing message', () async {
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenThrow(const RelayApiException(statusCode: 404, message: 'Not found'));

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupError>());
    expect(
      (result as JoinGroupError).message,
      'Invite code not found or expired',
    );
  });

  test('maps conflict error to user-facing message', () async {
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenThrow(const RelayApiException(statusCode: 409, message: 'Conflict'));

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupError>());
    expect(
      (result as JoinGroupError).message,
      'Already a member of this group',
    );
  });

  test('maps server single-group conflict to typed conflict', () async {
    when(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenThrow(
      const RelayApiException(
        statusCode: 409,
        message: 'device already grouped',
        code: 'device_already_grouped',
      ),
    );

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupError>());
    expect(
      (result as JoinGroupError).kind,
      GroupOperationErrorKind.membershipConflict,
    );
  });

  test('blocks invite verification when a local live group exists', () async {
    when(() => groupRepository.getCurrentGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'existing-group',
        status: GroupStatus.pending,
        groupName: 'Existing',
        role: 'owner',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupError>());
    expect(
      (result as JoinGroupError).kind,
      GroupOperationErrorKind.membershipConflict,
    );
    verifyNever(
      () => apiClient.joinGroup(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    );
  });

  test('returns error when device identity cannot be resolved', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => null);
    when(() => keyManager.hasKeyPair()).thenAnswer((_) async => true);

    final result = await useCase.execute(
      inviteCode: 'INV123',
      displayName: 'Mama',
      avatarEmoji: '\u{1F469}',
    );

    expect(result, isA<JoinGroupError>());
    expect((result as JoinGroupError).message, 'Device key not initialized');
  });
}
