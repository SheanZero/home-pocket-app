// Widget test for VoiceRecordPanel (quick task 260622-nhs R3 — inline panel
// that REPLACES the keypad in place: no scrim, no overlay, no bottom-sheet
// chrome. Tap the panel's blank area = exit; the reset button does NOT bubble).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_ptt_session_mixin.dart';
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
            body: VoiceRecordPanel(
              transcript: '拿铁 一千二百八',
              soundLevel: 0.6,
              onExit: () {},
              onReset: () {},
            ),
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pump();

      final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));

      expect(find.text('拿铁 一千二百八'), findsOneWidget);
      expect(find.text(l10n.listeningTitle), findsOneWidget);
      expect(find.text(l10n.voiceTapToExit), findsOneWidget);
      expect(find.text(l10n.voiceResetRestore), findsOneWidget);
      expect(find.byType(VoiceWaveform), findsOneWidget);
      // Line-style mics (panel mic + reset restore icon are line-style).
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    },
  );

  testWidgets(
    'R3: it is an INLINE panel — no full-screen scrim overlay',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VoiceRecordPanel(
                  transcript: 'x',
                  soundLevel: 0.1,
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

      // No Positioned.fill scrim: the panel does not paint a full-screen dim.
      expect(find.byType(Positioned), findsNothing,
          reason: 'R3: the inline panel must not use a Positioned scrim/overlay');
    },
  );

  testWidgets('tapping the panel body fires onExit (not onReset)',
      (tester) async {
    var exits = 0;
    var resets = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            onExit: () => exits++,
            onReset: () => resets++,
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    // Tap the listening title region (inside the panel body, away from reset).
    final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));
    await tester.tap(find.text(l10n.listeningTitle));
    await tester.pump();

    expect(exits, 1, reason: 'tapping the panel blank area exits');
    expect(resets, 0);
  });

  testWidgets('tapping the reset button fires onReset and NOT onExit',
      (tester) async {
    var exits = 0;
    var resets = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            onExit: () => exits++,
            onReset: () => resets++,
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));
    await tester.tap(find.text(l10n.voiceResetRestore));
    await tester.pump();

    expect(resets, 1, reason: 'reset button restores the form');
    expect(exits, 0, reason: 'reset tap must NOT bubble to the exit handler');
  });

  // ── R4 BUG C: live status drives the title ────────────────────────────────

  testWidgets('R4 BUG C: status listening shows the listening title',
      (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            status: PttListenStatus.listening,
            onExit: () {},
            onReset: () {},
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));
    expect(find.text(l10n.listeningTitle), findsOneWidget);
    expect(find.text(l10n.voiceStatusProcessing), findsNothing);
    expect(find.text(l10n.voiceStatusStopped), findsNothing);
  });

  testWidgets('R4 BUG C: status processing shows the parsing title',
      (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            status: PttListenStatus.processing,
            onExit: () {},
            onReset: () {},
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));
    expect(find.text(l10n.voiceStatusProcessing), findsOneWidget);
    expect(find.text(l10n.listeningTitle), findsNothing);
  });

  testWidgets('R4 BUG C: status stopped shows the stopped title',
      (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            status: PttListenStatus.stopped,
            onExit: () {},
            onReset: () {},
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    final l10n = S.of(tester.element(find.byType(VoiceRecordPanel)));
    expect(find.text(l10n.voiceStatusStopped), findsOneWidget);
    expect(find.text(l10n.listeningTitle), findsNothing);
  });
}
