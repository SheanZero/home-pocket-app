import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/pairing_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/gradient_action_button.dart';
import 'package:home_pocket/features/family_sync/use_cases/create_group_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/join_group_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockCreateGroupUseCase createGroupUseCase;
  late MockJoinGroupUseCase joinGroupUseCase;
  late MockGroupRepository groupRepository;

  setUp(() {
    createGroupUseCase = MockCreateGroupUseCase();
    joinGroupUseCase = MockJoinGroupUseCase();
    groupRepository = MockGroupRepository();

    when(() => createGroupUseCase.execute(any())).thenAnswer(
      (_) async => CreateGroupSuccess(
        groupId: 'group-1',
        inviteCode: '654321',
        expiresAt:
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      ),
    );
    when(
      () => joinGroupUseCase.execute(any()),
    ).thenAnswer((_) async => const JoinGroupError('Invalid invite code'));
    when(() => groupRepository.getGroupById('group-1')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.confirming,
        role: 'member',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026, 3, 3),
      ),
    );
  });

  testWidgets('shows redesigned create and join group tabs', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const PairingScreen(bookId: 'book-1'),
        overrides: [
          createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
          joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
          groupRepositoryProvider.overrideWithValue(groupRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
    expect(find.text('Invite Code'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    await tester.tap(find.text('Join Group'));
    await tester.pumpAndSettle();

    expect(find.text('Join Family'), findsOneWidget);
    expect(find.text('Join Group'), findsAtLeastNWidgets(1));
    expect(find.text('Scan QR Code'), findsOneWidget);
  });

  testWidgets('navigates to waiting approval screen after join success', (
    tester,
  ) async {
    when(() => joinGroupUseCase.execute(any())).thenAnswer(
      (_) async => const JoinGroupSuccess(
        groupId: 'group-1',
        members: [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const PairingScreen(bookId: 'book-1'),
        overrides: [
          createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
          joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
          groupRepositoryProvider.overrideWithValue(groupRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join Group').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GradientActionButton));
    await tester.pumpAndSettle();

    verify(() => joinGroupUseCase.execute('123456')).called(1);
    expect(find.text('Waiting for Approval...'), findsAtLeastNWidgets(1));
    expect(find.text('Owner phone'), findsOneWidget);
  });
}
