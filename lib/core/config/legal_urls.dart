/// Public URLs used by the legal and support surfaces.
library;

/// The legal documents are published from the public Home Pocket repository.
/// Keeping the locale in the URL lets App Store review and users open the same
/// text that is bundled for offline reading in `assets/legal/`.
class LegalUrls {
  LegalUrls._();

  static const String _legalRoot =
      'https://github.com/SheanZero/home-pocket-app/blob/main/assets/legal';

  static const String privacyPolicyHosted = '$_legalRoot/privacy_ja.md';
  static const String termsOfUseHosted = '$_legalRoot/terms_ja.md';
  static const String tokushoHosted = '$_legalRoot/tokusho_ja.md';

  /// There is no live donation account yet. Use the operator's real contact
  /// destination instead of shipping a fabricated payment URL.
  static const String support = 'https://www.sheanzero.com/#contact';

  /// Compatibility alias retained for DONATE-04 callers.
  static const String donation = support;

  static String privacyPolicyFor(String languageCode) =>
      '$_legalRoot/privacy_${_safeLanguage(languageCode)}.md';

  static String termsOfUseFor(String languageCode) =>
      '$_legalRoot/terms_${_safeLanguage(languageCode)}.md';

  static String tokushoFor(String languageCode) =>
      '$_legalRoot/tokusho_${_safeLanguage(languageCode)}.md';

  static String _safeLanguage(String value) =>
      const {'ja', 'zh', 'en'}.contains(value) ? value : 'ja';
}
