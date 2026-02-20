import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/ocr_scanner_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/entry_mode_switcher.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/input_mode_tabs.dart';

import '../../../home/helpers/test_localizations.dart';

void main() {
  group('EntryModeSwitcher', () {
    testWidgets('navigates to OCR screen when OCR tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: EntryModeSwitcher(
              selectedMode: InputMode.manual,
              bookId: 'book_test',
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.document_scanner_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byType(OcrScannerScreen), findsOneWidget);
    });

    testWidgets('navigates to Voice screen when Voice tab is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        testLocalizedApp(
          child: const Scaffold(
            body: EntryModeSwitcher(
              selectedMode: InputMode.manual,
              bookId: 'book_test',
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
