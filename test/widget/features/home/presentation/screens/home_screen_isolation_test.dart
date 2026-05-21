@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_best_joy_moment_use_case.dart';
import 'package:home_pocket/application/analytics/get_family_happiness_use_case.dart';
import 'package:home_pocket/application/analytics/get_happiness_report_use_case.dart';
import 'package:home_pocket/application/analytics/get_monthly_report_use_case.dart';
import 'package:home_pocket/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart';
import 'package:home_pocket/application/analytics/get_per_category_soul_breakdown_use_case.dart';
import 'package:home_pocket/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart';
import 'package:home_pocket/application/analytics/get_soul_vs_survival_snapshot_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_joy_metric_variant.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_hero_card.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/happiness_test_fixtures.dart';
import '../../../../../helpers/test_localizations.dart';

class _MockMonthlyReportUseCase extends Mock
    implements GetMonthlyReportUseCase {}

class _MockHappinessReportUseCase extends Mock
    implements GetHappinessReportUseCase {}

class _MockBestJoyMomentUseCase extends Mock
    implements GetBestJoyMomentUseCase {}

class _MockFamilyHappinessUseCase extends Mock
    implements GetFamilyHappinessUseCase {}

class _MockGetPerCategorySoulBreakdownUseCase extends Mock
    implements GetPerCategorySoulBreakdownUseCase {}

class _MockGetPerCategorySoulBreakdownAcrossBooksUseCase extends Mock
    implements GetPerCategorySoulBreakdownAcrossBooksUseCase {}

class _MockGetSoulVsSurvivalSnapshotUseCase extends Mock
    implements GetSoulVsSurvivalSnapshotUseCase {}

class _MockGetSoulVsSurvivalSnapshotAcrossBooksUseCase extends Mock
    implements GetSoulVsSurvivalSnapshotAcrossBooksUseCase {}

class _TestSelectedTimeWindow extends SelectedTimeWindow {
  @override
  TimeWindow build() => const TimeWindow.year(year: 2020);
}

const _bookId = 'book-x';

final _book = Book(
  id: _bookId,
  name: 'Main Book',
  currency: 'JPY',
  deviceId: 'device_local',
  createdAt: DateTime.utc(2026, 1),
);

final _groupInfo = GroupInfo(
  groupId: 'group_test',
  status: GroupStatus.active,
  groupName: 'Test Group',
  role: 'owner',
  members: const [],
  createdAt: DateTime.utc(2026, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000));
    registerFallbackValue(<String>[]);
  });

  late DateTime currentMonthStart;
  late DateTime currentMonthEnd;
  late _MockMonthlyReportUseCase monthlyReportUseCase;
  late _MockHappinessReportUseCase happinessReportUseCase;
  late _MockBestJoyMomentUseCase bestJoyMomentUseCase;
  late _MockFamilyHappinessUseCase familyHappinessUseCase;
  late _MockGetPerCategorySoulBreakdownUseCase perCategorySoulBreakdownUseCase;
  late _MockGetPerCategorySoulBreakdownAcrossBooksUseCase
  perCategorySoulBreakdownAcrossBooksUseCase;
  late _MockGetSoulVsSurvivalSnapshotUseCase soulVsSurvivalSnapshotUseCase;
  late _MockGetSoulVsSurvivalSnapshotAcrossBooksUseCase
  soulVsSurvivalSnapshotAcrossBooksUseCase;

  setUp(() {
    final now = DateTime.now();
    currentMonthStart = DateTime(now.year, now.month);
    currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    monthlyReportUseCase = _MockMonthlyReportUseCase();
    happinessReportUseCase = _MockHappinessReportUseCase();
    bestJoyMomentUseCase = _MockBestJoyMomentUseCase();
    familyHappinessUseCase = _MockFamilyHappinessUseCase();
    perCategorySoulBreakdownUseCase = _MockGetPerCategorySoulBreakdownUseCase();
    perCategorySoulBreakdownAcrossBooksUseCase =
        _MockGetPerCategorySoulBreakdownAcrossBooksUseCase();
    soulVsSurvivalSnapshotUseCase = _MockGetSoulVsSurvivalSnapshotUseCase();
    soulVsSurvivalSnapshotAcrossBooksUseCase =
        _MockGetSoulVsSurvivalSnapshotAcrossBooksUseCase();

    when(
      () => monthlyReportUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => fixtureMonthlyReportRich());
    when(
      () => happinessReportUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        currencyCode: any(named: 'currencyCode'),
      ),
    ).thenAnswer((_) async => fixtureHappinessReportRich(bookId: _bookId));
    when(
      () => bestJoyMomentUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => fixtureBestJoyResultRich());
    when(
      () => familyHappinessUseCase.execute(
        groupBookIds: any(named: 'groupBookIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => fixtureFamilyHappinessRich());
    // Phase 16: HomeHero must NEVER reach these use cases. Stubbing Empty()
    // keeps any accidental call from throwing (which would mask the
    // verifyNever signal below) — the assertion proper is verifyNever(...).
    when(
      () => perCategorySoulBreakdownUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Empty());
    when(
      () => perCategorySoulBreakdownAcrossBooksUseCase.execute(
        groupBookIds: any(named: 'groupBookIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Empty());
    when(
      () => soulVsSurvivalSnapshotUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Empty());
    when(
      () => soulVsSurvivalSnapshotAcrossBooksUseCase.execute(
        groupBookIds: any(named: 'groupBookIds'),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Empty());
  });

  Widget buildSubject({bool includeJoyMetricVariantToggle = false}) {
    return createLocalizedWidget(
      Scaffold(
        body: Stack(
          children: [
            const HomeScreen(bookId: _bookId),
            if (includeJoyMetricVariantToggle)
              Consumer(
                builder: (context, ref, _) => Positioned(
                  left: 0,
                  bottom: 0,
                  child: TextButton(
                    key: const Key('joy-metric-variant-toggle'),
                    onPressed: () => ref
                        .read(selectedJoyMetricVariantProvider.notifier)
                        .setVariant(JoyMetricVariant.manualOnly),
                    child: const Text('toggle variant'),
                  ),
                ),
              ),
          ],
        ),
      ),
      locale: const Locale('en'),
      overrides: [
        selectedTimeWindowProvider.overrideWith(_TestSelectedTimeWindow.new),
        getMonthlyReportUseCaseProvider.overrideWith(
          (_) => monthlyReportUseCase,
        ),
        getHappinessReportUseCaseProvider.overrideWith(
          (_) => happinessReportUseCase,
        ),
        getBestJoyMomentUseCaseProvider.overrideWith(
          (_) => bestJoyMomentUseCase,
        ),
        getFamilyHappinessUseCaseProvider.overrideWith(
          (_) => familyHappinessUseCase,
        ),
        // Phase 16: provider overrides so a stray HomeHero read (if any
        // regression occurred) would land on these mocks — letting verifyNever
        // detect it instead of throwing on a missing override.
        getPerCategorySoulBreakdownUseCaseProvider.overrideWith(
          (_) => perCategorySoulBreakdownUseCase,
        ),
        getPerCategorySoulBreakdownAcrossBooksUseCaseProvider.overrideWith(
          (_) => perCategorySoulBreakdownAcrossBooksUseCase,
        ),
        getSoulVsSurvivalSnapshotUseCaseProvider.overrideWith(
          (_) => soulVsSurvivalSnapshotUseCase,
        ),
        getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider.overrideWith(
          (_) => soulVsSurvivalSnapshotAcrossBooksUseCase,
        ),
        accounting_providers
            .bookByIdProvider(bookId: _bookId)
            .overrideWith((_) async => _book),
        todayTransactionsProvider(
          bookId: _bookId,
        ).overrideWith((_) async => const []),
        locale_providers.currentLocaleProvider.overrideWith(
          (_) async => const Locale('en'),
        ),
        appSettingsProvider.overrideWith(
          (_) async => const AppSettings(monthlyJoyTarget: 80),
        ),
        monthlyJoyTargetRecommendationProvider(
          bookId: _bookId,
          currencyCode: 'JPY',
        ).overrideWith((_) async => const Empty()),
        activeGroupProvider.overrideWith((_) => Stream.value(_groupInfo)),
        isGroupModeProvider.overrideWith((_) => true),
        shadowBooksProvider.overrideWith(
          (_) async => fixtureShadowBooksThree(),
        ),
        shadowAggregateProvider(
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        ).overrideWith((_) async => fixtureShadowAggregateThree()),
      ],
    );
  }

  testWidgets(
    'HomeHero remains current-month keyed when Analytics window is year 2020',
    (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      verify(
        () => monthlyReportUseCase.execute(
          bookId: _bookId,
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        ),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => happinessReportUseCase.execute(
          bookId: _bookId,
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
          currencyCode: 'JPY',
        ),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => bestJoyMomentUseCase.execute(
          bookId: _bookId,
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        ),
      ).called(greaterThanOrEqualTo(1));
      verify(
        () => familyHappinessUseCase.execute(
          groupBookIds: any(named: 'groupBookIds'),
          startDate: currentMonthStart,
          endDate: currentMonthEnd,
        ),
      ).called(greaterThanOrEqualTo(1));

      verifyNever(
        () => monthlyReportUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: DateTime(2020),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => happinessReportUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: DateTime(2020),
          endDate: any(named: 'endDate'),
          currencyCode: any(named: 'currencyCode'),
        ),
      );
      verifyNever(
        () => bestJoyMomentUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: DateTime(2020),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => familyHappinessUseCase.execute(
          groupBookIds: any(named: 'groupBookIds'),
          startDate: DateTime(2020),
          endDate: any(named: 'endDate'),
        ),
      );

      // Phase 16 — HAPPY-V2-01 + STATSUI-V2-01.
      // HomeHero must never reach the new providers at ALL (it does not
      // consume them). verifyNever with any() proves zero invocations across
      // every parameter shape.
      verifyNever(
        () => perCategorySoulBreakdownUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => perCategorySoulBreakdownAcrossBooksUseCase.execute(
          groupBookIds: any(named: 'groupBookIds'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => soulVsSurvivalSnapshotUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => soulVsSurvivalSnapshotAcrossBooksUseCase.execute(
          groupBookIds: any(named: 'groupBookIds'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    },
  );

  test('HomeScreen file does not import state_time_window', () {
    final source = File(
      'lib/features/home/presentation/screens/home_screen.dart',
    ).readAsStringSync();

    expect(
      source.contains('state_time_window'),
      isFalse,
      reason:
          'D-12: HomeHero must stay current-month anchored (ADR-016 §3); import would couple it to AnalyticsScreen window.',
    );
    expect(source.contains('selectedTimeWindowProvider'), isFalse);
    // Phase 16: HomeHero must not import the new analytics ledger-snapshot
    // providers either — those are AnalyticsScreen-only state.
    expect(
      source.contains('state_ledger_snapshot'),
      isFalse,
      reason:
          'D-12 + Phase 16: HomeScreen must not import analytics state_ledger_snapshot — those providers are AnalyticsScreen-only.',
    );
  });

  testWidgets(
    'AnalyticsScreen JoyMetricVariant toggle does not invalidate or change HomeHero (Phase 17 SC-4 / D-15)',
    (tester) async {
      await tester.pumpWidget(
        buildSubject(includeJoyMetricVariantToggle: true),
      );
      await tester.pumpAndSettle();

      final heroBefore = tester.widget<HomeHeroCard>(find.byType(HomeHeroCard));
      final textsBefore = tester
          .widgetList<Text>(find.byType(Text, skipOffstage: false))
          .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .toList();

      clearInteractions(monthlyReportUseCase);
      clearInteractions(happinessReportUseCase);
      clearInteractions(bestJoyMomentUseCase);
      clearInteractions(familyHappinessUseCase);

      await tester.tap(find.byKey(const Key('joy-metric-variant-toggle')));
      await tester.pumpAndSettle();

      final heroAfter = tester.widget<HomeHeroCard>(find.byType(HomeHeroCard));
      final textsAfter = tester
          .widgetList<Text>(find.byType(Text, skipOffstage: false))
          .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
          .toList();

      expect(
        heroAfter.happiness.joyContribution,
        heroBefore.happiness.joyContribution,
      );
      expect(heroAfter.report, heroBefore.report);
      expect(textsAfter, textsBefore);

      verifyNever(
        () => monthlyReportUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => happinessReportUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          currencyCode: any(named: 'currencyCode'),
        ),
      );
      verifyNever(
        () => bestJoyMomentUseCase.execute(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
      verifyNever(
        () => familyHappinessUseCase.execute(
          groupBookIds: any(named: 'groupBookIds'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      );
    },
  );
}
