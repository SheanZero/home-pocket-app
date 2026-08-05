import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _requiredIcons = <String>{
  'alertCircle',
  'badgeCheck',
  'bird',
  'bookOpen',
  'cat',
  'check',
  'chevronLeft',
  'chevronRight',
  'circle',
  'circleAlert',
  'circleCheck',
  'circleX',
  'clock',
  'coffee',
  'copy',
  'dog',
  'flower2',
  'heart',
  'house',
  'info',
  'leaf',
  'lockKeyhole',
  'logIn',
  'logOut',
  'pencil',
  'plus',
  'rabbit',
  'refreshCw',
  'share2',
  'shieldCheck',
  'smile',
  'sprout',
  'star',
  'undo',
  'userPlus',
  'userRound',
  'users',
};

void main() {
  test('Lucide dependency contains only the reviewed static icon subset', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('path: third_party/lucide_icons_flutter'),
    );

    final packagePubspec = File(
      'third_party/lucide_icons_flutter/pubspec.yaml',
    ).readAsStringSync();
    expect(packagePubspec, contains('asset: assets/lucide.ttf'));
    expect(packagePubspec, isNot(contains('LucideVariable')));
    expect(
      File('third_party/lucide_icons_flutter/LICENSE').existsSync(),
      isTrue,
    );

    final declarations = File(
      'third_party/lucide_icons_flutter/lib/lucide_icons.dart',
    ).readAsStringSync();
    final declaredIcons = RegExp(
      r'static const IconData ([A-Za-z0-9_]+) =',
    ).allMatches(declarations).map((match) => match.group(1)!).toSet();
    expect(declaredIcons, _requiredIcons);

    final referencedIcons = <String>{};
    for (final root in ['lib', 'test', 'integration_test']) {
      final directory = Directory(root);
      if (!directory.existsSync()) {
        continue;
      }
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        referencedIcons.addAll(
          RegExp(r'LucideIcons\.([A-Za-z0-9_]+)')
              .allMatches(entity.readAsStringSync())
              .map((match) => match.group(1)!),
        );
      }
    }
    expect(declaredIcons, containsAll(referencedIcons));
  });
}
