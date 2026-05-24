import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: non-generated source files must not keep stale analyzer
/// suppressions.
///
/// Run: flutter test test/architecture/stale_suppressions_scan_test.dart

const approvedSuppressions = <String, String>{
  // Phase 20 corpus accuracy reporters — print() is the deliberate per-locale
  // accuracy summary surface per RESEARCH §Validation Architecture; the
  // printOnFailure() ignore guards against any analyzer pass that treats the
  // identifier as print()-adjacent. Keep grouped (zh + ja, mirrored layout).
  'test/integration/voice/voice_corpus_zh_test.dart:64':
      'printOnFailure() reporter for per-case soft failures',
  'test/integration/voice/voice_corpus_zh_test.dart:76':
      'print() accuracy banner top',
  'test/integration/voice/voice_corpus_zh_test.dart:78':
      'print() accuracy summary line',
  'test/integration/voice/voice_corpus_zh_test.dart:80':
      'print() accuracy banner bottom',
  'test/integration/voice/voice_corpus_ja_test.dart:64':
      'printOnFailure() reporter for per-case soft failures',
  'test/integration/voice/voice_corpus_ja_test.dart:76':
      'print() accuracy banner top',
  'test/integration/voice/voice_corpus_ja_test.dart:78':
      'print() accuracy summary line',
  'test/integration/voice/voice_corpus_ja_test.dart:80':
      'print() accuracy banner bottom',
  // Phase 21 voice category corpus accuracy reporters — same rationale as
  // Phase 20 (per-locale accuracy summary surface). Keep grouped (zh + ja,
  // mirrored layout).
  'test/integration/voice/voice_category_corpus_zh_test.dart:118':
      'printOnFailure() reporter for per-case soft failures',
  'test/integration/voice/voice_category_corpus_zh_test.dart:147':
      'print() accuracy banner top',
  'test/integration/voice/voice_category_corpus_zh_test.dart:149':
      'print() accuracy summary line',
  'test/integration/voice/voice_category_corpus_zh_test.dart:151':
      'print() accuracy banner bottom',
  'test/integration/voice/voice_category_corpus_ja_test.dart:96':
      'printOnFailure() reporter for per-case soft failures',
  'test/integration/voice/voice_category_corpus_ja_test.dart:125':
      'print() accuracy banner top',
  'test/integration/voice/voice_category_corpus_ja_test.dart:127':
      'print() accuracy summary line',
  'test/integration/voice/voice_category_corpus_ja_test.dart:129':
      'print() accuracy banner bottom',
};

void main() {
  group('stale suppression scanner', () {
    test(
      'non-generated Dart files do not contain unapproved ignore comments',
      () {
        final hits = <String>[];
        final ignoreDirectivePattern = RegExp(
          r'^\s*//\s*(ignore_for_file|ignore):',
        );

        for (final root in const ['lib', 'test', 'scripts']) {
          final directory = Directory(root);
          if (!directory.existsSync()) continue;

          for (final entity in directory.listSync(recursive: true)) {
            if (entity is! File || !_shouldScan(entity)) continue;

            final path = _normalizePath(entity.path);
            final lines = entity.readAsLinesSync();
            for (var index = 0; index < lines.length; index++) {
              final line = lines[index];
              if (!ignoreDirectivePattern.hasMatch(line)) continue;

              final key = '$path:${index + 1}';
              final reason = approvedSuppressions[key];
              if (reason == null || reason.trim().isEmpty) {
                hits.add('$key: ${line.trim()}');
              }
            }
          }
        }

        expect(
          hits,
          isEmpty,
          reason:
              'Stale // ignore: or // ignore_for_file: directives found outside '
              'the explicit allow list:\n${hits.join("\n")}',
        );
      },
    );
  });
}

bool _shouldScan(File file) {
  final path = _normalizePath(file.path);
  if (!path.endsWith('.dart')) return false;
  if (path.startsWith('lib/generated/')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  if (path.endsWith('.mocks.dart')) return false;
  return true;
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');
