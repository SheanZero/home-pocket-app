import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/ocr_parse_draft.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/amount_display.dart';
import '../widgets/amount_edit_bottom_sheet.dart';
import '../widgets/transaction_details_form.dart';

/// Host screen for OCR review (step 2 of the two-step OCR flow).
///
/// Phase 18 reserves the architectural slot — MOD-005's first commit replaces
/// the camera stub in [OcrScannerScreen] with real capture + OCR and populates
/// the [OcrParseDraft]. The `entrySource: EntrySource.manual` literal here
/// flips to `EntrySource.ocr` when the OCR writer lands (D-12).
///
/// Phase 19 D-14 spillover: this host renders its own [AmountDisplay] above
/// the embedded form. Tapping the display opens [AmountEditBottomSheet] (modal
/// sheet UX — only ManualOneStepScreen uses the persistent keypad).
///
/// Thin Scaffold + AppBar + bottom save CTA wrapper around [TransactionDetailsForm]
/// configured as `.$new`. No field-editing logic in this screen (D-01).
/// Post-save: `popUntil((r) => r.isFirst)` — mirrors confirm screen (.new flow, D-13/D-04).
class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({super.key, required this.bookId, required this.draft});

  final String bookId;
  final OcrParseDraft draft;
  @override ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  bool _isSubmitting = false;

  /// Host-owned display amount (Phase 19 D-14 spillover).
  ///
  /// Initialized from the OCR draft's amount field; updated by
  /// [_editAmount] (sheet confirm) and the clear button.
  /// Must stay in sync with the form's internal _amount via [updateAmount].
  late int _displayAmount;

  TransactionDetailsFormConfig get _config => widget.draft.maybeWhen(
        (amount, merchant, date, rawOcrText, imagePath) =>
            TransactionDetailsFormConfig.$new(
              bookId: widget.bookId,
              initialAmount: amount,
              initialMerchant: merchant,
              initialDate: date,
              entrySource: EntrySource.manual, // MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)
            ),
        orElse: () => TransactionDetailsFormConfig.$new(
          bookId: widget.bookId,
          entrySource: EntrySource.manual, // MOD-005: flip to EntrySource.ocr when OCR writer ships (D-12)
        ),
      );

  @override
  void initState() {
    super.initState();
    // Seed _displayAmount from the draft's amount field; default to 0 for empty drafts.
    _displayAmount = widget.draft.maybeWhen(
      (amount, merchant, date, rawOcrText, imagePath) => amount ?? 0,
      orElse: () => 0,
    );
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).transactionSaved)),
        );
        Navigator.of(context).popUntil((r) => r.isFirst); // .new flow, D-13/D-04
      },
      validationError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
      persistError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  /// Opens [AmountEditBottomSheet] for amount editing (D-14 spillover modal-sheet UX).
  ///
  /// On confirm: updates host display state AND pushes value to form via [updateAmount].
  Future<void> _editAmount() async {
    await AmountEditBottomSheet.show(
      context,
      initialAmount: _displayAmount,
      onConfirm: (v) {
        if (!mounted) return;
        setState(() => _displayAmount = v);
        _formKey.currentState?.updateAmount(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.backgroundWarm,
      appBar: AppBar(
        backgroundColor: isDark ? AppColorsDark.card : AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: AppColors.survival),
          label: Text(l10n.back,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.survival)),
        ),
        leadingWidth: 100,
        title: Text(l10n.ocrReviewTitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
            )),
        centerTitle: true,
      ),
      body: Column(children: [
        // D-14 spillover: host renders AmountDisplay above the form.
        // Tapping opens AmountEditBottomSheet (modal-sheet UX, not persistent keyboard).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _editAmount,
          child: AmountDisplay(
            amount: _displayAmount > 0 ? _displayAmount.toString() : '',
            onClear: () {
              if (!mounted) return;
              setState(() => _displayAmount = 0);
              _formKey.currentState?.updateAmount(0);
            },
          ),
        ),
        // Empty-draft banner — preserved verbatim (Phase 18 D-13).
        // Positioned AFTER AmountDisplay so the display is always visible at top.
        if (widget.draft.isEmpty)
          MaterialBanner(
            content: Text(l10n.ocrReviewEmptyDraftBanner),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TransactionDetailsForm(key: _formKey, config: _config),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.actionGradientStart, AppColors.actionGradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: AppColors.actionShadow, blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _save,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.save,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              )),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
