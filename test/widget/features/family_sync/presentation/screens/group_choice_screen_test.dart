import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/create_group_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_choice_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/join_group_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_flow_components.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockUserProfileRepository profileRepository;

  setUp(() {
    profileRepository = _MockUserProfileRepository();
    when(() => profileRepository.find()).thenAnswer(
      (_) async => UserProfile(
        id: 'profile-1',
        displayName: 'Aoi',
        avatarEmoji: 'A',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const GroupChoiceScreen(),
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the two task-oriented family paths without shared steps', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('How would you like to start?'), findsOneWidget);
    expect(find.text('Create a new family'), findsOneWidget);
    expect(find.text('Join with an invite code'), findsOneWidget);
    expect(find.byType(FamilyFlowProgress), findsNothing);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('create path opens the create-family flow', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('family-choice-create')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(find.text('Create family'), findsOneWidget);
  });

  testWidgets('entry, create, and join layouts remain stable on phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(320, 640), Size(430, 932)]) {
      tester.view.physicalSize = size;
      await pumpScreen(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('family-choice-create')));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGroupScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('family-choice-join')));
      await tester.pumpAndSettle();
      expect(find.byType(JoinGroupScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('invite path opens the join-family flow', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('family-choice-join')));
    await tester.pumpAndSettle();

    expect(find.byType(JoinGroupScreen), findsOneWidget);
    expect(find.text('Join family'), findsOneWidget);
  });
}
