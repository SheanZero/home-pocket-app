import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/apns_push_messaging_client.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}

class FakePushMessagingClient implements PushMessagingClient {
  FakePushMessagingClient({this.initialToken, this.initialMessage});

  final String? initialToken;
  final Map<String, dynamic>? initialMessage;
  bool permissionRequested = false;

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _foregroundController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _openedController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Future<String?> getToken() async => initialToken;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => initialMessage;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _openedController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }

  Future<void> emitTokenRefresh(String token) async {
    _tokenRefreshController.add(token);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> emitForegroundMessage(Map<String, dynamic> data) async {
    _foregroundController.add(data);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> emitOpenedMessage(Map<String, dynamic> data) async {
    _openedController.add(data);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await _tokenRefreshController.close();
    await _foregroundController.close();
    await _openedController.close();
  }
}

class FakeLocalNotificationClient implements LocalNotificationClient {
  Future<void> Function(Map<String, dynamic> data)? _onTap;
  final shownNotifications = <ShownLocalNotification>[];

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    _onTap = onTap;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    shownNotifications.add(
      ShownLocalNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }

  Future<void> tapLastNotification() async {
    final last = shownNotifications.last;
    await _onTap?.call(last.payload);
  }
}

class FakeApnsPushBridge implements ApnsPushBridge {
  FakeApnsPushBridge({this.initialToken});

  final String? initialToken;
  bool permissionRequested = false;
  final _tokenRefreshController = StreamController<String>.broadcast();

  @override
  Future<String?> getToken() async => initialToken;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }

  Future<void> dispose() async {
    await _tokenRefreshController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRelayApiClient apiClient;
  late FakePushMessagingClient messagingClient;
  late FakeLocalNotificationClient localNotificationClient;
  late PushNotificationService service;
  late int memberConfirmedCalls;
  late int syncAvailableCalls;
  late int joinRequestCalls;
  late int memberLeftCalls;
  late int groupDissolvedCalls;

  setUp(() {
    apiClient = MockRelayApiClient();
    messagingClient = FakePushMessagingClient(initialToken: 'token-1');
    localNotificationClient = FakeLocalNotificationClient();
    memberConfirmedCalls = 0;
    syncAvailableCalls = 0;
    joinRequestCalls = 0;
    memberLeftCalls = 0;
    groupDissolvedCalls = 0;

    when(
      () => apiClient.updatePushToken(
        pushToken: any(named: 'pushToken'),
        pushPlatform: any(named: 'pushPlatform'),
      ),
    ).thenAnswer((_) async {});

    service = PushNotificationService(
      apiClient: apiClient,
      messagingClient: messagingClient,
      localNotificationClient: localNotificationClient,
      firebaseInitializer: () async {},
      localeProvider: () => const Locale('en'),
    );
    service.registerHandlers(
      onMemberConfirmed: (_) async {
        memberConfirmedCalls++;
      },
      onSyncAvailable: (_) async {
        syncAvailableCalls++;
      },
      onJoinRequest: (_) async {
        joinRequestCalls++;
      },
      onMemberLeft: (_) async {
        memberLeftCalls++;
      },
      onGroupDissolved: (_) async {
        groupDissolvedCalls++;
      },
    );
  });

  tearDown(() async {
    await service.dispose();
    await messagingClient.dispose();
  });

  test('navigation intents compare member removal destinations', () {
    expect(
      const PushNavigationIntent.memberRemoved(groupId: 'group-1'),
      const PushNavigationIntent.memberRemoved(groupId: 'group-1'),
    );
    expect(
      const PushNavigationIntent.memberRemoved(groupId: 'group-1').hashCode,
      const PushNavigationIntent.memberRemoved(groupId: 'group-1').hashCode,
    );
  });

  test(
    'initialize requests permission and registers current and refreshed token',
    () async {
      await service.initialize();

      expect(messagingClient.permissionRequested, isTrue);
      verify(
        () => apiClient.updatePushToken(
          pushToken: 'token-1',
          pushPlatform: any(named: 'pushPlatform'),
        ),
      ).called(1);

      await messagingClient.emitTokenRefresh('token-2');

      verify(
        () => apiClient.updatePushToken(
          pushToken: 'token-2',
          pushPlatform: any(named: 'pushPlatform'),
        ),
      ).called(1);
    },
  );

  test(
    'foreground join_request emits navigation intent for member approval',
    () async {
      await service.initialize();

      final intents = <PushNavigationIntent>[];
      service.navigationIntents.listen(intents.add);

      await messagingClient.emitForegroundMessage({
        'type': 'join_request',
        'groupId': 'group-1',
      });

      expect(joinRequestCalls, 1);
      expect(localNotificationClient.shownNotifications, isEmpty);
      expect(intents, [
        const PushNavigationIntent.memberApproval(groupId: 'group-1'),
      ]);
    },
  );

  test(
    'initial member_confirmed message publishes pending group management navigation intent',
    () async {
      messagingClient = FakePushMessagingClient(
        initialToken: 'token-1',
        initialMessage: {'type': 'member_confirmed', 'groupId': 'group-1'},
      );
      service = PushNotificationService(
        apiClient: apiClient,
        messagingClient: messagingClient,
        localNotificationClient: localNotificationClient,
        firebaseInitializer: () async {},
        localeProvider: () => const Locale('en'),
      );
      service.registerHandlers(
        onMemberConfirmed: (_) async {
          memberConfirmedCalls++;
        },
        onSyncAvailable: (_) async {
          syncAvailableCalls++;
        },
        onJoinRequest: (_) async {
          joinRequestCalls++;
        },
        onMemberLeft: (_) async {
          memberLeftCalls++;
        },
        onGroupDissolved: (_) async {
          groupDissolvedCalls++;
        },
      );

      await service.initialize();

      expect(memberConfirmedCalls, 1);
      expect(
        service.takePendingNavigationIntent(),
        const PushNavigationIntent.groupManagement(groupId: 'group-1'),
      );
    },
  );

  test(
    'initialize supports native APNs messaging without Firebase bootstrap',
    () async {
      final bridge = FakeApnsPushBridge(initialToken: 'apns-token-1');
      service = PushNotificationService(
        apiClient: apiClient,
        messagingClient: ApnsPushMessagingClient(bridge: bridge),
        localNotificationClient: localNotificationClient,
        firebaseInitializer: null,
        localeProvider: () => const Locale('en'),
        pushPlatform: 'apns',
      );
      service.registerHandlers(
        onMemberConfirmed: (_) async {},
        onSyncAvailable: (_) async {},
        onJoinRequest: (_) async {},
        onMemberLeft: (_) async {},
        onGroupDissolved: (_) async {},
      );

      await service.initialize();

      expect(bridge.permissionRequested, isTrue);
      verify(
        () => apiClient.updatePushToken(
          pushToken: 'apns-token-1',
          pushPlatform: 'apns',
        ),
      ).called(1);

      await bridge.dispose();
    },
  );

  test('foreground member_left message invokes handler', () async {
    await service.initialize();

    await messagingClient.emitForegroundMessage({
      'type': 'member_left',
      'groupId': 'group-1',
      'deviceId': 'device-2',
      'reason': 'left',
    });

    expect(memberLeftCalls, 1);
  });

  test(
    'foreground group_dissolved message invokes handler and emits navigation intent',
    () async {
      await service.initialize();

      final intents = <PushNavigationIntent>[];
      service.navigationIntents.listen(intents.add);

      await messagingClient.emitForegroundMessage({
        'type': 'group_dissolved',
        'groupId': 'group-1',
      });

      expect(groupDissolvedCalls, 1);
      expect(intents, [
        const PushNavigationIntent.groupDissolved(groupId: 'group-1'),
      ]);
    },
  );

  test(
    'initialize is idempotent and getToken delegates to messaging client',
    () async {
      expect(await service.initialize(), 'token-1');
      expect(await service.initialize(), 'token-1');
      expect(await service.getToken(), 'token-1');

      verify(
        () => apiClient.updatePushToken(
          pushToken: 'token-1',
          pushPlatform: any(named: 'pushPlatform'),
        ),
      ).called(1);
    },
  );

  test('initialize returns null when firebase bootstrap fails', () async {
    service = PushNotificationService(
      apiClient: apiClient,
      messagingClient: messagingClient,
      localNotificationClient: localNotificationClient,
      firebaseInitializer: () async => throw StateError('firebase failed'),
      localeProvider: () => const Locale('en'),
    );

    expect(await service.initialize(), isNull);
  });

  test(
    'direct messages invoke handlers without navigation side effects',
    () async {
      final intents = <PushNavigationIntent>[];
      service.navigationIntents.listen(intents.add);

      await service.handleMessage({'type': 'sync_available'});
      await service.handleMessage({
        'type': 'pair_confirmed',
        'groupId': 'group-1',
      });
      await service.handleMessage({'type': 'unknown'});

      expect(syncAvailableCalls, 1);
      expect(memberConfirmedCalls, 1);
      expect(intents, isEmpty);
      expect(service.takePendingNavigationIntent(), isNull);
    },
  );

  test('foreground member confirmation shows localized notification', () async {
    await service.initialize();

    await messagingClient.emitForegroundMessage({
      'type': 'pair_confirmed',
      'groupId': 'group-1',
    });

    expect(memberConfirmedCalls, 1);
    expect(localNotificationClient.shownNotifications, hasLength(1));
    expect(localNotificationClient.shownNotifications.single.id, 1002);
    expect(
      localNotificationClient.shownNotifications.single.payload['groupId'],
      'group-1',
    );
  });

  test(
    'opened pair_request and notification tap emit member approval intent',
    () async {
      await service.initialize();

      final intents = <PushNavigationIntent>[];
      service.navigationIntents.listen(intents.add);

      await messagingClient.emitOpenedMessage({
        'type': 'pair_request',
        'groupId': 'group-1',
      });
      await service.handleNotificationTap({
        'type': 'group_dissolved',
        'groupId': 'group-1',
      });
      await service.handleNotificationTap({'type': 'member_left'});

      expect(intents, [
        const PushNavigationIntent.memberApproval(groupId: 'group-1'),
        const PushNavigationIntent.groupDissolved(groupId: 'group-1'),
      ]);
      expect(
        service.takePendingNavigationIntent(),
        const PushNavigationIntent.groupDissolved(groupId: 'group-1'),
      );
      expect(service.takePendingNavigationIntent(), isNull);
    },
  );

  test('foreground join request notification can be tapped', () async {
    await service.initialize();

    final intents = <PushNavigationIntent>[];
    service.navigationIntents.listen(intents.add);

    await messagingClient.emitForegroundMessage({
      'type': 'pair_confirmed',
      'groupId': 'group-1',
    });
    await localNotificationClient.tapLastNotification();

    expect(intents, [
      const PushNavigationIntent.groupManagement(groupId: 'group-1'),
    ]);
  });
}
