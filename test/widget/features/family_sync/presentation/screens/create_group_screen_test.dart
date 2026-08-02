import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/application/family_sync/group_operation_error.dart';
import 'package:home_pocket/application/family_sync/notify_member_approval_use_case.dart';
import 'package:home_pocket/application/family_sync/repository_providers.dart'
    show notifyMemberApprovalUseCaseProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/create_group_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart'
    show userProfileRepositoryProvider;
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class _MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}

class _MockNotifyMemberApprovalUseCase extends Mock
    implements NotifyMemberApprovalUseCase {}

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockCreateGroupUseCase createGroupUseCase;
  late _MockNotifyMemberApprovalUseCase notifyUseCase;
  late _MockUserProfileRepository profileRepository;

  final profile = UserProfile(
    id: 'profile-1',
    displayName: 'Papa',
    avatarEmoji: '\u{1F468}',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    createGroupUseCase = _MockCreateGroupUseCase();
    notifyUseCase = _MockNotifyMemberApprovalUseCase();
    profileRepository = _MockUserProfileRepository();

    when(() => profileRepository.find()).thenAnswer((_) async => profile);
    when(
      () => notifyUseCase.listenForJoinRequests(),
    ).thenAnswer((_) => const Stream<WebSocketEvent>.empty());
    when(
      () => notifyUseCase.connectWebSocket(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {});
    when(() => notifyUseCase.disconnectWebSocket()).thenReturn(null);
  });

  List<Override> overrides() => [
    createGroupUseCaseProvider.overrideWithValue(createGroupUseCase),
    notifyMemberApprovalUseCaseProvider.overrideWithValue(notifyUseCase),
    userProfileRepositoryProvider.overrideWithValue(profileRepository),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(const CreateGroupScreen(), overrides: overrides()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'opening and returning before confirmation has no API side effect',
    (tester) async {
      await pumpScreen(tester);

      verifyNever(
        () => createGroupUseCase.execute(
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          groupName: any(named: 'groupName'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      );

      await tester.tap(find.byKey(const Key('create-group-back')));
      await tester.pump();

      verifyNever(
        () => createGroupUseCase.execute(
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          groupName: any(named: 'groupName'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      );
    },
  );

  testWidgets(
    'explicit confirmation submits exactly once and rebuild is inert',
    (tester) async {
      when(
        () => createGroupUseCase.execute(
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          groupName: any(named: 'groupName'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      ).thenAnswer(
        (_) async => const CreateGroupResult.success(
          groupId: 'group-1',
          inviteCode: 'INV123',
          expiresAt: 4102444800,
        ),
      );
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('create-group-submit')));
      await tester.pumpAndSettle();

      verify(
        () => createGroupUseCase.execute(
          displayName: 'Papa',
          avatarEmoji: '\u{1F468}',
          groupName: "Papa's Family",
          avatarImageHash: null,
        ),
      ).called(1);

      await tester.pumpWidget(
        createLocalizedWidget(
          const CreateGroupScreen(),
          overrides: overrides(),
        ),
      );
      await tester.pump();
      verifyNoMoreInteractions(createGroupUseCase);
    },
  );

  testWidgets('double tap while creating is coalesced', (tester) async {
    final completer = Completer<CreateGroupResult>();
    when(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer((_) => completer.future);
    await pumpScreen(tester);

    final submit = find.byKey(const Key('create-group-submit'));
    await tester.tap(submit);
    await tester.tap(submit);
    await tester.pump();

    verify(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).called(1);

    completer.complete(const CreateGroupResult.error('network error'));
    await tester.pumpAndSettle();
  });

  testWidgets('back control and name editing are disabled while creating', (
    tester,
  ) async {
    final completer = Completer<CreateGroupResult>();
    when(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer((_) => completer.future);
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('create-group-submit')));
    await tester.pump();

    final back = tester.widget<GestureDetector>(
      find.byKey(const Key('create-group-back')),
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('create-group-name-field')),
    );
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(back.onTap, isNull);
    expect(nameField.enabled, isFalse);
    expect(popScope.canPop, isFalse);

    completer.complete(const CreateGroupResult.error('network error'));
    await tester.pumpAndSettle();
  });

  testWidgets('failed creation can be retried safely', (tester) async {
    var calls = 0;
    when(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) return const CreateGroupResult.error('network error');
      return const CreateGroupResult.success(
        groupId: 'group-1',
        inviteCode: 'INV123',
        expiresAt: 4102444800,
      );
    });
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('create-group-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-group-retry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-group-retry')));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.text('INV 123'), findsOneWidget);
  });

  testWidgets('single-group conflict uses localized guidance', (tester) async {
    when(
      () => createGroupUseCase.execute(
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        groupName: any(named: 'groupName'),
        avatarImageHash: any(named: 'avatarImageHash'),
      ),
    ).thenAnswer(
      (_) async => const CreateGroupResult.error(
        'server detail',
        kind: GroupOperationErrorKind.membershipConflict,
      ),
    );
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('create-group-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('already has a family group'), findsOneWidget);
    expect(find.textContaining('server detail'), findsNothing);
  });

  testWidgets(
    'network failure shows a friendly retry dialog without technical details',
    (tester) async {
      var calls = 0;
      when(
        () => createGroupUseCase.execute(
          displayName: any(named: 'displayName'),
          avatarEmoji: any(named: 'avatarEmoji'),
          groupName: any(named: 'groupName'),
          avatarImageHash: any(named: 'avatarImageHash'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          return const CreateGroupResult.error(
            'ClientException with SocketException: Failed host lookup: sync.happypocket.app',
            kind: GroupOperationErrorKind.networkUnavailable,
          );
        }
        return const CreateGroupResult.success(
          groupId: 'group-1',
          inviteCode: 'INV123',
          expiresAt: 4102444800,
        );
      });
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('create-group-submit')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('family-network-unavailable-dialog')),
        findsOneWidget,
      );
      expect(find.textContaining('ClientException'), findsNothing);
      expect(find.textContaining('happypocket.app'), findsNothing);
      expect(find.byKey(const Key('create-group-name-field')), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('family-network-unavailable-retry')),
      );
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('INV 123'), findsOneWidget);
    },
  );
}
