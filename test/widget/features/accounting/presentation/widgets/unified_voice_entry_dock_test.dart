import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/unified_voice_entry_dock.dart';

const _copy = UnifiedVoiceEntryCopy(
  privacy: 'privacy',
  status: 'status',
  transcript: 'transcript',
  help: 'help',
  keyboardSemanticLabel: 'keyboard semantic',
  coreSemanticLabel: 'core semantic',
  primaryAction: 'primary action',
  settingsAction: 'settings action',
  continuousSummary: 'continuous summary',
  continuousAction: 'continuous action',
);

Widget _testApp({
  required UnifiedVoiceEntryState state,
  UnifiedVoiceEntryCopy copy = _copy,
  double soundLevel = 0.5,
  bool continuousMode = false,
  bool isSubmitting = false,
  VoidCallback? onKeyboard,
  VoidCallback? onCore,
  VoidCallback? onPrimary,
  VoidCallback? onSettings,
  VoidCallback? onToggleContinuous,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 390,
          child: UnifiedVoiceEntryDock(
            state: state,
            copy: copy,
            soundLevel: soundLevel,
            continuousMode: continuousMode,
            isSubmitting: isSubmitting,
            onKeyboard: onKeyboard ?? () {},
            onCore: onCore ?? () {},
            onPrimary: onPrimary ?? () {},
            onSettings: onSettings ?? () {},
            onToggleContinuous: onToggleContinuous ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final state in UnifiedVoiceEntryState.values) {
    testWidgets('$state renders injected visible and semantic copy', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final copy = UnifiedVoiceEntryCopy(
        privacy: 'privacy-$state',
        status: 'status-$state',
        transcript: 'transcript-$state',
        help: 'help-$state',
        keyboardSemanticLabel: 'keyboard-$state',
        coreSemanticLabel: 'core-$state',
        primaryAction: 'primary-$state',
        settingsAction: 'settings-$state',
        continuousSummary: 'summary-$state',
        continuousAction: 'continuous-$state',
      );

      await tester.pumpWidget(_testApp(state: state, copy: copy));

      expect(find.text(copy.privacy), findsOneWidget);
      expect(find.text(copy.status), findsOneWidget);
      expect(find.text(copy.transcript), findsOneWidget);
      expect(find.text(copy.help), findsOneWidget);
      expect(find.text(copy.continuousSummary), findsOneWidget);
      expect(find.text(copy.continuousAction), findsOneWidget);
      expect(find.bySemanticsLabel(copy.keyboardSemanticLabel), findsOneWidget);
      expect(find.bySemanticsLabel(copy.coreSemanticLabel), findsOneWidget);

      switch (state) {
        case UnifiedVoiceEntryState.idle:
          expect(find.byIcon(Icons.mic), findsOneWidget);
          expect(find.text(copy.primaryAction), findsNothing);
          expect(find.text(copy.settingsAction), findsNothing);
        case UnifiedVoiceEntryState.listening:
          expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
          expect(find.text(copy.primaryAction), findsNothing);
          expect(find.text(copy.settingsAction), findsNothing);
        case UnifiedVoiceEntryState.processing:
          expect(find.byIcon(Icons.autorenew_rounded), findsOneWidget);
          expect(find.text(copy.primaryAction), findsNothing);
          expect(find.text(copy.settingsAction), findsNothing);
        case UnifiedVoiceEntryState.review:
          expect(find.byIcon(Icons.mic), findsOneWidget);
          expect(find.text(copy.primaryAction), findsOneWidget);
          expect(find.text(copy.settingsAction), findsNothing);
        case UnifiedVoiceEntryState.unavailable:
          expect(find.byIcon(Icons.mic_off_rounded), findsOneWidget);
          expect(find.text(copy.primaryAction), findsNothing);
          expect(find.text(copy.settingsAction), findsOneWidget);
      }

      semantics.dispose();
    });
  }

  testWidgets('routes keyboard, core, primary, settings, and continuous taps', (
    tester,
  ) async {
    var keyboardTaps = 0;
    var coreTaps = 0;
    var primaryTaps = 0;
    var settingsTaps = 0;
    var continuousTaps = 0;

    Widget app(UnifiedVoiceEntryState state) => _testApp(
      state: state,
      onKeyboard: () => keyboardTaps++,
      onCore: () => coreTaps++,
      onPrimary: () => primaryTaps++,
      onSettings: () => settingsTaps++,
      onToggleContinuous: () => continuousTaps++,
    );

    await tester.pumpWidget(app(UnifiedVoiceEntryState.review));
    await tester.tap(find.byKey(const Key('unified-voice-keyboard')));
    await tester.tap(find.byKey(const Key('unified-voice-core')));
    await tester.tap(find.byKey(const Key('unified-voice-primary-action')));
    await tester.tap(find.byKey(const Key('unified-voice-continuous-action')));

    await tester.pumpWidget(app(UnifiedVoiceEntryState.unavailable));
    await tester.tap(find.byKey(const Key('unified-voice-settings-action')));

    expect(keyboardTaps, 1);
    expect(coreTaps, 1);
    expect(primaryTaps, 1);
    expect(settingsTaps, 1);
    expect(continuousTaps, 1);
  });

  testWidgets('processing and unavailable core actions are disabled', (
    tester,
  ) async {
    var coreTaps = 0;

    for (final state in [
      UnifiedVoiceEntryState.processing,
      UnifiedVoiceEntryState.unavailable,
    ]) {
      await tester.pumpWidget(_testApp(state: state, onCore: () => coreTaps++));
      await tester.tap(find.byKey(const Key('unified-voice-core')));
    }

    expect(coreTaps, 0);
  });

  testWidgets('submitting disables the review primary action', (tester) async {
    var primaryTaps = 0;
    await tester.pumpWidget(
      _testApp(
        state: UnifiedVoiceEntryState.review,
        isSubmitting: true,
        onPrimary: () => primaryTaps++,
      ),
    );

    await tester.tap(find.byKey(const Key('unified-voice-primary-action')));

    expect(primaryTaps, 0);
    expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    expect(find.byIcon(Icons.autorenew_rounded), findsNothing);
  });

  testWidgets(
    'owns the exact V16 dock, header, keyboard, core, and action geometry',
    (tester) async {
      await tester.pumpWidget(_testApp(state: UnifiedVoiceEntryState.review));

      expect(
        tester.getSize(find.byKey(const Key('unified-voice-entry-dock'))),
        const Size(390, 336),
      );
      expect(
        tester.getSize(find.byKey(const Key('unified-voice-header'))).height,
        44,
      );
      expect(
        tester.getSize(find.byKey(const Key('unified-voice-keyboard'))),
        const Size(44, 44),
      );
      expect(
        tester.getSize(find.byKey(const Key('unified-voice-core'))),
        const Size(60, 60),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('unified-voice-action-slot')))
            .height,
        46,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('unified-voice-primary-action')))
            .width,
        322,
      );
    },
  );

  testWidgets('review primary action uses the palette primary green', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(state: UnifiedVoiceEntryState.review));

    final material = tester.widget<Material>(
      find.byKey(const Key('unified-voice-primary-action')),
    );
    expect(material.color, AppPalette.light.accentPrimary);
  });

  testWidgets('continuous copy uses the same compact inline layout as keypad', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(state: UnifiedVoiceEntryState.idle));

    final summary = find.text(_copy.continuousSummary);
    final action = find.text(_copy.continuousAction);
    final gap =
        tester.getTopLeft(action).dx - tester.getBottomRight(summary).dx;
    expect(gap, greaterThan(4.5));
    expect(gap, lessThanOrEqualTo(6));
  });

  testWidgets(
    'continuous toggle is limited to the centered target in voice mode',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _testApp(
          state: UnifiedVoiceEntryState.idle,
          onToggleContinuous: () => taps++,
        ),
      );

      final target = find.byKey(const Key('unified-voice-continuous-action'));
      expect(tester.getSize(target).width, 230);

      final dock = find.byKey(const Key('unified-voice-entry-dock'));
      await tester.tapAt(
        Offset(tester.getRect(dock).left + 4, tester.getCenter(target).dy),
      );
      expect(taps, 0, reason: 'voice dock corners must not toggle the mode');

      await tester.tapAt(
        Offset(tester.getRect(target).left + 8, tester.getCenter(target).dy),
      );
      expect(
        taps,
        1,
        reason: 'the padded area inside the centered target remains tappable',
      );
    },
  );

  testWidgets('idle microphone has comfortable spacing above and below', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(state: UnifiedVoiceEntryState.idle));

    final waveform = find.byKey(const Key('unified-voice-waveform'));
    final core = find.byKey(const Key('unified-voice-core'));
    final help = find.text(_copy.help);
    expect(tester.getTopLeft(core).dy - tester.getBottomLeft(waveform).dy, 16);
    expect(tester.getTopLeft(help).dy - tester.getBottomLeft(core).dy, 12);
  });
}
