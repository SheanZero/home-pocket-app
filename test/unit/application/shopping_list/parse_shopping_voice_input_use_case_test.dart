import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/shopping_list/parse_shopping_voice_input_use_case.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  const useCase = ParseShoppingVoiceInputUseCase();

  group('ParseShoppingVoiceInputUseCase', () {
    test('parses the Japanese mockup utterance', () {
      const rawText = '牛乳を2本、日常、参考価格500円';

      final draft = useCase.execute(rawText, localeId: 'ja-JP');

      expect(draft.rawText, rawText);
      expect(draft.name, '牛乳');
      expect(draft.quantity, 2);
      expect(draft.ledgerType, LedgerType.daily);
      expect(draft.categoryId, 'cat_food_groceries');
      expect(draft.estimatedPrice, 500);
    });

    test('parses an equivalent natural Chinese utterance', () {
      const rawText = '买两瓶牛奶，日常，参考价格20元';

      final draft = useCase.execute(rawText, localeId: 'zh-CN');

      expect(draft.rawText, rawText);
      expect(draft.name, '牛奶');
      expect(draft.quantity, 2);
      expect(draft.ledgerType, LedgerType.daily);
      expect(draft.categoryId, 'cat_food_groceries');
      expect(draft.estimatedPrice, 20);
    });

    test('parses an equivalent natural English utterance', () {
      const rawText = 'Add two bottles of milk, daily, estimated price 500 yen';

      final draft = useCase.execute(rawText, localeId: 'en-US');

      expect(draft.rawText, rawText);
      expect(draft.name, 'milk');
      expect(draft.quantity, 2);
      expect(draft.ledgerType, LedgerType.daily);
      expect(draft.categoryId, 'cat_food_groceries');
      expect(draft.estimatedPrice, 500);
    });

    test('recognizes Japanese joy wording without deriving privacy', () {
      final draft = useCase.execute(
        'コーヒー豆を1袋、ときめき、参考価格1280円',
        localeId: 'ja-JP',
      );

      expect(draft.name, 'コーヒー豆');
      expect(draft.quantity, 1);
      expect(draft.ledgerType, LedgerType.joy);
      expect(draft.categoryId, 'cat_food_cafe');
      expect(draft.estimatedPrice, 1280);
    });

    test('recognizes Chinese joy wording', () {
      final draft = useCase.execute('买一盒巧克力，悦己，参考价格35元', localeId: 'zh-TW');

      expect(draft.name, '巧克力');
      expect(draft.quantity, 1);
      expect(draft.ledgerType, LedgerType.joy);
      expect(draft.estimatedPrice, 35);
    });

    for (final testCase in const [
      (
        description: 'simplified',
        localeId: 'zh-CN',
        rawText: '买一盒巧克力，犒劳自己，参考价格35元',
      ),
      (
        description: 'traditional',
        localeId: 'zh-TW',
        rawText: '買一盒巧克力，犒勞自己，參考價格35元',
      ),
    ]) {
      test(
        'recognizes and removes ${testCase.description} reward-yourself wording',
        () {
          final draft = useCase.execute(
            testCase.rawText,
            localeId: testCase.localeId,
          );

          expect(draft.name, '巧克力');
          expect(draft.quantity, 1);
          expect(draft.ledgerType, LedgerType.joy);
          expect(draft.estimatedPrice, 35);
        },
      );
    }

    test('recognizes English joy wording', () {
      final draft = useCase.execute(
        'Add one puzzle, joy, estimated price 2500 JPY',
        localeId: 'en-GB',
      );

      expect(draft.name, 'puzzle');
      expect(draft.quantity, 1);
      expect(draft.ledgerType, LedgerType.joy);
      expect(draft.estimatedPrice, 2500);
    });

    test('treats an unqualified English price as the local JPY amount', () {
      final draft = useCase.execute(
        'Add milk, estimated price 500',
        localeId: 'en-US',
      );

      expect(draft.name, 'milk');
      expect(draft.estimatedPrice, 500);
    });

    for (final foreignPrice in const [
      r'estimated price $5',
      'estimated price 5 dollars',
      'estimated price 5 USD',
      'estimated price £5',
      'estimated price 5 GBP',
      'estimated price €5',
      'estimated price 5 EUR',
    ]) {
      test(
        'ignores foreign-currency amount without an exchange rate: $foreignPrice',
        () {
          final draft = useCase.execute(
            'Add milk, $foreignPrice',
            localeId: 'en-US',
          );

          expect(draft.name, 'milk');
          expect(draft.estimatedPrice, isNull);
        },
      );
    }

    test('keeps absent optional fields null instead of inventing defaults', () {
      final draft = useCase.execute('牛乳', localeId: 'ja-JP');

      expect(draft.name, '牛乳');
      expect(draft.quantity, isNull);
      expect(draft.ledgerType, isNull);
      expect(draft.categoryId, 'cat_food_groceries');
      expect(draft.estimatedPrice, isNull);
    });

    test(
      'does not manufacture a name or category from metadata-only input',
      () {
        final draft = useCase.execute('日常、参考価格500円', localeId: 'ja-JP');

        expect(draft.name, isNull);
        expect(draft.quantity, isNull);
        expect(draft.ledgerType, LedgerType.daily);
        expect(draft.categoryId, isNull);
        expect(draft.estimatedPrice, 500);
      },
    );

    test('returns an empty safe draft for blank input', () {
      const rawText = '   ';

      final draft = useCase.execute(rawText, localeId: 'zh-CN');

      expect(draft.rawText, rawText);
      expect(draft.name, isNull);
      expect(draft.quantity, isNull);
      expect(draft.ledgerType, isNull);
      expect(draft.categoryId, isNull);
      expect(draft.estimatedPrice, isNull);
    });

    test('leaves conflicting ledger wording unresolved', () {
      final draft = useCase.execute(
        'Add milk, daily and joy',
        localeId: 'en-US',
      );

      expect(draft.name, 'milk');
      expect(draft.ledgerType, isNull);
    });

    test('leaves unsupported locales unparsed but preserves raw text', () {
      const rawText = 'Ajouter deux bouteilles de lait';

      final draft = useCase.execute(rawText, localeId: 'fr-FR');

      expect(draft.rawText, rawText);
      expect(draft.name, isNull);
      expect(draft.quantity, isNull);
      expect(draft.ledgerType, isNull);
      expect(draft.categoryId, isNull);
      expect(draft.estimatedPrice, isNull);
    });

    for (final foreignPrice in const [
      '参考価格5ドル',
      '参考価格5米ドル',
      r'参考価格$5',
      '参考価格5 USD',
      '参考価格5ポンド',
      '参考価格5ユーロ',
      '参考価格5人民元',
    ]) {
      test('ignores Japanese foreign-currency amount: $foreignPrice', () {
        final draft = useCase.execute('牛乳を1本、$foreignPrice', localeId: 'ja-JP');

        expect(draft.name, '牛乳');
        expect(draft.estimatedPrice, isNull);
      });
    }

    for (final foreignPrice in const [
      '参考价格5美元',
      '参考价格5欧元',
      '参考价格5人民币',
      '参考价格5英镑',
      '参考价格5韩元',
      r'参考价格$5',
      '参考价格5 USD',
    ]) {
      test('ignores Chinese foreign-currency amount: $foreignPrice', () {
        final draft = useCase.execute('买一瓶牛奶，$foreignPrice', localeId: 'zh-CN');

        expect(draft.name, '牛奶');
        expect(draft.estimatedPrice, isNull);
      });
    }

    test('keeps unqualified local prices for Japanese and Chinese', () {
      expect(
        useCase.execute('牛乳を1本、参考価格500', localeId: 'ja-JP').estimatedPrice,
        500,
      );
      expect(
        useCase.execute('买一瓶牛奶，参考价格500', localeId: 'zh-CN').estimatedPrice,
        500,
      );
    });
  });
}
