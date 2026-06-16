import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_category_drill_down_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/category_dao.dart';
import 'package:home_pocket/data/daos/transaction_dao.dart';
import 'package:home_pocket/data/repositories/category_repository_impl.dart';
import 'package:home_pocket/data/repositories/transaction_repository_impl.dart';
import 'package:home_pocket/features/analytics/domain/category_l1_rollup.dart';
import 'package:home_pocket/features/analytics/domain/models/category_drill_down.dart';
import 'package:home_pocket/infrastructure/crypto/services/field_encryption_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockFieldEncryptionService extends Mock
    implements FieldEncryptionService {}

void main() {
  late AppDatabase database;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late CategoryRepositoryImpl categoryRepository;
  late TransactionRepositoryImpl transactionRepository;
  late _MockFieldEncryptionService encryptionService;
  late GetCategoryDrillDownUseCase useCase;

  // Window: the whole of May 2026.
  final windowStart = DateTime(2026, 5, 1);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);
  // A timestamp safely outside the window (April).
  final outOfWindow = DateTime(2026, 4, 20, 12);

  setUp(() async {
    database = AppDatabase.forTesting();
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);
    categoryRepository = CategoryRepositoryImpl(dao: categoryDao);
    encryptionService = _MockFieldEncryptionService();
    // Identity passthrough — seeded transactions carry no notes, so these are
    // safety nets only and never alter assertions.
    when(() => encryptionService.encryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => encryptionService.decryptField(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    transactionRepository = TransactionRepositoryImpl(
      dao: transactionDao,
      encryptionService: encryptionService,
    );

    useCase = GetCategoryDrillDownUseCase(
      transactionRepository: transactionRepository,
      categoryRepository: categoryRepository,
    );

    // ── Categories ──────────────────────────────────────────────────────────
    // Target L1 + its L2 child (Pitfall 2: both must be drilled into).
    await categoryDao.insertCategory(
      id: 'l1_food',
      name: 'Food',
      icon: '🍕',
      color: '#FF0000',
      level: 1,
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await categoryDao.insertCategory(
      id: 'l2_dining',
      name: 'Dining',
      icon: '🍜',
      color: '#FF3333',
      level: 2,
      parentId: 'l1_food',
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
    // A sibling L1 + its L2 child (must be EXCLUDED from the Food drill).
    await categoryDao.insertCategory(
      id: 'l1_transport',
      name: 'Transport',
      icon: '🚃',
      color: '#0000FF',
      level: 1,
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await categoryDao.insertCategory(
      id: 'l2_train',
      name: 'Train',
      icon: '🚉',
      color: '#3333FF',
      level: 2,
      parentId: 'l1_transport',
      isSystem: true,
      createdAt: DateTime(2026, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedTx({
    required String id,
    required int amount,
    required String categoryId,
    required DateTime timestamp,
    String ledgerType = 'daily',
    String? prevHash,
  }) async {
    await transactionDao.insertTransaction(
      id: id,
      bookId: 'book1',
      deviceId: 'dev1',
      amount: amount,
      type: 'expense',
      categoryId: categoryId,
      ledgerType: ledgerType,
      timestamp: timestamp,
      currentHash: 'hash_$id',
      prevHash: prevHash,
      createdAt: timestamp,
      entrySource: 'manual',
    );
  }

  group('GetCategoryDrillDownUseCase', () {
    test(
      'includes L1-direct AND L2-child txns in window, excludes sibling L1 and '
      'out-of-window (Pitfall 2)',
      () async {
        // Filed directly on the target L1.
        await seedTx(
          id: 'tx_l1_direct',
          amount: 50000,
          categoryId: 'l1_food',
          timestamp: DateTime(2026, 5, 10, 9),
        );
        // Filed on the L2 child of the target L1.
        await seedTx(
          id: 'tx_l2_child',
          amount: 30000,
          categoryId: 'l2_dining',
          timestamp: DateTime(2026, 5, 20, 19),
          prevHash: 'hash_tx_l1_direct',
        );
        // Sibling L1 (Transport) — must be excluded.
        await seedTx(
          id: 'tx_sibling_l1',
          amount: 99999,
          categoryId: 'l1_transport',
          timestamp: DateTime(2026, 5, 15, 8),
          prevHash: 'hash_tx_l2_child',
        );
        // Sibling L1's L2 child — must be excluded.
        await seedTx(
          id: 'tx_sibling_l2',
          amount: 88888,
          categoryId: 'l2_train',
          timestamp: DateTime(2026, 5, 16, 8),
          prevHash: 'hash_tx_sibling_l1',
        );
        // Target L1 but OUT OF WINDOW — must be excluded.
        await seedTx(
          id: 'tx_out_of_window',
          amount: 77777,
          categoryId: 'l1_food',
          timestamp: outOfWindow,
          prevHash: 'hash_tx_sibling_l2',
        );

        final CategoryDrillDown result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
          l1CategoryId: 'l1_food',
        );

        final ids = result.transactions.map((t) => t.id).toSet();
        expect(ids, {'tx_l1_direct', 'tx_l2_child'});
        expect(ids, isNot(contains('tx_sibling_l1')));
        expect(ids, isNot(contains('tx_sibling_l2')));
        expect(ids, isNot(contains('tx_out_of_window')));
      },
    );

    test(
      'subtotal/count match Plan 01 l1RollupFromTransactions (D-11 single source)',
      () async {
        await seedTx(
          id: 'tx_l1_direct',
          amount: 50000,
          categoryId: 'l1_food',
          timestamp: DateTime(2026, 5, 10, 9),
        );
        await seedTx(
          id: 'tx_l2_child',
          amount: 30000,
          categoryId: 'l2_dining',
          timestamp: DateTime(2026, 5, 20, 19),
          prevHash: 'hash_tx_l1_direct',
        );
        await seedTx(
          id: 'tx_sibling_l1',
          amount: 99999,
          categoryId: 'l1_transport',
          timestamp: DateTime(2026, 5, 15, 8),
          prevHash: 'hash_tx_l2_child',
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
          l1CategoryId: 'l1_food',
        );

        // Direct subtotal/count of the two Food txns.
        expect(result.subtotal, 80000);
        expect(result.count, 2);

        // Cross-check against the LOCKED Plan 01 rollup over the SAME fixtures:
        // the drill header MUST equal the donut slice by construction.
        final categories = await categoryRepository.findAll();
        final categoryMap = {for (final c in categories) c.id: c};
        final allTxns = await transactionRepository.findByBookIds(
          ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );
        final rollup = l1RollupFromTransactions(
          allTxns,
          categoryMap,
          'l1_food',
        );
        expect(result.subtotal, rollup.amount);
        expect(result.count, rollup.transactionCount);
      },
    );

    test('empty window returns empty transactions, zero subtotal/count', () async {
      // Seed a Food txn OUTSIDE the queried window only.
      await seedTx(
        id: 'tx_out_of_window',
        amount: 12345,
        categoryId: 'l1_food',
        timestamp: outOfWindow,
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
        l1CategoryId: 'l1_food',
      );

      expect(result.transactions, isEmpty);
      expect(result.subtotal, 0);
      expect(result.count, 0);
    });

    test('avgPerDay is a plain descriptive average over the window days', () async {
      // 90000 over the 31 days of May => floor(90000 / 31) == 2903.
      await seedTx(
        id: 'tx_a',
        amount: 60000,
        categoryId: 'l1_food',
        timestamp: DateTime(2026, 5, 5),
      );
      await seedTx(
        id: 'tx_b',
        amount: 30000,
        categoryId: 'l2_dining',
        timestamp: DateTime(2026, 5, 25),
        prevHash: 'hash_tx_a',
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
        l1CategoryId: 'l1_food',
      );

      expect(result.subtotal, 90000);
      // Descriptive average only — never a target/goal.
      expect(result.avgPerDay, 90000 ~/ 31);
    });

    test('includes both daily and joy ledger txns of the target L1', () async {
      await seedTx(
        id: 'tx_daily',
        amount: 40000,
        categoryId: 'l1_food',
        timestamp: DateTime(2026, 5, 3),
        ledgerType: 'daily',
      );
      await seedTx(
        id: 'tx_joy',
        amount: 20000,
        categoryId: 'l2_dining',
        timestamp: DateTime(2026, 5, 4),
        ledgerType: 'joy',
        prevHash: 'hash_tx_daily',
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
        l1CategoryId: 'l1_food',
      );

      expect(result.transactions.map((t) => t.id).toSet(), {
        'tx_daily',
        'tx_joy',
      });
      expect(result.subtotal, 60000);
      expect(result.count, 2);
    });
  });
}
