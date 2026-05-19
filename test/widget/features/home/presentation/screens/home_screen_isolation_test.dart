@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_best_joy_moment_use_case.dart';
import 'package:home_pocket/application/analytics/get_family_happiness_use_case.dart';
import 'package:home_pocket/application/analytics/get_happiness_report_use_case.dart';
import 'package:home_pocket/application/analytics/get_monthly_report_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    as accounting_providers;
import 'package:home_pocket/features/analytics/domain/models/time_window.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_time_window.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
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

  setUp(() {
    final now = DateTime.now();
    currentMonthStart = DateTime(now.year, now.month);
    currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    monthlyReportUseCase = _MockMonthlyReportUseCase();
    happinessReportUseCase = _MockHappinessReportUseCase();
    bestJoyMomentUseCase = _MockBestJoyMomentUseCase();
    familyHappinessUseCase = _MockFamilyHappinessUseCase();

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
  });

  Widget buildSubject() {
    return createLocalizedWidget(
      const Scaffold(body: HomeScreen(bookId: _bookId)),
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
  });
}
