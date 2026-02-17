import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_colors.dart';
import 'package:home_pocket/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
    });

    test('scaffold background is AppColors.background', () {
      final theme = AppTheme.light;
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('text theme uses IBM Plex Sans via default body style', () {
      final theme = AppTheme.light;
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        contains('IBM Plex Sans'),
      );
    });
  });
}
