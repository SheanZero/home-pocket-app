import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository groupRepository;

  setUp(() {
    groupRepository = MockGroupRepository();
  });

  testWidgets('shows waiting approval state using repository group data', (
    tester,
  ) async {
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
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'pk-member',
            deviceName: 'My iPhone',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026, 3, 3),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(groupId: 'group-1'),
        overrides: [groupRepositoryProvider.overrideWithValue(groupRepository)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for Approval...'), findsAtLeastNWidgets(1));
    expect(find.text('Group'), findsOneWidget);
    expect(find.text('group-1'), findsOneWidget);
    expect(find.text('Current Members'), findsOneWidget);
    expect(find.text('Owner phone'), findsOneWidget);
    expect(find.text('My iPhone'), findsOneWidget);
  });
}
