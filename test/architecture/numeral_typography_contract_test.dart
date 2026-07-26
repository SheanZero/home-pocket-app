import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Protects the app-wide numeric-glyph contract.
///
/// Production text inherits the numeral-only font family from [AppTheme].
/// Feature-local `fontFamily` declarations would bypass that contract, while
/// a full Roboto Mono asset would also turn Latin prose monospaced instead of
/// limiting the change to numbers and numeric symbols.
void main() {
  test('production code has no feature-local font-family override', () {
    final hits = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File ||
          !entity.path.endsWith('.dart') ||
          entity.path.endsWith('app_text_styles.dart')) {
        continue;
      }

      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (lines[index].contains('fontFamily:')) {
          hits.add('${entity.path}:${index + 1}: ${lines[index].trim()}');
        }
      }
    }

    expect(
      hits,
      isEmpty,
      reason:
          'All production text must inherit the numeral-only family from '
          'AppTheme:\n${hits.join("\n")}',
    );
  });

  test('pubspec bundles only the numeric Roboto Mono subset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final subset = File('assets/fonts/RobotoMonoNumerals-Variable.ttf');
    final fullFont = File('assets/fonts/RobotoMono-Variable.ttf');

    expect(subset.existsSync(), isTrue);
    expect(
      subset.lengthSync(),
      lessThan(30 * 1024),
      reason: 'The numeral font must remain a glyph subset, not the full face.',
    );
    expect(fullFont.existsSync(), isFalse);
    expect(pubspec, contains('family: RobotoMonoNumerals'));
    expect(pubspec, contains('assets/fonts/RobotoMonoNumerals-Variable.ttf'));
  });
}
