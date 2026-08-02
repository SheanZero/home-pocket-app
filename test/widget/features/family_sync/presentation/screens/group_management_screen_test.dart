import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/application/family_sync/deactivate_group_use_case.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/manage_group_invite_use_case.dart';
import 'package:home_pocket/application/family_sync/transfer_owner_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockLeaveGroupUseCase extends Mock implements LeaveGroupUseCase {}

class MockDeactivateGroupUseCase extends Mock
    implements DeactivateGroupUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockManageGroupInviteUseCase extends Mock
    implements ManageGroupInviteUseCase {}

class MockOwnerTransferUseCase extends Mock implements OwnerTransferUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockLeaveGroupUseCase leaveGroupUseCase;
  late MockDeactivateGroupUseCase deactivateGroupUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockManageGroupInviteUseCase manageGroupInviteUseCase;
  late MockOwnerTransferUseCase ownerTransferUseCase;

  setUp(() {
    groupRepository = MockGroupRepository();
    leaveGroupUseCase = MockLeaveGroupUseCase();
    deactivateGroupUseCase = MockDeactivateGroupUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    manageGroupInviteUseCase = MockManageGroupInviteUseCase();
    ownerTransferUseCase = MockOwnerTransferUseCase();

    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(null));

    when(
      () => leaveGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const LeaveGroupSuccess());
    when(
      () => deactivateGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const DeactivateGroupSuccess());
    when(
      () => removeMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const RemoveMemberSuccess());
    when(
      () => manageGroupInviteUseCase.execute(
        groupId: any(named: 'groupId'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    ).thenAnswer(
      (_) async => ManageGroupInviteSuccess(
        inviteCode: 'INV123',
        expiresAt: DateTime(2099),
        wasRegenerated: false,
      ),
    );
    when(
      () => ownerTransferUseCase.execute(
        groupId: any(named: 'groupId'),
        targetDeviceId: any(named: 'targetDeviceId'),
      ),
    ).thenAnswer(
      (_) async => const OwnerTransferSuccess(
        newOwnerDeviceId: 'member-1',
        keyEpoch: 2,
        requestId: 'request-1',
      ),
    );
  });

  testWidgets('shows owner actions and all group members', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        inviteCode: 'INV123',
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
        confirmedAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Group name is displayed
    expect(find.text('Test Family'), findsOneWidget);
    // Active member (owner) is displayed
    expect(find.text('Owner phone', skipOffstage: false), findsOneWidget);
    // Pending member approval alert follows the task-oriented mockup copy.
    expect(
      find.text('New join requests · 1', skipOffstage: false),
      findsOneWidget,
    );
    // Invite new member button is present for owner
    expect(find.text('Invite new member', skipOffstage: false), findsOneWidget);
    // Disband Group action is visible for owner
    expect(find.text('Disband Family', skipOffstage: false), findsOneWidget);

    await tester.ensureVisible(find.text('Sync settings'));
    await tester.tap(find.text('Sync settings'));
    await tester.pumpAndSettle();
    expect(find.text('Sync Ledger'), findsOneWidget);
    expect(find.text('Manually sync data'), findsOneWidget);
  });

  testWidgets('uses explicit groupId to load the target group', (tester) async {
    when(() => groupRepository.getGroupById('group-42')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-42',
        groupName: 'Test Family',
        status: GroupStatus.active,
        inviteCode: 'INV999',
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
        confirmedAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(groupId: 'group-42'),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    verify(() => groupRepository.getGroupById('group-42')).called(1);
    verifyNever(() => groupRepository.getActiveGroup());
    expect(find.text('Owner phone', skipOffstage: false), findsOneWidget);
  });

  testWidgets('reacts to an authoritative local group-name update', (
    tester,
  ) async {
    final controller = StreamController<GroupInfo?>();
    addTearDown(controller.close);
    final initial = GroupInfo(
      groupId: 'group-1',
      groupName: 'Old family',
      status: GroupStatus.active,
      role: 'member',
      members: const [],
      createdAt: DateTime(2026, 3, 1),
    );
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => initial);
    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => controller.stream);

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old family'), findsOneWidget);

    controller.add(initial.copyWith(groupName: 'New family'));
    await tester.pumpAndSettle();

    expect(find.text('New family'), findsOneWidget);
    expect(find.text('Old family'), findsNothing);
  });

  testWidgets('owner can open, copy, refresh, and share the current invite', (
    tester,
  ) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        inviteCode: '111222',
        inviteExpiresAt: DateTime(2099),
        role: 'owner',
        groupKey: 'current-key',
        members: const [],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    when(
      () => manageGroupInviteUseCase.execute(
        groupId: 'group-1',
        forceRefresh: false,
      ),
    ).thenAnswer(
      (_) async => ManageGroupInviteSuccess(
        inviteCode: '111222',
        expiresAt: DateTime(2099),
        wasRegenerated: false,
      ),
    );
    when(
      () => manageGroupInviteUseCase.execute(
        groupId: 'group-1',
        forceRefresh: true,
      ),
    ).thenAnswer(
      (_) async => ManageGroupInviteSuccess(
        inviteCode: '333444',
        expiresAt: DateTime(2099),
        wasRegenerated: true,
      ),
    );

    final sharedTexts = <String>[];
    final copiedCodes = <String>[];
    await tester.pumpWidget(
      createLocalizedWidget(
        GroupManagementScreen(
          shareInvite: (text) async => sharedTexts.add(text),
          copyInvite: (code) async => copiedCodes.add(code),
        ),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('owner-invite-inline-refresh')),
    );
    await tester.tap(find.byKey(const Key('owner-invite-inline-refresh')));
    await tester.pumpAndSettle();
    expect(find.text('333 444'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('owner-invite-action')));
    await tester.tap(find.byKey(const Key('owner-invite-action')));
    await tester.pumpAndSettle();

    expect(find.text('111222'), findsOneWidget);
    await tester.tap(find.byKey(const Key('owner-invite-copy')));
    await tester.pump();
    expect(copiedCodes, ['111222']);

    await tester.tap(find.byKey(const Key('owner-invite-share')));
    await tester.pump();
    expect(sharedTexts.single, contains('111222'));

    await tester.tap(find.byKey(const Key('owner-invite-refresh')));
    await tester.pumpAndSettle();
    expect(find.text('333444'), findsOneWidget);

    await tester.tap(find.byKey(const Key('owner-invite-share')));
    await tester.pump();
    expect(sharedTexts.last, contains('333444'));
    expect(sharedTexts.last, isNot(contains('111222')));
  });

  testWidgets('non-owner cannot see or invoke invite management', (
    tester,
  ) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'member',
        members: const [],
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('owner-invite-action')), findsNothing);
    verifyNever(
      () => manageGroupInviteUseCase.execute(
        groupId: any(named: 'groupId'),
        forceRefresh: any(named: 'forceRefresh'),
      ),
    );
  });

  testWidgets('expired invite is visibly expired and cannot be shared', (
    tester,
  ) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'current-key',
        members: const [],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    when(
      () => manageGroupInviteUseCase.execute(
        groupId: 'group-1',
        forceRefresh: false,
      ),
    ).thenAnswer(
      (_) async => ManageGroupInviteSuccess(
        inviteCode: 'OLD123',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        wasRegenerated: false,
      ),
    );

    var shared = false;
    await tester.pumpWidget(
      createLocalizedWidget(
        GroupManagementScreen(shareInvite: (_) async => shared = true),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('owner-invite-action')));
    await tester.tap(find.byKey(const Key('owner-invite-action')));
    await tester.pumpAndSettle();

    expect(find.text('Invite code expired'), findsOneWidget);
    final shareButton = tester.widget<FilledButton>(
      find.byKey(const Key('owner-invite-share')),
    );
    expect(shareButton.onPressed, isNull);
    expect(shared, false);
  });

  testWidgets('invite API failure is shown without opening the sheet', (
    tester,
  ) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'current-key',
        members: const [],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    when(
      () => manageGroupInviteUseCase.execute(
        groupId: 'group-1',
        forceRefresh: false,
      ),
    ).thenAnswer(
      (_) async => const ManageGroupInviteError('Network unavailable'),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('owner-invite-action')));
    await tester.tap(find.byKey(const Key('owner-invite-action')));
    await tester.pump();

    expect(
      find.text('Regenerate invite failed: Network unavailable'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('owner-invite-code')), findsNothing);
  });

  testWidgets('owner selects an active member and confirms transfer twice', (
    tester,
  ) async {
    final ownerGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'owner',
      groupKey: 'current-key',
      members: const [
        GroupMember(
          deviceId: 'owner-1',
          publicKey: 'pk-owner',
          deviceName: 'Owner phone',
          displayName: 'Owner',
          avatarEmoji: '🏠',
          role: 'owner',
          status: 'active',
        ),
        GroupMember(
          deviceId: 'member-1',
          publicKey: 'pk-member',
          deviceName: 'Member phone',
          displayName: 'Member',
          avatarEmoji: '🌿',
          role: 'member',
          status: 'active',
        ),
      ],
      createdAt: DateTime(2026),
    );
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => ownerGroup);

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
          ownerTransferUseCaseProvider.overrideWithValue(ownerTransferUseCase),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('transfer-owner-action')));
    await tester.tap(find.byKey(const Key('transfer-owner-action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('transfer-owner-candidate-member-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Transfer ownership?'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Final confirmation'), findsOneWidget);
    await tester.tap(find.text('Transfer ownership').last);
    await tester.pumpAndSettle();

    verify(
      () => ownerTransferUseCase.execute(
        groupId: 'group-1',
        targetDeviceId: 'member-1',
      ),
    ).called(1);
  });

  testWidgets('former owner refreshed as member can leave normally', (
    tester,
  ) async {
    final formerOwnerGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      keyEpoch: 5,
      groupKey: 'epoch-5-key',
      members: const [],
      createdAt: DateTime(2026),
    );
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => formerOwnerGroup);

    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
          removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
          manageGroupInviteUseCaseProvider.overrideWithValue(
            manageGroupInviteUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Leave Group'));
    await tester.tap(find.text('Leave Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave Group').last);
    await tester.pumpAndSettle();

    verify(() => leaveGroupUseCase.execute('group-1')).called(1);
    verifyNever(() => deactivateGroupUseCase.execute(any()));
  });
}
