import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/shopping_list/presentation/widgets/shopping_voice_draft_panel.dart';

const _copy = ShoppingVoiceDraftCopy(
  manualTitle: 'manual title',
  manualHelp: 'manual help',
  manualSemanticLabel: 'open voice input',
  privacyLabel: 'privacy',
  listeningStatus: 'listening status',
  processingStatus: 'processing status',
  reviewStatus: 'review status',
  unavailableStatus: 'unavailable status',
  keyboardSemanticLabel: 'return to keyboard',
  listeningTranscriptPlaceholder: 'listening placeholder',
  processingTranscriptPlaceholder: 'processing placeholder',
  reviewTranscriptPlaceholder: 'review placeholder',
  unavailableTranscript: 'unavailable transcript',
  stopSemanticLabel: 'stop and process',
  processingSemanticLabel: 'processing disabled',
  rerecordSemanticLabel: 'record again',
  unavailableCoreSemanticLabel: 'microphone unavailable',
  listeningHelp: 'listening help',
  processingHelp: 'processing help',
  reviewHelp: 'review help',
  unavailableHelp: 'unavailable help',
  settingsLabel: 'open settings',
  settingsSemanticLabel: 'open microphone settings',
);

Future<void> _pumpPanel(
  WidgetTester tester, {
  required ShoppingVoiceDraftState state,
  String transcript = '',
  double soundLevel = 0.5,
  VoidCallback? onOpen,
  VoidCallback? onStop,
  VoidCallback? onKeyboard,
  VoidCallback? onRerecord,
  VoidCallback? onSettings,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            child: ShoppingVoiceDraftPanel(
              state: state,
              copy: _copy,
              transcript: transcript,
              soundLevel: soundLevel,
              onOpen: onOpen ?? () {},
              onStop: onStop ?? () {},
              onKeyboard: onKeyboard ?? () {},
              onRerecord: onRerecord ?? () {},
              onSettings: onSettings ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ShoppingVoiceDraftPanel', () {
    testWidgets('exposes a stable root key and copy for every state', (
      tester,
    ) async {
      const expectedCopy =
          <
            ShoppingVoiceDraftState,
            ({String status, String transcript, String help})
          >{
            ShoppingVoiceDraftState.listening: (
              status: 'listening status',
              transcript: 'listening placeholder',
              help: 'listening help',
            ),
            ShoppingVoiceDraftState.processing: (
              status: 'processing status',
              transcript: 'processing placeholder',
              help: 'processing help',
            ),
            ShoppingVoiceDraftState.review: (
              status: 'review status',
              transcript: 'review placeholder',
              help: 'review help',
            ),
            ShoppingVoiceDraftState.unavailable: (
              status: 'unavailable status',
              transcript: 'unavailable transcript',
              help: 'unavailable help',
            ),
          };

      for (final state in ShoppingVoiceDraftState.values) {
        await _pumpPanel(tester, state: state);

        expect(
          find.byKey(ShoppingVoiceDraftPanel.stateKey(state)),
          findsOneWidget,
        );
        if (state == ShoppingVoiceDraftState.manual) {
          expect(find.text('manual title'), findsOneWidget);
          expect(find.text('manual help'), findsOneWidget);
          continue;
        }

        final expected = expectedCopy[state]!;
        expect(find.text(expected.status), findsOneWidget);
        expect(find.text(expected.transcript), findsOneWidget);
        expect(find.text(expected.help), findsOneWidget);
      }
    });

    testWidgets('manual card opens voice input and keeps 64/38 geometry', (
      tester,
    ) async {
      var opens = 0;
      await _pumpPanel(
        tester,
        state: ShoppingVoiceDraftState.manual,
        onOpen: () => opens++,
      );

      expect(
        tester
            .getSize(find.byKey(ShoppingVoiceDraftPanel.manualStateKey))
            .height,
        64,
      );
      expect(
        tester.getSize(find.byKey(ShoppingVoiceDraftPanel.manualMicBoxKey)),
        const Size.square(38),
      );
      final help = tester.widget<Text>(find.text('manual help'));
      expect(help.maxLines, 2);
      expect(help.overflow, isNot(TextOverflow.ellipsis));

      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.manualStateKey));
      expect(opens, 1);
    });

    testWidgets('routes active actions to their state-specific callbacks', (
      tester,
    ) async {
      var stops = 0;
      var keyboards = 0;
      var rerecords = 0;
      var settings = 0;

      await _pumpPanel(
        tester,
        state: ShoppingVoiceDraftState.listening,
        onStop: () => stops++,
        onKeyboard: () => keyboards++,
      );
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.coreActionKey));
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.keyboardActionKey));
      expect(stops, 1);
      expect(keyboards, 1);

      await _pumpPanel(
        tester,
        state: ShoppingVoiceDraftState.review,
        onRerecord: () => rerecords++,
      );
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.coreActionKey));
      expect(rerecords, 1);

      await _pumpPanel(
        tester,
        state: ShoppingVoiceDraftState.unavailable,
        onSettings: () => settings++,
      );
      await tester.tap(find.byKey(ShoppingVoiceDraftPanel.settingsActionKey));
      expect(settings, 1);
    });

    testWidgets('processing and unavailable core actions are disabled', (
      tester,
    ) async {
      var stops = 0;
      var rerecords = 0;

      for (final state in const [
        ShoppingVoiceDraftState.processing,
        ShoppingVoiceDraftState.unavailable,
      ]) {
        await _pumpPanel(
          tester,
          state: state,
          onStop: () => stops++,
          onRerecord: () => rerecords++,
        );

        final core = find.byKey(ShoppingVoiceDraftPanel.coreActionKey);
        final inkWell = tester.widget<InkWell>(
          find.descendant(of: core, matching: find.byType(InkWell)),
        );
        expect(inkWell.onTap, isNull);
        await tester.tap(core);
      }

      expect(stops, 0);
      expect(rerecords, 0);
    });

    testWidgets(
      'active panel preserves 44 header/actions and 58 core geometry',
      (tester) async {
        await _pumpPanel(
          tester,
          state: ShoppingVoiceDraftState.listening,
          transcript: 'live transcript',
          soundLevel: 4,
        );

        expect(
          tester
              .getSize(find.byKey(ShoppingVoiceDraftPanel.listeningStateKey))
              .height,
          greaterThanOrEqualTo(190),
        );
        expect(
          tester.getSize(find.byKey(ShoppingVoiceDraftPanel.headerKey)).height,
          44,
        );
        expect(
          tester.getSize(find.byKey(ShoppingVoiceDraftPanel.keyboardActionKey)),
          const Size.square(44),
        );
        expect(
          tester.getSize(find.byKey(ShoppingVoiceDraftPanel.coreActionKey)),
          const Size.square(58),
        );
        expect(find.text('live transcript'), findsOneWidget);
      },
    );
  });
}
