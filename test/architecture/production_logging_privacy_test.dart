import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _sensitiveNames = [
  'body',
  'token',
  'signature',
  'deviceId',
  'groupId',
  'inviteCode',
  'transactionId',
  'payload',
  'encryptedPayload',
  'publicKey',
  'privateKey',
  'message=',
];

void main() {
  group('production logging privacy scanner', () {
    test('production code does not contain unsafe logging', () {
      final hits = <String>[];

      for (final file in _filesToScan()) {
        final path = _normalizePath(file.path);
        final lines = file.readAsLinesSync();

        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          final trimmed = line.trimLeft();

          if (trimmed.contains('print(')) {
            hits.add('$path:${index + 1}: print() is forbidden');
            continue;
          }

          final isDebugPrint = trimmed.contains('debugPrint(');
          final isDevLog = trimmed.contains('dev.log(');
          if (!isDebugPrint && !isDevLog) continue;

          if (!_isKDebugModeGuarded(lines, index)) {
            hits.add(
              '$path:${index + 1}: logging must be guarded by kDebugMode',
            );
          }

          final loggedBlock = _loggedBlock(lines, index);
          final sensitiveHit = _sensitiveNames
              .where(loggedBlock.contains)
              .toList();
          if (sensitiveHit.isNotEmpty) {
            hits.add(
              '$path:${index + 1}: logging contains sensitive names '
              '${sensitiveHit.join(", ")}',
            );
          }
        }
      }

      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });
}

List<File> _filesToScan() {
  final scoped = Platform.environment['LOGGING_PRIVACY_SCOPE'];
  if (scoped != null && scoped.trim().isNotEmpty) {
    return scoped
        .split(',')
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .map(File.new)
        .where((file) => file.existsSync() && _shouldScan(file.path))
        .toList();
  }

  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => _shouldScan(file.path))
      .toList();
}

bool _shouldScan(String rawPath) {
  final path = _normalizePath(rawPath);
  if (!path.endsWith('.dart')) return false;
  if (path.startsWith('lib/generated/')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  return true;
}

bool _isKDebugModeGuarded(List<String> lines, int index) {
  final start = index - 4 < 0 ? 0 : index - 4;
  final nearby = lines.sublist(start, index + 1).join('\n');
  return nearby.contains('if (kDebugMode)');
}

String _loggedBlock(List<String> lines, int index) {
  final buffer = StringBuffer(lines[index]);
  for (
    var cursor = index + 1;
    cursor < lines.length && cursor <= index + 6;
    cursor++
  ) {
    buffer.writeln(lines[cursor]);
    if (lines[cursor].contains(');')) break;
  }
  return buffer.toString();
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');
