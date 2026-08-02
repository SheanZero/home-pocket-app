@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/shared/widgets/feedback_toast.dart';

void main() {
  setUpAll(() async {
    final cjkBytes = await File(
      '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
    ).readAsBytes();
    await Future.wait([
      (FontLoader(
        'GoldenCjk',
      )..addFont(Future.value(ByteData.sublistView(cjkBytes)))).load(),
      (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    ]);
  });

  testWidgets('compact success status pill dark zh', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late BuildContext hostContext;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'GoldenCjk'),
          primaryTextTheme: AppTheme.dark.primaryTextTheme.apply(
            fontFamily: 'GoldenCjk',
          ),
        ),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          key: const Key('feedback-toast-golden-surface'),
          body: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    showSuccessFeedback(hostContext, '邀请码已重新生成');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(Overlay),
      matchesGoldenFile('goldens/feedback_toast_status_pill_dark_zh.png'),
    );

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
