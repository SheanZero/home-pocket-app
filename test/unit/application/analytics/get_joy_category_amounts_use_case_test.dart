import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_joy_category_amounts_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/analytics/domain/models/joy_category_amount.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

/// A fake [TransactionRepository] that records the bookIds + window + ledger it
/// was called with and returns the rows matching the requested window/ledger.
/// Only [findByBookIds] is exercised; every other member throws.
class _RecordingTransactionRepository implements TransactionRepository {
  _RecordingTransactionRepository(this._rows);

  final List<Transaction> _rows;

  List<String>? lastBookIds;
  DateTime? lastStartDate;
  DateTime? lastEndDate;
  LedgerType? lastLedgerType;
  String? lastCategoryId;
  int findByBookIdsCallCount = 0;

  @override
  Future<List<Transaction>> findByBookIds(
    List<String> bookIds, {
    LedgerType? ledgerType,
    String? categoryId,
    required DateTime startDate,
    required DateTime endDate,
    SortField sortField = SortField.timestamp,
    SortDirection sortDirection = SortDirection.asc,
  }) async {
    findByBookIdsCallCount++;
    lastBookIds = bookIds;
    lastStartDate = startDate;
    lastEndDate = endDate;
    lastLedgerType = ledgerType;
    lastCategoryId = categoryId;
    return _rows
        .where(
          (tx) =>
              !tx.timestamp.isBefore(startDate) &&
              !tx.timestamp.isAfter(endDate) &&
              (ledgerType == null || tx.ledgerType == ledgerType),
        )
        .toList();
  }

  @override
  Object noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

/// A fake [CategoryRepository] returning a fixed category list via [findAll].
class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this._categories);

  final List<Category> _categories;

  @override
  Future<List<Category>> findAll() async => _categories;

  @override
  Object noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Category _cat({
  required String id,
  required int level,
  String? parentId,
}) {
  return Category(
    id: id,
    name: id,
    icon: '🍕',
    color: '#FF0000',
    level: level,
    parentId: parentId,
    createdAt: DateTime(2026, 1, 1),
  );
}

Transaction _tx({
  required String id,
  required int amount,
  required String categoryId,
  required DateTime timestamp,
  LedgerType ledgerType = LedgerType.joy,
  TransactionType type = TransactionType.expense,
  String deviceId = 'dev1',
}) {
  return Transaction(
    id: id,
    bookId: 'book1',
    deviceId: deviceId,
    amount: amount,
    type: type,
    categoryId: categoryId,
    ledgerType: ledgerType,
    timestamp: timestamp,
    currentHash: 'hash_$id',
    createdAt: timestamp,
  );
}

void main() {
  // L1 categories + an L2 child of l1_hobby (Pitfall 2 rollup).
  final categories = <Category>[
    _cat(id: 'l1_hobby', level: 1),
    _cat(id: 'l2_books', level: 2, parentId: 'l1_hobby'),
    _cat(id: 'l1_travel', level: 1),
    _cat(id: 'l1_food', level: 1),
  ];

  final windowStart = DateTime(2026, 5, 1);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  group('GetJoyCategoryAmountsUseCase', () {
    test(
      'one JoyCategoryAmount per L1; L2 children roll into L1 (l1AncestorOf), '
      'sorted amount-descending (D-C2 segment order)',
      () async {
        final repo = _RecordingTransactionRepository([
          // l1_hobby: 30000 direct + 20000 via l2_books child = 50000.
          _tx(
            id: 'h1',
            amount: 30000,
            categoryId: 'l1_hobby',
            timestamp: DateTime(2026, 5, 10),
          ),
          _tx(
            id: 'h2',
            amount: 20000,
            categoryId: 'l2_books',
            timestamp: DateTime(2026, 5, 11),
          ),
          // l1_travel: 80000 (largest).
          _tx(
            id: 't1',
            amount: 80000,
            categoryId: 'l1_travel',
            timestamp: DateTime(2026, 5, 12),
          ),
        ]);
        final useCase = GetJoyCategoryAmountsUseCase(
          transactionRepository: repo,
          categoryRepository: _FakeCategoryRepository(categories),
        );

        final List<JoyCategoryAmount> result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(result.map((e) => e.categoryId).toList(), [
          'l1_travel',
          'l1_hobby',
        ]);
        expect(result.first.amount, 80000); // travel, largest first
        expect(result[1].amount, 50000); // hobby = 30000 + 20000 (l2 rolled up)
      },
    );

    test('joy-ledger ONLY — daily-ledger rows in the window are excluded', () async {
      final repo = _RecordingTransactionRepository([
        _tx(
          id: 'joy1',
          amount: 40000,
          categoryId: 'l1_hobby',
          timestamp: DateTime(2026, 5, 10),
          ledgerType: LedgerType.joy,
        ),
        _tx(
          id: 'daily1',
          amount: 99999,
          categoryId: 'l1_hobby',
          timestamp: DateTime(2026, 5, 11),
          ledgerType: LedgerType.daily,
        ),
      ]);
      final useCase = GetJoyCategoryAmountsUseCase(
        transactionRepository: repo,
        categoryRepository: _FakeCategoryRepository(categories),
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      // Fetch must request the joy ledger.
      expect(repo.lastLedgerType, LedgerType.joy);
      expect(result.length, 1);
      expect(result.single.categoryId, 'l1_hobby');
      expect(result.single.amount, 40000); // daily 99999 excluded
    });

    test('expense-only — non-expense joy rows excluded (mirror drill CR-01)', () async {
      final repo = _RecordingTransactionRepository([
        _tx(
          id: 'exp',
          amount: 50000,
          categoryId: 'l1_hobby',
          timestamp: DateTime(2026, 5, 10),
        ),
        _tx(
          id: 'inc',
          amount: 20000,
          categoryId: 'l1_hobby',
          timestamp: DateTime(2026, 5, 11),
          type: TransactionType.income,
        ),
        _tx(
          id: 'xfer',
          amount: 13000,
          categoryId: 'l2_books',
          timestamp: DateTime(2026, 5, 12),
          type: TransactionType.transfer,
        ),
      ]);
      final useCase = GetJoyCategoryAmountsUseCase(
        transactionRepository: repo,
        categoryRepository: _FakeCategoryRepository(categories),
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result.length, 1);
      expect(result.single.amount, 50000); // income + transfer excluded
    });

    test(
      'subset invariant — joy L1 amount <= that L1 total over the same window '
      '(round-5 B 悦己 strict subset of donut L1)',
      () async {
        // l1_food has BOTH daily and joy spend in the window. The joy amount the
        // use case returns must be <= the L1 total (daily + joy).
        final rows = [
          _tx(
            id: 'food_daily',
            amount: 70000,
            categoryId: 'l1_food',
            timestamp: DateTime(2026, 5, 5),
            ledgerType: LedgerType.daily,
          ),
          _tx(
            id: 'food_joy',
            amount: 25000,
            categoryId: 'l1_food',
            timestamp: DateTime(2026, 5, 6),
            ledgerType: LedgerType.joy,
          ),
        ];
        final repo = _RecordingTransactionRepository(rows);
        final useCase = GetJoyCategoryAmountsUseCase(
          transactionRepository: repo,
          categoryRepository: _FakeCategoryRepository(categories),
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        final foodJoy = result
            .firstWhere((e) => e.categoryId == 'l1_food')
            .amount;
        const l1Total = 70000 + 25000; // daily + joy
        expect(foodJoy, 25000);
        expect(foodJoy, lessThanOrEqualTo(l1Total));
      },
    );

    test('empty window -> empty list, no throw', () async {
      final repo = _RecordingTransactionRepository(const []);
      final useCase = GetJoyCategoryAmountsUseCase(
        transactionRepository: repo,
        categoryRepository: _FakeCategoryRepository(categories),
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result, isEmpty);
    });

    test(
      'deviceId filter (260622-d5i / D2): only the chosen device contributes; '
      'deviceId == null is byte-unchanged (all devices)',
      () async {
        // dev-a: 30000 (l1_hobby) ; dev-b: 80000 (l1_travel).
        final rows = [
          _tx(
            id: 'a1',
            amount: 30000,
            categoryId: 'l1_hobby',
            timestamp: DateTime(2026, 5, 10),
            deviceId: 'dev-a',
          ),
          _tx(
            id: 'b1',
            amount: 80000,
            categoryId: 'l1_travel',
            timestamp: DateTime(2026, 5, 12),
            deviceId: 'dev-b',
          ),
        ];
        final repo = _RecordingTransactionRepository(rows);
        final useCase = GetJoyCategoryAmountsUseCase(
          transactionRepository: repo,
          categoryRepository: _FakeCategoryRepository(categories),
        );

        // Filtered to dev-a: only l1_hobby = 30000.
        final filtered = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
          deviceId: 'dev-a',
        );
        expect(filtered.map((e) => e.categoryId).toList(), ['l1_hobby']);
        expect(filtered.single.amount, 30000);

        // Null deviceId: unchanged — both devices contribute.
        final unfiltered = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );
        expect(unfiltered.map((e) => e.categoryId).toList(), [
          'l1_travel',
          'l1_hobby',
        ]);
        expect(unfiltered.first.amount, 80000);
        expect(unfiltered[1].amount, 30000);
      },
    );

    test(
      'security: findByBookIds called with exactly the caller bookIds '
      '(T-46-02-01 / T-44-03-03)',
      () async {
        final repo = _RecordingTransactionRepository(const []);
        final useCase = GetJoyCategoryAmountsUseCase(
          transactionRepository: repo,
          categoryRepository: _FakeCategoryRepository(categories),
        );

        await useCase.execute(
          bookIds: ['book1', 'book2'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(repo.lastBookIds, ['book1', 'book2']);
        expect(repo.findByBookIdsCallCount, 1); // exactly one fetch
      },
    );
  });
}
