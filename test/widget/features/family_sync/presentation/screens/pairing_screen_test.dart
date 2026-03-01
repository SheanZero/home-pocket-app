import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/pairing_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/create_group_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/join_group_use_case.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}

void main() {
  late MockCreateGroupUseCase createGroupUseCase;
  late MockJoinGroupUseCase joinGroupUseCase;

  setUp(() {
    createGroupUseCase = MockCreateGroupUseCase();
    joinGroupUseCase = MockJoinGroupUseCase();

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
  });

  testWidgets('shows group-oriented tabs and invite code copy', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const PairingScreen(bookId: 'book-1'),
        overrides: [
          createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
          joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
    expect(find.text('Invite Code'), findsOneWidget);
    expect(find.text('654 321'), findsOneWidget);
  });
}
