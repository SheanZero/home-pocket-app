// Phase 62 makes release_gate.dart the only blocking CI verdict authority.
// Supplemental audit scanners may preserve diagnostic artifacts but cannot
// soften, duplicate, or replace the host release-gate result.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String? _jobSource(String workflow, String jobName) {
  final start = RegExp(
    '^  ${RegExp.escape(jobName)}:\\n',
    multiLine: true,
  ).firstMatch(workflow);
  if (start == null) return null;
  Match? next;
  for (final match in RegExp(
    r'^  [a-z][a-z0-9-]*:\n',
    multiLine: true,
  ).allMatches(workflow)) {
    if (match.start >= start.end) {
      next = match;
      break;
    }
  }
  return workflow.substring(start.end, next?.start ?? workflow.length);
}

void main() {
  group('audit.yml release-authority invariants', () {
    const path = '.github/workflows/audit.yml';
    late String content;

    setUpAll(() {
      final file = File(path);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'audit.yml must exist at $path',
      );
      content = file.readAsStringSync();
    });

    test('top-level warning declares the sole Phase 62 authority', () {
      final nameIndex = content.indexOf('name: audit');
      expect(nameIndex, greaterThan(0));
      final preamble = content.substring(0, nameIndex);
      expect(preamble, contains('Phase 62'));
      expect(preamble, contains('release_gate.dart'));
      expect(preamble, contains('only pass/fail authority'));
    });

    test(
      'release-gate host invokes one fail-closed authority after Stable setup',
      () {
        final host = _jobSource(content, 'release-gate-host');
        expect(
          host,
          isNotNull,
          reason: 'blocking release-gate-host job is required',
        );
        expect(host, contains('uses: actions/checkout@v4'));
        expect(host, contains('flutter-version: 3.44.8'));
        expect(
          host,
          contains('dart run scripts/release_gate.dart --scope=host'),
        );
        expect(host, isNot(contains('continue-on-error: true')));
        expect(host, isNot(contains('|| true')));
        expect(
          host,
          isNot(contains('bash scripts/verify_codegen_reproducibility.sh')),
        );
        expect(host, isNot(contains('dart run import_lint')));
      },
    );

    test('no pull-request-only guard lets direct main bypass the authority', () {
      final regexes = [
        RegExp(
          r'''if:\s*\$\{\{\s*github\.event_name\s*==\s*['"]pull_request['"]\s*\}\}''',
        ),
        RegExp(r'''if:\s*github\.event_name\s*==\s*['"]pull_request['"]'''),
      ];
      for (final regex in regexes) {
        expect(regex.allMatches(content), isEmpty);
      }
    });

    test(
      'supplemental scanners wait for the host authority and lock dependencies',
      () {
        final scanners = _jobSource(content, 'audit-scanners');
        expect(
          scanners,
          isNotNull,
          reason: 'supplemental audit scanner job is required',
        );
        expect(scanners, contains('needs: release-gate-host'));
        expect(scanners, contains('flutter pub get --enforce-lockfile'));
        expect(scanners, contains('continue-on-error: true'));
        expect(scanners, contains('actions/upload-artifact@v4'));
        expect(scanners, contains('.planning/audit/issues.json'));
      },
    );
  });
}
