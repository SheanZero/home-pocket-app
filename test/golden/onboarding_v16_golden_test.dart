@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/app_theme.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/shared/constants/avatar_icon_ids.dart';

Widget _host(Widget child, {bool needsProviders = false}) {
  // The headless Flutter test engine does not provide a CJK system-font
  // fallback. English keeps the visual regression images legible and stable;
  // localized Japanese/Chinese copy is covered by the widget tests.
  const locale = Locale('en');
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: AppTheme.light,
    home: child,
  );
  if (!needsProviders) {
    return app;
  }
  return ProviderScope(
    overrides: [
      biometricAvailabilityProvider.overrideWith(
        (_) async => BiometricAvailability.faceId,
      ),
    ],
    child: app,
  );
}

void main() {
  void configureSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('V16 onboarding welcome page', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(_host(OnboardingIntroScreen(onContinue: () {})));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_welcome_v16_light_en.png'),
    );
  });

  testWidgets('V16 onboarding privacy page', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(
      _host(OnboardingIntroScreen(initialPage: 1, onContinue: () {})),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_privacy_v16_light_en.png'),
    );
  });

  testWidgets('V16 onboarding initial setup', (tester) async {
    configureSurface(tester);
    await tester.pumpWidget(
      _host(
        OnboardingSettingsScreen(
          bookId: 'book-1',
          initialAvatarId: avatarIconIds[1],
          onConfirmed: () {},
        ),
        needsProviders: true,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding_setup_v16_light_en.png'),
    );
  });
}
