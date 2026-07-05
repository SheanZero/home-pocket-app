import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/security/biometric_service.dart';
import '../../../../infrastructure/security/models/auth_result.dart';
import '../../../../infrastructure/security/providers.dart';
import '../providers/app_lock_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/face_id_panel.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// The two-surface unlock screen (sketch 002 tone B — LOCK-05 / LOCK-06).
///
/// Composes the Plan 08 presentational widgets ([FaceIdPanel] / [PinKeypad] /
/// [PinDots]) and drives them with the Plan 02 [BiometricService] and the
/// Plan 07 `AppLockService.verifyPin`. Two surfaces ([AppLockSurface]):
///
///   * **Face ID** (default entry): auto-triggers the biometric prompt on first
///     frame (D-09). On [AuthResultSuccess] it reports unlock; on EVERY other
///     outcome it STAYS visible with a 再試行 retry + a ghost「パスコードを使用」
///     escape to the PIN page — biometric is never a dead end (LOCK-05 /
///     T-55-20, consuming the Plan 02 LOCK-10 all-non-success → fallback map).
///   * **PIN**: instant-verifies on the 4th digit with no submit key (D-12). A
///     wrong PIN shakes + clears the dots with a haptic and NO text, instantly
///     retryable with zero cooldown (D-06). A low-key「忘记 PIN?」reveals the
///     no-recovery explanation (D-08 / LOCK-09).
///
/// Unlock is reported ONLY via [onUnlocked]; the screen never navigates or flips
/// a gate flag itself (Plan 11 owns that — boot-gate-completion-must-flip-flag).
/// The biometric call is fenced by [onBeginAuth] / [onEndAuth] so the lifecycle
/// observer (Plan 06) ignores the system sheet and Face ID never relock-loops
/// (T-55-23); Plan 11 supplies those callbacks.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.onBeginAuth,
    this.onEndAuth,
    this.startOnPinPage = false,
  });

  /// Fired exactly once on a genuine unlock (biometric success or PIN match).
  final VoidCallback onUnlocked;

  /// Fences the start of a biometric prompt (observer ignores the OS sheet).
  final VoidCallback? onBeginAuth;

  /// Fences the end of a biometric prompt.
  final VoidCallback? onEndAuth;

  /// Start directly on the PIN page (PIN-only config / biometric disabled).
  final bool startOnPinPage;

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  static const int _pinLength = 4;

  late AppLockSurface _surface;
  String _entered = '';
  int _errorTrigger = 0;
  bool _authRunning = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _surface = widget.startOnPinPage
        ? AppLockSurface.pin
        : AppLockSurface.faceId;
    if (!widget.startOnPinPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _runBiometric();
        }
      });
    }
  }

  Future<void> _runBiometric() async {
    if (_authRunning) {
      return;
    }
    setState(() => _authRunning = true);
    final reason = S.of(context).appLockReauthReason;
    widget.onBeginAuth?.call();
    try {
      final result = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: reason, biometricOnly: true);
      if (result is AuthResultSuccess) {
        widget.onUnlocked();
        return;
      }
    } finally {
      widget.onEndAuth?.call();
      if (mounted) {
        setState(() => _authRunning = false);
      }
    }
  }

  void _onDigit(int digit) {
    if (_verifying || _entered.length >= _pinLength) {
      return;
    }
    setState(() => _entered += '$digit');
    if (_entered.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_verifying || _entered.isEmpty) {
      return;
    }
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verifyPin() async {
    final pin = _entered;
    setState(() => _verifying = true);
    final ok = await ref.read(appLockServiceProvider).verifyPin(pin);
    if (!mounted) {
      return;
    }
    if (ok) {
      widget.onUnlocked();
      setState(() => _verifying = false);
      return;
    }
    // Wrong PIN: shake + clear + haptic (PinDots owns the haptic on the
    // errorTrigger bump), NO text, instantly retryable — no cooldown (D-06).
    setState(() {
      _entered = '';
      _errorTrigger += 1;
      _verifying = false;
    });
  }

  void _showForgotPin() {
    final l = S.of(context);
    final palette = context.palette;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.card,
        title: Text(
          l.appLockForgotPin,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        content: Text(
          l.appLockForgotPinExplanation,
          key: const ValueKey('app-lock-forgot-explanation'),
          style: TextStyle(
            fontFamily: 'Outfit',
            height: 1.5,
            color: palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: palette.accentPrimary),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 318,
            child: switch (_surface) {
              AppLockSurface.faceId => _buildFaceIdSurface(),
              AppLockSurface.pin => _buildPinSurface(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFaceIdSurface() {
    return FaceIdPanel(
      onRetry: _runBiometric,
      onUsePasscode: () => setState(() => _surface = AppLockSurface.pin),
    );
  }

  Widget _buildPinSurface() {
    final palette = context.palette;
    final l = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.appLockPinTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: PinDots(
            filledCount: _entered.length,
            length: _pinLength,
            errorTrigger: _errorTrigger,
          ),
        ),
        // Verify-state feedback (LOCK-V2-05): the Argon2id derive is slow
        // on-device (~1s), so surface a lightweight spinner while verifyPin is
        // pending instead of leaving the filled dots looking frozen. Reuses the
        // existing 36px gap so the keypad never shifts. Security-neutral — no
        // KDF change; the keypad is already input-guarded by `_verifying`.
        SizedBox(
          height: 36,
          child: Center(
            child: _verifying
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.accentPrimary,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
        const SizedBox(height: 12),
        TextButton(
          key: const ValueKey('app-lock-forgot-pin'),
          onPressed: _showForgotPin,
          style: TextButton.styleFrom(foregroundColor: palette.textSecondary),
          child: Text(
            l.appLockForgotPin,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
