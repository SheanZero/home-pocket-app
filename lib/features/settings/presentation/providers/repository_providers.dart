import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../application/settings/clear_all_data_use_case.dart';
import '../../../../application/settings/export_backup_use_case.dart';
import '../../../../application/settings/import_backup_use_case.dart';
import '../../../../data/repositories/settings_repository_impl.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../domain/repositories/settings_repository.dart';

part 'repository_providers.g.dart';

/// SharedPreferences instance provider.
@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}

/// SettingsRepository provider (single source of truth).
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return SettingsRepositoryImpl(prefs: prefs);
}

// ── Backup use case providers (folded from backup_providers.dart) ─────────────

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
