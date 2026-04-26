import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_budget_progress_use_case.dart';
import 'package:home_pocket/application/analytics/get_expense_trend_use_case.dart';
import 'package:home_pocket/application/analytics/get_monthly_report_use_case.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late _MockAnalyticsRepository mockAnalyticsRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late ProviderContainer container;

  setUp(() {
    mockAnalyticsRepo = _MockAnalyticsRepository();
    mockCategoryRepo = _MockCategoryRepository();

    container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'analytics/analytics_providers characterization tests (pre-refactor behavior)',
    () {
      test('selectedMonthProvider initial state is current month', () {
        final month = container.read(selectedMonthProvider);
        final now = DateTime.now();
        // Initial state should be current year/month
        expect(month.year, now.year);
        expect(month.month, now.month);
      });

      test('selectedMonthProvider setMonth changes state correctly', () {
        final target = DateTime(2026, 3);
        container.read(selectedMonthProvider.notifier).setMonth(target);
        final month = container.read(selectedMonthProvider);
        expect(month.year, 2026);
        expect(month.month, 3);
      });

      test('selectedMonthProvider previousMonth navigates back one month', () {
        container
            .read(selectedMonthProvider.notifier)
            .setMonth(DateTime(2026, 3));
        container.read(selectedMonthProvider.notifier).previousMonth();
        final month = container.read(selectedMonthProvider);
        expect(month.month, 2);
        expect(month.year, 2026);
      });

      test('selectedMonthProvider nextMonth navigates forward one month', () {
        container
            .read(selectedMonthProvider.notifier)
            .setMonth(DateTime(2026, 3));
        container.read(selectedMonthProvider.notifier).nextMonth();
        final month = container.read(selectedMonthProvider);
        expect(month.month, 4);
        expect(month.year, 2026);
      });

      test('getMonthlyReportUseCaseProvider constructs without error', () {
        final uc = container.read(getMonthlyReportUseCaseProvider);
        expect(uc, isA<GetMonthlyReportUseCase>());
      });

      test('getBudgetProgressUseCaseProvider constructs without error', () {
        final uc = container.read(getBudgetProgressUseCaseProvider);
        expect(uc, isA<GetBudgetProgressUseCase>());
      });

      test('getExpenseTrendUseCaseProvider constructs without error', () {
        final uc = container.read(getExpenseTrendUseCaseProvider);
        expect(uc, isA<GetExpenseTrendUseCase>());
      });
    },
  );
}
