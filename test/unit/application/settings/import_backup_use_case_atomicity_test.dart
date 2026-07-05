import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
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
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/models/backup_data.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// Encrypts [backupData] into a valid `.hpb` file (same binary format the
/// export use case produces: salt(16) + nonce(12) + ciphertext + mac(16)).
Future<File> _createEncryptedBackup({
  required String password,
  required BackupData backupData,
  required String filePath,
}) async {
  final jsonString = jsonEncode(backupData.toJson());
  final gzipBytes = gzip.encode(utf8.encode(jsonString));

  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  final random = Random.secure();
  final salt = List.generate(16, (_) => random.nextInt(256));
  final nonce = List.generate(12, (_) => random.nextInt(256));

  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );

  final algorithm = AesGcm.with256bits();
  final secretBox = await algorithm.encrypt(
    gzipBytes,
    secretKey: secretKey,
    nonce: nonce,
  );

  final result = <int>[
    ...salt,
    ...nonce,
    ...secretBox.cipherText,
    ...secretBox.mac.bytes,
  ];

  final file = File(filePath);
  await file.writeAsBytes(Uint8List.fromList(result));
  return file;
}

void main() {
  late AppDatabase db;
  late BookRepositoryImpl bookRepo;
  late CategoryRepositoryImpl categoryRepo;
  late TransactionRepositoryImpl transactionRepo;
  late ExchangeRateRepositoryImpl exchangeRateRepo;
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
    transactionRepo = TransactionRepositoryImpl(
      dao: TransactionDao(db),
      encryptionService: mockEncryption,
    );
    exchangeRateRepo = ExchangeRateRepositoryImpl(dao: ExchangeRateDao(db));
    settingsRepo = _MockSettingsRepository();
    when(() => settingsRepo.updateSettings(any())).thenAnswer((_) async {});

    useCase = ImportBackupUseCase(
      transactionRepo: transactionRepo,
      categoryRepo: categoryRepo,
      bookRepo: bookRepo,
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
  });
}
