import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/settings/import_backup_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/currency/domain/repositories/exchange_rate_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/domain/repositories/unit_of_work.dart';
import 'package:home_pocket/infrastructure/crypto/services/backup_crypto_service.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockCategoryLedgerConfigRepository extends Mock
    implements CategoryLedgerConfigRepository {}

class _MockBookRepository extends Mock implements BookRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockExchangeRateRepository extends Mock
    implements ExchangeRateRepository {}

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _FakeUnitOfWork implements UnitOfWork {
  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}

class _ReturningBackupCryptoService extends BackupCryptoService {
  _ReturningBackupCryptoService(this.plaintext);

  final Uint8List plaintext;
  int decryptCallCount = 0;

  @override
  Future<Uint8List> decrypt(Uint8List data, String password) async {
    decryptCallCount += 1;
    return plaintext;
  }
}

void main() {
  late Directory tempDir;
  late _MockTransactionRepository transactionRepo;
  late _MockCategoryRepository categoryRepo;
  late _MockCategoryLedgerConfigRepository categoryLedgerConfigRepo;
  late _MockBookRepository bookRepo;
  late _MockSettingsRepository settingsRepo;
  late _MockExchangeRateRepository exchangeRateRepo;
  late _MockShoppingItemRepository shoppingItemRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_limits_test_');
    transactionRepo = _MockTransactionRepository();
    categoryRepo = _MockCategoryRepository();
    categoryLedgerConfigRepo = _MockCategoryLedgerConfigRepository();
    bookRepo = _MockBookRepository();
    settingsRepo = _MockSettingsRepository();
    exchangeRateRepo = _MockExchangeRateRepository();
    shoppingItemRepo = _MockShoppingItemRepository();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  ImportBackupUseCase createUseCase({
    required BackupCryptoService backupCrypto,
    required BackupImportLimits limits,
  }) {
    return ImportBackupUseCase(
      transactionRepo: transactionRepo,
      categoryRepo: categoryRepo,
      categoryLedgerConfigRepo: categoryLedgerConfigRepo,
      bookRepo: bookRepo,
      shoppingItemRepo: shoppingItemRepo,
      settingsRepo: settingsRepo,
      exchangeRateRepo: exchangeRateRepo,
      unitOfWork: _FakeUnitOfWork(),
      backupCrypto: backupCrypto,
      limits: limits,
    );
  }

  test(
    'rejects an encrypted file over the input limit before decrypting',
    () async {
      final file = File('${tempDir.path}/oversized.hpb');
      await file.writeAsBytes(List<int>.filled(9, 0));
      final backupCrypto = _ReturningBackupCryptoService(Uint8List(0));
      final useCase = createUseCase(
        backupCrypto: backupCrypto,
        limits: const BackupImportLimits(
          maxEncryptedBytes: 8,
          maxDecompressedBytes: 64,
        ),
      );

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password',
      );

      expect(result.isError, isTrue);
      expect(result.error, BackupImportError.encryptedFileTooLarge.name);
      expect(backupCrypto.decryptCallCount, 0);
      verifyNever(
        () => bookRepo.findAll(includeArchived: true, includeShadow: true),
      );
    },
  );

  test(
    'stops GZip expansion when decompressed data exceeds its limit',
    () async {
      final file = File('${tempDir.path}/compressed.hpb');
      await file.writeAsBytes([1, 2, 3, 4]);
      final compressedBomb = Uint8List.fromList(
        gzip.encode(utf8.encode('A' * 1024)),
      );
      final backupCrypto = _ReturningBackupCryptoService(compressedBomb);
      final useCase = createUseCase(
        backupCrypto: backupCrypto,
        limits: const BackupImportLimits(
          maxEncryptedBytes: 64,
          maxDecompressedBytes: 128,
        ),
      );

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password',
      );

      expect(result.isError, isTrue);
      expect(result.error, BackupImportError.decompressedDataTooLarge.name);
      expect(backupCrypto.decryptCallCount, 1);
      verifyNever(
        () => bookRepo.findAll(includeArchived: true, includeShadow: true),
      );
    },
  );

  test(
    'accepts encrypted and decompressed data exactly at each limit',
    () async {
      final file = File('${tempDir.path}/at-limit.hpb');
      await file.writeAsBytes([1, 2, 3, 4]);
      final compressedData = Uint8List.fromList(
        gzip.encode(utf8.encode('A' * 128)),
      );
      final backupCrypto = _ReturningBackupCryptoService(compressedData);
      final useCase = createUseCase(
        backupCrypto: backupCrypto,
        limits: const BackupImportLimits(
          maxEncryptedBytes: 4,
          maxDecompressedBytes: 128,
        ),
      );

      final result = await useCase.execute(
        backupFile: file,
        password: 'test-password',
      );

      expect(result.isError, isTrue);
      expect(result.error, 'Backup file is corrupted');
      expect(backupCrypto.decryptCallCount, 1);
    },
  );
}
