import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verify_android_safety_lane.dart' as lane;

void main() {
  Map<String, String> inputs() => {
    'baseline': File('docs/testing/STABLE_BASELINE.json').readAsStringSync(),
    'settings': File('android/settings.gradle.kts').readAsStringSync(),
    'properties': File('android/gradle.properties').readAsStringSync(),
    'wrapper': File(
      'android/gradle/wrapper/gradle-wrapper.properties',
    ).readAsStringSync(),
    'app': File('android/app/build.gradle.kts').readAsStringSync(),
    'evidence': File(lane.evidencePath).readAsStringSync(),
  };

  List<String> validate(
    Map<String, String> input, {
    List<String>? legacyPlugins,
    bool allowNotRun = true,
  }) => lane.validateAndroidSafetyLane(
    baselineJson: input['baseline']!,
    settingsGradle: input['settings']!,
    gradleProperties: input['properties']!,
    gradleWrapper: input['wrapper']!,
    appBuildGradle: input['app']!,
    evidenceMarkdown: input['evidence']!,
    legacyKgpPlugins:
        legacyPlugins ?? lane.inventoryLegacyKgpPlugins(Directory.current),
    allowNotRun: allowNotRun,
  );

  test('the exact pre-probe hold graph is coherent', () {
    expect(validate(inputs()), isEmpty);
  });

  test('candidate metadata and hold components fail independently', () {
    final current = inputs();
    final staleCandidate = current['baseline']!.replaceFirst(
      '"production_stable_candidate": "9.3.1"',
      '"production_stable_candidate": "9.0.1"',
    );
    expect(
      validate({...current, 'baseline': staleCandidate}),
      contains('AGP candidate must be 9.3.1'),
    );
    expect(
      validate({
        ...current,
        'properties': current['properties']!.replaceFirst(
          'android.builtInKotlin=false',
          '',
        ),
      }),
      contains('hold must retain both Flutter legacy Kotlin/DSL flags'),
    );
    expect(
      validate({
        ...current,
        'wrapper': current['wrapper']!.replaceFirst('8.14', '9.5.0'),
      }),
      contains('hold wrapper must retain Gradle 8.14'),
    );
  });

  test('selected state rejects legacy app and plugin KGP', () {
    final current = inputs();
    final baseline = jsonDecode(current['baseline']!) as Map<String, dynamic>;
    final toolchains = baseline['toolchains'] as Map<String, dynamic>;
    (baseline['lanes'] as Map<String, dynamic>)['phase61_android']['decision'] =
        'selected';
    (toolchains['agp'] as Map<String, dynamic>)['selected_current'] = '9.3.1';
    (toolchains['gradle'] as Map<String, dynamic>)['selected_current'] =
        '9.5.0';

    final issues = validate({
      ...current,
      'baseline': const JsonEncoder.withIndent('  ').convert(baseline),
    });
    expect(issues, contains('selected lane must remove app legacy KGP'));
    expect(
      issues,
      contains('selected lane must have no resolved legacy KGP plugins'),
    );
  });

  test('resolved graph inventories known legacy KGP blockers', () {
    expect(
      lane.inventoryLegacyKgpPlugins(Directory.current),
      containsAll(<String>[
        'file_picker',
        'package_info_plus',
        'share_plus',
        'speech_to_text',
      ]),
    );
  });
}
