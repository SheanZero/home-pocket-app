import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/join_group_use_case.dart';
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
    when(
      () => apiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.saveConfirmingGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        members: any(named: 'members'),
      ),
    ).thenAnswer((_) async {});
  });

  test('joins a group and persists confirming members', () async {
    when(
      () => apiClient.joinGroup(inviteCode: any(named: 'inviteCode')),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'bookId': 'book-1',
        'members': [
          {
            'deviceId': 'owner-device',
            'publicKey': 'owner-public-key',
            'deviceName': 'Owner phone',
            'role': 'owner',
            'status': 'active',
            'displayName': 'Owner',
            'avatarEmoji': '🏠',
          },
        ],
      },
    );

    final result = await useCase.execute('INV123');

    expect(result, isA<JoinGroupSuccess>());
    verify(
      () => groupRepository.saveConfirmingGroup(
        groupId: 'group-1',
        groupName: '',
        members: [
          const GroupMember(
            deviceId: 'owner-device',
            publicKey: 'owner-public-key',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
            displayName: 'Owner',
            avatarEmoji: '🏠',
          ),
        ],
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
      () => apiClient.joinGroup(inviteCode: any(named: 'inviteCode')),
    ).thenAnswer(
      (_) async => {
        'groupId': 'group-1',
        'bookId': 'book-1',
        'members': <Map<String, dynamic>>[],
      },
    );

    await useCase.execute('INV123');

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

  test('maps not-found and conflict errors to user-facing messages', () async {
    when(
      () => apiClient.joinGroup(inviteCode: any(named: 'inviteCode')),
    ).thenThrow(const RelayApiException(statusCode: 404, message: 'Not found'));

    final notFound = await useCase.execute('INV123');
    expect(
      (notFound as JoinGroupError).message,
      'Invite code not found or expired',
    );

    when(
      () => apiClient.joinGroup(inviteCode: any(named: 'inviteCode')),
    ).thenThrow(const RelayApiException(statusCode: 409, message: 'Conflict'));

    final conflict = await useCase.execute('INV123');
    expect(
      (conflict as JoinGroupError).message,
      'Already a member of this group',
    );
  });
}
