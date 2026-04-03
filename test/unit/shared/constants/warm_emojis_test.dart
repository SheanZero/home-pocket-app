import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/constants/warm_emojis.dart';

void main() {
  group('warmEmojis', () {
    test('contains exactly 24 emojis', () {
      expect(warmEmojis.length, 24);
    });

    test('has no duplicates', () {
      expect(warmEmojis.toSet().length, warmEmojis.length);
    });

    test('randomWarmEmoji returns an emoji from the list', () {
      for (var i = 0; i < 10; i++) {
        expect(warmEmojis.contains(randomWarmEmoji()), isTrue);
      }
    });
  });
}
