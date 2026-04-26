import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/application/family_sync/notify_member_approval_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/application/family_sync/repository_providers.dart'
    show notifyMemberApprovalUseCaseProvider;
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockNotifyMemberApprovalUseCase extends Mock
    implements NotifyMemberApprovalUseCase {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockNotifyMemberApprovalUseCase notifyUseCase;
  late StreamController<WebSocketEvent> wsEventController;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    notifyUseCase = MockNotifyMemberApprovalUseCase();
    wsEventController = StreamController<WebSocketEvent>.broadcast();

    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        groupName: 'Test Family',
        status: GroupStatus.active,
        role: 'owner',
        groupKey: 'group-key',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            displayName: 'Owner phone',
            avatarEmoji: '\u{1F3E0}',
            role: 'owner',
            status: 'active',
          ),
          GroupMember(
            deviceId: 'member-1',
            publicKey: 'pk-member',
            deviceName: 'Kitchen tablet',
            displayName: 'Kitchen tablet',
            avatarEmoji: '\u{1F3E0}',
            role: 'member',
            status: 'pending',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
    when(
      () => groupRepository.getGroupById(any()),
    ).thenAnswer((_) async => null);

    when(
      () => confirmMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const ConfirmMemberSuccess());

    when(
      () => removeMemberUseCase.execute(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
      ),
    ).thenAnswer((_) async => const RemoveMemberResult.success());

    // NotifyMemberApprovalUseCase mocks
    when(() => notifyUseCase.listenForJoinRequests())
        .thenAnswer((_) => wsEventController.stream);
    when(
      () => notifyUseCase.connectWebSocket(groupId: any(named: 'groupId')),
    ).thenAnswer((_) async {});
    when(() => notifyUseCase.disconnectWebSocket()).thenReturn(null);
  });

  tearDown(() async {
    await wsEventController.close();
  });

  List<Override> buildOverrides() => [
    groupRepositoryProvider.overrideWithValue(groupRepository),
    confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
    removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
    notifyMemberApprovalUseCaseProvider.overrideWithValue(notifyUseCase),
  ];

  testWidgets('connects WebSocket on init', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => notifyUseCase.connectWebSocket(groupId: any(named: 'groupId')),
    ).called(1);
  });

  testWidgets('reloads group when join_request event arrives', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    // Initial loads: _loadGroup() called once on initState
    verify(() => groupRepository.getActiveGroup()).called(greaterThanOrEqualTo(1));

    // Simulate join_request WebSocket event via the use case stream
    wsEventController.add(
      const WebSocketEvent(
        type: WebSocketEventType.joinRequest,
        groupId: 'group-1',
      ),
    );
    await tester.pumpAndSettle();

    // Group should be reloaded once more
    verify(() => groupRepository.getActiveGroup()).called(greaterThanOrEqualTo(1));
  });
}
