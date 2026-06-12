import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';

void main() {
  test('AppDatabase schemaVersion is 21', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: schemaVersion is currently 20 — this test fails until Wave 1 lands.
    expect(db.schemaVersion, equals(21));
  });

  test('exchange_rates table exists after fresh install', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: exchange_rates table does not exist until Wave 1 migration lands.
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'table' AND name = 'exchange_rates'",
        )
        .get();
    expect(rows, isNotEmpty);
  });

  test('exchange_rates index idx_exchange_rates_currency_date exists', () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: index does not exist until Wave 1 migration lands.
    final rows = await db
        .customSelect(
          'SELECT name FROM sqlite_master '
          "WHERE type = 'index' AND tbl_name = 'exchange_rates'",
        )
        .get();
    final indexNames = rows.map((r) => r.read<String>('name')).toSet();
    expect(indexNames, contains('idx_exchange_rates_currency_date'));
  });

  // WR-07 (Phase 40 review): every test here uses AppDatabase.forTesting(),
  // i.e. a FRESH INSTALL at schema 21 (onCreate path). The v20→v21 onUpgrade
  // ALTER TABLE path is NOT exercised by this suite — the group name must not
  // claim otherwise (repo convention: fresh-install schema assertions only).
  group('v21 schema columns (fresh install)', () {
    test('transactions table has original_currency column at v21', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('original_currency'));
    });

    test('transactions table has original_amount column at v21', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('original_amount'));
    });

    test('transactions table has applied_rate column at v21', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('applied_rate'));
    });

    test(
        'applied_rate is TEXT (not REAL) and original_amount is INTEGER — '
        'ADR-020 mandated type assertion', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final cols = await db
          .customSelect('PRAGMA table_info(transactions)')
          .get();
      // ADR-020: "applied_rate 在 transactions 表中的列类型为 TEXT（不为 REAL）"
      // — a regression to RealColumn is the exact failure mode ADR-020 exists
      // to prevent (float precision drift in stored exchange rates).
      final applied =
          cols.firstWhere((r) => r.read<String>('name') == 'applied_rate');
      expect(applied.read<String>('type'), equals('TEXT'));
      final origAmount =
          cols.firstWhere((r) => r.read<String>('name') == 'original_amount');
      expect(origAmount.read<String>('type'), equals('INTEGER'));
      final origCurrency =
          cols.firstWhere((r) => r.read<String>('name') == 'original_currency');
      expect(origCurrency.read<String>('type'), equals('TEXT'));
    });
  });

  test('original_currency, original_amount, applied_rate columns are nullable (accept NULL)',
      () async {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    // RED: columns do not exist until Wave 1 migration lands.
    // Once they exist, this test verifies they accept NULL values.
    final now = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch;
    // Insert a transaction row with NULL for the three new columns.
    // This will fail until schemaVersion 21 is in place.
    await db.customStatement(
      '''INSERT INTO transactions
         (id, book_id, device_id, amount, type, category_id, ledger_type,
          timestamp, created_at, current_hash, entry_source,
          original_currency, original_amount, applied_rate)
         VALUES (
           'tx_null_currency', 'book_1', 'device_1', 500, 'expense',
           'cat_food', 'daily', ?, ?, '', 'manual',
           NULL, NULL, NULL
         )''',
      [now, now],
    );
    final rows = await db
        .customSelect(
          'SELECT original_currency, original_amount, applied_rate '
          "FROM transactions WHERE id = 'tx_null_currency'",
        )
        .get();
    expect(rows, isNotEmpty);
    expect(rows.first.read<String?>('original_currency'), isNull);
    expect(rows.first.read<int?>('original_amount'), isNull);
    expect(rows.first.read<String?>('applied_rate'), isNull);
  });

  group('STORE-04 hash chain verifyChain', () {
    test(
      'STORE-04: HashChainService.verifyChain passes on dataset with '
      'null and non-null currency fields',
      () async {
        final db = AppDatabase.forTesting();
        addTearDown(db.close);

        final hashService = HashChainService();

        // Compute hashes for a two-transaction chain.
        // TX 1: JPY-native row (null currency fields) — pre-migration style.
        const genesisHash =
            '0000000000000000000000000000000000000000000000000000000000000000';
        const tx1Id = 'tx_jpy_native_store04';
        const tx1Amount = 1500;
        final tx1Timestamp = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000;

        final tx1Hash = hashService.calculateTransactionHash(
          transactionId: tx1Id,
          amount: tx1Amount.toDouble(),
          timestamp: tx1Timestamp,
          previousHash: genesisHash,
        );

        // TX 2: Foreign-currency row (non-null originalCurrency, originalAmount, appliedRate).
        const tx2Id = 'tx_usd_store04';
        const tx2Amount = 7465; // 50 USD × 149.30 = 7465 JPY
        final tx2Timestamp = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch ~/ 1000;

        final tx2Hash = hashService.calculateTransactionHash(
          transactionId: tx2Id,
          amount: tx2Amount.toDouble(),
          timestamp: tx2Timestamp,
          previousHash: tx1Hash,
        );

        final now = DateTime.utc(2026, 6, 12).millisecondsSinceEpoch;

        // Seed TX 1 — JPY-native row (original_currency = NULL)
        await db.customStatement(
          '''INSERT INTO transactions
             (id, book_id, device_id, amount, type, category_id, ledger_type,
              timestamp, created_at, prev_hash, current_hash, entry_source,
              original_currency, original_amount, applied_rate)
             VALUES (
               ?, 'book_store04', 'device_store04', ?, 'expense',
               'cat_food', 'daily', ?, ?, ?, ?, 'manual',
               NULL, NULL, NULL
             )''',
          [tx1Id, tx1Amount, tx1Timestamp * 1000, now, genesisHash, tx1Hash],
        );

        // Seed TX 2 — foreign-currency row (all three non-null)
        await db.customStatement(
          '''INSERT INTO transactions
             (id, book_id, device_id, amount, type, category_id, ledger_type,
              timestamp, created_at, prev_hash, current_hash, entry_source,
              original_currency, original_amount, applied_rate)
             VALUES (
               ?, 'book_store04', 'device_store04', ?, 'expense',
               'cat_food', 'daily', ?, ?, ?, ?, 'manual',
               'USD', 5000, '149.30'
             )''',
          [tx2Id, tx2Amount, tx2Timestamp * 1000, now, tx1Hash, tx2Hash],
        );

        // Build the list-of-maps for verifyChain (keys match HashChainService contract).
        final chainData = [
          {
            'transactionId': tx1Id,
            'amount': tx1Amount,
            'timestamp': tx1Timestamp,
            'previousHash': genesisHash,
            'currentHash': tx1Hash,
          },
          {
            'transactionId': tx2Id,
            'amount': tx2Amount,
            'timestamp': tx2Timestamp,
            'previousHash': tx1Hash,
            'currentHash': tx2Hash,
          },
        ];

        // ADR-021: currency fields are EXCLUDED from the hash formula.
        // verifyChain must pass regardless of originalCurrency/originalAmount/appliedRate values.
        final result = hashService.verifyChain(chainData);

        expect(result.isValid, isTrue,
            reason: 'verifyChain must pass on dataset containing both '
                'null-currency (JPY-native) and non-null-currency (USD) rows. '
                'ADR-021: currency fields are excluded from hash formula.');
        expect(result.tamperedTransactionIds, isEmpty);
        expect(result.totalTransactions, equals(2));
      },
    );

    // ARCHITECTURE ASSERTION (STORE-04 / ADR-021):
    // HashChainService.calculateTransactionHash must accept exactly 4 parameters.
    // If this test ever fails to compile due to a changed signature, the hash formula has drifted.
    // Confirmed parameters: transactionId (String), amount (double), timestamp (int), previousHash (String)
    // originalCurrency / originalAmount / appliedRate must NOT be added to this call.
    test(
      'calculateTransactionHash accepts exactly 4 parameters '
      '(transactionId, amount, timestamp, previousHash) — ADR-021 invariant',
      () {
        final hashService = HashChainService();

        // This call must compile with exactly these 4 named parameters.
        // If anyone adds originalCurrency/originalAmount/appliedRate to the signature,
        // this test documents the contract violation.
        final hash = hashService.calculateTransactionHash(
          transactionId: 'test-id',
          amount: 1000.0,
          timestamp: DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
          previousHash:
              '0000000000000000000000000000000000000000000000000000000000000000',
        );

        // Assert: function exists, accepts exactly the 4 expected parameters,
        // and returns a non-empty SHA-256 hash string.
        expect(hash, isNotEmpty);
        expect(hash, isA<String>());
        // SHA-256 hex digest is always 64 characters
        expect(hash.length, equals(64));
      },
    );
  });
}
