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
  });
}
