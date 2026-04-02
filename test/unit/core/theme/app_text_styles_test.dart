import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles Wa-Modern', () {
    test('font family is Outfit', () {
      expect(AppTextStyles.headlineLarge.fontFamily, 'Outfit');
    });

    test('headlineLarge is 30px bold', () {
      expect(AppTextStyles.headlineLarge.fontSize, 30);
      expect(AppTextStyles.headlineLarge.fontWeight, FontWeight.w700);
    });

    test('headlineMedium is 24px bold', () {
      expect(AppTextStyles.headlineMedium.fontSize, 24);
      expect(AppTextStyles.headlineMedium.fontWeight, FontWeight.w700);
    });

    test('titleMedium is 15px semibold', () {
      expect(AppTextStyles.titleMedium.fontSize, 15);
      expect(AppTextStyles.titleMedium.fontWeight, FontWeight.w600);
    });

    test('amountLarge is 30px bold with tabular figures', () {
      expect(AppTextStyles.amountLarge.fontSize, 30);
      expect(AppTextStyles.amountLarge.fontWeight, FontWeight.w700);
      expect(AppTextStyles.amountLarge.fontFeatures, isNotEmpty);
    });

    test('navLabel uses DM Sans', () {
      expect(AppTextStyles.navLabel.fontFamily, 'DM Sans');
      expect(AppTextStyles.navLabel.fontSize, 9);
    });
  });
}
