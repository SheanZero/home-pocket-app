import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounting/presentation/providers/repository_providers.dart';
import '../../../accounting/presentation/screens/manual_one_step_screen.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../analytics/presentation/providers/state_transaction_aggregate_refresh.dart';
import '../../../analytics/presentation/providers/state_primary_tab.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../analytics/presentation/widgets/analytics_primary_tabs.dart';
import '../../../list/presentation/providers/state_calendar_totals.dart';
import '../../../list/presentation/providers/state_list_transactions.dart';
import '../../../list/presentation/screens/list_screen.dart';
import '../../../family_sync/domain/models/sync_status_model.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';
import '../../../family_sync/presentation/widgets/family_sync_notification_route_listener.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../shopping_list/presentation/screens/shopping_item_form_screen.dart';
import '../../../shopping_list/presentation/screens/shopping_list_screen.dart';
import '../../../../shared/widgets/lazy_indexed_stack.dart';
import '../../../../core/config/release_features.dart';
import '../providers/state_home.dart';
import '../providers/state_shadow_books.dart';
import '../providers/state_today_transactions.dart';
import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_joy_prompt.dart';
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
        invalidateTransactionAggregates(ref);
        ref.invalidate(shadowBooksProvider);
        ref.invalidate(
          shadowAggregateProvider(
            startDate: currentMonthStart,
            endDate: currentMonthEnd,
          ),
        );
        // D-03: forward-wiring; no visible effect this phase (ListScreen is loading-only)
        // P2-1: the list's SQL lives in the base; the search layer cascades.
        ref.invalidate(listTransactionsBaseProvider(bookId: bookId));
        ref.invalidate(
          calendarDailyTotalsProvider(
            bookId: bookId,
            year: now.year,
            month: now.month,
          ),
        );
      }
    });

    // 260614-iww: open the manual add-entry screen, threading [continuousMode]
    // from the FAB gesture (tap → false / long-press → true). The post-pop
    // invalidate block is preserved verbatim so home data refreshes after the
    // entry flow returns.
    Future<void> openAddEntry({
      required bool continuousMode,
      HomeJoyPrompt? joyPrompt,
    }) async {
      Category? initialCategory;
      Category? initialParentCategory;
      if (joyPrompt != null) {
        final categoryId = switch (joyPrompt) {
          HomeJoyPrompt.custom => 'cat_hobbies_other',
          HomeJoyPrompt.coffee => 'cat_food_cafe',
          HomeJoyPrompt.book => 'cat_education_books',
          HomeJoyPrompt.rest => 'cat_hobbies_leisure',
        };
        final categoryRepository = ref.read(categoryRepositoryProvider);
        initialCategory = await categoryRepository.findById(categoryId);
        final parentId = initialCategory?.parentId;
        if (parentId != null) {
          initialParentCategory = await categoryRepository.findById(parentId);
        }
        if (!context.mounted) return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ManualOneStepScreen(
            bookId: bookId,
            continuousMode: continuousMode,
            initialCategory: initialCategory,
            initialParentCategory: initialParentCategory,
            initialLedgerType: joyPrompt == null ? null : LedgerType.joy,
            onHistoryTap: () {
              ref.read(selectedTabIndexProvider.notifier).select(1);
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      // Refresh data after returning from entry flow
      final now = DateTime.now();
      invalidateTransactionAggregates(ref);
      ref.invalidate(todayTransactionsProvider(bookId: bookId));
      // D-03: forward-wiring; no visible effect this phase (ListScreen is loading-only)
      // P2-1: the list's SQL lives in the base; the search layer cascades.
      ref.invalidate(listTransactionsBaseProvider(bookId: bookId));
      ref.invalidate(
        calendarDailyTotalsProvider(
          bookId: bookId,
          year: now.year,
          month: now.month,
        ),
      );
    }

    void openAnalytics(AnalyticsPrimaryTab tab) {
      ref.read(selectedAnalyticsPrimaryTabProvider.notifier).select(tab);
      ref.read(selectedTabIndexProvider.notifier).select(2);
    }

    final shell = Scaffold(
      // Onboarding can hand off while the iOS keyboard dismissal animation
      // still reports a non-zero viewInset. The shell itself has no text
      // input, so resizing here only lifts the floating tab bar/FAB into the
      // middle of the first home frame. Input routes manage their own insets.
      resizeToAvoidBottomInset: false,
      body: Stack(
        key: const ValueKey('main-shell-body-stack'),
        fit: StackFit.expand,
        children: [
          LazyIndexedStack(
            index: currentIndex,
            itemCount: 4,
            cacheKey: bookId,
            itemBuilder: (context, index) => switch (index) {
              0 => HomeScreen(
                bookId: bookId,
                onAddJoyTap: (prompt) =>
                    openAddEntry(continuousMode: false, joyPrompt: prompt),
                onJoyAnalyticsTap: () => openAnalytics(AnalyticsPrimaryTab.joy),
                onSettingsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(bookId: bookId),
                    ),
                  );
                },
              ),
              1 => ListScreen(bookId: bookId),
              2 => AnalyticsScreen(bookId: bookId),
              3 => ShoppingListScreen(
                onSettingsTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(bookId: bookId),
                    ),
                  );
                },
              ),
              _ => throw RangeError.index(index, const <Never>[]),
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index == 0 || index == 2) {
                  invalidateTransactionAggregates(ref);
                }
                if (index == 2) {
                  openAnalytics(AnalyticsPrimaryTab.spending);
                  return;
                }
                ref.read(selectedTabIndexProvider.notifier).select(index);
              },
              onFabTap: () async {
                if (currentIndex == 3) {
                  // NAV-01: shopping tab → add-shopping-item screen.
                  // New items default to 'public' (G8Z2 FIX-2); the form
                  // exposes a public/private switch in every mode (private is
                  // opt-in). The view toggle value, which can be 'all', is
                  // not a storable list_type.
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const ShoppingItemFormScreen(listType: 'public'),
                    ),
                  );
                  // Shopping items reactive via .watch() — NO invalidate needed here
                } else {
                  // 260614-iww: single tap → non-continuous add entry.
                  await openAddEntry(continuousMode: false);
                }
              },
              // 260614-iww: long-press → continuous add entry. Gated to the
              // accounting path only; on the shopping tab it is a no-op so
              // the FAB behaves normally there.
              onFabLongPress: currentIndex == 3
                  ? null
                  : () => openAddEntry(continuousMode: true),
            ),
          ),
        ],
      ),
    );
    return ReleaseFeatures.pushNotifications
        ? FamilySyncNotificationRouteListener(child: shell)
        : shell;
  }
}
