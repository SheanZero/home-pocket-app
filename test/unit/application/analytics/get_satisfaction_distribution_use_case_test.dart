import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_satisfaction_distribution_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetSatisfactionDistributionUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

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
    return useCase.execute(
      bookId: 'book-1',
      startDate: startDate,
      endDate: endDate,
    );
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

  test('combines score buckets across all family books', () async {
    when(
      () => repository.getSatisfactionDistribution(
        bookId: any(named: 'bookId'),
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((invocation) async {
      final bookId = invocation.namedArguments[#bookId] as String;
      return bookId == 'personal'
          ? const [SatisfactionScoreBucket(score: 6, count: 1)]
          : const [
              SatisfactionScoreBucket(score: 6, count: 2),
              SatisfactionScoreBucket(score: 9, count: 1),
            ];
    });

    final result = await useCase.executeAcrossBooks(
      bookIds: const ['personal', 'shadow'],
      startDate: startDate,
      endDate: endDate,
    );

    expect(result, hasLength(2));
    expect(result[0].score, 6);
    expect(result[0].count, 3);
    expect(result[1].score, 9);
    expect(result[1].count, 1);
  });

  test('throws ArgumentError when start > end', () async {
    expect(
      () => useCase.execute(
        bookId: 'book-1',
        startDate: DateTime(2026, 5, 31),
        endDate: DateTime(2026, 5),
      ),
      throwsArgumentError,
    );
  });

  test('throws ArgumentError when range exceeds 12 months', () async {
    expect(
      () => useCase.execute(
        bookId: 'book-1',
        startDate: DateTime(2024, 5),
        endDate: DateTime(2025, 6),
      ),
      throwsArgumentError,
    );
  });

  test('throws ArgumentError when endDate is in the future', () async {
    expect(
      () => useCase.execute(
        bookId: 'book-1',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 2)),
      ),
      throwsArgumentError,
    );
  });
}
