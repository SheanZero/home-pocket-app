import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';

void main() {
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
}
