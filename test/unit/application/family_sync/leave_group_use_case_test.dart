import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/membership_rotation_coordinator.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockShadowBookService extends Mock implements ShadowBookService {}

class MockMembershipRotationCoordinator extends Mock
    implements MembershipRotationCoordinator {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late MockShadowBookService shadowBookService;
  late MockMembershipRotationCoordinator membershipRotation;
  late MembershipRotationIntent intent;
  late LeaveGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    shadowBookService = MockShadowBookService();
    membershipRotation = MockMembershipRotationCoordinator();
    useCase = LeaveGroupUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      queueManager: queueManager,
      shadowBookService: shadowBookService,
      membershipRotation: membershipRotation,
    );

    intent = MembershipRotationIntent(
      groupId: 'group-1',
      requestId: 'request-1',
      operation: 'leave',
      targetDeviceId: 'member-b',
      expectedKeyEpoch: 4,
      newKeyEpoch: 5,
      groupKey: null,
      envelopes: [],
      createdAt: DateTime(2026),
    );
    when(
      () => membershipRotation.submitSelfLeave('group-1'),
    ).thenAnswer((_) async => intent);
    when(
      () => membershipRotation.finalizeSelfLeave(intent),
    ).thenAnswer((_) async {});
  });

  test('leaves the group, clears queue, and deactivates locally', () async {
    final result = await useCase.execute('group-1');

    expect(result, isA<LeaveGroupSuccess>());
    verify(() => membershipRotation.submitSelfLeave('group-1')).called(1);
    verify(() => membershipRotation.finalizeSelfLeave(intent)).called(1);
  });

  test('returns relay API errors', () async {
    when(
      () => membershipRotation.submitSelfLeave(any()),
    ).thenThrow(const RelayApiException(statusCode: 403, message: 'Forbidden'));

    final result = await useCase.execute('group-1');

    expect(result, isA<LeaveGroupError>());
    expect((result as LeaveGroupError).message, 'Forbidden');
  });
}
