import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/entry_mode_switcher.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/input_mode_tabs.dart';

import '../../../home/helpers/test_localizations.dart';

void main() {
  group('EntryModeSwitcher', () {
    // 260614-iww: the OCR/scan tab is reversibly hidden behind kOcrEntryEnabled
    // (currently false). The tab is no longer rendered, so its icon is absent
    // and there is no OCR entry point in the switcher. Flipping the flag to true
    // restores the tab (and this assertion would invert).
    testWidgets('OCR tab is hidden while kOcrEntryEnabled is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: testLocalizedApp(
            child: const Scaffold(
              body: EntryModeSwitcher(
                selectedMode: InputMode.manual,
                bookId: 'book_test',
              ),
            ),
          ),
        ),
      );

      expect(
        find.byIcon(Icons.document_scanner_outlined),
        findsNothing,
        reason: 'OCR tab is hidden behind kOcrEntryEnabled=false',
      );
      // Manual + voice tabs remain present.
      expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.mic_outlined), findsOneWidget);
    });

    testWidgets('navigates to Voice screen when Voice tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: testLocalizedApp(
            child: const Scaffold(
              body: EntryModeSwitcher(
                selectedMode: InputMode.manual,
                bookId: 'book_test',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(VoiceInputScreen), findsOneWidget);
    });
  });
}
