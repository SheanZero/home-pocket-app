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

  test('strict verification follows the evidence completion stage', () {
    final current = inputs();
    final candidateObserved = current['evidence']!
        .replaceFirst(
          '"completed_stage": "emulator"',
          '"completed_stage": "candidate"',
        )
        .replaceFirst('"compile": "PASS"', '"compile": "NOT_RUN"')
        .replaceFirst('"package": "PASS"', '"package": "NOT_RUN"')
        .replaceFirst('"emulator": "PASS"', '"emulator": "NOT_RUN"');
    expect(
      validate({...current, 'evidence': candidateObserved}, allowNotRun: false),
      isEmpty,
    );

    final dishonestCompile = candidateObserved.replaceFirst(
      '"completed_stage": "candidate"',
      '"completed_stage": "compile"',
    );
    expect(
      validate({...current, 'evidence': dishonestCompile}, allowNotRun: false),
      contains('compile result must be PASS at compile stage'),
    );
  });

  test('observed hold names every blocker and a non-circular exit gate', () {
    final current = inputs();
    final baseline = jsonDecode(current['baseline']!) as Map<String, dynamic>;
    final lanePolicy =
        (baseline['lanes'] as Map<String, dynamic>)['phase61_android']
            as Map<String, dynamic>;
    final reason = lanePolicy['compatibility_reason'] as String;
    final exitCondition = lanePolicy['exit_condition'] as String;

    expect(reason, contains('Flutter 3.44.8'));
    for (final plugin in <String>[
      'file_picker',
      'package_info_plus',
      'share_plus',
      'speech_to_text',
    ]) {
      expect(reason, contains(plugin));
    }
    expect(exitCondition, contains('Flutter 3.47'));
    expect(exitCondition, contains('Phase 59'));
    expect(
      current['evidence'],
      contains(
        'Flutter configuration restored the legacy built-in-Kotlin/new-DSL opt-outs.',
      ),
    );
  });

  test('final provenance rejects cross-plan, incomplete, and mixed evidence', () {
    final current = inputs();
    final cases = <String, String>{
      'source commit mismatch': current['evidence']!.replaceFirst(
        '"package_source_commit": "e6b5cbf672e885dcbb4446621cc20e7ca05aa058"',
        '"package_source_commit": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"',
      ),
      'missing timestamp': current['evidence']!.replaceFirst(
        '"package_completed_utc": "2026-08-10T00:43:09.500889Z",',
        '',
      ),
      'missing command exit': current['evidence']!.replaceFirst(
        '"exit_code": 0,',
        '',
      ),
      'missing artifact hash': current['evidence']!.replaceFirst(
        '"sha256": "2c8cebace1d09a69d60f334aacc158ed83ea676a7bc89299cc78a5049d97905e",',
        '"sha256": "",',
      ),
      'incomplete matrix': current['evidence']!.replaceFirst(
        '"file": "device_critical_journey_test.dart",',
        '"file": "missing_test.dart",',
      ),
    };

    for (final entry in cases.entries) {
      expect(
        validate({...current, 'evidence': entry.value}),
        isNotEmpty,
        reason: entry.key,
      );
    }
  });

  test('active Android documents keep arm64 primary and x86 supplemental', () {
    final validation = File(
      '.planning/phases/61-android-toolchain-emulator-lane/61-VALIDATION.md',
    ).readAsStringSync();
    final compatibility = File(
      'docs/testing/DEPENDENCY_COMPATIBILITY.md',
    ).readAsStringSync();

    for (final document in [validation, compatibility]) {
      expect(document, contains('arm64-v8a'));
      expect(document, contains('supplemental'));
      expect(document, isNot(contains('AND-04 remains blocked')));
    }
  });
}
