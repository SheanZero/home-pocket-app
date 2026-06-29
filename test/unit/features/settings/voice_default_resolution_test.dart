import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/utils/onboarding_locale_resolution.dart';

void main() {
  group('preselectOnboardingLanguage', () {
    test('returns the device language when it is ja/zh/en', () {
      expect(preselectOnboardingLanguage('ja'), 'ja');
      expect(preselectOnboardingLanguage('zh'), 'zh');
      expect(preselectOnboardingLanguage('en'), 'en');
    });

    test('falls back to ja for unsupported codes (D-07)', () {
      expect(preselectOnboardingLanguage('ko'), 'ja');
      expect(preselectOnboardingLanguage('fr'), 'ja');
      expect(preselectOnboardingLanguage(''), 'ja');
      expect(preselectOnboardingLanguage('system'), 'ja');
    });
  });

  group('resolveVoiceLanguageForOnboarding', () {
    test('returns the explicit pick regardless of device language', () {
      expect(
        resolveVoiceLanguageForOnboarding(
          explicitlyPicked: true,
          pickedLanguage: 'en',
          deviceLanguage: 'ja',
        ),
        'en',
      );
    });

    test('resolves untouched preselect to concrete device language', () {
      expect(
        resolveVoiceLanguageForOnboarding(
          explicitlyPicked: false,
          pickedLanguage: 'ignored',
          deviceLanguage: 'ja',
        ),
        'ja',
      );
    });

    test('unsupported device language resolves to ja, never system', () {
      final result = resolveVoiceLanguageForOnboarding(
        explicitlyPicked: false,
        pickedLanguage: 'ignored',
        deviceLanguage: 'ko',
      );

      expect(result, 'ja');
      expect(result, isNot('system'));
    });

    test('result is always a concrete code and never system (Pitfall 4)', () {
      for (final device in ['ja', 'zh', 'en', 'ko', 'system', '']) {
        final result = resolveVoiceLanguageForOnboarding(
          explicitlyPicked: false,
          pickedLanguage: 'ignored',
          deviceLanguage: device,
        );

        expect(result, isNot('system'));
        expect({'ja', 'zh', 'en'}.contains(result), isTrue);
      }
    });
  });
}
