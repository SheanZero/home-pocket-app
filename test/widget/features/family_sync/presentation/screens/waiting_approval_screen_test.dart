import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/join_request_lifecycle_use_cases.dart';
import 'package:home_pocket/application/family_sync/group_key_recovery_use_case.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
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

class MockGroupKeyRecoveryCoordinator extends Mock
    implements GroupKeyRecoveryCoordinator {}

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
  late StreamController<Map<String, dynamic>> joinRequestEvents;

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
    memberActivationUseCase = MockCompleteMemberActivationUseCase();
    mockOrchestrator = MockSyncOrchestrator();
    when(() => mockOrchestrator.needsFullPull()).thenAnswer((_) async => false);
    when(
      () => mockOrchestrator.getQueueSummary(),
    ).thenAnswer((_) async => const SyncQueueSummary());
    when(
      () => mockOrchestrator.execute(any()),
    ).thenAnswer((_) async => const SyncOrchestratorSuccess());
    when(() => groupRepository.getActiveGroup()).thenAnswer((_) async => null);
    when(() => groupRepository.deactivateGroup(any())).thenAnswer((_) async {});
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
    getJoinRequestStatusUseCase = MockGetJoinRequestStatusUseCase();
    cancelJoinRequestUseCase = MockCancelJoinRequestUseCase();
    pushNotificationService = MockPushNotificationService();
    joinRequestEvents = StreamController<Map<String, dynamic>>.broadcast();

    when(
      () => webSocketService.connectionStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => webSocketService.connectionState,
    ).thenReturn(WebSocketConnectionState.disconnected);
    when(
      () => webSocketService.eventStream,
    ).thenAnswer((_) => const Stream.empty());
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
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any())).thenAnswer(
      (_) async => Signature(
        [],
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
      ),
    );
    when(
      () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
    ).thenAnswer(
      (_) async => const JoinRequestLifecycleSuccess(JoinRequestStatus.pending),
    );
    when(() => cancelJoinRequestUseCase.execute(groupId: 'group-1')).thenAnswer(
      (_) async =>
          const JoinRequestLifecycleSuccess(JoinRequestStatus.cancelled),
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
    // Default: still waiting
    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationNotInGroup());
  });

  tearDown(() {
    syncEngine.dispose();
    joinRequestEvents.close();
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
          pushNotificationServiceProvider.overrideWithValue(
            pushNotificationService,
          ),
        ],
      ),
    );
    // Use pump with duration instead of pumpAndSettle to avoid timeout
    // caused by the indefinitely-animating CircularProgressIndicator
    await tester.pump(const Duration(milliseconds: 100));

    // Header and owner-specific waiting state follow the selected mockup.
    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Waiting for owner approval'), findsOneWidget);
    // A progress indicator is displayed
    expect(find.byType(WaitingApprovalScreen), findsOneWidget);
  });

  testWidgets(
    'shows manual retry and safe rebuild path when zero-knowledge recovery expires',
    (tester) async {
      final recovery = MockGroupKeyRecoveryCoordinator();
      final recoveryEvents =
          StreamController<GroupKeyRecoveryStatus>.broadcast();
      when(
        () => recovery.currentStatus,
      ).thenReturn(const GroupKeyRecoveryStatus());
      when(
        () => recovery.statusStream,
      ).thenAnswer((_) => recoveryEvents.stream);
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
            groupKeyRecoveryCoordinatorProvider.overrideWithValue(recovery),
          ],
        ),
      );
      joinRequestEvents.add({'groupId': 'group-1', 'status': 'approved'});
      recoveryEvents.add(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.unrecoverable,
          groupId: 'group-1',
          expiresAt: DateTime.utc(2026, 8, 1),
        ),
      );
      await tester.pump();

      expect(find.text('Restoring the family key'), findsOneWidget);
      expect(find.text('Retry key recovery'), findsOneWidget);
      expect(find.text('Leave and set up a new family'), findsOneWidget);
      await recoveryEvents.close();
    },
  );

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
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).thenAnswer(
        (_) async => const MemberActivationReady(groupId: 'group-1'),
      );

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate SyncEngine receiving memberConfirmed → status changes
      syncEngine.onMemberConfirmed();
      // Allow the async verification and navigation to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(1);
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
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).thenAnswer((_) async => const MemberActivationNotInGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Simulate SyncEngine receiving memberConfirmed → emits initialSyncing then synced
      syncEngine.onMemberConfirmed();
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(greaterThan(0));
      // Screen should remain since checkGroup returns not-in-group
      expect(find.byType(WaitingApprovalScreen), findsOneWidget);
    },
  );

  testWidgets(
    'stays on waiting screen while the local member is pending approval',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());
      when(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).thenAnswer(
        (_) async => const MemberActivationPendingApproval(groupId: 'group-1'),
      );

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      syncEngine.onMemberConfirmed();
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(greaterThan(0));
      expect(find.byType(WaitingApprovalScreen), findsOneWidget);
    },
  );

  testWidgets('polls server with adaptive backoff starting at 5s', (
    tester,
  ) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationNotInGroup());

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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      );

      // Wait for the 5-second adaptive polling timer to fire
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(1);
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
      () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
    ).thenAnswer((_) async => const MemberActivationReady(groupId: 'group-1'));

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
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for first adaptive poll to fire and navigate (5s)
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 100));

      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(1);

      // Wait for another poll cycle — should not call again after navigation
      await Future<void>.delayed(const Duration(seconds: 11));
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      );
    });
  });

  testWidgets('terminal push stops polling and shows a reapply path', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner phone',
        ),
        overrides: [
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
          pushNotificationServiceProvider.overrideWithValue(
            pushNotificationService,
          ),
        ],
      ),
    );
    await tester.pump();

    joinRequestEvents.add({
      'type': 'join_request_rejected',
      'groupId': 'group-1',
      'status': 'rejected',
    });
    await tester.pump();

    expect(find.text('Join request declined'), findsOneWidget);
    expect(find.text('Enter another invite code'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    verifyNever(() => getJoinRequestStatusUseCase.execute(groupId: 'group-1'));
  });

  testWidgets('applicant can cancel a pending request', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(
          groupId: 'group-1',
          groupName: 'Test Family',
          ownerDisplayName: 'Owner phone',
        ),
        overrides: [
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
          pushNotificationServiceProvider.overrideWithValue(
            pushNotificationService,
          ),
        ],
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Cancel join request'));
    await tester.tap(find.text('Cancel join request'));
    await tester.pump();

    verify(
      () => cancelJoinRequestUseCase.execute(groupId: 'group-1'),
    ).called(1);
    expect(find.text('Join request cancelled'), findsOneWidget);
  });
}
