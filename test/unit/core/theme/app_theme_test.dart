import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
    });

    test('scaffold background is AppColors.background', () {
      final theme = AppTheme.light;
      expect(theme.scaffoldBackgroundColor, AppPalette.light.background);
    });

    test('text theme uses Outfit via default body style', () {
      final theme = AppTheme.light;
      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Outfit'));
    });
  });
}
