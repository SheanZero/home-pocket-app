import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _localizedInfoPlistKeys = <String>{
  'CFBundleDisplayName',
  'NSMicrophoneUsageDescription',
  'NSSpeechRecognitionUsageDescription',
  'NSFaceIDUsageDescription',
};

const _localizedFiles = <String, String>{
  'en': 'ios/Runner/en.lproj/InfoPlist.strings',
  'ja': 'ios/Runner/ja.lproj/InfoPlist.strings',
  'zh-Hans': 'ios/Runner/zh-Hans.lproj/InfoPlist.strings',
};

const _expectedDisplayNames = <String, String>{
  'en': 'Happy Pocket',
  'ja': 'Happy Pocket',
  'zh-Hans': 'Happy Pocket',
};

void main() {
  group('iOS InfoPlist localization contract', () {
    for (final entry in _localizedFiles.entries) {
      test('${entry.key} has every localized permission key', () {
        final values = _parseStringsFile(File(entry.value));

        expect(values.keys.toSet(), _localizedInfoPlistKeys);
        expect(values['CFBundleDisplayName'], _expectedDisplayNames[entry.key]);
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
