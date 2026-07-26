import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the production numeral subset for visual tests.
///
/// Flutter widget tests otherwise fall back to the deterministic test font,
/// which would let golden tests pass without ever rendering the app's bundled
/// numeric glyphs.
Future<void> loadNumeralFont() async {
  final loader = FontLoader('RobotoMonoNumerals')
    ..addFont(rootBundle.load('assets/fonts/RobotoMonoNumerals-Variable.ttf'));
  await loader.load();
}
