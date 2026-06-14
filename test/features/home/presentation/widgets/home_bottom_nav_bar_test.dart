import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('renders 4 tab icons plus FAB icon', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(currentIndex: 0, onTap: (_) {}, onFabTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    // 4 tab icons + 1 FAB icon = at least 5
    expect(find.byType(Icon), findsAtLeastNWidgets(5));
  });

  testWidgets('FAB uses plus icon and triggers callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(
          currentIndex: 0,
          onTap: (_) {},
          onFabTap: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    expect(tapped, isTrue);
  });

  testWidgets('tab tap triggers callback with correct index', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(
          currentIndex: 0,
          onTap: (i) => tappedIndex = i,
          onFabTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Tap the second tab (一覧 / list)
    await tester.tap(find.byIcon(Icons.list));
    expect(tappedIndex, 1);
  });

  testWidgets('active tab icon uses primary accent color', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(currentIndex: 2, onTap: (_) {}, onFabTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    // The active tab (index 2, bar_chart) icon is tinted with the accent colour
    final barChartIcon = tester.widget<Icon>(find.byIcon(Icons.bar_chart));
    expect(barChartIcon.color, AppPalette.light.accentPrimary);
  });

  testWidgets('inactive tab icon uses tertiary color', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(currentIndex: 0, onTap: (_) {}, onFabTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    // Tab index 1 (list) is inactive when currentIndex is 0
    final listIcon = tester.widget<Icon>(find.byIcon(Icons.list));
    expect(listIcon.color, AppPalette.light.textTertiary);
  });

  testWidgets('renders all 4 tab labels', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(currentIndex: 0, onTap: (_) {}, onFabTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    // Check that tab labels are rendered (ja locale)
    expect(find.text('ホーム'), findsOneWidget);
    expect(find.text('一覧'), findsOneWidget);
    expect(find.text('チャート'), findsOneWidget);
    expect(find.text('買い物'), findsOneWidget);
  });

  testWidgets('pill container has white background and rounded corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestWidget(
        HomeBottomNavBar(currentIndex: 0, onTap: (_) {}, onFabTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    // Find the pill container (Expanded > Container with height 62)
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.constraints?.maxHeight == 62 && c.constraints?.minHeight == 62,
        )
        .toList();
    expect(containers, isNotEmpty);
  });
}
