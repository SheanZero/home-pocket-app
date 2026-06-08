import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';

import '../../../../../widget/features/home/helpers/test_localizations.dart';

void main() {
  group('HomeBottomNavBar — shopping list tab (NAV-02)', () {
    testWidgets('4th tab shows 買い物リスト in Japanese locale', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          locale: const Locale('ja'),
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('買い物リスト'), findsOneWidget);
      expect(find.text('やること'), findsNothing);
    });

    testWidgets('4th tab shows 购物清单 in Chinese locale', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          locale: const Locale('zh'),
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('购物清单'), findsOneWidget);
      expect(find.text('待办事项'), findsNothing);
    });

    testWidgets('4th tab shows Shopping List in English locale', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          locale: const Locale('en'),
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 0,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Shopping List'), findsOneWidget);
      expect(find.text('Todo'), findsNothing);
    });

    testWidgets('4th tab shows shopping_bag_outlined icon when inactive',
        (tester) async {
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

      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('4th tab shows shopping_bag icon when active', (tester) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: Scaffold(
            bottomNavigationBar: HomeBottomNavBar(
              currentIndex: 3,
              onTap: (_) {},
              onFabTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
    });
  });
}
