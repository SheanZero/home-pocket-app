import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_budget_progress_use_case.dart';
import 'package:home_pocket/application/analytics/get_monthly_report_use_case.dart';
import 'package:home_pocket/application/analytics/get_within_month_cumulative_use_case.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

void main() {
  late _MockAnalyticsRepository mockAnalyticsRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late _MockTransactionRepository mockTransactionRepo;
  late ProviderContainer container;

  setUp(() {
    mockAnalyticsRepo = _MockAnalyticsRepository();
    mockCategoryRepo = _MockCategoryRepository();
    mockTransactionRepo = _MockTransactionRepository();

    container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group(
    'analytics/analytics_providers characterization tests (pre-refactor behavior)',
    () {
      // SelectedTimeWindow tests live in state_time_window_test.dart (Phase 15).

      test('getMonthlyReportUseCaseProvider constructs without error', () {
        final uc = container.read(getMonthlyReportUseCaseProvider);
        expect(uc, isA<GetMonthlyReportUseCase>());
      });

      test('getBudgetProgressUseCaseProvider constructs without error', () {
        final uc = container.read(getBudgetProgressUseCaseProvider);
        expect(uc, isA<GetBudgetProgressUseCase>());
      });

      test(
        'getWithinMonthCumulativeUseCaseProvider constructs without error '
        '(within-month cumulative trend path, D-E1)',
        () {
          final uc = container.read(getWithinMonthCumulativeUseCaseProvider);
          expect(uc, isA<GetWithinMonthCumulativeUseCase>());
        },
      );
    },
  );
}
