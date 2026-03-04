import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

void main() {
  late MockGroupRepository groupRepository;
  late MockSyncTriggerService syncTriggerService;
  late StreamController<SyncTriggerEvent> eventsController;

  GroupInfo buildConfirmingGroup() => GroupInfo(
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
  );

  GroupInfo buildActiveGroup() => GroupInfo(
    groupId: 'group-1',
    bookId: 'book-1',
    status: GroupStatus.active,
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
        status: 'active',
      ),
    ],
    createdAt: DateTime(2026, 3, 3),
  );

  setUp(() {
    groupRepository = MockGroupRepository();
    syncTriggerService = MockSyncTriggerService();
    eventsController = StreamController<SyncTriggerEvent>.broadcast();
    when(
      () => syncTriggerService.events,
    ).thenAnswer((_) => eventsController.stream);
    when(() => syncTriggerService.dispose()).thenReturn(null);
  });

  tearDown(() async {
    await eventsController.close();
  });

  testWidgets('shows waiting approval state using repository group data', (
    tester,
  ) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => buildActiveGroup());

    await tester.pumpWidget(
      createLocalizedWidget(
        const WaitingApprovalScreen(groupId: 'group-1'),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
        ],
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

  testWidgets(
    'auto-navigates to group management when memberConfirmed event is received',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(groupId: 'group-1'),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      eventsController.add(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Group Management'), findsOneWidget);
    },
  );
}
