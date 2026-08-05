import 'dart:io';

import 'package:yaml/yaml.dart';

/// P2-04 compatibility contract for dependency versions that cannot be
/// upgraded independently without weakening SQLCipher or native builds.
List<String> validateDependencyCompatibility({
  required String pubspecYaml,
  required String lockYaml,
  required String androidSettings,
  required String androidAppBuild,
  required String androidProperties,
  required String gradleWrapper,
  required String podfile,
  required String podfileLock,
  required String xcodeProject,
  required String auditWorkflow,
  required String futureWorkflow,
}) {
  final issues = <String>[];
  final pubspec = _map(loadYaml(pubspecYaml));
  final dependencies = _map(pubspec['dependencies']);
  final devDependencies = _map(pubspec['dev_dependencies']);
  final lock = _map(loadYaml(lockYaml));
  final packages = _map(lock['packages']);

  void expectConstraint(String package, String expected) {
    final actual = (dependencies[package] ?? devDependencies[package])
        ?.toString();
    if (actual != expected) {
      issues.add('$package constraint must be $expected (found $actual)');
    }
  }

  void expectLocked(String package, String expected) {
    final actual = _map(packages[package])['version']?.toString();
    if (actual != expected) {
      issues.add('$package lock must be $expected (found $actual)');
    }
  }

  void expectText(String label, String contents, String marker) {
    if (!contents.contains(marker)) {
      issues.add('$label must contain: $marker');
    }
  }

  // Security lane: 0.7.0+eol contains no native SQLCipher library, and
  // sqlite3 3.x is not compatible with the current encrypted native path.
  expectConstraint('sqlcipher_flutter_libs', '^0.6.8');
  expectLocked('sqlcipher_flutter_libs', '0.6.8');
  expectConstraint('sqlite3', '^2.9.4');
  expectLocked('sqlite3', '2.9.4');
  if (dependencies.containsKey('sqlite3_flutter_libs') ||
      packages.containsKey('sqlite3_flutter_libs')) {
    issues.add(
      'sqlite3_flutter_libs conflicts with SQLCipher and is forbidden',
    );
  }

  // Stable native-plugin lane: these versions share win32 5.x. The newer
  // plus plugins require win32 6.x, which only file_picker 12 prereleases
  // currently support. Upgrade all four together after a stable release.
  expectConstraint('file_picker', '^11.0.3');
  expectLocked('file_picker', '11.0.3');
  expectConstraint('share_plus', '^12.0.2');
  expectLocked('share_plus', '12.0.2');
  expectConstraint('package_info_plus', '^9.0.1');
  expectLocked('package_info_plus', '9.0.1');
  expectLocked('win32', '5.15.0');

  // 7.4.0 was published from a beta line and changes the adapter API. Keep
  // the proven version exact until a compatible stable release is available.
  expectConstraint('speech_to_text', '7.3.0');
  expectLocked('speech_to_text', '7.3.0');
  expectConstraint('flutter_local_notifications', '^22.2.0');
  expectLocked('flutter_local_notifications', '22.2.0');

  // The architecture lint and code-generation toolchains are collectively
  // constrained by analyzer 8.x. Newer Riverpod and JSON releases require
  // analyzer 9+/13+, so they cannot be advanced independently.
  expectConstraint('flutter_riverpod', '^3.1.0');
  expectLocked('flutter_riverpod', '3.1.0');
  expectConstraint('riverpod_annotation', '^4.0.0');
  expectLocked('riverpod_annotation', '4.0.0');
  expectConstraint('json_annotation', '^4.9.0');
  expectLocked('json_annotation', '4.9.0');
  expectConstraint('json_serializable', '^6.9.4');
  expectLocked('json_serializable', '6.11.2');
  expectConstraint('riverpod_generator', '^4.0.0+1');
  expectLocked('riverpod_generator', '4.0.0+1');
  expectConstraint('riverpod_lint', '^3.1.0');
  expectLocked('riverpod_lint', '3.1.0');
  expectConstraint('custom_lint', '^0.8.1');
  expectLocked('custom_lint', '0.8.1');
  expectConstraint('import_guard_custom_lint', '^1.0.0');
  expectLocked('import_guard_custom_lint', '1.0.0');
  final analyzerVersion = _map(packages['analyzer'])['version']?.toString();
  if (analyzerVersion == null ||
      !RegExp(r'^8\.\d+\.\d+$').hasMatch(analyzerVersion)) {
    issues.add(
      'analyzer lock must stay on the verified 8.x line '
      '(found $analyzerVersion)',
    );
  }

  // Flutter 3.44 must remain on the legacy Android DSL. Flutter's official
  // migration guide requires Flutter 3.47+ before Built-in Kotlin is enabled.
  expectText(
    'android/gradle.properties',
    androidProperties,
    'android.builtInKotlin=false',
  );
  expectText(
    'android/gradle.properties',
    androidProperties,
    'android.newDsl=false',
  );
  expectText(
    'android/settings.gradle.kts',
    androidSettings,
    'id("com.android.application") version "8.11.1"',
  );
  expectText(
    'android/settings.gradle.kts',
    androidSettings,
    'id("org.jetbrains.kotlin.android") version "2.2.20"',
  );
  expectText(
    'android/app/build.gradle.kts',
    androidAppBuild,
    'id("kotlin-android")',
  );
  expectText('Gradle wrapper', gradleWrapper, 'gradle-8.14-all.zip');

  // iOS intentionally uses Flutter SwiftPM plus a CocoaPods fallback only for
  // SQLCipher. The linker strip prevents system sqlite3 from winning symbols.
  if (pubspecYaml.contains('enable-swift-package-manager: false')) {
    issues.add('Swift Package Manager must stay enabled for supported plugins');
  }
  expectText(
    'Xcode project',
    xcodeProject,
    'FlutterGeneratedPluginSwiftPackage',
  );
  expectText('ios/Podfile.lock', podfileLock, 'SQLCipher (4.10.0)');
  expectText('ios/Podfile', podfile, 'original.gsub');
  expectText('ios/Podfile', podfile, 'sqlite3');
  expectText('ios/Podfile', podfile, 'stripped');

  // Make removal of either the stable blocking contract or future beta probe
  // visible in ordinary host tests.
  expectText(
    'audit workflow',
    auditWorkflow,
    'dart run scripts/dependency_compatibility.dart',
  );
  if (auditWorkflow.contains('Verify analyzer pin (smoke check)') ||
      auditWorkflow.contains('analyzer 7.x confirmed') ||
      auditWorkflow.contains('FUTURE-TOOL-01 readiness')) {
    issues.add(
      'audit workflow must use the blocking dependency compatibility contract '
      'instead of the legacy analyzer 7.x smoke check',
    );
  }
  expectText('future workflow', futureWorkflow, 'channel: beta');
  expectText('future workflow', futureWorkflow, 'flutter build apk --debug');
  expectText(
    'future workflow',
    futureWorkflow,
    'flutter build ios --simulator --debug',
  );

  return issues;
}

Map<Object?, Object?> _map(Object? value) {
  return value is Map ? value.cast<Object?, Object?>() : const {};
}

void main() {
  String read(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('[dependency-compat] ERROR: missing $path');
      exitCode = 1;
      return '';
    }
    return file.readAsStringSync();
  }

  final issues = validateDependencyCompatibility(
    pubspecYaml: read('pubspec.yaml'),
    lockYaml: read('pubspec.lock'),
    androidSettings: read('android/settings.gradle.kts'),
    androidAppBuild: read('android/app/build.gradle.kts'),
    androidProperties: read('android/gradle.properties'),
    gradleWrapper: read('android/gradle/wrapper/gradle-wrapper.properties'),
    podfile: read('ios/Podfile'),
    podfileLock: read('ios/Podfile.lock'),
    xcodeProject: read('ios/Runner.xcodeproj/project.pbxproj'),
    auditWorkflow: read('.github/workflows/audit.yml'),
    futureWorkflow: read('.github/workflows/flutter-future-compat.yml'),
  );

  if (issues.isNotEmpty) {
    stderr.writeln('[dependency-compat] FAIL (${issues.length} issue(s))');
    for (final issue in issues) {
      stderr.writeln('  - $issue');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('[dependency-compat] PASS');
  stdout.writeln('  SQLCipher 0.6.8 / sqlite3 2.9.4 / pod 4.10.0');
  stdout.writeln('  stable file/share/package-info/win32 group aligned');
  stdout.writeln(
    '  Flutter 3.44 Android legacy flags and future beta probes wired',
  );
}
