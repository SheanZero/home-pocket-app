import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _FakeMessagingClient implements PushMessagingClient {
  Completer<Map<String, dynamic>?>? initialMessageBarrier;
  bool permissionRequested = false;
  final foreground = StreamController<Map<String, dynamic>>.broadcast();
  final opened = StreamController<Map<String, dynamic>>.broadcast();
  final tokens = StreamController<String>.broadcast();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() =>
      initialMessageBarrier?.future ?? Future.value();

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => foreground.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => opened.stream;

  @override
  Stream<String> get onTokenRefresh => tokens.stream;

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }

  Future<void> close() async {
    await foreground.close();
    await opened.close();
    await tokens.close();
  }
}

class _FakeLocalNotificationClient
    implements LocalNotificationClient, IdentityBoundLocalNotificationCleaner {
  Future<void> Function(Map<String, dynamic>)? onTap;
  int cancelAllCalls = 0;

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    this.onTap = onTap;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdentityBoundFamilyPushAcceptancePolicy', () {
    String? identity = 'device-old';
    var context = const FamilyPushAcceptanceContext(
      deviceId: 'device-old',
      groupId: 'group-old',
      groupStatus: 'active',
      groupRole: 'owner',
      memberStatus: 'active',
      controlRevision: 7,
    );
    late IdentityBoundFamilyPushAcceptancePolicy policy;

    setUp(() {
      identity = 'device-old';
      context = const FamilyPushAcceptanceContext(
        deviceId: 'device-old',
        groupId: 'group-old',
        groupStatus: 'active',
        groupRole: 'owner',
        memberStatus: 'active',
        controlRevision: 7,
      );
      policy = IdentityBoundFamilyPushAcceptancePolicy(
        identityGenerationResolver: () async => identity,
        contextResolver: () async => context,
      );
    });

    test('accepts current active owner pair request', () async {
      expect(
        await policy.accepts({
          'type': 'pair_request',
          'groupId': 'group-old',
        }, boundIdentityGeneration: 'device-old'),
        isTrue,
      );
    });

    test('rejects approval notification for active member', () async {
      context = const FamilyPushAcceptanceContext(
        deviceId: 'device-old',
        groupId: 'group-old',
        groupStatus: 'active',
        groupRole: 'member',
        memberStatus: 'active',
        controlRevision: 7,
      );

      expect(
        await policy.accepts({
          'type': 'join_request',
          'groupId': 'group-old',
        }, boundIdentityGeneration: 'device-old'),
        isFalse,
      );
    });

    test('rejects old group and malformed family payloads', () async {
      expect(
        await policy.accepts({
          'type': 'pair_request',
          'groupId': 'group-new',
        }, boundIdentityGeneration: 'device-old'),
        isFalse,
      );
      expect(
        await policy.accepts({
          'type': 'pair_request',
        }, boundIdentityGeneration: 'device-old'),
        isFalse,
      );
      expect(
        await policy.accepts({
          'type': 'pair_request',
          'groupId': 42,
        }, boundIdentityGeneration: 'device-old'),
        isFalse,
      );
    });

    test(
      'strictly validates optional target identity and control revision',
      () async {
        expect(
          await policy.accepts({
            'type': 'pair_request',
            'groupId': 'group-old',
            'targetDeviceId': 'another-device',
          }, boundIdentityGeneration: 'device-old'),
          isFalse,
        );
        expect(
          await policy.accepts({
            'type': 'sync_available',
            'groupId': 'group-old',
            'controlRevision': '6',
          }, boundIdentityGeneration: 'device-old'),
          isFalse,
        );
        expect(
          await policy.accepts({
            'type': 'sync_available',
            'groupId': 'group-old',
            'controlRevision': 'not-a-number',
          }, boundIdentityGeneration: 'device-old'),
          isFalse,
        );
        expect(
          await policy.accepts({
            'type': 'sync_available',
            'groupId': 'group-old',
            'targetDeviceId': 'device-old',
            'controlRevision': 8,
          }, boundIdentityGeneration: 'device-old'),
          isTrue,
        );
      },
    );

    test('rejects a callback bound to the previous identity', () async {
      identity = 'device-new';
      context = const FamilyPushAcceptanceContext(
        deviceId: 'device-new',
        groupId: 'group-new',
        groupStatus: 'active',
        groupRole: 'owner',
        memberStatus: 'active',
      );

      expect(
        await policy.accepts({
          'type': 'pair_request',
          'groupId': 'group-new',
        }, boundIdentityGeneration: 'device-old'),
        isFalse,
      );
    });

    test('leaves non-family notification types unaffected', () async {
      expect(
        await policy.accepts({
          'type': 'generic_reminder',
        }, boundIdentityGeneration: 'device-old'),
        isTrue,
      );
    });
  });

  group('PushNotificationService identity revocation', () {
    late _MockRelayApiClient apiClient;
    late _FakeMessagingClient messaging;
    late _FakeLocalNotificationClient localNotifications;
    late PushNotificationService service;
    String? identity = 'device-old';
    var context = const FamilyPushAcceptanceContext(
      deviceId: 'device-old',
      groupId: 'group-old',
      groupStatus: 'active',
      groupRole: 'owner',
      memberStatus: 'active',
    );
    var joinCalls = 0;

    PushNotificationService buildService() {
      return PushNotificationService(
        apiClient: apiClient,
        messagingClient: messaging,
        localNotificationClient: localNotifications,
        firebaseInitializer: () async {},
        localeProvider: () => const Locale('en'),
        acceptancePolicy: IdentityBoundFamilyPushAcceptancePolicy(
          identityGenerationResolver: () async => identity,
          contextResolver: () async => context,
        ),
      )..registerHandlers(onJoinRequest: (_) async => joinCalls++);
    }

    setUp(() {
      apiClient = _MockRelayApiClient();
      messaging = _FakeMessagingClient();
      localNotifications = _FakeLocalNotificationClient();
      identity = 'device-old';
      context = const FamilyPushAcceptanceContext(
        deviceId: 'device-old',
        groupId: 'group-old',
        groupStatus: 'active',
        groupRole: 'owner',
        memberStatus: 'active',
      );
      joinCalls = 0;
      service = buildService();
    });

    tearDown(() async {
      await service.dispose();
      await messaging.close();
    });

    test('does not start Push while restart wipe left no identity', () async {
      identity = null;

      expect(await service.initialize(), isNull);
      expect(messaging.permissionRequested, isFalse);
      expect(localNotifications.onTap, isNull);
    });

    test('clear rejects an already queued old-identity callback', () async {
      final contextRead = Completer<void>();
      final releaseContext = Completer<void>();
      service.configureAcceptancePolicy(
        IdentityBoundFamilyPushAcceptancePolicy(
          identityGenerationResolver: () async => identity,
          contextResolver: () async {
            contextRead.complete();
            await releaseContext.future;
            return context;
          },
        ),
      );
      await service.initialize();

      final delivery = service.handleMessage({
        'type': 'pair_request',
        'groupId': 'group-old',
      });
      await contextRead.future;
      final clearing = service.clearIdentityBoundState();
      releaseContext.complete();
      await Future.wait([delivery, clearing]);

      expect(joinCalls, 0);
      expect(service.takePendingNavigationIntent(), isNull);
      expect(localNotifications.cancelAllCalls, 1);
    });

    test('stale cold-start message cannot publish after wipe starts', () async {
      messaging.initialMessageBarrier = Completer<Map<String, dynamic>?>();
      final initialization = service.initialize();
      while (!messaging.permissionRequested) {
        await Future<void>.delayed(Duration.zero);
      }

      final clearing = service.clearIdentityBoundState();
      messaging.initialMessageBarrier!.complete({
        'type': 'pair_request',
        'groupId': 'group-old',
      });
      await Future.wait([initialization, clearing]);

      expect(joinCalls, 0);
      expect(service.takePendingNavigationIntent(), isNull);
    });

    test(
      'old local tap is rejected after wipe and new identity accepts',
      () async {
        await service.initialize();
        final oldTap = localNotifications.onTap!;
        await service.clearIdentityBoundState();

        await oldTap({'type': 'pair_request', 'groupId': 'group-old'});
        expect(joinCalls, 0);
        expect(service.takePendingNavigationIntent(), isNull);

        identity = 'device-new';
        context = const FamilyPushAcceptanceContext(
          deviceId: 'device-new',
          groupId: 'group-new',
          groupStatus: 'active',
          groupRole: 'owner',
          memberStatus: 'active',
        );
        // Group/device registration uses this path after a fresh identity is
        // minted; it must rebuild the revoked delivery pipeline.
        await service.registerCurrentToken();
        await messaging.opened.addStream(
          Stream.value({
            'type': 'pair_request',
            'groupId': 'group-new',
            'targetDeviceId': 'device-new',
          }),
        );
        await Future<void>.delayed(Duration.zero);

        expect(joinCalls, 1);
        expect(
          service.takePendingNavigationIntent(),
          const PushNavigationIntent.memberApproval(groupId: 'group-new'),
        );
      },
    );
  });
}
