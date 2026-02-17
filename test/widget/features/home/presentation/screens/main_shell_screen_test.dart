import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/providers/home_providers.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';

import '../../helpers/test_localizations.dart';

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
}
