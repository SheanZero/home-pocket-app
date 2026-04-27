import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/category/category_locale_service.dart';

void main() {
  group('CategoryLocaleService', () {
    test('resolve preserves existing Japanese category labels after rename', () {
      expect(
        CategoryLocaleService.resolve('category_food', const Locale('ja')),
        '食費',
      );
    });
  });
}
