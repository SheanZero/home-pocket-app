import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';

/// A throwing encryption service that simulates decryption failure on a
/// shadow-book note encrypted with another device's key (SC#5).
class _ThrowingEncryptionService implements FieldEncryptionService {
  @override
  Future<String> encryptField(String plaintext) async =>
      'encrypted_$plaintext';

  /// Always throws to simulate wrong-device-key scenario.
  @override
  Future<String> decryptField(String ciphertext) async =>
      throw Exception('Cannot decrypt — wrong device key');

  @override
  Future<String> encryptAmount(double amount) async =>
      amount.toStringAsFixed(2);

  @override
  Future<double> decryptAmount(String encrypted) async =>
      double.parse(encrypted);

  @override
  Future<void> clearCache() async {}
}

void main() {
  late AppDatabase db;
  late TransactionDao dao;
  late TransactionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
    repo = TransactionRepositoryImpl(
      dao: dao,
      encryptionService: _ThrowingEncryptionService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SC#5 — _toModel note decrypt failure', () {
    test(
      'findById returns note: null when decryption fails, all other fields intact',
      () async {
        // Insert a transaction with an encrypted note via DAO directly
        // (bypasses repo encryption, simulating a shadow-book row from another device)
        await dao.insertTransaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: 'expense',
          categoryId: 'cat_food',
          ledgerType: 'daily',
          timestamp: DateTime(2026, 5, 29, 10, 0),
          currentHash: 'hash_abc',
          createdAt: DateTime(2026, 5, 29, 10, 0),
          note: 'some_ciphertext',
          entrySource: 'manual',
        );

        final result = await repo.findById('tx_001');

        expect(result, isNotNull);
        // note must be null — decryption threw, SC#5 silent catch
        expect(result!.note, isNull);
        // All other fields must be intact
        expect(result.amount, equals(1000));
        expect(result.categoryId, equals('cat_food'));
        expect(result.bookId, equals('book_001'));
        expect(result.id, equals('tx_001'));
      },
    );
  });
}
