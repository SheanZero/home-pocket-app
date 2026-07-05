import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../features/settings/domain/models/backup_data.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../infrastructure/crypto/services/backup_crypto_service.dart';
import '../../shared/utils/result.dart';

/// Creates an encrypted backup file (.hpb) containing all app data.
///
/// Algorithm: JSON → GZip → [BackupCryptoService] encryption (Argon2id +
/// AES-256-GCM, versioned self-describing header).
class ExportBackupUseCase {
  ExportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
    required ExchangeRateRepository exchangeRateRepo,
    required BackupCryptoService backupCrypto,
  }) : _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo,
       _bookRepo = bookRepo,
       _settingsRepo = settingsRepo,
       _exchangeRateRepo = exchangeRateRepo,
       _backupCrypto = backupCrypto;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;
  final ExchangeRateRepository _exchangeRateRepo;
  final BackupCryptoService _backupCrypto;

  Future<Result<File>> execute({
    required String bookId,
    required String password,
    String? deviceId,
    String? appVersion,
    Directory? outputDirectory,
  }) async {
    if (password.length < 8) {
      return Result.error('Password must be at least 8 characters');
    }

    try {
      // 1. Collect all data
      final transactions = await _transactionRepo.findAllByBook(bookId);
      final categories = await _categoryRepo.findAll();
      final books = await _bookRepo.findAll(
        includeArchived: true,
        includeShadow: true,
      );
      final settings = await _settingsRepo.getSettings();
      final exchangeRates = await _exchangeRateRepo.findAll();

      // 2. Build backup data structure
      final backupData = BackupData(
        metadata: BackupMetadata(
          version: '1.0',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          deviceId: deviceId ?? 'unknown',
          appVersion: appVersion ?? '0.1.0',
        ),
        transactions: transactions.map((tx) => tx.toJson()).toList(),
        categories: categories.map((cat) => cat.toJson()).toList(),
        books: books.map((book) => book.toJson()).toList(),
        settings: settings.toJson(),
        // D-10: epoch-seconds serialization per RESEARCH.md backup shape.
        exchangeRates: exchangeRates
            .map(
              (er) => <String, dynamic>{
                'currency': er.currency,
                'rateDate': er.rateDate.millisecondsSinceEpoch ~/ 1000,
                'rate': er.rate,
                'fetchedAt': er.fetchedAt.millisecondsSinceEpoch ~/ 1000,
                'source': er.source,
                if (er.actualRateDate != null)
                  'actualRateDate':
                      er.actualRateDate!.millisecondsSinceEpoch ~/ 1000,
              },
            )
            .toList(),
      );

      // 3. Serialize to JSON
      final jsonString = jsonEncode(backupData.toJson());

      // 4. Compress with GZip
      final gzipBytes = gzip.encode(utf8.encode(jsonString));

      // 5. Encrypt (Argon2id + AES-256-GCM, crypto layer)
      final encryptedData = await _backupCrypto.encrypt(
        Uint8List.fromList(gzipBytes),
        password,
      );

      // 6. Save to file
      final directory =
          outputDirectory ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = File('${directory.path}/homepocket_backup_$timestamp.hpb');
      await file.writeAsBytes(encryptedData);

      return Result.success(file);
    } catch (e) {
      return Result.error('Backup export failed: $e');
    }
  }
}
