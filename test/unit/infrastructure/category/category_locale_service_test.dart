import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/category/category_locale_service.dart';

void main() {
  group('CategoryLocaleService', () {
    test(
      'resolve preserves existing Japanese category labels after rename',
      () {
        expect(
          CategoryLocaleService.resolve('category_food', const Locale('ja')),
          '食費',
        );
      },
    );

    test(
      'resolve returns translated category labels for supported locales',
      () {
        expect(
          CategoryLocaleService.resolve('category_food', const Locale('ja')),
          '食費',
        );
        expect(
          CategoryLocaleService.resolve('category_food', const Locale('zh')),
          '食费',
        );
        expect(
          CategoryLocaleService.resolve('category_food', const Locale('en')),
          'Food',
        );
      },
    );

    test('resolveFromId resolves category IDs through the static map', () {
      expect(
        CategoryLocaleService.resolveFromId('cat_food', const Locale('zh')),
        '食费',
      );
    });

    test('unsupported locale codes fall back to English labels', () {
      expect(
        CategoryLocaleService.resolve('category_food', const Locale('fr')),
        'Food',
      );
      expect(
        CategoryLocaleService.resolveFromId(
          'cat_food_other',
          const Locale('fr'),
        ),
        'Other Food',
      );
    });

    test('unknown keys and non-system IDs passthrough unchanged', () {
      expect(
        CategoryLocaleService.resolve(
          'unknown_category_name',
          const Locale('ja'),
        ),
        'unknown_category_name',
      );
      expect(
        CategoryLocaleService.resolveFromId(
          'custom_category',
          const Locale('zh'),
        ),
        'custom_category',
      );
    });
  });
}
