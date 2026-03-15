import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/leave_group_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late LeaveGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    useCase = LeaveGroupUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      queueManager: queueManager,
    );

    when(() => apiClient.leaveGroup(any())).thenAnswer((_) async {});
    when(() => queueManager.clearQueue()).thenAnswer((_) async {});
    when(() => groupRepository.deactivateGroup(any())).thenAnswer((_) async {});
  });

  test('leaves the group, clears queue, and deactivates locally', () async {
    final result = await useCase.execute('group-1');

    expect(result, isA<LeaveGroupSuccess>());
    verify(() => apiClient.leaveGroup('group-1')).called(1);
    verify(() => queueManager.clearQueue()).called(1);
    verify(() => groupRepository.deactivateGroup('group-1')).called(1);
  });

  test('returns relay API errors', () async {
    when(
      () => apiClient.leaveGroup(any()),
    ).thenThrow(const RelayApiException(statusCode: 403, message: 'Forbidden'));

    final result = await useCase.execute('group-1');

    expect(result, isA<LeaveGroupError>());
    expect((result as LeaveGroupError).message, 'Forbidden');
  });
}
