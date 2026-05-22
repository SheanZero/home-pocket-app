/// Integration test: entry_source round-trips through UpdateTransactionUseCase
/// for all three EntrySource literals (manual, voice, ocr).
///
/// Covers:
/// - SC-3: entrySource preservation through edit
/// - D-08: prevHash/currentHash frozen across edit (cross-layer verification at DAO surface)
/// - D-12: reserved 'ocr' literal is accepted by the v17 CHECK constraint and
///         round-trips through the DAO without modification
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/update_transaction_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

void main() {
  late AppDatabase db;
  late TransactionDao transactionDao;
  late UpdateTransactionUseCase useCase;
  late _MockFieldEncryptionService encryptionService;

  setUp(() {
    db = AppDatabase.forTesting();
    transactionDao = TransactionDao(db);
    encryptionService = _MockFieldEncryptionService();

    // Stub encryption to pass through plaintext — the use case delegates
    // note encryption to TransactionRepositoryImpl; tests don't test crypto.
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (inv) async => inv.positionalArguments.first as String,
    );

    final transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: encryptionService,
    );

    // SyncEngine and ChangeTracker are nullable — omit them to skip sync push
    // lane in integration tests (out of scope for DAO round-trip verification).
    useCase = UpdateTransactionUseCase(
      transactionRepository: transactionRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ─── helper: insert a transaction row directly via DAO ──────────────────────

  Future<Transaction> insertSeed({
    required EntrySource entrySource,
    String id = 'tx-seed',
    String bookId = 'book-test',
    String deviceId = 'dev-test',
    int amount = 1000,
    String categoryId = 'cat-food',
    String prevHash = 'prev-hash-abc',
    String currentHash = 'current-hash-xyz',
  }) async {
    final now = DateTime(2026, 1, 1, 12);
    await transactionDao.insertTransaction(
      id: id,
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: TransactionType.expense.name,
      categoryId: categoryId,
      ledgerType: LedgerType.survival.name,
      timestamp: now,
      currentHash: currentHash,
      createdAt: now,
      prevHash: prevHash,
      entrySource: entrySource.name,
    );
    return Transaction(
      id: id,
      bookId: bookId,
      deviceId: deviceId,
      amount: amount,
      type: TransactionType.expense,
      categoryId: categoryId,
      ledgerType: LedgerType.survival,
      timestamp: now,
      currentHash: currentHash,
      prevHash: prevHash,
      createdAt: now,
      entrySource: entrySource,
    );
  }

  // ─── tests: three EntrySource literals ────────────────────────────────────

  test('preserves entry_source: manual through edit round-trip (SC-3)', () async {
    final seed = await insertSeed(entrySource: EntrySource.manual);

    final result = await useCase.execute(
      UpdateTransactionParams(seed: seed, amount: 1500),
    );

    expect(result.isSuccess, isTrue, reason: result.error);

    final row = await transactionDao.findById(seed.id);
    expect(row, isNotNull);

    // SC-3: entry_source preserved verbatim
    expect(row!.entrySource, 'manual');

    // D-08: hash chain frozen across edit
    expect(row.prevHash, 'prev-hash-abc',
        reason: 'prevHash must not change on edit (D-08)');
    expect(row.currentHash, 'current-hash-xyz',
        reason: 'currentHash must not change on edit (D-08)');
  });

  test('preserves entry_source: voice through edit round-trip (SC-3)', () async {
    final seed = await insertSeed(
      entrySource: EntrySource.voice,
      id: 'tx-voice',
    );

    final result = await useCase.execute(
      UpdateTransactionParams(seed: seed, amount: 2000),
    );

    expect(result.isSuccess, isTrue, reason: result.error);

    final row = await transactionDao.findById(seed.id);
    expect(row, isNotNull);

    // SC-3: voice entrySource preserved — must NOT flip to 'manual'
    expect(row!.entrySource, 'voice',
        reason: 'voice entry_source must not be flipped to manual on edit');

    // D-08: hash chain frozen
    expect(row.prevHash, 'prev-hash-abc');
    expect(row.currentHash, 'current-hash-xyz');
  });

  test(
    'preserves entry_source: ocr through edit round-trip (SC-3 + D-12 reserved literal)',
    () async {
      // D-12: 'ocr' is type-reserved; v17 CHECK constraint accepts it.
      // Phase 18 stamps no live rows with 'ocr', but the DAO must preserve
      // it verbatim if a row carries it (future MOD-005 compatibility).
      final seed = await insertSeed(
        entrySource: EntrySource.ocr,
        id: 'tx-ocr',
      );

      final result = await useCase.execute(
        UpdateTransactionParams(seed: seed, amount: 3000),
      );

      expect(result.isSuccess, isTrue, reason: result.error);

      final row = await transactionDao.findById(seed.id);
      expect(row, isNotNull);

      // SC-3 + D-12: reserved 'ocr' literal preserved verbatim
      expect(row!.entrySource, 'ocr',
          reason: "'ocr' entry_source must survive a round-trip through edit");

      // D-08: hash chain frozen even for ocr rows
      expect(row.prevHash, 'prev-hash-abc');
      expect(row.currentHash, 'current-hash-xyz');
    },
  );

  test(
    'updatedAt is stamped on edit while createdAt is preserved (D-07 cross-layer)',
    () async {
      final seed = await insertSeed(entrySource: EntrySource.manual);
      final before = DateTime.now();

      await useCase.execute(
        UpdateTransactionParams(seed: seed, amount: 4000),
      );

      final row = await transactionDao.findById(seed.id);
      expect(row, isNotNull);

      // D-07: updatedAt stamped on every save
      expect(row!.updatedAt, isNotNull);
      expect(
        row.updatedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
        reason: 'updatedAt must be set to approximately now',
      );

      // D-07: createdAt preserved verbatim
      expect(row.createdAt, DateTime(2026, 1, 1, 12));
    },
  );
}
