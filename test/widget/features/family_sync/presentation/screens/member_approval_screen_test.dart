import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockSyncTriggerService syncTriggerService;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    syncTriggerService = MockSyncTriggerService();
    when(
      () => syncTriggerService.events,
    ).thenAnswer((_) => const Stream<SyncTriggerEvent>.empty());

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
    syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
  ];

  testWidgets('shows both approve and reject buttons', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member Approval'), findsOneWidget);
    expect(find.text('Kitchen tablet'), findsAtLeastNWidgets(1));
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Current Members'), findsOneWidget);
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
      () => removeMemberUseCase.execute(
        groupId: 'group-1',
        deviceId: 'member-1',
      ),
    ).called(1);
  });

  testWidgets('shows error snackbar when reject fails', (tester) async {
    when(
      () => removeMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer(
      (_) async => const RemoveMemberResult.error('Server error'),
    );

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

    // During approving, reject button should be disabled
    final rejectButton = tester.widget<OutlinedButton>(
      find.byType(OutlinedButton),
    );
    expect(rejectButton.onPressed, isNull);

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
    expect(find.text('Owner phone'), findsOneWidget);
  });
}
