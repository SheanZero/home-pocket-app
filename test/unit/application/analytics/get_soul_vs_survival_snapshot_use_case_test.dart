import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_soul_vs_survival_snapshot_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
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
  late GetSoulVsSurvivalSnapshotUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);
  const bookId = 'book-1';

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetSoulVsSurvivalSnapshotUseCase(analyticsRepository: repository);
  });

  void stubLedgers(
    List<LedgerSnapshotRow> rows, {
    EntrySource? entrySourceFilter,
  }) {
    when(
      () => repository.getLedgerSnapshot(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
    ).thenAnswer((_) async => rows);
  }

  void stubOverview(double avg, int count, {EntrySource? entrySourceFilter}) {
    when(
      () => repository.getSoulSatisfactionOverview(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
    ).thenAnswer(
      (_) async => SoulSatisfactionOverview(avgSatisfaction: avg, count: count),
    );
  }

  Future<MetricResult<SoulVsSurvivalSnapshot>> execute({
    EntrySource? entrySourceFilter,
  }) {
    return useCase.execute(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  group('happy path', () {
    test(
      'both ledgers populated → Value with soul-only avg provenance',
      () async {
        stubLedgers([_ledger('soul', 1500, 5), _ledger('survival', 12000, 8)]);
        stubOverview(7.4, 5);

        final result = await execute() as Value<SoulVsSurvivalSnapshot>;

        // D-04 provenance: Soul.avgSatisfaction comes from the soul-scoped
        // getSoulSatisfactionOverview mock — NEVER from survival ledger.
        expect(result.data.soul.avgSatisfaction, 7.4);
        expect(result.data.soul.entryCount, 5);
        expect(result.data.soul.totalSpend, 1500);
        expect(result.data.survival.entryCount, 8);
        expect(result.data.survival.totalSpend, 12000);
        expect(result.data.familySoul, isNull);
        expect(result.data.familySurvival, isNull);
        // sampleSize = soul.entryCount + survival.entryCount
        expect(result.sampleSize, 13);
      },
    );
  });

  group('D-05 either-ledger-zero gate', () {
    test('soul entryCount=0 → Empty', () async {
      stubLedgers([_ledger('soul', 0, 0), _ledger('survival', 12000, 8)]);
      stubOverview(0, 0);

      expect(await execute(), isA<Empty<SoulVsSurvivalSnapshot>>());
    });

    test('survival entryCount=0 → Empty', () async {
      stubLedgers([_ledger('soul', 1500, 5), _ledger('survival', 0, 0)]);
      stubOverview(7.4, 5);

      expect(await execute(), isA<Empty<SoulVsSurvivalSnapshot>>());
    });

    test('soul row absent from list → Empty', () async {
      stubLedgers([_ledger('survival', 12000, 8)]);
      stubOverview(0, 0);

      expect(await execute(), isA<Empty<SoulVsSurvivalSnapshot>>());
    });

    test('survival row absent from list → Empty', () async {
      stubLedgers([_ledger('soul', 1500, 5)]);
      stubOverview(7.4, 5);

      expect(await execute(), isA<Empty<SoulVsSurvivalSnapshot>>());
    });

    test('both ledgers absent → Empty', () async {
      stubLedgers(const []);
      stubOverview(0, 0);

      expect(await execute(), isA<Empty<SoulVsSurvivalSnapshot>>());
    });
  });

  group('soul-only avg provenance (D-04 type-system gate)', () {
    test(
      'getSoulSatisfactionOverview called with same window as getLedgerSnapshot',
      () async {
        stubLedgers([_ledger('soul', 1500, 5), _ledger('survival', 12000, 8)]);
        stubOverview(7.4, 5);

        await execute();

        verify(
          () => repository.getSoulSatisfactionOverview(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: null,
          ),
        ).called(1);
        verify(
          () => repository.getLedgerSnapshot(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: null,
          ),
        ).called(1);
      },
    );
  });

  group('entrySourceFilter forwarding', () {
    test(
      'execute with entrySourceFilter = null forwards null to both repo calls',
      () async {
        stubLedgers([
          _ledger('soul', 1500, 5),
          _ledger('survival', 12000, 8),
        ], entrySourceFilter: null);
        stubOverview(7.4, 5, entrySourceFilter: null);

        final result = await execute() as Value<SoulVsSurvivalSnapshot>;

        expect(result.data.soul.entryCount, 5);
        verify(
          () => repository.getLedgerSnapshot(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: null,
          ),
        ).called(1);
        verify(
          () => repository.getSoulSatisfactionOverview(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: null,
          ),
        ).called(1);
      },
    );

    test(
      'execute with entrySourceFilter = EntrySource.manual forwards filter to both columns',
      () async {
        stubLedgers([
          _ledger('soul', 900, 3),
          _ledger('survival', 7000, 4),
        ], entrySourceFilter: EntrySource.manual);
        stubOverview(8.0, 3, entrySourceFilter: EntrySource.manual);

        final result =
            await execute(entrySourceFilter: EntrySource.manual)
                as Value<SoulVsSurvivalSnapshot>;

        expect(result.data.soul.entryCount, 3);
        expect(result.data.survival.entryCount, 4);
        verify(
          () => repository.getLedgerSnapshot(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: EntrySource.manual,
          ),
        ).called(1);
        verify(
          () => repository.getSoulSatisfactionOverview(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: EntrySource.manual,
          ),
        ).called(1);
      },
    );
  });

  group('time window validation', () {
    test('throws ArgumentError when start > end', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });
  });
}
