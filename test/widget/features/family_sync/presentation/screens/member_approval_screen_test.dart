import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/confirm_member_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockSyncTriggerService syncTriggerService;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    syncTriggerService = MockSyncTriggerService();
    when(() => syncTriggerService.events).thenAnswer(
      (_) => const Stream<SyncTriggerEvent>.empty(),
    );

    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.active,
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
      ),
    );

    when(
      () => confirmMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
        bookId: any(named: 'bookId'),
      ),
    ).thenAnswer((_) async => const ConfirmMemberSuccess());
  });

  testWidgets('shows pending request and approves a member', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Member Approval'), findsOneWidget);
    expect(find.text('Kitchen tablet'), findsAtLeastNWidgets(1));
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Current Members'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    verify(
      () => confirmMemberUseCase.execute(
        groupId: 'group-1',
        deviceId: 'member-1',
        bookId: 'book-1',
      ),
    ).called(1);
  });

  testWidgets('uses explicit groupId to load the target group', (tester) async {
    when(() => groupRepository.getGroupById('group-42')).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-42',
        bookId: 'book-42',
        status: GroupStatus.active,
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
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(groupId: 'group-42'),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
        ],
      ),
    );
    await tester.pumpAndSettle();

    verify(() => groupRepository.getGroupById('group-42')).called(1);
    verifyNever(() => groupRepository.getActiveGroup());
    expect(find.text('Owner phone'), findsOneWidget);
  });
}
