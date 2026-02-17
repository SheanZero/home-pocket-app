import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is #8AB8DA', () {
      expect(AppColors.primary, const Color(0xFF8AB8DA));
    });

    test('survival is #5A9CC8', () {
      expect(AppColors.survival, const Color(0xFF5A9CC8));
    });

    test('soul is #47B88A', () {
      expect(AppColors.soul, const Color(0xFF47B88A));
    });

    test('background is #F1F7FD', () {
      expect(AppColors.background, const Color(0xFFF1F7FD));
    });

    test('card is white', () {
      expect(AppColors.card, const Color(0xFFFFFFFF));
    });

    test('textPrimary is #2C2C2C', () {
      expect(AppColors.textPrimary, const Color(0xFF2C2C2C));
    });
  });
}
