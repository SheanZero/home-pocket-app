import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/confirm_join_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
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
  late ConfirmJoinUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
    groupRepository = MockGroupRepository();
    useCase = ConfirmJoinUseCase(
      apiClient: apiClient,
      keyManager: keyManager,
      groupRepository: groupRepository,
    );

    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
  });

  test('confirms join and saves group with empty members', () async {
    when(
      () => apiClient.confirmJoin(
        groupId: any(named: 'groupId'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.saveConfirmingGroup(
        groupId: any(named: 'groupId'),
        groupName: any(named: 'groupName'),
        members: any(named: 'members'),
      ),
    ).thenAnswer((_) async {});

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'Smith Family',
    );

    expect(result, isA<ConfirmJoinSuccess>());
    verify(
      () => apiClient.confirmJoin(
        groupId: 'group-1',
      ),
    ).called(1);
    verify(
      () => groupRepository.saveConfirmingGroup(
        groupId: 'group-1',
        groupName: 'Smith Family',
        members: const <GroupMember>[],
      ),
    ).called(1);
  });

  test('returns error when deviceId is not available', () async {
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => null);

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'Smith Family',
    );

    expect(result, isA<ConfirmJoinError>());
    expect(
      (result as ConfirmJoinError).message,
      'Device key not initialized',
    );
  });

  test('returns error on RelayApiException', () async {
    when(
      () => apiClient.confirmJoin(
        groupId: any(named: 'groupId'),
      ),
    ).thenThrow(
      const RelayApiException(
        statusCode: 403,
        message: 'Not authorized to join',
      ),
    );

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'Smith Family',
    );

    expect(result, isA<ConfirmJoinError>());
    expect(
      (result as ConfirmJoinError).message,
      'Not authorized to join',
    );
  });

  test('returns error on unexpected exception', () async {
    when(
      () => apiClient.confirmJoin(
        groupId: any(named: 'groupId'),
      ),
    ).thenThrow(Exception('Network error'));

    final result = await useCase.execute(
      groupId: 'group-1',
      groupName: 'Smith Family',
    );

    expect(result, isA<ConfirmJoinError>());
    expect(
      (result as ConfirmJoinError).message,
      contains('Failed to confirm join'),
    );
  });
}
