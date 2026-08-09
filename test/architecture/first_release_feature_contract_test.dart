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

  test('MVP removes notification packages and native auto-registration', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final package in <String>[
      'firebase_core:',
      'firebase_messaging:',
      'flutter_local_notifications:',
    ]) {
      expect(pubspec, isNot(contains(package)), reason: package);
    }

    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(androidManifest, isNot(contains('POST_NOTIFICATIONS')));
    expect(androidManifest, isNot(contains('firebase_')));

    final androidBuild = File('android/app/build.gradle.kts').readAsStringSync();
    expect(androidBuild, isNot(contains('com.google.firebase')));

    final iosInfo = File('ios/Runner/Info.plist').readAsStringSync();
    expect(iosInfo, isNot(contains('FirebaseMessagingAutoInitEnabled')));

    final entitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    expect(entitlements, isNot(contains('aps-environment')));
  });

  test('MVP has no notification client or registration path', () {
    final providers = File(
      'lib/application/family_sync/repository_providers.dart',
    ).readAsStringSync();
    expect(providers, isNot(contains('Firebase')));
    expect(providers, isNot(contains('ApnsPushMessagingClient')));
    final service = File(
      'lib/infrastructure/sync/push_notification_service.dart',
    ).readAsStringSync();
    expect(service, contains('DisabledPushMessagingClient'));
    expect(service, isNot(contains('FirebaseMessaging')));
    expect(service, isNot(contains('FlutterLocalNotificationsPlugin')));

    final main = File('lib/main.dart').readAsStringSync();
    expect(main, isNot(contains('connectPushNotifications')));
    expect(main, isNot(contains('pushNotificationServiceProvider')));

    final settingsProviders = File(
      'lib/features/settings/presentation/providers/repository_providers.dart',
    ).readAsStringSync();
    expect(settingsProviders, isNot(contains('pushNotificationServiceProvider')));
    expect(settingsProviders, isNot(contains('registerCurrentToken')));

    final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(appDelegate, isNot(contains('UserNotifications')));
    expect(appDelegate, isNot(contains('registerForRemoteNotifications')));
  });
}
