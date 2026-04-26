import 'dart:async';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/group_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/member_approval_screen.dart';
import 'package:home_pocket/application/family_sync/confirm_member_use_case.dart';
import 'package:home_pocket/application/family_sync/remove_member_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_connection_state.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockConfirmMemberUseCase extends Mock implements ConfirmMemberUseCase {}

class MockRemoveMemberUseCase extends Mock implements RemoveMemberUseCase {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockGroupRepository groupRepository;
  late MockConfirmMemberUseCase confirmMemberUseCase;
  late MockRemoveMemberUseCase removeMemberUseCase;
  late MockWebSocketService webSocketService;
  late MockKeyManager keyManager;
  late StreamController<WebSocketEvent> wsEventController;

  setUp(() {
    groupRepository = MockGroupRepository();
    confirmMemberUseCase = MockConfirmMemberUseCase();
    removeMemberUseCase = MockRemoveMemberUseCase();
    webSocketService = MockWebSocketService();
    keyManager = MockKeyManager();
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

    // WebSocket mocks
    when(
      () => webSocketService.connectionStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => webSocketService.connectionState,
    ).thenReturn(WebSocketConnectionState.disconnected);
    when(
      () => webSocketService.eventStream,
    ).thenAnswer((_) => wsEventController.stream);
    when(
      () => webSocketService.connect(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
        signMessage: any(named: 'signMessage'),
      ),
    ).thenReturn(null);
    when(() => webSocketService.disconnect()).thenReturn(null);
    when(() => webSocketService.startLifecycleObservation()).thenReturn(null);
    when(() => webSocketService.stopLifecycleObservation()).thenReturn(null);

    // KeyManager mock
    when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'test-device');
    when(() => keyManager.signData(any())).thenAnswer(
      (_) async => Signature(
        [],
        publicKey: SimplePublicKey([], type: KeyPairType.ed25519),
      ),
    );
  });

  tearDown(() async {
    await wsEventController.close();
  });

  List<Override> buildOverrides() => [
    groupRepositoryProvider.overrideWithValue(groupRepository),
    confirmMemberUseCaseProvider.overrideWithValue(confirmMemberUseCase),
    removeMemberUseCaseProvider.overrideWithValue(removeMemberUseCase),
    webSocketServiceProvider.overrideWithValue(webSocketService),
    keyManagerProvider.overrideWithValue(keyManager),
  ];

  testWidgets('connects WebSocket on init', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => webSocketService.startLifecycleObservation()).called(1);
  });

  testWidgets('reloads group when join_request event arrives', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const MemberApprovalScreen(),
        overrides: buildOverrides(),
      ),
    );
    await tester.pumpAndSettle();

    // Initial loads: _loadGroup() + _connectWebSocket() both call getActiveGroup
    verify(() => groupRepository.getActiveGroup()).called(2);

    // Simulate join_request WebSocket event
    wsEventController.add(
      const WebSocketEvent(
        type: WebSocketEventType.joinRequest,
        groupId: 'group-1',
      ),
    );
    await tester.pumpAndSettle();

    // Group should be reloaded once more
    verify(() => groupRepository.getActiveGroup()).called(1);
  });
}
