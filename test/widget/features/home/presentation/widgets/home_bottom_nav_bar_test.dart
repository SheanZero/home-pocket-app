import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';

import '../../helpers/test_localizations.dart';

void main() {
  group('HomeBottomNavBar', () {
    testWidgets('displays 4 tab labels', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      // ja locale labels
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('一覧'), findsOneWidget);
      expect(find.text('チャート'), findsOneWidget);
      expect(find.text('やること'), findsOneWidget);
    });

    testWidgets('active tab uses survival color', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('ホーム'));
      expect(text.style?.color, AppColors.survival);
    });

    testWidgets('inactive tab uses inactive color', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('一覧'));
      expect(text.style?.color, AppColors.inactiveTab);
    });

    testWidgets('FAB calls onFabTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.edit));
      expect(tapped, isTrue);
    });

    testWidgets('onTap returns correct index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (i) => tappedIndex = i,
              onFabTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('一覧'));
      expect(tappedIndex, 1);
    });
  });
}
