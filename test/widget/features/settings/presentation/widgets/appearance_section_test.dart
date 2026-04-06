import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/widgets/appearance_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildTestWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('AppearanceSection', () {
    late List<Override> overrides;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'language': 'ja'});
      final prefs = await SharedPreferences.getInstance();
      overrides = [
        sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
        settingsRepositoryProvider.overrideWith(
          (_) => SettingsRepositoryImpl(prefs: prefs),
        ),
      ];
    });

    testWidgets('shows language tile with current language', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: overrides,
          child: const AppearanceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('tapping language tile opens selection dialog',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: overrides,
          child: const AppearanceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Follow System'), findsOneWidget);
      // '日本語' appears both in the subtitle and in the dialog radio list
      expect(find.text('日本語'), findsAtLeast(1));
      expect(find.text('中文'), findsOneWidget);
      // 'English' appears both in the dialog radio and potentially elsewhere
      expect(find.text('English'), findsAtLeast(1));
      // Verify all 4 radio tiles exist in the dialog
      expect(find.byType(RadioListTile<String>), findsNWidgets(4));
    });
  });
}
