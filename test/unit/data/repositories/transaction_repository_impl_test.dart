import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

void main() {
  late AppDatabase db;
  late TransactionDao dao;
  late _MockFieldEncryptionService mockEncryption;
  late TransactionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = TransactionDao(db);
    mockEncryption = _MockFieldEncryptionService();
    repo = TransactionRepositoryImpl(
      dao: dao,
      encryptionService: mockEncryption,
    );

    // Default: encryption passthrough for testing
    when(
      () => mockEncryption.encryptField(any()),
    ).thenAnswer((inv) async => 'enc_${inv.positionalArguments[0]}');
    when(() => mockEncryption.decryptField(any())).thenAnswer((inv) async {
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
        ledgerType: LedgerType.daily,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        metadata: const {'sourceBookId': 'remote-book-1'},
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      verify(() => mockEncryption.encryptField('Lunch at cafe')).called(1);

      final row = await dao.findById('tx_001');
      expect(row, isNotNull);
      expect(row!.note, 'enc_Lunch at cafe');
      expect(row.metadata, '{"sourceBookId":"remote-book-1"}');
    });

    test('insert without note skips encryption', () async {
      final tx = Transaction(
        id: 'tx_002',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'cat_food_dining_out',
        ledgerType: LedgerType.daily,
        timestamp: DateTime(2026, 2, 6),
        currentHash: 'hash_xyz',
        createdAt: DateTime(2026, 2, 6),
      );

      await repo.insert(tx);
      verifyNever(() => mockEncryption.encryptField(any()));
    });

    test('findById decrypts note', () async {
      final tx = Transaction(
        id: 'tx_001',
        bookId: 'book_001',
        deviceId: 'dev_001',
        amount: 10000,
        type: TransactionType.expense,
        categoryId: 'cat_food',
        ledgerType: LedgerType.daily,
        timestamp: DateTime(2026, 2, 6, 10, 0),
        note: 'Lunch at cafe',
        metadata: const {'sourceBookId': 'remote-book-1'},
        currentHash: 'hash_abc',
        createdAt: DateTime(2026, 2, 6, 10, 0),
      );

      await repo.insert(tx);

      final found = await repo.findById('tx_001');
      expect(found, isNotNull);
      expect(found!.note, 'Lunch at cafe');
      expect(found.metadata?['sourceBookId'], 'remote-book-1');
      verify(() => mockEncryption.decryptField('enc_Lunch at cafe')).called(1);
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
          ledgerType: LedgerType.daily,
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
          categoryId: 'cat_food_dining_out',
          ledgerType: LedgerType.daily,
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
          ledgerType: LedgerType.daily,
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
          ledgerType: LedgerType.daily,
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
          ledgerType: LedgerType.daily,
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
          ledgerType: LedgerType.daily,
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

  // Phase 42 regression: the foreign-currency triple (originalCurrency /
  // originalAmount / appliedRate) MUST round-trip through the real DAO + DB.
  // Pre-fix, the repository dropped these on both write and read, so every
  // foreign transaction read back JPY-native — the edit host showed JPY and the
  // list annotation never appeared. These tests exercise the real persistence
  // path (no mock repo), which the use-case mock tests could not catch.
  group('multi-currency triple round-trip (Phase 42)', () {
    Transaction foreignTx({
      String id = 'tx_fx',
      String? originalCurrency = 'USD',
      int? originalAmount = 5000,
      String? appliedRate = '148.30',
      int amount = 7415,
    }) => Transaction(
      id: id,
      bookId: 'book_001',
      deviceId: 'dev_001',
      amount: amount,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.daily,
      timestamp: DateTime(2026, 6, 13, 10),
      currentHash: 'hash_fx',
      createdAt: DateTime(2026, 6, 13, 10),
      originalCurrency: originalCurrency,
      originalAmount: originalAmount,
      appliedRate: appliedRate,
    );

    test('insert persists and findById reads back the full foreign triple',
        () async {
      await repo.insert(foreignTx());

      final loaded = await repo.findById('tx_fx');
      expect(loaded, isNotNull);
      expect(loaded!.originalCurrency, 'USD');
      expect(loaded.originalAmount, 5000);
      expect(loaded.appliedRate, '148.30');
      expect(loaded.amount, 7415); // derived JPY unchanged
    });

    test('update persists edited triple (changed rate)', () async {
      await repo.insert(foreignTx());
      await repo.update(
        foreignTx(appliedRate: '150.00', amount: 7500),
      );

      final loaded = await repo.findById('tx_fx');
      expect(loaded!.appliedRate, '150.00');
      expect(loaded.originalAmount, 5000);
      expect(loaded.amount, 7500);
    });

    test('JPY-native row round-trips with a null triple (CURR-04 regression)',
        () async {
      await repo.insert(
        foreignTx(
          id: 'tx_jpy',
          originalCurrency: null,
          originalAmount: null,
          appliedRate: null,
          amount: 1200,
        ),
      );

      final loaded = await repo.findById('tx_jpy');
      expect(loaded!.originalCurrency, isNull);
      expect(loaded.originalAmount, isNull);
      expect(loaded.appliedRate, isNull);
      expect(loaded.amount, 1200);
    });
  });
}
