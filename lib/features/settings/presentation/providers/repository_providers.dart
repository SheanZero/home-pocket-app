import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../application/accounting/repository_providers.dart'
    as app_accounting;
import '../../../../application/currency/repository_providers.dart';
import '../../../../application/settings/repository_providers.dart'
    as app_settings;
import '../../../../application/settings/clear_all_data_use_case.dart';
import '../../../../application/settings/export_backup_use_case.dart';
import '../../../../application/settings/import_backup_use_case.dart';
import '../../../../application/settings/restore_backup_use_case.dart';
import '../../../../data/repositories/settings_repository_impl.dart';
import '../../../../data/repositories/unit_of_work_impl.dart';
import '../../../../features/family_sync/presentation/providers/repository_providers.dart'
    show
        familySyncOutboxRepositoryProvider,
        groupRepositoryProvider,
        pushNotificationServiceProvider,
        syncQueueManagerProvider;
import '../../../../features/family_sync/presentation/providers/state_notification_navigation.dart';
import '../../../../features/family_sync/presentation/providers/state_sync.dart';
import '../../../../infrastructure/security/providers.dart' as security;
import '../../../../infrastructure/storage/app_owned_user_files_cleaner.dart';
import '../../../../infrastructure/storage/file_privacy_wipe_journal_store.dart';
import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/unit_of_work.dart';

part 'repository_providers.g.dart';

/// SharedPreferences instance provider.
///
/// This is an application-wide platform singleton. It must outlive an isolated
/// `.future` read so synchronous dependents never observe a fresh AsyncLoading
/// state during cold-start initialization.
@Riverpod(keepAlive: true)
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
    unitOfWork: ref.watch(unitOfWorkProvider),
    backupCrypto: ref.watch(app_settings.appBackupCryptoServiceProvider),
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
    backupCrypto: ref.watch(app_settings.appBackupCryptoServiceProvider),
  );
}

/// Coordinates backup import with the same sync write barrier as clear-all.
///
/// Imported accounting history remains local-only. The current family is kept,
/// but any pre-restore queued or semantic operation is discarded before sync is
/// allowed to resume so it cannot publish rows that the restore replaced.
final restoreBackupUseCaseProvider = Provider<RestoreBackupUseCase>((ref) {
  final pushNotifications = ref.watch(pushNotificationServiceProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return RestoreBackupUseCase(
    importBackup: ref.watch(importBackupUseCaseProvider).execute,
    suspendSync: () {
      // Keep the clear-all ordering: push revocation happens synchronously
      // before either asynchronous suspension path can yield.
      final pushSuspension = pushNotifications.clearIdentityBoundState();
      final syncSuspension = syncEngine.suspendForLocalDataWipe();
      return Future.wait<void>([pushSuspension, syncSuspension]);
    },
    resetFamilySyncState: () async {
      final currentGroup = await ref
          .read(groupRepositoryProvider)
          .getCurrentGroup();
      if (currentGroup != null) {
        await ref
            .read(familySyncOutboxRepositoryProvider)
            .clearGroup(currentGroup.groupId);
      }
      await ref.read(syncQueueManagerProvider).clearQueue();
      ref.read(transactionChangeTrackerProvider).clear();
      ref.read(shoppingItemChangeTrackerProvider).clear();
      ref.read(familySyncNotificationNavigationProvider.notifier).clear();
    },
    resumeSync: () => Future.wait<void>([
      syncEngine.resumeAfterLocalDataRestore(),
      pushNotifications.registerCurrentToken(),
    ]),
  );
});

@Riverpod(keepAlive: true)
ClearAllDataUseCase clearAllDataUseCase(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final secureStorage = ref.watch(security.secureStorageServiceProvider);
  final fileCleaner = AppOwnedUserFilesCleaner(
    documentsDirectoryResolver: () async =>
        (await getApplicationDocumentsDirectory()).path,
    supportDirectoryResolver: () async =>
        (await getApplicationSupportDirectory()).path,
  );
  final wipeJournal = FilePrivacyWipeJournalStore(
    supportDirectoryResolver: () async =>
        (await getApplicationSupportDirectory()).path,
  );
  return ClearAllDataUseCase(
    journalStore: wipeJournal,
    suspendSync: () {
      // Invocation revokes the push generation synchronously before either
      // asynchronous suspension path can yield.
      final pushSuspension = ref
          .read(pushNotificationServiceProvider)
          .clearIdentityBoundState();
      final syncSuspension = ref
          .read(syncEngineProvider)
          .suspendForLocalDataWipe();
      return Future.wait<void>([pushSuspension, syncSuspension]);
    },
    wipeDatabase: database.wipeLocalUserData,
    wipeAppOwnedFiles: fileCleaner.clear,
    clearSecureUserData: secureStorage.clearUserData,
    resetSettings: () => settings.updateSettings(const AppSettings()),
    resetInMemoryState: () async {
      ref.read(transactionChangeTrackerProvider).clear();
      ref.read(shoppingItemChangeTrackerProvider).clear();
      await ref.read(pushNotificationServiceProvider).clearIdentityBoundState();
      ref.read(familySyncNotificationNavigationProvider.notifier).clear();
      ref.read(syncEngineProvider).resetAfterLocalDataWipe();
    },
  );
}
