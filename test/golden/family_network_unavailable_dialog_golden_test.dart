@Tags(['golden'])
library;

// Visual contract for the friendly family-network error dialog selected from
// the 2026-08-02 mockup exploration.
//
// Run:    flutter test test/golden/family_network_unavailable_dialog_golden_test.dart
// Update: flutter test test/golden/family_network_unavailable_dialog_golden_test.dart --update-goldens

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_network_unavailable_dialog.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('zh'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            key: const Key('open-family-network-dialog'),
            onPressed: () => showFamilyNetworkUnavailableDialog(context),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    final cjkBytes = await File(
      '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    ).readAsBytes();
    await Future.wait([
      (FontLoader(
        'RobotoMonoNumerals',
      )..addFont(Future.value(ByteData.sublistView(cjkBytes)))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
  });

  testWidgets('dark zh', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap());
    await tester.tap(find.byKey(const Key('open-family-network-dialog')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('family-network-unavailable-dialog')),
      matchesGoldenFile(
        'goldens/family_network_unavailable_dialog_dark_zh.png',
      ),
    );
  });
}
