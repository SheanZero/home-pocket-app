import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/satisfaction_face_icon.dart';
import '../widgets/onboarding_float_decor.dart';

/// The skippable onboarding intro (D-02 / ONBOARD-02, Welcome A design).
///
/// A 3-page horizontal PageView — ようこそ / プライバシー / 記録の悦び — with
/// page dots, 次へ on pages 1-2, はじめる on page 3, and a top-right スキップ
/// visible on all pages. The screen is purely presentational: both はじめる
/// (page 3) and スキップ collapse to [onContinue] — advancing always lands on
/// the settings step (skip jumps past the remaining intro pages, D-02). The
/// flow host (54-07) wires [onContinue] to push the settings route; this
/// screen does NOT navigate.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key, required this.onContinue});

  /// Fired exactly once when the user advances past the intro (page-3
  /// はじめる OR スキップ — both are equivalent because the intro is
  /// skippable, D-02). Never fired by 次へ (internal paging).
  final VoidCallback onContinue;

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPrimaryPressed() {
    if (_currentPage >= _pageCount - 1) {
      widget.onContinue();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final isLastPage = _currentPage >= _pageCount - 1;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: const [
                      _WelcomePage(),
                      _PrivacyPage(),
                      _JoyPage(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
                  child: Column(
                    children: [
                      _PageDots(count: _pageCount, current: _currentPage),
                      const SizedBox(height: 22),
                      _PrimaryButton(
                        label: isLastPage
                            ? l10n.onboardingIntroContinue
                            : l10n.next,
                        onPressed: _onPrimaryPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 14,
              child: TextButton(
                onPressed: widget.onContinue,
                style: TextButton.styleFrom(
                  foregroundColor: palette.textTertiary,
                ),
                child: Text(
                  l10n.onboardingIntroSkip,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Converts a palette [Color] to a `#RRGGBB` string for inline SVG glyphs.
/// Only ever fed from AppPalette values at build time (COLOR-01 compliant —
/// no literal constants).
String _svgHex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Wraps page content in a vertical scrollable so shorter test surfaces and
/// small phones never overflow, while centering on tall screens.
class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ── Page 1 ようこそ (A-*-welcome) ────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final houseSvg =
        '''
<svg viewBox="0 0 32 32" fill="none" stroke="${_svgHex(palette.accentPrimary)}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 15 L16 6 L27 15"/>
  <path d="M8 13.5 V25 a1 1 0 0 0 1 1 H23 a1 1 0 0 0 1-1 V13.5"/>
  <path d="M16 26 V19.5"/>
  <path d="M16 19.5 C16 16.8 18.3 16.2 20 16.2 C20 18.7 18 19.5 16 19.5 Z" fill="${_svgHex(palette.accentPrimaryLight)}"/>
  <path d="M16 21.4 C16 18.9 13.9 18.4 12.4 18.4 C12.4 20.7 14.2 21.4 16 21.4 Z" fill="${_svgHex(palette.accentPrimaryLight)}"/>
</svg>''';

    return _PageScroll(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 172,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 18,
                    right: 6,
                    child: DriftPetal(
                      size: 12,
                      color: palette.joy,
                      opacity: isDark ? 0.7 : 0.5,
                      period: const Duration(seconds: 5),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    child: DriftPetal(
                      size: 9,
                      color: palette.accentPrimary,
                      opacity: isDark ? 0.55 : 0.4,
                      period: const Duration(milliseconds: 6500),
                      phase: const Duration(milliseconds: 600),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 28,
                    child: FloatyLoop(
                      period: const Duration(seconds: 6),
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: palette.accentPrimaryLight,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: palette.accentPrimaryBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.string(
                          houseSvg,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: 8,
                    child: FloatyLoop(
                      period: const Duration(seconds: 5),
                      phase: const Duration(milliseconds: 300),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: palette.joyLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.joyFullnessBorder),
                        ),
                        alignment: Alignment.center,
                        child: SatisfactionFaceIcon(
                          value: 7,
                          size: 32,
                          color: palette.joyText,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: FloatyLoop(
                      period: const Duration(milliseconds: 6500),
                      phase: const Duration(milliseconds: 500),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: palette.card,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.accentPrimaryBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SatisfactionFaceIcon(
                          value: 3,
                          size: 26,
                          color: palette.dailyText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              decoration: BoxDecoration(
                color: palette.joyLight,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: palette.joyFullnessBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SatisfactionFaceIcon(
                    value: 7,
                    size: 15,
                    color: palette.joyText,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    l10n.onboardingWelcomeBadge,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: palette.joyText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.onboardingIntroTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingWelcomeBrand,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3.7,
                color: palette.textTertiary,
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                l10n.onboardingWelcomeTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.95,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 2 プライバシー (A-*-privacy) ───────────────────────────────────────

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);

    final shieldSvg =
        '''
<svg viewBox="0 0 24 24" fill="none" stroke="${_svgHex(palette.accentPrimary)}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
  <circle cx="12" cy="10.6" r="1.7"/>
  <path d="M12 12.3 V15"/>
</svg>''';

    return _PageScroll(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatyLoop(
              period: const Duration(seconds: 6),
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: palette.accentPrimaryLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: palette.accentPrimaryBorder),
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(shieldSvg, width: 50, height: 50),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              l10n.onboardingPrivacyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                l10n.onboardingPrivacySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.9,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _FeatureCard(
              icon: Icons.smartphone,
              title: l10n.onboardingPrivacyCardLocalTitle,
              body: l10n.onboardingPrivacyCardLocalBody,
            ),
            const SizedBox(height: 11),
            _FeatureCard(
              icon: Icons.lock_outline,
              title: l10n.onboardingPrivacyCardE2eTitle,
              body: l10n.onboardingPrivacyCardE2eBody,
            ),
            const SizedBox(height: 11),
            _FeatureCard(
              icon: Icons.verified_outlined,
              title: l10n.onboardingPrivacyCardTamperTitle,
              body: l10n.onboardingPrivacyCardTamperBody,
            ),
          ],
        ),
      ),
    );
  }
}

/// One full-width privacy feature card: icon chip + title + body.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.accentPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: palette.accentPrimary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3 記録の悦び (A-*-joy) ─────────────────────────────────────────────

class _JoyPage extends StatelessWidget {
  const _JoyPage();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _PageScroll(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 122,
              height: 122,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 2,
                    right: 2,
                    child: DriftPetal(
                      size: 14,
                      color: palette.joy,
                      opacity: isDark ? 0.7 : 0.5,
                      period: const Duration(seconds: 5),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: -2,
                    child: DriftPetal(
                      size: 10,
                      color: palette.accentPrimary,
                      opacity: isDark ? 0.55 : 0.4,
                      period: const Duration(milliseconds: 6500),
                      phase: const Duration(milliseconds: 600),
                    ),
                  ),
                  Positioned.fill(
                    left: 12,
                    top: 12,
                    right: 12,
                    bottom: 12,
                    child: FloatyLoop(
                      period: const Duration(seconds: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.joyLight,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: palette.joyFullnessBorder),
                        ),
                        alignment: Alignment.center,
                        child: SatisfactionFaceIcon(
                          value: 7,
                          size: 56,
                          color: palette.joyText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              l10n.onboardingJoyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                l10n.onboardingJoySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.9,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final value in const [1, 3, 5]) ...[
                  Opacity(
                    opacity: 0.45,
                    child: SatisfactionFaceIcon(
                      value: value,
                      size: 27,
                      color: palette.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: palette.joyLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.joy, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: SatisfactionFaceIcon(
                    value: 7,
                    size: 32,
                    color: palette.joyText,
                  ),
                ),
                const SizedBox(width: 14),
                Opacity(
                  opacity: 0.45,
                  child: SatisfactionFaceIcon(
                    value: 9,
                    size: 27,
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.onboardingJoyCaption,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textTertiary,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              l10n.onboardingJoyAccent,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                fontWeight: FontWeight.w600,
                color: palette.dailyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared chrome ───────────────────────────────────────────────────────────

/// The page-position dots: active pill 20×6, inactive 6×6 (radius 3).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? palette.accentPrimary
                  : palette.borderDefault,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}

/// The primary forward action — a flat leaf-green button per the Welcome A
/// design (replaces the old gradient pill).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.accentPrimary,
        boxShadow: [
          BoxShadow(
            color: palette.accentPrimary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
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
