import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();

    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
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
            deviceName: 'Kitchen tablet',
            displayName: 'Kitchen tablet',
            avatarEmoji: '🏠',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    when(
      () => confirmMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const ConfirmMemberSuccess());

    when(
      () => removeMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const RemoveMemberResult.success());

    // WebSocket mocks
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

    // KeyManager mock
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any())).thenAnswer(
      (_) async => Signature(
        [],
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
      ),
    );

    // Mock getGroupById for navigation to GroupManagementScreen after approve
    when(
      () => groupRepository.getGroupById(any()),
    ).thenAnswer((_) async => null);
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
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
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
  });

  List<Override> buildOverrides() => [
    groupRepositoryProvider.overrideWithValue(groupRepository),
    confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
    removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
    webSocketServiceProvider.overrideWithValue(webSocketService),
    keyManagerProvider.overrideWithValue(keyManager),
  ];

  testWidgets('shows both approve and reject buttons', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    // The new screen shows the pending member and approve/reject actions
    expect(find.text('Kitchen tablet'), findsAtLeastNWidgets(1));
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('approves a member and calls use case', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.pump();

    verify(
      () => confirmMemberUseCase.execute(
        groupId: 'group-1',
        deviceId: 'member-1',
      ),
    ).called(1);
  });

  testWidgets('rejects a member and pops navigation', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const MemberApprovalScreen(),
          ),
        ),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    verify(
      () =>
          removeMemberUseCase.execute(groupId: 'group-1', deviceId: 'member-1'),
    ).called(1);
  });

  testWidgets('shows error snackbar when reject fails', (tester) async {
    when(
      () => removeMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const RemoveMemberResult.error('Server error'));

    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('disables both buttons while approving', (tester) async {
    final completer = Completer<ConfirmMemberResult>();
    when(
      () => confirmMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.pump();

    // During approving, the approve button shows a progress indicator
    // and both GestureDetectors have their onTap set to null (isBusy = true).
    // Verify the loading indicator is shown instead of the approve text.
    expect(find.text('Approve'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

    // Complete the future to avoid pending timer
    completer.complete(const ConfirmMemberSuccess());
    await tester.pump();
  });

  testWidgets('uses explicit groupId to load the target group', (tester) async {
    when(() => groupRepository.getGroupById('group-42')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-42',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
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
            deviceId: 'pending-1',
            publicKey: 'pk-pending',
            deviceName: 'Guest device',
            displayName: 'Guest device',
            avatarEmoji: '🏠',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(groupId: 'group-42'),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => groupRepository.getGroupById('group-42')).called(1);
    verifyNever(() => groupRepository.getActiveGroup());
    // The pending member from group-42 is shown
    expect(find.text('Guest device'), findsAtLeastNWidgets(1));
  });
}
