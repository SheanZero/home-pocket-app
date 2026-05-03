import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_satisfaction_distribution_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetSatisfactionDistributionUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetSatisfactionDistributionUseCase(
      analyticsRepository: repository,
    );
  });

  void stubDistribution(List<SatisfactionScoreBucket> buckets) {
    when(
      () => repository.getSatisfactionDistribution(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => buckets);
  }

  Future<List<SatisfactionScoreBucket>> execute() {
    return useCase.execute(bookId: 'book-1', year: 2026, month: 5);
  }

  test('passes through repository buckets', () async {
    const buckets = [
      SatisfactionScoreBucket(score: 5, count: 2),
      SatisfactionScoreBucket(score: 8, count: 3),
    ];
    stubDistribution(buckets);

    final result = await execute();

    expect(result, buckets);
  });

  test('uses selected month boundaries', () async {
    stubDistribution(const []);

    await execute();

    verify(
      () => repository.getSatisfactionDistribution(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      ),
    ).called(1);
  });
}
