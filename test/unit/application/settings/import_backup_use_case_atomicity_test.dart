import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/book_dao.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/category_ledger_config_dao.dart';
import 'package:home_pocket/data/daos/exchange_rate_dao.dart';
import 'package:home_pocket/data/daos/shopping_item_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/book_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/data/repositories/category_ledger_config_repository_impl.dart';
import 'package:home_pocket/data/repositories/exchange_rate_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/data/repositories/shopping_item_repository_impl.dart';
import 'package:home_pocket/data/repositories/unit_of_work_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/models/backup_data.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_unit.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// A stateful preferences double. [updateSettings] deliberately applies one
/// setting at a time so a test can reproduce a SharedPreferences failure after
/// some keys have already changed.
class _JournalSettingsRepository implements SettingsRepository {
  _JournalSettingsRepository({
    required AppSettings initialSettings,
    this.failUpdateAfterWrite,
    this.failCompensationWrite,
  }) : _settings = initialSettings;

  AppSettings _settings;
  final int? failUpdateAfterWrite;
  final int? failCompensationWrite;
  int _updateWrites = 0;
  int compensationWrites = 0;

  AppSettings get currentSettings => _settings;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    final writes = <AppSettings Function(AppSettings)>[
      (current) => current.copyWith(themeMode: settings.themeMode),
      (current) => current.copyWith(language: settings.language),
      (current) =>
          current.copyWith(biometricLockEnabled: settings.biometricLockEnabled),
      (current) => current.copyWith(appLockEnabled: settings.appLockEnabled),
      (current) => current.copyWith(
        biometricUnlockEnabled: settings.biometricUnlockEnabled,
      ),
      (current) =>
          current.copyWith(onboardingComplete: settings.onboardingComplete),
      (current) => current.copyWith(voiceLanguage: settings.voiceLanguage),
      (current) => current.copyWith(
        voiceAllowOnDeviceFallback: settings.voiceAllowOnDeviceFallback,
      ),
      (current) =>
          current.copyWith(monthlyJoyTarget: settings.monthlyJoyTarget),
      (current) => current.copyWith(weekStartDay: settings.weekStartDay),
    ];

    for (final write in writes) {
      _settings = write(_settings);
      _updateWrites += 1;
      if (_updateWrites == failUpdateAfterWrite) {
        throw StateError('injected preferences write failure');
      }
    }
  }

  Future<void> _restoreField(AppSettings Function(AppSettings) update) async {
    compensationWrites += 1;
    if (compensationWrites == failCompensationWrite) {
      throw StateError('injected compensation write failure');
    }
    _settings = update(_settings);
  }

  @override
  Future<void> setThemeMode(AppThemeMode themeMode) =>
      _restoreField((current) => current.copyWith(themeMode: themeMode));

  @override
  Future<void> setLanguage(String language) =>
      _restoreField((current) => current.copyWith(language: language));

  @override
  Future<void> setBiometricLock(bool enabled) => _restoreField(
    (current) => current.copyWith(biometricLockEnabled: enabled),
  );

  @override
  Future<void> setAppLockEnabled(bool enabled) =>
      _restoreField((current) => current.copyWith(appLockEnabled: enabled));

  @override
  Future<void> setBiometricUnlockEnabled(bool enabled) => _restoreField(
    (current) => current.copyWith(biometricUnlockEnabled: enabled),
  );

  @override
  Future<void> setOnboardingComplete(bool enabled) =>
      _restoreField((current) => current.copyWith(onboardingComplete: enabled));

  @override
  Future<void> setVoiceLanguage(String languageCode) =>
      _restoreField((current) => current.copyWith(voiceLanguage: languageCode));

  @override
  Future<void> setVoiceAllowOnDeviceFallback(bool enabled) => _restoreField(
    (current) => current.copyWith(voiceAllowOnDeviceFallback: enabled),
  );

  @override
  Future<int?> getMonthlyJoyTarget() async => _settings.monthlyJoyTarget;

  @override
  Future<void> setMonthlyJoyTarget(int? value) =>
      _restoreField((current) => current.copyWith(monthlyJoyTarget: value));

  @override
  Future<WeekStartDay> getWeekStartDay() async => _settings.weekStartDay;

  @override
  Future<void> setWeekStartDay(WeekStartDay day) =>
      _restoreField((current) => current.copyWith(weekStartDay: day));
}

/// Throws after the callback has applied settings, mirroring a transaction
/// that fails while committing its database changes.
class _CommitFailingUnitOfWork implements UnitOfWork {
  _CommitFailingUnitOfWork(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    return _db.transaction(() async {
      await action();
      throw StateError('injected database commit failure');
    });
  }
}

/// Encrypts [backupData] into the current HPB v2 `.hpb` format.
Future<File> _createEncryptedBackup({
  required String password,
  required BackupData backupData,
  required String filePath,
}) async {
  final jsonString = jsonEncode(backupData.toJson());
  final gzipBytes = gzip.encode(utf8.encode(jsonString));
  final result = await BackupCryptoService().encrypt(
    Uint8List.fromList(gzipBytes),
    password,
  );

  final file = File(filePath);
  await file.writeAsBytes(Uint8List.fromList(result));
  return file;
}

void main() {
  late AppDatabase db;
  late BookRepositoryImpl bookRepo;
  late CategoryRepositoryImpl categoryRepo;
  late CategoryLedgerConfigRepositoryImpl categoryLedgerConfigRepo;
  late TransactionRepositoryImpl transactionRepo;
  late ExchangeRateRepositoryImpl exchangeRateRepo;
  late ShoppingItemRepositoryImpl shoppingItemRepo;
  late _MockSettingsRepository settingsRepo;
  late ImportBackupUseCase useCase;
  late Directory tempDir;

  final oldBook = Book(
    id: 'book_old',
    name: 'Old Book',
    currency: 'JPY',
    deviceId: 'dev_001',
    createdAt: DateTime(2026, 1, 1),
  );
  final oldCategory = Category(
    id: 'cat_old',
    name: 'Old Category',
    icon: 'food',
    color: '#5FAE72',
    level: 1,
    createdAt: DateTime(2026, 1, 1),
  );
  final oldTransaction = Transaction(
    id: 'tx_old',
    bookId: 'book_old',
    deviceId: 'dev_001',
    amount: 1200,
    type: TransactionType.expense,
    categoryId: 'cat_old',
    ledgerType: LedgerType.daily,
    timestamp: DateTime(2026, 1, 2, 12),
    currentHash: 'hash_old',
    createdAt: DateTime(2026, 1, 2, 12),
  );

  setUp(() async {
    registerFallbackValue(const AppSettings());

    db = AppDatabase.forTesting();
    final mockEncryption = _MockFieldEncryptionService();
    when(
      () => mockEncryption.encryptField(any()),
    ).thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
    when(() => mockEncryption.decryptField(any())).thenAnswer(
      (inv) async =>
          (inv.positionalArguments[0] as String).replaceFirst('enc_', ''),
    );

    bookRepo = BookRepositoryImpl(dao: BookDao(db));
    categoryRepo = CategoryRepositoryImpl(dao: CategoryDao(db));
    categoryLedgerConfigRepo = CategoryLedgerConfigRepositoryImpl(
      dao: CategoryLedgerConfigDao(db),
    );
    transactionRepo = TransactionRepositoryImpl(
      dao: TransactionDao(db),
      encryptionService: mockEncryption,
    );
    exchangeRateRepo = ExchangeRateRepositoryImpl(dao: ExchangeRateDao(db));
    shoppingItemRepo = ShoppingItemRepositoryImpl(
      dao: ShoppingItemDao(db),
      encryptionService: mockEncryption,
    );
    settingsRepo = _MockSettingsRepository();
    when(
      () => settingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings());
    when(() => settingsRepo.updateSettings(any())).thenAnswer((_) async {});

    useCase = ImportBackupUseCase(
      transactionRepo: transactionRepo,
      categoryRepo: categoryRepo,
      categoryLedgerConfigRepo: categoryLedgerConfigRepo,
      bookRepo: bookRepo,
      shoppingItemRepo: shoppingItemRepo,
      settingsRepo: settingsRepo,
      exchangeRateRepo: exchangeRateRepo,
      unitOfWork: UnitOfWorkImpl(db: db),
      backupCrypto: BackupCryptoService(),
    );

    tempDir = await Directory.systemTemp.createTemp('import_atomicity_');

    // Seed pre-existing data the import must not destroy on failure.
    await bookRepo.insert(oldBook);
    await categoryRepo.insert(oldCategory);
    await transactionRepo.insert(oldTransaction);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  group('ImportBackupUseCase atomicity', () {
    Future<File> createJournalBackup() {
      final newBook = Book(
        id: 'book_new',
        name: 'New Book',
        currency: 'USD',
        deviceId: 'dev_002',
        createdAt: DateTime(2026, 6, 1),
      );
      final restoredSettings = const AppSettings(
        themeMode: AppThemeMode.dark,
        language: 'en',
        biometricLockEnabled: false,
        appLockEnabled: true,
        biometricUnlockEnabled: true,
        onboardingComplete: false,
        voiceLanguage: 'ja',
        voiceAllowOnDeviceFallback: false,
        monthlyJoyTarget: 500,
        weekStartDay: WeekStartDay.sunday,
      );
      return _createEncryptedBackup(
        password: 'password123',
        backupData: BackupData(
          metadata: const BackupMetadata(
            version: '1.0',
            createdAt: 1750000000000,
            deviceId: 'dev_002',
            appVersion: '0.1.0',
          ),
          transactions: const [],
          categories: const [],
          books: [newBook.toJson()],
          settings: restoredSettings.toJson(),
        ),
        filePath: '${tempDir.path}/journal.hpb',
      );
    }

    Future<void> expectPreImportDbState() async {
      final books = await bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      expect(books.map((book) => book.id), contains('book_old'));
      expect(books.map((book) => book.id), isNot(contains('book_new')));
      expect((await categoryRepo.findAll()).map((category) => category.id), [
        'cat_old',
      ]);
      expect(
        (await transactionRepo.findAllByBook('book_old')).map((tx) => tx.id),
        ['tx_old'],
      );
    }

    test(
      'preferences failure mid-apply restores the old settings and database',
      () async {
        const oldSettings = AppSettings(
          language: 'ja',
          appLockEnabled: true,
          monthlyJoyTarget: 75,
          weekStartDay: WeekStartDay.sunday,
        );
        final journalSettings = _JournalSettingsRepository(
          initialSettings: oldSettings,
          failUpdateAfterWrite: 2,
        );
        final journalUseCase = ImportBackupUseCase(
          transactionRepo: transactionRepo,
          categoryRepo: categoryRepo,
          categoryLedgerConfigRepo: categoryLedgerConfigRepo,
          bookRepo: bookRepo,
          shoppingItemRepo: shoppingItemRepo,
          settingsRepo: journalSettings,
          exchangeRateRepo: exchangeRateRepo,
          unitOfWork: UnitOfWorkImpl(db: db),
          backupCrypto: BackupCryptoService(),
        );

        final result = await journalUseCase.execute(
          backupFile: await createJournalBackup(),
          password: 'password123',
        );

        expect(result.isError, isTrue);
        expect(journalSettings.currentSettings, oldSettings);
        expect(journalSettings.compensationWrites, 10);
        await expectPreImportDbState();
      },
    );

    test(
      'database commit failure after settings apply restores both stores',
      () async {
        const oldSettings = AppSettings(
          language: 'zh',
          biometricUnlockEnabled: true,
          monthlyJoyTarget: 95,
        );
        final journalSettings = _JournalSettingsRepository(
          initialSettings: oldSettings,
        );
        final journalUseCase = ImportBackupUseCase(
          transactionRepo: transactionRepo,
          categoryRepo: categoryRepo,
          categoryLedgerConfigRepo: categoryLedgerConfigRepo,
          bookRepo: bookRepo,
          shoppingItemRepo: shoppingItemRepo,
          settingsRepo: journalSettings,
          exchangeRateRepo: exchangeRateRepo,
          unitOfWork: _CommitFailingUnitOfWork(db),
          backupCrypto: BackupCryptoService(),
        );

        final result = await journalUseCase.execute(
          backupFile: await createJournalBackup(),
          password: 'password123',
        );

        expect(result.isError, isTrue);
        expect(journalSettings.currentSettings, oldSettings);
        expect(journalSettings.compensationWrites, 10);
        await expectPreImportDbState();
      },
    );

    test(
      'successful restore commits the new database and settings together',
      () async {
        const oldSettings = AppSettings(language: 'ja', monthlyJoyTarget: 75);
        final journalSettings = _JournalSettingsRepository(
          initialSettings: oldSettings,
        );
        final journalUseCase = ImportBackupUseCase(
          transactionRepo: transactionRepo,
          categoryRepo: categoryRepo,
          categoryLedgerConfigRepo: categoryLedgerConfigRepo,
          bookRepo: bookRepo,
          shoppingItemRepo: shoppingItemRepo,
          settingsRepo: journalSettings,
          exchangeRateRepo: exchangeRateRepo,
          unitOfWork: UnitOfWorkImpl(db: db),
          backupCrypto: BackupCryptoService(),
        );

        final result = await journalUseCase.execute(
          backupFile: await createJournalBackup(),
          password: 'password123',
        );

        expect(result.isSuccess, isTrue, reason: result.error ?? '');
        expect(
          journalSettings.currentSettings,
          const AppSettings(
            themeMode: AppThemeMode.dark,
            language: 'en',
            biometricLockEnabled: false,
            appLockEnabled: true,
            biometricUnlockEnabled: true,
            onboardingComplete: true,
            voiceLanguage: 'ja',
            voiceAllowOnDeviceFallback: false,
            monthlyJoyTarget: 500,
            weekStartDay: WeekStartDay.sunday,
          ),
        );
        final books = await bookRepo.findAll(
          includeArchived: true,
          includeShadow: true,
        );
        expect(books.map((book) => book.id), ['book_new']);
      },
    );

    test(
      'reports incomplete compensation after attempting every old setting',
      () async {
        const oldSettings = AppSettings(language: 'ja', monthlyJoyTarget: 75);
        final journalSettings = _JournalSettingsRepository(
          initialSettings: oldSettings,
          failUpdateAfterWrite: 2,
          failCompensationWrite: 1,
        );
        final journalUseCase = ImportBackupUseCase(
          transactionRepo: transactionRepo,
          categoryRepo: categoryRepo,
          categoryLedgerConfigRepo: categoryLedgerConfigRepo,
          bookRepo: bookRepo,
          shoppingItemRepo: shoppingItemRepo,
          settingsRepo: journalSettings,
          exchangeRateRepo: exchangeRateRepo,
          unitOfWork: UnitOfWorkImpl(db: db),
          backupCrypto: BackupCryptoService(),
        );

        final result = await journalUseCase.execute(
          backupFile: await createJournalBackup(),
          password: 'password123',
        );

        expect(result.isError, isTrue);
        expect(result.error, contains('settings compensation incomplete'));
        expect(journalSettings.compensationWrites, 10);
        await expectPreImportDbState();
      },
    );

    test(
      'failed restore (corrupt transaction row) leaves existing data intact',
      () async {
        final newBook = Book(
          id: 'book_new',
          name: 'New Book',
          currency: 'JPY',
          deviceId: 'dev_002',
          createdAt: DateTime(2026, 6, 1),
        );
        // A transaction row missing the required `amount` field makes
        // Transaction.fromJson throw mid-restore — after deletes and
        // book/category inserts have already run.
        final corruptTxJson = oldTransaction.toJson()..remove('amount');

        final backup = BackupData(
          metadata: const BackupMetadata(
            version: '1.0',
            createdAt: 1750000000000,
            deviceId: 'dev_002',
            appVersion: '0.1.0',
          ),
          transactions: [corruptTxJson],
          categories: [oldCategory.toJson()],
          books: [newBook.toJson()],
          settings: const AppSettings().toJson(),
        );
        final file = await _createEncryptedBackup(
          password: 'password123',
          backupData: backup,
          filePath: '${tempDir.path}/corrupt.hpb',
        );

        final result = await useCase.execute(
          backupFile: file,
          password: 'password123',
        );

        expect(result.isError, isTrue);

        // Pre-import data must survive a failed restore unchanged.
        final books = await bookRepo.findAll(
          includeArchived: true,
          includeShadow: true,
        );
        expect(books.map((b) => b.id), contains('book_old'));
        expect(
          books.map((b) => b.id),
          isNot(contains('book_new')),
          reason: 'partial import must be rolled back',
        );

        final categories = await categoryRepo.findAll();
        expect(categories.map((c) => c.id), contains('cat_old'));

        final transactions = await transactionRepo.findAllByBook('book_old');
        expect(transactions.map((t) => t.id), contains('tx_old'));

        verifyNever(() => settingsRepo.updateSettings(any()));
      },
    );

    test('successful restore replaces existing data completely', () async {
      final newBook = Book(
        id: 'book_new',
        name: 'New Book',
        currency: 'JPY',
        deviceId: 'dev_002',
        createdAt: DateTime(2026, 6, 1),
      );
      final newCategory = Category(
        id: 'cat_new',
        name: 'New Category',
        icon: 'hobby',
        color: '#C8841A',
        level: 1,
        createdAt: DateTime(2026, 6, 1),
      );
      final newTransaction = Transaction(
        id: 'tx_new',
        bookId: 'book_new',
        deviceId: 'dev_002',
        amount: 3400,
        type: TransactionType.expense,
        categoryId: 'cat_new',
        ledgerType: LedgerType.joy,
        timestamp: DateTime(2026, 6, 2, 9),
        currentHash: 'hash_new',
        createdAt: DateTime(2026, 6, 2, 9),
      );

      final backup = BackupData(
        metadata: const BackupMetadata(
          version: '1.0',
          createdAt: 1750000000000,
          deviceId: 'dev_002',
          appVersion: '0.1.0',
        ),
        transactions: [newTransaction.toJson()],
        categories: [newCategory.toJson()],
        books: [newBook.toJson()],
        settings: const AppSettings().toJson(),
      );
      final file = await _createEncryptedBackup(
        password: 'password123',
        backupData: backup,
        filePath: '${tempDir.path}/valid.hpb',
      );

      final result = await useCase.execute(
        backupFile: file,
        password: 'password123',
      );

      expect(result.isSuccess, isTrue, reason: result.error ?? '');

      final books = await bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      expect(books.map((b) => b.id), ['book_new']);

      final transactions = await transactionRepo.findAllByBook('book_new');
      expect(transactions.map((t) => t.id), ['tx_new']);
      expect(await transactionRepo.findAllByBook('book_old'), isEmpty);
    });

    test(
      'full backup round trip preserves books, shopping items, and category behavior',
      () async {
        final bookA = Book(
          id: 'book_a',
          name: 'Household',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime.utc(2026, 8, 1),
        );
        final bookB = Book(
          id: 'book_b',
          name: 'Travel',
          currency: 'JPY',
          deviceId: 'dev_001',
          createdAt: DateTime.utc(2026, 8, 1),
        );
        final transactionA = Transaction(
          id: 'tx_a',
          bookId: bookA.id,
          deviceId: 'dev_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: oldCategory.id,
          ledgerType: LedgerType.daily,
          timestamp: DateTime.utc(2026, 8, 2),
          currentHash: 'hash_a',
          createdAt: DateTime.utc(2026, 8, 2),
        );
        final transactionB = Transaction(
          id: 'tx_b',
          bookId: bookB.id,
          deviceId: 'dev_001',
          amount: 2000,
          type: TransactionType.expense,
          categoryId: oldCategory.id,
          ledgerType: LedgerType.daily,
          timestamp: DateTime.utc(2026, 8, 3),
          currentHash: 'hash_b',
          createdAt: DateTime.utc(2026, 8, 3),
        );
        final customizedCategory = Category(
          id: 'cat_customized',
          name: 'Hidden custom category',
          icon: 'shopping',
          color: '#123456',
          level: 1,
          isSystem: false,
          isArchived: true,
          sortOrder: 77,
          createdAt: DateTime.utc(2026, 8, 1),
        );
        final categoryConfig = CategoryLedgerConfig(
          categoryId: customizedCategory.id,
          ledgerType: LedgerType.joy,
          updatedAt: DateTime.utc(2026, 8, 2),
        );
        final shoppingItem = ShoppingItem(
          id: 'shopping_archived',
          deviceId: 'dev_001',
          listType: 'private',
          name: 'Archived coffee',
          ledgerType: LedgerType.joy,
          categoryId: customizedCategory.id,
          tags: const ['weekly'],
          note: 'Preserve me',
          quantity: 2.5,
          unit: ShoppingUnit.pack,
          estimatedPrice: 1800,
          completedAt: DateTime.utc(2026, 8, 3),
          isCompleted: true,
          sortOrder: 12,
          isDeleted: true,
          createdAt: DateTime.utc(2026, 8, 2),
          updatedAt: DateTime.utc(2026, 8, 3),
          syncRevision: 4,
          syncOriginDeviceId: 'dev_001',
        );
        await bookRepo.insert(bookA);
        await bookRepo.insert(bookB);
        await categoryRepo.insert(customizedCategory);
        await categoryLedgerConfigRepo.upsert(categoryConfig);
        await transactionRepo.insert(transactionA);
        await transactionRepo.insert(transactionB);
        await shoppingItemRepo.upsert(shoppingItem);

        final exportUseCase = ExportBackupUseCase(
          transactionRepo: transactionRepo,
          categoryRepo: categoryRepo,
          categoryLedgerConfigRepo: categoryLedgerConfigRepo,
          bookRepo: bookRepo,
          shoppingItemRepo: shoppingItemRepo,
          settingsRepo: settingsRepo,
          exchangeRateRepo: exchangeRateRepo,
          unitOfWork: UnitOfWorkImpl(db: db),
          backupCrypto: BackupCryptoService(),
        );
        when(
          () => settingsRepo.getSettings(),
        ).thenAnswer((_) async => const AppSettings());

        final exported = await exportUseCase.execute(
          bookId: bookA.id,
          password: 'password123',
          outputDirectory: tempDir,
        );
        expect(exported.isSuccess, isTrue, reason: exported.error ?? '');

        // A post-backup write confirms import replaces book B with its
        // archived transaction rather than silently leaving it empty.
        await transactionRepo.insert(
          transactionB.copyWith(
            id: 'tx_b_after_backup',
            timestamp: DateTime.utc(2026, 8, 4),
            createdAt: DateTime.utc(2026, 8, 4),
            currentHash: 'hash_b_after_backup',
          ),
        );
        await shoppingItemRepo.deleteAll();
        await categoryLedgerConfigRepo.deleteAll();

        final restored = await useCase.execute(
          backupFile: exported.data!,
          password: 'password123',
        );

        expect(restored.isSuccess, isTrue, reason: restored.error ?? '');
        expect(
          (await transactionRepo.findAllByBook(bookA.id)).map((tx) => tx.id),
          ['tx_a'],
        );
        expect(
          (await transactionRepo.findAllByBook(bookB.id)).map((tx) => tx.id),
          ['tx_b'],
          reason: 'restoring a full archive must not empty a second book',
        );
        final restoredCategory = await categoryRepo.findById(
          customizedCategory.id,
        );
        expect(restoredCategory?.isArchived, isTrue);
        expect(restoredCategory?.sortOrder, 77);
        final restoredCategoryConfig = await categoryLedgerConfigRepo.findById(
          customizedCategory.id,
        );
        expect(restoredCategoryConfig?.categoryId, customizedCategory.id);
        expect(restoredCategoryConfig?.ledgerType, LedgerType.joy);
        final restoredShoppingItems = await shoppingItemRepo.findAll(
          includeDeleted: true,
        );
        expect(restoredShoppingItems, hasLength(1));
        expect(restoredShoppingItems.single.id, shoppingItem.id);
        expect(restoredShoppingItems.single.note, shoppingItem.note);
        expect(restoredShoppingItems.single.isCompleted, isTrue);
        expect(restoredShoppingItems.single.isDeleted, isTrue);
        expect(restoredShoppingItems.single.sortOrder, 12);
      },
    );
  });
}
