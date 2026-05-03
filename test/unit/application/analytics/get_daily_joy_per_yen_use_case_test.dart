import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_daily_joy_per_yen_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/daily_joy_per_yen_point.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetDailyJoyPerYenUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetDailyJoyPerYenUseCase(analyticsRepository: repository);
  });

  void stubDailyRows(List<DailySoulRowSampleWithDay> rows) {
    when(
      () => repository.getDailySoulRowsForPtvf(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => rows);
  }

  Future<MetricResult<List<DailyJoyPerYenPoint>>> execute({
    String currencyCode = 'JPY',
  }) {
    return useCase.execute(
      bookId: 'book-1',
      year: 2026,
      month: 5,
      currencyCode: currencyCode,
    );
  }

  double expectedDensity(List<SoulRowSample> rows, double base) {
    var numerator = 0.0;
    var denominator = 0;
    for (final row in rows) {
      numerator +=
          row.soulSatisfaction * math.pow(row.amount / base, 0.88).toDouble();
      denominator += row.amount;
    }
    return numerator / denominator;
  }

  test('returns Empty when no soul rows in window', () async {
    stubDailyRows(const []);

    final result = await execute();

    expect(result, isA<Empty<List<DailyJoyPerYenPoint>>>());
  });

  test('groups rows by day-of-month and folds PTVF per day', () async {
    stubDailyRows([
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 1000,
        soulSatisfaction: 8,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 500,
        soulSatisfaction: 6,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 200,
        soulSatisfaction: 4,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 10),
        amount: 2000,
        soulSatisfaction: 10,
      ),
    ]);

    final result = await execute();

    expect(result, isA<Value<List<DailyJoyPerYenPoint>>>());
    final value = result as Value<List<DailyJoyPerYenPoint>>;
    expect(value.data, hasLength(2));

    final day5 = value.data.singleWhere((point) => point.day == 5);
    final day10 = value.data.singleWhere((point) => point.day == 10);
    expect(day5.sampleSize, 3);
    expect(day10.sampleSize, 1);
    expect(
      day5.joyPerYen,
      closeTo(
        expectedDensity(const [
          SoulRowSample(amount: 1000, soulSatisfaction: 8),
          SoulRowSample(amount: 500, soulSatisfaction: 6),
          SoulRowSample(amount: 200, soulSatisfaction: 4),
        ], 500),
        0.0001,
      ),
    );
    expect(
      day10.joyPerYen,
      closeTo(
        expectedDensity(const [
          SoulRowSample(amount: 2000, soulSatisfaction: 10),
        ], 500),
        0.0001,
      ),
    );
  });

  test('currency base flows correctly', () async {
    stubDailyRows([
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 1000,
        soulSatisfaction: 8,
      ),
    ]);

    final jpy = await execute();
    final cny = await execute(currencyCode: 'CNY');

    final jpyPoint = (jpy as Value<List<DailyJoyPerYenPoint>>).data.single;
    final cnyPoint = (cny as Value<List<DailyJoyPerYenPoint>>).data.single;
    expect(jpyPoint.joyPerYen, isNot(cnyPoint.joyPerYen));
    expect(
      cnyPoint.joyPerYen,
      closeTo(
        expectedDensity(const [
          SoulRowSample(amount: 1000, soulSatisfaction: 8),
        ], 25),
        0.0001,
      ),
    );
  });

  test('uses correct month boundaries', () async {
    stubDailyRows(const []);

    await execute();

    verify(
      () => repository.getDailySoulRowsForPtvf(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).called(1);
  });

  test('sample size equals total rows folded into all days', () async {
    stubDailyRows([
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 1000,
        soulSatisfaction: 8,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 500,
        soulSatisfaction: 6,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 5),
        amount: 200,
        soulSatisfaction: 4,
      ),
      DailySoulRowSampleWithDay(
        day: DateTime(2026, 5, 10),
        amount: 2000,
        soulSatisfaction: 10,
      ),
    ]);

    final result = await execute();

    final value = result as Value<List<DailyJoyPerYenPoint>>;
    expect(value.sampleSize, 4);
    expect(value.data.singleWhere((point) => point.day == 5).sampleSize, 3);
    expect(value.data.singleWhere((point) => point.day == 10).sampleSize, 1);
  });
}
