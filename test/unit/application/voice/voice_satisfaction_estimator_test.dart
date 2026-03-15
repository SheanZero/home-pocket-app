import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

List<DateTime> _generateTimestamps(int count, {int intervalMs = 200}) {
  final start = DateTime.now().subtract(
    Duration(milliseconds: count * intervalMs),
  );
  return List.generate(
    count,
    (i) => start.add(Duration(milliseconds: i * intervalMs)),
  );
}

void main() {
  late VoiceSatisfactionEstimator estimator;

  setUp(() {
    estimator = VoiceSatisfactionEstimator();
  });

  group('VoiceSatisfactionEstimator', () {
    test('excited voice with positive words -> satisfaction 7-10', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.7, 0.8, 0.6, 0.9, 0.7, 0.8, 0.9, 0.7],
        timestamps: _generateTimestamps(8, intervalMs: 200),
        startTime: DateTime.now().subtract(const Duration(seconds: 8)),
        endTime: DateTime.now(),
        partialResultCount: 6,
        wordCount: 15,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: 'ユニクロで服買った、めっちゃ嬉しい！',
      );

      expect(score, greaterThanOrEqualTo(7));
      expect(score, lessThanOrEqualTo(10));
    });

    test('calm voice with neutral text -> satisfaction 4-6', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.35, 0.3, 0.32, 0.3],
        timestamps: _generateTimestamps(5, intervalMs: 400),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '電車代320円',
      );

      expect(score, greaterThanOrEqualTo(4));
      expect(score, lessThanOrEqualTo(6));
    });

    test('empty audio features -> default satisfaction 3-5', () {
      final features = VoiceAudioFeatures(
        soundLevels: [],
        timestamps: [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 0,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '',
      );

      expect(score, greaterThanOrEqualTo(3));
      expect(score, lessThanOrEqualTo(5));
    });

    test('score is always in range 1-10', () {
      final highFeatures = VoiceAudioFeatures(
        soundLevels: List.filled(50, 1.0),
        timestamps: _generateTimestamps(50, intervalMs: 100),
        startTime: DateTime.now().subtract(const Duration(seconds: 20)),
        endTime: DateTime.now(),
        partialResultCount: 20,
        wordCount: 40,
      );
      final highScore = estimator.estimate(
        audioFeatures: highFeatures,
        recognizedText: 'めっちゃ最高！嬉しい！すごい！',
      );
      expect(highScore, inInclusiveRange(1, 10));

      final lowFeatures = VoiceAudioFeatures(
        soundLevels: [0.01, 0.01],
        timestamps: _generateTimestamps(2, intervalMs: 500),
        startTime: DateTime.now().subtract(const Duration(seconds: 2)),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 1,
      );
      final lowScore = estimator.estimate(
        audioFeatures: lowFeatures,
        recognizedText: '高い無駄だった後悔',
      );
      expect(lowScore, inInclusiveRange(1, 10));
    });

    test('negative sentiment words reduce score', () {
      final neutralFeatures = VoiceAudioFeatures(
        soundLevels: [0.4, 0.4, 0.4],
        timestamps: _generateTimestamps(3, intervalMs: 300),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final neutralScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '昼ごはん680円',
      );

      final negativeScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '高い、無駄だった、後悔してる',
      );

      expect(negativeScore, lessThan(neutralScore));
    });
  });
}
