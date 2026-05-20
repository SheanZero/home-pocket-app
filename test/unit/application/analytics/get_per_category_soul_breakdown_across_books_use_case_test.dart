import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_soul_breakdown.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

PerCategorySoulBreakdownItem _item(String id, double avg, int count) =>
    PerCategorySoulBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );

void main() {
  late _MockAnalyticsRepository repository;
  late GetPerCategorySoulBreakdownAcrossBooksUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetPerCategorySoulBreakdownAcrossBooksUseCase(
      analyticsRepository: repository,
    );
  });

  void stubAcrossBooks(
    List<String> bookIds,
    List<PerCategorySoulBreakdownItem> items,
  ) {
    when(
      () => repository.getPerCategorySoulBreakdownAcrossBooks(
        bookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      ),
    ).thenAnswer((_) async => items);
  }

  group('empty groupBookIds short-circuit', () {
    test('returns Empty and never calls repository', () async {
      final result = await useCase.execute(
        groupBookIds: const [],
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Empty<PerCategorySoulBreakdown>>());
      verifyNever(
        () => repository.getPerCategorySoulBreakdownAcrossBooks(
          bookIds: any(named: 'bookIds'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    });
  });

  group('non-empty groupBookIds', () {
    test('forwards exact bookIds list to repository', () async {
      final bookIds = ['b1', 'b2', 'b3'];
      stubAcrossBooks(bookIds, const []);

      await useCase.execute(
        groupBookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      );

      verify(
        () => repository.getPerCategorySoulBreakdownAcrossBooks(
          bookIds: bookIds,
          startDate: startDate,
          endDate: endDate,
        ),
      ).called(1);
    });

    test('partitions + sorts D-07 + folds Other across pooled rows', () async {
      final bookIds = ['b1', 'b2'];
      stubAcrossBooks(bookIds, [
        _item('cat_a', 8.0, 5), // qualifying
        _item('cat_b', 7.0, 3), // qualifying
        _item('cat_c', 9.5, 2), // low-N
        _item('cat_d', 4.0, 1), // low-N
      ]);

      final result =
          await useCase.execute(
                groupBookIds: bookIds,
                startDate: startDate,
                endDate: endDate,
              )
              as Value<PerCategorySoulBreakdown>;

      expect(result.data.items.map((i) => i.categoryId).toList(), [
        'cat_a',
        'cat_b',
      ]);
      expect(result.data.otherCount, 3); // 2 + 1
      expect(result.data.otherCategoryCount, 2);
      expect(result.data.totalCount, 5 + 3 + 3);
    });

    test('empty repo result → Empty', () async {
      final bookIds = ['b1', 'b2'];
      stubAcrossBooks(bookIds, const []);

      final result = await useCase.execute(
        groupBookIds: bookIds,
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Empty<PerCategorySoulBreakdown>>());
    });
  });

  group('time window validation', () {
    test('throws ArgumentError when start > end', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => useCase.execute(
          groupBookIds: const ['b1'],
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });
  });
}
