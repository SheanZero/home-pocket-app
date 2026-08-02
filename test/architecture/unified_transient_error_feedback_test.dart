import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transient error feedback does not bypass the shared toast', () {
    final bypasses = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      final source = entity.readAsStringSync();
      if (source.contains('SnackBar(') || source.contains('.showSnackBar(')) {
        bypasses.add(path);
      }
    }

    expect(
      bypasses,
      isEmpty,
      reason:
          'All transient feedback must use the shared status pill so visual '
          'style, timing, stacking, and action behavior stay consistent.',
    );
  });
}
