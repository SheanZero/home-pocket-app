import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_best_joy_moment_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/models/best_joy_moment_row.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repo;
  late GetBestJoyMomentUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

  setUp(() {
    repo = _MockAnalyticsRepository();
    useCase = GetBestJoyMomentUseCase(analyticsRepository: repo);
  });

  group('GetBestJoyMomentUseCase', () {
    test(
      'returns Empty when overview.count == 0 and short-circuits DAO',
      () async {
        when(
          () => repo.getSoulSatisfactionOverview(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer(
          (_) async =>
              const SoulSatisfactionOverview(avgSatisfaction: 0, count: 0),
        );

        final result = await useCase.execute(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isA<Empty<BestJoyMomentRow>>());
        verifyNever(
          () => repo.getBestJoyMoment(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        );
      },
    );

    test(
      'returns Empty when overview.count > 0 and best joy row is null',
      () async {
        when(
          () => repo.getSoulSatisfactionOverview(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer(
          (_) async =>
              const SoulSatisfactionOverview(avgSatisfaction: 7.2, count: 5),
        );
        when(
          () => repo.getBestJoyMoment(
            bookId: 'book-1',
            startDate: startDate,
            endDate: endDate,
          ),
        ).thenAnswer((_) async => null);

        final result = await useCase.execute(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        );

        expect(result, isA<Empty<BestJoyMomentRow>>());
      },
    );

    test('returns Value with the same BestJoyMomentRow instance', () async {
      final row = BestJoyMomentRow(
        transactionId: 'tx-best',
        amount: 3000,
        soulSatisfaction: 10,
        categoryId: 'cat-coffee',
        timestamp: DateTime(2026, 5, 20, 18, 30),
      );
      when(
        () => repo.getSoulSatisfactionOverview(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer(
        (_) async =>
            const SoulSatisfactionOverview(avgSatisfaction: 7.2, count: 5),
      );
      when(
        () => repo.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer((_) async => row);

      final result = await useCase.execute(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      );

      expect(
        result,
        isA<Value<BestJoyMomentRow>>()
            .having((value) => value.data, 'data', same(row))
            .having((value) => value.sampleSize, 'sampleSize', 5),
      );
    });

    test('aligns Value sampleSize with overview.count', () async {
      final row = BestJoyMomentRow(
        transactionId: 'tx-best',
        amount: 4500,
        soulSatisfaction: 9,
        categoryId: 'cat-books',
        timestamp: DateTime(2026, 5, 21, 19),
      );
      when(
        () => repo.getSoulSatisfactionOverview(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer(
        (_) async =>
            const SoulSatisfactionOverview(avgSatisfaction: 6.4, count: 11),
      );
      when(
        () => repo.getBestJoyMoment(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer((_) async => row);

      final result = await useCase.execute(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<Value<BestJoyMomentRow>>());
      expect((result as Value<BestJoyMomentRow>).sampleSize, 11);
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
  });
}
