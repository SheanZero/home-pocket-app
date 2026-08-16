// Contract tests for the repository-owned structural duplication audit.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/duplication.dart' as duplication;

void main() {
  group('duplication audit', () {
    late Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('duplication_audit_test_');
      Directory('${temp.path}/lib').createSync(recursive: true);
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('finds an exact sixteen-line structural clone across Dart files', () {
      const clone = '''
  final subtotal = price * quantity;
  final discount = subtotal * discountRate;
  final taxable = subtotal - discount;
  final tax = taxable * taxRate;
  final total = taxable + tax;
  final rounded = total.roundToDouble();
  final capped = rounded.clamp(0, maxTotal).toDouble();
  final result = capped + serviceFee;
  if (result < 0) {
    throw StateError('negative total');
  }
  final formatted = result.toStringAsFixed(2);
  if (formatted.isEmpty) {
    throw StateError('missing total');
  }
  return result;
''';
      File(
        '${temp.path}/lib/first.dart',
      ).writeAsStringSync('double first() {\n$clone}\n');
      File(
        '${temp.path}/lib/second.dart',
      ).writeAsStringSync('double second() {\n$clone}\n');

      final envelope = duplication.buildDuplicationAuditEnvelope(
        sourcePath: '${temp.path}/lib',
        projectRoot: temp.path,
        generatedAt: DateTime.utc(2026, 8, 6),
      );

      expect(envelope['tool_source'], 'owned_duplication_detector');
      expect(envelope['scan_state'], 'ran');
      expect((envelope['detector'] as Map)['scope'], 'lib');
      final findings = (envelope['findings'] as List).cast<Map>();
      expect(findings, hasLength(1));
      expect(findings.single['category'], 'redundant_code');
      expect(findings.single['file_path'], 'lib/second.dart');
      expect(findings.single['line_start'], 2);
      expect(findings.single['tool_source'], 'owned_duplication_detector');
    });

    test('does not report shorter common snippets', () {
      const snippet = '''
  final subtotal = price * quantity;
  return subtotal;
''';
      File(
        '${temp.path}/lib/first.dart',
      ).writeAsStringSync('double first() {\n$snippet}\n');
      File(
        '${temp.path}/lib/second.dart',
      ).writeAsStringSync('double second() {\n$snippet}\n');

      final envelope = duplication.buildDuplicationAuditEnvelope(
        sourcePath: '${temp.path}/lib',
        projectRoot: temp.path,
        generatedAt: DateTime.utc(2026, 8, 6),
      );

      expect(envelope['scan_state'], 'ran');
      expect(envelope['findings'], isEmpty);
    });

    test(
      'uses the real meaningful window end and clusters overlapping clones',
      () {
        const clone = '''
  final a = 1; // ignored comment

  // ignored comment
  final b = 2;
  final c = 3;
  final d = 4;
  final e = 5;
  final f = 6;
  final g = 7;
  final h = 8;
  final i = 9;
  final j = 10;
  final k = 11;
  final l = 12;
  final m = 13;
  final n = 14;
  final o = 15;
  final p = 16;
  final q = 17;
''';
        for (final name in ['first', 'second', 'third']) {
          File(
            '${temp.path}/lib/$name.dart',
          ).writeAsStringSync('double $name() {\n$clone\n  return 0;\n}');
        }

        final envelope = duplication.buildDuplicationAuditEnvelope(
          sourcePath: '${temp.path}/lib',
          projectRoot: temp.path,
          generatedAt: DateTime.utc(2026, 8, 6),
        );

        final findings = (envelope['findings'] as List).cast<Map>();
        // Three files give three pairs, not one pair and not one per overlap.
        expect(findings, hasLength(3));
        final second = findings.singleWhere(
          (finding) => finding['file_path'] == 'lib/second.dart',
        );
        expect(second['line_start'], 2);
        // The contiguous clone reaches the physical `return` line after the
        // ignored blank/comment lines; it must not be lineStart + 15.
        expect(second['line_end'], 23);
        expect(second['rationale'], contains('Fingerprint:'));
      },
    );

    test('accepts only an exact fingerprint and re-reports source drift', () {
      const clone = '''
  final a = 1;
  final b = 2;
  final c = 3;
  final d = 4;
  final e = 5;
  final f = 6;
  final g = 7;
  final h = 8;
  final i = 9;
  final j = 10;
  final k = 11;
  final l = 12;
  final m = 13;
  final n = 14;
  final o = 15;
  final p = 16;
''';
      for (final name in ['first', 'second']) {
        File(
          '${temp.path}/lib/$name.dart',
        ).writeAsStringSync('double $name() {\n$clone\n  return 0;\n}');
      }
      final initial = duplication.buildDuplicationAuditEnvelope(
        sourcePath: '${temp.path}/lib',
        projectRoot: temp.path,
      );
      final rationale =
          (initial['findings'] as List).single['rationale'] as String;
      final fingerprint = RegExp(
        r'Fingerprint: ([0-9a-f]+)',
      ).firstMatch(rationale)![1]!;
      final audit = Directory('${temp.path}/tool/audit')
        ..createSync(recursive: true);
      File('${audit.path}/duplication_allowlist.json').writeAsStringSync('''
{
  "accepted": [
    {
      "files": ["lib/first.dart", "lib/second.dart"],
      "fingerprint": "$fingerprint",
      "rationale": "fixture false positive"
    }
  ]
}
''');

      final accepted = duplication.buildDuplicationAuditEnvelope(
        sourcePath: '${temp.path}/lib',
        projectRoot: temp.path,
      );
      expect((accepted['findings'] as List).single['status'], 'accepted');

      for (final name in ['first', 'second']) {
        final file = File('${temp.path}/lib/$name.dart');
        file.writeAsStringSync(
          file.readAsStringSync().replaceFirst('final a = 1', 'final a = 99'),
        );
      }
      final drifted = duplication.buildDuplicationAuditEnvelope(
        sourcePath: '${temp.path}/lib',
        projectRoot: temp.path,
      );
      expect((drifted['findings'] as List).single['status'], 'open');
    });
  });
}
