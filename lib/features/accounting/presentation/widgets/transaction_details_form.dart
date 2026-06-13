/// TransactionDetailsForm — embeddable form widget for creating and editing
/// transactions. Host screens own all chrome (Scaffold, AppBar, save CTA).
///
/// Configuration via [TransactionDetailsFormConfig]:
///   - `.$new(...)` — new entry mode
///   - `.edit(seed: tx)` — edit-existing mode
///
/// Submit via GlobalKey[TransactionDetailsFormState].currentState!.submit()
/// which returns [Future] of [TransactionDetailsFormResult].
///
/// Locale-aware formatting is delegated to child widgets (DetailInfoCard);
/// Phase 19/22 may revisit if in-form formatting is needed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/create_transaction_use_case.dart';
import '../../../../application/accounting/update_transaction_use_case.dart';
import '../../../../application/currency/get_exchange_rate_use_case.dart';
import '../../../../application/currency/rate_result.dart';
import '../../../../application/currency/repository_providers.dart';
import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/dual_ledger/presentation/widgets/joy_celebration_overlay.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/utils/currency_conversion.dart'
    show convertToJpy, subunitToUnitFor, validateAppliedRate;
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/repository_providers.dart';
import '../screens/category_selection_screen.dart';
import '../utils/category_display_utils.dart';
import '../widgets/currency_linked_edit_fields.dart';
import '../widgets/detail_info_card.dart';
import '../widgets/keyboard_toolbar.dart' show kKeyboardToolbarTapRegionGroup;
import '../../../../shared/widgets/ledger_type_selector.dart';
import '../widgets/satisfaction_emoji_picker.dart';

/// Embeddable form for creating and editing transactions.
///
/// No Scaffold, AppBar, or save CTA inside — the host screen owns all chrome
/// (D-01). The host calls [TransactionDetailsFormState.submit] via a
/// [GlobalKey] of [TransactionDetailsFormState] and handles post-save
/// navigation.
class TransactionDetailsForm extends ConsumerStatefulWidget {
  const TransactionDetailsForm({
    super.key,
    required this.config,
    this.merchantFocusNode,
    this.noteFocusNode,
    this.onPickerDismissed,
    this.onForeignChanged,
  });

  final TransactionDetailsFormConfig config;

  /// Phase 42-09 / UAT fix: fired with the full [CurrencyLinkedEditValue]
  /// (original amount in minor units + applied rate + derived JPY) whenever a
  /// foreign row's original amount or rate is edited inside the linked edit
  /// host. The edit screen wires this to keep its top headline in lock-step:
  /// the headline shows the ORIGINAL currency + amount (consistency with the
  /// entry screen), so it reads `value.originalAmount`; the JPY figure remains
  /// the card's derived row (ADR-022 D-01, one direction only). Null in hosts
  /// without a top headline.
  final ValueChanged<CurrencyLinkedEditValue>? onForeignChanged;

  /// Presentation-layer form wiring (moved off the domain config to keep
  /// [TransactionDetailsFormConfig] free of package:flutter — CRIT-04).
  /// Only new-entry hosts supply these; null in edit / voice / OCR hosts,
  /// in which case the TextFields fall back to their own internal FocusNode.
  final FocusNode? merchantFocusNode;
  final FocusNode? noteFocusNode;

  /// Fired after a date/category picker dismisses (pick OR cancel).
  /// ManualOneStepScreen wires this to reclaim amount focus so the
  /// SmartKeyboard reappears. Null in hosts that don't render the keypad.
  final VoidCallback? onPickerDismissed;

  @override
  ConsumerState<TransactionDetailsForm> createState() =>
      TransactionDetailsFormState();
}

/// Public state class — required for GlobalKey of [TransactionDetailsFormState]
/// in host screens (D-02).
class TransactionDetailsFormState
    extends ConsumerState<TransactionDetailsForm> {
  final _storeController = TextEditingController();
  final _memoController = TextEditingController();

  late int _amount;
  Category? _category;
  Category? _parentCategory;
  late DateTime _date;

  // Phase 42 (CURR-01/05, SC-5): host-owned foreign-currency triple. Null on
  // JPY-native entry (CURR-04 — the JPY path never sets these, so submit()
  // forwards nulls and the create use case persists a native JPY row exactly as
  // before). Set non-null by the host via [updateCurrencyTriple] once a foreign
  // currency is selected AND a rate has resolved. All three move together
  // (partial triples are rejected by the use case).
  String? _originalCurrency;
  int? _originalAmount;
  String? _appliedRate;

  // Phase 42 GAP (WR-06): true while the foreign edit host reports its original
  // amount as cleared / non-positive / unparseable. Gates submit() so a Save
  // taken while the amount field is visibly empty does NOT silently persist the
  // previous last-good amount (the edit host stops firing onChanged in that
  // state, so _originalAmount/_amount would otherwise retain stale values).
  bool _foreignAmountInvalid = false;

  String? _initialCategoryId;
  LedgerType _ledgerType = LedgerType.daily;
  int _joyFullness = 2;
  bool _isSubmitting = false;

  // Joy-save celebration temporarily disabled per user request (2026-06-03,
  // quick-260603-nr1 follow-up): "先不要了，后续再看如何添加".
  // Flip to true to restore the joy save sparkle animation — all scaffolding
  // (overlay widget, completer machinery, waitForCelebrationDismissed) is left
  // intact so re-enabling is a one-line change. See joy_celebration_overlay.dart.
  static const bool _kJoyCelebrationEnabled = false;

  // Drives the celebration Stack overlay; only mutated by .new branch (D-15).
  bool _showCelebration = false;

  /// Phase 23 D-08 / WR-04: completion future for the joy celebration overlay.
  /// Initialized just before the overlay mounts; completed in [onDismissed].
  /// [waitForCelebrationDismissed] returns this future so the voice screen can
  /// defer Navigator.popUntil until the animation finishes (RESEARCH §Pattern 3
  /// Option A). Null when no celebration is pending.
  Completer<void>? _celebrationCompleter;

  // Local category cache for parent-lookup (mirrors analog _categoryById).
  final Map<String, Category> _categoryById = {};

  /// True when this form is configured as `.edit` (vs `.new`). Drives the
  /// Phase 42-09 foreign-currency edit host, which only renders in edit mode.
  bool get _isEditMode =>
      widget.config.maybeWhen(edit: (_) => true, orElse: () => false);

  @override
  void initState() {
    super.initState();
    widget.config.when(
      $new:
          (
            bookId,
            initialAmount,
            initialCategory,
            initialParentCategory,
            initialMerchant,
            initialSatisfaction,
            initialDate,
            entrySource,
            voiceKeyword,
          ) {
            _amount = initialAmount ?? 0;
            _category = initialCategory;
            _parentCategory = initialParentCategory;
            _date = initialDate ?? DateTime.now();
            _initialCategoryId = initialCategory?.id;
            if (initialMerchant != null) {
              _storeController.text = initialMerchant;
            }
            if (initialSatisfaction != null) {
              _joyFullness = initialSatisfaction.clamp(1, 10);
            }
            // Resolve ledger type from category if one was pre-seeded.
            if (_category != null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _resolveLedgerType(_category!.id),
              );
            }
          },
      edit: (seed) {
        // .edit init: preload all mutable fields from seed verbatim (D-07).
        // seed.ledgerType used as-is — _resolveLedgerType is NOT called (W3).
        _amount = seed.amount;
        // Phase 42-09 (DISP-03 / ADR-022 D-01): seed the foreign-currency triple
        // so the edit host can render the three linked rows. Null on JPY-native
        // rows (CURR-04 — the JPY edit path stays byte-identical).
        _originalCurrency = seed.originalCurrency;
        _originalAmount = seed.originalAmount;
        _appliedRate = seed.appliedRate;
        _date = seed.timestamp;
        _ledgerType = seed.ledgerType;
        _joyFullness = seed.joyFullness;
        _storeController.text = seed.merchant ?? '';
        _memoController.text = seed.note ?? '';
        _initialCategoryId = seed.categoryId;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadCategoryFromSeed(seed.categoryId),
        );
      },
    );
  }

  @override
  void dispose() {
    _storeController.dispose();
    _memoController.dispose();
    _celebrationCompleter = null;
    super.dispose();
  }

  // ── Async helpers ──────────────────────────────────────────────────────────

  /// Loads the category and its parent from the repository for .edit mode.
  ///
  /// W3 fix: handles null gracefully (deleted/orphaned categoryId) — sets both
  /// _category and _parentCategory to null so the form renders in
  /// "please select" state rather than crashing.
  Future<void> _loadCategoryFromSeed(String categoryId) async {
    final cat = await ref.read(categoryRepositoryProvider).findById(categoryId);
    if (!mounted) return;
    if (cat == null) {
      setState(() {
        _category = null;
        _parentCategory = null;
      });
      return;
    }
    // Warm the local cache.
    _categoryById[cat.id] = cat;
    Category? parent = resolveParentCategory(cat, _categoryById);
    if (parent == null && cat.parentId != null) {
      parent = await ref
          .read(categoryRepositoryProvider)
          .findById(cat.parentId!);
      if (parent != null) _categoryById[parent.id] = parent;
    }
    if (!mounted) return;
    setState(() {
      _category = cat;
      _parentCategory = parent;
    });
    // .edit mode: DO NOT call _resolveLedgerType here — seed.ledgerType is
    // authoritative and was already set in initState (W3 clarification).
  }

  /// Resolves the default ledger type for [categoryId] via CategoryService.
  ///
  /// Called only in .new mode — after initState and after a category change.
  /// .edit mode uses seed.ledgerType verbatim (W3).
  Future<void> _resolveLedgerType(String categoryId) async {
    final service = ref.read(categoryServiceProvider);
    final resolved = await service.resolveLedgerType(categoryId);
    if (mounted && resolved != null) {
      setState(() => _ledgerType = resolved);
    }
  }

  // ── Field edit affordances ─────────────────────────────────────────────────

  /// Phase 19 D-14 — host owns amount editing UX; form widget keeps `_amount`
  /// in sync for save-time validation in `submit()`.
  ///
  /// Short-circuits if the new value equals the current `_amount` (Pattern S-1
  /// idempotency — prevents unnecessary rebuilds when the host's SmartKeyboard
  /// fires on every digit).
  void updateAmount(int amount) {
    if (!mounted) return;
    if (amount == _amount) return;
    setState(() => _amount = amount);
  }

  /// Phase 42 (CURR-01/05, SC-5) — host pushes the foreign-currency triple so
  /// `submit()` persists `originalCurrency` / `originalAmount` (minor units) /
  /// `appliedRate` alongside the converted JPY `_amount`. Pass all three null to
  /// clear back to a JPY-native row (CURR-04 — the host clears these when JPY is
  /// re-selected, so the create use case sees no currency fields and the JPY
  /// persist path is byte-identical to pre-Phase-42).
  ///
  /// The host owns the conversion: it sets `_amount` (the JPY figure from the
  /// single-site `convertToJpy()`) via [updateAmount], and the triple via this
  /// method — keeping the persisted JPY and the stored original in lock-step.
  ///
  /// Idempotency: short-circuits when the new triple equals the current one so
  /// repeated host pushes (e.g. on every keypad tap) don't rebuild-storm.
  void updateCurrencyTriple({
    required String? originalCurrency,
    required int? originalAmount,
    required String? appliedRate,
  }) {
    if (!mounted) return;
    if (originalCurrency == _originalCurrency &&
        originalAmount == _originalAmount &&
        appliedRate == _appliedRate) {
      return;
    }
    setState(() {
      _originalCurrency = originalCurrency;
      _originalAmount = originalAmount;
      _appliedRate = appliedRate;
    });
  }

  /// Phase 42-09 (DISP-03 / ADR-022 D-01) — imperative host sync for the
  /// foreign currency code. Mirrors [updateAmount]'s idempotency short-circuit
  /// (host-owns, form-syncs). Setting a non-JPY code marks the row foreign so
  /// the edit host renders the three linked rows; the JPY `_amount` is NOT
  /// recomputed here (the rate may not yet be resolved) — the host pushes the
  /// resolved rate via [updateRate], which recomputes the derived JPY.
  void updateCurrency(String currency) {
    if (!mounted) return;
    if (currency == _originalCurrency) return;
    setState(() => _originalCurrency = currency);
  }

  /// Phase 42-09 (DISP-03 / ADR-022 D-01) — imperative host sync for the applied
  /// rate. On a valid rate AND a present foreign triple, recomputes the derived
  /// JPY `_amount` via the single-site [convertToJpy] (D-12, one direction only:
  /// original × rate → JPY; JPY never writes back). Mirrors [updateAmount]'s
  /// idempotency short-circuit. Invalid rates are stored but skip the recompute
  /// (the edit host surfaces the inline validation error and blocks save).
  void updateRate(String rate) {
    if (!mounted) return;
    if (rate == _appliedRate) return;
    setState(() {
      _appliedRate = rate;
      final amount = _originalAmount;
      final currency = _originalCurrency;
      if (amount != null &&
          currency != null &&
          validateAppliedRate(rate) == null) {
        _amount = convertToJpy(
          originalMinorUnits: amount,
          appliedRate: rate,
          subunitToUnit: subunitToUnitFor(currency),
        );
      }
    });
  }

  /// Quick task 260613-mgc — host (TransactionEditScreen headline keypad)
  /// pushes the edited foreign ORIGINAL amount (in MINOR units) here after the
  /// currency-aware [AmountEditBottomSheet] confirms. Mirrors [updateRate]'s
  /// idempotency + single-site recompute: on a valid triple it recomputes the
  /// derived JPY `_amount` via [convertToJpy] (D-12, one direction only —
  /// original × rate → JPY; JPY never writes back) and clears the
  /// [_foreignAmountInvalid] gate. The CurrencyLinkedEditFields card re-derives
  /// its JPY row from the injected [_originalAmount] on the next rebuild.
  void updateOriginalAmount(int minorUnits) {
    if (!mounted) return;
    if (minorUnits == _originalAmount) return;
    setState(() {
      _originalAmount = minorUnits;
      final currency = _originalCurrency;
      final rate = _appliedRate;
      if (minorUnits > 0 &&
          currency != null &&
          rate != null &&
          validateAppliedRate(rate) == null) {
        _amount = convertToJpy(
          originalMinorUnits: minorUnits,
          appliedRate: rate,
          subunitToUnit: subunitToUnitFor(currency),
        );
        _foreignAmountInvalid = false;
      } else {
        // Non-positive / invalid amount — gate save (WR-06).
        _foreignAmountInvalid = minorUnits <= 0;
      }
    });
  }

  /// Phase 22 D-07 — host (VoiceInputScreen) pushes voice-resolved category +
  /// parent via this method on `_stopRecordingAndCommit` batch fill. Mirrors
  /// the internal `_editCategory` write set + ledger resolution so behavior is
  /// identical regardless of whether the user tapped the chevron or voice
  /// resolved a category.
  ///
  /// Idempotency: short-circuits when `category.id == _category?.id`. Caller
  /// may invoke repeatedly without rebuild storms.
  void updateCategory(Category category, Category? parentCategory) {
    if (!mounted) return;
    if (category.id == _category?.id) return;
    setState(() {
      _categoryById[category.id] = category;
      if (parentCategory != null) {
        _categoryById[parentCategory.id] = parentCategory;
      }
      _category = category;
      _parentCategory = parentCategory;
    });
    _resolveLedgerType(category.id);
  }

  /// Phase 22 D-07 — host pushes voice-resolved merchant string via this
  /// method on batch fill. Assigning `.text` on the existing controller
  /// triggers a TextField rebuild without recreating the controller.
  ///
  /// Idempotency: short-circuits when the new value equals the current
  /// `_storeController.text`. Prevents cursor-reset (Pitfall 3) on re-runs.
  void updateMerchant(String merchant) {
    if (!mounted) return;
    if (merchant == _storeController.text) return;
    _storeController.text = merchant;
  }

  /// Phase 22 D-07 — public surface for note batch-fill. In v1.3 the voice
  /// parser does NOT emit a discrete note (per RESEARCH §Assumptions A5);
  /// this method exists for forward-compat with future parser revisions and
  /// is typically a no-op call from the voice screen.
  void updateNote(String note) {
    if (!mounted) return;
    if (note == _memoController.text) return;
    _memoController.text = note;
  }

  /// Phase 22 D-07 / RESEARCH §Open Q2 — host pushes the voice-estimated
  /// joy-ledger satisfaction value via this method on batch fill. Preserves
  /// the Phase 11 `VoiceSatisfactionEstimator` → `_parseResult.estimatedSatisfaction`
  /// pipeline through the Phase 22 single-screen rewrite (deletion of
  /// `_navigateToConfirm` in Plan 04 removes the previous handoff via
  /// `initialSatisfaction:`).
  ///
  /// Joy-ledger only — for daily-ledger categories the satisfaction field
  /// is not rendered; calling this method is harmless (state is still mutated
  /// but never read at submit() time).
  ///
  /// Idempotency: short-circuits when the new value equals the current
  /// `_joyFullness`.
  void updateSatisfaction(int satisfaction) {
    if (!mounted) return;
    if (satisfaction == _joyFullness) return;
    setState(() => _joyFullness = satisfaction.clamp(1, 10));
  }

  /// Phase 23 D-08 / WR-04: host-await accessor used by the voice screen to
  /// defer Navigator.popUntil until the joy celebration animation finishes
  /// (RESEARCH §Pattern 3 Option A). Returns immediately if no celebration
  /// is pending.
  Future<void> waitForCelebrationDismissed() {
    return _celebrationCompleter?.future ?? Future.value();
  }

  /// Quick task 260526-k92 (Item 4): host pushes voice-resolved date via this
  /// method on batch fill. Mirrors the public-setter contract of
  /// `updateAmount` / `updateCategory` so the voice screen can populate `_date`
  /// without touching the date picker. Whole-day comparison short-circuits
  /// idempotent re-runs.
  void updateDate(DateTime date) {
    if (!mounted) return;
    final normalized = DateTime(date.year, date.month, date.day);
    final current = DateTime(_date.year, _date.month, _date.day);
    if (normalized == current) return;
    setState(() => _date = normalized);
  }

  /// Item 4 (260526-j98): fires the host-supplied `onPickerDismissed` callback
  /// (if any) after a date/category picker closes — regardless of whether the
  /// user picked or cancelled. ManualOneStepScreen uses this to reclaim amount
  /// focus so the SmartKeyboard reappears.
  void _notifyPickerDismissed() {
    if (!mounted) return;
    widget.onPickerDismissed?.call();
  }

  Future<void> _editCategory() async {
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _category?.id),
      ),
    );
    // Item 4: cancel path — picker dismissed without selection.
    if (result == null || !mounted) {
      _notifyPickerDismissed();
      return;
    }

    // Resolve parent for display path.
    Category? parent = resolveParentCategory(result, _categoryById);
    if (parent == null && result.parentId != null) {
      final repo = ref.read(categoryRepositoryProvider);
      parent = await repo.findById(result.parentId!);
    }

    if (!mounted) return;
    setState(() {
      _categoryById[result.id] = result;
      if (parent != null) _categoryById[parent.id] = parent;
      _category = result;
      _parentCategory = parent;
    });

    // Resolve ledger type for .new mode after category change.
    await _resolveLedgerType(result.id);

    if (!mounted) return;

    // Voice-correction gate (D-09): .new mode only, fires when category
    // changed from the initial voice-matched one.
    await widget.config.maybeWhen(
      $new:
          (
            nBookId,
            nInitialAmount,
            nInitialCategory,
            nInitialParentCategory,
            nInitialMerchant,
            nInitialSatisfaction,
            nInitialDate,
            nEntrySource,
            voiceKeyword,
          ) async {
            if (voiceKeyword != null &&
                voiceKeyword.isNotEmpty &&
                result.id != _initialCategoryId) {
              final correctionUseCase = ref.read(
                recordCategoryCorrectionUseCaseProvider,
              );
              await correctionUseCase.execute(
                keyword: voiceKeyword,
                correctedCategoryId: result.id,
              );
            }
          },
      orElse: () {},
    );

    // Item 4: success path — fire after voice-correction tail.
    _notifyPickerDismissed();
  }

  Future<void> _editDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: context.palette.daily),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
    // Item 4: fire dismissal callback on BOTH pick and cancel paths.
    _notifyPickerDismissed();
  }

  /// Phase 42 GAP-CLOSURE: resolve the REAL re-fetched rate for a foreign edit
  /// row's CURRENT date via the already-wired `appGetExchangeRateUseCaseProvider`
  /// (same use case the entry preview consumes — `conversion_preview_panel`).
  ///
  /// Supplied to [CurrencyLinkedEditFields.dateChangeRefetchRate] so its
  /// ADR-022 D-02 dialog / D-03 toast decision logic runs against the REAL rate
  /// instead of a hardcoded stub.
  ///
  /// never-block-save (P41): returns null on [RateUnavailable] (offline /
  /// no rate) so the edit host degrades gracefully — the existing rate stays,
  /// nothing is blocked. Reads (not watches) the provider — this is a one-shot
  /// side-effect, not a reactive dependency (Riverpod 3 / CLAUDE.md).
  Future<String?> _refetchRateForCurrentDate() async {
    final currency = _originalCurrency;
    if (currency == null) return null;

    final useCase = ref.read(appGetExchangeRateUseCaseProvider);
    final withSignal = await useCase.execute(
      GetExchangeRateParams(currency: currency, date: _date),
    );
    return _extractRate(withSignal.result);
  }

  /// Rate string for any rate-bearing variant; null for [RateUnavailable]
  /// (mirrors the entry preview's extraction — never throws).
  String? _extractRate(RateResult result) => switch (result) {
    RateFetched(:final rate) => rate,
    RateCached(:final rate) => rate,
    RateFallback(:final rate) => rate,
    RateManual(:final rate) => rate,
    RateUnavailable() => null,
  };

  // ── Public submit() — invoked by host CTA via GlobalKey (D-02) ─────────────

  /// Validates the form and persists via the appropriate use case.
  ///
  /// Returns [TransactionDetailsFormResult.validationError] if [_category] is
  /// null (user has not selected a category), without calling any use case.
  ///
  /// On success:
  /// - `.new` mode: may show [JoyCelebrationOverlay] if saved as joy (D-15).
  /// - `.edit` mode: never shows celebration overlay (D-15 invariant).
  ///
  /// Host is responsible for post-save navigation and snackbars.
  Future<TransactionDetailsFormResult> submit() async {
    if (_category == null) {
      return TransactionDetailsFormResult.validationError(
        S.of(context).pleaseSelectCategory,
      );
    }
    // WR-06: a foreign row whose original amount is cleared / invalid must NOT
    // save with the stale last-good amount. Block it with the same affordance as
    // an empty amount, rather than silently persisting _amount/_originalAmount.
    if (_foreignAmountInvalid) {
      return TransactionDetailsFormResult.validationError(
        S.of(context).pleaseEnterAmount,
      );
    }
    setState(() => _isSubmitting = true);
    try {
      return await widget.config.when(
        $new:
            (
              bookId,
              newInitialAmount,
              newInitialCategory,
              newInitialParentCategory,
              newInitialMerchant,
              newInitialSatisfaction,
              newInitialDate,
              entrySource,
              voiceKeyword,
            ) async {
              final result = await ref
                  .read(createTransactionUseCaseProvider)
                  .execute(
                    CreateTransactionParams(
                      bookId: bookId,
                      amount: _amount,
                      type: TransactionType.expense,
                      categoryId: _category!.id,
                      timestamp: _date,
                      note: _memoController.text.trim().isEmpty
                          ? null
                          : _memoController.text.trim(),
                      merchant: _storeController.text.trim().isEmpty
                          ? null
                          : _storeController.text.trim(),
                      joyFullness: _ledgerType == LedgerType.joy
                          ? _joyFullness
                          : null,
                      ledgerType: _ledgerType,
                      entrySource: entrySource,
                      // Phase 42 SC-5: forward the host-owned foreign-currency
                      // triple. Null on JPY-native entry (CURR-04) → native row.
                      originalCurrency: _originalCurrency,
                      originalAmount: _originalAmount,
                      appliedRate: _appliedRate,
                    ),
                  );
              if (!result.isSuccess) {
                if (!mounted) {
                  // Widget disposed before result arrived — host's !mounted guard
                  // prevents this value from reaching the UI. Use an internal
                  // sentinel rather than a hardcoded English string.
                  return const TransactionDetailsFormResult.persistError(
                    'INTERNAL_UNMOUNTED',
                  );
                }
                return TransactionDetailsFormResult.persistError(
                  result.error ?? S.of(context).failedToSave,
                );
              }
              final tx = result.data!;

              // Merchant-learning hook (Phase 18 D-09, ported to this form from
              // the legacy two-screen flow): record merchant→category preference
              // so the ML classifier improves suggestions over time.
              final merchantRaw = _storeController.text.trim();
              if (merchantRaw.isNotEmpty && mounted) {
                await ref
                    .read(merchantCategoryLearningServiceProvider)
                    .recordSelection(
                      merchantRaw: merchantRaw,
                      selectedCategoryId: _category!.id,
                    );
              }

              // D-15: celebration only for .new joy saves. .edit branch never
              // touches _showCelebration.
              // Phase 23 D-08: initialize the completer before showing the overlay
              // so waitForCelebrationDismissed() returns a pending future.
              if (_kJoyCelebrationEnabled &&
                  tx.ledgerType == LedgerType.joy &&
                  mounted) {
                _celebrationCompleter = Completer<void>();
                setState(() => _showCelebration = true);
              }
              return TransactionDetailsFormResult.success(tx);
            },
        edit: (seed) async {
          final result = await ref
              .read(updateTransactionUseCaseProvider)
              .execute(
                UpdateTransactionParams(
                  seed: seed,
                  amount: _amount,
                  categoryId: _category!.id,
                  timestamp: _date,
                  note: _memoController.text.trim().isEmpty
                      ? null
                      : _memoController.text.trim(),
                  merchant: _storeController.text.trim().isEmpty
                      ? null
                      : _storeController.text.trim(),
                  ledgerType: _ledgerType,
                  joyFullness: _ledgerType == LedgerType.joy
                      ? _joyFullness
                      : null,
                  // Phase 42-09 (DISP-03/04, ADR-022): persist the edited
                  // foreign-currency triple via the extended use case. Coalesce
                  // semantics (EDIT-02): these are the host-owned current values,
                  // which were seeded from `seed` and may have been edited via
                  // the linked edit host. The use case excludes them from the
                  // hash chain (ADR-021 — no rehash on currency fields).
                  originalCurrency: _originalCurrency,
                  originalAmount: _originalAmount,
                  appliedRate: _appliedRate,
                ),
              );
          // .edit branch NEVER sets _showCelebration (D-15 invariant).
          if (!result.isSuccess) {
            if (!mounted) {
              // Widget disposed before result arrived — internal sentinel
              // (host's !mounted guard already prevents UI display).
              return const TransactionDetailsFormResult.persistError(
                'INTERNAL_UNMOUNTED',
              );
            }
            return TransactionDetailsFormResult.persistError(
              result.error ?? S.of(context).failedToUpdate,
            );
          }
          return TransactionDetailsFormResult.success(result.data!);
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  String _categoryLabel(Locale locale, S l10n) {
    if (_category == null) return l10n.pleaseSelectCategory;
    return formatCategoryPath(
      category: _category!,
      parentCategory: _parentCategory,
      locale: locale,
    );
  }

  Widget _buildMerchantRow(S l10n) {
    final palette = context.palette;
    final secondaryColor = palette.textSecondary;
    final tertiaryColor = palette.textTertiary;
    final primaryColor = palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.store_outlined, size: 16, color: tertiaryColor),
          const SizedBox(width: 8),
          Text(
            l10n.merchant,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: const ValueKey('merchant-textfield'),
              controller: _storeController,
              focusNode: widget.merchantFocusNode,
              // 260526-r8y Item 3: shared TapRegion group with KeyboardToolbar
              // so taps on the toolbar are treated as inside-region — onTapOutside
              // does NOT fire, the toolbar stays mounted, and save fires.
              groupId: kKeyboardToolbarTapRegionGroup,
              textAlign: TextAlign.end,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.enterStore,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: secondaryColor,
                  fontSize: 14,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(S l10n) {
    final palette = context.palette;
    final secondaryColor = palette.textSecondary;
    final tertiaryColor = palette.textTertiary;
    final primaryColor = palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: tertiaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.note,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: secondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.backgroundMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              key: const ValueKey('note-textfield'),
              controller: _memoController,
              focusNode: widget.noteFocusNode,
              // 260526-r8y Item 3: shared TapRegion group with KeyboardToolbar.
              groupId: kKeyboardToolbarTapRegionGroup,
              maxLines: null,
              expands: true,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l10n.enterMemo,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: secondaryColor,
                  fontSize: 13,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Item 1 (260526-j98): shared rounded-card wrapper for Card B (ledger +
  /// satisfaction) and Card C (note). Dedupes the inline Container decoration
  /// previously used only for Card B.
  Widget _formCard({required Widget child}) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.value ?? const Locale('ja');
    final palette = context.palette;
    final displayCategory = _parentCategory ?? _category;

    // AbsorbPointer prevents field interaction while submit is in progress.
    final formBody = AbsorbPointer(
      absorbing: _isSubmitting,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick task 260613-mgc: the foreign-currency card (rate + derived
            // JPY) renders ABOVE the category/date card. Original-amount editing
            // moved to the screen's top headline keypad; this card now carries
            // only two rows. Rendered only for foreign rows; JPY-native rows
            // skip it entirely (CURR-04 regression protection).
            if (_isEditMode &&
                _originalCurrency != null &&
                _originalAmount != null &&
                _appliedRate != null) ...[
              _formCard(
                child: CurrencyLinkedEditFields(
                  key: const ValueKey('currency-linked-edit-fields'),
                  originalCurrency: _originalCurrency!,
                  originalAmount: _originalAmount!,
                  appliedRate: _appliedRate!,
                  manualOverride: false,
                  // GAP-CLOSURE: feed the host's REAL exchange-rate re-fetch into
                  // the edit host's D-02/D-03 logic (drops the 160.00 stub).
                  dateChangeRefetchRate: _refetchRateForCurrentDate,
                  onChanged: (value) {
                    // One direction only (ADR-022 D-01): original × rate → JPY.
                    // Keep the host triple + derived JPY in lock-step for submit.
                    if (!mounted) return;
                    setState(() {
                      _originalAmount = value.originalAmount;
                      _appliedRate = value.appliedRate;
                      _amount = value.jpyAmount;
                      // A valid onChanged means the amount is valid again.
                      _foreignAmountInvalid = false;
                    });
                    // Notify the screen so its top headline tracks the ORIGINAL
                    // amount + currency live (foreign rows only). The screen
                    // reads value.originalAmount for the headline and keeps
                    // value.jpyAmount for the card's derived row.
                    widget.onForeignChanged?.call(value);
                  },
                  // WR-06: the edit host reports a cleared/invalid amount here
                  // (onChanged stays silent in that state). Track it so submit()
                  // blocks rather than persisting the stale last-good amount.
                  onAmountInvalid: (invalid) {
                    if (!mounted) return;
                    setState(() => _foreignAmountInvalid = invalid);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            DetailInfoCard(
              rows: [
                DetailInfoRow(
                  key: const ValueKey('category-chip'),
                  icon: displayCategory != null
                      ? resolveCategoryIcon(displayCategory.icon)
                      : Icons.shopping_bag_outlined,
                  label: l10n.category,
                  value: _categoryLabel(locale, l10n),
                  showChevron: true,
                  onTap: _editCategory,
                ),
                DetailInfoRow(
                  key: const ValueKey('date-chip'),
                  icon: Icons.calendar_today_outlined,
                  label: l10n.date,
                  value: const FormatterService().formatDate(_date, locale),
                  showChevron: true,
                  onTap: _editDate,
                ),
              ],
              trailing: _buildMerchantRow(l10n),
            ),

            const SizedBox(height: 16),

            // Card B: 用途 (Purpose) header + ledger + (joy) satisfaction.
            _formCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 260529-e5f: 用途 title and the ledger pills share one
                    // row (pills on the right) so Card B is shorter and the
                    // joy satisfaction picker below gets more vertical room.
                    // Flexible wraps the title so a long localized label
                    // ellipsises instead of overflowing the row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.expenseClassification,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontSize: 13,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        LedgerTypeSelector(
                          selected: _ledgerType,
                          onChanged: (type) =>
                              setState(() => _ledgerType = type),
                          dailyLabel: l10n.dailyExpense,
                          joyLabel: l10n.joyExpense,
                        ),
                      ],
                    ),
                    if (_ledgerType == LedgerType.joy) ...[
                      const SizedBox(height: 12),
                      SatisfactionEmojiPicker(
                        value: _joyFullness,
                        onChanged: (v) => setState(() => _joyFullness = v),
                        title: l10n.satisfactionLevel,
                        levelLabels: [
                          l10n.satisfactionBad,
                          l10n.satisfactionSlightlyBad,
                          l10n.satisfactionNormal,
                          l10n.satisfactionGood,
                          l10n.satisfactionVeryGood,
                        ],
                        bottomLabels: [
                          l10n.satisfactionBad,
                          l10n.satisfactionNormal,
                          l10n.satisfactionExcellent,
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card C: 备注 (note) — extracted from Card A's trailing so the
            // note has its own rounded card per Item 1 (260526-j98).
            _formCard(child: _buildNoteSection(l10n)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    // Wrap body in Stack for celebration overlay (D-15).
    return Stack(
      children: [
        formBody,
        // D-15: joy-celebration overlay — .new mode only; dismissed on
        // animation completion. .edit branch never sets _showCelebration.
        if (_showCelebration)
          Positioned.fill(
            child: JoyCelebrationOverlay(
              onDismissed: () {
                // Phase 23 D-08: complete the host-await future FIRST so the
                // voice screen's deferred pop fires before the overlay clears.
                if (_celebrationCompleter != null &&
                    !_celebrationCompleter!.isCompleted) {
                  _celebrationCompleter!.complete();
                }
                if (mounted) setState(() => _showCelebration = false);
              },
            ),
          ),
      ],
    );
  }
}
