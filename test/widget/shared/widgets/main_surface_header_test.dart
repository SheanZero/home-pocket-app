import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_text_styles.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/shared/widgets/main_surface_header.dart';

void main() {
  testWidgets('owns the shared main-surface title and action geometry', (
    tester,
  ) async {
    var titleTaps = 0;
    var calendarTaps = 0;
    var settingsTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 390,
              child: MainSurfaceHeader(
                key: const Key('main-surface-header'),
                title: '2026年7月',
                titleKey: const Key('main-surface-title'),
                onTitleTap: () => titleTaps++,
                trailing: const SizedBox(
                  key: Key('main-surface-trailing'),
                  width: 34,
                  height: 27,
                ),
                actions: [
                  MainSurfaceHeaderAction(
                    key: const Key('calendar-action'),
                    icon: Icons.calendar_month_outlined,
                    tooltip: 'Month',
                    onPressed: () => calendarTaps++,
                  ),
                  MainSurfaceHeaderAction(
                    key: const Key('settings-action'),
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onPressed: () => settingsTaps++,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final header = find.byKey(const Key('main-surface-header'));
    final title = find.byKey(const Key('main-surface-title'));
    final calendarAction = find.byKey(const Key('calendar-action'));
    final settingsAction = find.byKey(const Key('settings-action'));
    final trailing = find.byKey(const Key('main-surface-trailing'));

    expect(tester.getSize(header), const Size(390, 46));
    expect(tester.getTopLeft(title).dx, 0);

    final titleStyle = tester.widget<Text>(title).style!;
    expect(titleStyle.fontSize, AppTypography.pageTitle);
    expect(
      titleStyle.height,
      AppTypography.pageTitleLineHeight / AppTypography.pageTitle,
    );
    expect(titleStyle.fontWeight, AppTypography.pageTitleWeight);

    expect(tester.getSize(calendarAction), const Size(40, 40));
    expect(tester.getSize(settingsAction), const Size(40, 40));
    expect(
      tester.getCenter(settingsAction).dx - tester.getCenter(calendarAction).dx,
      40,
    );
    expect(
      tester.getTopLeft(calendarAction).dx - tester.getTopRight(trailing).dx,
      9,
    );
    expect(
      tester.getSize(find.byIcon(Icons.calendar_month_outlined)),
      const Size(24, 24),
    );
    expect(
      tester.getSize(find.byIcon(Icons.settings_outlined)),
      const Size(24, 24),
    );

    await tester.tap(title);
    await tester.tap(calendarAction);
    await tester.tap(settingsAction);
    expect(titleTaps, 1);
    expect(calendarTaps, 1);
    expect(settingsTaps, 1);
  });
}
