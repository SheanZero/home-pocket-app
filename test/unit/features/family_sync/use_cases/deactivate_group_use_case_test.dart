import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockShadowBookService extends Mock implements ShadowBookService {}

void main() {
  late MockRelayApiClient apiClient;
  late MockGroupRepository groupRepository;
  late MockSyncQueueManager queueManager;
  late MockShadowBookService shadowBookService;
  late DeactivateGroupUseCase useCase;

  setUp(() {
    apiClient = MockRelayApiClient();
    groupRepository = MockGroupRepository();
    queueManager = MockSyncQueueManager();
    shadowBookService = MockShadowBookService();
    useCase = DeactivateGroupUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      queueManager: queueManager,
      shadowBookService: shadowBookService,
    );

    when(() => apiClient.deactivateGroup(any())).thenAnswer((_) async {});
    when(() => queueManager.clearQueue()).thenAnswer((_) async {});
    when(() => groupRepository.deactivateGroup(any())).thenAnswer((_) async {});
    when(() => shadowBookService.cleanSyncData(any())).thenAnswer((_) async {});
  });

  test(
    'deactivates the group, clears queue, and deactivates locally',
    () async {
      final result = await useCase.execute('group-1');

      expect(result, isA<DeactivateGroupSuccess>());
      verify(() => apiClient.deactivateGroup('group-1')).called(1);
      verify(() => queueManager.clearQueue()).called(1);
      verify(() => shadowBookService.cleanSyncData('group-1')).called(1);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
    },
  );
}
