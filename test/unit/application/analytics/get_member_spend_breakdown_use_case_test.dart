import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_member_spend_breakdown_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/analytics/domain/models/member_spend_breakdown.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';

/// A fake [TransactionRepository] that records the bookIds + window it was called
/// with and returns the rows matching the requested window/ledger. Only
/// [findByBookIds] is exercised; every other member throws.
class _RecordingTransactionRepository implements TransactionRepository {
  _RecordingTransactionRepository(this._rows);

  final List<Transaction> _rows;

  List<String>? lastBookIds;
  DateTime? lastStartDate;
  DateTime? lastEndDate;
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
    lastStartDate = startDate;
    lastEndDate = endDate;
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
  required int amount,
  required String deviceId,
  required DateTime timestamp,
  LedgerType ledgerType = LedgerType.daily,
  TransactionType type = TransactionType.expense,
  EntrySource entrySource = EntrySource.manual,
  String categoryId = 'cat_x',
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
    entrySource: entrySource,
  );
}

void main() {
  final windowStart = DateTime(2026, 5, 1);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  group('GetMemberSpendBreakdownUseCase', () {
    test(
      'Test 1: multi-device expense grouped by deviceId — amount=Σ, count=笔数, '
      'sorted amount-descending (stable & distinguishable)',
      () async {
        final repo = _RecordingTransactionRepository([
          // dev-a: 30000 + 20000 = 50000, 2 tx.
          _tx(id: 'a1', amount: 30000, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 10)),
          _tx(id: 'a2', amount: 20000, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 11)),
          // dev-b: 80000, 1 tx (largest).
          _tx(id: 'b1', amount: 80000, deviceId: 'dev-b',
              timestamp: DateTime(2026, 5, 12)),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final List<MemberSpendBreakdown> result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(result.map((e) => e.deviceId).toList(), ['dev-b', 'dev-a']);
        expect(result.first.amount, 80000);
        expect(result.first.transactionCount, 1);
        expect(result[1].amount, 50000);
        expect(result[1].transactionCount, 2);
      },
    );

    test('Test 2: expense-only — income/transfer rows excluded', () async {
      final repo = _RecordingTransactionRepository([
        _tx(id: 'exp', amount: 50000, deviceId: 'dev-a',
            timestamp: DateTime(2026, 5, 10)),
        _tx(id: 'inc', amount: 20000, deviceId: 'dev-a',
            timestamp: DateTime(2026, 5, 11), type: TransactionType.income),
        _tx(id: 'xfer', amount: 13000, deviceId: 'dev-a',
            timestamp: DateTime(2026, 5, 12), type: TransactionType.transfer),
      ]);
      final useCase = GetMemberSpendBreakdownUseCase(
        transactionRepository: repo,
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result.length, 1);
      expect(result.single.amount, 50000); // income + transfer excluded
      expect(result.single.transactionCount, 1);
    });

    test(
      'Test 3: entrySourceFilter==manual counts only manual rows',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'm1', amount: 40000, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 10),
              entrySource: EntrySource.manual),
          _tx(id: 'v1', amount: 99999, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 11),
              entrySource: EntrySource.voice),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
          entrySourceFilter: EntrySource.manual,
        );

        expect(result.length, 1);
        expect(result.single.amount, 40000); // voice 99999 excluded
        expect(result.single.transactionCount, 1);
      },
    );

    test(
      'Test 4: single device → exactly 1 MemberSpendBreakdown (graceful '
      'degradation, no throw, non-empty when there is spend)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 's1', amount: 10000, deviceId: 'dev-solo',
              timestamp: DateTime(2026, 5, 10)),
          _tx(id: 's2', amount: 5000, deviceId: 'dev-solo',
              timestamp: DateTime(2026, 5, 11)),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        expect(result.length, 1);
        expect(result.single.deviceId, 'dev-solo');
        expect(result.single.amount, 15000);
        expect(result.single.transactionCount, 2);
      },
    );

    test('Test 5: empty window → empty list, no throw', () async {
      final repo = _RecordingTransactionRepository(const []);
      final useCase = GetMemberSpendBreakdownUseCase(
        transactionRepository: repo,
      );

      final result = await useCase.execute(
        bookIds: ['book1'],
        startDate: windowStart,
        endDate: windowEnd,
      );

      expect(result, isEmpty);
    });

    test(
      'Test 7 (260622-d5i / D3): default ledgerType forwards null '
      '(cross-ledger, byte-unchanged)',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'd1', amount: 10000, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 10), ledgerType: LedgerType.daily),
          _tx(id: 'j1', amount: 5000, deviceId: 'dev-a',
              timestamp: DateTime(2026, 5, 11), ledgerType: LedgerType.joy),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        // Cross-ledger: both daily and joy spend counted.
        expect(repo.lastLedgerType, isNull);
        expect(result.single.deviceId, 'dev-a');
        expect(result.single.amount, 15000);
        expect(result.single.transactionCount, 2);
      },
    );

    test(
      'Test 8 (260622-d5i / D3): ledgerType: joy forwarded to findByBookIds; '
      'a daily-only member yields no joy bucket',
      () async {
        final repo = _RecordingTransactionRepository([
          // dev-joy has joy spend; dev-daily has only daily spend.
          _tx(id: 'j1', amount: 8000, deviceId: 'dev-joy',
              timestamp: DateTime(2026, 5, 10), ledgerType: LedgerType.joy),
          _tx(id: 'd1', amount: 99999, deviceId: 'dev-daily',
              timestamp: DateTime(2026, 5, 11), ledgerType: LedgerType.daily),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1'],
          startDate: windowStart,
          endDate: windowEnd,
          ledgerType: LedgerType.joy,
        );

        // Fetch must request the joy ledger.
        expect(repo.lastLedgerType, LedgerType.joy);
        // Only the joy-spending member yields a bucket.
        expect(result.map((e) => e.deviceId).toList(), ['dev-joy']);
        expect(result.single.amount, 8000);
      },
    );

    test(
      'Test 6: amount==0 groups not produced; bookIds NOT widened',
      () async {
        final repo = _RecordingTransactionRepository([
          _tx(id: 'z', amount: 0, deviceId: 'dev-zero',
              timestamp: DateTime(2026, 5, 10)),
          _tx(id: 'p', amount: 7000, deviceId: 'dev-pos',
              timestamp: DateTime(2026, 5, 11)),
        ]);
        final useCase = GetMemberSpendBreakdownUseCase(
          transactionRepository: repo,
        );

        final result = await useCase.execute(
          bookIds: ['book1', 'book2'],
          startDate: windowStart,
          endDate: windowEnd,
        );

        // amount==0 device not produced.
        expect(result.map((e) => e.deviceId), ['dev-pos']);
        // bookIds passed through exactly (not widened).
        expect(repo.lastBookIds, ['book1', 'book2']);
        expect(repo.findByBookIdsCallCount, 1);
      },
    );
  });
}
