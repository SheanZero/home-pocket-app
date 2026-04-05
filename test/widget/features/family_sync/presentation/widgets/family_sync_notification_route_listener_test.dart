import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

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
        overrides: [pushNotificationServiceProvider.overrideWithValue(service)],
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
        overrides: [pushNotificationServiceProvider.overrideWithValue(service)],
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
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
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
        overrides: [pushNotificationServiceProvider.overrideWithValue(service)],
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

  testWidgets('pops to root and resets status on groupDissolved intent', (
    tester,
  ) async {
    final service = PushNotificationService(
      apiClient: MockRelayApiClient(),
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
          pushNotificationServiceProvider.overrideWithValue(service),
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
    // Snackbar with "unpaired" message should be visible
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
