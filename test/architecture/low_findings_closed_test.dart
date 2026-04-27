import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: Phase 6 LOW audit findings must be closed.
///
/// Run: flutter test test/architecture/low_findings_closed_test.dart

void main() {
  group('LOW audit closure gate', () {
    test('issues.json has no open LOW findings', () {
      final catalogue =
          jsonDecode(File('.planning/audit/issues.json').readAsStringSync())
              as Map<String, Object?>;
      final findings = catalogue['findings']! as List<Object?>;

      final openLowFindings = findings
          .whereType<Map<String, Object?>>()
          .where(
            (finding) =>
                finding['severity'] == 'LOW' && finding['status'] == 'open',
          )
          .map((finding) => finding['id'])
          .toList();

      expect(
        openLowFindings,
        isEmpty,
        reason: 'Open LOW findings remain: $openLowFindings',
      );
    });
  });
}
