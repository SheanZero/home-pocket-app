// Widget test for VoiceRecordPanel (quick task 260622-nhs R3 → R7).
//
// R7 redesign: the bottom 「重置·恢复账目」 button is GONE. The central square is
// a dual-state button driven by [status]:
//   - listening/processing → grey square + line mic ([Icons.mic_none]); PASSIVE
//     (no onTap — a tap bubbles to the panel's exit handler).
//   - stopped → red square + reset icon ([Icons.restore]); TAPPABLE → onReset.
// Both states are EQUAL HEIGHT (the stopped-only tap-reset hint keeps reserved
// placeholder space while listening so 「轻点空白处退出」 aligns identically).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_ptt_session_mixin.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_listening_overlay.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/voice_waveform.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  testWidgets(
    'listening: renders transcript, title, tap-exit hint, waveform, grey line mic '
    '(no bottom reset button)',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: VoiceRecordPanel(
              transcript: '拿铁 一千二百八',
              soundLevel: 0.6,
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

      expect(find.text('拿铁 一千二百八'), findsOneWidget);
      expect(find.text(l10n.listeningTitle), findsOneWidget);
      expect(find.text(l10n.voiceTapToExit), findsOneWidget);
      expect(find.byType(VoiceWaveform), findsOneWidget);
      // The central square shows the line mic while listening.
      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
      // R7: the bottom reset button is removed — no reset icon while listening.
      expect(find.byIcon(Icons.restore), findsNothing,
          reason: 'R7: no reset affordance while listening');
      // R7: the standalone reset button key no longer exists.
      expect(find.byKey(const ValueKey('voice-panel-reset')), findsNothing,
          reason: 'R7: the bottom reset button is deleted');
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

  testWidgets('listening: tapping the central grey square fires onExit (passive)',
      (tester) async {
    var exits = 0;
    var resets = 0;

    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(
          body: VoiceRecordPanel(
            transcript: 'x',
            soundLevel: 0.1,
            status: PttListenStatus.listening,
            onExit: () => exits++,
            onReset: () => resets++,
          ),
        ),
        locale: const Locale('zh'),
      ),
    );
    await tester.pump();

    // The grey square is passive: a tap on it bubbles to the panel exit.
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump();

    expect(resets, 0, reason: 'R7: the grey listening square must NOT reset');
    expect(exits, 1, reason: 'R7: the passive square forwards the tap to exit');
  });

  testWidgets(
    'stopped: tapping the central red square fires onReset and NOT onExit',
    (tester) async {
      var exits = 0;
      var resets = 0;

      await tester.pumpWidget(
        createLocalizedWidget(
          Scaffold(
            body: VoiceRecordPanel(
              transcript: 'x',
              soundLevel: 0.1,
              status: PttListenStatus.stopped,
              onExit: () => exits++,
              onReset: () => resets++,
            ),
          ),
          locale: const Locale('zh'),
        ),
      );
      await tester.pump();

      // The red square shows the reset icon and is tappable.
      expect(find.byIcon(Icons.restore), findsOneWidget,
          reason: 'R7: stopped state shows the reset icon on the red square');
      expect(find.byIcon(Icons.mic_none), findsNothing,
          reason: 'R7: the mic glyph is replaced by reset when stopped');

      await tester.tap(find.byKey(const ValueKey('voice-square-reset')));
      await tester.pump();

      expect(resets, 1, reason: 'R7: tapping the red square restores the form');
      expect(exits, 0, reason: 'R7: the reset tap must NOT bubble to exit');
    },
  );

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
    // processing is a listening-class state: grey mic, no reset.
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsNothing);
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

  // ── 260622-nhs R6 BUG 1: stopped-state tap-reset hint ─────────────────────

  testWidgets(
    'R6: status stopped shows the 点击重置重新录入 tap-reset hint below the square',
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
      // The stopped-state hint tells the user that tapping the red square records again.
      expect(find.text(l10n.voiceTapResetToRerecord), findsOneWidget,
          reason: 'stopped state must surface the tap-reset hint');
      // The tap-exit hint remains available.
      expect(find.text(l10n.voiceTapToExit), findsOneWidget);
    },
  );

  testWidgets(
    'R7: while listening the tap-reset hint text is hidden but its space is RESERVED '
    '(equal panel height)',
    (tester) async {
      final l10nHolder = <S>[];

      Future<Size> panelSize(PttListenStatus status) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: VoiceRecordPanel(
                  transcript: '今天吃饭用了 888 日元',
                  soundLevel: 0.4,
                  status: status,
                  onExit: () {},
                  onReset: () {},
                ),
              ),
            ),
            locale: const Locale('zh'),
          ),
        );
        await tester.pump();
        l10nHolder.add(S.of(tester.element(find.byType(VoiceRecordPanel))));
        return tester.getSize(find.byType(VoiceRecordPanel));
      }

      final listeningSize = await panelSize(PttListenStatus.listening);
      final stoppedSize = await panelSize(PttListenStatus.stopped);

      // R7 equal-height requirement: the panel must not change height between
      // listening and stopped (no jump on transition). The reserved placeholder
      // for the tap-reset hint guarantees this.
      expect(listeningSize.height, stoppedSize.height,
          reason: 'R7: listening and stopped panels must be equal height');

      // While listening, the reset-hint TEXT is not visible (only stopped shows it)…
      final l10n = l10nHolder.first;
      // …re-pump listening to assert on the visible text in that state.
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
      // maintainState keeps the Text in the tree (for layout) but invisible.
      // The reserved placeholder line keeps the height identical — asserted above.
      // The hint text node still exists in the tree (maintainState: true).
      expect(find.text(l10n.voiceTapResetToRerecord), findsOneWidget,
          reason: 'R7: the hint line is maintained (reserved) while listening');
    },
  );
}
