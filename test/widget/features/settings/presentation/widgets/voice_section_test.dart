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

/// Captures every [setVoiceAllowOnDeviceFallback] call while still persisting
/// via the real SharedPreferences impl (so the round-trip is honest).
class _CapturingSettingsRepository extends SettingsRepositoryImpl {
  _CapturingSettingsRepository({required super.prefs});

  final List<bool> allowFallbackCalls = [];

  @override
  Future<void> setVoiceAllowOnDeviceFallback(bool enabled) async {
    allowFallbackCalls.add(enabled);
    await super.setVoiceAllowOnDeviceFallback(enabled);
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

const _switchKey = ValueKey('voiceAllowCloudFallbackSwitch');
const _statusSubtitleKey = ValueKey('voiceOnDeviceStatusSubtitle');

void main() {
  group('VoiceSection - on-device recognition control', () {
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

    testWidgets('renders the auto-degradation SwitchListTile (default on)',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_switchKey), findsOneWidget);
      final sw = tester.widget<SwitchListTile>(find.byKey(_switchKey));
      expect(sw.value, isTrue, reason: 'default auto-degrade allowed');

      // Strings resolve via S (English locale), not hardcoded.
      expect(find.text('Allow cloud fallback'), findsWidgets);
      expect(find.text('On-device recognition'), findsOneWidget);
    });

    testWidgets('status subtitle reflects the auto-fallback-allowed state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      final subtitle =
          tester.widget<Text>(find.byKey(_statusSubtitleKey));
      expect(subtitle.data, 'Allow cloud fallback');
    });

    testWidgets('status subtitle reflects the on-device-only state',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(
            settings: AppSettings(voiceAllowOnDeviceFallback: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sw = tester.widget<SwitchListTile>(find.byKey(_switchKey));
      expect(sw.value, isFalse);

      final subtitle =
          tester.widget<Text>(find.byKey(_statusSubtitleKey));
      expect(
        subtitle.data,
        'When off, recognition stays on-device and a failure is shown '
        'instead of using cloud recognition.',
        reason: 'on-device-only status is a distinct string from the '
            'fallback-allowed state',
      );
    });

    testWidgets('toggling the switch persists via setVoiceAllowOnDeviceFallback',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          overrides: overrides,
          child: const VoiceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_switchKey));
      await tester.pumpAndSettle();

      expect(repo.allowFallbackCalls, [false],
          reason: 'toggling off calls the setter with the new value');
      // Honest round-trip: the value was persisted.
      final persisted = await repo.getSettings();
      expect(persisted.voiceAllowOnDeviceFallback, isFalse);
    });
  });
}
