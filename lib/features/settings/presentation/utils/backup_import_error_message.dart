import '../../../../application/settings/import_backup_use_case.dart';
import '../../../../generated/app_localizations.dart';

/// Converts application-layer backup error codes into user-facing copy.
String backupImportErrorMessage(S l10n, String? error) {
  if (error == BackupImportError.encryptedFileTooLarge.name) {
    return l10n.backupFileTooLarge;
  }
  if (error == BackupImportError.decompressedDataTooLarge.name) {
    return l10n.backupDataTooLarge;
  }
  return error ?? l10n.importFailed;
}
