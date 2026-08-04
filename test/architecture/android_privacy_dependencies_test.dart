import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Prevents analytics/tracking dependencies and advertising-ID permissions
/// from silently re-entering the privacy-focused Android app.
///
/// Firebase Core and Firebase Messaging remain allowed for initialization and
/// push delivery. This contract only rejects Analytics and advertising-ID
/// access, which are not product capabilities and contradict the bundled
/// privacy policy.
void main() {
  test('Android sources do not opt into analytics or advertising IDs', () {
    final inspectedFiles = <File>[
      File('pubspec.yaml'),
      File('pubspec.lock'),
      ...Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (file) =>
                file.path.endsWith('.gradle') ||
                file.path.endsWith('.gradle.kts') ||
                file.path.endsWith('AndroidManifest.xml'),
          ),
    ];

    final forbiddenPatterns = <RegExp>[
      RegExp(r'firebase[-_:]analytics', caseSensitive: false),
      RegExp(r'com\.google\.android\.gms\.permission\.AD_ID'),
      RegExp(r'android\.permission\.ACCESS_ADSERVICES_AD_ID'),
      RegExp(r'android\.permission\.ACCESS_ADSERVICES_ATTRIBUTION'),
    ];

    final findings = <String>[];
    for (final file in inspectedFiles) {
      final content = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        if (pattern.hasMatch(content)) {
          findings.add('${file.path}: ${pattern.pattern}');
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Home Pocket does not use behavioral analytics or advertising IDs. '
          'Remove these dependencies/permissions or amend the privacy contract '
          'before shipping:\n${findings.join('\n')}',
    );
  });
}
