import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/satisfaction_face_icon.dart';
import '../widgets/onboarding_float_decor.dart';

/// The skippable onboarding intro (D-02 / ONBOARD-02, Welcome A design).
///
/// A 2-page horizontal PageView — ようこそ / プライバシー — with page dots,
/// 次へ on page 1, はじめる on page 2, and a top-right スキップ visible on both
/// pages. The screen is purely presentational: both はじめる (page 2) and
/// スキップ collapse to [onContinue] — advancing always lands on
/// the settings step (skip jumps past the remaining intro pages, D-02). The
/// flow host (54-07) wires [onContinue] to push the settings route; this
/// screen does NOT navigate.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({
    super.key,
    required this.onContinue,
    this.initialPage = 0,
  }) : assert(initialPage >= 0 && initialPage < 2);

  /// Fired exactly once when the user advances past the intro (page-2
  /// はじめる OR スキップ — both are equivalent because the intro is
  /// skippable, D-02). Never fired by 次へ (internal paging).
  final VoidCallback onContinue;

  /// Supports deterministic visual capture without changing production flow.
  final int initialPage;

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  late final PageController _pageController;
  late int _currentPage;

  static const int _pageCount = 2;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

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

  void _onBackPressed() {
    if (_currentPage == 0) {
      return;
    }
    _pageController.previousPage(
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
          fit: StackFit.expand,
          children: [
            const _OnboardingAmbience(),
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    // Keep the adjacent intro page built before the first
                    // interaction. Its SVG, icons, layout, and repeating
                    // decor tickers otherwise initialize during nextPage's
                    // 300 ms animation and make the first transition jank.
                    allowImplicitScrolling: true,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      TickerMode(
                        enabled: _currentPage == 0,
                        child: const _WelcomePage(),
                      ),
                      TickerMode(
                        enabled: _currentPage == 1,
                        child: const _PrivacyPage(),
                      ),
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
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage == 0)
                    const SizedBox(width: 56, height: 48)
                  else
                    TextButton(
                      onPressed: _onBackPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textTertiary,
                      ),
                      child: Text(
                        MaterialLocalizations.of(context).backButtonTooltip,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                  TextButton(
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
                ],
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

/// V16 option 2: tiny pressed botanical fragments around the screen edges.
///
/// They stay deliberately faint and outside the reading column, adding paper
/// texture without turning into a large illustration or competing watermark.
class _OnboardingAmbience extends StatelessWidget {
  const _OnboardingAmbience();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = Color.alphaBlend(
      palette.accentPrimary.withValues(alpha: 0.16),
      palette.borderDefault,
    );

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          children: [
            _PressedMotif(
              icon: Icons.eco_outlined,
              top: 34,
              left: 37,
              size: 13,
              turns: -0.05,
              color: color,
            ),
            _PressedMotif(
              icon: Icons.spa_outlined,
              top: 248,
              right: 28,
              size: 16,
              turns: 0.04,
              color: color,
            ),
            _PressedMotif(
              icon: Icons.eco_outlined,
              bottom: 136,
              left: 30,
              size: 14,
              turns: -0.03,
              color: color,
            ),
            _PressedMotif(
              icon: Icons.spa_outlined,
              bottom: 62,
              right: 36,
              size: 11,
              turns: 0.06,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _PressedMotif extends StatelessWidget {
  const _PressedMotif({
    required this.icon,
    required this.size,
    required this.turns,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final IconData icon;
  final double size;
  final double turns;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: RotationTransition(
        turns: AlwaysStoppedAnimation(turns),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

/// Wraps page content in a vertical scrollable so shorter test surfaces and
/// small phones never overflow, while retaining the mockup's top-led rhythm.
class _PageScroll extends StatelessWidget {
  const _PageScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(alignment: Alignment.topCenter, child: child),
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
        padding: const EdgeInsets.fromLTRB(40, 50, 40, 24),
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
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 278),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 6,
                ),
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
                    Flexible(
                      child: Text(
                        l10n.onboardingWelcomeBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: palette.joyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 6),
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
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                l10n.onboardingWelcomeTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 23),
            Row(
              children: [
                Expanded(child: _ValuePill(label: l10n.dailyLedger)),
                const SizedBox(width: 7),
                Expanded(
                  child: _ValuePill(label: l10n.joyLedger, highlighted: true),
                ),
                const SizedBox(width: 7),
                Expanded(child: _ValuePill(label: l10n.satisfactionLevel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? palette.joyLight : palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? palette.joyFullnessBorder
              : palette.borderDefault,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlighted ? palette.joyText : palette.textSecondary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shieldSvg =
        '''
<svg viewBox="0 0 24 24" fill="none" stroke="${_svgHex(palette.accentPrimary)}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
  <circle cx="12" cy="10.6" r="1.7"/>
  <path d="M12 12.3 V15"/>
</svg>''';

    return _PageScroll(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 24),
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
                    left: 32,
                    child: FloatyLoop(
                      period: const Duration(seconds: 6),
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: palette.accentPrimaryLight,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: palette.accentPrimaryBorder,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.string(
                          shieldSvg,
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
                      child: _PrivacySatellite(
                        size: 52,
                        icon: Icons.lock_outline,
                        background: palette.joyLight,
                        border: palette.joyFullnessBorder,
                        foreground: palette.joyText,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: FloatyLoop(
                      period: const Duration(milliseconds: 6500),
                      phase: const Duration(milliseconds: 500),
                      child: _PrivacySatellite(
                        size: 42,
                        icon: Icons.smartphone_outlined,
                        background: palette.card,
                        border: palette.accentPrimaryBorder,
                        foreground: palette.dailyText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 22),
            _PrivacyPromiseList(
              title: l10n.onboardingPrivacyCardLocalTitle,
              body: l10n.onboardingPrivacyCardLocalBody,
              tag: l10n.onboardingPrivacyTagLocal,
              secondTitle: l10n.onboardingPrivacyCardE2eTitle,
              secondBody: l10n.onboardingPrivacyCardE2eBody,
              secondTag: l10n.onboardingPrivacyTagE2ee,
              thirdTitle: l10n.onboardingPrivacyCardTamperTitle,
              thirdBody: l10n.onboardingPrivacyCardTamperBody,
              thirdTag: l10n.onboardingPrivacyTagSafe,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySatellite extends StatelessWidget {
  const _PrivacySatellite({
    required this.size,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final double size;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.52, color: foreground),
    );
  }
}

class _PrivacyPromiseList extends StatelessWidget {
  const _PrivacyPromiseList({
    required this.title,
    required this.body,
    required this.tag,
    required this.secondTitle,
    required this.secondBody,
    required this.secondTag,
    required this.thirdTitle,
    required this.thirdBody,
    required this.thirdTag,
  });

  final String title;
  final String body;
  final String tag;
  final String secondTitle;
  final String secondBody;
  final String secondTag;
  final String thirdTitle;
  final String thirdBody;
  final String thirdTag;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _PrivacyPromiseRow(title: title, body: body, tag: tag),
          Divider(height: 1, color: palette.borderDefault),
          _PrivacyPromiseRow(
            title: secondTitle,
            body: secondBody,
            tag: secondTag,
          ),
          Divider(height: 1, color: palette.borderDefault),
          _PrivacyPromiseRow(title: thirdTitle, body: thirdBody, tag: thirdTag),
        ],
      ),
    );
  }
}

class _PrivacyPromiseRow extends StatelessWidget {
  const _PrivacyPromiseRow({
    required this.title,
    required this.body,
    required this.tag,
  });

  final String title;
  final String body;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: palette.dailyText,
            ),
          ),
        ],
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
