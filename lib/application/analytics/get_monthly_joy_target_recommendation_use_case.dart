import 'dart:math' as math;

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';

/// Recommends a monthly Joy target from the past 3 complete months.
class GetMonthlyJoyTargetRecommendationUseCase {
  GetMonthlyJoyTargetRecommendationUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// D-04: Kahneman & Tversky 1979 PTVF empirical fit.
  static const double _ptvfAlpha = 0.88;

  /// Spike-decided per 13-SPIKE.md (D-06), at top of ADR-016 range [30, 100].
  static const int _fallbackBaseline = 100;

  /// Cold-start baseline for UI consumers when [execute] returns [Empty].
  static int get fallbackBaseline => _fallbackBaseline;

  Future<MetricResult<int>> execute({
    required String bookId,
    required String currencyCode,
    required DateTime asOf,
  }) async {
    final base = ptvfBaseFor(currencyCode);
    final windows = List.generate(3, (index) {
      final offset = index + 1;
      return (
        start: DateTime(asOf.year, asOf.month - offset, 1),
        end: DateTime(asOf.year, asOf.month - offset + 1, 0, 23, 59, 59),
      );
    });

    final results = await Future.wait(
      windows.map(
        (window) => _repo.getSoulRowsForJoyContribution(
          bookId: bookId,
          startDate: window.start,
          endDate: window.end,
        ),
      ),
    );

    final monthSums = <double>[];
    for (final rows in results) {
      if (rows.isEmpty) continue;
      monthSums.add(_foldContribution(rows, base));
    }

    if (monthSums.length < 3) {
      return const Empty();
    }

    monthSums.sort();
    final median = monthSums[1];
    return Value(median.ceil(), 3);
  }

  double _foldContribution(List<SoulRowSample> rows, double base) {
    if (rows.isEmpty) return 0;

    var sum = 0.0;
    for (final row in rows) {
      sum +=
          row.joyFullness *
          math.pow(row.amount / base, _ptvfAlpha).toDouble();
    }
    return sum;
  }
}
