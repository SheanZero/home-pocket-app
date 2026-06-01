@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/voice_input_screen.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/generated/app_localizations.dart';

import 'voice_input_screen_test.dart'
    show
        FakeStartSpeechRecognitionUseCase,
        FakeCategoryRepository,
        FakeCategoryLedgerConfigRepository;

/// Phase 22 / SC-4 — idle mic button golden baseline.
///
/// D-12 collapses the SmartKeyboard 6-image matrix (3 locales × 2 themes) to a
/// 1×1 matrix here: the mic button shape/gradient/icon are i18n- and theme-
/// insensitive (the caption text below is i18n-sensitive but lives outside the
/// `voice-mic-button` subtree this golden scopes to). Single locale (ja) and
/// single theme (light) is sufficient to detect regressions in the
/// AnimatedContainer's idle decoration.
///
/// Recording-state visuals are asserted via decoration introspection in
/// `voice_input_screen_test.dart` (REC-02 visual test) — no recording golden.

Widget _wrap({
  required Locale locale,
  required ThemeMode themeMode,
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: child,
    ),
  );
}

void main() {
  group(
    'Phase 22 — voice screen mic button golden (D-12, SC-4 visual)',
    () {
      testWidgets(
        'idle mic button (ja, light) matches golden baseline',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() async => tester.binding.setSurfaceSize(null));

          final categoryRepository = FakeCategoryRepository();
          final categoryService = CategoryService(
            categoryRepository: categoryRepository,
            ledgerConfigRepository: FakeCategoryLedgerConfigRepository(),
          );

          await tester.pumpWidget(
            _wrap(
              locale: const Locale('ja'),
              themeMode: ThemeMode.light,
              overrides: [
                categoryRepositoryProvider.overrideWithValue(
                  categoryRepository,
                ),
                categoryServiceProvider.overrideWithValue(categoryService),
                voiceLocaleIdProvider.overrideWith((ref) async => 'ja-JP'),
              ],
              child: VoiceInputScreen(
                bookId: 'book-1',
                speechService: FakeStartSpeechRecognitionUseCase(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final micButtonFinder = find.byKey(
            const ValueKey('voice-mic-button'),
          );
          expect(
            micButtonFinder,
            findsOneWidget,
            reason:
                'Plan 04 must commit ValueKey("voice-mic-button") on the AnimatedContainer',
          );

          await expectLater(
            micButtonFinder,
            matchesGoldenFile('goldens/voice_input_screen_mic_button_idle.png'),
          );
        },
      );
    },
  );
}

