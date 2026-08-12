import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _localizedInfoPlistKeys = <String>{
  'NSCameraUsageDescription',
  'NSLocationWhenInUseUsageDescription',
  'NSMicrophoneUsageDescription',
  'NSPhotoLibraryUsageDescription',
  'NSSpeechRecognitionUsageDescription',
  'NSFaceIDUsageDescription',
};

const _localizedFiles = <String, String>{
  'en': 'ios/Runner/en.lproj/InfoPlist.strings',
  'ja': 'ios/Runner/ja.lproj/InfoPlist.strings',
  'zh-Hans': 'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
};

void main() {
  group('iOS InfoPlist localization contract', () {
    for (final entry in _localizedFiles.entries) {
      test('${entry.key} has every localized permission key', () {
        final values = _parseStringsFile(File(entry.value));

        expect(values.keys.toSet(), _localizedInfoPlistKeys);
        for (final key in _localizedInfoPlistKeys) {
          expect(values[key], isNotEmpty, reason: '${entry.key}: $key');
        }
      });
    }

    test('Xcode bundles InfoPlist.strings for all supported regions', () {
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();

      expect(project, contains('InfoPlist.strings in Resources'));
      expect(project, contains('en.lproj/InfoPlist.strings'));
      expect(project, contains('ja.lproj/InfoPlist.strings'));
      expect(project, contains('zh-Hans.lproj/InfoPlist.strings'));
      expect(project, contains('name = InfoPlist.strings;'));

      final knownRegions = RegExp(
        r'knownRegions = \(([\s\S]*?)\);',
      ).firstMatch(project)?.group(1);
      expect(knownRegions, isNotNull);
      expect(knownRegions, contains('en,'));
      expect(knownRegions, contains('ja,'));
      expect(knownRegions, contains('"zh-Hans",'));
    });

    test(
      'privacy configuration is bundled and declares only evidenced data',
      () {
        final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
        expect(
          infoPlist,
          contains('<key>NSPhotoLibraryUsageDescription</key>'),
        );
        expect(infoPlist, contains('<key>NSCameraUsageDescription</key>'));
        expect(
          infoPlist,
          contains('<key>NSLocationWhenInUseUsageDescription</key>'),
        );
        expect(
          infoPlist,
          isNot(contains('<key>NSPhotoLibraryAddUsageDescription</key>')),
        );

        final manifest = File('ios/Runner/PrivacyInfo.xcprivacy');
        expect(manifest.existsSync(), isTrue);
        final privacy = manifest.readAsStringSync();
        expect(privacy, contains('<key>NSPrivacyTracking</key>\n\t<false/>'));
        expect(
          privacy,
          contains('<key>NSPrivacyTrackingDomains</key>\n\t<array/>'),
        );
        expect(
          privacy,
          contains('<key>NSPrivacyAccessedAPITypes</key>\n\t<array/>'),
        );
        expect(privacy, contains('NSPrivacyCollectedDataTypeName'));
        expect(privacy, contains('NSPrivacyCollectedDataTypeUserID'));
        expect(privacy, contains('NSPrivacyCollectedDataTypeDeviceID'));
        expect(privacy, contains('NSPrivacyCollectedDataTypeOtherUserContent'));
        expect(
          privacy,
          isNot(contains('NSPrivacyCollectedDataTypePhotosorVideos')),
        );
        expect(
          privacy,
          isNot(contains('NSPrivacyCollectedDataTypePurchaseHistory')),
        );
        expect(
          privacy,
          isNot(contains('NSPrivacyCollectedDataTypeOtherFinancialInfo')),
        );

        final project = File(
          'ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();
        expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
        expect(project, contains('lastKnownFileType = text.xml;'));
        expect(project, contains('path = PrivacyInfo.xcprivacy;'));
      },
    );

    test('exports the HPB document type for the iOS file picker', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

      expect(infoPlist, contains('<key>UTExportedTypeDeclarations</key>'));
      expect(
        infoPlist,
        contains('<string>com.sheanzero.happypocket.backup</string>'),
      );
      expect(infoPlist, contains('<key>public.filename-extension</key>'));
      expect(infoPlist, contains('<string>hpb</string>'));
      expect(infoPlist, contains('<string>public.data</string>'));
    });
  });
}

Map<String, String> _parseStringsFile(File file) {
  expect(file.existsSync(), isTrue, reason: 'Missing ${file.path}');
  final contents = file.readAsStringSync();
  final entries = RegExp(
    r'^\s*"([^"]+)"\s*=\s*"([^"]*)";\s*$',
    multiLine: true,
  ).allMatches(contents);

  return <String, String>{
    for (final entry in entries) entry.group(1)!: entry.group(2)!,
  };
}
