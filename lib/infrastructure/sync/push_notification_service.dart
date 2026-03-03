import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../generated/app_localizations.dart';
import 'relay_api_client.dart';

typedef PushMessageHandler = Future<void> Function(Map<String, dynamic> data);
typedef FirebaseInitializer = Future<void> Function();

enum PushNavigationDestination { memberApproval, groupManagement }

class PushNavigationIntent {
  const PushNavigationIntent._({required this.destination, this.groupId});

  const PushNavigationIntent.memberApproval({String? groupId})
    : this._(
        destination: PushNavigationDestination.memberApproval,
        groupId: groupId,
      );

  const PushNavigationIntent.groupManagement({String? groupId})
    : this._(
        destination: PushNavigationDestination.groupManagement,
        groupId: groupId,
      );

  final PushNavigationDestination destination;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is PushNavigationIntent &&
        other.destination == destination &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(destination, groupId);
}

class ShownLocalNotification {
  const ShownLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
}

abstract class PushMessagingClient {
  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<Map<String, dynamic>> get onForegroundMessage;

  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  Future<Map<String, dynamic>?> getInitialMessage();
}

abstract class LocalNotificationClient {
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  );

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  });
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient({FirebaseMessaging? messaging})
    : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  FirebaseMessaging get _instance => _messaging ?? FirebaseMessaging.instance;

  @override
  Future<void> requestPermission() async {
    await _instance.requestPermission();
  }

  @override
  Future<String?> getToken() => _instance.getToken();

  @override
  Stream<String> get onTokenRefresh => _instance.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map((message) => message.data);

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map((message) => message.data);

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    final message = await _instance.getInitialMessage();
    return message?.data;
  }
}

class FlutterLocalNotificationClient implements LocalNotificationClient {
  FlutterLocalNotificationClient({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'family_sync';
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        await onTap(jsonDecode(payload) as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Family Sync',
        channelDescription: 'Family sync notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: jsonEncode(payload));
  }
}

enum _PushMessageSource { direct, foreground, appOpened, initialMessage }

class PushNotificationService {
  PushNotificationService({
    required RelayApiClient apiClient,
    PushMessagingClient? messagingClient,
    LocalNotificationClient? localNotificationClient,
    FirebaseInitializer? firebaseInitializer,
    Locale Function()? localeProvider,
    String? pushPlatform,
  }) : _apiClient = apiClient,
       _messagingClient = messagingClient ?? FirebasePushMessagingClient(),
       _localNotificationClient =
           localNotificationClient ?? FlutterLocalNotificationClient(),
       _firebaseInitializer =
           firebaseInitializer ??
           (Platform.isAndroid ? Firebase.initializeApp : null),
       _localeProvider =
           localeProvider ??
           (() => WidgetsBinding.instance.platformDispatcher.locale),
       _pushPlatform = pushPlatform;

  final RelayApiClient _apiClient;
  final PushMessagingClient _messagingClient;
  final LocalNotificationClient _localNotificationClient;
  final FirebaseInitializer? _firebaseInitializer;
  final Locale Function() _localeProvider;
  final String? _pushPlatform;

  final _navigationController =
      StreamController<PushNavigationIntent>.broadcast();

  PushMessageHandler? _onMemberConfirmed;
  PushMessageHandler? _onSyncAvailable;
  PushMessageHandler? _onJoinRequest;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<Map<String, dynamic>>? _foregroundSubscription;
  StreamSubscription<Map<String, dynamic>>? _openedAppSubscription;

  PushNavigationIntent? _pendingNavigationIntent;
  bool _initialized = false;

  Stream<PushNavigationIntent> get navigationIntents =>
      _navigationController.stream;

  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
    PushMessageHandler? onJoinRequest,
  }) {
    _onMemberConfirmed = onMemberConfirmed;
    _onSyncAvailable = onSyncAvailable;
    _onJoinRequest = onJoinRequest;
  }

  Future<String?> initialize() async {
    if (_initialized) {
      return _messagingClient.getToken();
    }

    try {
      if (kDebugMode) {
        debugPrint('PushNotificationService: initializing');
      }
      if (_firebaseInitializer != null) {
        await _firebaseInitializer();
      }
      await _localNotificationClient.initialize(handleNotificationTap);
      await _messagingClient.requestPermission();

      final token = await _messagingClient.getToken();
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: initial token '
          '${token == null || token.isEmpty ? '<empty>' : token}',
        );
      }
      if (token != null && token.isNotEmpty) {
        await registerToken(token);
      }

      _tokenRefreshSubscription = _messagingClient.onTokenRefresh.listen((
        token,
      ) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: token refreshed $token');
        }
        unawaited(registerToken(token));
      });

      _foregroundSubscription = _messagingClient.onForegroundMessage.listen((
        data,
      ) {
        unawaited(
          _handleIncomingMessage(data, source: _PushMessageSource.foreground),
        );
      });

      _openedAppSubscription = _messagingClient.onMessageOpenedApp.listen((
        data,
      ) {
        unawaited(
          _handleIncomingMessage(data, source: _PushMessageSource.appOpened),
        );
      });

      final initialMessage = await _messagingClient.getInitialMessage();
      if (initialMessage != null) {
        await _handleIncomingMessage(
          initialMessage,
          source: _PushMessageSource.initialMessage,
        );
      }

      _initialized = true;
      if (kDebugMode) {
        debugPrint('PushNotificationService: initialized');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: initialization failed: $e');
      }
      return null;
    }
  }

  Future<String?> getToken() => _messagingClient.getToken();

  Future<void> registerToken(String token) async {
    final platform = _pushPlatform ?? (Platform.isIOS ? 'apns' : 'fcm');
    if (kDebugMode) {
      debugPrint(
        'PushNotificationService: registering token for $platform '
        '(${token.length} chars)',
      );
    }
    await _apiClient.updatePushToken(pushToken: token, pushPlatform: platform);
    if (kDebugMode) {
      debugPrint('PushNotificationService: token registered');
    }
  }

  Future<void> handleMessage(Map<String, dynamic> data) async {
    await _handleIncomingMessage(data, source: _PushMessageSource.direct);
  }

  Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final intent = _intentForMessage(data);
    if (intent == null) return;

    _pendingNavigationIntent = intent;
    if (!_navigationController.isClosed) {
      _navigationController.add(intent);
    }
  }

  PushNavigationIntent? takePendingNavigationIntent() {
    final intent = _pendingNavigationIntent;
    _pendingNavigationIntent = null;
    return intent;
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _navigationController.close();
  }

  Future<void> _handleIncomingMessage(
    Map<String, dynamic> data, {
    required _PushMessageSource source,
  }) async {
    final type = data['type'] as String?;

    switch (type) {
      case 'member_confirmed':
      case 'pair_confirmed':
        await _onMemberConfirmed?.call(data);
        if (source == _PushMessageSource.foreground) {
          await _showForegroundNotification(data);
        } else if (source != _PushMessageSource.direct) {
          await handleNotificationTap(data);
        }
        break;
      case 'sync_available':
        await _onSyncAvailable?.call(data);
        break;
      case 'join_request':
      case 'pair_request':
        await _onJoinRequest?.call(data);
        if (source == _PushMessageSource.foreground) {
          await _showForegroundNotification(data);
        } else if (source != _PushMessageSource.direct) {
          await handleNotificationTap(data);
        }
        break;
      default:
        if (kDebugMode) {
          debugPrint('PushNotificationService: unknown message type: $type');
        }
    }
  }

  Future<void> _showForegroundNotification(Map<String, dynamic> data) async {
    final l10n = lookupS(_localeProvider());
    final type = data['type'] as String?;

    switch (type) {
      case 'join_request':
      case 'pair_request':
        await _localNotificationClient.show(
          id: 1001,
          title: l10n.familySyncNewRequest,
          body: l10n.familySyncJoinRequestNotificationBody,
          payload: data,
        );
        break;
      case 'member_confirmed':
      case 'pair_confirmed':
        await _localNotificationClient.show(
          id: 1002,
          title: l10n.familySyncMemberConfirmedNotificationTitle,
          body: l10n.familySyncMemberConfirmedNotificationBody,
          payload: data,
        );
        break;
    }
  }

  PushNavigationIntent? _intentForMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final groupId = data['groupId'] as String?;

    return switch (type) {
      'join_request' ||
      'pair_request' => PushNavigationIntent.memberApproval(groupId: groupId),
      'member_confirmed' || 'pair_confirmed' =>
        PushNavigationIntent.groupManagement(groupId: groupId),
      _ => null,
    };
  }
}
