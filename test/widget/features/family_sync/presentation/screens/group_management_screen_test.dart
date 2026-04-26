import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/application/family_sync/deactivate_group_use_case.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockLeaveGroupUseCase extends Mock implements LeaveGroupUseCase {}

class MockDeactivateGroupUseCase extends Mock
    implements DeactivateGroupUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockLeaveGroupUseCase leaveGroupUseCase;
  late MockDeactivateGroupUseCase deactivateGroupUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;

  setUp(() {
    groupRepository = MockGroupRepository();
    leaveGroupUseCase = MockLeaveGroupUseCase();
    deactivateGroupUseCase = MockDeactivateGroupUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();

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
  });

  testWidgets('shows owner actions and all group members', (tester) async {
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
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Group name is displayed
    expect(find.text('Test Family'), findsOneWidget);
    // Active member (owner) is displayed
    expect(find.text('Owner phone', skipOffstage: false), findsOneWidget);
    // Pending member approval alert is shown (uses familySyncApprovalTitle key)
    expect(find.text('Member Approval', skipOffstage: false), findsOneWidget);
    // Invite new member button is present for owner
    expect(find.text('Invite new member', skipOffstage: false), findsOneWidget);
    // Disband Group action is visible for owner
    expect(find.text('Disband Group', skipOffstage: false), findsOneWidget);
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
        ],
      ),
    );
    await tester.pumpAndSettle();

    verify(() => groupRepository.getGroupById('group-42')).called(1);
    verifyNever(() => groupRepository.getActiveGroup());
    expect(find.text('Owner phone', skipOffstage: false), findsOneWidget);
  });
}
