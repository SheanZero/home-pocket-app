import 'dart:io';

const _packageRoot = 'third_party/lucide_icons_flutter';
const _fontAsset = 'packages/lucide_icons_flutter/assets/lucide.ttf';
const _maxTreeShakenFontBytes = 20 * 1024;

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

Never _fail(String message) => throw StateError(message);

void main(List<String> arguments) {
  final packageDirectory = Directory(_packageRoot);
  if (!packageDirectory.existsSync()) {
    _fail('Missing local Lucide subset at $_packageRoot.');
  }

  final appPubspec = File('pubspec.yaml').readAsStringSync();
  if (!appPubspec.contains('path: third_party/lucide_icons_flutter')) {
    _fail(
      'pubspec.yaml must resolve lucide_icons_flutter to the local subset.',
    );
  }

  final packagePubspec = File('$_packageRoot/pubspec.yaml').readAsStringSync();
  if (!packagePubspec.contains('asset: assets/lucide.ttf') ||
      packagePubspec.contains('LucideVariable')) {
    _fail('The local package must declare only the static Lucide font.');
  }

  final declarations = File(
    '$_packageRoot/lib/lucide_icons.dart',
  ).readAsStringSync();
  final declaredIcons = RegExp(
    r'static const IconData ([A-Za-z0-9_]+) =',
  ).allMatches(declarations).map((match) => match.group(1)!).toSet();
  if (declaredIcons.length != _requiredIcons.length ||
      !declaredIcons.containsAll(_requiredIcons)) {
    _fail(
      'Local Lucide declarations must exactly match the reviewed static subset.',
    );
  }

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
        RegExp(
          r'LucideIcons\.([A-Za-z0-9_]+)',
        ).allMatches(entity.readAsStringSync()).map((match) => match.group(1)!),
      );
    }
  }
  if (!declaredIcons.containsAll(referencedIcons)) {
    _fail(
      'Local subset is missing: '
      '${(referencedIcons.difference(declaredIcons).toList()..sort()).join(', ')}',
    );
  }

  final assetRootArgument = arguments
      .cast<String?>()
      .map(
        (argument) => argument?.startsWith('--asset-root=') == true
            ? argument!.substring('--asset-root='.length)
            : null,
      )
      .whereType<String>()
      .singleOrNull;
  if (assetRootArgument != null) {
    final assetDirectory = Directory(
      '$assetRootArgument/packages/lucide_icons_flutter',
    );
    final assets = assetDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.substring('$assetRootArgument/'.length))
        .toSet();
    if (assets.length != 1 || !assets.contains(_fontAsset)) {
      _fail('Built asset bundle must contain only $_fontAsset; found $assets.');
    }
    final treeShakenFont = File('$assetRootArgument/$_fontAsset');
    if (arguments.contains('--expect-tree-shaken') &&
        treeShakenFont.lengthSync() > _maxTreeShakenFontBytes) {
      _fail('Tree-shaken Lucide font exceeds $_maxTreeShakenFontBytes bytes.');
    }
  }

  stdout.writeln(
    'Lucide static subset verified (${declaredIcons.length} icons).',
  );
}
