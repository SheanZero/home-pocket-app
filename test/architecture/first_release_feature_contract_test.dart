import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/config/legal_urls.dart';
import 'package:home_pocket/core/config/release_features.dart';

void main() {
  test('first release keeps push notifications and sponsorship disabled', () {
    expect(ReleaseFeatures.pushNotifications, isFalse);
    expect(ReleaseFeatures.sponsorship, isFalse);
  });

  test('legal links use the canonical public routes', () {
    expect(LegalUrls.privacy, 'https://happypocket.app/privacy');
    expect(LegalUrls.terms, 'https://happypocket.app/terms');
    expect(LegalUrls.tokusho, 'https://happypocket.app/tokusho');
  });

  test('native push auto-registration is disabled for the first release', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(androidManifest, contains('firebase_messaging_auto_init_enabled'));
    expect(androidManifest, contains('firebase_analytics_collection_enabled'));
    expect(androidManifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(androidManifest, contains('tools:node="remove"'));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, contains('FirebaseMessagingAutoInitEnabled'));
    expect(iosInfo, isNot(contains('<string>remote-notification</string>')));

    final entitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    expect(entitlements, isNot(contains('aps-environment')));
  });

  test('first release preserves custom iOS APNs and Android Firebase FCM', () {
    final providers = File(
      'lib/application/family_sync/repository_providers.dart',
    ).readAsStringSync();
    expect(providers, contains('Platform.isIOS'));
    expect(providers, contains('? ApnsPushMessagingClient()'));
    expect(providers, contains(': FirebasePushMessagingClient()'));
    expect(
      providers,
      contains(
        'firebaseInitializer: Platform.isIOS ? null : Firebase.initializeApp',
      ),
    );
    expect(
      providers,
      contains("pushPlatform: Platform.isIOS ? 'apns' : 'fcm'"),
    );

    final service = File(
      'lib/infrastructure/sync/push_notification_service.dart',
    ).readAsStringSync();
    expect(service, contains('Future<String?> _runInitialization()'));
    expect(service, contains('await _localNotificationClient.initialize('));
    expect(service, contains('await _messagingClient.requestPermission()'));
    expect(service, contains('_initialized = true;'));
    expect(service, contains('await _messagingClient.getInitialMessage()'));
  });
}
