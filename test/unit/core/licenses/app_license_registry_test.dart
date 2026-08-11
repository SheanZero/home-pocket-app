import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/licenses/app_license_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'registers bundled font and native dependency licenses exactly once',
    () async {
      registerBundledThirdPartyLicenses();
      registerBundledThirdPartyLicenses();

      final entries = await LicenseRegistry.licenses.toList();
      final packageCounts = <String, int>{};
      for (final entry in entries) {
        for (final package in entry.packages) {
          packageCounts.update(
            package,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }

      for (final package in bundledThirdPartyPackageNames) {
        expect(packageCounts[package], 1, reason: '$package notice is missing');
      }
    },
  );

  test('covers every iOS Swift Package resolved into the release app', () {
    final resolved =
        jsonDecode(
              File(
                'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final pins = resolved['pins']! as List<dynamic>;
    final resolvedIdentities = pins
        .cast<Map<String, dynamic>>()
        .map((pin) => pin['identity']! as String)
        .toSet();
    final resolvedRevisions = {
      for (final pin in pins.cast<Map<String, dynamic>>())
        pin['identity']! as String:
            (pin['state']! as Map<String, dynamic>)['revision']! as String,
    };

    expect(
      bundledIosSwiftPackageIdentities,
      containsAll(resolvedIdentities),
      reason: 'Every resolved iOS native dependency needs a bundled notice',
    );
    expect(
      bundledIosSwiftPackageRevisions,
      resolvedRevisions,
      reason: 'Native dependency revisions changed; review and refresh notices',
    );
  });
}
