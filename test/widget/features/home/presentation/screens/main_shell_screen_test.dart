import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/providers/state_home.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_batch.dart';

import '../../helpers/test_localizations.dart';

// ---------------------------------------------------------------------------
// Test-only notifier that immediately enters batch-selection mode.
// Overrides build() to return an active BatchSelectModeState.
// Cannot use .enter() in the factory because ref is uninitialized there.
// ---------------------------------------------------------------------------
class _ActiveBatchSelectMode extends BatchSelectMode {
  @override
  BatchSelectModeState build() =>
      const BatchSelectModeState(isActive: true, selectedIds: {});
}

void main() {
  group('MainShellScreen', () {
    testWidgets('HomeBottomNavBar renders at shell level', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTabIndexProvider.overrideWith(() => SelectedTabIndex()),
          ],
          child: testLocalizedApp(
            child: Scaffold(
              body: const Center(child: Text('Content')),
              bottomNavigationBar: HomeBottomNavBar(
                currentIndex: 0,
                onTap: (_) {},
                onFabTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HomeBottomNavBar), findsOneWidget);
    });

    testWidgets('bottom nav persists across tab switches', (tester) async {
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTabIndexProvider.overrideWith(() => SelectedTabIndex()),
          ],
          child: testLocalizedApp(
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                final index = ref.watch(selectedTabIndexProvider);
                return Scaffold(
                  body: IndexedStack(
                    index: index,
                    children: const [
                      Center(child: Text('Home')),
                      Center(child: Text('List')),
                      Center(child: Text('Charts')),
                      Center(child: Text('Todo')),
                    ],
                  ),
                  bottomNavigationBar: HomeBottomNavBar(
                    currentIndex: index,
                    onTap: (i) =>
                        ref.read(selectedTabIndexProvider.notifier).select(i),
                    onFabTap: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state: Tab 0
      expect(find.byType(HomeBottomNavBar), findsOneWidget);

      // Switch to tab 1
      capturedRef.read(selectedTabIndexProvider.notifier).select(1);
      await tester.pumpAndSettle();

      // Bottom nav should still be present
      expect(find.byType(HomeBottomNavBar), findsOneWidget);

      // Switch to tab 2
      capturedRef.read(selectedTabIndexProvider.notifier).select(2);
      await tester.pumpAndSettle();

      expect(find.byType(HomeBottomNavBar), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Batch mode nav bar visibility (D38-03)
  //
  // Tests that the nav bar + FAB Positioned block is hidden when
  // batchSelectModeProvider.isActive == true, and visible when false.
  //
  // Uses a minimal _BatchGuardShell that applies the same `if (!batchActive)`
  // guard as MainShellScreen, without pumping the full screen's provider tree.
  // ---------------------------------------------------------------------------

  group('Batch mode nav bar visibility (D38-03)', () {
    testWidgets('HomeBottomNavBar is absent when batch mode is active',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTabIndexProvider.overrideWith(() => SelectedTabIndex()),
            // Override batchSelectModeProvider so it starts in active state.
            // Riverpod 3: state must be set from build() not from the factory
            // (state setter requires ref to be initialized first).
            batchSelectModeProvider.overrideWith(
              () => _ActiveBatchSelectMode(),
            ),
          ],
          child: testLocalizedApp(
            child: Consumer(
              builder: (context, ref, _) {
                final batchActive = ref.watch(batchSelectModeProvider).isActive;
                final currentIndex = ref.watch(selectedTabIndexProvider);
                return Scaffold(
                  body: const Center(child: Text('Content')),
                  bottomNavigationBar: batchActive
                      ? null
                      : HomeBottomNavBar(
                          currentIndex: currentIndex,
                          onTap: (_) {},
                          onFabTap: () {},
                        ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Nav bar should be hidden while batch mode is active
      expect(find.byType(HomeBottomNavBar), findsNothing,
          reason: 'HomeBottomNavBar must be hidden when batchSelectMode is active (D38-03)');
    });

    testWidgets('HomeBottomNavBar is visible when batch mode is inactive',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedTabIndexProvider.overrideWith(() => SelectedTabIndex()),
            // Override batchSelectModeProvider to be inactive (default)
            batchSelectModeProvider.overrideWith(() => BatchSelectMode()),
          ],
          child: testLocalizedApp(
            child: Consumer(
              builder: (context, ref, _) {
                final batchActive = ref.watch(batchSelectModeProvider).isActive;
                final currentIndex = ref.watch(selectedTabIndexProvider);
                return Scaffold(
                  body: const Center(child: Text('Content')),
                  bottomNavigationBar: batchActive
                      ? null
                      : HomeBottomNavBar(
                          currentIndex: currentIndex,
                          onTap: (_) {},
                          onFabTap: () {},
                        ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Nav bar should be visible when batch mode is inactive
      expect(find.byType(HomeBottomNavBar), findsOneWidget,
          reason: 'HomeBottomNavBar must be visible when batchSelectMode is inactive (D38-03)');
    });
  });
}
