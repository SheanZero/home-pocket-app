import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/settings/clear_all_data_use_case.dart';
import '../../../../application/settings/export_backup_use_case.dart';
import '../../../../application/settings/import_backup_use_case.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import 'repository_providers.dart';

part 'backup_providers.g.dart';

@riverpod
ExportBackupUseCase exportBackupUseCase(Ref ref) {
  return ExportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}

@riverpod
ImportBackupUseCase importBackupUseCase(Ref ref) {
  return ImportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}

@riverpod
ClearAllDataUseCase clearAllDataUseCase(Ref ref) {
  return ClearAllDataUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}
