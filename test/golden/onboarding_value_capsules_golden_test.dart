@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    final textFont = FontLoader('NotoSansCJK')
      ..addFont(
        File('/System/Library/Fonts/Hiragino Sans GB.ttc').readAsBytes().then(
          (bytes) => ByteData.sublistView(Uint8List.fromList(bytes)),
        ),
      );
    await textFont.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  testWidgets('warm onboarding value capsules — dark zh', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        theme: AppTheme.light.copyWith(
          textTheme: AppTheme.light.textTheme.apply(fontFamily: 'NotoSansCJK'),
        ),
        darkTheme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'NotoSansCJK'),
        ),
        themeMode: ThemeMode.dark,
        home: OnboardingIntroScreen(onContinue: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/onboarding_value_capsules_dark_zh.png'),
    );
  });
}
