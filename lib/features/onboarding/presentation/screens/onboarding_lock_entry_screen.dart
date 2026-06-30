import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/scattered_emoji_background.dart';
import '../../../settings/presentation/providers/repository_providers.dart';
import '../../../settings/presentation/providers/state_settings.dart';

/// The trailing onboarding lock-entry screen (D-11 / D-13 / ONBOARD-06).
///
/// Asks「アプリロックを設定しますか？」with two actions:
///   - スキップ (skip): explicitly turns the app-lock master toggle OFF
///     (`setAppLockEnabled(false)`) then completes with `setupSecurity: false`.
///     Per D-02 the new lock reads ONLY `appLockEnabled` (default **false**) —
///     the legacy `biometricLockEnabled` is retired and never armed here. The
///     explicit `false` write keeps the skip semantic unambiguous and pins the
///     master off for a fresh user who skips (D-13 / threat T-54-09 / T-55-07).
///   - 今すぐ設定 (set up now): performs NO biometric write and completes with
///     `setupSecurity: true`. The flow host (54-07) deep-links to the existing
///     SecuritySection; Phase 55 enables the real PIN/biometric there.
///
/// This screen builds NO PIN/biometric capture UI — it only routes via
/// [onComplete]. It does not set `onboarding_complete` (the flow host does).
class OnboardingLockEntryScreen extends ConsumerStatefulWidget {
  const OnboardingLockEntryScreen({super.key, required this.onComplete});

  /// Fired exactly once. `setupSecurity:false` → user skipped (lock forced
  /// OFF); `setupSecurity:true` → user wants to set it up now (deep-link).
  final void Function({required bool setupSecurity}) onComplete;

  @override
  ConsumerState<OnboardingLockEntryScreen> createState() =>
      _OnboardingLockEntryScreenState();
}

class _OnboardingLockEntryScreenState
    extends ConsumerState<OnboardingLockEntryScreen> {
  bool _busy = false;

  Future<void> _skip() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    // D-02/D-13: lock stays OFF on skip — write the new master toggle off. The
    // new lock reads ONLY appLockEnabled; the legacy biometricLockEnabled is
    // retired and never consulted (T-55-07).
    await ref.read(settingsRepositoryProvider).setAppLockEnabled(false);
    ref.invalidate(appSettingsProvider);
    if (!mounted) {
      return;
    }
    widget.onComplete(setupSecurity: false);
  }

  void _setupNow() {
    if (_busy) {
      return;
    }
    // No biometric write — the flow host deep-links to the SecuritySection.
    widget.onComplete(setupSecurity: true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: ScatteredEmojiBackground(
        pattern: ScatteredEmojiPattern.onboarding,
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: 318,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🔐',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 48, color: palette.textPrimary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    S.of(context).onboardingLockTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    S.of(context).onboardingLockDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _OnboardingGradientButton(
                    label: S.of(context).onboardingLockSetupNow,
                    onPressed: _setupNow,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSecondary,
                    ),
                    child: Text(
                      S.of(context).onboardingLockSkip,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary action — a leaf-green gradient pill (ADR-019), ported from
/// `ProfileOnboardingScreen._ProfileGradientButton`.
class _OnboardingGradientButton extends StatelessWidget {
  const _OnboardingGradientButton({
    required this.label,
    required this.onPressed,
  });

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
              fontFamily: 'Outfit',
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
