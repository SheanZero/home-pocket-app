import 'dart:io';

import 'package:flutter/foundation.dart';

import 'relay_api_client.dart';

/// Callback type for handling push notification messages.
typedef PushMessageHandler = Future<void> Function(Map<String, dynamic> data);

/// Manages push notifications for sync triggers.
///
/// Handles:
/// - Registering/refreshing FCM/APNs push tokens with the relay server
/// - Dispatching incoming push messages by type:
///   - `member_confirmed` -> confirm local group membership and pull sync
///   - `sync_available` -> pull sync
///   - `join_request` -> foreground notification only
///
/// NOTE: Firebase must be configured (GoogleService-Info.plist / google-services.json)
/// before this service can be used. During development without Firebase,
/// sync can be triggered manually via pull-on-resume.
class PushNotificationService {
  PushNotificationService({required RelayApiClient apiClient})
    : _apiClient = apiClient;

  final RelayApiClient _apiClient;

  PushMessageHandler? _onMemberConfirmed;
  PushMessageHandler? _onSyncAvailable;

  /// Register handlers for push notification types.
  void registerHandlers({
    PushMessageHandler? onMemberConfirmed,
    PushMessageHandler? onSyncAvailable,
  }) {
    _onMemberConfirmed = onMemberConfirmed;
    _onSyncAvailable = onSyncAvailable;
  }

  /// Initialize push notification service.
  ///
  /// This should be called after app initialization when Firebase is available.
  /// Returns the push token if successfully obtained, null otherwise.
  Future<String?> initialize() async {
    try {
      // Firebase messaging initialization would go here:
      // final messaging = FirebaseMessaging.instance;
      // await messaging.requestPermission();
      // final token = await messaging.getToken();
      //
      // For now, return null until Firebase is configured.
      if (kDebugMode) {
        debugPrint(
          'PushNotificationService: Firebase not configured, '
          'push notifications disabled. Sync will use pull-on-resume.',
        );
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: initialization failed: $e');
      }
      return null;
    }
  }

  /// Register push token with the relay server.
  Future<void> registerToken(String token) async {
    final platform = Platform.isIOS ? 'apns' : 'fcm';
    await _apiClient.updatePushToken(pushToken: token, pushPlatform: platform);
  }

  /// Handle incoming push notification data.
  ///
  /// Called by Firebase messaging callbacks (foreground + background).
  Future<void> handleMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;

    switch (type) {
      case 'member_confirmed':
        await _onMemberConfirmed?.call(data);
        break;
      case 'pair_confirmed':
        await _onMemberConfirmed?.call(data);
        break;
      case 'sync_available':
        await _onSyncAvailable?.call(data);
        break;
      case 'join_request':
        break;
      case 'pair_request':
        // Handled by system notification display, no code action needed
        break;
      default:
        if (kDebugMode) {
          debugPrint('PushNotificationService: unknown message type: $type');
        }
    }
  }
}
