// Pure, deterministic locale-resolution helpers for the onboarding flow.
//
// These have no Flutter widget dependencies: the testable core takes the
// device language as a parameter so callers (the onboarding settings page)
// can feed it from `PlatformDispatcher` while the logic stays unit-testable.

/// Supported app/voice language codes. Anything outside this set falls back
/// to Japanese (the app default, D-07).
const Set<String> _supportedLanguages = {'ja', 'zh', 'en'};

/// Preselects the onboarding language from the device language.
///
/// Returns [deviceLanguage] when it is one of the supported codes (ja/zh/en),
/// otherwise falls back to 'ja' (D-07).
String preselectOnboardingLanguage(String deviceLanguage) {
  return _supportedLanguages.contains(deviceLanguage) ? deviceLanguage : 'ja';
}

/// Resolves the concrete voice language to persist on onboarding confirm.
///
/// When the user explicitly picked a language, that pick wins. Otherwise the
/// untouched preselect resolves to the concrete device language via
/// [preselectOnboardingLanguage]. The result is always one of {ja, zh, en} —
/// 'system' can never leak into voiceLanguage (D-09 / ONBOARD-05, Pitfall 4).
String resolveVoiceLanguageForOnboarding({
  required bool explicitlyPicked,
  required String pickedLanguage,
  required String deviceLanguage,
}) {
  return explicitlyPicked
      ? pickedLanguage
      : preselectOnboardingLanguage(deviceLanguage);
}
