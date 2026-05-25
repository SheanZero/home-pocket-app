// test/unit/features/accounting/presentation/voice_recognition_event_handler_mixin_test.dart
//
// Phase 23 D-05: per-mixin unit tests for VoiceRecognitionEventHandlerMixin.onStatus
// intra-session guard. Exercises the mixin in isolation via a fake State implementing
// the 6-member abstract contract declared in the mixin.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_recognition_event_handler_mixin.dart';

// ── Fake State implementing the mixin contract ────────────────────────────────

/// Minimal host widget — required so _TestState has a real BuildContext.
class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.stateRef});

  final void Function(_TestState state) stateRef;

  @override
  State<_TestWidget> createState() => _TestState();
}

/// Fake [State] that mixes in [VoiceRecognitionEventHandlerMixin] for isolation
/// testing. Exposes mutable fields directly so individual tests can set up the
/// guard preconditions without going through the screen.
class _TestState extends State<_TestWidget> with VoiceRecognitionEventHandlerMixin {
  // ── Abstract contract implementation ────────────────────────────────────────

  @override
  bool isRecording = false;

  @override
  DateTime? pressStart;

  /// Backing store for the abstract [isInitialized] setter.
  // Exposed as a readable field so tests can assert on it if needed;
  // prevents the unused-field warning on a write-only backing var.
  bool lastIsInitialized = true;

  @override
  set isInitialized(bool value) => setState(() => lastIsInitialized = value);

  /// Backing store for the abstract [soundLevel] setter.
  double lastSoundLevel = 0.0;

  @override
  set soundLevel(double value) => setState(() => lastSoundLevel = value);

  /// Mock last-final timestamp — set directly by tests.
  DateTime? mockLastFinal;

  @override
  DateTime? get lastMergerFinalAt => mockLastFinal;

  /// Counter incremented whenever stopRecordingAndCommit is invoked.
  /// Tests assert on this to verify whether the commit path fired.
  int commitCount = 0;

  @override
  Future<void> stopRecordingAndCommit() async {
    commitCount++;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    widget.stateRef(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Helper ───────────────────────────────────────────────────────────────────

Future<_TestState> _pumpTestState(WidgetTester tester) async {
  late _TestState capturedState;
  await tester.pumpWidget(
    MaterialApp(
      home: _TestWidget(stateRef: (s) => capturedState = s),
    ),
  );
  await tester.pump();
  return capturedState;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VoiceRecognitionEventHandlerMixin (Phase 23 D-05)', () {
    // ── D-05 case (a): intra-session block ──────────────────────────────────
    //
    // lastMergerFinalAt = now - 100ms  (well within 800ms threshold)
    // pressStart != null
    // isRecording = true
    // → onStatus('notListening') MUST NOT invoke stopRecordingAndCommit.
    testWidgets(
      'D-05 (a) intra-session: notListening within threshold does NOT commit',
      (tester) async {
        final state = await _pumpTestState(tester);

        state.isRecording = true;
        state.pressStart = DateTime.now();
        state.mockLastFinal =
            DateTime.now().subtract(const Duration(milliseconds: 100));

        state.onStatus('notListening');
        await tester.pump();

        expect(
          state.commitCount,
          0,
          reason:
              'D-05: lastFinal was 100ms ago (< 800ms threshold); '
              'recognizer self-restart in flight — commit must be suppressed',
        );
      },
    );

    // ── D-05 case (b): end-of-session commit ────────────────────────────────
    //
    // lastMergerFinalAt = now - 2000ms  (well past the 800ms threshold)
    // pressStart != null
    // isRecording = true
    // → onStatus('notListening') MUST invoke stopRecordingAndCommit exactly once.
    testWidgets(
      'D-05 (b) end-of-session: notListening past threshold commits exactly once',
      (tester) async {
        final state = await _pumpTestState(tester);

        state.isRecording = true;
        state.pressStart = DateTime.now();
        state.mockLastFinal =
            DateTime.now().subtract(const Duration(milliseconds: 2000));

        state.onStatus('notListening');
        await tester.pump();

        expect(
          state.commitCount,
          1,
          reason:
              'D-05: lastFinal was 2000ms ago (> 800ms threshold); '
              'this is a real session end — commit must fire',
        );
      },
    );

    // ── D-05 case (c): 'done' bypasses guard ────────────────────────────────
    //
    // mockLastFinal = DateTime.now() (within threshold — 0ms elapsed)
    // pressStart != null
    // isRecording = true
    // status = 'done' — canonically terminal per speech_to_text v5+ docs
    // → guard does NOT apply; stopRecordingAndCommit MUST be invoked.
    testWidgets(
      "D-05 (c) done-bypass: status='done' commits unconditionally even within threshold",
      (tester) async {
        final state = await _pumpTestState(tester);

        state.isRecording = true;
        state.pressStart = DateTime.now();
        // Within threshold — if guard erroneously applied to 'done', would block.
        state.mockLastFinal = DateTime.now();

        state.onStatus('done');
        await tester.pump();

        expect(
          state.commitCount,
          1,
          reason:
              "D-05: 'done' is canonically terminal per speech_to_text v5+ docs; "
              "the D-05 guard only applies to 'notListening' — 'done' must always commit",
        );
      },
    );

    // ── D-05 case (d): null lastMergerFinalAt — guard inactive ─────────────
    //
    // mockLastFinal = null  (no chunks seen yet)
    // pressStart != null
    // isRecording = true
    // → D-05 guard has no signal; falls through to G-01 commit path.
    //   stopRecordingAndCommit MUST be invoked (default to commit per G-01).
    testWidgets(
      'D-05 (d) null-finals: notListening with null lastMergerFinalAt commits (G-01 preserved)',
      (tester) async {
        final state = await _pumpTestState(tester);

        state.isRecording = true;
        state.pressStart = DateTime.now();
        state.mockLastFinal = null; // no chunks seen

        state.onStatus('notListening');
        await tester.pump();

        expect(
          state.commitCount,
          1,
          reason:
              'D-05: lastMergerFinalAt is null (no chunks yet); '
              'guard cannot fire — fall through to G-01 commit path',
        );
      },
    );
  });
}
