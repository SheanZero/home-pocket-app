import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:home_pocket/application/family_sync/check_group_use_case.dart';
import 'package:home_pocket/application/family_sync/deactivate_group_use_case.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/navigation/family_flow_launcher.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_choice_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/join_group_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/profile/presentation/providers/state_user_profile.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/join_request_lifecycle_use_cases.dart';
import 'package:home_pocket/application/family_sync/group_key_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
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

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class MockLeaveGroupUseCase extends Mock implements LeaveGroupUseCase {}

class MockDeactivateGroupUseCase extends Mock
    implements DeactivateGroupUseCase {}

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
  late MockCheckGroupUseCase checkGroupUseCase;
  late MockLeaveGroupUseCase leaveGroupUseCase;
  late MockDeactivateGroupUseCase deactivateGroupUseCase;
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
    checkGroupUseCase = MockCheckGroupUseCase();
    leaveGroupUseCase = MockLeaveGroupUseCase();
    deactivateGroupUseCase = MockDeactivateGroupUseCase();
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
      () => leaveGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const LeaveGroupResult.success());
    when(
      () => deactivateGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const DeactivateGroupResult.success());
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
    'approved membership stays in recovery progress until activation is ready',
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
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());
      when(
        () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
      ).thenAnswer(
        (_) async =>
            const JoinRequestLifecycleSuccess(JoinRequestStatus.approved),
      );
      var activationAttempts = 0;
      when(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).thenAnswer((_) async {
        activationAttempts++;
        return activationAttempts == 1
            ? const MemberActivationAwaitingKey(groupId: 'group-1')
            : const MemberActivationReady(groupId: 'group-1');
      });

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

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(find.text('Restoring the family key'), findsOneWidget);
      expect(find.text('Unable to join this family right now'), findsNothing);
      expect(find.text('Cancel join request'), findsNothing);
      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(1);

      recoveryEvents.add(
        const GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.recovered,
          groupId: 'group-1',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WaitingApprovalScreen), findsNothing);
      expect(find.text('Test Family'), findsOneWidget);
      verify(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      ).called(1);
      await recoveryEvents.close();
    },
  );

  testWidgets(
    'shows the unified unable-to-join recovery layout without technical copy',
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

      expect(find.text('Unable to join this family right now'), findsOneWidget);
      expect(
        find.text(
          "Don't worry. You can enter the invite code again, or leave and choose another family.",
        ),
        findsOneWidget,
      );
      expect(find.text('Enter invite code again'), findsOneWidget);
      expect(find.text('Leave and choose another family'), findsOneWidget);
      expect(find.text('Restoring the family key'), findsNothing);
      expect(find.text('Retry key recovery'), findsNothing);

      final reenterAction = find.byKey(
        const Key('reenter-family-invite-action'),
      );
      final chooseAction = find.byKey(
        const Key('choose-another-family-action'),
      );
      expect(reenterAction, findsOneWidget);
      expect(chooseAction, findsOneWidget);
      expect(tester.getSize(reenterAction), tester.getSize(chooseAction));
      final reenterButton = tester.widget<OutlinedButton>(reenterAction);
      final chooseButton = tester.widget<OutlinedButton>(chooseAction);
      expect(
        reenterButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        Colors.transparent,
      );
      expect(
        chooseButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        Colors.transparent,
      );
      await recoveryEvents.close();
    },
  );

  testWidgets(
    'authoritative awaiting-key entry opens recovery without approval copy',
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
      when(() => checkGroupUseCase.execute()).thenAnswer(
        (_) async => const CheckGroupAwaitingKey(groupId: 'group-1'),
      );
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          Consumer(
            builder: (context, ref, _) => Scaffold(
              body: FilledButton(
                onPressed: () => openAuthoritativeFamilyFlow(context, ref),
                child: const Text('Open family'),
              ),
            ),
          ),
          overrides: [
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
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
            leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
            deactivateGroupUseCaseProvider.overrideWithValue(
              deactivateGroupUseCase,
            ),
          ],
        ),
      );
      await tester.tap(find.text('Open family'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Restoring the family key'), findsOneWidget);
      expect(find.text('Unable to join this family right now'), findsNothing);
      expect(find.text('Waiting for owner approval'), findsNothing);
      expect(find.text('Cancel join request'), findsNothing);
      expect(find.text('Enter invite code again'), findsNothing);
      expect(find.text('Leave and choose another family'), findsNothing);
      verify(() => checkGroupUseCase.execute()).called(1);
      await recoveryEvents.close();
    },
  );

  testWidgets(
    'active member can leave during key recovery and choose another family',
    (tester) async {
      final recovery = MockGroupKeyRecoveryCoordinator();
      when(() => recovery.currentStatus).thenReturn(
        const GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.unrecoverable,
          groupId: 'group-1',
        ),
      );
      when(() => recovery.statusStream).thenAnswer((_) => const Stream.empty());
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
            initialMode: WaitingApprovalInitialMode.recoveringKey,
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            completeMemberActivationUseCaseProvider.overrideWithValue(
              memberActivationUseCase,
            ),
            syncEngineProvider.overrideWithValue(syncEngine),
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
            leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
            deactivateGroupUseCaseProvider.overrideWithValue(
              deactivateGroupUseCase,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Leave and choose another family'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Leave Group'));
      await tester.pumpAndSettle();

      verify(() => leaveGroupUseCase.execute('group-1')).called(1);
      verifyNever(() => deactivateGroupUseCase.execute(any()));
      expect(find.byType(GroupChoiceScreen), findsOneWidget);
    },
  );

  testWidgets(
    'active member can leave during key recovery and enter another invite',
    (tester) async {
      final recovery = MockGroupKeyRecoveryCoordinator();
      when(() => recovery.currentStatus).thenReturn(
        const GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.unrecoverable,
          groupId: 'group-1',
        ),
      );
      when(() => recovery.statusStream).thenAnswer((_) => const Stream.empty());
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
            initialMode: WaitingApprovalInitialMode.recoveringKey,
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            completeMemberActivationUseCaseProvider.overrideWithValue(
              memberActivationUseCase,
            ),
            syncEngineProvider.overrideWithValue(syncEngine),
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
            leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
            deactivateGroupUseCaseProvider.overrideWithValue(
              deactivateGroupUseCase,
            ),
            userProfileProvider.overrideWith((_) async => null),
          ],
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Enter invite code again'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Leave Group'));
      await tester.pumpAndSettle();

      verify(() => leaveGroupUseCase.execute('group-1')).called(1);
      expect(find.byType(JoinGroupScreen), findsOneWidget);
    },
  );

  testWidgets(
    'active owner can dissolve during key recovery and choose another family',
    (tester) async {
      final recovery = MockGroupKeyRecoveryCoordinator();
      when(() => recovery.currentStatus).thenReturn(
        const GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.unrecoverable,
          groupId: 'group-1',
        ),
      );
      when(() => recovery.statusStream).thenAnswer((_) => const Stream.empty());
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup().copyWith(role: 'owner'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupId: 'group-1',
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
            initialMode: WaitingApprovalInitialMode.recoveringKey,
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            completeMemberActivationUseCaseProvider.overrideWithValue(
              memberActivationUseCase,
            ),
            syncEngineProvider.overrideWithValue(syncEngine),
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
            leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
            deactivateGroupUseCaseProvider.overrideWithValue(
              deactivateGroupUseCase,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Leave and choose another family'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Deactivate Group'));
      await tester.pumpAndSettle();

      verify(() => deactivateGroupUseCase.execute('group-1')).called(1);
      verifyNever(() => leaveGroupUseCase.execute(any()));
      expect(find.byType(GroupChoiceScreen), findsOneWidget);
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

  testWidgets(
    'rate-limited background poll stays quiet and skips activation request',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => const JoinRequestLifecycleError(
          'rate limit exceeded',
          kind: GroupOperationErrorKind.rateLimited,
        ),
      );

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
        await Future<void>.delayed(const Duration(seconds: 6));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('rate limit exceeded'), findsNothing);
        verify(
          () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
        ).called(1);
        verifyNever(
          () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
        );
      });
    },
  );

  testWidgets(
    'missing authoritative request clears stale local waiting state',
    (tester) async {
      when(
        () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => const JoinRequestLifecycleError(
          'member not found in group',
          kind: GroupOperationErrorKind.notFound,
        ),
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
      await tester.pumpAndSettle();

      expect(find.text('member not found in group'), findsNothing);
      expect(find.text('Unable to join this family right now'), findsOneWidget);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
      verifyNever(
        () => memberActivationUseCase.execute(expectedGroupId: 'group-1'),
      );
    },
  );

  testWidgets(
    'missing authoritative request remains terminal when local cleanup fails',
    (tester) async {
      when(
        () => getJoinRequestStatusUseCase.execute(groupId: 'group-1'),
      ).thenAnswer(
        (_) async => const JoinRequestLifecycleError(
          'member not found in group',
          kind: GroupOperationErrorKind.notFound,
        ),
      );
      when(
        () => groupRepository.deactivateGroup('group-1'),
      ).thenThrow(StateError('local cache unavailable'));

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
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('member not found in group'), findsNothing);
      expect(find.text('Unable to join this family right now'), findsOneWidget);
      verify(() => groupRepository.deactivateGroup('group-1')).called(1);
    },
  );

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

  testWidgets('first release does not subscribe to terminal push events', (
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

    verifyNever(() => pushNotificationService.joinRequestLifecycleEvents);

    joinRequestEvents.add({
      'type': 'join_request_rejected',
      'groupId': 'group-1',
      'status': 'rejected',
    });
    await tester.pump();

    expect(find.text('Waiting for approval'), findsOneWidget);
    expect(find.text('Unable to join this family right now'), findsNothing);
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
    expect(find.text('Unable to join this family right now'), findsOneWidget);
  });

  testWidgets(
    'cancel action stays above the iPhone safe area and works without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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

      final action = find.ancestor(
        of: find.text('Cancel join request'),
        matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
      );
      expect(action, findsOneWidget);
      final actionRect = tester.getRect(action);
      expect(actionRect.height, greaterThanOrEqualTo(56));
      expect(
        actionRect.bottom,
        lessThanOrEqualTo(852 - 34),
        reason: 'the entire action must stay above the bottom safe area',
      );
      expect(find.byIcon(LucideIcons.undo), findsOneWidget);

      await tester.tap(action);
      await tester.pump();

      verify(
        () => cancelJoinRequestUseCase.execute(groupId: 'group-1'),
      ).called(1);
      expect(find.text('Unable to join this family right now'), findsOneWidget);
    },
  );
}
