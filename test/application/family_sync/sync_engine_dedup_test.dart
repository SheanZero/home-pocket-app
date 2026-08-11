import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/refresh_group_snapshot_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockCompleteMemberActivationUseCase extends Mock
    implements CompleteMemberActivationUseCase {}

class MockRefreshGroupSnapshotUseCase extends Mock
    implements RefreshGroupSnapshotUseCase {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockWebSocketService extends Mock implements WebSocketService {
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  @override
  Stream<WebSocketEvent> get eventStream => _eventController.stream;

  @override
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  void connect({
    required String groupId,
    required String deviceId,
    required SignMessageFn signMessage,
  }) {}

  @override
  void disconnect() {}

  @override
  void startLifecycleObservation() {}

  @override
  void stopLifecycleObservation() {}
}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  group('SyncEngine deduplication', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockGroupRepository groupRepo;
    late MockWebSocketService webSocketService;
    late MockKeyManager keyManager;

    final activeGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      members: const [
        GroupMember(
          deviceId: 'owner-1',
          publicKey: 'pk',
          deviceName: 'Phone',
          displayName: 'Owner',
          avatarEmoji: '🏠',
          role: 'owner',
          status: 'active',
        ),
      ],
      createdAt: DateTime(2026, 4, 1),
    );

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      groupRepo = MockGroupRepository();
      webSocketService = MockWebSocketService();
      keyManager = MockKeyManager();
      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(
        () => orchestrator.getQueueSummary(),
      ).thenAnswer((_) async => const SyncQueueSummary());
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => activeGroup);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test('duplicate onMemberConfirmed within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      engine.onMemberConfirmed(); // duplicate — should be suppressed

      // Allow async sync request to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only one initialSyncing emission (not two)
      final syncingCount = statuses
          .where((s) => s.state == SyncState.initialSyncing)
          .length;
      expect(syncingCount, 1);
    });

    test('duplicate onSyncAvailable within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onSyncAvailable();
      engine.onSyncAvailable(); // duplicate

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final syncingCount = statuses
          .where((s) => s.state == SyncState.syncing)
          .length;
      expect(syncingCount, 1);
    });

    test('different event types are not deduplicated', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      // Wait for first to start processing before sending second
      await Future<void>.delayed(const Duration(milliseconds: 50));
      engine.onSyncAvailable(); // different type — should go through

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Both should trigger sync status changes
      final allSyncing = statuses
          .where(
            (s) =>
                s.state == SyncState.syncing ||
                s.state == SyncState.initialSyncing,
          )
          .length;
      expect(allSyncing, greaterThanOrEqualTo(2));
    });
  });

  group('SyncEngine member confirmation bootstrap', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockCompleteMemberActivationUseCase memberActivation;
    late MockGroupRepository groupRepo;
    late MockWebSocketService webSocketService;
    late MockKeyManager keyManager;

    final readyGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      groupKey: 'group-key',
      members: const [],
      createdAt: DateTime(2026, 4, 1),
    );

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      memberActivation = MockCompleteMemberActivationUseCase();
      groupRepo = MockGroupRepository();
      webSocketService = MockWebSocketService();
      keyManager = MockKeyManager();

      when(
        () => orchestrator.getQueueSummary(),
      ).thenAnswer((_) async => const SyncQueueSummary());
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => readyGroup);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
        memberActivation: memberActivation,
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test(
      'realtime confirmation reaches ready only after bootstrap succeeds',
      () async {
        when(
          () => memberActivation.execute(expectedGroupId: 'group-1'),
        ).thenAnswer(
          (_) async => const MemberActivationReady(groupId: 'group-1'),
        );
        final statuses = <SyncStatus>[];
        engine.statusStream.listen(statuses.add);

        await engine.onMemberConfirmed({'groupId': 'group-1'});

        expect(statuses.map((status) => status.state), [
          SyncState.initialSyncing,
          SyncState.synced,
        ]);
        verify(
          () => memberActivation.execute(expectedGroupId: 'group-1'),
        ).called(1);
        verifyNever(() => orchestrator.execute(any()));
      },
    );

    test(
      'awaiting-key result remains retryable and never reports synced',
      () async {
        when(
          () => memberActivation.execute(expectedGroupId: 'group-1'),
        ).thenAnswer(
          (_) async => const MemberActivationAwaitingKey(groupId: 'group-1'),
        );
        final statuses = <SyncStatus>[];
        engine.statusStream.listen(statuses.add);

        await engine.onMemberConfirmed({'groupId': 'group-1'});
        await engine.onMemberConfirmed({'groupId': 'group-1'});

        expect(statuses.last.state, SyncState.awaitingKey);
        expect(
          statuses,
          isNot(
            contains(
              predicate<SyncStatus>(
                (status) => status.state == SyncState.synced,
              ),
            ),
          ),
        );
        verify(
          () => memberActivation.execute(expectedGroupId: 'group-1'),
        ).called(2);
      },
    );
  });

  group('SyncEngine group snapshot invalidation', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockGroupRepository groupRepo;
    late MockWebSocketService webSocketService;
    late MockKeyManager keyManager;
    late MockRefreshGroupSnapshotUseCase refreshGroupSnapshot;

    final activeGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Old family',
      status: GroupStatus.active,
      role: 'member',
      members: const [],
      createdAt: DateTime(2026, 8, 1),
    );

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      groupRepo = MockGroupRepository();
      webSocketService = MockWebSocketService();
      keyManager = MockKeyManager();
      refreshGroupSnapshot = MockRefreshGroupSnapshotUseCase();
      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(
        () => orchestrator.getQueueSummary(),
      ).thenAnswer((_) async => const SyncQueueSummary());
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => activeGroup);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => refreshGroupSnapshot.execute(
          groupId: any(named: 'groupId'),
          controlEvent: any(named: 'controlEvent'),
        ),
      ).thenAnswer(
        (_) async => const RefreshGroupSnapshotApplied(groupName: 'New family'),
      );

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
        groupSnapshotRefresh: refreshGroupSnapshot,
      );
    });

    tearDown(() => engine.dispose());

    test(
      'WebSocket group status and rename events use the same refresh',
      () async {
        engine.initialize();
        await Future<void>.delayed(Duration.zero);

        webSocketService._eventController
          ..add(
            const WebSocketEvent(
              type: WebSocketEventType.groupStatus,
              groupId: 'group-1',
            ),
          )
          ..add(
            const WebSocketEvent(
              type: WebSocketEventType.groupNameUpdated,
              groupId: 'group-1',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        verify(
          () => refreshGroupSnapshot.execute(
            groupId: 'group-1',
            controlEvent: any(named: 'controlEvent'),
          ),
        ).called(2);
      },
    );
  });
}
