import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/state_calendar_totals.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

/// Minimal Book fixture for shadow-book stubs.
Book _stubBook(String id) => Book(
      id: id,
      name: 'Shadow $id',
      currency: 'JPY',
      deviceId: 'device-$id',
      createdAt: DateTime(2026, 1, 1),
      isShadow: true,
    );

/// Fixed filter override — injects a known ListFilterState synchronously.
class _FixedListFilter extends ListFilter {
  _FixedListFilter(this._fixed);
  final ListFilterState _fixed;

  @override
  ListFilterState build() => _fixed;
}

ProviderContainer _makeContainer(
  _MockAnalyticsRepository mockRepo, {
  bool isGroupMode = false,
  List<ShadowBookInfo> shadows = const [],
  ListFilterState? filterState,
}) {
  return ProviderContainer.test(
    overrides: [
      analyticsRepositoryProvider.overrideWithValue(mockRepo),
      isGroupModeProvider.overrideWithValue(isGroupMode),
      shadowBooksProvider.overrideWith((_) async => shadows),
      if (filterState != null)
        listFilterProvider.overrideWith(() => _FixedListFilter(filterState)),
    ],
  );
}

void main() {
  group('calendarDailyTotalsProvider', () {
    test('SC#2: expense-only basis — stub returns one DailyTotal', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => [
          DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1200),
        ],
      );

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map[DateTime(2026, 5, 3)], equals(1200));
      expect(map.length, equals(1));
    });

    test(
      '_dayKey normalization: map lookup succeeds regardless of time component',
      () async {
        final mockRepo = _MockAnalyticsRepository();
        // DAO returns a DailyTotal with a non-midnight time component
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 3, 12, 30), totalAmount: 1200),
          ],
        );

        final container = _makeContainer(mockRepo);
        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasValue, isTrue);
        final map = result.requireValue;
        // Normalized key lookup must succeed: DateTime(2026,5,3,12,30) → _dayKey → DateTime(2026,5,3)
        expect(map[DateTime(2026, 5, 3)], equals(1200));
      },
    );

    test('empty month: map is empty and fold yields 0', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map, isEmpty);
      expect(map.values.fold(0, (a, b) => a + b), equals(0));
    });

    test('D-11: month total fold equals sum of per-day values', () async {
      final mockRepo = _MockAnalyticsRepository();
      when(
        () => mockRepo.getDailyTotals(
          bookId: any(named: 'bookId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer(
        (_) async => [
          DailyTotal(date: DateTime(2026, 5, 3), totalAmount: 1000),
          DailyTotal(date: DateTime(2026, 5, 5), totalAmount: 2000),
          DailyTotal(date: DateTime(2026, 5, 10), totalAmount: 3000),
        ],
      );

      final container = _makeContainer(mockRepo);
      final result = await waitForFirstValue<Map<DateTime, int>>(
        container,
        calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
      );

      expect(result.hasValue, isTrue);
      final map = result.requireValue;
      expect(map.values.fold(0, (a, b) => a + b), equals(6000));
    });

    test(
      'repository error propagates as AsyncValue.error (StateError)',
      () async {
        final mockRepo = _MockAnalyticsRepository();
        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenThrow(StateError('db error'));

        final container = _makeContainer(mockRepo);

        // For @riverpod Future<T> providers in Riverpod 3.1.0, errors thrown
        // by the async function are stored in AsyncValue.error as-is (the raw
        // error, not wrapped in ProviderException).
        // ProviderException wrapping applies to synchronous provider reads only.
        // Import ProviderException from package:flutter_riverpod/misc.dart.
        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasError, isTrue);
        // The error stored in AsyncValue is the raw StateError thrown by the repo.
        // Use ProviderException pattern when reading synchronous providers;
        // for async providers the inner error is accessible directly.
        expect(result.error, isA<StateError>());
        expect(
          () => container.read(
            calendarDailyTotalsProvider(
              bookId: 'book1',
              year: 2026,
              month: 5,
            ),
          ),
          isNot(throwsA(anything)),
          // container.read() for settled async providers returns AsyncValue, never throws.
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Phase 29: family calendar D-06
  // ---------------------------------------------------------------------------
  // All tests in this group are RED until state_calendar_totals.dart is
  // updated in Plan 02/03 to fan-out getDailyTotals over all book IDs.
  // ---------------------------------------------------------------------------

  group('Phase 29: family calendar D-06', () {
    test(
      'FAM-01/D-06: group mode sums own + shadow book daily totals',
      () async {
        final mockRepo = _MockAnalyticsRepository();

        // Own book: 1000 on May 15
        when(
          () => mockRepo.getDailyTotals(
            bookId: 'book1',
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 1000),
          ],
        );

        // Shadow book: 500 on the same day
        when(
          () => mockRepo.getDailyTotals(
            bookId: 'shadow-1',
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 500),
          ],
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = _makeContainer(
          mockRepo,
          isGroupMode: true,
          shadows: shadows,
        );

        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasValue, isTrue);
        final map = result.requireValue;

        // RED: provider currently only calls getDailyTotals for own book;
        // after Plan 02 it will sum own (1000) + shadow (500) = 1500
        expect(
          map[DateTime(2026, 5, 15)],
          equals(1500),
          reason:
              'FAM-01/D-06: group mode must sum own + shadow book daily totals',
        );
      },
    );

    test(
      'D-04: solo mode uses own book only',
      () async {
        final mockRepo = _MockAnalyticsRepository();

        when(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 1000),
          ],
        );

        // Solo mode — no shadow books
        final container = _makeContainer(
          mockRepo,
          isGroupMode: false,
        );

        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasValue, isTrue);
        final map = result.requireValue;

        // Solo mode: only own book is queried; total should be exactly 1000
        expect(
          map[DateTime(2026, 5, 15)],
          equals(1000),
          reason: 'D-04: solo mode uses own book only, total = 1000',
        );

        // Verify getDailyTotals was called exactly once (own book only)
        verify(
          () => mockRepo.getDailyTotals(
            bookId: any(named: 'bookId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);
      },
    );

    test(
      'Pitfall 3/D-06: calendar is isolated from memberBookId filter — '
      'result equals group-merged value regardless of member filter',
      () async {
        final mockRepo = _MockAnalyticsRepository();

        // Own book: 1000; shadow: 500 — merged should be 1500
        when(
          () => mockRepo.getDailyTotals(
            bookId: 'book1',
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 1000),
          ],
        );
        when(
          () => mockRepo.getDailyTotals(
            bookId: 'shadow-1',
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer(
          (_) async => [
            DailyTotal(date: DateTime(2026, 5, 15), totalAmount: 500),
          ],
        );

        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        // CRITICAL: override listFilterProvider with memberBookId != null
        // The calendar provider must NOT watch listFilterProvider (Pitfall 3).
        // If it did, it would narrow to only shadow-1 and show 500, not 1500.
        final container = _makeContainer(
          mockRepo,
          isGroupMode: true,
          shadows: shadows,
          filterState: const ListFilterState(
            selectedYear: 2026,
            selectedMonth: 5,
            memberBookId: 'shadow-1', // member filter active
          ),
        );

        final result = await waitForFirstValue<Map<DateTime, int>>(
          container,
          calendarDailyTotalsProvider(bookId: 'book1', year: 2026, month: 5),
        );

        expect(result.hasValue, isTrue);
        final map = result.requireValue;

        // RED until Plan 02 lands; currently only own book is queried so value
        // is 1000 (not 1500). After Plan 02: value must be 1500 regardless of
        // memberBookId filter (calendar is always fully-merged).
        expect(
          map[DateTime(2026, 5, 15)],
          equals(1500),
          reason:
              'Pitfall 3/D-06: calendar must show merged total (1500) '
              'even when memberBookId filter is active',
        );
      },
    );
  });
}
