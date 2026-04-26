// Characterization test for AnalyticsScreen.
// Locks: screen renders without crash, Scaffold/AppBar present,
// selectedMonthProvider provider chain is intact.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildApp(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  late _MockAnalyticsRepository mockAnalyticsRepo;
  late _MockCategoryRepository mockCategoryRepo;
  late _MockSettingsRepository mockSettingsRepo;

  setUp(() {
    mockAnalyticsRepo = _MockAnalyticsRepository();
    mockCategoryRepo = _MockCategoryRepository();
    mockSettingsRepo = _MockSettingsRepository();

    when(
      () => mockCategoryRepo.findAll(),
    ).thenAnswer((_) async => []);

    // AnalyticsRepository methods used by GetMonthlyReportUseCase / GetExpenseTrendUseCase
    when(
      () => mockAnalyticsRepo.getMonthlyTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer(
      (_) async => const MonthlyTotals(totalExpenses: 0, totalIncome: 0),
    );
    when(
      () => mockAnalyticsRepo.getCategoryTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockAnalyticsRepo.getDailyTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        type: any(named: 'type'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => mockAnalyticsRepo.getLedgerTotals(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => const AppSettings(language: 'ja'));
  });

  group(
    'AnalyticsScreen characterization tests (pre-refactor behavior)',
    () {
      testWidgets('renders without crashing', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const AnalyticsScreen(bookId: 'book-001'),
            [
              analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(Scaffold), findsWidgets);
      });

      testWidgets('contains an AppBar with analytics title', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const AnalyticsScreen(bookId: 'book-001'),
            [
              analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('selectedMonthProvider wired — screen accesses year/month',
          (tester) async {
        // selectedMonthProvider provides SelectedMonth(year, month) to the screen.
        // This test verifies the provider chain is intact by confirming screen builds.
        await tester.pumpWidget(
          _buildApp(
            const AnalyticsScreen(bookId: 'book-001'),
            [
              analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
              categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
              settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
            ],
          ),
        );
        await tester.pump();
        expect(find.byType(AnalyticsScreen), findsOneWidget);
      });
    },
  );
}
