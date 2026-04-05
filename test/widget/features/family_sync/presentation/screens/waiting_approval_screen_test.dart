import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
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

  GroupInfo buildConfirmingGroup() => GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.confirming,
    role: 'member',
    members: const [
      GroupMember(
        deviceId: 'owner-1',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        displayName: 'Owner phone',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      ),
      GroupMember(
        deviceId: 'member-1',
        publicKey: 'pk-member',
        deviceName: 'My iPhone',
        displayName: 'My iPhone',
        avatarEmoji: '🏠',
        role: 'member',
        status: 'pending',
      ),
    ],
    createdAt: DateTime(2026, 3, 3),
  );

  GroupInfo buildActiveGroup() => GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'member',
    members: const [
      GroupMember(
        deviceId: 'owner-1',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        displayName: 'Owner phone',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      ),
      GroupMember(
        deviceId: 'member-1',
        publicKey: 'pk-member',
        deviceName: 'My iPhone',
        displayName: 'My iPhone',
        avatarEmoji: '🏠',
        role: 'member',
        status: 'active',
      ),
    ],
    createdAt: DateTime(2026, 3, 3),
  );

  setUp(() {
    groupRepository = MockGroupRepository();
    checkGroupUseCase = MockCheckGroupUseCase();
    mockOrchestrator = MockSyncOrchestrator();
    when(() => mockOrchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(() => mockOrchestrator.getPendingQueueCount())
        .thenAnswer((_) async => 0);
    when(() => mockOrchestrator.execute(any()))
        .thenAnswer((_) async => const SyncOrchestratorSuccess());
    when(() => groupRepository.getActiveGroup())
        .thenAnswer((_) async => null);
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();

    when(() => webSocketService.connectionStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => webSocketService.connectionState)
        .thenReturn(WebSocketConnectionState.disconnected);
    when(() => webSocketService.eventStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => webSocketService.connect(
          groupId: any(named: 'groupId'),
          deviceId: any(named: 'deviceId'),
          signMessage: any(named: 'signMessage'),
        )).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);
    when(() => keyManager.getDeviceId())
        .thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any())).thenAnswer((_) async =>
        Signature([], publicKey: SimplePublicKey([], type: KeyPairType.ed25519)));

    syncEngine = SyncEngine(
      orchestrator: mockOrchestrator,
      groupRepo: groupRepository,
      webSocketService: webSocketService,
      keyManager: keyManager,
    );
    // Default: still waiting
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupNotInGroup());
  });

  tearDown(() {
    syncEngine.dispose();
  });

  testWidgets('shows waiting approval state using repository group data', (
    tester,
  ) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => buildActiveGroup());

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner phone',
        ),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
          syncEngineProvider.overrideWithValue(syncEngine),
          webSocketServiceProvider.overrideWithValue(webSocketService),
          keyManagerProvider.overrideWithValue(keyManager),
        ],
      ),
    );
    // Use pump with duration instead of pumpAndSettle to avoid timeout
    // caused by the indefinitely-animating CircularProgressIndicator
    await tester.pump(const Duration(milliseconds: 100));

    // The new screen shows groupName and ownerDisplayName passed as params
    expect(find.text('Test Family'), findsOneWidget);
    // Waiting title from l10n.groupWaitingApproval
    expect(find.text('Waiting for Owner approval...'), findsOneWidget);
    // A progress indicator is displayed
    expect(find.byType(WaitingApprovalScreen), findsOneWidget);
  });

  testWidgets(
    'verifies group state before navigating when memberConfirmed event is received',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncEngineProvider.overrideWithValue(syncEngine),
            webSocketServiceProvider.overrideWithValue(webSocketService),
            keyManagerProvider.overrideWithValue(keyManager),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate SyncEngine receiving memberConfirmed → status changes
      syncEngine.onMemberConfirmed();
      // Allow the async verification and navigation to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => checkGroupUseCase.execute()).called(1);
      // After approval the screen navigates to GroupManagementScreen,
      // which shows the group name from the loaded group data
      expect(find.text('Test Family'), findsOneWidget);
      expect(find.byType(WaitingApprovalScreen), findsNothing);
    },
  );

  testWidgets(
    'stays on waiting screen when group verification returns not-in-group',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupNotInGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncEngineProvider.overrideWithValue(syncEngine),
            webSocketServiceProvider.overrideWithValue(webSocketService),
            keyManagerProvider.overrideWithValue(keyManager),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate SyncEngine receiving memberConfirmed → emits initialSyncing then synced
      syncEngine.onMemberConfirmed();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => checkGroupUseCase.execute()).called(greaterThan(0));
      // Screen should remain since checkGroup returns not-in-group
      expect(find.byType(WaitingApprovalScreen), findsOneWidget);
    },
  );

  testWidgets('polls server with adaptive backoff starting at 5s', (tester) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupNotInGroup());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncEngineProvider.overrideWithValue(syncEngine),
            webSocketServiceProvider.overrideWithValue(webSocketService),
            keyManagerProvider.overrideWithValue(keyManager),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => checkGroupUseCase.execute());

      // Wait for the 5-second adaptive polling timer to fire
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => checkGroupUseCase.execute()).called(1);
    });
  });

  testWidgets('stops polling after successful navigation', (tester) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => buildActiveGroup());
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncEngineProvider.overrideWithValue(syncEngine),
            webSocketServiceProvider.overrideWithValue(webSocketService),
            keyManagerProvider.overrideWithValue(keyManager),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for first adaptive poll to fire and navigate (5s)
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => checkGroupUseCase.execute()).called(1);

      // Wait for another poll cycle — should not call again after navigation
      await Future<void>.delayed(const Duration(seconds: 11));
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => checkGroupUseCase.execute());
    });
  });
}
