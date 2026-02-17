import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';

void main() {
  group('AppTextStyles', () {
    test('headlineLarge is 24/w600', () {
      expect(AppTextStyles.headlineLarge.fontSize, 24);
      expect(AppTextStyles.headlineLarge.fontWeight, FontWeight.w600);
      expect(AppTextStyles.headlineLarge.fontFamily, 'IBM Plex Sans');
    });

    test('titleMedium is 14/w600', () {
      expect(AppTextStyles.titleMedium.fontSize, 14);
      expect(AppTextStyles.titleMedium.fontWeight, FontWeight.w600);
    });

    test('bodySmall is 12/normal', () {
      expect(AppTextStyles.bodySmall.fontSize, 12);
      expect(AppTextStyles.bodySmall.fontWeight, FontWeight.normal);
    });

    test('labelSmall is 10/w500', () {
      expect(AppTextStyles.labelSmall.fontSize, 10);
      expect(AppTextStyles.labelSmall.fontWeight, FontWeight.w500);
    });

    test('tabLabel is 10/w500', () {
      expect(AppTextStyles.tabLabel.fontSize, 10);
      expect(AppTextStyles.tabLabel.fontWeight, FontWeight.w500);
    });
  });
}
