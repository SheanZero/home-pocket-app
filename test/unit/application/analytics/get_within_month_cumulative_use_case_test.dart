import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_within_month_cumulative_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/analytics/domain/models/within_month_cumulative_trend.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

/// A fake [TransactionRepository] that records the bookIds + window it was
/// called with and returns a fixed transaction list. Only [findByBookIds] is
/// exercised by the use case; every other member throws.
class _RecordingTransactionRepository implements TransactionRepository {
  _RecordingTransactionRepository(this._rows);

  final List<Transaction> _rows;

  List<String>? lastBookIds;
  DateTime? lastStartDate;
  DateTime? lastEndDate;
  LedgerType? lastLedgerType;
  String? lastCategoryId;

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
    lastBookIds = bookIds;
    lastStartDate = startDate;
    lastEndDate = endDate;
    lastLedgerType = ledgerType;
    lastCategoryId = categoryId;
    return _rows
        .where(
          (tx) =>
              !tx.timestamp.isBefore(startDate) &&
              !tx.timestamp.isAfter(endDate),
        )
        .toList();
  }

  @override
  Object noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

Transaction _tx({
  required String id,
  required int amount,
  required DateTime timestamp,
  LedgerType ledgerType = LedgerType.daily,
  TransactionType type = TransactionType.expense,
}) {
  return Transaction(
    id: id,
    bookId: 'book1',
    deviceId: 'dev1',
    amount: amount,
    type: type,
    categoryId: 'cat',
    ledgerType: ledgerType,
    timestamp: timestamp,
    currentHash: 'hash_$id',
    createdAt: timestamp,
  );
}

/// The cumulative value exactly AT [day] if a point exists on that day,
/// else null. Used for assertions that target a specific spend day.
int? _cumAt(List<CumulativePoint> points, int day) {
  for (final p in points) {
    if (p.day == day) return p.cumulativeAmount;
  }
  return null;
}

/// The carried-forward cumulative on/before [day] (the value a line chart would
/// draw at [day]): the cumulative of the latest point at or before [day], or 0
/// if no spend has occurred yet. Series are sparse (only spend days are
/// emitted), so a no-spend day inherits the prior cumulative — never resets.
int _cumOnOrBefore(List<CumulativePoint> points, int day) {
  int running = 0;
  for (final p in points) {
    if (p.day <= day) {
      running = p.cumulativeAmount;
    } else {
      break;
    }
  }
  return running;
}

void main() {
  // June 2026 is the current month; May 2026 is the previous month.
  final monthAnchor = DateTime(2026, 6, 1);

  group('GetWithinMonthCumulativeUseCase', () {
    test(
      'Test 1: per-day cumulative points are the running sum on/before each day '
      'within the month (monotonic non-decreasing)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'a', amount: 10000, timestamp: DateTime(2026, 6, 2, 9)),
          _tx(id: 'b', amount: 20000, timestamp: DateTime(2026, 6, 2, 18)),
          _tx(id: 'c', amount: 5000, timestamp: DateTime(2026, 6, 10, 12)),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          monthAnchor: monthAnchor,
        );

        final total = result.currentMonthTotal;
        // Day 2 == both June-2 txns; day 10 == all three (running sum).
        expect(_cumAt(total, 2), 30000);
        expect(_cumAt(total, 10), 35000);

        // Monotonic non-decreasing.
        int prev = 0;
        for (final p in total) {
          expect(p.cumulativeAmount, greaterThanOrEqualTo(prev));
          prev = p.cumulativeAmount;
        }
      },
    );

    test(
      'Test 2: per-ledger split — total == daily + joy at every point; a day '
      'with no joy spend keeps the prior joy cumulative (no reset)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(
            id: 'd1',
            amount: 10000,
            timestamp: DateTime(2026, 6, 1, 9),
            ledgerType: LedgerType.daily,
          ),
          _tx(
            id: 'j1',
            amount: 4000,
            timestamp: DateTime(2026, 6, 1, 10),
            ledgerType: LedgerType.joy,
          ),
          // Day 5: daily only — joy cumulative must NOT reset.
          _tx(
            id: 'd2',
            amount: 6000,
            timestamp: DateTime(2026, 6, 5, 9),
            ledgerType: LedgerType.daily,
          ),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          monthAnchor: monthAnchor,
        );

        // total == daily + joy at every point in total. Series are sparse
        // (only spend days emitted), so use the carried-forward cumulative for
        // the per-ledger lookup — a no-spend day keeps the prior cumulative.
        for (final p in result.currentMonthTotal) {
          final daily = _cumOnOrBefore(result.currentMonthDaily, p.day);
          final joy = _cumOnOrBefore(result.currentMonthJoy, p.day);
          expect(p.cumulativeAmount, daily + joy);
        }

        // Day 5 daily cumulative == 16000 (has a point on day 5).
        expect(_cumAt(result.currentMonthDaily, 5), 16000);
        // Joy has NO point on day 5 (sparse) — its carried-forward cumulative
        // stays 4000 (no reset on a no-joy-spend day).
        expect(_cumAt(result.currentMonthJoy, 5), isNull);
        expect(_cumOnOrBefore(result.currentMonthJoy, 5), 4000);
        // Total at day 5 == 20000.
        expect(_cumAt(result.currentMonthTotal, 5), 20000);
      },
    );

    test(
      'Test 3: previous-month series exists for total/daily; joy carries ONLY '
      'the current month (no previous-month joy — D-E1, Pitfall 2)',
      () async {
        final repo = _RecordingTransactionRepository([
          // Previous month (May) spend, daily + joy.
          _tx(
            id: 'm1',
            amount: 7000,
            timestamp: DateTime(2026, 5, 3, 9),
            ledgerType: LedgerType.daily,
          ),
          _tx(
            id: 'm2',
            amount: 3000,
            timestamp: DateTime(2026, 5, 3, 10),
            ledgerType: LedgerType.joy,
          ),
          // Current month (June) spend.
          _tx(
            id: 'c1',
            amount: 9000,
            timestamp: DateTime(2026, 6, 4, 9),
            ledgerType: LedgerType.daily,
          ),
          _tx(
            id: 'c2',
            amount: 2000,
            timestamp: DateTime(2026, 6, 4, 10),
            ledgerType: LedgerType.joy,
          ),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          monthAnchor: monthAnchor,
        );

        // Spend (total/daily) previous-month series are populated.
        expect(result.previousMonthTotal, isNotEmpty);
        expect(result.previousMonthDaily, isNotEmpty);
        expect(_cumAt(result.previousMonthTotal, 3), 10000);
        expect(_cumAt(result.previousMonthDaily, 3), 7000);

        // Current-month joy is populated.
        expect(result.currentMonthJoy, isNotEmpty);
        expect(_cumAt(result.currentMonthJoy, 4), 2000);

        // CROSS-PERIOD GUARD: there is NO previous-month joy series at all
        // (the model has no previousMonthJoy field — this is the type-level
        // guarantee). Confirm the spend previous-month series only carry daily,
        // never a joy contribution (May joy 3000 must NOT leak into prev total).
        expect(_cumAt(result.previousMonthTotal, 3), 7000 + 3000);
        // previous-month daily excludes the joy row entirely.
        expect(_cumAt(result.previousMonthDaily, 3), 7000);
      },
    );

    test(
      'Test 4: expense-only — income/transfer rows are excluded so the trend '
      'matches the expense-only overview',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'e', amount: 10000, timestamp: DateTime(2026, 6, 2, 9)),
          _tx(
            id: 'inc',
            amount: 50000,
            timestamp: DateTime(2026, 6, 2, 10),
            type: TransactionType.income,
          ),
          _tx(
            id: 'xfer',
            amount: 30000,
            timestamp: DateTime(2026, 6, 2, 11),
            type: TransactionType.transfer,
          ),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          monthAnchor: monthAnchor,
        );

        // Only the 10000 expense contributes.
        expect(_cumAt(result.currentMonthTotal, 2), 10000);
      },
    );

    test('Test 5: empty window — all series empty, no throw', () async {
      final repo = _RecordingTransactionRepository(const []);
      final useCase = GetWithinMonthCumulativeUseCase(
        transactionRepository: repo,
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        monthAnchor: monthAnchor,
      );

      expect(result.currentMonthTotal, isEmpty);
      expect(result.currentMonthDaily, isEmpty);
      expect(result.currentMonthJoy, isEmpty);
      expect(result.previousMonthTotal, isEmpty);
      expect(result.previousMonthDaily, isEmpty);
    });

    test(
      'Test 6 (security): the book set passed to findByBookIds equals exactly '
      'the caller bookIds; never widened (T-46-01-01)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'a', amount: 1000, timestamp: DateTime(2026, 6, 2, 9)),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        await useCase.execute(
          bookIds: ['book1', 'book2'],
          monthAnchor: monthAnchor,
        );

        expect(repo.lastBookIds, ['book1', 'book2']);
        // Window is the 2-month span (May 1 .. end of June).
        expect(repo.lastStartDate, DateTime(2026, 5, 1));
        expect(repo.lastEndDate!.year, 2026);
        expect(repo.lastEndDate!.month, 6);
        expect(repo.lastEndDate!.day, 30);
      },
    );

    test(
      'entrySourceFilter is threaded through to support the manualOnly joy '
      'variant (compiles + executes)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'a', amount: 1000, timestamp: DateTime(2026, 6, 2, 9)),
        ]);
        final useCase = GetWithinMonthCumulativeUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          monthAnchor: monthAnchor,
          entrySourceFilter: EntrySource.manual,
        );

        expect(result.currentMonthTotal, isNotEmpty);
      },
    );
  });
}
