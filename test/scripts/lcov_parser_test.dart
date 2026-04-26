// test/scripts/lcov_parser_test.dart
// Unit tests for scripts/coverage/lcov_parser.dart.
//
// Covers:
//   - happy-path SF/DA/LF/LH parsing (multi-record fixture)
//   - LF==0 fallback to DA-line recomputation
//   - linesTotal==0 → 100% (avoid divide-by-zero, very_good_coverage convention)
//   - malformed-record handling (no end_of_record at EOF)
//   - isGeneratedPath predicate over .g.dart / .freezed.dart / .mocks.dart /
//     lib/generated/ (and .drift.dart if the codebase uses any — runtime probe
//     in Plan 02-01 found none, so this test does not assert .drift.dart)
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/coverage/lcov_parser.dart';

const _twoRecordFixture = '''
SF:lib/core/theme/app_theme.dart
DA:6,2
DA:17,1
DA:20,1
DA:22,1
DA:27,0
DA:33,0
DA:38,0
DA:41,0
DA:43,0
LF:9
LH:4
end_of_record
SF:lib/features/accounting/domain/models/category.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
''';

const _missingLfLhFixture = '''
SF:lib/foo.dart
DA:1,1
DA:2,0
DA:3,1
end_of_record
''';

const _zeroLfFixture = '''
SF:lib/empty.dart
LF:0
LH:0
end_of_record
''';

const _malformedNoEorFixture = '''
SF:lib/orphan.dart
DA:1,1
DA:2,1
LF:2
LH:2
''';

void main() {
  group('parseLcov', () {
    test('parses two records with LF/LH happy path', () {
      final records = parseLcov(_twoRecordFixture);
      expect(records.length, equals(2));

      final first = records[0];
      expect(first.filePath, equals('lib/core/theme/app_theme.dart'));
      expect(first.linesCovered, equals(4));
      expect(first.linesTotal, equals(9));
      expect(first.percentage, closeTo(44.44, 0.01));

      final second = records[1];
      expect(
        second.filePath,
        equals('lib/features/accounting/domain/models/category.dart'),
      );
      expect(second.linesCovered, equals(2));
      expect(second.linesTotal, equals(2));
      expect(second.percentage, equals(100.0));
    });

    test('falls back to DA recomputation when LF/LH are missing', () {
      final records = parseLcov(_missingLfLhFixture);
      expect(records.length, equals(1));
      expect(records.first.linesTotal, equals(3));
      expect(records.first.linesCovered, equals(2));
      expect(records.first.percentage, closeTo(66.67, 0.01));
    });

    test('falls back to DA recomputation when LF=0', () {
      final records = parseLcov('''
SF:lib/foo.dart
DA:1,1
DA:2,0
DA:3,1
LF:0
LH:0
end_of_record
''');
      expect(records.length, equals(1));
      expect(records.first.linesTotal, equals(3));
      expect(records.first.linesCovered, equals(2));
    });

    test('linesTotal==0 yields percentage 100.0 (no divide-by-zero)', () {
      final records = parseLcov(_zeroLfFixture);
      expect(records.length, equals(1));
      expect(records.first.linesTotal, equals(0));
      expect(records.first.linesCovered, equals(0));
      expect(records.first.percentage, equals(100.0));
    });

    test('skips malformed record (no end_of_record at EOF)', () {
      final records = parseLcov(_malformedNoEorFixture);
      expect(records, isEmpty);
    });

    test('recomputeFromDa=true ignores LF/LH and uses DA counts', () {
      // LF/LH say 4/9, but DA lines say 2/3. With recomputeFromDa=true the
      // parser MUST trust DA.
      final records = parseLcov('''
SF:lib/foo.dart
DA:1,1
DA:2,0
DA:3,1
LF:9
LH:4
end_of_record
''', recomputeFromDa: true);
      expect(records.length, equals(1));
      expect(records.first.linesTotal, equals(3));
      expect(records.first.linesCovered, equals(2));
    });

    test('LcovRecord.toJson uses snake_case keys', () {
      final records = parseLcov(_twoRecordFixture);
      final json = records.first.toJson();
      expect(
        json.keys.toSet(),
        equals({'file_path', 'lines_covered', 'lines_total', 'percentage'}),
      );
      expect(json['file_path'], equals('lib/core/theme/app_theme.dart'));
      expect(json['lines_covered'], equals(4));
      expect(json['lines_total'], equals(9));
    });
  });

  group('isGeneratedPath', () {
    test('returns true for .g.dart suffix', () {
      expect(isGeneratedPath('lib/foo.g.dart'), isTrue);
    });

    test('returns true for .freezed.dart suffix', () {
      expect(isGeneratedPath('lib/foo.freezed.dart'), isTrue);
    });

    test('returns true for .mocks.dart suffix', () {
      expect(isGeneratedPath('test/foo.mocks.dart'), isTrue);
    });

    test('returns true for lib/generated/ contents', () {
      expect(isGeneratedPath('lib/generated/strings.dart'), isTrue);
    });

    test('returns false for ordinary lib/ paths', () {
      expect(isGeneratedPath('lib/foo.dart'), isFalse);
      expect(isGeneratedPath('lib/features/bar.dart'), isFalse);
    });
  });
}
