import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accounting/presentation/screens/transaction_entry_screen.dart';
import '../../../analytics/presentation/providers/analytics_providers.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../family_sync/domain/models/sync_status_model.dart';
import '../../../family_sync/presentation/providers/sync_providers.dart';
import '../../../family_sync/presentation/widgets/family_sync_notification_route_listener.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../providers/home_providers.dart';
import '../providers/shadow_books_provider.dart';
import '../providers/today_transactions_provider.dart';
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
      final prevState = prev?.valueOrNull?.state;
      final currState = next.valueOrNull?.state;
      if (currState == null) return;

      final wasSyncing = prevState == SyncState.syncing ||
          prevState == SyncState.initialSyncing;
      final nowDone =
          currState == SyncState.synced || currState == SyncState.idle;

      if (wasSyncing && nowDone) {
        final now = DateTime.now();
        ref.invalidate(todayTransactionsProvider(bookId: bookId));
        ref.invalidate(monthlyReportProvider(
          bookId: bookId,
          year: now.year,
          month: now.month,
        ));
        ref.invalidate(shadowBooksProvider);
        ref.invalidate(
          shadowAggregateProvider(year: now.year, month: now.month),
        );
      }
    });

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
                // Placeholder for List tab
                const Center(child: Text('List')),
                AnalyticsScreen(bookId: bookId),
                // Placeholder for Todo tab
                const Center(child: Text('Todo')),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: HomeBottomNavBar(
                currentIndex: currentIndex,
                onTap: (index) =>
                    ref.read(selectedTabIndexProvider.notifier).select(index),
                onFabTap: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => TransactionEntryScreen(bookId: bookId),
                    ),
                  );
                  // Refresh data after returning from entry flow
                  final now = DateTime.now();
                  ref.invalidate(
                    monthlyReportProvider(
                      bookId: bookId,
                      year: now.year,
                      month: now.month,
                    ),
                  );
                  ref.invalidate(todayTransactionsProvider(bookId: bookId));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
