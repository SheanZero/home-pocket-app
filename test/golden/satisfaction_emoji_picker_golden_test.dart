@Tags(['golden'])
library;

// Golden tests for SatisfactionEmojiPicker — the cat satisfaction face set
// (assets/satisfaction/sat_01..05.svg), light + dark, with the top level selected.
//
// Baselines: test/golden/goldens/satisfaction_emoji_picker_{light,dark}.png
// Run with: flutter test test/golden/satisfaction_emoji_picker_golden_test.dart
// Update:   flutter test test/golden/satisfaction_emoji_picker_golden_test.dart --update-goldens

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart';

Widget _wrap({required ThemeMode themeMode}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SatisfactionEmojiPicker(
              value: 10,
              onChanged: (_) {},
              title: '満足度',
              levelLabels: const ['無難', '快適', '順調', '満足', '至福'],
              bottomLabels: const ['無難', '順調', '至福！'],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SatisfactionEmojiPicker golden', () {
    testWidgets('light', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SatisfactionEmojiPicker),
        matchesGoldenFile('goldens/satisfaction_emoji_picker_light.png'),
      );
    });

    testWidgets('dark', (tester) async {
      await tester.pumpWidget(_wrap(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SatisfactionEmojiPicker),
        matchesGoldenFile('goldens/satisfaction_emoji_picker_dark.png'),
      );
    });
  });
}
