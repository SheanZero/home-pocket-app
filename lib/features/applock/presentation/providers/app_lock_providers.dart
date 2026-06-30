/// Presentation-local state types for the app-lock screen (Plan 09).
///
/// This module intentionally holds NO business logic and does NOT redefine
/// `appLockServiceProvider` / `biometricServiceProvider` — those live in
/// `lib/infrastructure/security/providers.dart` (Plan 07/02) and the screen
/// consumes them via `ref.read`. It exists to keep the lock screen's UI-only
/// surface enum in one place so the screen (and any future PIN-only variant)
/// share a single source of truth for "which face is showing".
library;

/// Which surface the lock screen is currently presenting.
///
/// The Face ID surface auto-triggers the biometric prompt on entry (D-09); any
/// non-success outcome keeps it visible with a ghost「パスコードを使用」escape
/// that flips to [pin]. The PIN surface instant-verifies on the 4th digit
/// (D-12). There is no reverse path back to [faceId] once the user escapes —
/// the PIN page is the guaranteed-reachable floor (LOCK-05 / T-55-20).
enum AppLockSurface {
  /// Biometric (Face ID / Touch ID) prompt surface.
  faceId,

  /// Numeric PIN entry surface.
  pin,
}
