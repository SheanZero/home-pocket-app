import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_monthly_joy_target_recommendation_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetMonthlyJoyTargetRecommendationUseCase useCase;

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetMonthlyJoyTargetRecommendationUseCase(
      analyticsRepository: repository,
    );
  });

  Future<Value<T>> valueMetric<T>(MetricResult<T> result) async {
    expect(result, isA<Value<T>>());
    return result as Value<T>;
  }

  Future<Empty<T>> emptyMetric<T>(MetricResult<T> result) async {
    expect(result, isA<Empty<T>>());
    return result as Empty<T>;
  }

  Future<MetricResult<int>> execute({
    String currencyCode = 'JPY',
    DateTime? asOf,
  }) {
    return useCase.execute(
      bookId: 'book-1',
      currencyCode: currencyCode,
      asOf: asOf ?? DateTime(2026, 5, 15),
    );
  }

  void stubMonth({
    required int year,
    required int month,
    required List<SoulRowSample> rows,
  }) {
    when(
      () => repository.getSoulRowsForJoyContribution(
        bookId: 'book-1',
        startDate: DateTime(year, month, 1),
        endDate: DateTime(year, month + 1, 0, 23, 59, 59),
      ),
    ).thenAnswer((_) async => rows);
  }

  void stubDefaultPastMonths({
    required List<SoulRowSample> m1,
    required List<SoulRowSample> m2,
    required List<SoulRowSample> m3,
  }) {
    stubMonth(year: 2026, month: 4, rows: m1);
    stubMonth(year: 2026, month: 3, rows: m2);
    stubMonth(year: 2026, month: 2, rows: m3);
  }

  List<SoulRowSample> repeatedBaseRows(int count, {int satisfaction = 1}) {
    return List.generate(
      count,
      (_) => SoulRowSample(amount: 500, joyFullness: satisfaction),
    );
  }

  group('GetMonthlyJoyTargetRecommendationUseCase', () {
    test('returns ceil median when all three past months have rows', () async {
      stubDefaultPastMonths(
        m1: repeatedBaseRows(40),
        m2: repeatedBaseRows(60),
        m3: repeatedBaseRows(80),
      );

      final result = await execute();
      final value = await valueMetric<int>(result);

      expect(value.data, 60);
      expect(value.sampleSize, 3);
    });

    test('returns Empty when only two of three months have rows', () async {
      stubDefaultPastMonths(
        m1: repeatedBaseRows(40),
        m2: const [],
        m3: repeatedBaseRows(80),
      );

      final result = await execute();

      await emptyMetric<int>(result);
    });

    test('returns Empty when no past months have rows', () async {
      stubDefaultPastMonths(m1: const [], m2: const [], m3: const []);

      final result = await execute();

      await emptyMetric<int>(result);
    });

    test(
      'includes all-zero satisfaction months as Value zero samples',
      () async {
        stubDefaultPastMonths(
          m1: repeatedBaseRows(3, satisfaction: 0),
          m2: repeatedBaseRows(2, satisfaction: 0),
          m3: repeatedBaseRows(1, satisfaction: 0),
        );

        final result = await execute();
        final value = await valueMetric<int>(result);

        expect(value.data, 0);
        expect(value.sampleSize, 3);
      },
    );

    test('ceil boundary keeps exact integer median unchanged', () async {
      stubDefaultPastMonths(
        m1: repeatedBaseRows(40),
        m2: repeatedBaseRows(50),
        m3: repeatedBaseRows(80),
      );

      final result = await execute();
      final value = await valueMetric<int>(result);

      expect(value.data, 50);
    });

    test('ceil boundary rounds fractional median up', () async {
      stubDefaultPastMonths(
        m1: repeatedBaseRows(40),
        m2: [
          ...repeatedBaseRows(50),
          const SoulRowSample(amount: 100, joyFullness: 1),
        ],
        m3: repeatedBaseRows(80),
      );

      final result = await execute();
      final value = await valueMetric<int>(result);

      expect(value.data, 51);
    });

    test('uses currency-specific PTVF base for CNY', () async {
      stubDefaultPastMonths(
        m1: const [SoulRowSample(amount: 25, joyFullness: 10)],
        m2: const [SoulRowSample(amount: 50, joyFullness: 10)],
        m3: const [SoulRowSample(amount: 75, joyFullness: 10)],
      );

      final result = await execute(currencyCode: 'CNY');
      final value = await valueMetric<int>(result);

      expect(value.data, 19);
    });

    test('samples previous months across a year boundary', () async {
      stubMonth(year: 2026, month: 1, rows: repeatedBaseRows(10));
      stubMonth(year: 2025, month: 12, rows: repeatedBaseRows(20));
      stubMonth(year: 2025, month: 11, rows: repeatedBaseRows(30));

      final result = await execute(asOf: DateTime(2026, 2, 15));
      final value = await valueMetric<int>(result);

      expect(value.data, 20);
      verify(
        () => repository.getSoulRowsForJoyContribution(
          bookId: 'book-1',
          startDate: DateTime(2026),
          endDate: DateTime(2026, 2, 0, 23, 59, 59),
        ),
      ).called(1);
      verify(
        () => repository.getSoulRowsForJoyContribution(
          bookId: 'book-1',
          startDate: DateTime(2025, 12),
          endDate: DateTime(2026, 1, 0, 23, 59, 59),
        ),
      ).called(1);
      verify(
        () => repository.getSoulRowsForJoyContribution(
          bookId: 'book-1',
          startDate: DateTime(2025, 11),
          endDate: DateTime(2025, 12, 0, 23, 59, 59),
        ),
      ).called(1);
    });
  });
}
