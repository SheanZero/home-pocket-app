import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 62 iOS simulator stage is a full-suite adapter, not Phase 60', () {
    final stage = File('scripts/release_gate/ios_simulator_stage.dart');
    final phase60 = File('scripts/verify_ios_native_safety_lane.dart');

    expect(stage.existsSync(), isTrue);
    final source = stage.readAsStringSync();
    expect(source, contains("'xcrun', 'simctl'"));
    expect(source, contains('bootstatus'));
    expect(source, contains('release_preflight.sh'));
    expect(source, contains('integration_test'));
    expect(source, isNot(contains('physical device')));
    expect(phase60.readAsStringSync(), contains('_allowedRuntimeTests'));
  });
}
