import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/utils/backup_import_error_message.dart';
import 'package:home_pocket/generated/app_localizations_en.dart';
import 'package:home_pocket/generated/app_localizations_ja.dart';
import 'package:home_pocket/generated/app_localizations_zh.dart';

void main() {
  test('localizes encrypted and decompressed backup size errors', () {
    expect(
      backupImportErrorMessage(SEn(), 'encryptedFileTooLarge'),
      'This backup file is too large to import.',
    );
    expect(
      backupImportErrorMessage(SJa(), 'decompressedDataTooLarge'),
      'バックアップの展開後サイズが安全な上限を超えています。',
    );
    expect(
      backupImportErrorMessage(SZh(), 'encryptedFileTooLarge'),
      '备份文件过大，无法导入。',
    );
  });

  test('preserves existing detailed errors and falls back for null', () {
    final l10n = SEn();

    expect(
      backupImportErrorMessage(l10n, 'Incorrect password'),
      'Incorrect password',
    );
    expect(backupImportErrorMessage(l10n, null), l10n.importFailed);
  });
}
