import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('accentPrimary is #E85A4F', () {
      expect(AppColors.accentPrimary, const Color(0xFFE85A4F));
    });

    test('survival is #5A9CC8', () {
      expect(AppColors.survival, const Color(0xFF5A9CC8));
    });

    test('soul is #47B88A', () {
      expect(AppColors.soul, const Color(0xFF47B88A));
    });

    test('background is #FCFBF9', () {
      expect(AppColors.background, const Color(0xFFFCFBF9));
    });

    test('card is white', () {
      expect(AppColors.card, const Color(0xFFFFFFFF));
    });

    test('textPrimary is #1E2432', () {
      expect(AppColors.textPrimary, const Color(0xFF1E2432));
    });
  });
}
