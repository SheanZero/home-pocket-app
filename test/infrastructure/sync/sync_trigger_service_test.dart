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

class FakePushMessagingClient implements PushMessagingClient {
  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> requestPermission() async {}
}

class FakeLocalNotificationClient implements LocalNotificationClient {
  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGroupRepository groupRepository;
  late MockPullSyncUseCase pullSync;
  late MockPushSyncUseCase pushSync;
  late MockSyncQueueManager queueManager;
  late PushNotificationService pushNotificationService;
  late SyncTriggerService service;
  final emittedJoinRequests = <SyncTriggerEvent>[];

  setUp(() {
    groupRepository = MockGroupRepository();
    pullSync = MockPullSyncUseCase();
    pushSync = MockPushSyncUseCase();
    queueManager = MockSyncQueueManager();
    pushNotificationService = PushNotificationService(
      apiClient: MockRelayApiClient(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
    );
    service = SyncTriggerService(
      groupRepo: groupRepository,
      pullSync: pullSync,
      pushSync: pushSync,
      queueManager: queueManager,
      pushNotificationService: pushNotificationService,
    );
    service.events.listen(emittedJoinRequests.add);

    when(
      () => pullSync.execute(),
    ).thenAnswer((_) async => const PullSyncResult.noNewData());
    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    service.dispose();
  });

  test(
    'member_confirmed transitions pending group and triggers pull',
    () async {
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
      when(
        () => groupRepository.confirmLocalGroup(any()),
      ).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'member_confirmed',
        'groupId': 'group-1',
      });

      verify(() => groupRepository.confirmLocalGroup('group-1')).called(1);
      verify(() => pullSync.execute()).called(1);
    },
  );

  test('join_request emits a trigger event', () async {
    await service.initialize();

    await pushNotificationService.handleMessage({
      'type': 'join_request',
      'groupId': 'group-1',
    });

    expect(
      emittedJoinRequests,
      contains(const SyncTriggerEvent.joinRequest(groupId: 'group-1')),
    );
  });
}
