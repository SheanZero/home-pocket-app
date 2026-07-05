import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/widgets/onboarding_float_decor.dart';

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
  // The onboarding intro decor (FloatyLoop/DriftPetal) loops repeating
  // tickers on-device. Under flutter_test those tickers never settle and
  // would hang every pumpAndSettle that crosses the onboarding gate
  // (onboarding widget tests AND main_characterization_smoke_test), so the
  // decor is forced static suite-wide.
  OnboardingFloatDecor.animationsEnabled = false;
  await testMain();
}
