import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/confirm_member_use_case.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockE2EEService extends Mock implements E2EEService {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockE2EEService e2eeService;
  late ConfirmMemberUseCase useCase;
  late int fullSyncCalls;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    e2eeService = MockE2EEService();
    fullSyncCalls = 0;
    useCase = ConfirmMemberUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      e2eeService: e2eeService,
      executeFullSync: (bookId) async {
        fullSyncCalls++;
        return 10;
      },
    );

    when(
      () => apiClient.confirmMember(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{});
    when(
      () => groupRepository.activateMember(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => apiClient.pushGroupSync(
        groupId: any(named: 'groupId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
      ),
    ).thenAnswer((_) async => {'recipientCount': 1});
  });

  test('confirms member, exchanges key, and triggers full sync', () async {
    when(() => groupRepository.getGroupById(any())).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.pending,
        role: 'owner',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'member-public-key',
            deviceName: 'Member phone',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026),
      ),
    );
    when(
      () => e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: any(named: 'groupKeyBase64'),
        memberDeviceId: any(named: 'memberDeviceId'),
        memberPublicKey: any(named: 'memberPublicKey'),
      ),
    ).thenAnswer((_) async => 'encrypted-key');

    final result = await useCase.execute(
      groupId: 'group-1',
      deviceId: 'member-1',
      bookId: 'book-1',
    );

    expect(result, isA<ConfirmMemberSuccess>());
    verify(
      () => groupRepository.activateMember('group-1', 'member-1'),
    ).called(1);
    verify(
      () => apiClient.pushGroupSync(
        groupId: 'group-1',
        payload: 'encrypted-key',
        vectorClock: const {},
        operationCount: 0,
      ),
    ).called(1);
    expect(fullSyncCalls, 1);
  });

  test('skips key exchange when the group key is not available', () async {
    when(() => groupRepository.getGroupById(any())).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.pending,
        role: 'owner',
        groupKey: null,
        members: const [],
        createdAt: DateTime(2026),
      ),
    );

    final result = await useCase.execute(
      groupId: 'group-1',
      deviceId: 'member-1',
      bookId: 'book-1',
    );

    expect(result, isA<ConfirmMemberSuccess>());
    verifyNever(
      () => apiClient.pushGroupSync(
        groupId: any(named: 'groupId'),
        payload: any(named: 'payload'),
        vectorClock: any(named: 'vectorClock'),
        operationCount: any(named: 'operationCount'),
      ),
    );
    expect(fullSyncCalls, 1);
  });

  test('returns API errors from confirmMember', () async {
    when(
      () => apiClient.confirmMember(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenThrow(const RelayApiException(statusCode: 403, message: 'Forbidden'));

    final result = await useCase.execute(
      groupId: 'group-1',
      deviceId: 'member-1',
      bookId: 'book-1',
    );

    expect(result, isA<ConfirmMemberError>());
    expect((result as ConfirmMemberError).message, 'Forbidden');
  });
}
