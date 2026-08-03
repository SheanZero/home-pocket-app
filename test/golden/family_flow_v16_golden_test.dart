@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/application/family_sync/deactivate_group_use_case.dart';
import 'package:home_pocket/application/family_sync/group_key_recovery_use_case.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/application/family_sync/join_request_lifecycle_use_cases.dart';
import 'package:home_pocket/application/family_sync/leave_group_use_case.dart';
import 'package:home_pocket/application/family_sync/manage_group_invite_use_case.dart';
import 'package:home_pocket/application/family_sync/notify_member_approval_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/repository_providers.dart'
    show notifyMemberApprovalUseCaseProvider;
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/confirm_join_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/create_group_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_choice_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/join_group_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/waiting_approval_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/presentation/providers/state_user_profile.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class _MockNotifyMemberApprovalUseCase extends Mock
    implements NotifyMemberApprovalUseCase {}

class _MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class _MockRejectJoinRequestUseCase extends Mock
    implements RejectJoinRequestUseCase {}

class _MockLeaveGroupUseCase extends Mock implements LeaveGroupUseCase {}

class _MockDeactivateGroupUseCase extends Mock
    implements DeactivateGroupUseCase {}

class _MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class _MockManageGroupInviteUseCase extends Mock
    implements ManageGroupInviteUseCase {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockCompleteMemberActivationUseCase extends Mock
    implements CompleteMemberActivationUseCase {}

class _MockGetJoinRequestStatusUseCase extends Mock
    implements GetJoinRequestStatusUseCase {}

class _MockCancelJoinRequestUseCase extends Mock
    implements CancelJoinRequestUseCase {}

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _MockGroupKeyRecoveryCoordinator extends Mock
    implements GroupKeyRecoveryCoordinator {}

final _profile = UserProfile(
  id: 'family-golden-profile',
  displayName: 'あおい',
  avatarEmoji: '🌿',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _zhProfile = UserProfile(
  id: 'family-invite-ticket-golden-profile',
  displayName: 'shean',
  avatarEmoji: '🌿',
  createdAt: DateTime(2026, 8, 3),
  updatedAt: DateTime(2026, 8, 3),
);

Widget _wrap(
  Widget home, {
  List<Override> overrides = const [],
  Locale locale = const Locale('ja'),
  UserProfile? profile,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((_) async => profile ?? _profile),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: home,
    ),
  );
}

Future<void> _setPhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 810);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _setReferenceViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _setIPhoneSafeAreaViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
}

Future<void> _matchScreen(WidgetTester tester, String goldenName) async {
  await expectLater(
    find.byType(Scaffold).first,
    matchesGoldenFile('goldens/$goldenName'),
  );
}

Future<void> _precacheEntryImages(WidgetTester tester) async {
  final context = tester.element(find.byType(GroupChoiceScreen));
  await tester.runAsync(() async {
    await Future.wait([
      precacheImage(
        const AssetImage(
          'docs/mockup/v16/assets/family-entry-create-warm-v1.png',
        ),
        context,
      ),
      precacheImage(
        const AssetImage(
          'docs/mockup/v16/assets/family-entry-join-warm-v1.png',
        ),
        context,
      ),
    ]);
  });
  await tester.pumpAndSettle();
}

Future<void> _finishFileImageDecoding(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

GroupInfo _managementGroup() => GroupInfo(
  groupId: 'family-golden-group',
  groupName: '青木家の家計',
  status: GroupStatus.active,
  inviteCode: '482169',
  inviteExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
  role: 'owner',
  groupKey: 'golden-key',
  members: [
    GroupMember(
      deviceId: 'owner',
      publicKey: 'owner-key',
      deviceName: 'あおいのiPhone',
      displayName: 'あおい',
      avatarEmoji: '🌿',
      avatarImagePath:
          '${Directory.current.path}/docs/mockup/v16/assets/family-avatar-owner.png',
      role: 'owner',
      status: 'active',
    ),
    GroupMember(
      deviceId: 'member-hanako',
      publicKey: 'hanako-key',
      deviceName: '花子のiPad',
      displayName: '花子',
      avatarEmoji: '🌸',
      avatarImagePath:
          '${Directory.current.path}/docs/mockup/v16/assets/family-avatar-hanako.png',
      role: 'member',
      status: 'active',
    ),
    GroupMember(
      deviceId: 'member-taro',
      publicKey: 'taro-key',
      deviceName: '太郎のiPhone',
      displayName: '太郎',
      avatarEmoji: '🌱',
      avatarImagePath:
          '${Directory.current.path}/docs/mockup/v16/assets/family-avatar-taro.png',
      role: 'member',
      status: 'active',
    ),
    GroupMember(
      deviceId: 'pending-hanako',
      publicKey: 'pending-key',
      deviceName: '花子のiPad',
      displayName: '花子',
      avatarEmoji: '🌸',
      avatarImagePath:
          '${Directory.current.path}/docs/mockup/v16/assets/family-avatar-hanako.png',
      role: 'member',
      status: 'pending',
    ),
  ],
  createdAt: DateTime(2026, 3, 1),
);

void main() {
  setUpAll(() async {
    final cjkBytes = await File(
      '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    ).readAsBytes();
    final cjkLoader = FontLoader('RobotoMonoNumerals')
      ..addFont(Future.value(ByteData.sublistView(cjkBytes)));
    final lucideLoader = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    await Future.wait([cjkLoader.load(), lucideLoader.load()]);
  });

  testWidgets('family entry — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(_wrap(const GroupChoiceScreen()));
    await tester.pumpAndSettle();
    await _precacheEntryImages(tester);
    await _matchScreen(tester, 'family_entry_v16_light_ja.png');
  });

  testWidgets('create family invite — light ja', (tester) async {
    await _setPhoneViewport(tester);
    final now = DateTime(2026, 8, 3, 12);
    final create = _MockCreateGroupUseCase();
    final notify = _MockNotifyMemberApprovalUseCase();
    when(
      () => create.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => CreateGroupResult.success(
        groupId: 'family-golden-group',
        groupName: '青木家の家計',
        inviteCode: '482169',
        expiresAt:
            now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000,
      ),
    );
    when(
      () => notify.listenForJoinRequests(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => notify.connectWebSocket(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {});
    when(() => notify.disconnectWebSocket()).thenReturn(null);

    await tester.pumpWidget(
      _wrap(
        CreateGroupScreen(now: () => now),
        overrides: [
          createGroupUseCaseProvider.overrideWithValue(create),
          notifyMemberApprovalUseCaseProvider.overrideWithValue(notify),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-group-submit')));
    await tester.pumpAndSettle();
    await _matchScreen(tester, 'family_create_invite_v16_light_ja.png');
  });

  testWidgets('create family invite ticket — light zh', (tester) async {
    await _setReferenceViewport(tester);
    final now = DateTime(2026, 8, 3, 11, 50, 16);
    final create = _MockCreateGroupUseCase();
    final notify = _MockNotifyMemberApprovalUseCase();
    when(
      () => create.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => CreateGroupResult.success(
        groupId: 'family-invite-ticket-golden-group',
        groupName: 'shean的家',
        inviteCode: '256931',
        expiresAt:
            now
                .add(const Duration(minutes: 9, seconds: 44))
                .millisecondsSinceEpoch ~/
            1000,
      ),
    );
    when(
      () => notify.listenForJoinRequests(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => notify.connectWebSocket(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {});
    when(() => notify.disconnectWebSocket()).thenReturn(null);

    await tester.pumpWidget(
      _wrap(
        CreateGroupScreen(now: () => now),
        locale: const Locale('zh'),
        profile: _zhProfile,
        overrides: [
          createGroupUseCaseProvider.overrideWithValue(create),
          notifyMemberApprovalUseCaseProvider.overrideWithValue(notify),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-group-submit')));
    await tester.pumpAndSettle();
    await _matchScreen(tester, 'family_create_invite_ticket_light_zh.png');
  });

  testWidgets('join family code — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(_wrap(const JoinGroupScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '482169');
    await tester.pump();
    await _matchScreen(tester, 'family_join_code_v16_light_ja.png');
  });

  testWidgets('join family confirmation — light ja', (tester) async {
    await _setPhoneViewport(tester);
    await tester.pumpWidget(
      _wrap(
        const ConfirmJoinScreen(
          result: JoinGroupVerified(
            groupId: 'family-golden-group',
            groupName: '青木家の家計',
            ownerDeviceId: 'owner',
            ownerDisplayName: 'あおい',
            ownerAvatarEmoji: '🌿',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _matchScreen(tester, 'family_join_confirm_v16_light_ja.png');
  });

  testWidgets('member approval — light ja', (tester) async {
    await _setPhoneViewport(tester);
    final repository = _MockGroupRepository();
    final confirm = _MockConfirmMemberUseCase();
    final reject = _MockRejectJoinRequestUseCase();
    final notify = _MockNotifyMemberApprovalUseCase();
    final group = _managementGroup();
    when(
      () => repository.getGroupById(group.groupId),
    ).thenAnswer((_) async => group);
    when(
      () => notify.listenForJoinRequests(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => notify.connectWebSocket(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {});
    when(() => notify.disconnectWebSocket()).thenReturn(null);

    await tester.pumpWidget(
      _wrap(
        MemberApprovalScreen(groupId: group.groupId),
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          confirmMemberUseCaseProvider.overrideWithValue(confirm),
          rejectJoinRequestUseCaseProvider.overrideWithValue(reject),
          notifyMemberApprovalUseCaseProvider.overrideWithValue(notify),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _finishFileImageDecoding(tester);
    await _matchScreen(tester, 'family_member_approval_v16_light_ja.png');
  });

  testWidgets('waiting for approval — light ja', (tester) async {
    await _setPhoneViewport(tester);
    final repository = _MockGroupRepository();
    final activation = _MockCompleteMemberActivationUseCase();
    final syncEngine = _MockSyncEngine();
    final status = _MockGetJoinRequestStatusUseCase();
    final cancel = _MockCancelJoinRequestUseCase();
    final push = _MockPushNotificationService();
    final recovery = _MockGroupKeyRecoveryCoordinator();
    when(() => syncEngine.statusStream).thenAnswer((_) => const Stream.empty());
    when(
      () => push.joinRequestLifecycleEvents,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => recovery.currentStatus,
    ).thenReturn(const GroupKeyRecoveryStatus());
    when(() => recovery.statusStream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      _wrap(
        const WaitingApprovalScreen(
          groupId: 'family-golden-group',
          groupName: '青木家の家計',
          ownerDisplayName: 'あおい',
        ),
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          completeMemberActivationUseCaseProvider.overrideWithValue(activation),
          syncEngineProvider.overrideWithValue(syncEngine),
          getJoinRequestStatusUseCaseProvider.overrideWithValue(status),
          cancelJoinRequestUseCaseProvider.overrideWithValue(cancel),
          pushNotificationServiceProvider.overrideWithValue(push),
          groupKeyRecoveryCoordinatorProvider.overrideWithValue(recovery),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _matchScreen(tester, 'family_waiting_approval_v16_light_ja.png');
  });

  testWidgets('waiting for approval — dark zh safe area', (tester) async {
    await _setIPhoneSafeAreaViewport(tester);
    final repository = _MockGroupRepository();
    final activation = _MockCompleteMemberActivationUseCase();
    final syncEngine = _MockSyncEngine();
    final status = _MockGetJoinRequestStatusUseCase();
    final cancel = _MockCancelJoinRequestUseCase();
    final push = _MockPushNotificationService();
    final recovery = _MockGroupKeyRecoveryCoordinator();
    when(() => syncEngine.statusStream).thenAnswer((_) => const Stream.empty());
    when(
      () => push.joinRequestLifecycleEvents,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => recovery.currentStatus,
    ).thenReturn(const GroupKeyRecoveryStatus());
    when(() => recovery.statusStream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      _wrap(
        const WaitingApprovalScreen(
          groupId: 'family-golden-group',
          groupName: 'Shean的家庭',
          ownerDisplayName: 'Shean',
        ),
        locale: const Locale('zh'),
        profile: _zhProfile,
        themeMode: ThemeMode.dark,
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          completeMemberActivationUseCaseProvider.overrideWithValue(activation),
          syncEngineProvider.overrideWithValue(syncEngine),
          getJoinRequestStatusUseCaseProvider.overrideWithValue(status),
          cancelJoinRequestUseCaseProvider.overrideWithValue(cancel),
          pushNotificationServiceProvider.overrideWithValue(push),
          groupKeyRecoveryCoordinatorProvider.overrideWithValue(recovery),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _matchScreen(tester, 'family_waiting_approval_safe_area_dark_zh.png');
  });

  testWidgets('family management — light ja', (tester) async {
    await _setPhoneViewport(tester);
    final repository = _MockGroupRepository();
    final leave = _MockLeaveGroupUseCase();
    final deactivate = _MockDeactivateGroupUseCase();
    final remove = _MockRemoveMemberUseCase();
    final invite = _MockManageGroupInviteUseCase();
    final syncEngine = _MockSyncEngine();
    final group = _managementGroup();
    when(() => repository.getActiveGroup()).thenAnswer((_) async => group);
    when(
      () => repository.watchActiveGroup(),
    ).thenAnswer((_) => Stream.value(group));
    when(
      () => syncEngine.currentStatus,
    ).thenReturn(const SyncStatus(state: SyncState.synced));
    when(() => syncEngine.statusStream).thenAnswer(
      (_) => Stream.value(const SyncStatus(state: SyncState.synced)),
    );

    await tester.pumpWidget(
      _wrap(
        const GroupManagementScreen(),
        overrides: [
          groupRepositoryProvider.overrideWithValue(repository),
          leaveGroupUseCaseProvider.overrideWithValue(leave),
          deactivateGroupUseCaseProvider.overrideWithValue(deactivate),
          removeMemberUseCaseProvider.overrideWithValue(remove),
          manageGroupInviteUseCaseProvider.overrideWithValue(invite),
          syncEngineProvider.overrideWithValue(syncEngine),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _finishFileImageDecoding(tester);
    await _matchScreen(tester, 'family_management_v16_light_ja.png');
  });
}
