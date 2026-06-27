import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_analytics.dart';
import 'package:home_pocket/features/home/presentation/providers/state_today_transactions.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/shared/utils/invalidate_all_data_providers.dart';

void main() {
  group('invalidateAllDataProviders', () {
    testWidgets(
      're-executes a representative provider from each data group',
      (tester) async {
        var todayBuilds = 0; // home/list group
        var analyticsBuilds = 0; // analytics group
        var settingsBuilds = 0; // settings group

        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              todayTransactionsProvider(bookId: 'book-1').overrideWith((
                ref,
              ) async {
                todayBuilds++;
                return <Transaction>[];
              }),
              analyticsCategoriesMapProvider.overrideWith((ref) async {
                analyticsBuilds++;
                return <String, Category>{};
              }),
              appSettingsProvider.overrideWith((ref) async {
                settingsBuilds++;
                return const AppSettings();
              }),
            ],
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                ref.watch(todayTransactionsProvider(bookId: 'book-1'));
                ref.watch(analyticsCategoriesMapProvider);
                ref.watch(appSettingsProvider);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Each representative provider built once and is now cached.
        expect(todayBuilds, 1);
        expect(analyticsBuilds, 1);
        expect(settingsBuilds, 1);

        // Whole-family invalidation should discard every cached instance, so
        // the watching Consumer re-reads and each provider re-executes.
        invalidateAllDataProviders(capturedRef);
        await tester.pumpAndSettle();

        expect(todayBuilds, 2, reason: 'home/list family must re-execute');
        expect(analyticsBuilds, 2, reason: 'analytics family must re-execute');
        expect(settingsBuilds, 2, reason: 'settings family must re-execute');
      },
    );
  });
}
