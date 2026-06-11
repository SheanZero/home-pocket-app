import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'helpers/ci_golden_comparator.dart';

/// Global test bootstrap (applies to every test under test/).
///
/// Golden pixel comparison is platform-gated: baselines are rendered on
/// macOS, so exact comparison only runs there. On non-macOS (CI runs
/// ubuntu-latest) golden tests still execute — keeping widget coverage and
/// crash detection — but only assert that the committed baseline exists.
/// See [BaselineExistenceGoldenComparator] for rationale and observed diffs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (!Platform.isMacOS && comparator is LocalFileComparator) {
    goldenFileComparator = BaselineExistenceGoldenComparator(
      comparator.basedir,
    );
  }
  await testMain();
}
