import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/models/category.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../features/accounting/domain/repositories/book_repository.dart';
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/settings/domain/models/backup_data.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../shared/utils/result.dart';

/// Restores app data from an encrypted backup file (.hpb).
///
/// Algorithm: AES-256-GCM decrypt → GZip decompress → JSON parse → DB restore.
class ImportBackupUseCase {
  ImportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required BookRepository bookRepo,
    required SettingsRepository settingsRepo,
  }) : _transactionRepo = transactionRepo,
       _categoryRepo = categoryRepo,
       _bookRepo = bookRepo,
       _settingsRepo = settingsRepo;

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final BookRepository _bookRepo;
  final SettingsRepository _settingsRepo;

  Future<Result<void>> execute({
    required File backupFile,
    required String password,
  }) async {
    try {
      // 1. Read encrypted file
      final encryptedData = await backupFile.readAsBytes();

      // 2. Validate minimum size: salt(16) + nonce(12) + mac(16) = 44
      if (encryptedData.length < 44) {
        return Result.error('Invalid backup file: too small');
      }

      // 3. Decrypt
      final Uint8List decryptedData;
      try {
        decryptedData = await _decryptData(encryptedData, password);
      } on IncorrectPasswordException {
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

  Future<Uint8List> _decryptData(
    Uint8List encryptedData,
    String password,
  ) async {
    // Extract components: salt(16) + nonce(12) + ciphertext + mac(16)
    final salt = encryptedData.sublist(0, 16);
    final nonce = encryptedData.sublist(16, 28);
    final cipherText = encryptedData.sublist(28, encryptedData.length - 16);
    final mac = Mac(encryptedData.sublist(encryptedData.length - 16));

    // Derive key from password
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    // Decrypt
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    try {
      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw IncorrectPasswordException();
    }
  }

  Future<void> _restoreData(BackupData backupData) async {
    // Delete existing data first
    // Get all books to delete their transactions
    final existingBooks = await _bookRepo.findAll(includeArchived: true);
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

    // Import settings
    final settings = AppSettings.fromJson(backupData.settings);
    await _settingsRepo.updateSettings(settings);
  }
}

class IncorrectPasswordException implements Exception {
  @override
  String toString() => 'Incorrect password';
}
