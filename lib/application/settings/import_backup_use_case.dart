import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/currency/domain/models/exchange_rate.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/settings/domain/models/backup_data.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/repositories/unit_of_work.dart';
import '../../infrastructure/crypto/services/backup_crypto_service.dart';
import '../../shared/utils/currency_conversion.dart';
import '../../shared/utils/result.dart';

/// Restores app data from an encrypted backup file (.hpb).
///
/// Algorithm: decrypt ([BackupCryptoService]) → GZip decompress → JSON parse
/// → DB restore.
class ImportBackupUseCase {
  ImportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
    required ExchangeRateRepository exchangeRateRepo,
    required UnitOfWork unitOfWork,
    required BackupCryptoService backupCrypto,
  }) : _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo,
       _bookRepo = bookRepo,
       _settingsRepo = settingsRepo,
       _exchangeRateRepo = exchangeRateRepo,
       _unitOfWork = unitOfWork,
       _backupCrypto = backupCrypto;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;
  final ExchangeRateRepository _exchangeRateRepo;
  final UnitOfWork _unitOfWork;
  final BackupCryptoService _backupCrypto;

  Future<Result<void>> execute({
    required File backupFile,
    required String password,
  }) async {
    try {
      // 1. Read encrypted file
      final encryptedData = await backupFile.readAsBytes();

      // 2. Decrypt (format detection, size validation and KDF handling live
      // in the crypto layer — legacy and v2 .hpb files both supported).
      final Uint8List decryptedData;
      try {
        decryptedData = await _backupCrypto.decrypt(encryptedData, password);
      } on InvalidBackupFormatException catch (e) {
        return Result.error(e.toString());
      } on UnsupportedBackupFormatException catch (e) {
        return Result.error(e.toString());
      } on BackupDecryptionException {
        return Result.error('Incorrect password');
      }

      // 4. Decompress
      final jsonBytes = gzip.decode(decryptedData);
      final jsonString = utf8.decode(jsonBytes);

      // 5. Parse JSON
      final Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return Result.error('Backup file is corrupted');
      }

      final backupData = BackupData.fromJson(jsonMap);

      // 6. Validate version
      if (backupData.metadata.version != '1.0') {
        return Result.error(
          'Unsupported backup version: ${backupData.metadata.version}',
        );
      }

      // 7. Restore data
      await _restoreData(backupData);

      return Result.success(null);
    } catch (e) {
      return Result.error('Backup import failed: $e');
    }
  }

  Future<void> _restoreData(BackupData backupData) async {
    // Atomicity: the whole delete+reinsert sequence runs inside one database
    // transaction — a corrupt or hostile row that aborts mid-restore must
    // roll back to the pre-import state instead of leaving the DB half-wiped.
    await _unitOfWork.run(() async {
      // Delete existing data first
      // Get all books to delete their transactions
      final existingBooks = await _bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      for (final book in existingBooks) {
        await _transactionRepo.deleteAllByBook(book.id);
      }
      await _categoryRepo.deleteAll();
      await _bookRepo.deleteAll();

      // Import books
      for (final bookJson in backupData.books) {
        final book = Book.fromJson(bookJson);
        await _bookRepo.insert(book);
      }

      // Import categories
      for (final catJson in backupData.categories) {
        final category = Category.fromJson(catJson);
        await _categoryRepo.insert(category);
      }

      // Import transactions
      for (final txJson in backupData.transactions) {
        final transaction = Transaction.fromJson(txJson);
        await _transactionRepo.insert(transaction);
      }

      // Import exchange rates (D-10): upsert, not insert — idempotent by the
      // (currency, rateDate) composite key. Epoch-seconds → UTC DateTime.
      //
      // CR-01 trust boundary: a decrypted backup's contents are NOT
      // authenticated — the password protects confidentiality, not integrity.
      // Each imported rate is therefore routed through the SAME canonical
      // validation floor as the manual-override write path
      // (validateAppliedRate, ADR-020 single-parse-site / T-41-13). Rows with
      // a non-numeric / <=0 / non-finite / scientific-notation rate, or an
      // unrecognized source, are SKIPPED rather than persisted — a hostile or
      // corrupted row must not poison the cache, where convertToJpy would
      // later throw on it.
      for (final erJson in backupData.exchangeRates) {
        final rawRate = erJson['rate'] as String;
        if (validateAppliedRate(rawRate) != null) {
          // Invalid rate literal — skip this row, keep importing the rest.
          continue;
        }

        final source = erJson['source'] as String;
        if (!_validBackupRateSources.contains(source)) {
          // Unknown source would break the D-07 manual/non-manual fallback
          // partition — skip rather than trust an arbitrary value.
          continue;
        }

        final er = ExchangeRate(
          currency: erJson['currency'] as String,
          rateDate: DateTime.fromMillisecondsSinceEpoch(
            (erJson['rateDate'] as int) * 1000,
            isUtc: true,
          ),
          rate: rawRate,
          fetchedAt: DateTime.fromMillisecondsSinceEpoch(
            (erJson['fetchedAt'] as int) * 1000,
            isUtc: true,
          ),
          source: source,
          actualRateDate: erJson['actualRateDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (erJson['actualRateDate'] as int) * 1000,
                  isUtc: true,
                )
              : null,
        );
        await _exchangeRateRepo.upsert(er);
      }

      // Import settings (D-06): a restored backup represents an existing
      // user, so force onboardingComplete=true — even for pre-Phase-54
      // backups whose settings map omits the key — so import skips
      // onboarding. No BackupData field is added; the flag rides inside the
      // existing settings map. Runs LAST inside the transaction because a
      // SharedPreferences write cannot be rolled back.
      final settings = AppSettings.fromJson(
        backupData.settings,
      ).copyWith(onboardingComplete: true);
      await _settingsRepo.updateSettings(settings);
    });
  }

  /// The only `source` values a trusted Phase 41 write path can produce
  /// (D-07). An imported row claiming any other source is rejected.
  static const Set<String> _validBackupRateSources = {
    'frankfurter',
    'fawazahmed0',
    'manual',
  };
}
