import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

void main() {
  group('VoiceParseResult', () {
    test('can be instantiated with rawText only', () {
      const result = VoiceParseResult(rawText: 'test text');
      expect(result.rawText, equals('test text'));
      expect(result.amount, isNull);
      expect(result.merchantName, isNull);
    });

    test('estimatedSatisfaction defaults to 5', () {
      const result = VoiceParseResult(rawText: 'test');
      expect(result.estimatedSatisfaction, equals(5));
    });

    test('copyWith works correctly', () {
      const original = VoiceParseResult(rawText: 'original', amount: 100);
      final copy = original.copyWith(amount: 200);
      expect(copy.rawText, equals('original'));
      expect(copy.amount, equals(200));
    });
  });

  group('VoiceAudioFeatures', () {
    test('can be instantiated with all required fields', () {
      final now = DateTime.now();
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.5, 0.7],
        timestamps: [now, now.add(const Duration(milliseconds: 100))],
        startTime: now,
        endTime: now.add(const Duration(seconds: 3)),
        partialResultCount: 2,
        wordCount: 5,
      );
      expect(features.soundLevels, hasLength(3));
      expect(features.wordCount, equals(5));
    });
  });

  group('CategoryMatchResult', () {
    test('stores categoryId, confidence, and source', () {
      const matchResult = CategoryMatchResult(
        categoryId: 'cat_food',
        confidence: 0.90,
        source: MatchSource.keyword,
      );
      expect(matchResult.categoryId, equals('cat_food'));
      expect(matchResult.confidence, equals(0.90));
      expect(matchResult.source, equals(MatchSource.keyword));
    });
  });

  group('MatchSource', () {
    test('has all three values', () {
      expect(MatchSource.values, containsAll([
        MatchSource.merchant,
        MatchSource.keyword,
        MatchSource.fallback,
      ]));
    });
  });
}
