import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_info.dart' as app_info;
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/accounting/domain/models/transaction_photo_sync_policy.dart';
import '../../features/currency/domain/repositories/exchange_rate_repository.dart';
import '../../features/currency/domain/models/exchange_rate.dart';
import '../../features/settings/domain/models/backup_data.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/repositories/unit_of_work.dart';
import '../../infrastructure/crypto/services/backup_crypto_service.dart';
import '../../shared/utils/result.dart';

/// Creates an encrypted backup file (.hpb) containing all app data.
///
/// Algorithm: JSON → GZip → [BackupCryptoService] encryption (Argon2id +
/// AES-256-GCM, versioned self-describing header).
class ExportBackupUseCase {
  ExportBackupUseCase({
    required this._transactionRepo,
    required this._categoryRepo,
    required this._bookRepo,
    required this._settingsRepo,
    required this._exchangeRateRepo,
    required this._unitOfWork,
    required this._backupCrypto,
    DateTime Function()? clock,
    String Function()? backupIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _backupIdGenerator = backupIdGenerator ?? _generateBackupId;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;
  final ExchangeRateRepository _exchangeRateRepo;
  final UnitOfWork _unitOfWork;
  final BackupCryptoService _backupCrypto;
  final DateTime Function() _clock;
  final String Function() _backupIdGenerator;

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
      // 1. Collect a full-application snapshot. A restore replaces every
      // retained book, so exporting only the currently selected [bookId]
      // would make the archive internally inconsistent and lose the other
      // books' transactions on restore. The UnitOfWork provides a single
      // SQLCipher snapshot boundary while all retained books are read.
      final snapshot = await _unitOfWork.run(() async {
        final books = await _bookRepo.findAll(
          includeArchived: true,
          includeShadow: true,
        );
        final transactions = await Future.wait(
          books.map((book) => _transactionRepo.findAllByBook(book.id)),
        );
        return _BackupSnapshot(
          transactions: transactions.expand((items) => items).toList(),
          categories: await _categoryRepo.findAll(),
          books: books,
          exchangeRates: await _exchangeRateRepo.findAll(),
        );
      });
      final settings = await _settingsRepo.getSettings();

      // 2. Build backup data structure
      final backupData = BackupData(
        metadata: BackupMetadata(
          version: '1.0',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          deviceId: deviceId ?? 'unknown',
          appVersion: appVersion ?? app_info.appVersion,
        ),
        transactions: snapshot.transactions
            .map(TransactionPhotoSyncPolicy.toBackupJson)
            .toList(),
        categories: snapshot.categories.map((cat) => cat.toJson()).toList(),
        books: snapshot.books.map((book) => book.toJson()).toList(),
        settings: settings.toJson(),
        // D-10: epoch-seconds serialization per RESEARCH.md backup shape.
        exchangeRates: snapshot.exchangeRates
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
      final file = await _writeBackupAtomically(
        directory: directory,
        encryptedData: encryptedData,
        exportedAt: _clock().toUtc(),
      );

      return Result.success(file);
    } catch (e) {
      return Result.error('Backup export failed: $e');
    }
  }

  /// Publishes a fully flushed backup by renaming a sibling temporary file.
  ///
  /// Dart's [File.rename] replaces an existing destination on some platforms,
  /// so a per-candidate exclusive reservation prevents app writers from ever
  /// publishing over a completed backup. Numeric suffixes make a rare token
  /// collision deterministic instead of discarding an earlier export.
  Future<File> _writeBackupAtomically({
    required Directory directory,
    required Uint8List encryptedData,
    required DateTime exportedAt,
  }) async {
    await directory.create(recursive: true);

    final timestamp = _formatUtcTimestamp(exportedAt);
    final identifier = _backupIdGenerator();
    const maxCollisions = 10000;
    for (var collision = 0; collision < maxCollisions; collision++) {
      final suffix = collision == 0 ? '' : '-$collision';
      final fileName = 'homepocket_backup_${timestamp}_$identifier$suffix.hpb';
      final destination = File(
        '${directory.path}${Platform.pathSeparator}$fileName',
      );
      if (await destination.exists()) continue;

      // `File.create(exclusive: true)` is the cross-platform primitive Dart
      // exposes for atomic name reservation. All application exporters honor
      // this sibling reservation until the completed temporary file is renamed.
      final reservation = File(
        '${directory.path}${Platform.pathSeparator}.$fileName.lock',
      );
      try {
        await reservation.create(exclusive: true);
      } on PathExistsException {
        continue;
      }

      final temporary = File(
        '${directory.path}${Platform.pathSeparator}.$fileName.tmp',
      );
      var temporaryCreated = false;
      try {
        // Recheck after acquiring the reservation to protect pre-existing
        // completed backups that may have appeared between the first check.
        if (await destination.exists()) continue;

        try {
          await temporary.create(exclusive: true);
          temporaryCreated = true;
        } on PathExistsException {
          continue;
        }
        await temporary.writeAsBytes(encryptedData, flush: true);

        // File.rename can replace its destination on POSIX. The reservation
        // serializes app exporters; this additional check protects a completed
        // file created outside that protocol before publication.
        if (await destination.exists()) continue;
        await temporary.rename(destination.path);
        return destination;
      } finally {
        try {
          if (temporaryCreated && await temporary.exists()) {
            await temporary.delete();
          }
        } finally {
          if (await reservation.exists()) {
            await reservation.delete();
          }
        }
      }
    }

    throw StateError('Unable to reserve a unique backup filename');
  }

  static String _formatUtcTimestamp(DateTime value) {
    String padded(int number, int width) =>
        number.toString().padLeft(width, '0');
    return '${padded(value.year, 4)}${padded(value.month, 2)}${padded(value.day, 2)}'
        'T${padded(value.hour, 2)}${padded(value.minute, 2)}${padded(value.second, 2)}'
        '${padded(value.millisecond, 3)}Z';
  }

  static String _generateBackupId() {
    final random = Random.secure();
    return List<String>.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      growable: false,
    ).join();
  }
}

class _BackupSnapshot {
  const _BackupSnapshot({
    required this.transactions,
    required this.categories,
    required this.books,
    required this.exchangeRates,
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Book> books;
  final List<ExchangeRate> exchangeRates;
}
