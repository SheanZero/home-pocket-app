import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/models/transaction_photo_sync_policy.dart';
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
///
/// Both the encrypted input and the decompressed JSON are treated as untrusted
/// and bounded by [BackupImportLimits] before parsing or database writes.
class ImportBackupUseCase {
  ImportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
    required ExchangeRateRepository exchangeRateRepo,
    required UnitOfWork unitOfWork,
    required BackupCryptoService backupCrypto,
    this.limits = const BackupImportLimits(),
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
  final BackupImportLimits limits;

  Future<Result<void>> execute({
    required File backupFile,
    required String password,
  }) async {
    try {
      // 1. Read encrypted file through a bounded stream. The cheap length
      // check rejects ordinary oversized files before opening them, while the
      // stream cap also handles a file growing between length() and read().
      final Uint8List encryptedData;
      try {
        encryptedData = await _readEncryptedBackup(backupFile);
      } on _BackupImportSizeLimitException catch (e) {
        return Result.error(e.error.name);
      }

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

      // 3. Decompress through a chunked sink so a high-compression-ratio
      // payload is stopped as soon as its output budget is exhausted.
      final Uint8List jsonBytes;
      try {
        jsonBytes = _decompressBackup(decryptedData);
      } on _BackupImportSizeLimitException catch (e) {
        return Result.error(e.error.name);
      }
      final jsonString = utf8.decode(jsonBytes);

      // 4. Parse JSON
      final Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return Result.error('Backup file is corrupted');
      }

      final backupData = BackupData.fromJson(jsonMap);

      // 5. Validate version
      if (backupData.metadata.version != '1.0') {
        return Result.error(
          'Unsupported backup version: ${backupData.metadata.version}',
        );
      }

      // 6. Restore data
      await _restoreData(backupData);

      return Result.success(null);
    } on _SettingsCompensationException catch (e) {
      return Result.error(
        'Backup import failed; database changes were rolled back, but settings '
        'compensation incomplete. Please retry the import: ${e.cause}',
      );
    } catch (e) {
      return Result.error('Backup import failed: $e');
    }
  }

  Future<Uint8List> _readEncryptedBackup(File backupFile) async {
    final maxBytes = limits.maxEncryptedBytes;
    if (await backupFile.length() > maxBytes) {
      throw const _BackupImportSizeLimitException(
        BackupImportError.encryptedFileTooLarge,
      );
    }

    final bytes = BytesBuilder(copy: false);
    await for (final chunk in backupFile.openRead(0, maxBytes + 1)) {
      if (chunk.length > maxBytes - bytes.length) {
        throw const _BackupImportSizeLimitException(
          BackupImportError.encryptedFileTooLarge,
        );
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Uint8List _decompressBackup(Uint8List compressedData) {
    final bytes = BytesBuilder(copy: false);
    final output = _BoundedBytesSink(
      bytes: bytes,
      maxBytes: limits.maxDecompressedBytes,
      limitError: BackupImportError.decompressedDataTooLarge,
    );
    final input = gzip.decoder.startChunkedConversion(output);
    input.add(compressedData);
    input.close();
    return bytes.takeBytes();
  }

  Future<void> _restoreData(BackupData backupData) async {
    // SharedPreferences cannot participate in Drift's transaction. Capture the
    // complete old state before making either store mutable, then compensate it
    // if the settings apply fails part-way through or the DB transaction fails
    // after settings have been written.
    final oldSettings = await _settingsRepo.getSettings();
    final restoredSettings = AppSettings.fromJson(
      backupData.settings,
    ).copyWith(onboardingComplete: true);
    var settingsApplyStarted = false;

    // Atomicity: the whole delete+reinsert sequence runs inside one database
    // transaction — a corrupt or hostile row that aborts mid-restore must
    // roll back to the pre-import state instead of leaving the DB half-wiped.
    try {
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
          final transaction =
              Transaction.fromJson(
                TransactionPhotoSyncPolicy.sanitizeBackupJson(txJson),
              ).copyWith(
                // A restore is a local recovery action, not consent to publish old
                // financial history into the currently active family group.
                familySyncVisibility: FamilySyncVisibility.localOnly,
                familySharedRevision: 0,
              );
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
        // onboarding. A settings write is journaled by [oldSettings] because
        // SharedPreferences is outside the Drift transaction.
        settingsApplyStarted = true;
        await _settingsRepo.updateSettings(restoredSettings);
      });
    } catch (error) {
      if (!settingsApplyStarted) {
        rethrow;
      }

      try {
        await _settingsRepo.restoreSettingsBestEffort(oldSettings);
      } on SettingsRestorationException catch (compensationError) {
        throw _SettingsCompensationException(
          cause: error,
          compensationError: compensationError,
        );
      }
      rethrow;
    }
  }

  /// The only `source` values a trusted Phase 41 write path can produce
  /// (D-07). An imported row claiming any other source is rejected.
  static const Set<String> _validBackupRateSources = {
    'frankfurter',
    'fawazahmed0',
    'manual',
  };
}

class _SettingsCompensationException implements Exception {
  const _SettingsCompensationException({
    required this.cause,
    required this.compensationError,
  });

  final Object cause;
  final SettingsRestorationException compensationError;
}

/// Memory budgets for importing an untrusted backup file.
///
/// Backups contain JSON records only; receipt image bytes are deliberately
/// excluded by [TransactionPhotoSyncPolicy]. The defaults allow substantial
/// account histories while preventing a single import from allocating
/// unbounded encrypted or decompressed data.
class BackupImportLimits {
  const BackupImportLimits({
    this.maxEncryptedBytes = 16 * 1024 * 1024,
    this.maxDecompressedBytes = 64 * 1024 * 1024,
  }) : assert(maxEncryptedBytes > 0),
       assert(maxDecompressedBytes > 0);

  final int maxEncryptedBytes;
  final int maxDecompressedBytes;
}

/// Stable error codes that the presentation layer maps to localized copy.
enum BackupImportError { encryptedFileTooLarge, decompressedDataTooLarge }

class _BoundedBytesSink implements Sink<List<int>> {
  _BoundedBytesSink({
    required this.bytes,
    required this.maxBytes,
    required this.limitError,
  });

  final BytesBuilder bytes;
  final int maxBytes;
  final BackupImportError limitError;

  @override
  void add(List<int> data) {
    if (data.length > maxBytes - bytes.length) {
      throw _BackupImportSizeLimitException(limitError);
    }
    bytes.add(data);
  }

  @override
  void close() {}
}

class _BackupImportSizeLimitException implements Exception {
  const _BackupImportSizeLimitException(this.error);

  final BackupImportError error;
}
