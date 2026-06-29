import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/scattered_emoji_background.dart';

/// The skippable onboarding intro screen (D-02 / ONBOARD-02).
///
/// Presents the four approved selling points (privacy/端末内暗号化,
/// local-first, 日常+悦己 dual-ledger, voice) and a forward action. The screen
/// is purely presentational: both the「はじめる」(continue) and「スキップ」
/// (skip) actions collapse to [onContinue] — the intro is informational and
/// advancing always lands on the settings step. The flow host (54-07) wires
/// [onContinue] to push the settings route; this screen does NOT navigate.
class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key, required this.onContinue});

  /// Fired exactly once when the user advances past the intro (continue OR
  /// skip — both are equivalent because the intro is skippable, D-02).
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: ScatteredEmojiBackground(
        pattern: ScatteredEmojiPattern.onboarding,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 318,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      S.of(context).onboardingIntroTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).onboardingIntroSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SellingPoint(
                      emoji: '🔒',
                      title: S.of(context).onboardingIntroPrivacyTitle,
                      body: S.of(context).onboardingIntroPrivacyBody,
                    ),
                    const SizedBox(height: 16),
                    _SellingPoint(
                      emoji: '📴',
                      title: S.of(context).onboardingIntroLocalTitle,
                      body: S.of(context).onboardingIntroLocalBody,
                    ),
                    const SizedBox(height: 16),
                    _SellingPoint(
                      emoji: '📒',
                      title: S.of(context).onboardingIntroLedgerTitle,
                      body: S.of(context).onboardingIntroLedgerBody,
                    ),
                    const SizedBox(height: 16),
                    _SellingPoint(
                      emoji: '🎤',
                      title: S.of(context).onboardingIntroVoiceTitle,
                      body: S.of(context).onboardingIntroVoiceBody,
                    ),
                    const SizedBox(height: 32),
                    _OnboardingGradientButton(
                      label: S.of(context).onboardingIntroContinue,
                      onPressed: onContinue,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onContinue,
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textSecondary,
                      ),
                      child: Text(
                        S.of(context).onboardingIntroSkip,
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
      ),
    );
  }
}

/// One selling-point row: an emoji glyph beside a title + supporting body.
class _SellingPoint extends StatelessWidget {
  const _SellingPoint({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24, height: 1.2)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  height: 1.35,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The primary forward action — a leaf-green gradient pill (ADR-019), ported
/// from `ProfileOnboardingScreen._ProfileGradientButton`.
class _OnboardingGradientButton extends StatelessWidget {
  const _OnboardingGradientButton({required this.label, required this.onPressed});

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
