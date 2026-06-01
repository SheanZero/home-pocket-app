import 'package:collection/collection.dart';

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-V2-01 / D-18 + D-19 — family-aggregate Daily-vs-Joy snapshot.
///
/// Group-mode variant: pools the per-ledger row across all member books via
/// `getLedgerSnapshotAcrossBooks` (`book_id IN (...)` at the DAO — NEVER
/// per-member group per ADR-012 §6). Computes the family-wide joy
/// satisfaction average as a SAMPLE-WEIGHTED average across each book's
/// `getJoyFullnessOverview` result:
///
///   familyAvg = Σ(perBookAvg * perBookCount) / Σ(perBookCount)
///
/// — same weighting algebra as a single AVG over the union of all joy rows
/// (each per-book AVG is `Σ rating / count`, so the weighted recombination
/// recovers the underlying `Σ ratings / Σ counts`).
///
/// D-05 either-ledger-zero gate extended to the family scope: if EITHER the
/// family joy row OR family daily row is missing/zero, the entire
/// snapshot returns [Empty]. D-16 + D-20 defense in depth: an empty
/// `groupBookIds` short-circuits before any repository call.
///
/// Design choice (per Plan 16-05 task spec): this use case represents the
/// family scope only. It returns a [DailyVsJoySnapshot] whose `joy` and
/// `daily` ARE the family aggregates; `familyJoy` / `familyDaily` stay
/// null (those fields are reserved for the widget-level composition in Plan
/// 16-06, where the family provider combines the single-book result and the
/// family result into one display model).
class GetDailyVsJoySnapshotAcrossBooksUseCase {
  GetDailyVsJoySnapshotAcrossBooksUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<DailyVsJoySnapshot>> execute({
    required List<String> groupBookIds,
    required DateTime startDate,
    required DateTime endDate,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    // D-16 + D-20 defense in depth: short-circuit BEFORE any repository call.
    if (groupBookIds.isEmpty) {
      return const Empty();
    }

    // Kick off the family-aggregate ledger snapshot in parallel with the
    // per-book joy satisfaction overviews.
    final ledgerFuture = _repo.getLedgerSnapshotAcrossBooks(
      bookIds: groupBookIds,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
    final overviewsFuture = Future.wait(
      groupBookIds.map(
        (id) => _repo.getJoyFullnessOverview(
          bookId: id,
          startDate: startDate,
          endDate: endDate,
          entrySourceFilter: entrySourceFilter,
        ),
      ),
    );

    final ledgerRows = await ledgerFuture;
    final overviews = await overviewsFuture;

    final joyRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'joy');
    final dailyRow = ledgerRows.firstWhereOrNull(
      (r) => r.ledgerType == 'daily',
    );

    // D-05 family-scope gate: any side missing or zero-count → Empty.
    if (joyRow == null ||
        joyRow.entryCount == 0 ||
        dailyRow == null ||
        dailyRow.entryCount == 0) {
      return const Empty();
    }

    final familyAvgSatisfaction = _weightedFamilyAvg(overviews);

    final snapshot = DailyVsJoySnapshot(
      joy: JoyLedgerSnapshot(
        entryCount: joyRow.entryCount,
        totalSpend: joyRow.totalAmount,
        // D-04 provenance: family avg derived ONLY from joy-scoped overviews
        // (each `getJoyFullnessOverview` is filtered to joy rows at the
        // DAO). Daily row totals never feed into this value.
        avgSatisfaction: familyAvgSatisfaction,
      ),
      daily: DailyLedgerSnapshot(
        entryCount: dailyRow.entryCount,
        totalSpend: dailyRow.totalAmount,
      ),
    );

    return Value(snapshot, joyRow.entryCount + dailyRow.entryCount);
  }

  /// Weighted family avg: Σ(perBookAvg * perBookCount) / Σ(perBookCount).
  /// Returns 0 when no rated samples exist across the family.
  double _weightedFamilyAvg(List<JoyFullnessOverview> overviews) {
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
