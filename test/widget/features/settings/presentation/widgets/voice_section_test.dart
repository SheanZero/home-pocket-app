import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/widgets/voice_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Captures recognition-language updates while still persisting via the real
/// SharedPreferences implementation.
class _CapturingSettingsRepository extends SettingsRepositoryImpl {
  _CapturingSettingsRepository({required super.prefs});

  final List<String> voiceLanguageCalls = [];

  @override
  Future<void> setVoiceLanguage(String languageCode) async {
    voiceLanguageCalls.add(languageCode);
    await super.setVoiceLanguage(languageCode);
  }
}

Widget _buildTestWidget({
  required Widget child,
  required List<Override> overrides,
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
  group('VoiceSection - recognition language only', () {
    late _CapturingSettingsRepository repo;
    late List<Override> overrides;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = _CapturingSettingsRepository(prefs: prefs);
      overrides = [
        sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
        settingsRepositoryProvider.overrideWith((_) => repo),
      ];
    });

    testWidgets('renders only the recognition-language preference', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(settings: AppSettings(voiceLanguage: 'ja')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('settings-voice-language')),
        findsOneWidget,
      );
      expect(find.text('Recognition Language'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Allow cloud fallback'), findsNothing);
      expect(find.text('On-device recognition'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('selecting a language persists the new value', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(settings: AppSettings(voiceLanguage: 'ja')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('settings-voice-language')));
      await tester.pumpAndSettle();

      expect(find.text('日本語'), findsWidgets);
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();

      expect(repo.voiceLanguageCalls, ['zh']);
      final persisted = await repo.getSettings();
      expect(persisted.voiceLanguage, 'zh');
    });
  });
}
