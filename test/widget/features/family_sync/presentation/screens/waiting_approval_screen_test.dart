import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockSyncTriggerService syncTriggerService;
  late MockCheckGroupUseCase checkGroupUseCase;
  late StreamController<SyncTriggerEvent> eventsController;

  GroupInfo buildConfirmingGroup() => GroupInfo(
    groupId: 'group-1',

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
    checkGroupUseCase = MockCheckGroupUseCase();
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
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
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
    'verifies group state before navigating when memberConfirmed event is received',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => groupRepository.getActiveGroup(),
      ).thenAnswer((_) async => buildActiveGroup());
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(groupId: 'group-1'),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      eventsController.add(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await tester.pumpAndSettle();

      verify(() => checkGroupUseCase.execute()).called(1);
      expect(find.text('Group Management'), findsOneWidget);
    },
  );

  testWidgets(
    'stays on waiting screen and shows snackbar when group verification fails',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupError('Network error'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(groupId: 'group-1'),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      eventsController.add(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => checkGroupUseCase.execute()).called(1);
      expect(find.byType(WaitingApprovalScreen), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    },
  );
}
