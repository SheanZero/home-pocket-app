import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v23 historical fixture has a standalone provenance verifier', () {
    expect(
      File('scripts/verify_sqlcipher_v23_fixture_provenance.dart').existsSync(),
      isTrue,
      reason: 'the immutable historical witness requires a fail-closed verifier',
    );
  });
}
