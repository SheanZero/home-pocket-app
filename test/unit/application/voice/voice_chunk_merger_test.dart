import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_chunk_merger.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:home_pocket/infrastructure/voice/chinese_numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/japanese_numeral_state_machine.dart';
import 'package:home_pocket/infrastructure/voice/numeral_state_machine.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpeechRecognitionService extends Mock
    implements SpeechRecognitionService {}

VoiceChunkMerger _buildMerger({
  required NumeralStateMachine parser,
  required AmountResolvedCallback onAmountResolved,
  required FakeAsync async,
  required SpeechRecognitionService speechService,
}) {
  return VoiceChunkMerger(
    parser: parser,
    speechService: speechService,
    onAmountResolved: onAmountResolved,
    clock: () => async.getClock(DateTime.utc(2026, 1, 1)).now(),
  );
}

void main() {
  group('VoiceChunkMerger', () {
    test('anchor zh: 1千8百 + 1.2s pause + 4十元 -> 1840 (VOICE-02 anchor)', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        merger.feedChunk('1千8百', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1200));
        merger.feedChunk('4十元', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();

        expect(commits, equals([1840]));
        verify(() => mockSpeech.restartListen()).called(2);
        merger.dispose();
      });
    });

    test(
      'anchor ja: せんはっぴゃく + 1.5s pause + よんじゅう円 -> 1840 (VOICE-02 anchor)',
      () {
        fakeAsync((async) {
          final commits = <int>[];
          final mockSpeech = _MockSpeechRecognitionService();
          when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

          final merger = _buildMerger(
            parser: JapaneseNumeralStateMachine(),
            onAmountResolved: commits.add,
            async: async,
            speechService: mockSpeech,
          );

          merger.feedChunk('せんはっぴゃく', isFinal: true);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 1500));
          merger.feedChunk('よんじゅう円', isFinal: true);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 2500));
          async.flushMicrotasks();

          expect(commits, equals([1840]));
          verify(() => mockSpeech.restartListen()).called(2);
          merger.dispose();
        });
      },
    );

    test(
      'false-merge regression: 1千8百 + 现金 commits 1800 and drops 现金',
      () {
        fakeAsync((async) {
          final commits = <int>[];
          final mockSpeech = _MockSpeechRecognitionService();
          when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

          final merger = _buildMerger(
            parser: const ChineseNumeralStateMachine(),
            onAmountResolved: commits.add,
            async: async,
            speechService: mockSpeech,
          );

          merger.feedChunk('1千8百', isFinal: true);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 1000));
          merger.feedChunk('现金', isFinal: true); // lexical gate fails
          async.flushMicrotasks();

          expect(commits, equals([1800])); // committed immediately on gate fail
          verify(
            () => mockSpeech.restartListen(),
          ).called(1); // only on first feed
          merger.dispose();
        });
      },
    );

    test('window expiry commits single chunk after 2.5s', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        // Use Chinese unit-notation so the parser can produce a numeric result.
        // Pure arabic digits (e.g. '680') have no units and parse to null in the
        // section-accumulator — they need explicit 百/十/千 markers.
        merger.feedChunk('6百8十元', isFinal: true); // 680 in Chinese numeral notation
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2501)); // just past window boundary
        async.flushMicrotasks();

        expect(commits, equals([680]));
        merger.dispose();
      });
    });

    test('partial result is ignored (no buffer, no timer, no restart)', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        merger.feedChunk('1千8百', isFinal: false);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 5000));
        async.flushMicrotasks();

        expect(commits, isEmpty);
        verifyNever(() => mockSpeech.restartListen());
        merger.dispose();
      });
    });

    test('stop() commits buffer immediately', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        merger.feedChunk('1千8百', isFinal: true);
        async.flushMicrotasks();
        merger.stop();

        expect(commits, equals([1800]));
        merger.dispose();
      });
    });

    test('dispose cancels pending timer; no commit fires after dispose', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        merger.feedChunk('1千8百', isFinal: true);
        async.flushMicrotasks();
        merger.dispose();
        async.elapse(const Duration(milliseconds: 5000));
        async.flushMicrotasks();

        expect(commits, isEmpty);
      });
    });

    test('empty final chunk is ignored', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
        );

        merger.feedChunk('', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 3000));
        async.flushMicrotasks();

        expect(commits, isEmpty);
        verifyNever(() => mockSpeech.restartListen());
        merger.dispose();
      });
    });
  });
}
