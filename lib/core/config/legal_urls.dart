/// Public URLs used by support surfaces.
library;

/// Legal documents are bundled in `assets/legal/` and opened inside the app;
/// this class contains only destinations that inherently leave the app.
class LegalUrls {
  LegalUrls._();

  /// There is no live donation account yet. Use the operator's real contact
  /// destination instead of shipping a fabricated payment URL.
  static const String support = 'https://www.sheanzero.com/#contact';

  /// Compatibility alias retained for DONATE-04 callers.
  static const String donation = support;
}
