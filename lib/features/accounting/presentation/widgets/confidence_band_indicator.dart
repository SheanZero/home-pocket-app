import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/transaction.dart' show LedgerType;
import '../../../voice/domain/models/recognition_outcome.dart';

/// Purely-visual recognition confidence band (RECUX-01 / CONTEXT D-03).
///
/// Renders a qualitative 3-tier confidence cue as **color/icon intensity only**
/// keyed to the resolved category's ledger family (日常 daily-green vs 悦己
/// joy-pink). It paints no numeric or worded confidence cue at all
/// (ADR-012 anti-gamification) — the ONLY text is an a11y-hidden [Semantics]
/// label (`recognitionBandSuggestedCategory`) that screen readers announce but
/// the widget never paints.
///
/// Intensity is switched on the domain-owned [ConfidenceBand] enum value
/// (computed in Phase 51 by `RecognitionReconciler`); presentation NEVER
/// recomputes the band from any numeric confidence (T-52-04).
///
/// Returns [SizedBox.shrink] when [band] is null — supports the manual-entry
/// no-affordance contract (D-10): no recognition outcome → no band.
class ConfidenceBandIndicator extends StatelessWidget {
  const ConfidenceBandIndicator({
    super.key,
    required this.band,
    required this.ledgerType,
  });

  /// The qualitative confidence band. Null → render nothing (D-10).
  final ConfidenceBand? band;

  /// The resolved category's ledger family — drives the accent color family
  /// (daily-green vs joy-pink). Defaults to daily upstream when unknown.
  final LedgerType ledgerType;

  @override
  Widget build(BuildContext context) {
    final band = this.band;
    if (band == null) return const SizedBox.shrink();

    final palette = context.palette;
    final isJoy = ledgerType == LedgerType.joy;

    // Family accent (full-intensity) and its Light fill, keyed to the ledger.
    final accent = isJoy ? palette.joy : palette.daily;
    final accentLight = isJoy ? palette.joyLight : palette.dailyLight;

    // Intensity is switched on the band enum ONLY (never a numeric value). Per
    // UI-SPEC §Color:
    //   strong → full-intensity family accent (solid 2px border + filled dot)
    //   medium → reduced intensity (Light fill / 1px border, hollow dot)
    //   weak   → minimal / textTertiary de-emphasis
    final Color borderColor;
    final double borderWidth;
    final Color fillColor;
    final Color dotColor;
    switch (band) {
      case ConfidenceBand.strong:
        borderColor = accent;
        borderWidth = 2;
        fillColor = accentLight;
        dotColor = accent;
      case ConfidenceBand.medium:
        borderColor = accent;
        borderWidth = 1;
        fillColor = accentLight;
        dotColor = accentLight;
      case ConfidenceBand.weak:
        borderColor = palette.textTertiary;
        borderWidth = 1;
        fillColor = palette.backgroundMuted;
        dotColor = palette.textTertiary;
    }

    // a11y-only label — announced by screen readers, NEVER painted (D-03).
    final a11yLabel = S.of(context).recognitionBandSuggestedCategory;

    return Semantics(
      container: true,
      label: a11yLabel,
      // Hide the decorative children from the a11y tree so only the label
      // (qualitative "suggested category") is announced — no number leaks.
      excludeSemantics: true,
      child: Container(
        // Compact pure-visual pill: a small filled dot inside a family-tinted
        // chip whose border depth encodes the band tier. No text.
        width: 28,
        height: 16,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
