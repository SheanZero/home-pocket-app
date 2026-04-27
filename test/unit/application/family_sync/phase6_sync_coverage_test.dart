import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/sync_lifecycle_observer.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/sync_scheduler.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class _MockPushSyncUseCase extends Mock implements PushSyncUseCase {}

class _MockFullSyncUseCase extends Mock implements FullSyncUseCase {}

class _MockSyncAvatarUseCase extends Mock implements SyncAvatarUseCase {}

class _MockCheckGroupValidityUseCase extends Mock
    implements CheckGroupValidityUseCase {}

class _MockShadowBookService extends Mock implements ShadowBookService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _FakeWebSocketService extends Mock implements WebSocketService {
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

  void emit(WebSocketEvent event) => _eventController.add(event);

  Future<void> disposeControllers() async {
    await _eventController.close();
    await _stateController.close();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue(<String, int>{});
  });

  group('TransactionChangeTracker', () {
    test('records create and delete operations then flushes once', () {
      final tracker = TransactionChangeTracker();

      tracker.trackCreate({
        'op': 'create',
        'entityType': 'bill',
        'entityId': 'txn-1',
      });
      tracker.trackDelete(transactionId: 'txn-2', bookId: 'book-1');

      expect(tracker.pendingCount, 2);
      final flushed = tracker.flush();

      expect(flushed, hasLength(2));
      expect(flushed.first['entityId'], 'txn-1');
      expect(flushed.last['entityId'], 'txn-2');
      expect(flushed.last['data'], {'bookId': 'book-1'});
      expect(tracker.pendingCount, 0);
      expect(tracker.flush(), isEmpty);
    });
  });

  group('SyncOrchestrator', () {
    late _MockPullSyncUseCase pullSync;
    late _MockPushSyncUseCase pushSync;
    late _MockFullSyncUseCase fullSync;
    late _MockSyncAvatarUseCase avatarSync;
    late _MockCheckGroupValidityUseCase checkValidity;
    late _MockGroupRepository groupRepo;
    late _MockUserProfileRepository profileRepo;
    late _MockSyncQueueManager queueManager;
    late _MockKeyManager keyManager;
    late TransactionChangeTracker changeTracker;
    late SyncOrchestrator orchestrator;

    setUp(() {
      pullSync = _MockPullSyncUseCase();
      pushSync = _MockPushSyncUseCase();
      fullSync = _MockFullSyncUseCase();
      avatarSync = _MockSyncAvatarUseCase();
      checkValidity = _MockCheckGroupValidityUseCase();
      groupRepo = _MockGroupRepository();
      profileRepo = _MockUserProfileRepository();
      queueManager = _MockSyncQueueManager();
      keyManager = _MockKeyManager();
      changeTracker = TransactionChangeTracker();

      when(
        () => pullSync.execute(),
      ).thenAnswer((_) async => PullSyncSuccess(3));
      when(() => fullSync.execute()).thenAnswer((_) async => 4);
      when(
        () => avatarSync.pushAvatarToMembers(groupId: any(named: 'groupId')),
      ).thenAnswer((_) async {});
      when(
        () => checkValidity.execute(),
      ).thenAnswer((_) async => const GroupValidityResult.valid());
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
        ),
      ).thenAnswer((_) async => const PushSyncResult.success(1));
      when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
      when(() => queueManager.getPendingCount()).thenAnswer((_) async => 0);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');

      orchestrator = SyncOrchestrator(
        pullSync: pullSync,
        pushSync: pushSync,
        fullSync: fullSync,
        avatarSync: avatarSync,
        checkValidity: checkValidity,
        shadowBookService: _MockShadowBookService(),
        groupRepo: groupRepo,
        profileRepo: profileRepo,
        queueManager: queueManager,
        keyManager: keyManager,
        changeTracker: changeTracker,
      );
    });

    test(
      'returns no-group for every mode when no active group exists',
      () async {
        when(() => groupRepo.getActiveGroup()).thenAnswer((_) async => null);

        for (final mode in SyncMode.values) {
          final result = await orchestrator.execute(mode);
          expect(result, isA<SyncOrchestratorNoGroup>());
        }
      },
    );

    test('reports whether a full pull is needed from last sync time', () async {
      when(() => groupRepo.getActiveGroup()).thenAnswer((_) async => null);
      expect(await orchestrator.needsFullPull(), isFalse);

      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup(lastSyncAt: null));
      expect(await orchestrator.needsFullPull(), isTrue);

      when(() => groupRepo.getActiveGroup()).thenAnswer(
        (_) async => _activeGroup(
          lastSyncAt: DateTime.now().subtract(const Duration(hours: 25)),
        ),
      );
      expect(await orchestrator.needsFullPull(), isTrue);

      when(() => groupRepo.getActiveGroup()).thenAnswer(
        (_) async => _activeGroup(
          lastSyncAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      );
      expect(await orchestrator.needsFullPull(), isFalse);
    });

    test(
      'initial sync pushes all data, avatar, then pulls remote changes',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());

        final result = await orchestrator.execute(SyncMode.initialSync);

        expect(result, isA<SyncOrchestratorSuccess>());
        final success = result as SyncOrchestratorSuccess;
        expect(success.pushedCount, 4);
        expect(success.appliedCount, 3);
        verifyInOrder([
          () => fullSync.execute(),
          () => avatarSync.pushAvatarToMembers(groupId: 'group-1'),
          () => pullSync.execute(),
        ]);
      },
    );

    test(
      'incremental push validates group, pushes changes and profile once',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(() => profileRepo.find()).thenAnswer((_) async => _profile());
        changeTracker.trackDelete(transactionId: 'txn-1', bookId: 'book-1');

        final result = await orchestrator.execute(SyncMode.incrementalPush);

        expect(result, isA<SyncOrchestratorSuccess>());
        verify(() => checkValidity.execute()).called(1);
        verify(
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: const {},
          ),
        ).called(2);
        verify(() => queueManager.drainQueue()).called(1);

        await orchestrator.execute(SyncMode.incrementalPush);
        verifyNever(
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: const {},
          ),
        );
      },
    );

    test(
      'incremental push returns invalid and no-group validity results',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(
          () => checkValidity.execute(),
        ).thenAnswer((_) async => const GroupValidityResult.invalid('removed'));

        final invalid = await orchestrator.execute(SyncMode.incrementalPush);
        expect(invalid, isA<SyncOrchestratorError>());

        when(
          () => checkValidity.execute(),
        ).thenAnswer((_) async => const GroupValidityResult.noGroup());
        final noGroup = await orchestrator.execute(SyncMode.incrementalPush);
        expect(noGroup, isA<SyncOrchestratorNoGroup>());
      },
    );

    test('profile sync pushes profile operation and avatar', () async {
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup());
      when(() => profileRepo.find()).thenAnswer((_) async => _profile());

      final result = await orchestrator.execute(SyncMode.profileSync);

      expect(result, isA<SyncOrchestratorSuccess>());
      verify(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: const {},
        ),
      ).called(1);
      verify(
        () => avatarSync.pushAvatarToMembers(groupId: 'group-1'),
      ).called(1);
    });

    test('full pull and incremental pull report applied count', () async {
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup());

      final fullPull = await orchestrator.execute(SyncMode.fullPull);
      final incrementalPull = await orchestrator.execute(
        SyncMode.incrementalPull,
      );

      expect((fullPull as SyncOrchestratorSuccess).appliedCount, 3);
      expect((incrementalPull as SyncOrchestratorSuccess).appliedCount, 3);
    });

    test('execute catches exceptions as SyncOrchestratorError', () async {
      when(
        () => groupRepo.getActiveGroup(),
      ).thenThrow(StateError('database unavailable'));

      final result = await orchestrator.execute(SyncMode.initialSync);

      expect(result, isA<SyncOrchestratorError>());
      expect((result as SyncOrchestratorError).message, contains('database'));
    });
  });

  group('SyncScheduler', () {
    test('manual sync requests push then pull immediately', () {
      fakeAsync((async) {
        final requests = <SyncMode>[];
        final scheduler = SyncScheduler(
          onSyncRequested: (mode) async {
            requests.add(mode);
          },
          checkNeedsFullPull: () async => false,
        );

        scheduler.onManualSync();
        async.flushMicrotasks();

        expect(requests, [SyncMode.incrementalPush, SyncMode.incrementalPull]);
        scheduler.dispose();
      });
    });

    test('pause flushes pending transaction debounce', () {
      fakeAsync((async) {
        final requests = <SyncMode>[];
        final scheduler = SyncScheduler(
          onSyncRequested: (mode) async {
            requests.add(mode);
          },
          checkNeedsFullPull: () async => false,
        );

        scheduler.onTransactionChanged();
        async.elapse(const Duration(seconds: 5));
        scheduler.onAppPaused();
        async.flushMicrotasks();

        expect(requests, [SyncMode.incrementalPush]);
        scheduler.dispose();
      });
    });

    test(
      'resume pulls immediately and enqueues full pull when threshold hits',
      () {
        fakeAsync((async) {
          final requests = <SyncMode>[];
          final scheduler = SyncScheduler(
            onSyncRequested: (mode) async {
              requests.add(mode);
            },
            checkNeedsFullPull: () async => true,
          );

          scheduler.onAppResumed();
          async.flushMicrotasks();

          expect(requests, [SyncMode.incrementalPull, SyncMode.fullPull]);
          scheduler.dispose();
        });
      },
    );

    test(
      'queued modes drain in priority order after an active sync finishes',
      () async {
        final requests = <SyncMode>[];
        final release = Completer<void>();
        final scheduler = SyncScheduler(
          onSyncRequested: (mode) async {
            requests.add(mode);
            if (mode == SyncMode.incrementalPush) {
              await release.future;
            }
          },
          checkNeedsFullPull: () async => false,
        );

        scheduler.onManualSync();
        scheduler.onMemberConfirmed();
        await Future<void>.delayed(Duration.zero);
        release.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(requests, [
          SyncMode.incrementalPush,
          SyncMode.initialSync,
          SyncMode.incrementalPull,
        ]);
        scheduler.dispose();
      },
    );
  });

  group('SyncLifecycleObserver', () {
    testWidgets('dispatches resume and pause callbacks', (tester) async {
      var resumed = 0;
      var paused = 0;
      final observer = SyncLifecycleObserver(
        onResume: () async {
          resumed++;
        },
        onPaused: () {
          paused++;
        },
      );

      observer.start();
      observer.start();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      observer.dispose();
      observer.dispose();

      expect(resumed, 1);
      expect(paused, 1);
    });
  });

  group('SyncEngine', () {
    late _MockSyncOrchestrator orchestrator;
    late _MockGroupRepository groupRepo;
    late _FakeWebSocketService webSocketService;
    late _MockKeyManager keyManager;
    late SyncEngine engine;

    setUp(() {
      orchestrator = _MockSyncOrchestrator();
      groupRepo = _MockGroupRepository();
      webSocketService = _FakeWebSocketService();
      keyManager = _MockKeyManager();

      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(
        () => orchestrator.getPendingQueueCount(),
      ).thenAnswer((_) async => 0);
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup());
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
      );
    });

    tearDown(() async {
      engine.dispose();
      await webSocketService.disposeControllers();
    });

    test(
      'manual sync emits synced, queued, error, and no-group statuses',
      () async {
        final statuses = <SyncStatus>[];
        engine.statusStream.listen(statuses.add);

        engine.onManualSync();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.synced);

        when(
          () => orchestrator.getPendingQueueCount(),
        ).thenAnswer((_) async => 2);
        engine.onProfileChanged();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.queuedOffline);

        when(
          () => orchestrator.execute(any()),
        ).thenAnswer((_) async => const SyncOrchestratorError('offline'));
        engine.onSyncAvailable();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.error);
        expect(engine.currentStatus.errorMessage, 'offline');

        when(() => groupRepo.getActiveGroup()).thenAnswer((_) async => null);
        engine.onMemberConfirmed();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.noGroup);
        expect(statuses, isNotEmpty);
      },
    );

    test(
      'initializes websocket and routes websocket events into scheduler',
      () async {
        final pushService = _MockPushNotificationService();
        when(
          () => pushService.registerHandlers(
            onMemberConfirmed: any(named: 'onMemberConfirmed'),
            onSyncAvailable: any(named: 'onSyncAvailable'),
          ),
        ).thenReturn(null);

        engine.connectPushNotifications(pushService);
        engine.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        webSocketService.emit(
          const WebSocketEvent(type: WebSocketEventType.syncAvailable),
        );
        webSocketService.emit(
          const WebSocketEvent(type: WebSocketEventType.memberConfirmed),
        );
        webSocketService.emit(
          const WebSocketEvent(type: WebSocketEventType.joinRequest),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => orchestrator.execute(SyncMode.incrementalPull)).called(1);
        verify(() => orchestrator.execute(SyncMode.initialSync)).called(1);
      },
    );
  });
}

GroupInfo _activeGroup({DateTime? lastSyncAt}) {
  return GroupInfo(
    groupId: 'group-1',
    groupName: 'Family',
    status: GroupStatus.active,
    role: 'owner',
    groupKey: 'group-key',
    members: const [
      GroupMember(
        deviceId: 'device-1',
        publicKey: 'public-key',
        deviceName: 'Phone',
        displayName: 'Owner',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      ),
    ],
    createdAt: DateTime(2026, 4),
    lastSyncAt: lastSyncAt,
  );
}

UserProfile _profile() {
  return UserProfile(
    id: 'profile-1',
    displayName: 'Owner',
    avatarEmoji: '🏠',
    createdAt: DateTime(2026, 4),
    updatedAt: DateTime(2026, 4, 2),
  );
}
