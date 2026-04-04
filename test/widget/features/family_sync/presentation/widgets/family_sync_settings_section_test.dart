import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_choice_screen.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_sync_settings_section.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/sync_trigger_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}

class MockSyncTriggerService extends Mock implements SyncTriggerService {}

class MockPushNotificationService extends Mock
    implements PushNotificationService {}

class TestSyncStatusNotifier extends SyncStatusNotifier {
  TestSyncStatusNotifier(this.initialState);

  final SyncStatus initialState;

  @override
  SyncStatus build() => initialState;
}

void main() {
  late MockGroupRepository groupRepository;
  late MockCheckGroupUseCase checkGroupUseCase;
  late MockCreateGroupUseCase createGroupUseCase;
  late MockJoinGroupUseCase joinGroupUseCase;
  late MockSyncTriggerService syncTriggerService;
  late MockPushNotificationService pushNotificationService;

  GroupInfo buildActiveGroup() => GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'owner',
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
    ],
    createdAt: DateTime(2026, 3, 1),
  );

  setUp(() {
    groupRepository = MockGroupRepository();
    checkGroupUseCase = MockCheckGroupUseCase();
    createGroupUseCase = MockCreateGroupUseCase();
    joinGroupUseCase = MockJoinGroupUseCase();
    syncTriggerService = MockSyncTriggerService();
    pushNotificationService = MockPushNotificationService();
    when(
      () => groupRepository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(buildActiveGroup()));
    when(() => groupRepository.getGroupById(any())).thenAnswer((
      invocation,
    ) async {
      final groupId = invocation.positionalArguments.first as String;
      return buildActiveGroup().copyWith(groupId: groupId);
    });
    when(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => CreateGroupSuccess(
        groupId: 'group-1',
        inviteCode: '654321',
        expiresAt: DateTime(2026, 3, 14, 12).millisecondsSinceEpoch ~/ 1000,
      ),
    );
    when(
      () => joinGroupUseCase.execute(
        inviteCode: any(named: 'inviteCode'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer((_) async => const JoinGroupError('Invalid invite code'));
    when(() => syncTriggerService.initialize()).thenAnswer((_) async {});
    when(
      () => syncTriggerService.events,
    ).thenAnswer((_) => const Stream<SyncTriggerEvent>.empty());
  });

  testWidgets('navigates to GroupManagementScreen when already paired', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const Scaffold(body: FamilySyncSettingsSection()),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
          createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
          joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
          syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
          pushNotificationServiceProvider.overrideWithValue(
            pushNotificationService,
          ),
          syncStatusNotifierProvider.overrideWith(
            () => TestSyncStatusNotifier(SyncStatus.synced),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.byType(GroupManagementScreen), findsOneWidget);
    verifyNever(() => checkGroupUseCase.execute());
  });

  testWidgets(
    'navigates to local group management when active group exists even if sync status is unpaired',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(body: FamilySyncSettingsSection()),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
            joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
            syncStatusNotifierProvider.overrideWith(
              () => TestSyncStatusNotifier(SyncStatus.unpaired),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(GroupManagementScreen), findsOneWidget);
      verifyNever(() => checkGroupUseCase.execute());
    },
  );

  testWidgets(
    'checks server before showing pairing when unpaired and no local group exists',
    (tester) async {
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-123'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(body: FamilySyncSettingsSection()),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
            joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
            syncStatusNotifierProvider.overrideWith(
              () => TestSyncStatusNotifier(SyncStatus.unpaired),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GroupManagementScreen), findsOneWidget);
      verify(() => checkGroupUseCase.execute()).called(1);
    },
  );

  testWidgets(
    'shows pairing screen when server check reports device is not in a group',
    (tester) async {
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupNotInGroup());

      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(body: FamilySyncSettingsSection()),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
            joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
            syncStatusNotifierProvider.overrideWith(
              () => TestSyncStatusNotifier(SyncStatus.unpaired),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GroupChoiceScreen), findsOneWidget);
      verify(() => checkGroupUseCase.execute()).called(1);
    },
  );

  testWidgets(
    'shows error snackbar and falls back to pairing when server check fails',
    (tester) async {
      when(
        () => groupRepository.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => checkGroupUseCase.execute(),
      ).thenAnswer((_) async => const CheckGroupError('Network error'));

      await tester.pumpWidget(
        createLocalizedWidget(
          const Scaffold(body: FamilySyncSettingsSection()),
          overrides: [
            groupRepositoryProvider.overrideWithValue(groupRepository),
            checkGroupUseCaseProvider.overrideWithValue(checkGroupUseCase),
            createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
            joinGroupUseCaseProvider.overrideWithValue(joinGroupUseCase),
            syncTriggerServiceProvider.overrideWithValue(syncTriggerService),
            pushNotificationServiceProvider.overrideWithValue(
              pushNotificationService,
            ),
            syncStatusNotifierProvider.overrideWith(
              () => TestSyncStatusNotifier(SyncStatus.unpaired),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GroupChoiceScreen), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      verify(() => checkGroupUseCase.execute()).called(1);
    },
  );
}
