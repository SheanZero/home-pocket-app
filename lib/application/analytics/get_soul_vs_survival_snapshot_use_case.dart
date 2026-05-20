import 'package:collection/collection.dart';

import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-V2-01 / D-01..D-05 — Soul-vs-Survival engagement snapshot.
///
/// Single-book variant. Fetches the per-ledger `(count, totalSpend)` rows from
/// `getLedgerSnapshot` in parallel with the soul-scoped satisfaction average
/// from `getSoulSatisfactionOverview`. D-04 type-system gate:
/// `SurvivalLedgerSnapshot` has no `avgSatisfaction` field, and the soul-side
/// avg is sourced ONLY from `getSoulSatisfactionOverview` (the DAO filters
/// that query via `_soulExpenseFilter`). The survival row's amount/count never
/// touches the soul satisfaction value.
///
/// D-05 either-ledger-zero gate: if EITHER the soul row OR the survival row
/// is missing/zero, the entire snapshot returns [Empty]. The compare card
/// renders the global empty state rather than a half-populated comparison
/// (one-sided cards are confusing — "is the other ledger broken or just
/// empty?").
class GetSoulVsSurvivalSnapshotUseCase {
  GetSoulVsSurvivalSnapshotUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<SoulVsSurvivalSnapshot>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    // Kick off both reads concurrently — mirrors the parallel-fetch pattern
    // in `get_family_happiness_use_case.dart`.
    final ledgerFuture = _repo.getLedgerSnapshot(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
    final overviewFuture = _repo.getSoulSatisfactionOverview(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
    final ledgerRows = await ledgerFuture;
    final soulOverview = await overviewFuture;

    final soulRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'soul');
    final survivalRow = ledgerRows.firstWhereOrNull(
      (r) => r.ledgerType == 'survival',
    );

    // D-05 either-ledger-zero gate: any side missing or zero-count → Empty.
    if (soulRow == null ||
        soulRow.entryCount == 0 ||
        survivalRow == null ||
        survivalRow.entryCount == 0) {
      return const Empty();
    }

    final snapshot = SoulVsSurvivalSnapshot(
      soul: SoulLedgerSnapshot(
        entryCount: soulRow.entryCount,
        totalSpend: soulRow.totalAmount,
        // D-04 provenance: soul-scoped avg ONLY. Survival amount/count never
        // touches this value — type-system also enforces it (SurvivalLedger-
        // Snapshot has no avgSatisfaction field).
        avgSatisfaction: soulOverview.avgSatisfaction,
      ),
      survival: SurvivalLedgerSnapshot(
        entryCount: survivalRow.entryCount,
        totalSpend: survivalRow.totalAmount,
      ),
    );

    return Value(snapshot, soulRow.entryCount + survivalRow.entryCount);
  }
}
