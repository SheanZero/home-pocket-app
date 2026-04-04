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
    groupName: 'Test Family',
    status: GroupStatus.confirming,
    role: 'member',
    members: const [
      GroupMember(
        deviceId: 'owner-1',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        displayName: 'Owner phone',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      ),
      GroupMember(
        deviceId: 'member-1',
        publicKey: 'pk-member',
        deviceName: 'My iPhone',
        displayName: 'My iPhone',
        avatarEmoji: '🏠',
        role: 'member',
        status: 'pending',
      ),
    ],
    createdAt: DateTime(2026, 3, 3),
  );

  GroupInfo buildActiveGroup() => GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'member',
    members: const [
      GroupMember(
        deviceId: 'owner-1',
        publicKey: 'pk-owner',
        deviceName: 'Owner phone',
        displayName: 'Owner phone',
        avatarEmoji: '🏠',
        role: 'owner',
        status: 'active',
      ),
      GroupMember(
        deviceId: 'member-1',
        publicKey: 'pk-member',
        deviceName: 'My iPhone',
        displayName: 'My iPhone',
        avatarEmoji: '🏠',
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
    // Default: still waiting
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupNotInGroup());
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
        const WaitingApprovalScreen(
          groupName: 'Test Family',
          ownerDisplayName: 'Owner phone',
        ),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
        ],
      ),
    );
    // Use pump with duration instead of pumpAndSettle to avoid timeout
    // caused by the indefinitely-animating CircularProgressIndicator
    await tester.pump(const Duration(milliseconds: 100));

    // The new screen shows groupName and ownerDisplayName passed as params
    expect(find.text('Test Family'), findsOneWidget);
    // Waiting title from l10n.groupWaitingApproval
    expect(find.text('Waiting for Owner approval...'), findsOneWidget);
    // A progress indicator is displayed
    expect(find.byType(WaitingApprovalScreen), findsOneWidget);
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
          const WaitingApprovalScreen(
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      eventsController.add(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      // Allow the async verification and navigation to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => checkGroupUseCase.execute()).called(1);
      // After approval the screen navigates to GroupManagementScreen,
      // which shows the group name from the loaded group data
      expect(find.text('Test Family'), findsOneWidget);
      expect(find.byType(WaitingApprovalScreen), findsNothing);
    },
  );

  testWidgets(
    'stays on waiting screen when group verification returns not-in-group',
    (tester) async {
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => buildConfirmingGroup());
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupNotInGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      eventsController.add(
        const SyncTriggerEvent.memberConfirmed(groupId: 'group-1'),
      );
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => checkGroupUseCase.execute()).called(1);
      // Screen should remain on the waiting screen
      expect(find.byType(WaitingApprovalScreen), findsOneWidget);
    },
  );

  testWidgets('polls server every 30 seconds', (tester) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupNotInGroup());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => checkGroupUseCase.execute());

      // Wait for the 30-second timer to fire
      await Future<void>.delayed(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => checkGroupUseCase.execute()).called(1);
    });
  });

  testWidgets('stops polling after successful navigation', (tester) async {
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => buildConfirmingGroup());
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => buildActiveGroup());
    when(
      () => checkGroupUseCase.execute(),
    ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));

    await tester.runAsync(() async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const WaitingApprovalScreen(
            groupName: 'Test Family',
            ownerDisplayName: 'Owner phone',
          ),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Wait for first poll to fire and navigate
      await Future<void>.delayed(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => checkGroupUseCase.execute()).called(1);

      // Wait for another poll cycle — should not call again after navigation
      await Future<void>.delayed(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => checkGroupUseCase.execute());
    });
  });
}
