import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/models/backup_data.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';

/// Passthrough — these mock-based tests assert repository interactions, not
/// transactional rollback (covered by the *_atomicity_test with a real DB).
class _FakeUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBookRepository extends Mock implements BookRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

/// Helper to create an encrypted backup file for testing.
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
  late ImportBackupUseCase useCase;
  late MockTransactionRepository mockTransactionRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockBookRepository mockBookRepo;
  late MockSettingsRepository mockSettingsRepo;
  late MockExchangeRateRepository mockExchangeRateRepo;
  late Directory tempDir;

  setUp(() async {
    mockTransactionRepo = MockTransactionRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockBookRepo = MockBookRepository();
    mockSettingsRepo = MockSettingsRepository();
    mockExchangeRateRepo = MockExchangeRateRepository();
    useCase = ImportBackupUseCase(
      transactionRepo: mockTransactionRepo,
      categoryRepo: mockCategoryRepo,
      bookRepo: mockBookRepo,
      settingsRepo: mockSettingsRepo,
      exchangeRateRepo: mockExchangeRateRepo,
      unitOfWork: _FakeUnitOfWork(),
      // Real service: the legacy-format helper below doubles as coverage for
      // the pre-v2 back-compat decrypt path.
      backupCrypto: BackupCryptoService(),
    );

    tempDir = await Directory.systemTemp.createTemp('import_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUpAll(() {
    registerFallbackValue(const AppSettings());
    registerFallbackValue(
      Book(
        id: '',
        name: '',
        currency: '',
        deviceId: '',
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      Category(
        id: '',
        name: '',
        icon: '',
        color: '',
        level: 0,
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      Transaction(
        id: '',
        bookId: '',
        deviceId: '',
        amount: 0,
        type: TransactionType.expense,
        categoryId: '',
        ledgerType: LedgerType.daily,
        timestamp: DateTime(2026),
        currentHash: '',
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      ExchangeRate(
        currency: '',
        rateDate: DateTime.utc(2026),
        rate: '1',
        fetchedAt: DateTime.utc(2026),
        source: 'frankfurter',
      ),
    );
  });

  test('rejects file that is too small', () async {
    final file = File('${tempDir.path}/tiny.hpb');
    await file.writeAsBytes([1, 2, 3]); // Only 3 bytes

    final result = await useCase.execute(
      backupFile: file,
      password: 'test-password-123',
    );

    expect(result.isError, true);
    expect(result.error, contains('too small'));
  });

  test('rejects wrong password', () async {
    final backupData = BackupData(
      metadata: BackupMetadata(
        version: '1.0',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test',
        appVersion: '0.1.0',
      ),
      transactions: [],
      categories: [],
      books: [],
      settings: const AppSettings().toJson(),
    );

    final file = await _createEncryptedBackup(
      password: 'correct-password',
      backupData: backupData,
      filePath: '${tempDir.path}/backup.hpb',
    );

    final result = await useCase.execute(
      backupFile: file,
      password: 'wrong-password-123',
    );

    expect(result.isError, true);
    expect(result.error, contains('Incorrect password'));
  });

  test('rejects unsupported backup version', () async {
    final backupData = BackupData(
      metadata: BackupMetadata(
        version: '2.0',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: 'test',
        appVersion: '0.1.0',
      ),
      transactions: [],
      categories: [],
      books: [],
      settings: const AppSettings().toJson(),
    );

    final file = await _createEncryptedBackup(
      password: 'test-password-123',
      backupData: backupData,
      filePath: '${tempDir.path}/backup.hpb',
    );

    final result = await useCase.execute(
      backupFile: file,
      password: 'test-password-123',
    );

    expect(result.isError, true);
    expect(result.error, contains('Unsupported backup version'));
  });

  test('restores data successfully', () async {
    // Arrange
    final now = DateTime(2026, 2, 7);
    final book = Book(
      id: 'book-1',
      name: 'Default',
      currency: 'JPY',
      deviceId: 'dev',
      createdAt: now,
    );
    final category = Category(
      id: 'cat-1',
      name: 'Food',
      icon: 'food',
      color: '#FF0000',
      level: 1,
      createdAt: now,
    );
    final transaction = Transaction(
      id: 'tx-1',
      bookId: 'book-1',
      deviceId: 'dev',
      amount: 1000,
      type: TransactionType.expense,
      categoryId: 'cat-1',
      ledgerType: LedgerType.daily,
      timestamp: now,
      currentHash: 'hash1',
      createdAt: now,
    );

    final backupData = BackupData(
      metadata: BackupMetadata(
        version: '1.0',
        createdAt: now.millisecondsSinceEpoch,
        deviceId: 'test',
        appVersion: '0.1.0',
      ),
      transactions: [transaction.toJson()],
      categories: [category.toJson()],
      books: [book.toJson()],
      settings: const AppSettings(language: 'en').toJson(),
    );

    final file = await _createEncryptedBackup(
      password: 'test-password-123',
      backupData: backupData,
      filePath: '${tempDir.path}/backup.hpb',
    );

    // Mock existing data
    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockBookRepo.insert(any())).thenAnswer((_) async {});
    when(() => mockCategoryRepo.insert(any())).thenAnswer((_) async {});
    when(() => mockTransactionRepo.insert(any())).thenAnswer((_) async {});
    when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async {});
    when(() => mockExchangeRateRepo.upsert(any())).thenAnswer((_) async {});

    // Act
    final result = await useCase.execute(
      backupFile: file,
      password: 'test-password-123',
    );

    // Assert
    expect(result.isSuccess, true);
    verify(() => mockBookRepo.insert(any())).called(1);
    verify(() => mockCategoryRepo.insert(any())).called(1);
    verify(() => mockTransactionRepo.insert(any())).called(1);
    verify(() => mockSettingsRepo.updateSettings(any())).called(1);
  });

  test('D-10: upserts each exchange rate from the backup', () async {
    final now = DateTime(2026, 2, 7);
    final backupData = BackupData(
      metadata: BackupMetadata(
        version: '1.0',
        createdAt: now.millisecondsSinceEpoch,
        deviceId: 'test',
        appVersion: '0.1.0',
      ),
      transactions: [],
      categories: [],
      books: [],
      settings: const AppSettings().toJson(),
      exchangeRates: [
        {
          'currency': 'USD',
          'rateDate': DateTime.utc(2026, 6, 11).millisecondsSinceEpoch ~/ 1000,
          'rate': '157.34',
          'fetchedAt':
              DateTime.utc(2026, 6, 11, 9).millisecondsSinceEpoch ~/ 1000,
          'source': 'frankfurter',
          'actualRateDate':
              DateTime.utc(2026, 6, 10).millisecondsSinceEpoch ~/ 1000,
        },
      ],
    );

    final file = await _createEncryptedBackup(
      password: 'test-password-123',
      backupData: backupData,
      filePath: '${tempDir.path}/backup.hpb',
    );

    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
    when(() => mockSettingsRepo.updateSettings(any())).thenAnswer((_) async {});
    when(() => mockExchangeRateRepo.upsert(any())).thenAnswer((_) async {});

    final result = await useCase.execute(
      backupFile: file,
      password: 'test-password-123',
    );

    expect(result.isSuccess, true);
    final captured =
        verify(() => mockExchangeRateRepo.upsert(captureAny())).captured.single
            as ExchangeRate;
    expect(captured.currency, 'USD');
    expect(captured.rate, '157.34');
    expect(captured.source, 'frankfurter');
    expect(captured.rateDate, DateTime.utc(2026, 6, 11));
    expect(captured.actualRateDate, DateTime.utc(2026, 6, 10));
  });

  test(
    'D-06: old backup lacking onboarding_complete → forces onboardingComplete true',
    () async {
      final now = DateTime(2026, 2, 7);
      // Simulate a pre-Phase-54 backup whose settings map omits the key entirely.
      final settingsMap = const AppSettings(language: 'en').toJson();
      settingsMap.remove('onboarding_complete');

      final backupData = BackupData(
        metadata: BackupMetadata(
          version: '1.0',
          createdAt: now.millisecondsSinceEpoch,
          deviceId: 'test',
          appVersion: '0.1.0',
        ),
        transactions: [],
        categories: [],
        books: [],
        settings: settingsMap,
      );

      final file = await _createEncryptedBackup(
        password: 'test-password-123',
        backupData: backupData,
        filePath: '${tempDir.path}/backup.hpb',
      );

      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
      when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
      when(
        () => mockSettingsRepo.updateSettings(any()),
      ).thenAnswer((_) async {});

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password-123',
      );

      expect(result.isSuccess, true);
      final persisted =
          verify(
                () => mockSettingsRepo.updateSettings(captureAny()),
              ).captured.single
              as AppSettings;
      expect(persisted.onboardingComplete, true);
    },
  );

  test(
    'D-06: backup with onboarding_complete=false → still forced true',
    () async {
      final now = DateTime(2026, 2, 7);
      final backupData = BackupData(
        metadata: BackupMetadata(
          version: '1.0',
          createdAt: now.millisecondsSinceEpoch,
          deviceId: 'test',
          appVersion: '0.1.0',
        ),
        transactions: [],
        categories: [],
        books: [],
        settings: const AppSettings(onboardingComplete: false).toJson(),
      );

      final file = await _createEncryptedBackup(
        password: 'test-password-123',
        backupData: backupData,
        filePath: '${tempDir.path}/backup.hpb',
      );

      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
      when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
      when(
        () => mockSettingsRepo.updateSettings(any()),
      ).thenAnswer((_) async {});

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password-123',
      );

      expect(result.isSuccess, true);
      final persisted =
          verify(
                () => mockSettingsRepo.updateSettings(captureAny()),
              ).captured.single
              as AppSettings;
      expect(persisted.onboardingComplete, true);
    },
  );

  test(
    'CR-01: skips imported rows with an invalid rate but keeps valid ones',
    () async {
      final now = DateTime(2026, 2, 7);
      Map<String, dynamic> rateJson(
        String rate, {
        String source = 'frankfurter',
      }) {
        return {
          'currency': 'USD',
          'rateDate': DateTime.utc(2026, 6, 11).millisecondsSinceEpoch ~/ 1000,
          'rate': rate,
          'fetchedAt':
              DateTime.utc(2026, 6, 11, 9).millisecondsSinceEpoch ~/ 1000,
          'source': source,
          'actualRateDate': null,
        };
      }

      final backupData = BackupData(
        metadata: BackupMetadata(
          version: '1.0',
          createdAt: now.millisecondsSinceEpoch,
          deviceId: 'test',
          appVersion: '0.1.0',
        ),
        transactions: [],
        categories: [],
        books: [],
        settings: const AppSettings().toJson(),
        exchangeRates: [
          rateJson('abc'), // non-numeric
          rateJson('-1'), // negative
          rateJson('0'), // zero
          rateJson('Infinity'), // non-finite literal
          rateJson('NaN'), // non-finite literal
          rateJson('1e9'), // scientific notation rejected (ADR-020 D-05)
          rateJson('157.34', source: 'evil'), // unknown source
          rateJson('157.34'), // the one valid row
        ],
      );

      final file = await _createEncryptedBackup(
        password: 'test-password-123',
        backupData: backupData,
        filePath: '${tempDir.path}/backup.hpb',
      );

      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.deleteAll()).thenAnswer((_) async {});
      when(() => mockBookRepo.deleteAll()).thenAnswer((_) async {});
      when(
        () => mockSettingsRepo.updateSettings(any()),
      ).thenAnswer((_) async {});
      when(() => mockExchangeRateRepo.upsert(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password-123',
      );

      expect(result.isSuccess, true);
      // Only the single valid row reaches the cache — all poison rows skipped.
      final captured = verify(
        () => mockExchangeRateRepo.upsert(captureAny()),
      ).captured;
      expect(captured.length, 1);
      expect((captured.single as ExchangeRate).rate, '157.34');
    },
  );
}
