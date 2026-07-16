import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';

/// Presentational Face ID surface (sketch 002 tone B "清爽极简", D-09).
///
/// Shows a centered brand glyph, the Face ID prompt, a primary retry action and
/// a ghost「パスコードを使用」escape. It emits callbacks ONLY — it never calls
/// `BiometricService`. The consuming lock screen (Plan 09) auto-triggers the
/// biometric prompt and, on any failure, keeps this panel visible so the user
/// can retry ([onRetry]) or drop to the PIN page ([onUsePasscode]). The ghost
/// escape is mandatory so Face ID is never a dead end (LOCK-05 / T-55-19).
///
/// Theming is via [AppPaletteContext.palette] (ADR-019 v1.6); strings via
/// [S.of].
class FaceIdPanel extends StatelessWidget {
  const FaceIdPanel({
    super.key,
    required this.onRetry,
    required this.onUsePasscode,
  });

  /// Fired when the user asks to re-run the biometric prompt.
  final VoidCallback onRetry;

  /// Fired when the user chooses to fall back to PIN entry (ghost escape).
  final VoidCallback onUsePasscode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = S.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: palette.borderDefault),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 40,
              color: palette.accentPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.appLockFaceIdPrompt,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        _RetryButton(label: l.appLockFaceIdRetry, onPressed: onRetry),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onUsePasscode,
          style: TextButton.styleFrom(foregroundColor: palette.accentPrimary),
          child: Text(
            l.appLockUsePasscode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.accentPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The primary retry action — a leaf-green gradient pill (ADR-019), mirroring
/// the onboarding `_OnboardingGradientButton` idiom.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [palette.accentPrimary, palette.fabGradientStart],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.white,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
