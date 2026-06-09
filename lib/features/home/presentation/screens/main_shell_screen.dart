import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../accounting/presentation/screens/manual_one_step_screen.dart';
import '../../../analytics/presentation/providers/state_analytics.dart';
import '../../../analytics/presentation/providers/state_happiness.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../list/presentation/providers/state_calendar_totals.dart';
import '../../../list/presentation/providers/state_list_transactions.dart';
import '../../../list/presentation/screens/list_screen.dart';
import '../../../family_sync/domain/models/sync_status_model.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';
import '../../../family_sync/presentation/widgets/family_sync_notification_route_listener.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../shopping_list/presentation/providers/state_shopping_batch.dart';
import '../../../shopping_list/presentation/screens/shopping_item_form_screen.dart';
import '../../../shopping_list/presentation/screens/shopping_list_screen.dart';
import '../providers/state_home.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../widgets/home_bottom_nav_bar.dart';
import 'home_screen.dart';

/// Main navigation shell with custom bottom nav bar and FAB.
///
/// Uses [selectedTabIndexProvider] for tab state so it persists
/// across navigation events and can be accessed from anywhere.
class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabIndexProvider);

    // Refresh home data when sync completes (syncing → synced)
    ref.listen(syncStatusStreamProvider, (prev, next) {
      final prevState = prev?.value?.state;
      final currState = next.value?.state;
      if (currState == null) return;

      final wasSyncing =
          prevState == SyncState.syncing ||
          prevState == SyncState.initialSyncing;
      final nowDone =
          currState == SyncState.synced || currState == SyncState.idle;

      if (wasSyncing && nowDone) {
        final now = DateTime.now();
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final currentMonthEnd = DateTime(
          now.year,
          now.month + 1,
          0,
          23,
          59,
          59,
        );
        ref.invalidate(todayTransactionsProvider(bookId: bookId));
        ref.invalidate(
          monthlyReportProvider(
            bookId: bookId,
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ),
        );
        ref.invalidate(shadowBooksProvider);
        ref.invalidate(
          shadowAggregateProvider(
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ),
        );
        ref.invalidate(
          bestJoyMomentProvider(
            bookId: bookId,
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ),
        );
        final bookAsync = ref.read(bookByIdProvider(bookId: bookId));
        if (bookAsync.hasValue) {
          ref.invalidate(
            happinessReportProvider(
              bookId: bookId,
              startDate: currentMonthStart,
              endDate: currentMonthEnd,
              currencyCode: bookAsync.value?.currency ?? 'JPY',
            ),
          );
        }
        // D-03: forward-wiring; no visible effect this phase (ListScreen is loading-only)
        ref.invalidate(listTransactionsProvider(bookId: bookId));
        ref.invalidate(
          calendarDailyTotalsProvider(
            bookId: bookId,
            year: now.year,
            month: now.month,
          ),
        );
      }
    });

    final batchActive = ref.watch(batchSelectModeProvider).isActive;

    return FamilySyncNotificationRouteListener(
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: [
                HomeScreen(
                  bookId: bookId,
                  onSettingsTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(bookId: bookId),
                      ),
                    );
                  },
                ),
                ListScreen(bookId: bookId),
                AnalyticsScreen(bookId: bookId),
                const ShoppingListScreen(),
              ],
            ),
            if (!batchActive)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: HomeBottomNavBar(
                  currentIndex: currentIndex,
                  onTap: (index) =>
                      ref.read(selectedTabIndexProvider.notifier).select(index),
                  onFabTap: () async {
                    if (currentIndex == 3) {
                      // NAV-01: shopping tab → add-shopping-item screen.
                      // New items default to 'public' (G8Z2 FIX-2); the form
                      // exposes a public/private switch in every mode (private is
                      // opt-in). The view toggle value, which can be 'all', is
                      // not a storable list_type.
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const ShoppingItemFormScreen(
                            listType: 'public',
                          ),
                        ),
                      );
                      // Shopping items reactive via .watch() — NO invalidate needed here
                    } else {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ManualOneStepScreen(bookId: bookId),
                        ),
                      );
                      // Refresh data after returning from entry flow
                      final now = DateTime.now();
                      final currentMonthStart = DateTime(now.year, now.month, 1);
                      final currentMonthEnd = DateTime(
                        now.year,
                        now.month + 1,
                        0,
                        23,
                        59,
                        59,
                      );
                      ref.invalidate(
                        monthlyReportProvider(
                          bookId: bookId,
                          startDate: currentMonthStart,
                          endDate: currentMonthEnd,
                        ),
                      );
                      ref.invalidate(todayTransactionsProvider(bookId: bookId));
                      ref.invalidate(
                        bestJoyMomentProvider(
                          bookId: bookId,
                          startDate: currentMonthStart,
                          endDate: currentMonthEnd,
                        ),
                      );
                      final bookAsync = ref.read(bookByIdProvider(bookId: bookId));
                      if (bookAsync.hasValue) {
                        ref.invalidate(
                          happinessReportProvider(
                            bookId: bookId,
                            startDate: currentMonthStart,
                            endDate: currentMonthEnd,
                            currencyCode: bookAsync.value?.currency ?? 'JPY',
                          ),
                        );
                      }
                      // D-03: forward-wiring; no visible effect this phase (ListScreen is loading-only)
                      ref.invalidate(listTransactionsProvider(bookId: bookId));
                      ref.invalidate(
                        calendarDailyTotalsProvider(
                          bookId: bookId,
                          year: now.year,
                          month: now.month,
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
