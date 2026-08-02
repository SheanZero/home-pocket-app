import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/repository_providers.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/shared/widgets/soft_toast.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class _AllowPushAcceptancePolicy implements PushAcceptancePolicy {
  const _AllowPushAcceptancePolicy();

  @override
  Future<bool> accepts(
    Map<String, dynamic> data, {
    required String? boundIdentityGeneration,
  }) async => true;

  @override
  Future<String?> resolveIdentityGeneration() async => 'test-identity';
}

class MockCompleteMemberActivationUseCase extends Mock
    implements CompleteMemberActivationUseCase {}

class FakePushMessagingClient implements PushMessagingClient {
  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> requestPermission() async {}
}

class FakeLocalNotificationClient implements LocalNotificationClient {
  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {}

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {}
}

void main() {
  testWidgets('routes join request notifications to the approval screen', (
    tester,
  ) async {
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
      acceptancePolicy: const _AllowPushAcceptancePolicy(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilySyncNotificationRouteListener(
          buildMemberApprovalScreen: (context, groupId) =>
              const Scaffold(body: Text('approval-screen')),
          buildGroupManagementScreen: (context, groupId) =>
              const Scaffold(body: Text('group-management-screen')),
          child: const Scaffold(body: Text('home')),
        ),
        overrides: [
          appPushNotificationServiceProvider.overrideWithValue(service),
        ],
      ),
    );

    await service.handleNotificationTap({
      'type': 'join_request',
      'groupId': 'group-1',
    });
    await tester.pumpAndSettle();

    expect(find.text('approval-screen'), findsOneWidget);
  });

  testWidgets('passes groupId from push intent to member approval builder', (
    tester,
  ) async {
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
      acceptancePolicy: const _AllowPushAcceptancePolicy(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );
    String? capturedGroupId;

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilySyncNotificationRouteListener(
          buildMemberApprovalScreen: (context, groupId) {
            capturedGroupId = groupId;
            return const Scaffold(body: Text('approval-screen'));
          },
          buildGroupManagementScreen: (context, groupId) =>
              const Scaffold(body: Text('group-management-screen')),
          child: const Scaffold(body: Text('home')),
        ),
        overrides: [
          appPushNotificationServiceProvider.overrideWithValue(service),
        ],
      ),
    );

    await service.handleNotificationTap({
      'type': 'join_request',
      'groupId': 'group-123',
    });
    await tester.pumpAndSettle();

    expect(capturedGroupId, 'group-123');
    expect(find.text('approval-screen'), findsOneWidget);
  });

  testWidgets('passes groupId from push intent to group management builder', (
    tester,
  ) async {
    final memberActivation = MockCompleteMemberActivationUseCase();
    when(
      () => memberActivation.execute(expectedGroupId: 'group-456'),
    ).thenAnswer(
      (_) async => const MemberActivationReady(groupId: 'group-456'),
    );
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
      acceptancePolicy: const _AllowPushAcceptancePolicy(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );
    String? capturedGroupId;

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilySyncNotificationRouteListener(
          buildMemberApprovalScreen: (context, groupId) =>
              const Scaffold(body: Text('approval-screen')),
          buildGroupManagementScreen: (context, groupId) {
            capturedGroupId = groupId;
            return const Scaffold(body: Text('group-management-screen'));
          },
          child: const Scaffold(body: Text('home')),
        ),
        overrides: [
          appPushNotificationServiceProvider.overrideWithValue(service),
          completeMemberActivationUseCaseProvider.overrideWithValue(
            memberActivation,
          ),
        ],
      ),
    );

    await service.handleNotificationTap({
      'type': 'member_confirmed',
      'groupId': 'group-456',
    });
    await tester.pumpAndSettle();

    expect(capturedGroupId, 'group-456');
    expect(find.text('group-management-screen'), findsOneWidget);
  });

  testWidgets('does not open group management before key bootstrap is ready', (
    tester,
  ) async {
    final memberActivation = MockCompleteMemberActivationUseCase();
    when(
      () => memberActivation.execute(expectedGroupId: 'group-456'),
    ).thenAnswer(
      (_) async => const MemberActivationAwaitingKey(groupId: 'group-456'),
    );
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
      acceptancePolicy: const _AllowPushAcceptancePolicy(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilySyncNotificationRouteListener(
          buildGroupManagementScreen: (context, groupId) =>
              const Scaffold(body: Text('group-management-screen')),
          child: const Scaffold(body: Text('home')),
        ),
        overrides: [
          appPushNotificationServiceProvider.overrideWithValue(service),
          completeMemberActivationUseCaseProvider.overrideWithValue(
            memberActivation,
          ),
        ],
      ),
    );

    await service.handleNotificationTap({
      'type': 'member_confirmed',
      'groupId': 'group-456',
    });
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('group-management-screen'), findsNothing);
  });

  testWidgets('pops to root and resets status on groupDissolved intent', (
    tester,
  ) async {
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
      acceptancePolicy: const _AllowPushAcceptancePolicy(),
      messagingClient: FakePushMessagingClient(),
      localNotificationClient: FakeLocalNotificationClient(),
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilySyncNotificationRouteListener(
          child: Scaffold(
            body: Column(
              children: [
                const Text('sync-status-placeholder'),
                Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const Scaffold(body: Text('details-screen')),
                        ),
                      );
                    },
                    child: const Text('open-details'),
                  ),
                ),
              ],
            ),
          ),
        ),
        overrides: [
          appPushNotificationServiceProvider.overrideWithValue(service),
        ],
      ),
    );

    await tester.tap(find.text('open-details'));
    await tester.pumpAndSettle();
    expect(find.text('details-screen'), findsOneWidget);

    await service.handleNotificationTap({
      'type': 'group_dissolved',
      'groupId': 'group-1',
    });
    await tester.pumpAndSettle();

    // After memberRemoved, should pop back to first route
    expect(find.text('details-screen'), findsNothing);
    // Top toast with "unpaired" message should be visible
    expect(find.byType(SoftToast), findsOneWidget);

    // SoftToast schedules an auto-hide Timer; advance past it so teardown
    // does not fail with "A Timer is still pending".
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
