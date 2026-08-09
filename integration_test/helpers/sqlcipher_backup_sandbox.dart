import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/clear_all_data_use_case.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/application/settings/restore_backup_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/exchange_rate_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/data/repositories/exchange_rate_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/data/repositories/unit_of_work_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction_photo_sync_policy.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/infrastructure/crypto/repositories/encryption_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:home_pocket/infrastructure/storage/app_owned_user_files_cleaner.dart';
import 'package:home_pocket/infrastructure/storage/file_privacy_wipe_journal_store.dart';

import 'device_test_crypto.dart';

const _plaintextSqliteHeader = <int>[
  0x53,
  0x51,
  0x4c,
  0x69,
  0x74,
  0x65,
  0x20,
  0x66,
  0x6f,
  0x72,
  0x6d,
  0x61,
  0x74,
  0x20,
  0x33,
  0x00,
];

/// Test-only composition of the production backup use cases below one unique
/// temporary root. It deliberately does not resolve app containers, platform
/// secure storage, or caller backup locations.
class SqlCipherBackupSandbox {
  SqlCipherBackupSandbox._(this._root)
    : _databaseFile = File('${_root.path}/database/current.db'),
      _backupDirectory = Directory('${_root.path}/backups'),
      _documentsDirectory = Directory('${_root.path}/documents'),
      _supportDirectory = Directory('${_root.path}/support'),
      _settings = _SandboxSettingsRepository(
        File('${_root.path}/settings/settings.json'),
      );

  final Directory _root;
  final File _databaseFile;
  final Directory _backupDirectory;
  final Directory _documentsDirectory;
  final Directory _supportDirectory;
  final DeviceTestMasterKeyRepository _masterKeys =
      DeviceTestMasterKeyRepository();
  final _SandboxSettingsRepository _settings;
  final _SyntheticSecureState _secureState = _SyntheticSecureState();
  final _SandboxSyncState _syncState = _SandboxSyncState();

  late AppDatabase _database;
  late BookRepositoryImpl _books;
  late CategoryRepositoryImpl _categories;
  late TransactionRepositoryImpl _transactions;
  late ExchangeRateRepositoryImpl _exchangeRates;
  late ExportBackupUseCase _export;
  late ImportBackupUseCase _import;
  late RestoreBackupUseCase _restore;
  late ClearAllDataUseCase _clear;

  static Future<SqlCipherBackupSandbox> create() async {
    final root = await Directory.systemTemp.createTemp('hpb-v2-sandbox-');
    final sandbox = SqlCipherBackupSandbox._(root);
    await sandbox._initialize();
    return sandbox;
  }

  Future<void> _initialize() async {
    await Future.wait([
      _backupDirectory.create(recursive: true),
      _documentsDirectory.create(recursive: true),
      _supportDirectory.create(recursive: true),
    ]);
    await _settings.initialize();
    _assertRootOwnership();
    await _openDatabase();
    _composeUseCases();
  }

  Future<void> _openDatabase() async {
    _databaseFile.parent.createSync(recursive: true);
    _database = AppDatabase(
      await createDeviceTestEncryptedExecutor(_masterKeys, _databaseFile),
    );
    _books = BookRepositoryImpl(dao: BookDao(_database));
    _categories = CategoryRepositoryImpl(dao: CategoryDao(_database));
    _transactions = TransactionRepositoryImpl(
      dao: TransactionDao(_database),
      encryptionService: FieldEncryptionService(
        repository: EncryptionRepositoryImpl(masterKeyRepository: _masterKeys),
      ),
    );
    _exchangeRates = ExchangeRateRepositoryImpl(
      dao: ExchangeRateDao(_database),
    );
  }

  void _composeUseCases() {
    final unitOfWork = UnitOfWorkImpl(db: _database);
    final backupCrypto = BackupCryptoService();
    _export = ExportBackupUseCase(
      transactionRepo: _transactions,
      categoryRepo: _categories,
      bookRepo: _books,
      settingsRepo: _settings,
      exchangeRateRepo: _exchangeRates,
      unitOfWork: unitOfWork,
      backupCrypto: backupCrypto,
    );
    _import = ImportBackupUseCase(
      transactionRepo: _transactions,
      categoryRepo: _categories,
      bookRepo: _books,
      settingsRepo: _settings,
      exchangeRateRepo: _exchangeRates,
      unitOfWork: unitOfWork,
      backupCrypto: backupCrypto,
    );
    _restore = RestoreBackupUseCase(
      importBackup: _import.execute,
      suspendSync: _syncState.suspend,
      resetFamilySyncState: _syncState.reset,
      resumeSync: _syncState.resume,
    );
    _clear = ClearAllDataUseCase(
      journalStore: FilePrivacyWipeJournalStore(
        supportDirectoryResolver: () async => _supportDirectory.path,
      ),
      suspendSync: _syncState.suspend,
      wipeDatabase: _database.wipeLocalUserData,
      wipeAppOwnedFiles: AppOwnedUserFilesCleaner(
        documentsDirectoryResolver: () async => _documentsDirectory.path,
        supportDirectoryResolver: () async => _supportDirectory.path,
      ).clear,
      clearSecureUserData: _secureState.clearUserData,
      resetSettings: _settings.reset,
      resetInMemoryState: _syncState.clearInMemory,
    );
  }

  Future<void> seedCurrentV2State() async {
    final timestamp = DateTime.utc(2026, 8, 9, 12);
    final book = Book(
      id: 'sandbox-book',
      name: 'Synthetic household',
      currency: 'JPY',
      deviceId: 'sandbox-device',
      createdAt: timestamp,
    );
    final category = Category(
      id: 'sandbox-category',
      name: 'Synthetic category',
      icon: 'home',
      color: '#47B88A',
      level: 1,
      createdAt: timestamp,
    );
    await _books.insert(book);
    await _categories.insert(category);
    await _transactions.insert(
      Transaction(
        id: 'sandbox-transaction',
        bookId: book.id,
        deviceId: book.deviceId,
        amount: 1234,
        type: TransactionType.expense,
        categoryId: category.id,
        ledgerType: LedgerType.joy,
        timestamp: timestamp,
        note: 'synthetic-only',
        merchant: 'synthetic-only',
        photoHash: 'local-photo-only',
        currentHash: 'synthetic-hash',
        createdAt: timestamp,
      ),
    );
    await _exchangeRates.upsert(
      ExchangeRate(
        currency: 'USD',
        rateDate: timestamp,
        rate: '150.25',
        fetchedAt: timestamp,
        source: 'manual',
      ),
    );
    await _settings.updateSettings(
      const AppSettings(
        themeMode: AppThemeMode.dark,
        language: 'en',
        notificationsEnabled: false,
        biometricLockEnabled: false,
        appLockEnabled: true,
        biometricUnlockEnabled: true,
        onboardingComplete: true,
        voiceLanguage: 'ja',
        voiceAllowOnDeviceFallback: false,
        monthlyJoyTarget: 800,
        weekStartDay: WeekStartDay.sunday,
      ),
    );
    await _secureState.seed();
    final avatar = File('${_documentsDirectory.path}/avatars/avatar.bin');
    await avatar.parent.create(recursive: true);
    await avatar.writeAsBytes(const <int>[1, 2, 3], flush: true);
    _syncState.seed();
  }

  Future<SqlCipherBackupSnapshot> snapshot() async {
    final books = await _books.findAll(
      includeArchived: true,
      includeShadow: true,
    );
    final transactions = <Map<String, dynamic>>[];
    for (final book in books) {
      final rows = await _transactions.findAllByBook(book.id);
      transactions.addAll(rows.map(TransactionPhotoSyncPolicy.toBackupJson));
    }
    final categories = await _categories.findAll();
    final rates = await _exchangeRates.findAll();
    final schemaRows = await _database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final schema = schemaRows.map((row) => row.read<String>('name')).toList()
      ..sort();
    return SqlCipherBackupSnapshot(
      books: books.map((value) => value.toJson()).toList(),
      categories: categories.map((value) => value.toJson()).toList(),
      transactions: transactions,
      exchangeRates: rates
          .map(
            (value) => <String, Object?>{
              'currency': value.currency,
              'rateDate': value.rateDate.toUtc().millisecondsSinceEpoch,
              'rate': value.rate,
              'fetchedAt': value.fetchedAt.toUtc().millisecondsSinceEpoch,
              'source': value.source,
              'actualRateDate': value.actualRateDate
                  ?.toUtc()
                  .millisecondsSinceEpoch,
            },
          )
          .toList(),
      settings: await _settings.getSettings(),
      schema: schema,
      secureDigest: _secureState.digest,
      syncDigest: _syncState.digest,
    );
  }

  Future<File> exportCurrentV2() async {
    final result = await _export.execute(
      bookId: 'sandbox-book',
      password: _SyntheticSecureState.backupPassword,
      outputDirectory: _backupDirectory,
    );
    expect(result.isSuccess, isTrue, reason: result.error ?? 'export failed');
    final backup = result.data!;
    _assertOwned(backup);
    await expectCurrentV2Backup(backup);
    return backup;
  }

  Future<void> clearAllData() async {
    final result = await _clear.execute();
    expect(result.isSuccess, isTrue, reason: result.error ?? 'clear failed');
    expect(_secureState.hasOnlyMasterKey, isTrue);
    expect(
      await File('${_documentsDirectory.path}/avatars/avatar.bin').exists(),
      isFalse,
    );
    expect(_syncState.inMemoryCleared, isTrue);
  }

  Future<void> restoreCurrentV2(File backup) async {
    final digestBefore = await _digest(backup);
    final result = await _restore.execute(
      backupFile: backup,
      password: _SyntheticSecureState.backupPassword,
    );
    expect(result.isSuccess, isTrue, reason: result.error ?? 'restore failed');
    expect(_syncState.isSuspended, isFalse);
    expect(_syncState.familyStateReset, isTrue);
    expect(await _digest(backup), digestBefore);
  }

  Future<void> expectSupportedStateEquals(
    SqlCipherBackupSnapshot before,
  ) async {
    final after = await snapshot();
    expect(after.books, equals(before.books));
    expect(after.categories, equals(before.categories));
    expect(after.transactions, equals(before.transactions));
    expect(after.exchangeRates, equals(before.exchangeRates));
    expect(after.settings, equals(before.settings));
    expect(after.schema, equals(before.schema));
    expect(after.secureDigest, isNot(before.secureDigest));
    expect(after.syncDigest, isNot(before.syncDigest));
  }

  Future<void> expectPhotoBackupPolicy() async {
    final restored = await _transactions.findAllByBook('sandbox-book');
    expect(restored, hasLength(1));
    expect(
      TransactionPhotoSyncPolicy.isUnavailableRemotePhoto(restored.single),
      isTrue,
    );
    expect(restored.single.photoHash, isNull);
    expect(
      await File('${_documentsDirectory.path}/avatars/avatar.bin').exists(),
      isFalse,
    );
  }

  Future<void> expectCurrentSqlCipherColdReopen() async {
    await _assertCurrentSqlCipher(_database);
    await _assertEncryptedHeader(_databaseFile);
    await _database.close();
    await _assertEncryptedHeader(_databaseFile);
    await _openDatabase();
    _composeUseCases();
    await _assertCurrentSqlCipher(_database);
    await _assertEncryptedHeader(_databaseFile);
  }

  Future<void> expectCurrentV2Backup(File backup) async {
    final bytes = await backup.readAsBytes();
    expect(bytes.length, greaterThanOrEqualTo(10));
    expect(
      bytes.sublist(0, 4),
      orderedEquals(const <int>[0x48, 0x50, 0x42, 2]),
    );
  }

  Future<String> backupDigest(File backup) async {
    _assertOwned(backup);
    return _digest(backup);
  }

  Future<void> close() async {
    await _database.close();
    if (await _root.exists()) {
      await _root.delete(recursive: true);
    }
  }

  void _assertRootOwnership() {
    for (final entity in <FileSystemEntity>[
      _databaseFile,
      _backupDirectory,
      _documentsDirectory,
      _supportDirectory,
    ]) {
      _assertOwned(entity);
    }
  }

  void _assertOwned(FileSystemEntity entity) {
    final rootPath = _root.absolute.path;
    final candidatePath = entity.absolute.path;
    if (candidatePath != rootPath &&
        !candidatePath.startsWith('$rootPath${Platform.pathSeparator}')) {
      throw StateError('Sandbox boundary violation.');
    }
  }
}

class SqlCipherBackupSnapshot {
  const SqlCipherBackupSnapshot({
    required this.books,
    required this.categories,
    required this.transactions,
    required this.exchangeRates,
    required this.settings,
    required this.schema,
    required this.secureDigest,
    required this.syncDigest,
  });

  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, Object?>> exchangeRates;
  final AppSettings settings;
  final List<String> schema;
  final String secureDigest;
  final String syncDigest;
}

class _SandboxSettingsRepository implements SettingsRepository {
  _SandboxSettingsRepository(this._file);

  final File _file;
  AppSettings _value = const AppSettings();

  Future<void> initialize() async {
    await _file.parent.create(recursive: true);
    await _persist();
  }

  Future<void> reset() => updateSettings(const AppSettings());

  @override
  Future<AppSettings> getSettings() async => _value;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _value = settings;
    await _persist();
  }

  @override
  Future<void> setThemeMode(AppThemeMode themeMode) =>
      updateSettings(_value.copyWith(themeMode: themeMode));
  @override
  Future<void> setLanguage(String language) =>
      updateSettings(_value.copyWith(language: language));
  @override
  Future<void> setNotificationsEnabled(bool enabled) =>
      updateSettings(_value.copyWith(notificationsEnabled: enabled));
  @override
  Future<void> setBiometricLock(bool enabled) =>
      updateSettings(_value.copyWith(biometricLockEnabled: enabled));
  @override
  Future<void> setAppLockEnabled(bool enabled) =>
      updateSettings(_value.copyWith(appLockEnabled: enabled));
  @override
  Future<void> setBiometricUnlockEnabled(bool enabled) =>
      updateSettings(_value.copyWith(biometricUnlockEnabled: enabled));
  @override
  Future<void> setOnboardingComplete(bool enabled) =>
      updateSettings(_value.copyWith(onboardingComplete: enabled));
  @override
  Future<void> setVoiceLanguage(String languageCode) =>
      updateSettings(_value.copyWith(voiceLanguage: languageCode));
  @override
  Future<void> setVoiceAllowOnDeviceFallback(bool enabled) =>
      updateSettings(_value.copyWith(voiceAllowOnDeviceFallback: enabled));
  @override
  Future<int?> getMonthlyJoyTarget() async => _value.monthlyJoyTarget;
  @override
  Future<void> setMonthlyJoyTarget(int? value) =>
      updateSettings(_value.copyWith(monthlyJoyTarget: value));
  @override
  Future<WeekStartDay> getWeekStartDay() async => _value.weekStartDay;
  @override
  Future<void> setWeekStartDay(WeekStartDay day) =>
      updateSettings(_value.copyWith(weekStartDay: day));

  Future<void> _persist() =>
      _file.writeAsString(jsonEncode(_value.toJson()), flush: true);
}

class _SyntheticSecureState {
  static const backupPassword = 'sandbox-v2-password';
  final Map<String, String> _values = <String, String>{'master': 'synthetic'};

  Future<void> seed() async {
    _values.addAll(const <String, String>{
      'device_private_key': 'synthetic',
      'device_public_key': 'synthetic',
      'device_id': 'synthetic',
      'pin_hash': 'synthetic',
      'recovery_kit_hash': 'synthetic',
    });
  }

  Future<void> clearUserData() async {
    _values.removeWhere((key, _) => key != 'master');
  }

  bool get hasOnlyMasterKey =>
      _values.length == 1 && _values.containsKey('master');
  String get digest {
    final keys = _values.keys.toList()..sort();
    return sha256.convert(utf8.encode(keys.join('|'))).toString();
  }
}

class _SandboxSyncState {
  var isSuspended = false;
  var inMemoryCleared = false;
  var familyStateReset = false;
  var _revision = 0;

  void seed() => _revision = 1;
  Future<void> suspend() async => isSuspended = true;
  Future<void> resume() async => isSuspended = false;
  Future<void> reset() async {
    familyStateReset = true;
    _revision = 0;
  }

  Future<void> clearInMemory() async => inMemoryCleared = true;
  String get digest =>
      '$_revision:$isSuspended:$inMemoryCleared:$familyStateReset';
}

Future<String> _scalar(AppDatabase database, String statement) async {
  final rows = await database.customSelect(statement).get();
  expect(rows, hasLength(1));
  return rows.single.data.values.single.toString().toLowerCase();
}

Future<void> _assertCurrentSqlCipher(AppDatabase database) async {
  final master = await database
      .customSelect('SELECT count(*) AS count FROM sqlite_master')
      .getSingle();
  expect(
    await _scalar(database, 'PRAGMA cipher_version'),
    matches(RegExp(r'^4\.17\.\d+(?:\s|$)')),
  );
  expect(await _scalar(database, 'PRAGMA cipher_status'), '1');
  expect(master.read<int>('count'), greaterThan(0));
  expect(await _scalar(database, 'PRAGMA integrity_check'), 'ok');
}

Future<void> _assertEncryptedHeader(File databaseFile) async {
  final header = await databaseFile
      .openRead(0, _plaintextSqliteHeader.length)
      .first;
  expect(header, isNot(orderedEquals(_plaintextSqliteHeader)));
}

Future<String> _digest(File file) async =>
    sha256.convert(await file.readAsBytes()).toString();
