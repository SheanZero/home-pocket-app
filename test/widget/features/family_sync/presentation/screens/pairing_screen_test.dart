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

  testWidgets('shows redesigned create and join group tabs', (tester) async {
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
}
