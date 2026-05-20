import 'package:collection/collection.dart';

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-V2-01 / D-18 + D-19 — family-aggregate Soul-vs-Survival snapshot.
///
/// Group-mode variant: pools the per-ledger row across all member books via
/// `getLedgerSnapshotAcrossBooks` (`book_id IN (...)` at the DAO — NEVER
/// per-member group per ADR-012 §6). Computes the family-wide soul
/// satisfaction average as a SAMPLE-WEIGHTED average across each book's
/// `getSoulSatisfactionOverview` result:
///
///   familyAvg = Σ(perBookAvg * perBookCount) / Σ(perBookCount)
///
/// — same weighting algebra as a single AVG over the union of all soul rows
/// (each per-book AVG is `Σ rating / count`, so the weighted recombination
/// recovers the underlying `Σ ratings / Σ counts`).
///
/// D-05 either-ledger-zero gate extended to the family scope: if EITHER the
/// family soul row OR family survival row is missing/zero, the entire
/// snapshot returns [Empty]. D-16 + D-20 defense in depth: an empty
/// `groupBookIds` short-circuits before any repository call.
///
/// Design choice (per Plan 16-05 task spec): this use case represents the
/// family scope only. It returns a [SoulVsSurvivalSnapshot] whose `soul` and
/// `survival` ARE the family aggregates; `familySoul` / `familySurvival` stay
/// null (those fields are reserved for the widget-level composition in Plan
/// 16-06, where the family provider combines the single-book result and the
/// family result into one display model).
class GetSoulVsSurvivalSnapshotAcrossBooksUseCase {
  GetSoulVsSurvivalSnapshotAcrossBooksUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<SoulVsSurvivalSnapshot>> execute({
    required List<String> groupBookIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    // D-16 + D-20 defense in depth: short-circuit BEFORE any repository call.
    if (groupBookIds.isEmpty) {
      return const Empty();
    }

    // Kick off the family-aggregate ledger snapshot in parallel with the
    // per-book soul satisfaction overviews.
    final ledgerFuture = _repo.getLedgerSnapshotAcrossBooks(
      bookIds: groupBookIds,
      startDate: startDate,
      endDate: endDate,
    );
    final overviewsFuture = Future.wait(
      groupBookIds.map(
        (id) => _repo.getSoulSatisfactionOverview(
          bookId: id,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    final ledgerRows = await ledgerFuture;
    final overviews = await overviewsFuture;

    final soulRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'soul');
    final survivalRow = ledgerRows.firstWhereOrNull(
      (r) => r.ledgerType == 'survival',
    );

    // D-05 family-scope gate: any side missing or zero-count → Empty.
    if (soulRow == null ||
        soulRow.entryCount == 0 ||
        survivalRow == null ||
        survivalRow.entryCount == 0) {
      return const Empty();
    }

    final familyAvgSatisfaction = _weightedFamilyAvg(overviews);

    final snapshot = SoulVsSurvivalSnapshot(
      soul: SoulLedgerSnapshot(
        entryCount: soulRow.entryCount,
        totalSpend: soulRow.totalAmount,
        // D-04 provenance: family avg derived ONLY from soul-scoped overviews
        // (each `getSoulSatisfactionOverview` is filtered to soul rows at the
        // DAO). Survival row totals never feed into this value.
        avgSatisfaction: familyAvgSatisfaction,
      ),
      survival: SurvivalLedgerSnapshot(
        entryCount: survivalRow.entryCount,
        totalSpend: survivalRow.totalAmount,
      ),
    );

    return Value(snapshot, soulRow.entryCount + survivalRow.entryCount);
  }

  /// Weighted family avg: Σ(perBookAvg * perBookCount) / Σ(perBookCount).
  /// Returns 0 when no rated samples exist across the family.
  double _weightedFamilyAvg(List<SoulSatisfactionOverview> overviews) {
    var weightedSum = 0.0;
    var totalCount = 0;
    for (final overview in overviews) {
      weightedSum += overview.avgSatisfaction * overview.count;
      totalCount += overview.count;
    }
    if (totalCount == 0) {
      return 0;
    }
    return weightedSum / totalCount;
  }
}
