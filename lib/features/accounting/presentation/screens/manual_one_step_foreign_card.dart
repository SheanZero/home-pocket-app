// lib/features/accounting/presentation/screens/manual_one_step_foreign_card.dart
//
// 260622-nhs: extracted from manual_one_step_screen.dart to keep that file under
// the CLAUDE.md 800-LOC cap after the single-page push-to-talk wiring landed.
// Holds the ADD-screen foreign-currency card presentation + the WR-01 staleness
// guard. No behavior change — byte-faithful move of the helpers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/currency/rate_result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../widgets/conversion_preview_panel.dart';
import '../widgets/currency_linked_edit_fields.dart';

/// Quick 260613-ufn (D-1): thin Consumer wrapper that mounts the unified
/// [CurrencyLinkedEditFields] card on the ADD screen, fed by the keyed
/// [conversionRateProvider]. It reuses the SAME card and the SAME single
/// staleness-derivation site as the edit host — the two screens are now visually
/// and interactively identical (no large ≈¥ preview block).
///
/// Date auto-refetch (D-4): because the provider is keyed on (currency, date,
/// amount), the host bumping `_selectedDate` re-resolves the rate and re-seeds
/// the card's 汇率 / 日元 / 汇率日期 / staleness. A user hand-edit of the 汇率 row
/// flips manual override via [onRateEdited] (the host persists the edited rate).
class AddScreenForeignCard extends ConsumerWidget {
  const AddScreenForeignCard({
    super.key,
    required this.currency,
    required this.date,
    required this.originalMinorUnits,
    required this.manualRateOverride,
    required this.onRateEdited,
    required this.onSignal,
  });

  final String currency;
  final DateTime date;
  final int originalMinorUnits;

  /// Active manual-override rate (null when the auto-resolved rate is in use).
  /// When set it seeds the card so the user's edit survives provider re-reads.
  final String? manualRateOverride;

  /// Fired when the user hand-edits the 汇率 row (manual override).
  final ValueChanged<CurrencyLinkedEditValue> onRateEdited;

  /// ADR-022 RateSignal sink (D-02/D-03), forwarded via ref.listen only.
  final void Function(RateSignal signal) onSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    final args = ConversionPreviewArgs(
      currency: currency,
      date: date,
    );

    // RateSignal side-effects (D-02 dialog / D-03 toast) belong in ref.listen,
    // NEVER ref.watch (Riverpod 3 — CLAUDE.md side-effect rule).
    ref.listen<AsyncValue<RateResultWithSignal>>(
      conversionRateProvider(args),
      (previous, next) {
        final signal = next.value?.signal;
        if (signal != null) onSignal(signal);
      },
    );

    final rateAsync = ref.watch(conversionRateProvider(args));

    return rateAsync.when(
      loading: () => const SizedBox(
        height: kAddScreenForeignCardLoadingHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _RateRequiredRow(l10n: l10n, palette: context.palette),
      data: (withSignal) {
        final result = withSignal.result;
        final resolvedRate = rateStringOf(result);
        // RateUnavailable (P41 D-08): prompt for a manual rate; the host's
        // _pushForeignTriple already withholds the triple so save is gated.
        if (resolvedRate == null && manualRateOverride == null) {
          return _RateRequiredRow(l10n: l10n, palette: context.palette);
        }
        // A user-edited (manual) rate wins over the auto-resolved one as the
        // seed, so the edit survives provider re-reads.
        final seedRate = manualRateOverride ?? resolvedRate!;
        final actualRateDate = rateEffectiveDateOf(result, date);
        final stalenessNote = manualRateOverride != null
            ? null // manual override supersedes the auto-rate staleness
            : stalenessNoteFor(
                result: result,
                requestedDate: date,
                l10n: l10n,
                locale: locale,
              );

        return CurrencyLinkedEditFields(
          // Re-seed the card when the resolved/override rate changes (date
          // re-resolve or currency switch) — a stable key preserves in-card
          // edits within the same seed.
          key: ValueKey('add-foreign-card-$currency-$seedRate'),
          originalCurrency: currency,
          originalAmount: originalMinorUnits,
          appliedRate: seedRate,
          manualOverride: manualRateOverride != null,
          rateDate: date,
          actualRateDate: actualRateDate,
          stalenessNote: stalenessNote,
          onChanged: onRateEdited,
        );
      },
    );
  }
}

/// Fixed loading height so the add-screen card area does not jump while the
/// keyed rate provider resolves.
const double kAddScreenForeignCardLoadingHeight = 56;

/// Mandatory-manual-rate prompt row (P41 D-08 / RateUnavailable) for the add
/// screen. Error color — save is gated on a present rate by the host.
class _RateRequiredRow extends StatelessWidget {
  const _RateRequiredRow({required this.l10n, required this.palette});

  final S l10n;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.conversionRateRequired,
          style: AppTextStyles.labelMedium.copyWith(color: palette.error),
        ),
      ),
    );
  }
}
