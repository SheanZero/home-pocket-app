import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/join_request_lifecycle_use_cases.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockCompleteMemberActivationUseCase extends Mock
    implements CompleteMemberActivationUseCase {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

class MockGetJoinRequestStatusUseCase extends Mock
    implements GetJoinRequestStatusUseCase {}

class MockCancelJoinRequestUseCase extends Mock
    implements CancelJoinRequestUseCase {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  late MockGroupRepository groupRepository;
  late MockCompleteMemberActivationUseCase memberActivationUseCase;
  late SyncEngine syncEngine;
  late MockSyncOrchestrator mockOrchestrator;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
  late MockGetJoinRequestStatusUseCase getJoinRequestStatusUseCase;
  late MockCancelJoinRequestUseCase cancelJoinRequestUseCase;
  late MockPushNotificationService pushNotificationService;
  late StreamController<WebSocketConnectionState> wsStateController;
  late StreamController<WebSocketEvent> wsEventController;
  late StreamController<Map<String, dynamic>> joinRequestEvents;

  setUp(() {
    groupRepository = MockGroupRepository();
    memberActivationUseCase = MockCompleteMemberActivationUseCase();
    mockOrchestrator = MockSyncOrchestrator();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
    getJoinRequestStatusUseCase = MockGetJoinRequestStatusUseCase();
    cancelJoinRequestUseCase = MockCancelJoinRequestUseCase();
    pushNotificationService = MockPushNotificationService();
    wsStateController = StreamController<WebSocketConnectionState>.broadcast();
    wsEventController = StreamController<WebSocketEvent>.broadcast();
    joinRequestEvents = StreamController<Map<String, dynamic>>.broadcast();

    when(() => mockOrchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(
      () => mockOrchestrator.getQueueSummary(),
    ).thenAnswer((_) async => const SyncQueueSummary());
    when(
      () => mockOrchestrator.execute(any()),
    ).thenAnswer((_) async => const SyncOrchestratorSuccess());
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    when(
      () => groupRepository.getGroupById(any()),
    ).thenAnswer((_) async => null);
    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
    ).thenAnswer(
      (_) async => const JoinRequestLifecycleSuccess(JoinRequestStatus.pending),
    );
    when(
      () => pushNotificationService.joinRequestLifecycleEvents,
    ).thenAnswer((_) => joinRequestEvents.stream);

    syncEngine = SyncEngine(
      orchestrator: mockOrchestrator,
      groupRepo: groupRepository,
      webSocketService: webSocketService,
      keyManager: keyManager,
    );

    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationNotInGroup());

    // WebSocket mocks
    when(
      () => webSocketService.connectionStateStream,
    ).thenAnswer((_) => wsStateController.stream);
    when(
      () => webSocketService.connectionState,
    ).thenReturn(WebSocketConnectionState.disconnected);
    when(
      () => webSocketService.connect(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
        signMessage: any(named: 'signMessage'),
      ),
    ).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(
      () => webSocketService.eventStream,
    ).thenAnswer((_) => wsEventController.stream);

    // KeyManager mock
    when(
      () => keyManager.getDeviceId(),
    ).thenAnswer((_) async => 'test-device-id');
    when(() => keyManager.signData(any())).thenAnswer(
      (_) async => Signature(
        [],
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
      ),
    );
  });

  tearDown(() async {
    syncEngine.dispose();
    await wsStateController.close();
    await wsEventController.close();
    await joinRequestEvents.close();
  });

  List<Override> buildOverrides() => [
    groupRepositoryProvider.overrideWithValue(groupRepository),
    completeMemberActivationUseCaseProvider.overrideWithValue(
      memberActivationUseCase,
    ),
    syncEngineProvider.overrideWithValue(syncEngine),
    webSocketServiceProvider.overrideWithValue(webSocketService),
    keyManagerProvider.overrideWithValue(keyManager),
    getJoinRequestStatusUseCaseProvider.overrideWithValue(
      getJoinRequestStatusUseCase,
    ),
    cancelJoinRequestUseCaseProvider.overrideWithValue(
      cancelJoinRequestUseCase,
    ),
    pushNotificationServiceProvider.overrideWithValue(pushNotificationService),
  ];

  testWidgets('member_confirmed WebSocket event activates immediately', (
    tester,
  ) async {
    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationReady(groupId: 'group-1'));

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner',
        ),
        overrides: buildOverrides(),
      ),
    );
    await tester.pump();

    verify(
      () => webSocketService.connect(
        groupId: 'group-1',
        deviceId: 'test-device-id',
        signMessage: any(named: 'signMessage'),
      ),
    ).called(1);

    wsEventController.add(
      const WebSocketEvent(
        type: WebSocketEventType.memberConfirmed,
        groupId: 'group-1',
        data: {'deviceId': 'test-device-id', 'eventId': 'event-7'},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    verify(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).called(1);
    expect(find.byType(GroupManagementScreen), findsOneWidget);
  });

  testWidgets('always polls regardless of WebSocket connection state', (
    tester,
  ) async {
    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationNotInGroup());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner',
          ),
          overrides: buildOverrides(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // WebSocket connection state events no longer affect polling in the screen;
      // SyncEngine owns the WebSocket. Polling runs unconditionally as fallback.
      wsStateController.add(WebSocketConnectionState.connected);
      await tester.pump();

      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump();
    });

    // Polling fires after 5s regardless of WebSocket state
    verify(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('continues polling after WebSocket disconnects', (tester) async {
    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationNotInGroup());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner',
          ),
          overrides: buildOverrides(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // WebSocket disconnect event does not restart polling in the screen;
      // polling is already running as a constant fallback.
      wsStateController.add(WebSocketConnectionState.disconnected);
      await tester.pump();

      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump();
    });

    verify(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).called(greaterThanOrEqualTo(1));
  });
}
