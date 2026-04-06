// scripts/arb_to_csv.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final jaFile = File('lib/l10n/app_ja.arb');
  final zhFile = File('lib/l10n/app_zh.arb');

  final en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final ja = jsonDecode(jaFile.readAsStringSync()) as Map<String, dynamic>;
  final zh = jsonDecode(zhFile.readAsStringSync()) as Map<String, dynamic>;

  // Collect all translation keys (skip metadata keys starting with @)
  final allKeys = <String>{
    ...en.keys.where((k) => !k.startsWith('@')),
    ...ja.keys.where((k) => !k.startsWith('@')),
    ...zh.keys.where((k) => !k.startsWith('@')),
  };
  final sortedKeys = allKeys.toList()..sort();

  final buffer = StringBuffer();
  buffer.writeln('key,en,ja,zh,notes');
  for (final key in sortedKeys) {
    final enVal = _escapeCsv(en[key]?.toString() ?? '');
    final jaVal = _escapeCsv(ja[key]?.toString() ?? '');
    final zhVal = _escapeCsv(zh[key]?.toString() ?? '');
    buffer.writeln('$key,$enVal,$jaVal,$zhVal,');
  }

  final outDir = Directory('docs/i18n');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  File('docs/i18n/translations.csv').writeAsStringSync(buffer.toString());
  print('Exported ${sortedKeys.length} keys to docs/i18n/translations.csv');
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
