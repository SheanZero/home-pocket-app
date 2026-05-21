import 'dart:math' as math;

import '../../features/accounting/domain/models/entry_source.dart';
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/best_joy_moment_row.dart';
import '../../features/analytics/domain/models/happiness_report.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
import '_time_window_validation.dart';

/// Personal happiness report use case (HAPPY-01..04).
///
/// Mirrors GetMonthlyReportUseCase:
/// - constructor-injected [AnalyticsRepository]
/// - single [execute] method that parallelizes repository calls
/// - returns mixed-packaging [HappinessReport] metrics (D-15)
class GetHappinessReportUseCase {
  GetHappinessReportUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// D-04: Kahneman & Tversky 1979 PTVF empirical fit.
  static const double _ptvfAlpha = 0.88;

  /// D-05: Highlights are "Good or better" soul transactions.
  static const int _highlightsThreshold = 6;

  Future<HappinessReport> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    required String currencyCode,
    EntrySource? entrySourceFilter,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    final results = await Future.wait([
      _repo.getSoulSatisfactionOverview(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
      _repo.getSatisfactionDistribution(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
      _repo.getSoulRowsForJoyContribution(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
      _repo.getBestJoyMoment(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
    ]);

    final overview = results[0] as SoulSatisfactionOverview;
    final distribution = results[1] as List<SatisfactionScoreBucket>;
    final ptvfRows = results[2] as List<SoulRowSample>;
    final topJoy = results[3] as BestJoyMomentRow?;
    final totalSoulTx = overview.count;

    // D-16: all personal metrics co-empty under totalSoulTx == 0.
    if (totalSoulTx == 0) {
      return HappinessReport(
        year: endDate.year,
        month: endDate.month,
        bookId: bookId,
        totalSoulTx: 0,
        avgSatisfaction: const Empty(),
        joyContribution: const Empty(),
        medianSatisfaction: const Empty(),
        highlightsCount: const Empty(),
        topJoy: const Empty(),
      );
    }

    final base = ptvfBaseFor(currencyCode);
    final joyContribution = _computeJoyContribution(ptvfRows, base);
    final median = _computeMedianFromDistribution(distribution);
    final highlights = _countHighlights(distribution);

    return HappinessReport(
      year: endDate.year,
      month: endDate.month,
      bookId: bookId,
      totalSoulTx: totalSoulTx,
      avgSatisfaction: Value(overview.avgSatisfaction, totalSoulTx),
      joyContribution: Value(joyContribution, totalSoulTx),
      medianSatisfaction: Value(median, totalSoulTx),
      highlightsCount: Value(highlights, totalSoulTx),
      topJoy: topJoy == null ? const Empty() : Value(topJoy, totalSoulTx),
    );
  }

  /// ADR-016 §2: joy_contribution = Σ(sat × (amount/base)^α).
  double _computeJoyContribution(List<SoulRowSample> rows, double base) {
    if (rows.isEmpty) return 0;
    var sum = 0.0;
    for (final r in rows) {
      final scaled = math.pow(r.amount / base, _ptvfAlpha).toDouble();
      sum += r.soulSatisfaction * scaled;
    }
    return sum;
  }

  /// RESEARCH Q2 Option A: count-keyed walk over score distribution.
  double _computeMedianFromDistribution(List<SatisfactionScoreBucket> dist) {
    final total = dist.fold<int>(0, (sum, bucket) => sum + bucket.count);
    if (total == 0) return 0;

    final isEven = total % 2 == 0;
    final midIndex = total ~/ 2;
    var cumulative = 0;
    int? lower;

    for (final bucket in dist) {
      cumulative += bucket.count;
      if (lower == null && cumulative > (isEven ? midIndex - 1 : midIndex)) {
        lower = bucket.score;
      }
      if (cumulative > midIndex) {
        return isEven ? (lower! + bucket.score) / 2.0 : bucket.score.toDouble();
      }
    }

    return 0;
  }

  /// HAPPY-03 / D-05: count transactions with sat >= 6.
  int _countHighlights(List<SatisfactionScoreBucket> dist) {
    var count = 0;
    for (final bucket in dist) {
      if (bucket.score >= _highlightsThreshold) {
        count += bucket.count;
      }
    }
    return count;
  }
}
