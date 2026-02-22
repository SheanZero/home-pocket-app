import 'dart:math';

import '../../features/accounting/domain/models/voice_parse_result.dart';

/// Voice satisfaction estimator for Soul Ledger transactions.
///
/// Analyzes audio features and recognized text to estimate user satisfaction
/// on a 1–10 scale. Used only for Soul Ledger transactions.
///
/// Technical limitations:
/// - speech_to_text only provides volume data, not pitch (Hz)
/// - Android and iOS volume values differ; they are normalized to 0.0–1.0 before
///   being passed to this estimator
/// - This is an approximation, not precise sentiment analysis
class VoiceSatisfactionEstimator {
  /// Estimates satisfaction (1–10) from audio features and recognized text.
  ///
  /// [audioFeatures] contains sound levels, timestamps, and word counts
  /// collected during voice recording.
  /// [recognizedText] is the final recognized text string.
  int estimate({
    required VoiceAudioFeatures audioFeatures,
    required String recognizedText,
  }) {
    // Individual signal scores (0.0 ~ 1.0)
    final volumeScore = _analyzeVolume(audioFeatures.soundLevels);
    final varianceScore = _analyzeVolumeVariance(audioFeatures.soundLevels);
    final speechRateScore = _analyzeSpeechRate(audioFeatures);
    final sentimentScore = _analyzeSentiment(recognizedText);
    final durationScore = _analyzeDuration(audioFeatures);

    // Weighted average
    final weightedScore = volumeScore * 0.25 +
        varianceScore * 0.25 +
        speechRateScore * 0.20 +
        sentimentScore * 0.20 +
        durationScore * 0.10;

    // Map to 1–10 range using an S-curve that favors the middle range
    final satisfaction = _mapToSatisfaction(weightedScore);

    return satisfaction.clamp(1, 10);
  }

  /// Analyzes average volume (0.0 ~ 1.0).
  ///
  /// Louder voice → more excited/happy.
  double _analyzeVolume(List<double> levels) {
    if (levels.isEmpty) return 0.3;

    // Filter out silent frames (< 0.05)
    final activeLevels = levels.where((l) => l > 0.05).toList();
    if (activeLevels.isEmpty) return 0.3;

    final avg = activeLevels.reduce((a, b) => a + b) / activeLevels.length;
    // Normal speech ~0.3–0.5, excited ~0.6–0.8
    return (avg / 0.8).clamp(0.0, 1.0);
  }

  /// Analyzes volume variance (0.0 ~ 1.0).
  ///
  /// Higher variance → more emotional speech.
  double _analyzeVolumeVariance(List<double> levels) {
    if (levels.length < 3) return 0.3;

    final activeLevels = levels.where((l) => l > 0.05).toList();
    if (activeLevels.length < 3) return 0.3;

    final mean = activeLevels.reduce((a, b) => a + b) / activeLevels.length;
    final variance = activeLevels
            .map((l) => (l - mean) * (l - mean))
            .reduce((a, b) => a + b) /
        activeLevels.length;
    final stdDev = sqrt(variance);

    // Normal stdDev ~0.05, emotional ~0.15+
    return (stdDev / 0.2).clamp(0.0, 1.0);
  }

  /// Analyzes speech rate (0.0 ~ 1.0).
  ///
  /// Faster speech → more excited.
  double _analyzeSpeechRate(VoiceAudioFeatures features) {
    final durationSecs =
        features.endTime.difference(features.startTime).inMilliseconds / 1000.0;

    if (durationSecs <= 0 || features.wordCount <= 0) return 0.3;

    final wordsPerSecond = features.wordCount / durationSecs;

    // Normal: ~3–5 words/sec, excited: ~6–8 words/sec
    return ((wordsPerSecond - 2.0) / 6.0).clamp(0.0, 1.0);
  }

  /// Analyzes text sentiment (0.0 ~ 1.0).
  ///
  /// Detects positive and negative words in Japanese, Chinese, and English.
  double _analyzeSentiment(String text) {
    var score = 0.5; // Start at neutral

    const positiveWords = [
      // Japanese
      '嬉しい', 'うれしい', '楽しい', 'たのしい', '最高', 'すごい',
      'いい', '良い', '好き', 'すき', '満足', '幸せ', 'しあわせ',
      'やった', 'ありがたい', '美味しい', 'おいしい', 'きれい',
      'かわいい', '素敵', 'すてき', 'ワクワク', 'ドキドキ',
      // Chinese
      '开心', '高兴', '太好了', '喜欢', '满意', '幸福', '棒',
      '好吃', '漂亮', '值得', '超级', '很爽', '不错',
      // English
      'happy', 'great', 'awesome', 'love', 'amazing', 'wonderful',
      'excellent', 'fantastic', 'nice', 'good', 'perfect',
    ];

    const negativeWords = [
      // Japanese
      '高い', 'たかい', '無駄', 'むだ', 'もったいない',
      '後悔', 'こうかい', '失敗', 'しっぱい',
      // Chinese
      '贵', '浪费', '后悔', '亏', '不值',
      // English
      'expensive', 'waste', 'regret', 'overpriced',
    ];

    const intensifiers = [
      'めっちゃ', 'すごく', 'とても', 'マジ', 'ほんと',
      '超', '非常', '特别', '太', 'really', 'very', 'so',
    ];

    final lowerText = text.toLowerCase();
    var hasIntensifier = false;

    for (final word in intensifiers) {
      if (lowerText.contains(word.toLowerCase())) {
        hasIntensifier = true;
        break;
      }
    }

    for (final word in positiveWords) {
      if (lowerText.contains(word.toLowerCase())) {
        score += hasIntensifier ? 0.20 : 0.12;
      }
    }

    for (final word in negativeWords) {
      if (lowerText.contains(word.toLowerCase())) {
        score -= hasIntensifier ? 0.15 : 0.10;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Analyzes speech duration (0.0 ~ 1.0).
  ///
  /// Longer speech → more to say → deeper feeling.
  double _analyzeDuration(VoiceAudioFeatures features) {
    final durationSecs =
        features.endTime.difference(features.startTime).inSeconds;

    if (durationSecs < 3) return 0.2;
    if (durationSecs < 5) return 0.4;
    if (durationSecs < 10) return 0.6;
    if (durationSecs < 15) return 0.8;
    return 1.0;
  }

  /// Maps a 0.0–1.0 score to 1–10 satisfaction range.
  ///
  /// Uses a slight upward bias since a purchase is generally a positive act.
  int _mapToSatisfaction(double score) {
    // Minimum ~0.3 → satisfaction 3
    final adjusted = 0.3 + score * 0.7;
    return (adjusted * 10).round().clamp(1, 10);
  }
}
