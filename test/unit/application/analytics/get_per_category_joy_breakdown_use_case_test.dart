import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_per_category_joy_breakdown_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/entry_source.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/per_category_joy_breakdown.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

PerCategoryJoyBreakdownItem _item(String id, double avg, int count) =>
    PerCategoryJoyBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );

void main() {
  late _MockAnalyticsRepository repository;
  late GetPerCategoryJoyBreakdownUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);
  const bookId = 'book-1';

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetPerCategoryJoyBreakdownUseCase(
      analyticsRepository: repository,
    );
  });

  void stubBreakdown(
    List<PerCategoryJoyBreakdownItem> items, {
    EntrySource? entrySourceFilter,
  }) {
    when(
      () => repository.getPerCategoryJoyBreakdown(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
        entrySourceFilter: entrySourceFilter,
      ),
    ).thenAnswer((_) async => items);
  }

  Future<MetricResult<PerCategoryJoyBreakdown>> execute({
    EntrySource? entrySourceFilter,
  }) {
    return useCase.execute(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      entrySourceFilter: entrySourceFilter,
    );
  }

  group('empty repo result', () {
    test('returns Empty<PerCategoryJoyBreakdown>', () async {
      stubBreakdown(const []);

      final result = await execute();

      expect(result, isA<Empty<PerCategoryJoyBreakdown>>());
    });
  });

  group('sub min-N only', () {
    test(
      'returns Value with items=[], otherCount=sum, otherCategoryCount=N',
      () async {
        stubBreakdown([
          _item('cat_a', 7.0, 2),
          _item('cat_b', 5.5, 1),
          _item('cat_c', 8.0, 2),
        ]);

        final result = await execute() as Value<PerCategoryJoyBreakdown>;

        expect(result.data.items, isEmpty);
        expect(result.data.otherCount, 5); // 2 + 1 + 2
        expect(result.data.otherCategoryCount, 3);
        expect(result.data.totalCount, 5);
        expect(result.sampleSize, 5);
      },
    );
  });

  group('mixed qualifying + low-N', () {
    test('partitions, sorts D-07, and folds Other counts', () async {
      stubBreakdown([
        _item('cat_a', 8.0, 4),
        _item('cat_b', 6.5, 3),
        _item('cat_c', 9.0, 2), // low-N
      ]);

      final result = await execute() as Value<PerCategoryJoyBreakdown>;

      // items pre-sorted: avg DESC: cat_a(8.0,4) then cat_b(6.5,3).
      expect(result.data.items.map((i) => i.categoryId).toList(), [
        'cat_a',
        'cat_b',
      ]);
      expect(result.data.otherCount, 2); // single low-N item with count=2
      expect(result.data.otherCategoryCount, 1);
      // totalCount = qualifying sum (4+3) + other (2)
      expect(result.data.totalCount, 9);
      expect(result.sampleSize, 9);
    });
  });

  group('sort tie-break', () {
    test('AVG equal → COUNT DESC → categoryId ASC', () async {
      // cat_x and cat_z share (7.0, 5); cat_y has (7.0, 3).
      // Expected order: cat_x, cat_z (alphabetical tie-break with equal count),
      // then cat_y (lower count).
      stubBreakdown([
        _item('cat_x', 7.0, 5),
        _item('cat_y', 7.0, 3),
        _item('cat_z', 7.0, 5),
      ]);

      final result = await execute() as Value<PerCategoryJoyBreakdown>;

      expect(result.data.items.map((i) => i.categoryId).toList(), [
        'cat_x',
        'cat_z',
        'cat_y',
      ]);
    });
  });

  group('totalCount invariant', () {
    test('equals sum of qualifying counts + otherCount', () async {
      stubBreakdown([
        _item('cat_a', 8.0, 5),
        _item('cat_b', 7.0, 4),
        _item('cat_c', 6.0, 1),
        _item('cat_d', 5.0, 2),
      ]);

      final result = await execute() as Value<PerCategoryJoyBreakdown>;

      final qualifyingSum = result.data.items.fold<int>(
        0,
        (acc, item) => acc + item.totalCount,
      );
      expect(qualifyingSum, 9); // 5 + 4
      expect(result.data.otherCount, 3); // 1 + 2
      expect(result.data.totalCount, qualifyingSum + result.data.otherCount);
    });
  });

  group('entrySourceFilter forwarding', () {
    test(
      'execute with entrySourceFilter = null preserves default behavior',
      () async {
        final items = [_item('cat_a', 8.0, 3)];
        stubBreakdown(items, entrySourceFilter: null);

        final result = await execute() as Value<PerCategoryJoyBreakdown>;

        expect(result.data.items.single.categoryId, 'cat_a');
        verify(
          () => repository.getPerCategoryJoyBreakdown(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: null,
          ),
        ).called(1);
      },
    );

    test(
      'execute with entrySourceFilter = EntrySource.manual forwards filter',
      () async {
        final items = [_item('cat_manual', 9.0, 4)];
        stubBreakdown(items, entrySourceFilter: EntrySource.manual);

        final result =
            await execute(entrySourceFilter: EntrySource.manual)
                as Value<PerCategoryJoyBreakdown>;

        expect(result.data.items.single.categoryId, 'cat_manual');
        verify(
          () => repository.getPerCategoryJoyBreakdown(
            bookId: bookId,
            startDate: startDate,
            endDate: endDate,
            entrySourceFilter: EntrySource.manual,
          ),
        ).called(1);
      },
    );
  });

  group('time window validation', () {
    test('throws ArgumentError when start > end', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime(2026, 5, 31),
          endDate: DateTime(2026, 5),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when range exceeds 12 months', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime(2024, 5),
          endDate: DateTime(2025, 6),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when endDate is in the future', () async {
      expect(
        () => useCase.execute(
          bookId: bookId,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 2)),
        ),
        throwsArgumentError,
      );
    });
  });
}
