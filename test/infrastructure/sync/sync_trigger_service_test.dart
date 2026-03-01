import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockRelayApiClient extends Mock implements RelayApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGroupRepository groupRepository;
  late MockPullSyncUseCase pullSync;
  late MockPushSyncUseCase pushSync;
  late MockSyncQueueManager queueManager;
  late PushNotificationService pushNotificationService;
  late SyncTriggerService service;

  setUp(() {
    groupRepository = MockGroupRepository();
    pullSync = MockPullSyncUseCase();
    pushSync = MockPushSyncUseCase();
    queueManager = MockSyncQueueManager();
    pushNotificationService = PushNotificationService(
      apiClient: MockRelayApiClient(),
    );
    service = SyncTriggerService(
      groupRepo: groupRepository,
      pullSync: pullSync,
      pushSync: pushSync,
      queueManager: queueManager,
      pushNotificationService: pushNotificationService,
    );

    when(() => pullSync.execute()).thenAnswer(
      (_) async => const PullSyncResult.noNewData(),
    );
    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    service.dispose();
  });

  test('member_confirmed transitions pending group and triggers pull', () async {
    when(() => groupRepository.getPendingGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.confirming,
        role: 'member',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(() => groupRepository.confirmLocalGroup(any())).thenAnswer((_) async {});

    service.initialize();
    await pushNotificationService.handleMessage({
      'type': 'member_confirmed',
      'groupId': 'group-1',
    });

    verify(() => groupRepository.confirmLocalGroup('group-1')).called(1);
    verify(() => pullSync.execute()).called(1);
  });
}
