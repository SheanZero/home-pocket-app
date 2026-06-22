// Widget test for VoiceListeningModal (quick task 260622-nhs R2 — auto-fill
// modal: tap-anywhere exit + reset-restore, no 完成 / no 取消 buttons).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_listening_overlay.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_waveform.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets(
    'renders transcript, listening title, tap-exit hint, waveform, line mic, reset button',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: Stack(
              children: [
                VoiceListeningModal(
                  transcript: '拿铁 一千二百八',
                  soundLevel: 0.6,
                  onExit: () {},
                  onReset: () {},
                ),
              ],
            ),
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pump();

      final l10n = S.of(tester.element(find.byType(VoiceListeningModal)));

      expect(find.text('拿铁 一千二百八'), findsOneWidget);
      expect(find.text(l10n.listeningTitle), findsOneWidget);
      expect(find.text(l10n.voiceTapToExit), findsOneWidget);
      expect(find.text(l10n.voiceResetRestore), findsOneWidget);
      expect(find.byType(VoiceWaveform), findsOneWidget);
      // Line-style mics (modal mic + reset restore icon are line-style).
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    },
  );

  testWidgets('tapping the modal body fires onExit (not onReset)',
      (tester) async {
    var exits = 0;
    var resets = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Stack(
            children: [
              VoiceListeningModal(
                transcript: 'x',
                soundLevel: 0.1,
                onExit: () => exits++,
                onReset: () => resets++,
              ),
            ],
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    // Tap the listening title region (inside the modal body, away from reset).
    final l10n = S.of(tester.element(find.byType(VoiceListeningModal)));
    await tester.tap(find.text(l10n.listeningTitle));
    await tester.pump();

    expect(exits, 1, reason: 'tapping the modal body exits');
    expect(resets, 0);
  });

  testWidgets('tapping the reset button fires onReset and NOT onExit',
      (tester) async {
    var exits = 0;
    var resets = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Stack(
            children: [
              VoiceListeningModal(
                transcript: 'x',
                soundLevel: 0.1,
                onExit: () => exits++,
                onReset: () => resets++,
              ),
            ],
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    final l10n = S.of(tester.element(find.byType(VoiceListeningModal)));
    await tester.tap(find.text(l10n.voiceResetRestore));
    await tester.pump();

    expect(resets, 1, reason: 'reset button restores the form');
    expect(exits, 0, reason: 'reset tap must NOT bubble to the exit handler');
  });

  testWidgets('tapping the scrim fires onExit', (tester) async {
    var exits = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: Stack(
            children: [
              VoiceListeningModal(
                transcript: 'x',
                soundLevel: 0.1,
                onExit: () => exits++,
                onReset: () {},
              ),
            ],
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    // Tap near the top of the screen — the scrim region above the sheet.
    await tester.tapAt(const Offset(50, 20));
    await tester.pump();

    expect(exits, 1, reason: 'tapping the scrim exits');
  });
}
