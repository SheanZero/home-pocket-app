import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_palette.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/shared/widgets/app_sheet_frame.dart';

Widget _subject(ThemeData theme) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800)),
      child: Scaffold(
        body: AppSheetFrame(child: const Center(child: Text('Sheet content'))),
      ),
    ),
  );
}

void main() {
  group('AppSheetFrame', () {
    testWidgets(
      'uses the standard height, top corners, and light drag handle',
      (tester) async {
        await tester.pumpWidget(_subject(AppTheme.light));

        expect(tester.getSize(find.byType(AppSheetFrame)).height, 520);

        final frame = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(AppSheetFrame),
                matching: find.byType(Container),
              )
              .first,
        );
        final frameDecoration = frame.decoration! as BoxDecoration;
        expect(frameDecoration.color, AppPalette.light.background);
        expect(
          frameDecoration.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(16)),
        );

        final handle = find.descendant(
          of: find.byType(AppSheetDragHandle),
          matching: find.byType(Container),
        );
        expect(tester.getSize(handle), const Size(40, 4));
        final handleDecoration =
            tester.widget<Container>(handle).decoration! as BoxDecoration;
        expect(handleDecoration.color, AppPalette.light.borderDivider);
        expect(handleDecoration.borderRadius, BorderRadius.circular(2));
      },
    );

    testWidgets('resolves the drag handle color from the dark palette', (
      tester,
    ) async {
      await tester.pumpWidget(_subject(AppTheme.dark));

      final handle = find.descendant(
        of: find.byType(AppSheetDragHandle),
        matching: find.byType(Container),
      );
      final decoration =
          tester.widget<Container>(handle).decoration! as BoxDecoration;
      expect(decoration.color, AppPalette.dark.borderDivider);
    });
  });
}
