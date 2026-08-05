import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/infrastructure/security/secure_storage_service.dart';
import 'package:home_pocket/infrastructure/storage/app_owned_user_files_cleaner.dart';
import 'package:home_pocket/infrastructure/storage/file_privacy_wipe_journal_store.dart';
import 'package:home_pocket/infrastructure/storage/privacy_wipe_journal.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/in_memory_privacy_wipe_journal_store.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

Future<int> _count(AppDatabase db, String table) async {
  final row = await db
      .customSelect('SELECT COUNT(*) AS count FROM "$table"')
      .getSingle();
  return row.read<int>('count');
}

void main() {
  test(
    'real local stores are empty only after the complete state machine succeeds',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'home-pocket-complete-wipe-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final documents = Directory('${temp.path}/documents')..createSync();
      final support = Directory('${temp.path}/support')..createSync();
      final avatar = File('${documents.path}/avatars/avatar.jpg');
      avatar.parent.createSync();
      avatar.writeAsStringSync('avatar');
      final staged = File(
        '${support.path}/family_sync/avatar_semantic_staging/blob.jpg',
      );
      staged.parent.createSync(recursive: true);
      staged.writeAsStringSync('staged');
      final unrelated = File('${documents.path}/homepocket_backup.hpb')
        ..writeAsStringSync('backup');
      final generatedBackup = File(
        '${documents.path}/homepocket_backup_2026-08-02.hpb',
      )..writeAsStringSync('encrypted backup');

      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.customStatement(
        "INSERT INTO groups (group_id,status,role,group_name,group_key,created_at) VALUES ('g','active','owner','family','secret',1)",
      );
      await db.customStatement(
        "INSERT INTO group_members (group_id,device_id,public_key,device_name,role,status) VALUES ('g','d','public','phone','owner','confirmed')",
      );
      await db.customStatement(
        "INSERT INTO shopping_items (id,device_id,list_type,name,note,created_at) VALUES ('s','d','private','private','encrypted',1)",
      );
      await db.customStatement(
        "INSERT INTO user_profiles (id,display_name,avatar_emoji,avatar_image_path,created_at,updated_at) VALUES ('p','name','fox','${avatar.path}',1,1)",
      );
      await db.customStatement(
        "INSERT INTO sync_queue (id,group_id,encrypted_payload,vector_clock,operation_count,state,created_at) VALUES ('q','g','cipher','{}',1,'dead_letter',1)",
      );
      await db.customStatement(
        "INSERT INTO inbound_sync_operations (group_id,operation_id,message_id,state,operation_json,created_at,updated_at) VALUES ('g','op','msg','quarantined','{}',1,1)",
      );
      await db.customStatement(
        "INSERT INTO family_sync_outbox (operation_id,group_id,entity_type,entity_id,revision,operation_json,created_at) VALUES ('out','g','profile','d',1,'{}',1)",
      );

      final values = <String, String>{
        for (final key in StorageKeys.allKeys) key: 'secret-$key',
        'other_sdk_key': 'keep',
      };
      final platformStorage = _MockFlutterSecureStorage();
      when(
        () => platformStorage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((invocation) async {
        values.remove(invocation.namedArguments[#key] as String);
      });
      final secureStorage = SecureStorageService(storage: platformStorage);
      final files = AppOwnedUserFilesCleaner(
        documentsDirectoryResolver: () async => documents.path,
        supportDirectoryResolver: () async => support.path,
      );
      var syncSuspended = false;
      var settingsReset = false;
      var memoryReset = false;
      final useCase = ClearAllDataUseCase(
        journalStore: InMemoryPrivacyWipeJournalStore(),
        suspendSync: () async => syncSuspended = true,
        wipeDatabase: db.wipeLocalUserData,
        wipeAppOwnedFiles: files.clear,
        clearSecureUserData: secureStorage.clearUserData,
        resetSettings: () async => settingsReset = true,
        resetInMemoryState: () async => memoryReset = true,
      );

      expect((await useCase.execute()).isSuccess, isTrue);
      expect(syncSuspended, isTrue);
      expect(settingsReset, isTrue);
      expect(memoryReset, isTrue);
      for (final table in AppDatabase.localUserDataTableNames) {
        expect(await _count(db, table), 0, reason: table);
      }
      expect(avatar.existsSync(), isFalse);
      expect(staged.existsSync(), isFalse);
      expect(unrelated.existsSync(), isTrue);
      expect(generatedBackup.existsSync(), isFalse);
      for (final key in StorageKeys.userDataKeys) {
        expect(values, isNot(contains(key)));
      }
      expect(values[StorageKeys.masterKey], isNotNull);
      expect(values['other_sdk_key'], 'keep');

      expect(
        (await useCase.execute()).isSuccess,
        isTrue,
        reason: 'wipe is idempotent',
      );
    },
  );

  test(
    'new process resumes real DB, files, secure data and preferences from persistent journal',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'home-pocket-reconstructed-wipe-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final documents = Directory('${temp.path}/documents')..createSync();
      final support = Directory('${temp.path}/support')..createSync();
      final avatar = File('${documents.path}/avatars/avatar.jpg');
      avatar.parent.createSync();
      avatar.writeAsStringSync('old avatar');

      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      await db.customStatement(
        "INSERT INTO groups (group_id,status,role,group_name,group_key,created_at) VALUES ('g','active','owner','family','secret',1)",
      );

      final values = <String, String>{
        for (final key in StorageKeys.allKeys) key: 'secret-$key',
      };
      final platformStorage = _MockFlutterSecureStorage();
      when(
        () => platformStorage.delete(
          key: any(named: 'key'),
          iOptions: any(named: 'iOptions'),
          aOptions: any(named: 'aOptions'),
        ),
      ).thenAnswer((invocation) async {
        values.remove(invocation.namedArguments[#key] as String);
      });
      final secureStorage = SecureStorageService(storage: platformStorage);

      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'language': 'ja',
      });
      final preferences = await SharedPreferences.getInstance();
      final settings = SettingsRepositoryImpl(prefs: preferences);
      final files = AppOwnedUserFilesCleaner(
        documentsDirectoryResolver: () async => documents.path,
        supportDirectoryResolver: () async => support.path,
      );
      FilePrivacyWipeJournalStore journal() => FilePrivacyWipeJournalStore(
        supportDirectoryResolver: () async => support.path,
      );

      var secureCleared = false;
      var preferencesReset = false;
      var memoryReset = false;
      final interrupted = ClearAllDataUseCase(
        journalStore: journal(),
        suspendSync: () async {},
        wipeDatabase: db.wipeLocalUserData,
        wipeAppOwnedFiles: () async {
          await files.clear();
          throw StateError('process terminated after file deletion');
        },
        clearSecureUserData: () async => secureCleared = true,
        resetSettings: () async => preferencesReset = true,
        resetInMemoryState: () async => memoryReset = true,
      );

      expect((await interrupted.execute()).isError, isTrue);
      expect(await _count(db, 'groups'), 0, reason: 'DB already committed');
      expect(avatar.existsSync(), isFalse, reason: 'file step also committed');
      expect(values[StorageKeys.deviceId], isNotNull);
      expect((await settings.getSettings()).onboardingComplete, isTrue);
      expect(secureCleared, isFalse);
      expect(preferencesReset, isFalse);
      expect(memoryReset, isFalse);
      expect(
        (await journal().read())?.stage,
        PrivacyWipeJournalStage.filesPending,
      );

      var replayedDatabase = false;
      final reconstructed = ClearAllDataUseCase(
        journalStore: journal(),
        suspendSync: () async {},
        wipeDatabase: () async {
          replayedDatabase = true;
          await db.wipeLocalUserData();
        },
        wipeAppOwnedFiles: files.clear,
        clearSecureUserData: secureStorage.clearUserData,
        resetSettings: () => settings.updateSettings(const AppSettings()),
        resetInMemoryState: () async => memoryReset = true,
      );

      expect((await reconstructed.resumePending()).isSuccess, isTrue);
      expect(
        replayedDatabase,
        isFalse,
        reason: 'filesPending proves the DB boundary was durable',
      );
      for (final key in StorageKeys.userDataKeys) {
        expect(values, isNot(contains(key)));
      }
      expect(values[StorageKeys.masterKey], isNotNull);
      expect((await settings.getSettings()).onboardingComplete, isFalse);
      expect(memoryReset, isTrue);
      expect(await journal().read(), isNull);
    },
  );
}
