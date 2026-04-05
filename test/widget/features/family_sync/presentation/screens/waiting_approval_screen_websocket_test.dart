import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  late MockGroupRepository groupRepository;
  late MockCheckGroupUseCase checkGroupUseCase;
  late SyncEngine syncEngine;
  late MockSyncOrchestrator mockOrchestrator;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
  late StreamController<WebSocketConnectionState> wsStateController;

  setUp(() {
    groupRepository = MockGroupRepository();
    checkGroupUseCase = MockCheckGroupUseCase();
    mockOrchestrator = MockSyncOrchestrator();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
    wsStateController = StreamController<WebSocketConnectionState>.broadcast();

    when(() => mockOrchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(() => mockOrchestrator.getPendingQueueCount())
        .thenAnswer((_) async => 0);
    when(() => mockOrchestrator.execute(any()))
        .thenAnswer((_) async => const SyncOrchestratorSuccess());
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);

    syncEngine = SyncEngine(
      orchestrator: mockOrchestrator,
      groupRepo: groupRepository,
      webSocketService: webSocketService,
      keyManager: keyManager,
    );

    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

    // WebSocket mocks
    when(() => webSocketService.connectionStateStream)
        .thenAnswer((_) => wsStateController.stream);
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.eventStream)
        .thenAnswer((_) => const Stream.empty());

    // KeyManager mock
    when(() => keyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device-id');
    when(() => keyManager.signData(any()))
        .thenAnswer((_) async =>
            Signature([], publicKey: SimplePublicKey([], type: KeyPairType.ed25519)));
  });

  tearDown(() async {
    syncEngine.dispose();
    await wsStateController.close();
  });

  List<Override> buildOverrides() => [
        groupRepositoryProvider.overrideWithValue(groupRepository),
        checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
        syncEngineProvider.overrideWithValue(syncEngine),
        webSocketServiceProvider.overrideWithValue(webSocketService),
        keyManagerProvider.overrideWithValue(keyManager),
      ];

  testWidgets('always polls regardless of WebSocket connection state',
      (tester) async {
    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

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
    verify(() => checkGroupUseCase.execute()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('continues polling after WebSocket disconnects', (tester) async {
    when(() => checkGroupUseCase.execute())
        .thenAnswer((_) async => const CheckGroupNotInGroup());

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

    verify(() => checkGroupUseCase.execute()).called(greaterThanOrEqualTo(1));
  });
}
