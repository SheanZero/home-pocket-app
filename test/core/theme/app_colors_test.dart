import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'dart:ui';

void main() {
  group('AppColors Wa-Modern light palette', () {
    test('background is warm ivory', () {
      expect(AppColors.background, const Color(0xFFFCFBF9));
    });
    test('accent primary is coral', () {
      expect(AppColors.accentPrimary, const Color(0xFFE85A4F));
    });
    test('text primary is dark', () {
      expect(AppColors.textPrimary, const Color(0xFF1E2432));
    });
    test('survival is blue', () {
      expect(AppColors.survival, const Color(0xFF5A9CC8));
    });
    test('soul is green', () {
      expect(AppColors.soul, const Color(0xFF47B88A));
    });
    test('border default is light gray', () {
      expect(AppColors.borderDefault, const Color(0xFFEFEFEF));
    });
    test('FAB gradient start is lighter coral', () {
      expect(AppColors.fabGradientStart, const Color(0xFFF08070));
    });
  });
}
