import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/create_group_use_case.dart';
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
  late Future<String?> Function() getPushToken;

  setUp(() {
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
    groupRepository = MockGroupRepository();
    e2eeService = MockE2EEService();
    getPushToken = () async => 'push-token-1';
    useCase = CreateGroupUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
      e2eeService: e2eeService,
      getPushToken: getPushToken,
    );

    when(
      () => apiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
        pushToken: any(named: 'pushToken'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(() => apiClient.createGroup(bookId: any(named: 'bookId'))).thenAnswer(
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
        bookId: any(named: 'bookId'),
        inviteCode: any(named: 'inviteCode'),
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
        groupKey: any(named: 'groupKey'),
      ),
    ).thenAnswer((_) async {});
  });

  test('creates group using existing device keys', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');

    final result = await useCase.execute('book-1');

    expect(result, isA<CreateGroupSuccess>());
    verify(() => apiClient.createGroup(bookId: 'book-1')).called(1);
    verify(
      () => groupRepository.savePendingGroup(
        groupId: 'group-1',
        bookId: 'book-1',
        inviteCode: 'INV123',
        inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(1000),
        groupKey: 'group-key',
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

    final result = await useCase.execute('book-1');

    expect(result, isA<CreateGroupSuccess>());
    verify(() => keyManager.generateDeviceKeyPair()).called(1);
    verify(
      () => apiClient.registerDevice(
        deviceId: 'generated-device',
        publicKey: 'generated-public-key',
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
        pushToken: 'push-token-1',
      ),
    ).called(1);
  });

  test('returns API errors from the relay client', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(() => keyManager.getPublicKey()).thenAnswer((_) async => 'public-key');
    when(() => apiClient.createGroup(bookId: any(named: 'bookId'))).thenThrow(
      const RelayApiException(statusCode: 409, message: 'Already grouped'),
    );

    final result = await useCase.execute('book-1');

    expect(result, isA<CreateGroupError>());
    expect((result as CreateGroupError).message, 'Already grouped');
  });
}
