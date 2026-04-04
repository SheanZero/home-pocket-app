import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockKeyManager extends Mock implements KeyManager {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockE2EEService extends Mock implements E2EEService {}

void main() {
  late MockRelayApiClient apiClient;
  late MockKeyManager keyManager;
  late MockGroupRepository groupRepository;
  late MockE2EEService e2eeService;
  late CreateGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
    groupRepository = MockGroupRepository();
    e2eeService = MockE2EEService();
    useCase = CreateGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
      e2eeService: e2eeService,
    );

    when(
      () => apiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => apiClient.createGroup(
        groupName: any(named: 'groupName'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'inviteCode': 'INV123',
        'expiresAt': 1,
      },
    );
    when(() => e2eeService.generateGroupKey()).thenReturn('group-key');
    when(
      () => groupRepository.savePendingGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        inviteCode: any(named: 'inviteCode'),
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
        groupKey: any(named: 'groupKey'),
      ),
    ).thenAnswer((_) async {});
  });

  test('creates group with profile fields using existing device keys',
      () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');

    final result = await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
    );

    expect(result, isA<CreateGroupSuccess>());
    final success = result as CreateGroupSuccess;
    expect(success.groupId, 'group-1');
    expect(success.inviteCode, 'INV123');
    expect(success.expiresAt, 1);

    verify(
      () => apiClient.createGroup(
        groupName: 'Smith Family',
        displayName: 'Papa',
        avatarEmoji: '\u{1F468}',
        avatarImageHash: null,
      ),
    ).called(1);
    verify(
      () => groupRepository.savePendingGroup(
        groupId: 'group-1',
        groupName: 'Smith Family',
        inviteCode: 'INV123',
        inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(1000),
        groupKey: 'group-key',
      ),
    ).called(1);
  });

  test('passes optional avatarImageHash to API', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');

    await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
      avatarImageHash: 'abc123',
    );

    verify(
      () => apiClient.createGroup(
        groupName: 'Smith Family',
        displayName: 'Papa',
        avatarEmoji: '\u{1F468}',
        avatarImageHash: 'abc123',
      ),
    ).called(1);
  });

  test('generates a device key pair when one does not exist', () async {
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

    final result = await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
    );

    expect(result, isA<CreateGroupSuccess>());
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

  test('returns error when device identity cannot be resolved', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => null);
    when(() => keyManager.hasKeyPair()).thenAnswer((_) async => true);

    final result = await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
    );

    expect(result, isA<CreateGroupError>());
    expect(
      (result as CreateGroupError).message,
      'Device key not initialized',
    );
  });

  test('returns error on incomplete server response', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');
    when(
      () => apiClient.createGroup(
        groupName: any(named: 'groupName'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer((_) async => {'groupId': 'group-1'});

    final result = await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
    );

    expect(result, isA<CreateGroupError>());
    expect(
      (result as CreateGroupError).message,
      contains('Server returned incomplete response'),
    );
  });

  test('returns API errors from the relay client', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');
    when(
      () => apiClient.createGroup(
        groupName: any(named: 'groupName'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenThrow(
      const RelayApiException(statusCode: 409, message: 'Already grouped'),
    );

    final result = await useCase.execute(
      displayName: 'Papa',
      avatarEmoji: '\u{1F468}',
      groupName: 'Smith Family',
    );

    expect(result, isA<CreateGroupError>());
    expect((result as CreateGroupError).message, 'Already grouped');
  });
}
