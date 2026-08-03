@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/list/get_list_transactions_use_case.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/list/presentation/providers/state_calendar_totals.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/screens/list_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetListTransactionsUseCase extends Mock
    implements GetListTransactionsUseCase {}

class _JulyFamilyListFilter extends ListFilter {
  @override
  ListFilterState build() =>
      const ListFilterState(selectedYear: 2026, selectedMonth: 7);
}

void main() {
  setUpAll(() async {
    final textFont = FontLoader('NotoSansCJK')
      ..addFont(
        File('/System/Library/Fonts/Hiragino Sans GB.ttc').readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await textFont.load();
    final numeralFont = FontLoader('RobotoMonoNumerals')
      ..addFont(
        File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    await numeralFont.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '/Users/xinz/flutter/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf',
        ).readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await materialIcons.load();
    registerFallbackValue(
      const GetListParams(
        bookIds: ['book-1'],
        filter: ListFilterState(selectedYear: 2026, selectedMonth: 7),
      ),
    );
  });

  testWidgets('V16 family list top matches the approved mockup structure', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final useCase = _MockGetListTransactionsUseCase();
    when(
      () => useCase.execute(any()),
    ).thenAnswer((_) async => Result.success(<Transaction>[]));

    final dailyTotals = <DateTime, int>{
      DateTime(2026, 7, 1): 3280,
      DateTime(2026, 7, 3): 12360,
      DateTime(2026, 7, 6): 11200,
      DateTime(2026, 7, 9): 15880,
      DateTime(2026, 7, 10): 11100,
      DateTime(2026, 7, 12): 1240,
      DateTime(2026, 7, 15): 12600,
      DateTime(2026, 7, 18): 4800,
      DateTime(2026, 7, 21): 6400,
      DateTime(2026, 7, 24): 2920,
      DateTime(2026, 7, 27): 4500,
      DateTime(2026, 7, 30): 4180,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locale_providers.currentLocaleProvider.overrideWith(
            (_) async => const Locale('ja'),
          ),
          listFilterProvider.overrideWith(() => _JulyFamilyListFilter()),
          isGroupModeProvider.overrideWithValue(true),
          shadowBooksProvider.overrideWith((_) async => const []),
          getListTransactionsUseCaseProvider.overrideWithValue(useCase),
          calendarDailyTotalsProvider(
            bookId: 'book-1',
            year: 2026,
            month: 7,
          ).overrideWith((_) async => dailyTotals),
          calendarFamilyLedgerTotalsProvider(
            bookId: 'book-1',
            year: 2026,
            month: 7,
          ).overrideWith(
            (_) async => const CalendarLedgerTotals(daily: 174000, joy: 53620),
          ),
          appSettingsProvider.overrideWith(
            (_) async => const AppSettings(weekStartDay: WeekStartDay.monday),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          theme: AppTheme.light.copyWith(
            textTheme: AppTheme.light.textTheme.apply(
              fontFamily: 'NotoSansCJK',
            ),
            primaryTextTheme: AppTheme.light.primaryTextTheme.apply(
              fontFamily: 'NotoSansCJK',
            ),
          ),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(390, 560),
              padding: EdgeInsets.only(top: 20),
            ),
            child: ListScreen(bookId: 'book-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ListScreen),
      matchesGoldenFile('goldens/family_list_top_v16_ja.png'),
    );
  });
}
