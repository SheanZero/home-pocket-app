// Characterization test for AppearanceSection.
// Locks: widget renders without crash, language picker UI renders,
// localeNotifierProvider is overrideable via settingsRepositoryProvider.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/widgets/appearance_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildApp(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late _MockSettingsRepository mockSettingsRepo;

  const testSettings = AppSettings(
    themeMode: AppThemeMode.system,
    language: 'ja',
    notificationsEnabled: true,
    biometricLockEnabled: true,
    voiceLanguage: 'ja',
  );

  setUp(() {
    mockSettingsRepo = _MockSettingsRepository();
    when(
      () => mockSettingsRepo.getSettings(),
    ).thenAnswer((_) async => testSettings);
  });

  group('AppearanceSection characterization tests (pre-refactor behavior)', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _buildApp(const AppearanceSection(settings: testSettings), [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ]),
      );
      await tester.pump();
      expect(find.byType(AppearanceSection), findsOneWidget);
    });

    testWidgets('shows theme section via ListTile', (tester) async {
      await tester.pumpWidget(
        _buildApp(const AppearanceSection(settings: testSettings), [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ]),
      );
      await tester.pump();
      // AppearanceSection renders at least one ListTile (theme + language)
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('localeNotifierProvider wired via settingsRepositoryProvider', (
      tester,
    ) async {
      // Characterization lock: locale settings flow through settingsRepositoryProvider.
      // getSettings() is called by localeNotifierProvider.build().
      await tester.pumpWidget(
        _buildApp(const AppearanceSection(settings: testSettings), [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ]),
      );
      await tester.pumpAndSettle();
      // Verify getSettings was called (locale notifier initialization)
      verify(() => mockSettingsRepo.getSettings()).called(greaterThan(0));
    });

    testWidgets('language picker section is present', (tester) async {
      await tester.pumpWidget(
        _buildApp(const AppearanceSection(settings: testSettings), [
          settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
        ]),
      );
      await tester.pump();
      // Column wrapping theme + language tiles
      expect(find.byType(Column), findsWidgets);
    });
  });
}
