import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class _MockSpeechToText extends Mock implements stt.SpeechToText {}

class _FakeSpeechRecognitionResult extends Fake
    implements SpeechRecognitionResult {}

class _FakeSpeechListenOptions extends Fake implements stt.SpeechListenOptions {
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSpeechRecognitionResult());
    registerFallbackValue(_FakeSpeechListenOptions());
  });

  group('SpeechRecognitionService - initial state', () {
    test('isListening is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isListening, isFalse);
    });

    test('isAvailable is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isAvailable, isFalse);
    });

    test('stopListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.stopListening(), completes);
    });

    test('cancelListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.cancelListening(), completes);
    });
  });

  group('SpeechRecognitionService - sound level normalization', () {
    test('normalizeSoundLevel clamps within 0.0-1.0 for Android values', () {
      final service = SpeechRecognitionService();
      expect(
        service.normalizeSoundLevelForTest(15.0, isAndroid: true),
        equals(1.0),
      );
      expect(
        service.normalizeSoundLevelForTest(5.0, isAndroid: true),
        equals(0.5),
      );
      expect(
        service.normalizeSoundLevelForTest(-1.0, isAndroid: true),
        equals(0.0),
      );
    });

    test('normalizeSoundLevel clamps within 0.0-1.0 for iOS values', () {
      final service = SpeechRecognitionService();
      expect(
        service.normalizeSoundLevelForTest(0.0, isAndroid: false),
        equals(1.0),
      );
      expect(
        service.normalizeSoundLevelForTest(-25.0, isAndroid: false),
        equals(0.5),
      );
      expect(
        service.normalizeSoundLevelForTest(-60.0, isAndroid: false),
        equals(0.0),
      );
    });
  });

  group('SpeechRecognitionService - initialize with mock', () {
    late _MockSpeechToText mockSpeech;
    late SpeechRecognitionService service;

    setUp(() {
      mockSpeech = _MockSpeechToText();
      service = SpeechRecognitionService(speech: mockSpeech);
    });

    test('initialize returns true when plugin initializes successfully',
        () async {
      when(() => mockSpeech.initialize(
            onStatus: any(named: 'onStatus'),
            onError: any(named: 'onError'),
            debugLogging: any(named: 'debugLogging'),
          )).thenAnswer((_) async => true);

      final result = await service.initialize();

      expect(result, isTrue);
      expect(service.isAvailable, isTrue);
    });

    test('getAvailableLocales returns empty list when not initialized',
        () async {
      final locales = await service.getAvailableLocales();
      expect(locales, isEmpty);
    });

    test('getAvailableLocales returns locales when initialized', () async {
      when(() => mockSpeech.initialize(
            onStatus: any(named: 'onStatus'),
            onError: any(named: 'onError'),
            debugLogging: any(named: 'debugLogging'),
          )).thenAnswer((_) async => true);
      when(() => mockSpeech.locales())
          .thenAnswer((_) async => <stt.LocaleName>[]);

      await service.initialize();
      final locales = await service.getAvailableLocales();

      expect(locales, isA<List<stt.LocaleName>>());
      verify(() => mockSpeech.locales()).called(1);
    });
  });

  group('restartListen', () {
    late _MockSpeechToText mockSpeech;
    late SpeechRecognitionService service;
    late int onResultCalls;
    late int onSoundLevelCalls;
    void onResultStub(SpeechRecognitionResult r) => onResultCalls++;
    void onSoundLevelStub(double l) => onSoundLevelCalls++;

    setUp(() {
      mockSpeech = _MockSpeechToText();
      service = SpeechRecognitionService(speech: mockSpeech);
      onResultCalls = 0;
      onSoundLevelCalls = 0;
    });

    test('returns false when no prior startListening and not initialized',
        () async {
      when(() => mockSpeech.isListening).thenReturn(false);

      expect(await service.restartListen(), isFalse);
      verifyNever(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          ));
    });

    test(
        'returns false when config cached but initialize was never successful',
        () async {
      when(() => mockSpeech.isListening).thenReturn(false);

      // startListening caches config but _isInitialized stays false
      await service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'ja-JP',
      );

      expect(await service.restartListen(), isFalse);
      verifyNever(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          ));
    });

    test(
        'after successful initialize+startListening, restartListen reopens listen() once when idle',
        () async {
      when(() => mockSpeech.initialize(
            onStatus: any(named: 'onStatus'),
            onError: any(named: 'onError'),
            debugLogging: any(named: 'debugLogging'),
          )).thenAnswer((_) async => true);
      when(() => mockSpeech.isListening).thenReturn(false);
      when(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).thenAnswer((_) async {});

      await service.initialize();
      await service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'ja-JP',
      );

      final ok = await service.restartListen();

      expect(ok, isTrue);
      // listen() called twice: once in startListening, once in restartListen
      verify(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: 'ja-JP',
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).called(2);
      // No cancel needed when idle
      verifyNever(() => mockSpeech.cancel());
    });

    test('Pitfall 3 mitigation: cancels first when isListening is true',
        () async {
      when(() => mockSpeech.initialize(
            onStatus: any(named: 'onStatus'),
            onError: any(named: 'onError'),
            debugLogging: any(named: 'debugLogging'),
          )).thenAnswer((_) async => true);

      // isListening returns true when restartListen checks it (simulating mid-session state).
      // startListening does not call isListening, so the first isListening call comes from
      // restartListen — return true to trigger the cancel-before-listen path.
      when(() => mockSpeech.isListening).thenReturn(true);
      when(() => mockSpeech.cancel()).thenAnswer((_) async {});
      when(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).thenAnswer((_) async {});

      await service.initialize();
      await service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'zh-CN',
      );

      final ok = await service.restartListen();

      expect(ok, isTrue);
      verify(() => mockSpeech.cancel()).called(1);
      verify(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).called(greaterThanOrEqualTo(1));
    });

    test('repeated restartListen calls use same cached config', () async {
      when(() => mockSpeech.initialize(
            onStatus: any(named: 'onStatus'),
            onError: any(named: 'onError'),
            debugLogging: any(named: 'debugLogging'),
          )).thenAnswer((_) async => true);
      when(() => mockSpeech.isListening).thenReturn(false);
      when(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: any(named: 'localeId'),
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).thenAnswer((_) async {});

      await service.initialize();
      await service.startListening(
        onResult: onResultStub,
        onSoundLevel: onSoundLevelStub,
        localeId: 'ja-JP',
      );

      // Restart 3 times
      expect(await service.restartListen(), isTrue);
      expect(await service.restartListen(), isTrue);
      expect(await service.restartListen(), isTrue);

      // listen() called 4 times total: 1 from startListening + 3 from restartListen
      verify(() => mockSpeech.listen(
            onResult: any(named: 'onResult'),
            localeId: 'ja-JP',
            listenFor: any(named: 'listenFor'),
            pauseFor: any(named: 'pauseFor'),
            onSoundLevelChange: any(named: 'onSoundLevelChange'),
            listenOptions: any(named: 'listenOptions'),
          )).called(4);
      verifyNever(() => mockSpeech.cancel());
    });
  });
}
