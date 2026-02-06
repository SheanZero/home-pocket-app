import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FieldEncryptionService])
import 'transaction_repository_impl_test.mocks.dart';

void main() {
  late AppDatabase db;
  late TransactionDao dao;
  late MockFieldEncryptionService mockEncryption;
  late TransactionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
    mockEncryption = MockFieldEncryptionService();
    repo = TransactionRepositoryImpl(
      dao: dao,
      encryptionService: mockEncryption,
    );

    // Default: encryption passthrough for testing
    when(
      mockEncryption.encryptField(any),
    ).thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
    when(mockEncryption.decryptField(any)).thenAnswer((inv) async {
      final cipher = inv.positionalArguments[0] as String;
      return cipher.replaceFirst('enc_', '');
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionRepositoryImpl', () {
    test('insert stores transaction with encrypted note', () async {
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      verify(mockEncryption.encryptField('Lunch at cafe')).called(1);

      final row = await dao.findById('tx_001');
      expect(row, isNotNull);
      expect(row!.note, 'enc_Lunch at cafe');
    });

    test('insert without note skips encryption', () async {
      final tx = Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'cat_salary',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'hash_xyz',
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(tx);
      verifyNever(mockEncryption.encryptField(any));
    });

    test('findById decrypts note', () async {
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.survival,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      final found = await repo.findById('tx_001');
      expect(found, isNotNull);
      expect(found!.note, 'Lunch at cafe');
      verify(mockEncryption.decryptField('enc_Lunch at cafe')).called(1);
    });

    test('findByBookId returns sorted, decrypted transactions', () async {
      final t1 = DateTime(2026, 2, 5, 10, 0);
      final t2 = DateTime(2026, 2, 6, 10, 0);

      await repo.insert(
        Transaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          timestamp: t1,
          currentHash: 'h1',
          createdAt: t1,
        ),
      );

      await repo.insert(
        Transaction(
          id: 'tx_002',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 2000,
          type: TransactionType.income,
          categoryId: 'cat_salary',
          ledgerType: LedgerType.survival,
          timestamp: t2,
          note: 'Salary',
          currentHash: 'h2',
          createdAt: t2,
        ),
      );

      final results = await repo.findByBookId('book_001');
      expect(results.length, 2);
      expect(results.first.id, 'tx_002');
      expect(results.first.note, 'Salary');
    });

    test('softDelete marks transaction as deleted', () async {
      await repo.insert(
        Transaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          timestamp: DateTime(2026, 2, 6),
          currentHash: 'h1',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.softDelete('tx_001');

      final results = await repo.findByBookId('book_001');
      expect(results.length, 0);
    });

    test('getLatestHash delegates to dao', () async {
      await repo.insert(
        Transaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          timestamp: DateTime(2026, 2, 6),
          currentHash: 'latest_hash_value',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      final hash = await repo.getLatestHash('book_001');
      expect(hash, 'latest_hash_value');
    });

    test('countByBookId returns count of non-deleted', () async {
      await repo.insert(
        Transaction(
          id: 'tx_001',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 1000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          timestamp: DateTime(2026, 2, 6),
          currentHash: 'h1',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.insert(
        Transaction(
          id: 'tx_002',
          bookId: 'book_001',
          deviceId: 'dev_001',
          amount: 2000,
          type: TransactionType.expense,
          categoryId: 'cat_food',
          ledgerType: LedgerType.survival,
          timestamp: DateTime(2026, 2, 6),
          currentHash: 'h2',
          createdAt: DateTime(2026, 2, 6),
        ),
      );

      await repo.softDelete('tx_002');

      final count = await repo.countByBookId('book_001');
      expect(count, 1);
    });
  });
}
