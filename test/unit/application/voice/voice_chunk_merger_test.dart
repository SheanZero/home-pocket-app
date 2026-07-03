import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_chunk_merger.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
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
  int? Function(String text)? amountExtractor,
}) {
  return VoiceChunkMerger(
    parser: parser,
    speechService: speechService,
    onAmountResolved: onAmountResolved,
    amountExtractor: amountExtractor,
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

    test('false-merge regression: 1千8百 + 现金 commits 1800 and drops 现金', () {
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
    });

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
        merger.feedChunk(
          '6百8十元',
          isFinal: true,
        ); // 680 in Chinese numeral notation
        async.flushMicrotasks();
        async.elapse(
          const Duration(milliseconds: 2501),
        ); // just past window boundary
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

  // 260703 BUG-1: iOS zh ITN can finalize 「两千五百四十六元」 as two separate
  // Arabic finals "2500" + "46元". The old gate judged the pure-Arabic buffer
  // "closed" → committed 2500 and silently DROPPED the tail. The buffer must be
  // treated as open (round group) and the merge must read positionally (2546).
  group('260703 BUG-1: ITN-split Arabic finals', () {
    test('2500 + 46元 across finals -> 2546 (not 2500-truncation)', () {
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

        merger.feedChunk('2500', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1200));
        merger.feedChunk('46元', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();

        expect(commits, equals([2546]));
        verify(() => mockSpeech.restartListen()).called(2);
        merger.dispose();
      });
    });

    test('2500 + 现金 -> commits 2500 and drops the non-numeric chunk', () {
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

        merger.feedChunk('2500', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1000));
        merger.feedChunk('现金', isFinal: true); // chunk-side lexical gate fails
        async.flushMicrotasks();

        expect(commits, equals([2500]));
        verify(() => mockSpeech.restartListen()).called(1);
        merger.dispose();
      });
    });

    test('comma-grouped final 2,546元 commits 2546 via the full-parser '
        'extractor (not the tail-only 546)', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);
        final textParser = VoiceTextParser();

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
          amountExtractor: (text) =>
              textParser.extractAmount(text, localeId: 'zh-CN'),
        );

        merger.feedChunk('2,546元', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2501));
        async.flushMicrotasks();

        expect(commits, equals([2546]));
        merger.dispose();
      });
    });

    test('split finals through the extractor also read 2546', () {
      fakeAsync((async) {
        final commits = <int>[];
        final mockSpeech = _MockSpeechRecognitionService();
        when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);
        final textParser = VoiceTextParser();

        final merger = _buildMerger(
          parser: const ChineseNumeralStateMachine(),
          onAmountResolved: commits.add,
          async: async,
          speechService: mockSpeech,
          amountExtractor: (text) =>
              textParser.extractAmount(text, localeId: 'zh-CN'),
        );

        merger.feedChunk('2500', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 800));
        merger.feedChunk('46元', isFinal: true);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();

        expect(commits, equals([2546]));
        merger.dispose();
      });
    });
  });

  group('lastFinalAt (Phase 23 D-05 prep)', () {
    test('returns null before any chunk is fed', () {
      final mockSpeech = _MockSpeechRecognitionService();
      when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

      final merger = VoiceChunkMerger(
        parser: const ChineseNumeralStateMachine(),
        speechService: mockSpeech,
        onAmountResolved: (_) {},
      );

      expect(merger.lastFinalAt, isNull);
      merger.dispose();
    });

    test('returns DateTime within range after a final chunk is fed', () async {
      final mockSpeech = _MockSpeechRecognitionService();
      when(() => mockSpeech.restartListen()).thenAnswer((_) async => true);

      final merger = VoiceChunkMerger(
        parser: const ChineseNumeralStateMachine(),
        speechService: mockSpeech,
        onAmountResolved: (_) {},
      );

      final before = DateTime.now();
      await merger.feedChunk('1千元', isFinal: true);
      final after = DateTime.now();

      expect(merger.lastFinalAt, isNotNull);
      expect(
        merger.lastFinalAt!.isAfter(
          before.subtract(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
      expect(
        merger.lastFinalAt!.isBefore(
          after.add(const Duration(milliseconds: 1)),
        ),
        isTrue,
      );
      merger.dispose();
    });
  });
}
