import 'package:flutter/services.dart';

import 'push_notification_service.dart';

const apnsPushMethodChannelName = 'home_pocket/apns_push/methods';
const apnsPushTokenEventChannelName = 'home_pocket/apns_push/token_refresh';
const apnsPushForegroundEventChannelName =
    'home_pocket/apns_push/foreground_messages';
const apnsPushOpenedEventChannelName = 'home_pocket/apns_push/opened_messages';

abstract class ApnsPushBridge {
  Future<void> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<Map<String, dynamic>> get onForegroundMessage;

  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  Future<Map<String, dynamic>?> getInitialMessage();
}

class MethodChannelApnsPushBridge implements ApnsPushBridge {
  MethodChannelApnsPushBridge({
    MethodChannel? methodChannel,
    EventChannel? tokenEventChannel,
    EventChannel? foregroundEventChannel,
    EventChannel? openedEventChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel(apnsPushMethodChannelName),
       _tokenEventChannel =
           tokenEventChannel ??
           const EventChannel(apnsPushTokenEventChannelName),
       _foregroundEventChannel =
           foregroundEventChannel ??
           const EventChannel(apnsPushForegroundEventChannelName),
       _openedEventChannel =
           openedEventChannel ??
           const EventChannel(apnsPushOpenedEventChannelName);

  final MethodChannel _methodChannel;
  final EventChannel _tokenEventChannel;
  final EventChannel _foregroundEventChannel;
  final EventChannel _openedEventChannel;

  @override
  Future<void> requestPermission() async {
    await _methodChannel.invokeMethod<void>('requestPermission');
  }

  @override
  Future<String?> getToken() async {
    return _methodChannel.invokeMethod<String>('getToken');
  }

  @override
  Stream<String> get onTokenRefresh => _tokenEventChannel
      .receiveBroadcastStream()
      .map((event) => event as String);

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _foregroundEventChannel.receiveBroadcastStream().map(_asMap);

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _openedEventChannel.receiveBroadcastStream().map(_asMap);

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    final message = await _methodChannel.invokeMethod<dynamic>(
      'getInitialMessage',
    );
    if (message == null) return null;
    return _asMap(message);
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);
}

class ApnsPushMessagingClient implements PushMessagingClient {
  ApnsPushMessagingClient({ApnsPushBridge? bridge})
    : _bridge = bridge ?? MethodChannelApnsPushBridge();

  final ApnsPushBridge _bridge;

  @override
  Future<void> requestPermission() => _bridge.requestPermission();

  @override
  Future<String?> getToken() => _bridge.getToken();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _bridge.onForegroundMessage;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() =>
      _bridge.getInitialMessage();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp =>
      _bridge.onMessageOpenedApp;

  @override
  Stream<String> get onTokenRefresh => _bridge.onTokenRefresh;
}
