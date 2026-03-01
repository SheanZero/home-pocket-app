import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/pair_management_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/deactivate_group_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/leave_group_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockLeaveGroupUseCase extends Mock implements LeaveGroupUseCase {}

class MockDeactivateGroupUseCase extends Mock
    implements DeactivateGroupUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockLeaveGroupUseCase leaveGroupUseCase;
  late MockDeactivateGroupUseCase deactivateGroupUseCase;

  setUp(() {
    groupRepository = MockGroupRepository();
    leaveGroupUseCase = MockLeaveGroupUseCase();
    deactivateGroupUseCase = MockDeactivateGroupUseCase();

    when(
      () => leaveGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const LeaveGroupSuccess());
    when(
      () => deactivateGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const DeactivateGroupSuccess());
  });

  testWidgets('shows owner actions and all group members', (tester) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.active,
        inviteCode: 'INV123',
        role: 'owner',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'pk-member',
            deviceName: 'Kitchen tablet',
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
        const PairManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Deactivate Group'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Owner phone'), findsOneWidget);
    expect(find.text('Kitchen tablet'), findsOneWidget);
    expect(find.text('Deactivate Group'), findsOneWidget);
    expect(find.text('Regenerate Invite'), findsOneWidget);
  });

  testWidgets('shows leave action for non-owner members', (tester) async {
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.active,
        role: 'member',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const PairManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          leaveGroupUseCaseProvider.overrideWithValue(leaveGroupUseCase),
          deactivateGroupUseCaseProvider.overrideWithValue(
            deactivateGroupUseCase,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Leave Group'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Leave Group'), findsOneWidget);
    expect(find.text('Deactivate Group'), findsNothing);
  });
}
