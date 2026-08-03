import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:home_pocket/application/family_sync/check_group_use_case.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/join_group_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}

class _MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  testWidgets('single-group conflict resolves authoritative server group', (
    tester,
  ) async {
    final joinUseCase = _MockJoinGroupUseCase();
    final checkGroupUseCase = _MockCheckGroupUseCase();
    final groupRepository = _MockGroupRepository();
    final profileRepository = _MockUserProfileRepository();
    when(() => profileRepository.find()).thenAnswer(
      (_) async => UserProfile(
        id: 'profile-1',
        displayName: 'Mama',
        avatarEmoji: '\u{1F469}',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    when(
      () => joinUseCase.execute(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => const JoinGroupResult.error(
        'server detail',
        kind: GroupOperationErrorKind.membershipConflict,
      ),
    );
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));
    final group = GroupInfo(
      groupId: 'group-1',
      groupName: 'Server Family',
      status: GroupStatus.active,
      role: 'owner',
      members: const [
        GroupMember(
          deviceId: 'device-1',
          publicKey: 'public-key',
          deviceName: 'My Phone',
          role: 'owner',
          status: 'active',
          displayName: 'Mama',
          avatarEmoji: '🏠',
        ),
      ],
      createdAt: DateTime(2026),
    );
    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(group));
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => group);

    final overrides = <Override>[
      joinGroupUseCaseProvider.overrideWithValue(joinUseCase),
      checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      userProfileRepositoryProvider.overrideWithValue(profileRepository),
    ];
    await tester.pumpWidget(
      createLocalizedWidget(const JoinGroupScreen(), overrides: overrides),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.tap(find.text('Review family details'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupManagementScreen), findsOneWidget);
    expect(find.textContaining('already has a family group'), findsNothing);
    expect(find.textContaining('server detail'), findsNothing);
    verify(() => checkGroupUseCase.execute()).called(1);
  });

  testWidgets('network failure shows the shared retry dialog', (tester) async {
    final joinUseCase = _MockJoinGroupUseCase();
    final profileRepository = _MockUserProfileRepository();
    when(() => profileRepository.find()).thenAnswer(
      (_) async => UserProfile(
        id: 'profile-1',
        displayName: 'Mama',
        avatarEmoji: '\u{1F469}',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    when(
      () => joinUseCase.execute(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => const JoinGroupResult.error(
        'ClientException: Failed host lookup: sync.happypocket.app',
        kind: GroupOperationErrorKind.networkUnavailable,
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const JoinGroupScreen(),
        overrides: <Override>[
          joinGroupUseCaseProvider.overrideWithValue(joinUseCase),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.ensureVisible(find.text('Review family details'));
    await tester.tap(find.text('Review family details'));
    await tester.pumpAndSettle();

    verify(
      () => joinUseCase.execute(
        inviteCode: '123456',
        displayName: 'Mama',
        avatarEmoji: '\u{1F469}',
        avatarImageHash: null,
      ),
    ).called(1);

    expect(
      find.byKey(const Key('family-network-unavailable-dialog')),
      findsOneWidget,
    );
    expect(find.textContaining('ClientException'), findsNothing);
    expect(find.textContaining('Failed host lookup'), findsNothing);
  });
}
