import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'currency_edit_strings.dart';

/// User choice returned by [ChangeRateConfirmationDialog] (ADR-022 D-02).
///
/// There is intentionally NO default — the user MUST pick one. A dismissed
/// dialog (barrier tap / back) returns `null`, which the caller treats as
/// "make no change" (neither re-fetch nor confirm).
enum ChangeRateChoice {
  /// Keep the user's manual override; do not re-fetch (override flag stays true).
  keepManual,

  /// Re-fetch the rate for the new date (override flag resets to false).
  refetch,
}

/// ADR-022 D-02 two-choice dialog shown when a manual-override rate is active
/// AND the transaction date changes.
///
/// Unlike the destructive [showSoftConfirmDialog] (one affirmative + cancel),
/// this dialog presents TWO affirmative actions with NO default selection:
/// 「保留手动汇率」 (keep manual) vs 「按新日期重取」 (re-fetch). Both options are
/// equally weighted; the user must actively choose — silent behaviour is
/// forbidden (ADR-022 D-02 rationale: POLA).
///
/// Uses Material [AlertDialog] (the keyed actions are asserted by
/// `edit_currency_linked_test.dart`). Returns the chosen [ChangeRateChoice], or
/// `null` if the dialog was dismissed without a choice.
Future<ChangeRateChoice?> showChangeRateConfirmationDialog(
  BuildContext context,
) {
  return showDialog<ChangeRateChoice>(
    context: context,
    builder: (_) => const ChangeRateConfirmationDialog(),
  );
}

/// The ADR-022 D-02 dialog body. Exposed as a public widget so it can be pumped
/// directly in widget tests and reused by [showChangeRateConfirmationDialog].
class ChangeRateConfirmationDialog extends StatelessWidget {
  const ChangeRateConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CurrencyEditStrings.of(context);
    final palette = context.palette;
    return AlertDialog(
      backgroundColor: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.borderDefault),
      ),
      title: Text(
        l10n.dialogTitle,
        style: AppTextStyles.titleSmall.copyWith(color: palette.textPrimary),
      ),
      content: Text(
        l10n.dialogBody,
        style: AppTextStyles.bodyMedium.copyWith(
          color: palette.textSecondary,
          height: 1.5,
        ),
      ),
      // Two affirmative actions, NO default (ADR-022 D-02). Both share neutral
      // tints so neither reads as the "recommended" one.
      actions: [
        TextButton(
          key: const Key('dialog_keep_manual_rate'),
          onPressed: () =>
              Navigator.pop(context, ChangeRateChoice.keepManual),
          style: TextButton.styleFrom(foregroundColor: palette.textSecondary),
          child: Text(
            l10n.keepManual,
            style: AppTextStyles.titleSmall.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
        TextButton(
          key: const Key('dialog_refetch_for_new_date'),
          onPressed: () => Navigator.pop(context, ChangeRateChoice.refetch),
          style: TextButton.styleFrom(foregroundColor: palette.daily),
          child: Text(
            l10n.refetch,
            style: AppTextStyles.titleSmall.copyWith(color: palette.daily),
          ),
        ),
      ],
    );
  }
}
