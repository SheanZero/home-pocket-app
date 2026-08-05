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
}
