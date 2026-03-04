import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class MockSyncQueueManager extends Mock implements SyncQueueManager {}

class MockKeyManager extends Mock implements KeyManager {}

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
  late MockKeyManager keyManager;
  late MockRelayApiClient relayApiClient;
  late PushNotificationService pushNotificationService;
  late SyncTriggerService service;
  final emittedJoinRequests = <SyncTriggerEvent>[];
  const testGroupId = 'group-1';
  const localDeviceId = 'local-device-id';
  final testActiveGroup = GroupInfo(
    groupId: testGroupId,
    bookId: 'book-1',
    status: GroupStatus.active,
    role: 'member',
    members: const [
      GroupMember(
        deviceId: 'owner-device-id',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        role: 'owner',
        status: 'active',
      ),
      GroupMember(
        deviceId: localDeviceId,
        publicKey: 'pk-local',
        deviceName: 'My phone',
        role: 'member',
        status: 'active',
      ),
      GroupMember(
        deviceId: 'leaving-device-id',
        publicKey: 'pk-leaving',
        deviceName: 'Leaving tablet',
        role: 'member',
        status: 'active',
      ),
    ],
    createdAt: DateTime(2026),
  );

  setUp(() {
    groupRepository = MockGroupRepository();
    pullSync = MockPullSyncUseCase();
    pushSync = MockPushSyncUseCase();
    queueManager = MockSyncQueueManager();
    keyManager = MockKeyManager();
    relayApiClient = MockRelayApiClient();
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
      keyManager: keyManager,
      relayApiClient: relayApiClient,
      pushNotificationService: pushNotificationService,
    );
    service.events.listen(emittedJoinRequests.add);

    when(
      () => pullSync.execute(),
    ).thenAnswer((_) async => const PullSyncResult.noNewData());
    when(
      () => pushSync.execute(
        operations: any(named: 'operations'),
        vectorClock: any(named: 'vectorClock'),
      ),
    ).thenAnswer((_) async => const PushSyncResult.success(1));
    when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => localDeviceId);
    when(
      () => relayApiClient.getGroupStatus(any()),
    ).thenAnswer((_) async => {'groupId': testGroupId, 'members': []});
    when(
      () => groupRepository.updateMembers(any(), any()),
    ).thenAnswer((_) async {});
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

  test(
    'member_confirmed without groupId confirms the pending group and pulls sync',
    () async {
      when(() => groupRepository.getPendingGroup()).thenAnswer(
        (_) async => GroupInfo(
          groupId: testGroupId,
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
      await pushNotificationService.handleMessage({'type': 'member_confirmed'});

      verify(() => groupRepository.confirmLocalGroup(testGroupId)).called(1);
      verify(() => pullSync.execute()).called(1);

      final event = service.takePendingEvent();
      expect(
        event,
        const SyncTriggerEvent.memberConfirmed(groupId: testGroupId),
      );
    },
  );

  test('member_confirmed refreshes group status from server', () async {
    when(() => groupRepository.getPendingGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: testGroupId,
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
    when(() => relayApiClient.getGroupStatus(testGroupId)).thenAnswer(
      (_) async => {
        'groupId': testGroupId,
        'members': [
          {
            'deviceId': 'owner-id',
            'publicKey': 'pk1',
            'deviceName': 'Owner Phone',
            'role': 'owner',
            'status': 'active',
          },
          {
            'deviceId': 'my-id',
            'publicKey': 'pk2',
            'deviceName': 'My Phone',
            'role': 'member',
            'status': 'active',
          },
        ],
      },
    );
    when(
      () => groupRepository.updateMembers(any(), any()),
    ).thenAnswer((_) async {});

    await service.initialize();
    await pushNotificationService.handleMessage({
      'type': 'member_confirmed',
      'groupId': testGroupId,
    });

    verify(() => relayApiClient.getGroupStatus(testGroupId)).called(1);
    final updatedMembers =
        verify(
              () => groupRepository.updateMembers(testGroupId, captureAny()),
            ).captured.single
            as List<GroupMember>;
    expect(updatedMembers, hasLength(2));
    expect(updatedMembers.first.deviceId, 'owner-id');
    expect(updatedMembers.last.deviceId, 'my-id');
  });

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

  group('member_left handling', () {
    test('removes member from local group and emits event', () async {
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => testActiveGroup);
      when(
        () => groupRepository.getGroupById(testGroupId),
      ).thenAnswer((_) async => testActiveGroup);
      when(
        () => groupRepository.updateMembers(any(), any()),
      ).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'member_left',
        'groupId': testGroupId,
        'deviceId': 'leaving-device-id',
        'reason': 'left',
      });

      final capturedMembers =
          verify(
                () => groupRepository.updateMembers(testGroupId, captureAny()),
              ).captured.single
              as List<GroupMember>;

      expect(capturedMembers.map((member) => member.deviceId), [
        'owner-device-id',
        localDeviceId,
      ]);

      final event = service.takePendingEvent();
      expect(event, isNotNull);
      expect(event!.type, SyncTriggerEventType.memberLeft);
      expect(event.groupId, testGroupId);
    });

    test('handles removed member that is self by deactivating group', () async {
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => testActiveGroup);
      when(
        () => groupRepository.deactivateGroup(testGroupId),
      ).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'member_left',
        'groupId': testGroupId,
        'deviceId': localDeviceId,
        'reason': 'removed',
      });

      verify(() => groupRepository.deactivateGroup(testGroupId)).called(1);
    });
  });

  group('group_dissolved handling', () {
    test('deactivates group locally and emits event', () async {
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => testActiveGroup);
      when(
        () => groupRepository.deactivateGroup(testGroupId),
      ).thenAnswer((_) async {});
      when(() => queueManager.clearQueue()).thenAnswer((_) async {});

      await service.initialize();
      await pushNotificationService.handleMessage({
        'type': 'group_dissolved',
        'groupId': testGroupId,
      });

      verify(() => groupRepository.deactivateGroup(testGroupId)).called(1);
      verify(() => queueManager.clearQueue()).called(1);

      final event = service.takePendingEvent();
      expect(event, isNotNull);
      expect(event!.type, SyncTriggerEventType.groupDissolved);
      expect(event.groupId, testGroupId);
    });
  });

  test('onTransactionCreated builds protocol-compliant operation', () async {
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => testActiveGroup);

    await service.onTransactionCreated({
      'id': 'tx-1',
      'amount': 1000,
      'category': 'food',
    });

    final captured =
        verify(
              () => pushSync.execute(
                operations: captureAny(named: 'operations'),
                vectorClock: any(named: 'vectorClock'),
              ),
            ).captured.first
            as List<Map<String, dynamic>>;

    expect(captured, hasLength(1));
    expect(captured[0]['op'], 'create');
    expect(captured[0]['entityType'], 'bill');
    expect(captured[0]['entityId'], 'tx-1');
    expect(captured[0]['data'], isNotNull);
    expect(captured[0]['timestamp'], isA<int>());
  });
}
