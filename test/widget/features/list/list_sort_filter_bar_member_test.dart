// Widget tests for ListSortFilterBar family member chips (FAM-03/FAM-04).
//
// Wave 0 scaffold: tests compile cleanly but fail on behavioral assertions
// because the family segment (Mine-only + member chips) is not yet added to
// list_sort_filter_bar.dart. RED is the expected outcome for Phase 29
// behavioral assertions. Tests for solo mode (isGroupMode=false) are GREEN
// even before implementation (widget simply does not render the chips).
//
// Run: flutter test test/widget/features/list/list_sort_filter_bar_member_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/home/presentation/providers/state_shadow_books.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_sort_filter_bar.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_locale.dart'
    as locale_providers;
import 'package:home_pocket/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a minimal Book fixture for shadow-book stubs.
Book _stubBook(String id) => Book(
      id: id,
      name: 'Shadow $id',
      currency: 'JPY',
      deviceId: 'device-$id',
      createdAt: DateTime(2026, 1, 1),
      isShadow: true,
    );

/// Fixed filter override — injects a known ListFilterState synchronously.
/// Copied from list_transactions_provider_test.dart lines 67–73.
class _FixedListFilter extends ListFilter {
  _FixedListFilter(this._fixed);
  final ListFilterState _fixed;

  @override
  ListFilterState build() => _fixed;
}

/// Pumps a ListSortFilterBar with the given group mode and shadow books.
///
/// Analog: _pumpBar from list_sort_filter_bar_test.dart, extended with
/// isGroupModeProvider and shadowBooksProvider overrides.
Future<ProviderContainer> _pumpBar(
  WidgetTester tester, {
  required bool isGroupMode,
  List<ShadowBookInfo> shadows = const [],
  ListFilterState? filterState,
}) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locale_providers.currentLocaleProvider
            .overrideWith((_) async => const Locale('ja')),
        isGroupModeProvider.overrideWithValue(isGroupMode),
        shadowBooksProvider.overrideWith((_) async => shadows),
        if (filterState != null)
          listFilterProvider.overrideWith(
            () => _FixedListFilter(filterState),
          ),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(
              body: ListSortFilterBar(bookId: 'book1'),
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('ListSortFilterBar — family member chips (FAM-03/FAM-04)', () {
    testWidgets(
      'FAM-04/SC#5: Mine-only chip always visible in group mode',
      (tester) async {
        await _pumpBar(tester, isGroupMode: true);

        // RED until Mine-only chip is added in list_sort_filter_bar.dart (Plan 03)
        expect(find.text('自分のみ'), findsOneWidget);
      },
    );

    testWidgets(
      'FAM-04/D-04: Mine-only chip absent in solo mode (isGroupMode=false)',
      (tester) async {
        await _pumpBar(tester, isGroupMode: false);

        // In solo mode, the family segment must not appear.
        expect(find.text('自分のみ'), findsNothing);
      },
    );

    testWidgets(
      'FAM-02: member chip renders per shadowBooksProvider (one chip per shadow member)',
      (tester) async {
        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        await _pumpBar(tester, isGroupMode: true, shadows: shadows);

        // RED until member chips are added in list_sort_filter_bar.dart (Plan 03)
        expect(find.text('🐻 太郎'), findsOneWidget);
      },
    );

    testWidgets(
      'FAM-03: tapping member chip calls setMemberFilter(shadowBookId)',
      (tester) async {
        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        final container = await _pumpBar(
          tester,
          isGroupMode: true,
          shadows: shadows,
        );

        // RED: chip not present yet; tap will fail before list_sort_filter_bar.dart is updated
        await tester.tap(find.text('🐻 太郎'));
        await tester.pumpAndSettle();

        expect(
          container.read(listFilterProvider).memberBookId,
          equals('shadow-1'),
          reason: 'FAM-03: tapping shadow member chip sets memberBookId',
        );
      },
    );

    testWidgets(
      'FAM-04: tapping Mine-only chip calls setMemberFilter(ownBookId)',
      (tester) async {
        final container = await _pumpBar(
          tester,
          isGroupMode: true,
        );

        // RED: chip not present yet
        await tester.tap(find.text('自分のみ'));
        await tester.pumpAndSettle();

        // The bar is constructed with bookId: 'book1' — Mine-only uses the own bookId
        expect(
          container.read(listFilterProvider).memberBookId,
          equals('book1'),
          reason: 'FAM-04: tapping Mine-only sets memberBookId == own bookId',
        );
      },
    );

    testWidgets(
      'FAM-03/Pitfall B: anyFilterActive includes memberBookId — Clear chip visible when member filter active',
      (tester) async {
        // Inject a filter state that has memberBookId set
        final filterWithMember = const ListFilterState(
          selectedYear: 2026,
          selectedMonth: 5,
          memberBookId: 'shadow-1',
        );

        await _pumpBar(
          tester,
          isGroupMode: true,
          filterState: filterWithMember,
        );

        // Clear affordance is now icon-only (quick 260714-qit): assert on the
        // filter_alt_off icon rather than the removed 'クリア' label.
        expect(
          find.byIcon(Icons.filter_alt_off),
          findsOneWidget,
          reason:
              'FAM-03/Pitfall B: memberBookId != null → anyFilterActive == true → Clear chip visible',
        );
      },
    );

    testWidgets(
      'FAM-02/D-04: member chips absent in solo mode',
      (tester) async {
        final shadows = [
          ShadowBookInfo(
            book: _stubBook('shadow-1'),
            memberDisplayName: '太郎',
            memberAvatarEmoji: '🐻',
          ),
        ];

        // Solo mode — even if we pass shadows, isGroupMode=false means no chips
        await _pumpBar(tester, isGroupMode: false, shadows: shadows);

        expect(find.text('🐻 太郎'), findsNothing);
        expect(find.text('自分のみ'), findsNothing);
      },
    );
  });
}
