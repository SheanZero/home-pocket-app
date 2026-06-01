import 'package:collection/collection.dart';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-V2-01 / D-01..D-05 — Daily-vs-Joy engagement snapshot.
///
/// Single-book variant. Fetches the per-ledger `(count, totalSpend)` rows from
/// `getLedgerSnapshot` in parallel with the joy-scoped satisfaction average
/// from `getJoyFullnessOverview`. D-04 type-system gate:
/// `DailyLedgerSnapshot` has no `avgSatisfaction` field, and the joy-side
/// avg is sourced ONLY from `getJoyFullnessOverview` (the DAO filters
/// that query via `_joyExpenseFilter`). The daily row's amount/count never
/// touches the joy satisfaction value.
///
/// D-05 either-ledger-zero gate: if EITHER the joy row OR the daily row
/// is missing/zero, the entire snapshot returns [Empty]. The compare card
/// renders the global empty state rather than a half-populated comparison
/// (one-sided cards are confusing — "is the other ledger broken or just
/// empty?").
class GetDailyVsJoySnapshotUseCase {
  GetDailyVsJoySnapshotUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<DailyVsJoySnapshot>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    // Kick off both reads concurrently — mirrors the parallel-fetch pattern
    // in `get_family_happiness_use_case.dart`.
    final ledgerFuture = _repo.getLedgerSnapshot(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
    final overviewFuture = _repo.getJoyFullnessOverview(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
    final ledgerRows = await ledgerFuture;
    final joyOverview = await overviewFuture;

    final joyRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'joy');
    final dailyRow = ledgerRows.firstWhereOrNull(
      (r) => r.ledgerType == 'daily',
    );

    // D-05 either-ledger-zero gate: any side missing or zero-count → Empty.
    if (joyRow == null ||
        joyRow.entryCount == 0 ||
        dailyRow == null ||
        dailyRow.entryCount == 0) {
      return const Empty();
    }

    final snapshot = DailyVsJoySnapshot(
      joy: JoyLedgerSnapshot(
        entryCount: joyRow.entryCount,
        totalSpend: joyRow.totalAmount,
        // D-04 provenance: joy-scoped avg ONLY. Daily amount/count never
        // touches this value — type-system also enforces it (DailyLedger-
        // Snapshot has no avgSatisfaction field).
        avgSatisfaction: joyOverview.avgSatisfaction,
      ),
      daily: DailyLedgerSnapshot(
        entryCount: dailyRow.entryCount,
        totalSpend: dailyRow.totalAmount,
      ),
    );

    return Value(snapshot, joyRow.entryCount + dailyRow.entryCount);
  }
}
