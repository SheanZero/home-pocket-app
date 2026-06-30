import 'package:flutter/widgets.dart';

/// Returns whether the app lock is currently effective
/// (`appLockEnabled && pinHash != null`, evaluated lazily by the host).
typedef LockEffectivePredicate = bool Function();

/// Root [WidgetsBindingObserver] that drives relock (LOCK-03) and the privacy
/// mask (LOCK-04) using the two-flag guard from 55-RESEARCH §2.
///
/// It EXTENDS the [SyncLifecycleObserver] callback shape (constructor callbacks
/// + idempotent `start`/`dispose`) but adds:
///   * an `inactive` branch that shows the privacy mask whenever the lock is
///     effective (Control Center, app-switcher snapshot, biometric sheet), and
///   * a `_didPause` + `_authInProgress` guard so relock fires ONLY on a true
///     background round-trip (`paused` was reached) and NEVER on the
///     OS-triggered biometric sheet (which only produces `inactive`→`resumed`).
///
/// This unit is intentionally device-free and Riverpod-free so it is fully
/// unit-testable. The host (Plan 11) wires the callbacks into the lock gate and
/// registers it in `main.dart`; the lock screen (Plan 09) fences its biometric
/// call with [beginAuth] / [endAuth].
class AppLockLifecycleObserver with WidgetsBindingObserver {
  AppLockLifecycleObserver({
    required LockEffectivePredicate isLockEffective,
    required VoidCallback onRelock,
    required VoidCallback onMask,
    required VoidCallback onUnmask,
  })  : _isLockEffective = isLockEffective,
        _onRelock = onRelock,
        _onMask = onMask,
        _onUnmask = onUnmask;

  final LockEffectivePredicate _isLockEffective;
  final VoidCallback _onRelock;
  final VoidCallback _onMask;
  final VoidCallback _onUnmask;

  bool _isActive = false;

  /// True while our own biometric sheet is up. Set via [beginAuth] /
  /// [endAuth] around `BiometricService.authenticate()`. Fences the lifecycle
  /// churn the system Face ID / Touch ID sheet causes so it neither arms nor
  /// fires a relock.
  bool _authInProgress = false;

  /// True once the app actually reached [AppLifecycleState.paused] (a genuine
  /// backgrounding). Control Center / Notification Center only produce
  /// `inactive`→`resumed`, so this stays false and no relock occurs.
  bool _didPause = false;

  /// Start observing lifecycle events (idempotent).
  void start() {
    if (_isActive) return;
    WidgetsBinding.instance.addObserver(this);
    _isActive = true;
  }

  /// Stop observing lifecycle events (idempotent).
  void dispose() {
    if (!_isActive) return;
    WidgetsBinding.instance.removeObserver(this);
    _isActive = false;
  }

  /// Open the biometric fence before calling the system auth sheet.
  void beginAuth() => _authInProgress = true;

  /// Close the biometric fence (call from a `finally`, even on throw).
  void endAuth() => _authInProgress = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Paint-only mask whenever the lock is effective. Safe behind the Face
        // ID sheet; never causes a loop (it is an overlay, not a state flip).
        if (_isLockEffective()) _onMask();
      case AppLifecycleState.paused:
        // Record a real backgrounding only when it is NOT our own auth sheet.
        if (!_authInProgress) _didPause = true;
      case AppLifecycleState.resumed:
        _onUnmask();
        // Relock ONLY on a true background round-trip that is not the
        // biometric sheet returning. Control Center never set `_didPause`;
        // the Face ID sheet is fenced by `_authInProgress`.
        if (_didPause && !_authInProgress && _isLockEffective()) {
          _onRelock();
        }
        _didPause = false;
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }
}
