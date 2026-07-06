// Quick task 260706-kzr — magnitude-word ↔ digit-count guard (L1 pure function).
//
// `expectedDigitCountForAmount` pins the digit count a spoken magnitude word
// implies: highest anchor 千/仟/せん/ぜん/thousand → multiplier digits + 3;
// 万/萬/まん → multiplier digits + 4 (en has no ten-thousand word). Precision
// over recall: idioms (千万别/万一/成千上万), non-monetary tails (1万步),
// decimal multipliers (3.5千), bare zh 千 without a multiplier, and
// anchor-free digit runs (99999元) all yield null — the guard refuses to
// validate rather than risk a wrong expectation.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/amount_magnitude_guard.dart';

void main() {
  group('zh magnitude expressions → expected digit count', () {
    test('3千5百16元 → 4 (mixed arabic-kanji, currency anchored)', () {
      expect(expectedDigitCountForAmount('3千5百16元', localeId: 'zh-CN'), 4);
    });

    test('三千五百一十六元 → 4 (pure kanji)', () {
      expect(
        expectedDigitCountForAmount('三千五百一十六元', localeId: 'zh-CN'),
        4,
      );
    });

    test('三十五万 → 6 (万 anchor, end-of-string anchored)', () {
      expect(expectedDigitCountForAmount('三十五万', localeId: 'zh-CN'), 6);
    });

    test('3千516 → 4 (no currency suffix, end-of-string anchored)', () {
      expect(expectedDigitCountForAmount('3千516', localeId: 'zh-CN'), 4);
    });

    test('上个月3号 花了3千5百16元 → 4 (date 3号 does not interfere)', () {
      expect(
        expectedDigitCountForAmount('上个月3号 花了3千5百16元', localeId: 'zh-CN'),
        4,
      );
    });
  });

  group('ja magnitude expressions → expected digit count', () {
    test('一万二千円 → 5 (万 anchor, 千 in residue is not a second anchor)', () {
      expect(expectedDigitCountForAmount('一万二千円', localeId: 'ja-JP'), 5);
    });

    test('千円 → 4 (bare 千 defaults multiplier 1 when currency anchored)', () {
      expect(expectedDigitCountForAmount('千円', localeId: 'ja-JP'), 4);
    });

    test('千五百円 → 4 (bare 千 with residue)', () {
      expect(expectedDigitCountForAmount('千五百円', localeId: 'ja-JP'), 4);
    });

    test('五万円 → 5', () {
      expect(expectedDigitCountForAmount('五万円', localeId: 'ja-JP'), 5);
    });

    test('さんぜんえん → 4 (kana anchor + kana multiplier)', () {
      expect(expectedDigitCountForAmount('さんぜんえん', localeId: 'ja-JP'), 4);
    });
  });

  group('en magnitude expressions → expected digit count', () {
    test('three thousand five hundred sixteen dollars → 4', () {
      expect(
        expectedDigitCountForAmount(
          'three thousand five hundred sixteen dollars',
          localeId: 'en-US',
        ),
        4,
      );
    });

    test('thirty five thousand dollars → 5', () {
      expect(
        expectedDigitCountForAmount(
          'thirty five thousand dollars',
          localeId: 'en-US',
        ),
        5,
      );
    });

    test('a thousand yen → 4 (a/an multiplier = 1)', () {
      expect(
        expectedDigitCountForAmount('a thousand yen', localeId: 'en-US'),
        4,
      );
    });
  });

  group('precision over recall — all null', () {
    test('千万别乱花钱 → null (idiom; 千 as 万-multiplier parses 1000 > 999)', () {
      expect(
        expectedDigitCountForAmount('千万别乱花钱', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('万一有问题 → null (idiom; zh missing multiplier)', () {
      expect(
        expectedDigitCountForAmount('万一有问题', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('成千上万 → null (idiom; no numeric multiplier)', () {
      expect(
        expectedDigitCountForAmount('成千上万', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('走了1万步 → null (万 tail is neither numeric, currency, nor end)', () {
      expect(
        expectedDigitCountForAmount('走了1万步', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('3.5千元 → null (decimal multiplier)', () {
      expect(
        expectedDigitCountForAmount('3.5千元', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('zh bare 千 → null (no multiplier default outside ja)', () {
      expect(expectedDigitCountForAmount('千', localeId: 'zh-CN'), isNull);
      expect(expectedDigitCountForAmount('千元', localeId: 'zh-CN'), isNull);
    });

    test('thousands of people → null (plural is not the anchor word)', () {
      expect(
        expectedDigitCountForAmount('thousands of people', localeId: 'en-US'),
        isNull,
      );
    });

    test('99999元 → null (no magnitude word at all)', () {
      expect(
        expectedDigitCountForAmount('99999元', localeId: 'zh-CN'),
        isNull,
      );
    });

    test('conflicting anchored expressions → null (三千元和五万元)', () {
      expect(
        expectedDigitCountForAmount('三千元和五万元', localeId: 'zh-CN'),
        isNull,
      );
    });
  });
}
