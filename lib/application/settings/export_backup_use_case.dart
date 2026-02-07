import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/settings/domain/models/backup_data.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../shared/utils/result.dart';

/// Creates an encrypted backup file (.hpb) containing all app data.
///
/// Algorithm: JSON → GZip → PBKDF2 key derivation → AES-256-GCM encryption.
/// Binary format: salt(16) + nonce(12) + ciphertext + mac(16).
class ExportBackupUseCase {
  ExportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _bookRepo = bookRepo,
        _settingsRepo = settingsRepo;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;

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
      final books = await _bookRepo.findAll(includeArchived: true);
      final settings = await _settingsRepo.getSettings();

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
      );

      // 3. Serialize to JSON
      final jsonString = jsonEncode(backupData.toJson());

      // 4. Compress with GZip
      final gzipBytes = gzip.encode(utf8.encode(jsonString));

      // 5. Encrypt with AES-256-GCM
      final encryptedData = await _encryptData(
        Uint8List.fromList(gzipBytes),
        password,
      );

      // 6. Save to file
      final directory =
          outputDirectory ?? await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().substring(0, 10);
      final file =
          File('${directory.path}/homepocket_backup_$timestamp.hpb');
      await file.writeAsBytes(encryptedData);

      return Result.success(file);
    } catch (e) {
      return Result.error('Backup export failed: $e');
    }
  }

  Future<Uint8List> _encryptData(Uint8List data, String password) async {
    // Derive key from password using PBKDF2
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final salt = _generateRandomBytes(16);
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    // Encrypt with AES-GCM
    final algorithm = AesGcm.with256bits();
    final nonce = _generateRandomBytes(12);

    final secretBox = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine: salt(16) + nonce(12) + ciphertext + mac(16)
    final result = <int>[
      ...salt,
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ];

    return Uint8List.fromList(result);
  }

  List<int> _generateRandomBytes(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256));
  }
}
