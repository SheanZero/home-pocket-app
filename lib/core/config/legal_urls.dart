/// Centralized placeholder external URLs (D-04).
///
/// The single source of truth for every launched / hosted URL the app opens in
/// an external browser. All values are compile-time `const` placeholders — each
/// carries a `上线前填真实值` (fill real value before launch) marker and MUST be
/// replaced with the production URL before the App Store submission:
///
/// - [privacyPolicyHosted] / [termsOfUseHosted]: App Store Connect mandates a
///   hosted privacy-policy / terms URL (LEGAL-01 / LEGAL-02).
/// - [donation]: the sponsor-platform URL launched by the settings sponsor row
///   (DONATE-04); the exact uri asserted downstream in plan 56-05.
library;

/// Holder for placeholder external URLs. 上线前填真实值 (fill real values before launch).
class LegalUrls {
  LegalUrls._();

  static const String privacyPolicyHosted =
      'https://example.com/homepocket/privacy'; // TODO 上线前填真实值
  static const String termsOfUseHosted =
      'https://example.com/homepocket/terms'; // TODO 上线前填真实值
  static const String donation =
      'https://example.com/homepocket/support'; // TODO 上线前填真实值 (DONATE-04)
}
