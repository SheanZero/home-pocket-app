import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/drain_family_sync_outbox_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/group_key_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/shopping_item_change_tracker.dart';
import 'package:home_pocket/application/family_sync/transaction_change_tracker.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
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

class _MockDrainFamilySyncOutboxUseCase extends Mock
    implements DrainFamilySyncOutboxUseCase {}

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

class _MockGroupKeyRecoveryCoordinator extends Mock
    implements GroupKeyRecoveryCoordinator {}

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _FakeWebSocketService extends Mock implements WebSocketService {
  final _eventController = StreamController<WebSocketEvent>.broadcast();
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  var disconnectCalls = 0;

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
  void disconnect() {
    disconnectCalls++;
  }

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
    test(
      'records safe create and minimal delete operations then flushes once',
      () {
        final tracker = TransactionChangeTracker();

        tracker.trackCreate({
          'op': 'create',
          'entityType': 'bill',
          'entityId': 'txn-1',
          'revision': 10,
          'originDeviceId': 'device-1',
          'data': {'id': 'txn-1', 'syncRevision': 10},
        });
        tracker.trackDelete(
          transactionId: 'txn-2',
          bookId: 'book-1',
          operation: {
            'op': 'delete',
            'entityType': 'bill',
            'entityId': 'txn-2',
            'revision': 11,
            'originDeviceId': 'device-1',
            'data': {
              'isDeleted': true,
              'syncRevision': 11,
              'syncOriginDeviceId': 'device-1',
            },
          },
        );

        expect(tracker.pendingCount, 2);
        final flushed = tracker.flush();

        expect(flushed, hasLength(2));
        expect(flushed.first['entityId'], 'txn-1');
        expect(flushed.last['entityId'], 'txn-2');
        expect(flushed.last['data'], {
          'isDeleted': true,
          'syncRevision': 11,
          'syncOriginDeviceId': 'device-1',
        });
        expect(tracker.pendingCount, 0);
        expect(tracker.flush(), isEmpty);
      },
    );
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
    late _MockDrainFamilySyncOutboxUseCase outboxDrainer;
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
      outboxDrainer = _MockDrainFamilySyncOutboxUseCase();

      when(
        () => pullSync.execute(),
      ).thenAnswer((_) async => PullSyncSuccess(3));
      when(() => fullSync.execute()).thenAnswer((_) async => 4);
      when(
        () => avatarSync.pushAvatarToMembers(groupId: any(named: 'groupId')),
      ).thenAnswer((_) async => null);
      when(
        () => checkValidity.execute(),
      ).thenAnswer((_) async => const GroupValidityResult.valid());
      when(
        () => pushSync.execute(
          operations: any(named: 'operations'),
          vectorClock: any(named: 'vectorClock'),
          expectedGroupId: any(named: 'expectedGroupId'),
        ),
      ).thenAnswer((_) async => const PushSyncResult.success(1));
      when(() => queueManager.drainQueue()).thenAnswer((_) async => 0);
      when(() => queueManager.getPendingCount()).thenAnswer((_) async => 0);
      when(() => outboxDrainer.execute()).thenAnswer((_) async => 0);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => groupRepo.updateLastSyncTime(
          any(),
          expectedGroupId: any(named: 'expectedGroupId'),
        ),
      ).thenAnswer((_) async => true);

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
        shoppingChangeTracker: ShoppingItemChangeTracker(),
        outboxDrainer: outboxDrainer,
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
        when(() => profileRepo.find()).thenAnswer((_) async => _profile());

        final result = await orchestrator.execute(SyncMode.initialSync);

        expect(result, isA<SyncOrchestratorSuccess>());
        final success = result as SyncOrchestratorSuccess;
        expect(success.pushedCount, 5);
        expect(success.appliedCount, 3);
        verifyInOrder([
          () => outboxDrainer.execute(),
          () => fullSync.execute(),
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: const {},
            expectedGroupId: 'group-1',
          ),
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
      'incremental push maps invalid and no-group validity to no-group',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(
          () => checkValidity.execute(),
        ).thenAnswer((_) async => const GroupValidityResult.invalid('removed'));

        final invalid = await orchestrator.execute(SyncMode.incrementalPush);
        expect(invalid, isA<SyncOrchestratorNoGroup>());

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
      final operations =
          verify(
                () => pushSync.execute(
                  operations: captureAny(named: 'operations'),
                  vectorClock: const {},
                  expectedGroupId: 'group-1',
                ),
              ).captured.single
              as List<Map<String, dynamic>>;
      final operation = operations.single;
      final revision = _profile().updatedAt.toUtc().microsecondsSinceEpoch;
      expect(
        operation['operationId'],
        startsWith('profile:device-1:$revision:'),
      );
      expect(operation['revision'], revision);
      expect(operation['originDeviceId'], 'device-1');
      expect(operation['data'], {
        'schemaVersion': 1,
        'ownerDeviceId': 'device-1',
        'revision': revision,
        'profileDigest': operation['profileDigest'],
        'displayName': 'Owner',
        'avatarEmoji': '🏠',
      });
      verify(
        () => avatarSync.pushAvatarToMembers(groupId: 'group-1'),
      ).called(1);
    });

    test(
      'pull modes retry durable outbox after a key envelope may be installed',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());

        final fullPull = await orchestrator.execute(SyncMode.fullPull);
        final incrementalPull = await orchestrator.execute(
          SyncMode.incrementalPull,
        );

        expect((fullPull as SyncOrchestratorSuccess).appliedCount, 3);
        expect((incrementalPull as SyncOrchestratorSuccess).appliedCount, 3);
        verify(
          () => groupRepo.updateLastSyncTime(any(), expectedGroupId: 'group-1'),
        ).called(2);
        verify(() => outboxDrainer.execute()).called(4);
      },
    );

    test(
      'an empty completed pull still persists the reconciliation time',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(
          () => pullSync.execute(),
        ).thenAnswer((_) async => const PullSyncResult.noNewData());

        final result = await orchestrator.execute(SyncMode.incrementalPull);

        expect(result, isA<SyncOrchestratorSuccess>());
        verify(
          () => groupRepo.updateLastSyncTime(any(), expectedGroupId: 'group-1'),
        ).called(1);
      },
    );

    test(
      'does not report success if the group changes before timestamp write',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(
          () => groupRepo.updateLastSyncTime(any(), expectedGroupId: 'group-1'),
        ).thenAnswer((_) async => false);

        final result = await orchestrator.execute(SyncMode.incrementalPull);

        expect(result, isA<SyncOrchestratorNoGroup>());
      },
    );

    test('partial pull does not persist the reconciliation time', () async {
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup());
      when(() => pullSync.execute()).thenAnswer(
        (_) async => const PullSyncResult.deferred(
          reason: PullSyncDeferredReason.noProgress,
          message: 'blocked by a future key epoch',
          pageCount: 1,
          unacknowledgedMessageIds: ['message-1'],
        ),
      );

      final result = await orchestrator.execute(SyncMode.incrementalPull);

      expect(result, isA<SyncOrchestratorError>());
      expect((result as SyncOrchestratorError).isDeferred, isTrue);
      verifyNever(
        () => groupRepo.updateLastSyncTime(
          any(),
          expectedGroupId: any(named: 'expectedGroupId'),
        ),
      );
    });

    test(
      'pull failures are not reported as successful reconciliation',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(
          () => pullSync.execute(),
        ).thenAnswer((_) async => const PullSyncResult.error('offline'));

        final initial = await orchestrator.execute(SyncMode.initialSync);
        final incremental = await orchestrator.execute(
          SyncMode.incrementalPull,
        );
        final fullPull = await orchestrator.execute(SyncMode.fullPull);

        expect(initial, isA<SyncOrchestratorError>());
        expect(incremental, isA<SyncOrchestratorError>());
        expect(fullPull, isA<SyncOrchestratorError>());
        verifyNever(
          () => groupRepo.updateLastSyncTime(
            any(),
            expectedGroupId: any(named: 'expectedGroupId'),
          ),
        );
      },
    );

    test('execute sanitizes exceptions as SyncOrchestratorError', () async {
      when(
        () => groupRepo.getActiveGroup(),
      ).thenThrow(StateError('database unavailable'));

      final result = await orchestrator.execute(SyncMode.initialSync);

      expect(result, isA<SyncOrchestratorError>());
      final message = (result as SyncOrchestratorError).message;
      expect(message, 'Family sync failed');
      expect(message, isNot(contains('database')));
    });

    test(
      'incrementalPush flushes and pushes shopping ops (SC-3, SYNC-01)',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup());
        when(() => profileRepo.find()).thenAnswer((_) async => _profile());

        // Prime the shoppingChangeTracker with a pending op
        // We reconstruct the orchestrator with a primed tracker for this test
        final shoppingTracker = ShoppingItemChangeTracker();
        shoppingTracker.trackCreate({
          'op': 'create',
          'entityType': 'shopping_item',
          'entityId': 'item-sync-1',
          'data': {'listType': 'public', 'name': 'Milk'},
        });

        final orchWithShopping = SyncOrchestrator(
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
          shoppingChangeTracker: shoppingTracker,
        );

        final result = await orchWithShopping.execute(SyncMode.incrementalPush);

        expect(result, isA<SyncOrchestratorSuccess>());
        // pushSync was called with the shopping op (at least once for the shopping batch)
        verify(
          () => pushSync.execute(
            operations: any(named: 'operations'),
            vectorClock: const {},
          ),
        ).called(greaterThanOrEqualTo(1));
      },
    );
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

    test(
      'local-data wipe suspension waits for active sync and blocks new work',
      () async {
        final requests = <SyncMode>[];
        final release = Completer<void>();
        final scheduler = SyncScheduler(
          onSyncRequested: (mode) async {
            requests.add(mode);
            await release.future;
          },
          checkNeedsFullPull: () async => false,
        );

        scheduler.onManualSync();
        await Future<void>.delayed(Duration.zero);
        var suspended = false;
        final suspension = scheduler.suspendAndWait().then(
          (_) => suspended = true,
        );
        scheduler.onMemberConfirmed();
        await Future<void>.delayed(Duration.zero);
        expect(suspended, isFalse);
        expect(requests, [SyncMode.incrementalPush]);

        release.complete();
        await suspension;
        expect(scheduler.isSuspended, isTrue);
        expect(requests, [SyncMode.incrementalPush]);

        scheduler.resetAfterLocalDataWipe();
        scheduler.onSyncAvailable();
        await Future<void>.delayed(Duration.zero);
        expect(requests, [SyncMode.incrementalPush, SyncMode.incrementalPull]);
        scheduler.dispose();
      },
    );

    test(
      'local-data wipe waits for an in-flight full-pull threshold check',
      () async {
        final thresholdRelease = Completer<bool>();
        final thresholdStarted = Completer<void>();
        final scheduler = SyncScheduler(
          onSyncRequested: (_) async {},
          checkNeedsFullPull: () {
            thresholdStarted.complete();
            return thresholdRelease.future;
          },
        );

        await scheduler.onAppResumed();
        await thresholdStarted.future;
        var suspended = false;
        final suspension = scheduler.suspendAndWait().then(
          (_) => suspended = true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(suspended, isFalse);
        thresholdRelease.complete(true);
        await suspension;
        expect(scheduler.isSuspended, isTrue);
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
    late _MockGroupKeyRecoveryCoordinator keyRecovery;
    late SyncEngine engine;

    setUp(() {
      orchestrator = _MockSyncOrchestrator();
      groupRepo = _MockGroupRepository();
      webSocketService = _FakeWebSocketService();
      keyManager = _MockKeyManager();
      keyRecovery = _MockGroupKeyRecoveryCoordinator();

      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(
        () => orchestrator.getQueueSummary(),
      ).thenAnswer((_) async => const SyncQueueSummary());
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(
        () => groupRepo.getActiveGroup(),
      ).thenAnswer((_) async => _activeGroup());
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => keyRecovery.respondForCurrentGroup(),
      ).thenAnswer((_) async => 0);

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
        groupKeyRecovery: keyRecovery,
      );
    });

    test(
      'startup requests a missing key for a restored active group',
      () async {
        when(
          () => groupRepo.getActiveGroup(),
        ).thenAnswer((_) async => _activeGroup().copyWith(groupKey: null));
        when(() => keyRecovery.requestKey(groupId: 'group-1')).thenAnswer(
          (_) async => const GroupKeyRecoveryStatus(
            phase: GroupKeyRecoveryPhase.waitingForPeer,
            groupId: 'group-1',
            requestId: 'request-1',
            keyEpoch: 1,
          ),
        );

        engine.initialize();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        verify(() => keyRecovery.requestKey(groupId: 'group-1')).called(1);
        expect(engine.currentStatus.state, SyncState.awaitingKey);
      },
    );

    testWidgets('startup and resume recover durable outbox before scheduling', (
      tester,
    ) async {
      var recoveryCalls = 0;
      final recoveringEngine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
        webSocketService: webSocketService,
        keyManager: keyManager,
        groupKeyRecovery: keyRecovery,
        recoverDurableOutbox: () async {
          recoveryCalls++;
          return 0;
        },
      );

      recoveringEngine.initialize();
      await tester.pump();
      expect(recoveryCalls, 1);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(recoveryCalls, 2);
      recoveringEngine.dispose();
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
          () => orchestrator.getQueueSummary(),
        ).thenAnswer((_) async => const SyncQueueSummary(pendingCount: 2));
        engine.onProfileChanged();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.queuedOffline);

        when(() => orchestrator.getQueueSummary()).thenAnswer(
          (_) async =>
              const SyncQueueSummary(pendingCount: 1, deadLetterCount: 1),
        );
        engine.onProfileChanged();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(engine.currentStatus.state, SyncState.needsAttention);
        expect(engine.currentStatus.pendingQueueCount, 1);
        expect(engine.currentStatus.deadLetterCount, 1);

        when(
          () => orchestrator.execute(any()),
        ).thenAnswer((_) async => const SyncOrchestratorError('offline'));
        when(
          () => orchestrator.getQueueSummary(),
        ).thenAnswer((_) async => const SyncQueueSummary());
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

    test('no-group sync result disconnects the relay websocket', () async {
      when(
        () => orchestrator.execute(any()),
      ).thenAnswer((_) async => const SyncOrchestratorNoGroup());

      engine.onSyncAvailable();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(engine.currentStatus.state, SyncState.noGroup);
      expect(webSocketService.disconnectCalls, 1);
    });

    test(
      'local-data wipe waits for in-flight sync and resets transport state',
      () async {
        final release = Completer<void>();
        when(() => orchestrator.execute(any())).thenAnswer((_) async {
          await release.future;
          return const SyncOrchestratorSuccess();
        });

        engine.onManualSync();
        await Future<void>.delayed(Duration.zero);
        var finished = false;
        final suspension = engine.suspendForLocalDataWipe().then(
          (_) => finished = true,
        );
        engine.onSyncAvailable();
        await Future<void>.delayed(Duration.zero);
        expect(finished, isFalse);

        release.complete();
        await suspension;
        expect(engine.isLocalDataWipeSuspended, isTrue);
        expect(webSocketService.disconnectCalls, greaterThanOrEqualTo(1));
        verify(() => orchestrator.execute(any())).called(1);

        engine.resetAfterLocalDataWipe();
        expect(engine.isLocalDataWipeSuspended, isFalse);
        expect(engine.currentStatus.state, SyncState.noGroup);
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
            onJoinRequest: any(named: 'onJoinRequest'),
            onMemberLeft: any(named: 'onMemberLeft'),
            onGroupDissolved: any(named: 'onGroupDissolved'),
            onGroupSnapshotInvalidated: any(
              named: 'onGroupSnapshotInvalidated',
            ),
            onGroupKeyRequested: any(named: 'onGroupKeyRequested'),
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

    test('registers and routes every push lifecycle handler', () async {
      final pushService = _MockPushNotificationService();
      late PushMessageHandler joinRequestHandler;
      late PushMessageHandler memberLeftHandler;
      late PushMessageHandler groupDissolvedHandler;
      late PushMessageHandler groupSnapshotInvalidatedHandler;
      var joinRequests = 0;
      var memberLeftGroupId = '';
      var memberLeftDeviceId = '';
      String? memberLeftReason;
      int? memberLeftKeyEpoch;
      var dissolvedGroupId = '';

      when(
        () => pushService.registerHandlers(
          onMemberConfirmed: any(named: 'onMemberConfirmed'),
          onSyncAvailable: any(named: 'onSyncAvailable'),
          onJoinRequest: any(named: 'onJoinRequest'),
          onMemberLeft: any(named: 'onMemberLeft'),
          onGroupDissolved: any(named: 'onGroupDissolved'),
          onGroupSnapshotInvalidated: any(named: 'onGroupSnapshotInvalidated'),
          onGroupKeyRequested: any(named: 'onGroupKeyRequested'),
        ),
      ).thenAnswer((invocation) {
        joinRequestHandler =
            invocation.namedArguments[#onJoinRequest] as PushMessageHandler;
        memberLeftHandler =
            invocation.namedArguments[#onMemberLeft] as PushMessageHandler;
        groupDissolvedHandler =
            invocation.namedArguments[#onGroupDissolved] as PushMessageHandler;
        groupSnapshotInvalidatedHandler =
            invocation.namedArguments[#onGroupSnapshotInvalidated]
                as PushMessageHandler;
      });

      engine.configureLifecycleHandlers(
        onJoinRequest: (groupId) async {
          joinRequests++;
        },
        onMemberLeft: (groupId, deviceId, reason, keyEpoch) async {
          memberLeftGroupId = groupId;
          memberLeftDeviceId = deviceId;
          memberLeftReason = reason;
          memberLeftKeyEpoch = keyEpoch;
        },
        onGroupDissolved: (groupId) async {
          dissolvedGroupId = groupId;
        },
      );
      engine.connectPushNotifications(pushService);

      await joinRequestHandler({'groupId': 'group-1', 'deviceId': 'device-2'});
      await memberLeftHandler({
        'groupId': 'group-1',
        'deviceId': 'device-2',
        'reason': 'removed',
        'keyEpoch': 2,
      });
      when(() => groupRepo.getActiveGroup()).thenAnswer((_) async => null);
      await groupDissolvedHandler({'groupId': 'group-1'});
      await groupSnapshotInvalidatedHandler({'groupId': 'group-1'});

      expect(joinRequests, 1);
      expect(memberLeftGroupId, 'group-1');
      expect(memberLeftDeviceId, 'device-2');
      expect(memberLeftReason, 'removed');
      expect(memberLeftKeyEpoch, 2);
      expect(dissolvedGroupId, 'group-1');
      expect(engine.currentStatus.state, SyncState.noGroup);
    });
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
