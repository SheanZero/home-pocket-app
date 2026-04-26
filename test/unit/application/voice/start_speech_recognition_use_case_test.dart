import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/start_speech_recognition_use_case.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSpeechRecognitionService extends Mock
    implements SpeechRecognitionService {}

void main() {
  late _MockSpeechRecognitionService mockService;
  late StartSpeechRecognitionUseCase useCase;

  setUp(() {
    mockService = _MockSpeechRecognitionService();
    useCase = StartSpeechRecognitionUseCase(service: mockService);
  });

  group('StartSpeechRecognitionUseCase', () {
    test('initialize returns true when service initializes successfully', () async {
      when(
        () => mockService.initialize(
          onStatus: any(named: 'onStatus'),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((_) async => true);

      final result = await useCase.initialize();

      expect(result, isTrue);
    });

    test('initialize returns false when service initialization fails', () async {
      when(
        () => mockService.initialize(
          onStatus: any(named: 'onStatus'),
          onError: any(named: 'onError'),
        ),
      ).thenAnswer((_) async => false);

      final result = await useCase.initialize();

      expect(result, isFalse);
    });

    test('startListening delegates to service with correct localeId', () async {
      when(
        () => mockService.startListening(
          onResult: any(named: 'onResult'),
          onSoundLevel: any(named: 'onSoundLevel'),
          localeId: any(named: 'localeId'),
        ),
      ).thenAnswer((_) async {});

      await useCase.startListening(
        localeId: 'ja-JP',
        onResult: (_) {},
        onSoundLevel: (_) {},
      );

      verify(
        () => mockService.startListening(
          onResult: any(named: 'onResult'),
          onSoundLevel: any(named: 'onSoundLevel'),
          localeId: 'ja-JP',
        ),
      ).called(1);
    });

    test('stopListening delegates to service', () async {
      when(() => mockService.stopListening()).thenAnswer((_) async {});

      await useCase.stop();

      verify(() => mockService.stopListening()).called(1);
    });

    test('isListening delegates to service', () {
      when(() => mockService.isListening).thenReturn(true);

      expect(useCase.isListening, isTrue);
    });

    test('cancel delegates to service cancelListening', () async {
      when(() => mockService.cancelListening()).thenAnswer((_) async {});

      await useCase.cancel();

      verify(() => mockService.cancelListening()).called(1);
    });

    test('isAvailable delegates to service', () {
      when(() => mockService.isAvailable).thenReturn(false);

      expect(useCase.isAvailable, isFalse);
    });
  });
}
