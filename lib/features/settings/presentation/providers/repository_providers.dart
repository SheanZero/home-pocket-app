import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../application/currency/repository_providers.dart';
import '../../../../application/settings/clear_all_data_use_case.dart';
import '../../../../application/settings/export_backup_use_case.dart';
import '../../../../application/settings/import_backup_use_case.dart';
import '../../../../data/repositories/settings_repository_impl.dart';
import '../../../../data/repositories/unit_of_work_impl.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../profile/presentation/providers/repository_providers.dart'
    as profile;
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/unit_of_work.dart';

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

/// Atomic multi-repository write runner (single source of truth).
///
/// Backs the destructive settings flows (backup restore, clear-all-data)
/// with a Drift transaction so a mid-way failure rolls back.
@riverpod
UnitOfWork unitOfWork(Ref ref) {
  return UnitOfWorkImpl(db: ref.watch(app_accounting.appAppDatabaseProvider));
}

// ── Backup use case providers (folded from backup_providers.dart) ─────────────

@riverpod
ExportBackupUseCase exportBackupUseCase(Ref ref) {
  return ExportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    exchangeRateRepo: ref.watch(appExchangeRateRepositoryProvider),
  );
}

@riverpod
ImportBackupUseCase importBackupUseCase(Ref ref) {
  return ImportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    exchangeRateRepo: ref.watch(appExchangeRateRepositoryProvider),
    unitOfWork: ref.watch(unitOfWorkProvider),
  );
}

@riverpod
ClearAllDataUseCase clearAllDataUseCase(Ref ref) {
  return ClearAllDataUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    userProfileRepo: ref.watch(profile.userProfileRepositoryProvider),
    unitOfWork: ref.watch(unitOfWorkProvider),
  );
}
