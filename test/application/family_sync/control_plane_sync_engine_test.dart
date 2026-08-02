import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/control_plane_reconciliation_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockControlPlaneReconciliation extends Mock
    implements ControlPlaneReconciliationUseCase {}

class _TrackingWebSocketService extends Mock implements WebSocketService {
  _TrackingWebSocketService(this.onConnect);

  final void Function() onConnect;
  final events = StreamController<WebSocketEvent>.broadcast();

  @override
  Stream<WebSocketEvent> get eventStream => events.stream;

  @override
  void connect({
    required String groupId,
    required String deviceId,
    required SignMessageFn signMessage,
  }) {
    onConnect();
  }

  @override
  void disconnect() {}

  @override
  void startLifecycleObservation() {}

  @override
  void stopLifecycleObservation() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockSyncOrchestrator orchestrator;
  late _MockGroupRepository groupRepository;
  late _MockKeyManager keyManager;
  late _MockControlPlaneReconciliation reconciliation;
  late _TrackingWebSocketService webSocket;
  late List<String> order;

  final activeGroup = GroupInfo(
    groupId: 'group-1',
    status: GroupStatus.active,
    groupName: 'Family',
    role: 'member',
    groupKey: 'group-key',
    keyEpoch: 2,
    members: const [
      GroupMember(
        deviceId: 'device-1',
        publicKey: 'pk-1',
        deviceName: 'Phone',
        role: 'member',
        status: 'active',
        displayName: 'Me',
        avatarEmoji: '🏠',
      ),
    ],
    createdAt: DateTime.utc(2026, 8, 1),
  );

  setUpAll(() {
    registerFallbackValue(SyncMode.incrementalPull);
  });

  setUp(() {
    order = [];
    orchestrator = _MockSyncOrchestrator();
    groupRepository = _MockGroupRepository();
    keyManager = _MockKeyManager();
    reconciliation = _MockControlPlaneReconciliation();
    webSocket = _TrackingWebSocketService(() => order.add('ws'));

    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => activeGroup);
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(
      () => orchestrator.getQueueSummary(),
    ).thenAnswer((_) async => const SyncQueueSummary());
    when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(() => orchestrator.execute(any())).thenAnswer((invocation) async {
      order.add('pull');
      return const SyncOrchestratorSuccess();
    });
    when(() => reconciliation.execute()).thenAnswer((_) async {
      order.add('reconcile');
      return const ControlPlaneReconciliationResult.reconciled(
        pageCount: 1,
        eventCount: 0,
      );
    });
  });

  SyncEngine makeEngine({
    Future<int> Function()? recoverOutbox,
    Future<void> Function()? maintainInboundQuarantine,
    Future<void> Function()? maintainAvatarStaging,
  }) {
    return SyncEngine(
      orchestrator: orchestrator,
      groupRepo: groupRepository,
      webSocketService: webSocket,
      keyManager: keyManager,
      controlPlaneReconciliation: reconciliation,
      recoverDurableOutbox:
          recoverOutbox ??
          () async {
            order.add('outbox');
            return 0;
          },
      maintainInboundQuarantine: maintainInboundQuarantine,
      maintainAvatarStaging: maintainAvatarStaging,
    );
  }

  test('cold start reconciles before outbox, pull, and WebSocket', () async {
    final engine = makeEngine();
    addTearDown(webSocket.events.close);

    await engine.initialize();

    expect(order.take(4), ['reconcile', 'outbox', 'pull', 'ws']);
    engine.dispose();
    verify(() => orchestrator.execute(SyncMode.incrementalPull)).called(1);
  });

  test('missed removal on cold start skips every data-plane action', () async {
    when(
      () => reconciliation.execute(),
    ).thenAnswer((_) async => const ControlPlaneReconciliationResult.noGroup());
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    var outboxCalls = 0;
    final engine = makeEngine(
      recoverOutbox: () async {
        outboxCalls++;
        return 0;
      },
    );
    addTearDown(webSocket.events.close);

    await engine.initialize();

    expect(outboxCalls, 0);
    expect(order, isEmpty);
    verifyNever(() => orchestrator.execute(any()));
  });

  testWidgets('foreground resume preserves the control-first order', (
    tester,
  ) async {
    final engine = makeEngine();
    addTearDown(webSocket.events.close);
    await engine.initialize();
    order.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 20));

    expect(order.take(4), ['reconcile', 'outbox', 'pull', 'ws']);
    engine.dispose();
  });

  testWidgets('cold start and resume both maintain inbound quarantine', (
    tester,
  ) async {
    var maintenanceCalls = 0;
    final engine = makeEngine(
      maintainInboundQuarantine: () async {
        maintenanceCalls++;
      },
    );
    addTearDown(engine.dispose);
    addTearDown(webSocket.events.close);

    await engine.initialize();
    expect(maintenanceCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 20));
    expect(maintenanceCalls, 2);
    engine.dispose();
  });

  testWidgets('cold start and resume both maintain avatar staging', (
    tester,
  ) async {
    var maintenanceCalls = 0;
    final engine = makeEngine(
      maintainAvatarStaging: () async {
        maintenanceCalls++;
      },
    );
    addTearDown(engine.dispose);
    addTearDown(webSocket.events.close);

    await engine.initialize();
    expect(maintenanceCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 20));
    expect(maintenanceCalls, 2);
    engine.dispose();
  });

  testWidgets('concurrent cold start and resume share one pipeline', (
    tester,
  ) async {
    final result = Completer<ControlPlaneReconciliationResult>();
    when(() => reconciliation.execute()).thenAnswer((_) {
      order.add('reconcile');
      return result.future;
    });
    final engine = makeEngine();
    addTearDown(engine.dispose);
    addTearDown(webSocket.events.close);

    final coldStart = engine.initialize();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    verify(() => reconciliation.execute()).called(1);
    result.complete(
      const ControlPlaneReconciliationResult.reconciled(
        pageCount: 1,
        eventCount: 0,
      ),
    );
    await coldStart;
    expect(order.where((step) => step == 'pull').length, 1);
    engine.dispose();
  });

  test('pull membership error triggers one follow-up reconciliation', () async {
    var reconciliationCalls = 0;
    when(() => reconciliation.execute()).thenAnswer((_) async {
      reconciliationCalls++;
      return const ControlPlaneReconciliationResult.reconciled(
        pageCount: 1,
        eventCount: 0,
      );
    });
    when(
      () => reconciliation.executeAfterAuthenticatedMembershipFailure(
        statusCode: 403,
        reason: 'removed',
      ),
    ).thenAnswer((_) async => const ControlPlaneReconciliationResult.noGroup());
    when(() => orchestrator.execute(SyncMode.incrementalPull)).thenAnswer(
      (_) async => const SyncOrchestratorError('removed', statusCode: 403),
    );
    final engine = makeEngine();
    addTearDown(engine.dispose);
    addTearDown(webSocket.events.close);

    await engine.initialize();

    expect(reconciliationCalls, 1);
    verify(
      () => reconciliation.executeAfterAuthenticatedMembershipFailure(
        statusCode: 403,
        reason: 'removed',
      ),
    ).called(1);
  });

  test(
    'local wipe waits for membership reconciliation spawned by sync failure',
    () async {
      final reconciliationStarted = Completer<void>();
      final reconciliationRelease =
          Completer<ControlPlaneReconciliationResult>();
      when(
        () => reconciliation.executeAfterAuthenticatedMembershipFailure(
          statusCode: 403,
          reason: 'removed',
        ),
      ).thenAnswer((_) {
        reconciliationStarted.complete();
        return reconciliationRelease.future;
      });
      when(() => orchestrator.execute(SyncMode.profileSync)).thenAnswer(
        (_) async => const SyncOrchestratorError('removed', statusCode: 403),
      );
      final engine = makeEngine();
      addTearDown(engine.dispose);
      addTearDown(webSocket.events.close);

      engine.onProfileChanged();
      await reconciliationStarted.future;
      var suspended = false;
      final suspension = engine.suspendForLocalDataWipe().then(
        (_) => suspended = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(suspended, isFalse);
      reconciliationRelease.complete(
        const ControlPlaneReconciliationResult.noGroup(),
      );
      await suspension;
      expect(engine.isLocalDataWipeSuspended, isTrue);
    },
  );

  test('WebSocket auth error triggers one reconciliation', () async {
    var reconciliationCalls = 0;
    when(() => reconciliation.execute()).thenAnswer((_) async {
      reconciliationCalls++;
      return const ControlPlaneReconciliationResult.reconciled(
        pageCount: 1,
        eventCount: 0,
      );
    });
    final engine = makeEngine();
    addTearDown(engine.dispose);
    addTearDown(webSocket.events.close);
    await engine.initialize();

    webSocket.events.add(
      const WebSocketEvent(
        type: WebSocketEventType.authError,
        groupId: 'group-1',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(reconciliationCalls, 2);
  });
}
