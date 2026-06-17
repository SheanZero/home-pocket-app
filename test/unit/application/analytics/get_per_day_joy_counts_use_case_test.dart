import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_per_day_joy_counts_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/analytics/domain/models/per_day_joy_count.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

/// A fake [TransactionRepository] recording bookIds/window/ledger and returning
/// rows matching the requested window + ledger. Only [findByBookIds] is used.
class _RecordingTransactionRepository implements TransactionRepository {
  _RecordingTransactionRepository(this._rows);

  final List<Transaction> _rows;

  List<String>? lastBookIds;
  LedgerType? lastLedgerType;
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
    lastLedgerType = ledgerType;
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

Transaction _tx({
  required String id,
  required DateTime timestamp,
  int amount = 1000,
  LedgerType ledgerType = LedgerType.joy,
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

/// The count for a given local calendar day, or 0 if absent.
int _countOn(List<PerDayJoyCount> rows, DateTime day) {
  for (final r in rows) {
    if (r.date.year == day.year &&
        r.date.month == day.month &&
        r.date.day == day.day) {
      return r.count;
    }
  }
  return 0;
}

void main() {
  final windowStart = DateTime(2026, 5, 1);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  group('GetPerDayJoyCountsUseCase', () {
    test('per-day COUNT (笔数, not sum); a day with 3 joy entries -> count 3', () async {
      final repo = _RecordingTransactionRepository([
        _tx(id: 'a', timestamp: DateTime(2026, 5, 10, 9), amount: 5000),
        _tx(id: 'b', timestamp: DateTime(2026, 5, 10, 14), amount: 7000),
        _tx(id: 'c', timestamp: DateTime(2026, 5, 10, 20), amount: 100),
        _tx(id: 'd', timestamp: DateTime(2026, 5, 12, 9), amount: 9999),
      ]);
      final useCase = GetPerDayJoyCountsUseCase(transactionRepository: repo);

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      // Count, NOT sum of amounts (Pitfall 3).
      expect(_countOn(result, DateTime(2026, 5, 10)), 3);
      expect(_countOn(result, DateTime(2026, 5, 12)), 1);
      // A day with no joy entries is absent / count 0.
      expect(_countOn(result, DateTime(2026, 5, 11)), 0);
    });

    test('joy-ledger ONLY + expense-only (daily + non-expense excluded)', () async {
      final repo = _RecordingTransactionRepository([
        _tx(id: 'joy', timestamp: DateTime(2026, 5, 10, 9)),
        _tx(
          id: 'daily',
          timestamp: DateTime(2026, 5, 10, 10),
          ledgerType: LedgerType.daily,
        ),
        _tx(
          id: 'income',
          timestamp: DateTime(2026, 5, 10, 11),
          type: TransactionType.income,
        ),
        _tx(
          id: 'transfer',
          timestamp: DateTime(2026, 5, 10, 12),
          type: TransactionType.transfer,
        ),
      ]);
      final useCase = GetPerDayJoyCountsUseCase(transactionRepository: repo);

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      // Fetch requests the joy ledger; only the one expense joy row counts.
      expect(repo.lastLedgerType, LedgerType.joy);
      expect(_countOn(result, DateTime(2026, 5, 10)), 1);
    });

    test('day grouping is local-day correct (late-night entry lands on its day)', () async {
      // Two entries late on the 10th and one just after midnight on the 11th.
      final repo = _RecordingTransactionRepository([
        _tx(id: 'late10', timestamp: DateTime(2026, 5, 10, 23, 50)),
        _tx(id: 'late10b', timestamp: DateTime(2026, 5, 10, 23, 59)),
        _tx(id: 'early11', timestamp: DateTime(2026, 5, 11, 0, 5)),
      ]);
      final useCase = GetPerDayJoyCountsUseCase(transactionRepository: repo);

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(_countOn(result, DateTime(2026, 5, 10)), 2);
      expect(_countOn(result, DateTime(2026, 5, 11)), 1);
      // Each PerDayJoyCount.date is day-anchored (midnight).
      for (final r in result) {
        expect(r.date.hour, 0);
        expect(r.date.minute, 0);
      }
    });

    test('empty month -> empty, no throw', () async {
      final repo = _RecordingTransactionRepository(const []);
      final useCase = GetPerDayJoyCountsUseCase(transactionRepository: repo);

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result, isEmpty);
    });

    test(
      'security: findByBookIds called with exactly the caller bookIds '
      '(T-46-02-01 / T-44-03-03)',
      () async {
        final repo = _RecordingTransactionRepository(const []);
        final useCase = GetPerDayJoyCountsUseCase(transactionRepository: repo);

        await useCase.execute(
          bookIds: ['book1', 'book2'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(repo.lastBookIds, ['book1', 'book2']);
        expect(repo.findByBookIdsCallCount, 1);
      },
    );
  });
}
