import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ci_golden_comparator.dart';

void main() {
  group('BaselineExistenceGoldenComparator', () {
    late Directory tempDir;
    late BaselineExistenceGoldenComparator comparator;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('golden_comparator_test');
      comparator = BaselineExistenceGoldenComparator(tempDir.uri);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'compare returns true when baseline exists, regardless of pixels',
      () async {
        final goldenDir = Directory('${tempDir.path}/goldens')..createSync();
        File('${goldenDir.path}/widget.png').writeAsBytesSync([1, 2, 3]);

        final result = await comparator.compare(
          Uint8List.fromList([9, 9, 9]),
          Uri.parse('goldens/widget.png'),
        );

        expect(result, isTrue);
      },
    );

    test('compare throws TestFailure when baseline is missing', () async {
      await expectLater(
        comparator.compare(
          Uint8List.fromList([1]),
          Uri.parse('goldens/missing.png'),
        ),
        throwsA(
          isA<TestFailure>().having(
            (f) => f.message,
            'message',
            contains('missing.png'),
          ),
        ),
      );
    });

    test(
      'update throws UnsupportedError (baselines are macOS-rendered)',
      () async {
        await expectLater(
          comparator.update(
            Uri.parse('goldens/widget.png'),
            Uint8List.fromList([1]),
          ),
          throwsUnsupportedError,
        );
      },
    );
  });
}
