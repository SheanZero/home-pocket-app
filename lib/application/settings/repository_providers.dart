import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/crypto/providers.dart' as crypto;
import '../../infrastructure/crypto/services/backup_crypto_service.dart';

part 'repository_providers.g.dart';

/// Application-layer re-export of [BackupCryptoService].
///
/// Feature settings presentation imports this instead of
/// infrastructure/crypto/providers.dart directly (HIGH-02 compliance,
/// mirrors application/accounting/repository_providers.dart).
@riverpod
BackupCryptoService appBackupCryptoService(Ref ref) {
  return ref.watch(crypto.backupCryptoServiceProvider);
}
