import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_daily_vs_joy_snapshot_across_books_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

LedgerSnapshotRow _ledger(String type, int total, int count) =>
    LedgerSnapshotRow(ledgerType: type, totalAmount: total, entryCount: count);

void main() {
  late _MockAnalyticsRepository repository;
  late GetDailyVsJoySnapshotAcrossBooksUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetDailyVsJoySnapshotAcrossBooksUseCase(
      analyticsRepository: repository,
    );
  });

  void stubLedgersAcross(List<String> bookIds, List<LedgerSnapshotRow> rows) {
    when(
      () => repository.getLedgerSnapshotAcrossBooks(
        bookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => rows);
  }

  void stubOverview(String bookId, double avg, int count) {
    when(
      () => repository.getJoyFullnessOverview(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer(
      (_) async => JoyFullnessOverview(avgSatisfaction: avg, count: count),
    );
  }

  group('empty groupBookIds short-circuit', () {
    test('returns Empty and never calls across-books or overview', () async {
      final result = await useCase.execute(
        groupBookIds: const [],
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Empty<DailyVsJoySnapshot>>());
      verifyNever(
        () => repository.getLedgerSnapshotAcrossBooks(
          bookIds: any(named: 'bookIds'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => repository.getJoyFullnessOverview(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    });
  });

  group('happy path', () {
    test(
      'both family ledgers populated → Value with family aggregates',
      () async {
        final bookIds = ['b1', 'b2'];
        stubLedgersAcross(bookIds, [
          _ledger('joy', 3000, 7),
          _ledger('daily', 25000, 12),
        ]);
        stubOverview('b1', 8.0, 3);
        stubOverview('b2', 6.0, 4);

        final result =
            await useCase.execute(
                  groupBookIds: bookIds,
                  startDate: startDate,
                  endDate: endDate,
                )
                as Value<DailyVsJoySnapshot>;

        expect(result.data.joy.entryCount, 7);
        expect(result.data.joy.totalSpend, 3000);
        // weighted family avg = (8*3 + 6*4) / (3+4) = (24+24)/7 = 48/7
        expect(result.data.joy.avgSatisfaction, closeTo(48 / 7, 1e-9));
        expect(result.data.daily.entryCount, 12);
        expect(result.data.daily.totalSpend, 25000);
        // sampleSize = joy + daily entries
        expect(result.sampleSize, 19);
      },
    );
  });

  group('D-05 either-ledger-zero gate at family scope', () {
    test('family joy has 0 entries → Empty', () async {
      final bookIds = ['b1', 'b2'];
      stubLedgersAcross(bookIds, [
        _ledger('joy', 0, 0),
        _ledger('daily', 25000, 12),
      ]);
      stubOverview('b1', 0, 0);
      stubOverview('b2', 0, 0);

      final result = await useCase.execute(
        groupBookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Empty<DailyVsJoySnapshot>>());
    });

    test('family daily has 0 entries → Empty', () async {
      final bookIds = ['b1', 'b2'];
      stubLedgersAcross(bookIds, [
        _ledger('joy', 3000, 7),
        _ledger('daily', 0, 0),
      ]);
      stubOverview('b1', 8.0, 3);
      stubOverview('b2', 6.0, 4);

      final result = await useCase.execute(
        groupBookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Empty<DailyVsJoySnapshot>>());
    });
  });

  group('weighted family avg satisfaction', () {
    test(
      'computed as Σ(avg*size)/Σ(size) — example 8*3 + 6*2 over 3+2 = 7.2',
      () async {
        final bookIds = ['b1', 'b2'];
        stubLedgersAcross(bookIds, [
          _ledger('joy', 1500, 5),
          _ledger('daily', 10000, 6),
        ]);
        stubOverview('b1', 8.0, 3);
        stubOverview('b2', 6.0, 2);

        final result =
            await useCase.execute(
                  groupBookIds: bookIds,
                  startDate: startDate,
                  endDate: endDate,
                )
                as Value<DailyVsJoySnapshot>;

        expect(result.data.joy.avgSatisfaction, closeTo(7.2, 1e-9));
      },
    );

    test('zero sample sizes across books → avg falls back to 0', () async {
      final bookIds = ['b1', 'b2'];
      stubLedgersAcross(bookIds, [
        // joy has aggregate entries from raw ledger snapshot, but per-book
        // overviews report zero joy-rated samples (no satisfaction ratings).
        _ledger('joy', 100, 1),
        _ledger('daily', 10000, 6),
      ]);
      stubOverview('b1', 0, 0);
      stubOverview('b2', 0, 0);

      final result =
          await useCase.execute(
                groupBookIds: bookIds,
                startDate: startDate,
                endDate: endDate,
              )
              as Value<DailyVsJoySnapshot>;

      expect(result.data.joy.avgSatisfaction, 0);
    });
  });

  group('time window validation', () {
    test('throws ArgumentError when start > end', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });
  });
}
