import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/levenshtein.dart';

void main() {
  group('levenshteinDistance', () {
    test('identical strings return 0', () {
      expect(levenshteinDistance('abc', 'abc'), 0);
    });

    test('empty vs non-empty returns length', () {
      expect(levenshteinDistance('', 'abc'), 3);
      expect(levenshteinDistance('abc', ''), 3);
    });

    test('both empty returns 0', () {
      expect(levenshteinDistance('', ''), 0);
    });

    test('single insertion', () {
      expect(levenshteinDistance('abc', 'abcd'), 1);
    });

    test('single deletion', () {
      expect(levenshteinDistance('abcd', 'abc'), 1);
    });

    test('single substitution', () {
      expect(levenshteinDistance('abc', 'axc'), 1);
    });

    test('kitten vs sitting = 3', () {
      expect(levenshteinDistance('kitten', 'sitting'), 3);
    });

    test('Japanese strings', () {
      // 朝ごはん vs 朝御飯 (speech recognition error)
      expect(levenshteinDistance('朝ごはん', '朝御飯'), 3);
    });

    test('Chinese strings', () {
      // 咖啡 vs 咖啡厅
      expect(levenshteinDistance('咖啡', '咖啡厅'), 1);
    });
  });

  group('normalizedSimilarity', () {
    test('identical strings return 1.0', () {
      expect(normalizedSimilarity('abc', 'abc'), 1.0);
    });

    test('both empty returns 1.0', () {
      expect(normalizedSimilarity('', ''), 1.0);
    });

    test('completely different returns 0.0', () {
      expect(normalizedSimilarity('abc', 'xyz'), 0.0);
    });

    test('one empty returns 0.0', () {
      expect(normalizedSimilarity('abc', ''), 0.0);
    });

    test('咖啡 vs 咖啡厅 similarity ~0.67', () {
      final sim = normalizedSimilarity('咖啡', '咖啡厅');
      expect(sim, closeTo(0.667, 0.01));
    });

    test('lunch vs lunhc (typo) similarity = 0.6', () {
      final sim = normalizedSimilarity('lunch', 'lunhc');
      expect(sim, closeTo(0.6, 0.01));
    });
  });
}
