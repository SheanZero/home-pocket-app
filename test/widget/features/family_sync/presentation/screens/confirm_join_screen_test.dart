import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/confirm_join_screen.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets('explains that confirming replaces the current empty family', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const ConfirmJoinScreen(
          result: JoinGroupVerified(
            groupId: 'target-group',
            groupName: 'Target Family',
            ownerDeviceId: 'target-owner',
            ownerDisplayName: 'Owner',
            ownerAvatarEmoji: '🏠',
            replacesEmptyOwnedGroup: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'After you submit the join request, your current family with no '
        'other members will be deleted automatically.',
      ),
      findsOneWidget,
    );
  });
}
