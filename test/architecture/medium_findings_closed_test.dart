import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: Phase 5 MEDIUM audit findings must be closed.
///
/// Run: flutter test test/architecture/medium_findings_closed_test.dart

void main() {
  group('MEDIUM audit closure gate', () {
    test('issues.json has no open MEDIUM findings', () {
      final catalogue =
          jsonDecode(File('.planning/audit/issues.json').readAsStringSync())
              as Map<String, Object?>;
      final findings = catalogue['findings']! as List<Object?>;

      final openMediumFindings = findings
          .whereType<Map<String, Object?>>()
          .where(
            (finding) =>
                finding['severity'] == 'MEDIUM' && finding['status'] == 'open',
          )
          .map((finding) => finding['id'])
          .toList();

      expect(
        openMediumFindings,
        isEmpty,
        reason: 'Open MEDIUM findings remain: $openMediumFindings',
      );
    });
  });
}
