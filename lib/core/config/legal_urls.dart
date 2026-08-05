/// Public URLs used by support surfaces.
library;

/// Canonical public destinations for legal and support surfaces.
class LegalUrls {
  LegalUrls._();

  static const String privacy = 'https://happypocket.app/privacy';
  static const String terms = 'https://happypocket.app/terms';
  static const String tokusho = 'https://happypocket.app/tokusho';
  static const String support = 'https://happypocket.app/support';

  /// Dormant compatibility alias. The first release hides sponsorship.
  static const String donation = support;
}
