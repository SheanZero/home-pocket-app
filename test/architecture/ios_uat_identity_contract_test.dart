import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HP-03 iOS UAT identity contract', () {
    test('keeps the production identity and provisions an isolated UAT flavor', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final podfile = File('ios/Podfile').readAsStringSync();
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      final uatEntitlements = File('ios/Runner/Runner-UAT.entitlements')
          .readAsStringSync();

      expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.sheanzero.happypocket.app;'));
      expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = com.sheanzero.happypocket.app.uat;'));
      expect(project, contains('PRODUCT_DISPLAY_NAME = "Happy Pocket UAT";'));
      expect(project, contains('HP_UAT_BUILD = YES;'));
      expect(project, contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner-UAT.entitlements;'));
      expect(project, contains('DEVELOPMENT_TEAM = 6Y64KR8RLP;'));

      for (final configuration in const ['Debug-uat', 'Profile-uat', 'Release-uat']) {
        expect(project, contains('name = $configuration;'));
        expect(podfile, contains("'$configuration' =>"));
      }

      expect(infoPlist, contains(r'<string>$(PRODUCT_DISPLAY_NAME)</string>'));
      expect(infoPlist, contains('<key>HPUATBuild</key>'));
      expect(infoPlist, contains(r'<string>$(HP_UAT_BUILD)</string>'));
      expect(uatEntitlements, contains('keychain-access-groups'));
      expect(
        uatEntitlements,
        contains(r'$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)'),
      );
      expect(uatEntitlements, isNot(contains('aps-environment')));
    });

    test('exposes a shared UAT scheme for Flutter device tests and profiles', () {
      final scheme = File(
        'ios/Runner.xcodeproj/xcshareddata/xcschemes/uat.xcscheme',
      ).readAsStringSync();

      expect(scheme, contains('buildConfiguration = "Debug-uat"'));
      expect(scheme, contains('buildConfiguration = "Profile-uat"'));
      expect(scheme, contains('buildConfiguration = "Release-uat"'));
      expect(scheme, contains('BlueprintName = "Runner"'));
    });

    test('does not let UAT request or register remote notifications', () {
      final appDelegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();

      expect(appDelegate, contains('private var isUatBuild: Bool'));
      expect(appDelegate, contains('guard !isUatBuild else {'));
      expect(appDelegate, contains('apns_unavailable_in_uat'));
      expect(appDelegate, contains('registerForRemoteNotifications()'));
    });

    test('does not bundle a Firebase configuration for either iOS identity', () {
      final firebaseConfigurations = Directory('ios/Runner')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('GoogleService-Info.plist'));

      expect(firebaseConfigurations, isEmpty);
    });
  });
}
