@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../helpers/load_numeral_font.dart';

void main() {
  setUpAll(loadNumeralFont);

  Future<void> pumpNav(WidgetTester tester, {required ThemeData theme}) async {
    tester.view.physicalSize = const Size(390, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: theme,
        home: Scaffold(
          bottomNavigationBar: HomeBottomNavBar(
            currentIndex: 1,
            onTap: (_) {},
            onFabTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('active bottom navigation indicator — light zh', (tester) async {
    await pumpNav(tester, theme: AppTheme.light);

    await expectLater(
      find.byType(HomeBottomNavBar),
      matchesGoldenFile('goldens/home_bottom_nav_active_light_zh.png'),
    );
  });

  testWidgets('active bottom navigation indicator — dark zh', (tester) async {
    await pumpNav(tester, theme: AppTheme.dark);

    await expectLater(
      find.byType(HomeBottomNavBar),
      matchesGoldenFile('goldens/home_bottom_nav_active_dark_zh.png'),
    );
  });
}
