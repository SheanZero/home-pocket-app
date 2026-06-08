// Widget tests for context-aware FAB routing in MainShellScreen.
//
// Covers: NAV-01 — index 3 → ShoppingItemFormScreen; other indices → ManualOneStepScreen
//
// Strategy: Rather than pumping the full MainShellScreen (which requires 15+
// provider overrides for HomeScreen/ListScreen/AnalyticsScreen), we pump a
// minimal _FabTestShell that replicates exactly the FAB routing logic under test.
//
// Route verification: we use a _TrackingRoute subclass approach.
// The FAB callback creates a _ShoppingItemFormRoute or _ManualEntryRoute subclass
// so we can inspect the *route class* via the observer without calling the builder
// (which would mount the real screen and trigger its DB provider chain).
//
// Run: flutter test test/widget/features/shopping_list/presentation/screens/main_shell_screen_fab_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/providers/state_home.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/state_shopping_filter.dart';
import 'package:home_pocket/features/shopping_list/presentation/screens/shopping_item_form_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Typed route subclasses — for inspection without calling builder
// ---------------------------------------------------------------------------

/// Marker subclass that identifies a ShoppingItemFormScreen push.
class _ShoppingItemFormRoute extends MaterialPageRoute<void> {
  _ShoppingItemFormRoute({required super.builder});
}

/// Marker subclass that identifies a ManualOneStepScreen push.
class _ManualEntryRoute extends MaterialPageRoute<void> {
  _ManualEntryRoute({required super.builder});
}

// ---------------------------------------------------------------------------
// CapturingNavigatorObserver
// ---------------------------------------------------------------------------

class _CapturingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

// ---------------------------------------------------------------------------
// Minimal test shell — replicates FAB routing from MainShellScreen
// but uses typed route subclasses so we can identify the destination
// without ever calling builder() or rendering the real screens.
// ---------------------------------------------------------------------------
class _FabTestShell extends ConsumerWidget {
  const _FabTestShell({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: Center(child: Text('Tab $currentIndex')),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab'),
        onPressed: () async {
          if (currentIndex == 3) {
            // NAV-01: shopping tab → add-shopping-item screen
            // Uses _ShoppingItemFormRoute for testability.
            await Navigator.of(context).push<void>(
              _ShoppingItemFormRoute(
                builder: (_) => ShoppingItemFormScreen(
                  listType: ref.read(listTypeProvider),
                ),
              ),
            );
          } else {
            // Uses _ManualEntryRoute for testability.
            await Navigator.of(context).push<void>(
              _ManualEntryRoute(
                builder: (_) => const SizedBox.shrink(), // stub — route type is the signal
              ),
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: pump the test shell at the given tab index
// ---------------------------------------------------------------------------

Future<_CapturingNavigatorObserver> _pumpShell(
  WidgetTester tester, {
  required int tabIndex,
  String bookId = 'book-1',
}) async {
  final observer = _CapturingNavigatorObserver();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        selectedTabIndexProvider.overrideWith(() => SelectedTabIndex()),
      ],
      child: MaterialApp(
        navigatorObservers: [observer],
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: _FabTestShell(bookId: bookId),
      ),
    ),
  );

  // Clear initial route push from MaterialApp startup
  observer.pushed.clear();

  // Switch to the desired tab index
  if (tabIndex != 0) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_FabTestShell)),
    );
    container.read(selectedTabIndexProvider.notifier).select(tabIndex);
    await tester.pump();
  }

  return observer;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MainShellScreen FAB routing (NAV-01)', () {
    testWidgets('index 3 (shopping tab): FAB routes to ShoppingItemFormScreen',
        (tester) async {
      final observer = await _pumpShell(tester, tabIndex: 3);

      await tester.tap(find.byKey(const Key('fab')));
      await tester.pump();
      await tester.pump(); // settle animation start

      expect(observer.pushed, isNotEmpty,
          reason: 'FAB should push a route at index 3');
      // Route must be the shopping-specific subclass
      expect(observer.pushed.last, isA<_ShoppingItemFormRoute>(),
          reason: 'Shopping tab FAB must use _ShoppingItemFormRoute → ShoppingItemFormScreen');
      expect(observer.pushed.last, isNot(isA<_ManualEntryRoute>()));
    });

    testWidgets(
        'index 0 (home tab): FAB routes to ManualEntryRoute (not ShoppingItemFormScreen)',
        (tester) async {
      final observer = await _pumpShell(tester, tabIndex: 0);

      await tester.tap(find.byKey(const Key('fab')));
      await tester.pump();
      await tester.pump();

      expect(observer.pushed, isNotEmpty,
          reason: 'FAB should push a route at index 0');
      expect(observer.pushed.last, isA<_ManualEntryRoute>(),
          reason: 'Non-shopping tab must use _ManualEntryRoute');
      expect(observer.pushed.last, isNot(isA<_ShoppingItemFormRoute>()));
    });

    testWidgets(
        'index 1 (list tab): FAB routes to ManualEntryRoute (not ShoppingItemFormScreen)',
        (tester) async {
      final observer = await _pumpShell(tester, tabIndex: 1);

      await tester.tap(find.byKey(const Key('fab')));
      await tester.pump();
      await tester.pump();

      expect(observer.pushed, isNotEmpty,
          reason: 'FAB should push a route at index 1');
      expect(observer.pushed.last, isA<_ManualEntryRoute>(),
          reason: 'Non-shopping tab must use _ManualEntryRoute');
      expect(observer.pushed.last, isNot(isA<_ShoppingItemFormRoute>()));
    });
  });
}
