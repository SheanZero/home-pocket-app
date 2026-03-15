import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class MockFullSyncUseCase extends Mock implements FullSyncUseCase {}

class MockShadowBookService extends Mock implements ShadowBookService {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockRelayApiClient extends Mock implements RelayApiClient {}

class MockKeyManager extends Mock implements KeyManager {}

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

class CountingPushNotificationService extends PushNotificationService {
  CountingPushNotificationService()
    : super(
        apiClient: MockRelayApiClient(),
        messagingClient: FakePushMessagingClient(),
        localNotificationClient: FakeLocalNotificationClient(),
        firebaseInitializer: () async {},
      );

  int registerHandlersCalls = 0;
  int initializeCalls = 0;

  @override
  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
    PushMessageHandler? onJoinRequest,
    PushMessageHandler? onMemberLeft,
    PushMessageHandler? onGroupDissolved,
  }) {
    registerHandlersCalls++;
  }

  @override
  Future<String?> initialize() async {
    initializeCalls++;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGroupRepository groupRepository;
  late MockPullSyncUseCase pullSync;
  late MockPushSyncUseCase pushSync;
  late MockFullSyncUseCase fullSync;
  late MockShadowBookService shadowBookService;
  late MockSyncQueueManager queueManager;
  late MockRelayApiClient apiClient;
  late MockKeyManager keyManager;
  late PushNotificationService pushNotificationService;
  late SyncTriggerService service;
  var emittedEvents = <SyncTriggerEvent>[];

  setUp(() {
    emittedEvents = <SyncTriggerEvent>[];
    groupRepository = MockGroupRepository();
    pullSync = MockPullSyncUseCase();
    pushSync = MockPushSyncUseCase();
    fullSync = MockFullSyncUseCase();
    shadowBookService = MockShadowBookService();
    queueManager = MockSyncQueueManager();
    apiClient = MockRelayApiClient();
    keyManager = MockKeyManager();
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
      fullSync: fullSync,
      shadowBookService: shadowBookService,
      queueManager: queueManager,
      pushNotificationService: pushNotificationService,
      apiClient: apiClient,
      keyManager: keyManager,
    );
    service.events.listen(emittedEvents.add);

    when(
      () => pullSync.execute(),
    ).thenAnswer((_) async => const PullSyncResult.noNewData());
    when(() => fullSync.execute()).thenAnswer((_) async => 0);
    when(() => shadowBookService.cleanSyncData(any())).thenAnswer((_) async {});
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
      verify(() => fullSync.execute()).called(1);
      verify(() => pullSync.execute()).called(1);
    },
  );

  test(
    'join_request fetches group status, updates members, and emits event',
    () async {
      when(() => apiClient.getGroupStatus('group-1')).thenAnswer(
        (_) async => {
          'groupId': 'group-1',
          'members': [
            {
              'deviceId': 'device-owner',
              'publicKey': 'pk-owner',
              'deviceName': 'Owner Phone',
              'role': 'owner',
              'status': 'active',
            },
            {
              'deviceId': 'device-new',
              'publicKey': 'pk-new',
              'deviceName': 'New Phone',
              'role': 'member',
              'status': 'pending',
            },
          ],
        },
      );
      when(
        () => groupRepository.updateMembers(any(), any()),
      ).thenAnswer((_) async {});

      await service.initialize();

      await pushNotificationService.handleMessage({
        'type': 'join_request',
        'groupId': 'group-1',
      });

      verify(() => apiClient.getGroupStatus('group-1')).called(1);
      verify(
        () => groupRepository.updateMembers('group-1', any(that: hasLength(2))),
      ).called(1);
      expect(
        emittedEvents,
        contains(const SyncTriggerEvent.joinRequest(groupId: 'group-1')),
      );
    },
  );

  test('join_request still emits event if server fetch fails', () async {
    when(() => apiClient.getGroupStatus('group-1')).thenThrow(
      const RelayApiException(statusCode: 500, message: 'server error'),
    );

    await service.initialize();

    await pushNotificationService.handleMessage({
      'type': 'join_request',
      'groupId': 'group-1',
    });

    expect(
      emittedEvents,
      contains(const SyncTriggerEvent.joinRequest(groupId: 'group-1')),
    );
  });

  test('initialize is idempotent', () async {
    final pushService = CountingPushNotificationService();
    final idempotentService = SyncTriggerService(
      groupRepo: groupRepository,
      pullSync: pullSync,
      pushSync: pushSync,
      fullSync: fullSync,
      shadowBookService: shadowBookService,
      queueManager: queueManager,
      pushNotificationService: pushService,
      apiClient: apiClient,
      keyManager: keyManager,
    );

    await idempotentService.initialize();
    await idempotentService.initialize();

    expect(pushService.registerHandlersCalls, 1);
    expect(pushService.initializeCalls, 1);

    idempotentService.dispose();
  });

  test(
    'member_left with reason=removed deactivates group for local device',
    () async {
      when(
        () => keyManager.getDeviceId(),
      ).thenAnswer((_) async => 'device-self');
      when(() => queueManager.clearQueue()).thenAnswer((_) async {});
      when(
        () => groupRepository.deactivateGroup(any()),
      ).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'member_left',
        'groupId': 'group-1',
        'deviceId': 'device-self',
        'reason': 'removed',
      });

      verify(() => queueManager.clearQueue()).called(1);
      verify(() => shadowBookService.cleanSyncData('group-1')).called(1);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
      expect(
        emittedEvents,
        contains(const SyncTriggerEvent.memberLeft(groupId: 'group-1')),
      );
    },
  );

  test(
    'member_left for another device removes them from local member list',
    () async {
      when(
        () => keyManager.getDeviceId(),
      ).thenAnswer((_) async => 'device-self');
      when(() => groupRepository.getGroupById('group-1')).thenAnswer(
        (_) async => GroupInfo(
          groupId: 'group-1',

          status: GroupStatus.active,
          role: 'owner',
          members: const [
            GroupMember(
              deviceId: 'device-self',
              publicKey: 'pk-self',
              deviceName: 'My phone',
              role: 'owner',
              status: 'active',
            ),
            GroupMember(
              deviceId: 'device-other',
              publicKey: 'pk-other',
              deviceName: 'Other phone',
              role: 'member',
              status: 'active',
            ),
          ],
          createdAt: DateTime(2026),
        ),
      );
      when(
        () => groupRepository.updateMembers(any(), any()),
      ).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'member_left',
        'groupId': 'group-1',
        'deviceId': 'device-other',
        'reason': 'left',
      });

      verify(
        () => groupRepository.updateMembers('group-1', any(that: hasLength(1))),
      ).called(1);
      expect(
        emittedEvents,
        contains(const SyncTriggerEvent.memberLeft(groupId: 'group-1')),
      );
    },
  );

  test('group_dissolved deactivates group and emits event', () async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',

        status: GroupStatus.active,
        role: 'member',
        members: const [],
        createdAt: DateTime(2026),
      ),
    );
    when(() => queueManager.clearQueue()).thenAnswer((_) async {});
    when(() => groupRepository.deactivateGroup(any())).thenAnswer((_) async {});

    await service.initialize();
    await pushNotificationService.handleMessage({
      'type': 'group_dissolved',
      'groupId': 'group-1',
    });

    verify(() => queueManager.clearQueue()).called(1);
    verify(() => shadowBookService.cleanSyncData('group-1')).called(1);
    verify(() => groupRepository.deactivateGroup('group-1')).called(1);
    expect(
      emittedEvents,
      contains(const SyncTriggerEvent.groupDissolved(groupId: 'group-1')),
    );
  });
}
