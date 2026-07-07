import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

// P2-3: the provider must assemble its MemberFilteredCategoryBreakdown from the
// SQL-pushed getMemberCategoryTotals rows (total, per-category percentage, entry
// count) and push the member narrowing down as `deviceId` — not pull all rows
// and filter in Dart.
void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  test(
    'assembles totals + percentages from getMemberCategoryTotals and pushes '
    'deviceId to SQL',
    () async {
      final repo = _MockAnalyticsRepository();
      when(
        () => repo.getMemberCategoryTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          deviceId: any(named: 'deviceId'),
          entrySourceFilter: any(named: 'entrySourceFilter'),
        ),
      ).thenAnswer(
        (_) async => const [
          CategoryTotal(
            categoryId: 'cat_food',
            totalAmount: 3000,
            transactionCount: 3,
          ),
          CategoryTotal(
            categoryId: 'cat_transport',
            totalAmount: 1000,
            transactionCount: 1,
          ),
        ],
      );

      final container = ProviderContainer.test(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repo)],
      );
      final provider = memberFilteredCategoryBreakdownProvider(
        bookId: 'book1',
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 31),
        deviceId: 'device_a',
      );
      // Hold a subscription so the auto-dispose provider isn't torn down mid-read.
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      final data = await container.read(provider.future);

      expect(data.total, 4000);
      expect(data.entryCount, 4);
      expect(data.breakdowns, hasLength(2));

      final food = data.breakdowns.firstWhere(
        (b) => b.categoryId == 'cat_food',
      );
      expect(food.amount, 3000);
      expect(food.transactionCount, 3);
      expect(food.percentage, closeTo(75.0, 0.001)); // 3000 / 4000

      final transport = data.breakdowns.firstWhere(
        (b) => b.categoryId == 'cat_transport',
      );
      expect(transport.percentage, closeTo(25.0, 0.001)); // 1000 / 4000

      // Member narrowing is pushed to SQL as deviceId (not Dart-filtered).
      final captured = verify(
        () => repo.getMemberCategoryTotals(
          bookId: 'book1',
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          deviceId: captureAny(named: 'deviceId'),
          entrySourceFilter: any(named: 'entrySourceFilter'),
        ),
      ).captured;
      expect(captured.single, 'device_a');
    },
  );
}
