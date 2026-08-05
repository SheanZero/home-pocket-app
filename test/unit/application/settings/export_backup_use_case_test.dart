import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/export_backup_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/currency/domain/models/exchange_rate.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';

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

void main() {
  final backupCrypto = BackupCryptoService();
  late ExportBackupUseCase useCase;
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
    useCase = ExportBackupUseCase(
      transactionRepo: mockTransactionRepo,
      categoryRepo: mockCategoryRepo,
      bookRepo: mockBookRepo,
      settingsRepo: mockSettingsRepo,
      exchangeRateRepo: mockExchangeRateRepo,
      unitOfWork: _FakeUnitOfWork(),
      backupCrypto: backupCrypto,
    );

    tempDir = await Directory.systemTemp.createTemp('backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('rejects password shorter than 8 characters', () async {
    final result = await useCase.execute(bookId: 'book-1', password: 'short');

    expect(result.isError, true);
    expect(result.error, contains('at least 8 characters'));
  });

  test('exports backup with correct encrypted format', () async {
    // Arrange
    final now = DateTime(2026, 2, 7);
    when(() => mockTransactionRepo.findAllByBook('book-1')).thenAnswer(
      (_) async => [
        Transaction(
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
        ),
      ],
    );
    when(() => mockCategoryRepo.findAll()).thenAnswer(
      (_) async => [
        Category(
          id: 'cat-1',
          name: 'Food',
          icon: 'food',
          color: '#FF0000',
          level: 1,
          createdAt: now,
        ),
      ],
    );
    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer(
      (_) async => [
        Book(
          id: 'book-1',
          name: 'Default',
          currency: 'JPY',
          deviceId: 'dev',
          createdAt: now,
        ),
      ],
    );
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings());
    when(() => mockExchangeRateRepo.findAll()).thenAnswer((_) async => []);

    // Act - use temp directory to avoid path_provider dependency in test
    final result = await useCase.execute(
      bookId: 'book-1',
      password: 'test-password-123',
      deviceId: 'test-device',
      appVersion: '0.1.0',
      outputDirectory: tempDir,
    );

    // Assert
    expect(result.isSuccess, true);
    final file = result.data!;
    expect(await file.exists(), true);
    expect(file.path.endsWith('.hpb'), true);

    // Verify the v2 self-describing format: 'HPB' magic + version byte 2
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(54)); // header + salt + nonce + mac
    expect(bytes.sublist(0, 3), equals(utf8.encode('HPB')));
    expect(bytes[3], equals(2));

    // Verify we can decrypt back through the crypto layer
    final plaintext = await backupCrypto.decrypt(bytes, 'test-password-123');

    // Decompress
    final jsonBytes = gzip.decode(plaintext);
    final jsonString = utf8.decode(jsonBytes);
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    expect(json['metadata']['version'], '1.0');
    expect(json['metadata']['deviceId'], 'test-device');
    expect((json['transactions'] as List).length, 1);
    expect((json['categories'] as List).length, 1);
    expect((json['books'] as List).length, 1);

    // Cleanup
    await file.delete();
  });

  test(
    'exports transactions for every retained book, not only the selected book',
    () async {
      final now = DateTime.utc(2026, 8, 5);
      final bookA = Book(
        id: 'book-a',
        name: 'Household',
        currency: 'JPY',
        deviceId: 'dev',
        createdAt: now,
      );
      final bookB = Book(
        id: 'book-b',
        name: 'Travel',
        currency: 'JPY',
        deviceId: 'dev',
        createdAt: now,
      );
      final transactionA = Transaction(
        id: 'tx-a',
        bookId: bookA.id,
        deviceId: 'dev',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        ledgerType: LedgerType.daily,
        timestamp: now,
        currentHash: 'hash-a',
        createdAt: now,
      );
      final transactionB = Transaction(
        id: 'tx-b',
        bookId: bookB.id,
        deviceId: 'dev',
        amount: 2000,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        ledgerType: LedgerType.daily,
        timestamp: now,
        currentHash: 'hash-b',
        createdAt: now,
      );
      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => [bookA, bookB]);
      when(
        () => mockTransactionRepo.findAllByBook(bookA.id),
      ).thenAnswer((_) async => [transactionA]);
      when(
        () => mockTransactionRepo.findAllByBook(bookB.id),
      ).thenAnswer((_) async => [transactionB]);
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockSettingsRepo.getSettings(),
      ).thenAnswer((_) async => const AppSettings());
      when(() => mockExchangeRateRepo.findAll()).thenAnswer((_) async => []);

      final result = await useCase.execute(
        bookId: bookA.id,
        password: 'test-password-123',
        outputDirectory: tempDir,
      );

      expect(result.isSuccess, isTrue);
      final encrypted = await result.data!.readAsBytes();
      final plaintext = await backupCrypto.decrypt(
        encrypted,
        'test-password-123',
      );
      final root =
          jsonDecode(utf8.decode(gzip.decode(plaintext)))
              as Map<String, dynamic>;
      final transactions = root['transactions'] as List<dynamic>;
      expect(
        transactions.map((entry) => (entry as Map<String, dynamic>)['bookId']),
        containsAllInOrder([bookA.id, bookB.id]),
      );
    },
  );

  test(
    'keeps two same-instant exports as distinct readable files without temp files',
    () async {
      final exportedAt = DateTime.utc(2026, 8, 5, 12, 34, 56, 789);
      useCase = ExportBackupUseCase(
        transactionRepo: mockTransactionRepo,
        categoryRepo: mockCategoryRepo,
        bookRepo: mockBookRepo,
        settingsRepo: mockSettingsRepo,
        exchangeRateRepo: mockExchangeRateRepo,
        unitOfWork: _FakeUnitOfWork(),
        backupCrypto: backupCrypto,
        clock: () => exportedAt,
        backupIdGenerator: () => 'fixed-token',
      );
      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer((_) async => []);
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockSettingsRepo.getSettings(),
      ).thenAnswer((_) async => const AppSettings());
      when(() => mockExchangeRateRepo.findAll()).thenAnswer((_) async => []);

      final first = await useCase.execute(
        bookId: 'book-1',
        password: 'test-password-123',
        outputDirectory: tempDir,
      );
      final second = await useCase.execute(
        bookId: 'book-1',
        password: 'test-password-123',
        outputDirectory: tempDir,
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(first.data!.path, isNot(second.data!.path));
      expect(
        first.data!.uri.pathSegments.last,
        'homepocket_backup_20260805T123456789Z_fixed-token.hpb',
      );
      expect(
        second.data!.uri.pathSegments.last,
        'homepocket_backup_20260805T123456789Z_fixed-token-1.hpb',
      );

      for (final file in [first.data!, second.data!]) {
        final plaintext = await backupCrypto.decrypt(
          await file.readAsBytes(),
          'test-password-123',
        );
        expect(jsonDecode(utf8.decode(gzip.decode(plaintext))), isA<Map>());
      }
      final leftovers = await tempDir
          .list()
          .where((entity) => entity.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    },
  );

  test('D-10: includes exchange rates in epoch-seconds backup shape', () async {
    when(
      () => mockTransactionRepo.findAllByBook('book-1'),
    ).thenAnswer((_) async => []);
    when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
    when(
      () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
    ).thenAnswer((_) async => []);
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings());
    when(() => mockExchangeRateRepo.findAll()).thenAnswer(
      (_) async => [
        ExchangeRate(
          currency: 'USD',
          rateDate: DateTime.utc(2026, 6, 11),
          rate: '157.34',
          fetchedAt: DateTime.utc(2026, 6, 11, 9),
          source: 'frankfurter',
          actualRateDate: DateTime.utc(2026, 6, 10),
        ),
      ],
    );

    final result = await useCase.execute(
      bookId: 'book-1',
      password: 'test-password-123',
      deviceId: 'test-device',
      appVersion: '0.1.0',
      outputDirectory: tempDir,
    );

    expect(result.isSuccess, true);
    final file = result.data!;
    final bytes = await file.readAsBytes();

    final plaintext = await backupCrypto.decrypt(bytes, 'test-password-123');
    final jsonString = utf8.decode(gzip.decode(plaintext));
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    final rates = json['exchangeRates'] as List;
    expect(rates.length, 1);
    final rate = rates.first as Map<String, dynamic>;
    expect(rate['currency'], 'USD');
    expect(rate['rate'], '157.34');
    expect(rate['source'], 'frankfurter');
    expect(
      rate['rateDate'],
      DateTime.utc(2026, 6, 11).millisecondsSinceEpoch ~/ 1000,
    );
    expect(
      rate['actualRateDate'],
      DateTime.utc(2026, 6, 10).millisecondsSinceEpoch ~/ 1000,
    );

    await file.delete();
  });

  test(
    'receipt photo backup stores availability but never local hash',
    () async {
      final now = DateTime.utc(2026, 8, 1);
      when(() => mockTransactionRepo.findAllByBook('book-1')).thenAnswer(
        (_) async => [
          Transaction(
            id: 'tx-photo',
            bookId: 'book-1',
            deviceId: 'dev',
            amount: 900,
            type: TransactionType.expense,
            categoryId: 'cat-1',
            ledgerType: LedgerType.daily,
            timestamp: now,
            photoHash: 'local-content-hash',
            currentHash: 'chain',
            createdAt: now,
          ),
        ],
      );
      when(() => mockCategoryRepo.findAll()).thenAnswer((_) async => []);
      when(
        () => mockBookRepo.findAll(includeArchived: true, includeShadow: true),
      ).thenAnswer(
        (_) async => [
          Book(
            id: 'book-1',
            name: 'Default',
            currency: 'JPY',
            deviceId: 'dev',
            createdAt: now,
          ),
        ],
      );
      when(
        () => mockSettingsRepo.getSettings(),
      ).thenAnswer((_) async => const AppSettings());
      when(() => mockExchangeRateRepo.findAll()).thenAnswer((_) async => []);

      final result = await useCase.execute(
        bookId: 'book-1',
        password: 'test-password-123',
        outputDirectory: tempDir,
      );

      final encrypted = await result.data!.readAsBytes();
      final plaintext = await backupCrypto.decrypt(
        encrypted,
        'test-password-123',
      );
      final root =
          jsonDecode(utf8.decode(gzip.decode(plaintext)))
              as Map<String, dynamic>;
      final transaction =
          (root['transactions'] as List).single as Map<String, dynamic>;
      expect(transaction, isNot(contains('photoHash')));
      expect(transaction['photoAvailability'], 'local_only');
    },
  );
}
