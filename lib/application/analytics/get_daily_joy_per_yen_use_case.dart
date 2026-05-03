import 'dart:math' as math;

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/daily_joy_per_yen_point.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_density_formatter.dart';

/// STATSUI-01 / D-05 — per-day Joy/¥ density via Dart-layer PTVF fold.
///
/// Mirrors monthly fold in `GetHappinessReportUseCase` with the same α and
/// currency-aware base resolution.
class GetDailyJoyPerYenUseCase {
  GetDailyJoyPerYenUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// Kahneman & Tversky 1979 PTVF empirical fit (ADR-013).
  static const double _ptvfAlpha = 0.88;

  Future<MetricResult<List<DailyJoyPerYenPoint>>> execute({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final rows = await _repo.getDailySoulRowsForPtvf(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    if (rows.isEmpty) {
      return const Empty();
    }

    final base = ptvfBaseFor(currencyCode);
    final byDay = <int, List<SoulRowSample>>{};
    for (final row in rows) {
      (byDay[row.day.day] ??= <SoulRowSample>[]).add(
        SoulRowSample(
          amount: row.amount,
          soulSatisfaction: row.soulSatisfaction,
        ),
      );
    }

    final points = <DailyJoyPerYenPoint>[];
    var totalSampleSize = 0;
    final sortedDays = byDay.keys.toList()..sort();
    for (final day in sortedDays) {
      final dayRows = byDay[day]!;
      points.add(
        DailyJoyPerYenPoint(
          day: day,
          joyPerYen: _computePtvfDensity(dayRows, base),
          sampleSize: dayRows.length,
        ),
      );
      totalSampleSize += dayRows.length;
    }

    return Value(points, totalSampleSize);
  }

  /// HAPPY-02 / ADR-013: density = Σ(sat × (amount/base)^α) / Σ(amount).
  double _computePtvfDensity(List<SoulRowSample> rows, double base) {
    if (rows.isEmpty) return 0;
    var numerator = 0.0;
    var denominator = 0;
    for (final r in rows) {
      final scaled = math.pow(r.amount / base, _ptvfAlpha).toDouble();
      numerator += r.soulSatisfaction * scaled;
      denominator += r.amount;
    }
    if (denominator == 0) return 0;
    return numerator / denominator;
  }
}
