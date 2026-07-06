/// Quick task 260706-tm6 (voice-consolidation P0-6 / offline Tier 0):
/// on-device recognition default + silent session-scoped fallback.
///
/// Behavior contract:
///   1. startListening passes SpeechListenOptions.onDevice == true by default
///      (other options unchanged: dictation / autoPunctuation /
///      cancelOnError:false / partialResults:true).
///   2. When the on-device listen throws ListenFailedException, the SAME call
///      retries once with identical localeId/listenFor/pauseFor and
///      onDevice:false — startListening completes normally (2 listen calls).
///   3. After a fallback, subsequent startListening calls go straight to
///      onDevice:false (session flag — 1 listen call each).
///   4. After a fallback, restartListen replays _lastConfig with
///      onDevice:false too (the cached-config path needs no second site —
///      it flows through startListening).
///   5. When onDevice is already false (fallback active) and listen throws,
///      the exception propagates unchanged with NO retry (no loop).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class _MockSpeechToText extends Mock implements stt.SpeechToText {}

class _FakeSpeechRecognitionResult extends Fake
    implements SpeechRecognitionResult {}

class _FakeSpeechListenOptions extends Fake
    implements stt.SpeechListenOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSpeechRecognitionResult());
    registerFallbackValue(_FakeSpeechListenOptions());
  });

  late _MockSpeechToText mockSpeech;
  late SpeechRecognitionService service;
  final capturedOptions = <stt.SpeechListenOptions>[];
  final capturedLocales = <String?>[];
  final capturedListenFor = <Duration?>[];
  final capturedPauseFor = <Duration?>[];

  void onResultStub(SpeechRecognitionResult r) {}
  void onSoundLevelStub(double l) {}

  /// Stubs listen() to record every invocation's options/locale/durations and
  /// throw ListenFailedException while [failWhile] returns true.
  void stubListen({required bool Function(stt.SpeechListenOptions opts) fail}) {
    when(() => mockSpeech.listen(
          onResult: any(named: 'onResult'),
          localeId: any(named: 'localeId'),
          listenFor: any(named: 'listenFor'),
          pauseFor: any(named: 'pauseFor'),
          onSoundLevelChange: any(named: 'onSoundLevelChange'),
          listenOptions: any(named: 'listenOptions'),
        )).thenAnswer((invocation) {
      final opts = invocation.namedArguments[#listenOptions]
          as stt.SpeechListenOptions;
      capturedOptions.add(opts);
      capturedLocales.add(
        invocation.namedArguments[#localeId] as String?,
      );
      capturedListenFor.add(
        invocation.namedArguments[#listenFor] as Duration?,
      );
      capturedPauseFor.add(
        invocation.namedArguments[#pauseFor] as Duration?,
      );
      if (fail(opts)) {
        throw stt.ListenFailedException('on-device unavailable');
      }
      return Future<void>.value();
    });
  }

  Future<void> initService() async {
    when(() => mockSpeech.initialize(
          onStatus: any(named: 'onStatus'),
          onError: any(named: 'onError'),
          debugLogging: any(named: 'debugLogging'),
        )).thenAnswer((_) async => true);
    await service.initialize();
  }

  setUp(() {
    mockSpeech = _MockSpeechToText();
    service = SpeechRecognitionService(speech: mockSpeech);
    capturedOptions.clear();
    capturedLocales.clear();
    capturedListenFor.clear();
    capturedPauseFor.clear();
  });

  test('Test 1: startListening defaults to onDevice:true with the existing '
      'option set unchanged', () async {
    await initService();
    stubListen(fail: (_) => false);

    await service.startListening(
      onResult: onResultStub,
      onSoundLevel: onSoundLevelStub,
      localeId: 'ja-JP',
    );

    expect(capturedOptions, hasLength(1));
    final opts = capturedOptions.single;
    expect(opts.onDevice, isTrue,
        reason: 'offline Tier 0: recognition starts on-device by default');
    expect(opts.listenMode, stt.ListenMode.dictation);
    expect(opts.autoPunctuation, isTrue);
    expect(opts.cancelOnError, isFalse);
    expect(opts.partialResults, isTrue);
  });

  test('Test 2: on-device ListenFailedException triggers ONE same-args retry '
      'with onDevice:false and completes', () async {
    await initService();
    stubListen(fail: (opts) => opts.onDevice == true);

    await expectLater(
      service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'zh-CN',
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 2),
      ),
      completes,
    );

    expect(capturedOptions, hasLength(2),
        reason: 'exactly one on-device attempt + one fallback retry');
    expect(capturedOptions[0].onDevice, isTrue);
    expect(capturedOptions[1].onDevice, isFalse);
    // Same-args retry: locale and durations are identical on both calls.
    expect(capturedLocales, ['zh-CN', 'zh-CN']);
    expect(capturedListenFor,
        [const Duration(seconds: 20), const Duration(seconds: 20)]);
    expect(capturedPauseFor,
        [const Duration(seconds: 2), const Duration(seconds: 2)]);
    expect(service.onDeviceFallbackActive, isTrue,
        reason: 'the session-scoped fallback flag is set after the degrade');
  });

  test('Test 3: after a fallback, the NEXT startListening goes straight to '
      'onDevice:false (single listen call)', () async {
    await initService();
    stubListen(fail: (opts) => opts.onDevice == true);

    // First call degrades (2 listen invocations).
    await service.startListening(
      onResult: onResultStub,
      onSoundLevel: onSoundLevelStub,
      localeId: 'ja-JP',
    );
    expect(capturedOptions, hasLength(2));

    // Second call: session flag persists — one call, already onDevice:false.
    await service.startListening(
      onResult: onResultStub,
      onSoundLevel: onSoundLevelStub,
      localeId: 'ja-JP',
    );

    expect(capturedOptions, hasLength(3),
        reason: 'no on-device attempt after the session degraded');
    expect(capturedOptions[2].onDevice, isFalse);
  });

  test('Test 4: after a fallback, restartListen replays the cached config '
      'with onDevice:false', () async {
    await initService();
    when(() => mockSpeech.isListening).thenReturn(false);
    stubListen(fail: (opts) => opts.onDevice == true);

    await service.startListening(
      onResult: onResultStub,
      onSoundLevel: onSoundLevelStub,
      localeId: 'ja-JP',
    );
    expect(capturedOptions, hasLength(2), reason: 'precondition: degraded');

    final ok = await service.restartListen();

    expect(ok, isTrue);
    expect(capturedOptions, hasLength(3),
        reason: 'restartListen replays via startListening exactly once');
    expect(capturedOptions[2].onDevice, isFalse,
        reason: 'the cached-config replay inherits the session fallback');
    expect(capturedLocales[2], 'ja-JP');
  });

  test('Test 5: a listen failure while already onDevice:false propagates '
      'unchanged with NO retry (no loop)', () async {
    await initService();
    // Degrade the session first (on-device fails, fallback succeeds).
    stubListen(fail: (opts) => opts.onDevice == true);
    await service.startListening(
      onResult: onResultStub,
      onSoundLevel: onSoundLevelStub,
      localeId: 'ja-JP',
    );
    expect(capturedOptions, hasLength(2), reason: 'precondition: degraded');

    // Now every listen fails — including the onDevice:false path.
    stubListen(fail: (_) => true);

    await expectLater(
      service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'ja-JP',
      ),
      throwsA(isA<stt.ListenFailedException>()),
    );

    expect(capturedOptions, hasLength(3),
        reason: 'exactly one more listen call — no retry when the failure is '
            'not an on-device degrade');
    expect(capturedOptions[2].onDevice, isFalse);
  });
}
