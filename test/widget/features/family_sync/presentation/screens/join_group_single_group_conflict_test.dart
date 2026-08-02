import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/join_group_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  testWidgets('single-group conflict uses localized guidance', (tester) async {
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
        'server detail',
        kind: GroupOperationErrorKind.membershipConflict,
      ),
    );

    final overrides = <Override>[
      joinGroupUseCaseProvider.overrideWithValue(joinUseCase),
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

    expect(find.textContaining('already has a family group'), findsOneWidget);
    expect(find.textContaining('server detail'), findsNothing);
  });
}
