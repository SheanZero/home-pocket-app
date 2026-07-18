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
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../providers/repository_providers.dart';
import '../screens/category_selection_screen.dart';
import '../utils/category_display_utils.dart';
import '../widgets/alternate_category_chips.dart';
import '../../../voice/domain/models/recognition_outcome.dart'
    show ConfidenceBand;
import '../../../voice/domain/models/voice_parse_result.dart'
    show CategoryMatchResult;
import '../widgets/conversion_preview_panel.dart'
    show rateStringOf, rateEffectiveDateOf, stalenessNoteFor;
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
    this.onDateChanged,
    this.showAlternateChips = false,
    this.useV16Layout = false,
  });

  final TransactionDetailsFormConfig config;

  /// Opt-in compact presentation used by the unified-entry and transaction
  /// edit surfaces in the v16 mockup. The legacy layout remains the default so
  /// voice/OCR and other existing hosts keep their current geometry.
  final bool useV16Layout;

  /// Phase 52 / 52-UAT (test 2): whether the alternate-category chip row (≤3
  /// suggested alternates + the trailing "more" exit chip) renders after a
  /// voice recognition. HIDDEN by default at the user's request, together with
  /// the former decorative confidence band. This is a reversible scope-cut:
  /// the [AlternateCategoryChips] widget, the chip-tap
  /// handler ([_selectAlternateCategory]) and their tests are all kept intact;
  /// flip the default to `true` (or remove this flag) to restore the chips.
  /// Category correction is unaffected — it still flows through the category-card
  /// edit ([_editCategory] → full selector → [_applyCategorySelection]), so the
  /// deferred-correction contract (D-05/06/07) still holds. Only the retained
  /// chip-path widget tests construct the form with `showAlternateChips: true`.
  @visibleForTesting
  final bool showAlternateChips;

  /// Quick 260613-ufn (D-4): fired with the new transaction date whenever the
  /// form's internal date changes via the date picker. The ADD screen
  /// (ManualOneStepScreen) wires this to keep its own `_selectedDate` in
  /// lock-step so the keyed `conversionRateProvider` re-resolves the rate for
  /// the new date and the unified card's 汇率/日元/汇率日期/staleness update. Null
  /// in hosts (edit) that own the date and the card together.
  final ValueChanged<DateTime>? onDateChanged;

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

  // Quick 260613-ufn (D-2/D-4): the ACTUAL effective rate date + pre-resolved
  // staleness note fed into the unified card's non-clickable 汇率日期 row. Both
  // are derived from the SAME RateResult via the shared single staleness site
  // (conversion_preview_panel.dart). Null until a rate has been resolved for
  // the current date.
  DateTime? _foreignActualRateDate;
  String? _foreignStalenessNote;

  /// Card key (quick 260613-ufn D-4): lets the date-picker flow invoke the
  /// card's retained ADR-022 D-02/D-03 logic via triggerDateChangeRefetch()
  /// after the date changes — the in-card clickable trigger was removed (D-3).
  final GlobalKey<CurrencyLinkedEditFieldsState> _currencyCardKey =
      GlobalKey<CurrencyLinkedEditFieldsState>();

  String? _initialCategoryId;

  // Phase 52 (RECUX-03 / D-05/D-06/D-07): the deferred category-correction
  // stash. Set when the user changes the category away from the recognized
  // original ([_initialCategoryId]) via EITHER a chip tap (52-02) OR the full
  // selector; carries `resolvedKeyword` verbatim (write==read identity,
  // 260526-pg6) plus the corrected categoryId. The KEYWORD-table write is
  // DEFERRED to confirmed save and fires exactly once (D-05). Cleared with NO
  // write when the category returns to the original, or on the host-driven
  // reset / 连续记账 / back paths (via [updateCategory], [restoreCategory],
  // or [discardPendingCorrection]).
  // A null/empty keyword never produces a stash — and the merchant table is
  // never touched on this path (D-07, D-16).
  _PendingCategoryCorrection? _pendingCorrection;

  LedgerType _ledgerType = LedgerType.daily;

  /// Invalidates stale asynchronous category-to-ledger resolutions when a host
  /// restores an authoritative ledger snapshot.
  int _ledgerResolutionEpoch = 0;

  int _joyFullness = 2;
  bool _isSubmitting = false;

  // Phase 52 (RECUX-01/02 / D-08/D-09/D-10): recognition confidence state.
  // Pushed by the voice host at resolve-on-final via [updateRecognition] (D-08)
  // and retained for the weak-category save guard/correction path. The former
  // decorative band is intentionally no longer rendered in the entry form.
  // State clears as soon as the user makes an authoritative category choice.
  ConfidenceBand? _band;
  List<CategoryMatchResult> _alternates = const <CategoryMatchResult>[];

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

  /// True for a newly-created row whose live config has been promoted to voice
  /// after a successful PTT fill. Used by the weak-category save guard only;
  /// voice provenance badges are intentionally not rendered in V16.
  bool get _isV16VoiceNewEntry =>
      widget.useV16Layout &&
      widget.config.maybeWhen(
        $new: (_, _, _, _, _, _, _, entrySource, _) =>
            entrySource == EntrySource.voice,
        orElse: () => false,
      );

  bool get _needsV16CategorySelection =>
      _isV16VoiceNewEntry &&
      _category == null &&
      (_band == ConfidenceBand.weak || _alternates.isNotEmpty);

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
    final epoch = ++_ledgerResolutionEpoch;
    final service = ref.read(categoryServiceProvider);
    final resolved = await service.resolveLedgerType(categoryId);
    if (mounted && epoch == _ledgerResolutionEpoch && resolved != null) {
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

  // ── 260622-nhs R2: read-only snapshot accessors ───────────────────────────
  //
  // The single-page voice-record modal (D-2 reset-restore) snapshots the form
  // BEFORE auto-filling so the 「重置·恢复账目」 button can roll the form back to
  // the pre-speech state. These getters expose the mutable fields the imperative
  // `update*` setters write, so the host can capture and re-apply them without
  // the form leaking its internal controllers.

  /// Current JPY amount (the figure `submit()` persists).
  int get currentAmount => _amount;

  /// Current selected category / parent (null until resolved).
  Category? get currentCategory => _category;
  Category? get currentParentCategory => _parentCategory;

  /// Current transaction date.
  DateTime get currentDate => _date;

  /// Current merchant text.
  String get currentMerchant => _storeController.text;

  /// Current note text.
  String get currentNote => _memoController.text;

  /// Current joy-ledger satisfaction value.
  int get currentSatisfaction => _joyFullness;

  /// Current ledger selection. Exposed for host-owned draft snapshots.
  LedgerType get currentLedgerType => _ledgerType;

  /// Current foreign-currency triple (all null on a JPY-native row).
  String? get currentOriginalCurrency => _originalCurrency;
  int? get currentOriginalAmount => _originalAmount;
  String? get currentAppliedRate => _appliedRate;

  /// Clears every draft-scoped field before a continuous-entry default is
  /// resolved. This is intentionally one synchronous state transition so no
  /// prior category/ledger/satisfaction/recognition state is observable as the
  /// next entry while the default-category lookup is in flight.
  void resetForFreshEntry({required DateTime date}) {
    if (!mounted) return;
    _ledgerResolutionEpoch++;
    final normalizedDate = DateTime(date.year, date.month, date.day);
    setState(() {
      _amount = 0;
      _originalCurrency = null;
      _originalAmount = null;
      _appliedRate = null;
      _foreignAmountInvalid = false;
      _foreignActualRateDate = null;
      _foreignStalenessNote = null;
      _category = null;
      _parentCategory = null;
      _initialCategoryId = null;
      _storeController.clear();
      _memoController.clear();
      _date = normalizedDate;
      _ledgerType = LedgerType.daily;
      _joyFullness = 2;
      _band = null;
      _alternates = const <CategoryMatchResult>[];
      _pendingCorrection = null;
      _showCelebration = false;
    });
  }

  /// Seeds the resolved default category after [resetForFreshEntry] and waits
  /// for its ledger mapping, keeping the host's submitting/resetting lock held
  /// until the fresh draft is fully coherent.
  Future<void> seedFreshEntryCategory(
    Category category,
    Category? parentCategory,
  ) async {
    if (!mounted) return;
    setState(() {
      _categoryById[category.id] = category;
      if (parentCategory != null) {
        _categoryById[parentCategory.id] = parentCategory;
      }
      _category = category;
      _parentCategory = parentCategory;
      _initialCategoryId = category.id;
      _pendingCorrection = null;
    });
    await _resolveLedgerType(category.id);
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
    // Phase 52 (RECUX-03 / D-05): a host-driven category push (voice batch-fill
    // or continuous-entry re-seed) is a fresh slate, NOT an
    // interactive user correction — discard any pending stash so an abandoned
    // draft's correction never carries into the next entry.
    _pendingCorrection = null;
    _resolveLedgerType(category.id);
  }

  /// Restores a category snapshot without deriving a new ledger type.
  ///
  /// Unlike [updateCategory], this accepts null so resetting a voice session
  /// can clear a category that did not exist before recording. It also
  /// invalidates any in-flight category inference; the caller restores the
  /// captured ledger explicitly through [updateLedgerType].
  void restoreCategory(Category? category, Category? parentCategory) {
    if (!mounted) return;
    _ledgerResolutionEpoch++;
    final restoredParent = category == null ? null : parentCategory;
    final categoryUnchanged = category?.id == _category?.id;
    final parentUnchanged = restoredParent?.id == _parentCategory?.id;
    if (!categoryUnchanged || !parentUnchanged) {
      setState(() {
        if (category != null) {
          _categoryById[category.id] = category;
        }
        if (restoredParent != null) {
          _categoryById[restoredParent.id] = restoredParent;
        }
        _category = category;
        _parentCategory = restoredParent;
      });
    }
    _pendingCorrection = null;
  }

  /// Phase 52 (RECUX-01/02 / D-08): the voice host pushes the recognized
  /// confidence band + ranked alternates at resolve-on-final — the SAME fill
  /// point that calls [updateCategory]. This drives the weak-category save
  /// guard and the test-gated alternate-category correction path. The former
  /// decorative band is deliberately hidden. Null clears both behaviors.
  ///
  /// Idempotency: short-circuits when band + alternate ids are unchanged so
  /// repeated final-fills do not rebuild-storm.
  void updateRecognition(
    ConfidenceBand? band,
    List<CategoryMatchResult> alternates,
  ) {
    if (!mounted) return;
    final sameBand = band == _band;
    final sameAlts =
        alternates.length == _alternates.length &&
        List.generate(
          alternates.length,
          (i) => alternates[i].categoryId == _alternates[i].categoryId,
        ).every((e) => e);
    if (sameBand && sameAlts) return;
    setState(() {
      _band = band;
      _alternates = List<CategoryMatchResult>.unmodifiable(alternates);
    });
  }

  /// D-09: the band clears the instant the user picks any category (chip tap or
  /// full selector) — the recognition guess is no longer authoritative. Chips
  /// collapse with it. No-op when the band is already cleared.
  void _clearRecognitionBand() {
    if (_band == null && _alternates.isEmpty) return;
    setState(() {
      _band = null;
      _alternates = const <CategoryMatchResult>[];
    });
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

  /// Restores a host-owned ledger snapshot without re-running category
  /// inference. Category changes still use [_resolveLedgerType] as before.
  void updateLedgerType(LedgerType ledgerType) {
    if (!mounted) return;
    _ledgerResolutionEpoch++;
    if (ledgerType == _ledgerType) return;
    setState(() => _ledgerType = ledgerType);
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
    // Quick 260613-ufn (D-4): an external date push (voice/host) on a foreign
    // row also auto-refetches the rate through the card's D-02/D-03 logic.
    _onForeignDateChanged();
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

    await _applyCategorySelection(result);

    // Item 4: success path — fire after voice-correction tail.
    _notifyPickerDismissed();
  }

  /// Shared user-selection write set used by BOTH the full-selector flow
  /// ([_editCategory]) and an alternate-chip tap ([_selectAlternateCategory]).
  /// Per D-09 the confidence band is cleared the moment the user picks any
  /// category (the recognition guess is no longer authoritative).
  Future<void> _applyCategorySelection(Category result) async {
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

    // D-09: user pick → clear the recognition band + collapse chips.
    _clearRecognitionBand();

    // Resolve ledger type for .new mode after category change.
    await _resolveLedgerType(result.id);

    if (!mounted) return;

    // Phase 52 (RECUX-03 / D-05/D-06/D-07): DEFER the correction write. Rather
    // than writing the KEYWORD learning table here (the legacy immediate write),
    // stash a pending correction and fire ONE write at confirmed save (D-05).
    // Applies to BOTH this path's callers — the full selector ([_editCategory])
    // AND an alternate-chip tap ([_selectAlternateCategory]) — so both count as
    // corrections (D-06). The write key is `voiceKeyword` (== `resolvedKeyword`)
    // verbatim (write==read, 260526-pg6); a null/empty keyword stashes NOTHING
    // and the merchant table is NEVER touched (D-07, D-16). Selecting back to
    // the recognized original clears the stash (no spurious correction).
    widget.config.maybeWhen(
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
          ) {
            if (result.id == _initialCategoryId) {
              // Reverted to the recognized original — discard any pending stash.
              _pendingCorrection = null;
            } else if (voiceKeyword != null && voiceKeyword.isNotEmpty) {
              _pendingCorrection = _PendingCategoryCorrection(
                keyword: voiceKeyword,
                correctedCategoryId: result.id,
              );
            }
            // voiceKeyword null/empty: leave _pendingCorrection untouched
            // (stays null) — D-07: no orphan-key write, ever.
          },
      orElse: () {},
    );
  }

  /// Phase 52 (RECUX-03 / D-05): discard the pending category correction with
  /// NO write. Invoked by the host on the reset / 连续记账 (continuous-entry) /
  /// back paths so an abandoned draft never pollutes the KEYWORD learning table.
  void discardPendingCorrection() {
    _pendingCorrection = null;
  }

  /// Phase 52 (RECUX-02): an alternate-category chip tap. Resolves the chosen
  /// category id to a [Category] then routes it through the same user-selection
  /// write set as the full selector (instant swap + ledger re-derive + band
  /// clear + correction record), per CONTEXT D-05/D-06/D-09.
  Future<void> _selectAlternateCategory(String categoryId) async {
    if (categoryId == _category?.id) {
      // Same category re-tapped — still a user-authoritative confirmation: clear
      // the band (D-09) without redoing the repo lookup / correction write.
      _clearRecognitionBand();
      return;
    }
    final cat =
        _categoryById[categoryId] ??
        await ref.read(categoryRepositoryProvider).findById(categoryId);
    if (!mounted || cat == null) return;
    await _applyCategorySelection(cat);
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
      // Quick 260613-ufn (D-4): notify the host (add screen) so its
      // `_selectedDate` + keyed rate provider re-resolve for the new date.
      widget.onDateChanged?.call(picked);
      // On an EDIT foreign row, the date-picker change auto-refetches the rate
      // and runs ADR-022 D-02 dialog / D-03 toast via the card (replaces the
      // removed in-card clickable trigger — D-3).
      await _onForeignDateChanged();
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
    final result = withSignal.result;

    // Quick 260613-ufn (D-2): derive the actual effective rate date + staleness
    // note from the SAME RateResult via the shared single staleness site so the
    // card's 汇率日期 row + amber note reflect this re-fetch. Side-effect of the
    // re-fetch — kept in this one-shot read, never in a watch (Riverpod 3).
    if (mounted) {
      final locale = Localizations.localeOf(context);
      setState(() {
        _foreignActualRateDate = rateEffectiveDateOf(result, _date);
        _foreignStalenessNote = stalenessNoteFor(
          result: result,
          requestedDate: _date,
          l10n: S.of(context),
          locale: locale,
        );
      });
    }

    return rateStringOf(result);
  }

  /// Quick 260613-ufn (D-4): the date-picker change handler for a FOREIGN edit
  /// row. After [_editDate] / [updateDate] set the new `_date`, this routes the
  /// re-fetch through the card's retained ADR-022 D-02 dialog / D-03 toast logic
  /// (the in-card clickable trigger was removed — D-3). The card's
  /// [DateChangeRefetchRateSource] reads the REAL use case (single fetch, which
  /// also seeds `_foreignActualRateDate` / `_foreignStalenessNote`).
  Future<void> _onForeignDateChanged() async {
    if (_originalCurrency == null) return;
    await _currencyCardKey.currentState?.triggerDateChangeRefetch();
  }

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

              // Phase 52 (RECUX-03 / D-05/D-06/D-07): fire the DEFERRED category
              // correction exactly once, only at confirmed save. The stash is
              // present only when the user changed the category away from the
              // recognized original via a chip tap OR the full selector (both
              // count — D-06); it carries `resolvedKeyword` verbatim (write==read,
              // 260526-pg6) and is null when the keyword was null/empty (D-07).
              // Re-check the final category still differs from the recognized
              // original (defense-in-depth — the host may have re-pushed the
              // original after the stash was set). The write target is the
              // KEYWORD table ONLY — the merchant table is never touched here.
              final pending = _pendingCorrection;
              if (pending != null &&
                  pending.correctedCategoryId != _initialCategoryId &&
                  _category!.id != _initialCategoryId) {
                await ref
                    .read(recordCategoryCorrectionUseCaseProvider)
                    .execute(
                      keyword: pending.keyword,
                      correctedCategoryId: pending.correctedCategoryId,
                    );
                _pendingCorrection = null;
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

  Widget _buildV16DetailsCard({
    required S l10n,
    required Locale locale,
    required Category? displayCategory,
  }) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('v16-details-card'),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildV16InfoRow(
            key: const ValueKey('category-chip'),
            icon: displayCategory != null
                ? resolveCategoryIcon(displayCategory.icon)
                : Icons.shopping_bag_outlined,
            label: l10n.category,
            value: _categoryLabel(locale, l10n),
            subline: _needsV16CategorySelection
                ? _buildV16CategoryRequiredBadge(l10n)
                : null,
            onTap: _editCategory,
          ),
          Divider(height: 1, thickness: 1, color: palette.borderDefault),
          _buildV16InfoRow(
            key: const ValueKey('date-chip'),
            icon: Icons.calendar_month_outlined,
            label: l10n.date,
            value: const FormatterService().formatDate(_date, locale),
            onTap: _editDate,
          ),
          Divider(height: 1, thickness: 1, color: palette.borderDefault),
          _buildV16MerchantRow(l10n),
        ],
      ),
    );
  }

  Widget _buildV16InfoRow({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    Widget? subline,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Icon(icon, size: 20, color: palette.textSecondary),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 48,
                  child: Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.label.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subline != null) ...[
                        const SizedBox(height: 2),
                        subline,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: palette.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildV16MerchantRow(S l10n) {
    final palette = context.palette;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Icon(
                Icons.storefront_outlined,
                size: 20,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 48,
              child: Text(
                l10n.merchant,
                style: AppTextStyles.label.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    key: const ValueKey('merchant-textfield'),
                    controller: _storeController,
                    focusNode: widget.merchantFocusNode,
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
                      hintStyle: AppTextStyles.label.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    style: AppTextStyles.label.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
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

  Widget _buildV16PurposeCard(S l10n) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('v16-purpose-card'),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                l10n.expenseClassification,
                style: AppTextStyles.label.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildV16LedgerOption(
                      key: const ValueKey('ledger_type_daily_chip'),
                      type: LedgerType.daily,
                      icon: Icons.shield_outlined,
                      label: l10n.dailyExpense,
                    ),
                    const SizedBox(width: 6),
                    _buildV16LedgerOption(
                      key: const ValueKey('ledger_type_joy_chip'),
                      type: LedgerType.joy,
                      icon: Icons.auto_awesome,
                      label: l10n.joyExpense,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_ledgerType == LedgerType.joy) ...[
            const SizedBox(height: 14),
            _buildV16SatisfactionCard(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildV16LedgerOption({
    required Key key,
    required LedgerType type,
    required IconData icon,
    required String label,
  }) {
    final palette = context.palette;
    final selected = _ledgerType == type;
    final activeColor = type == LedgerType.daily
        ? palette.dailyText
        : palette.joyText;
    final activeBorder = type == LedgerType.daily ? palette.daily : palette.joy;
    final activeBackground = type == LedgerType.daily
        ? palette.dailyLight
        : palette.joyLight;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(20),
          onTap: () => updateLedgerType(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? activeBackground : palette.backgroundMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? activeBorder : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? activeColor : palette.textSecondary,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? activeColor : palette.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildV16SatisfactionCard(S l10n) {
    final levelLabels = <String>[
      l10n.satisfactionBad,
      l10n.satisfactionSlightlyBad,
      l10n.satisfactionNormal,
      l10n.satisfactionGood,
      l10n.satisfactionVeryGood,
    ];
    if (_joyFullness.isOdd) {
      for (var index = 0; index < levelLabels.length; index++) {
        levelLabels[index] = '${levelLabels[index]} · $_joyFullness/10';
      }
    }

    return KeyedSubtree(
      key: const ValueKey('v16-satisfaction-card'),
      child: SatisfactionEmojiPicker(
        value: _joyFullness,
        onChanged: updateSatisfaction,
        title: l10n.satisfactionLevel,
        levelLabels: levelLabels,
        bottomLabels: [
          l10n.satisfactionBad,
          l10n.satisfactionNormal,
          l10n.satisfactionExcellent,
        ],
      ),
    );
  }

  Widget _buildV16NoteCard(S l10n) {
    final palette = context.palette;

    return Container(
      key: const ValueKey('v16-note-card'),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Icon(
              Icons.description_outlined,
              size: 20,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 48,
            child: Text(
              l10n.note,
              style: AppTextStyles.label.copyWith(color: palette.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('note-textfield'),
              controller: _memoController,
              focusNode: widget.noteFocusNode,
              groupId: kKeyboardToolbarTapRegionGroup,
              maxLines: 1,
              textAlign: TextAlign.end,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.enterMemo,
                hintStyle: AppTextStyles.label.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              style: AppTextStyles.label.copyWith(color: palette.textPrimary),
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right, size: 18, color: palette.textTertiary),
        ],
      ),
    );
  }

  Widget _buildV16CategoryRequiredBadge(S l10n) {
    final palette = context.palette;
    return Container(
      key: const ValueKey('v16-category-select-required'),
      constraints: const BoxConstraints(minHeight: 21),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: palette.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.entryCategorySelectRequired,
        style: AppTextStyles.micro.copyWith(
          color: palette.warning,
          fontWeight: FontWeight.w900,
        ),
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
    final sectionGap = widget.useV16Layout ? 10.0 : 16.0;

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
                  key: _currencyCardKey,
                  originalCurrency: _originalCurrency!,
                  originalAmount: _originalAmount!,
                  appliedRate: _appliedRate!,
                  manualOverride: false,
                  // Quick 260613-ufn: requested txn date; the non-clickable
                  // 汇率日期 row shows the ACTUAL effective date below.
                  rateDate: _date,
                  // Quick 260613-ufn (D-2): actual effective rate date +
                  // staleness note derived from the same re-fetch (shared site).
                  actualRateDate: _foreignActualRateDate,
                  stalenessNote: _foreignStalenessNote,
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
              SizedBox(height: sectionGap),
            ],

            if (widget.useV16Layout)
              _buildV16DetailsCard(
                l10n: l10n,
                locale: locale,
                displayCategory: displayCategory,
              )
            else
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

            // Phase 52 correction row, retained behind the @visibleForTesting
            // `showAlternateChips` flag for a reversible re-enable. The former
            // confidence-band decoration is intentionally hidden in production
            // and tests. Recognition state still powers the weak-category save
            // guard and clears when the user picks a category (D-09).
            if (widget.showAlternateChips &&
                _band != null &&
                _alternates.isNotEmpty) ...[
              SizedBox(height: widget.useV16Layout ? 10 : 12),
              AlternateCategoryChips(
                alternates: _alternates,
                selectedCategoryId: _category?.id,
                onSelect: _selectAlternateCategory,
              ),
            ],

            SizedBox(height: sectionGap),

            // Card B: 用途 (Purpose) header + ledger + (joy) satisfaction.
            if (widget.useV16Layout) ...[
              _buildV16PurposeCard(l10n),
            ] else
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
                            onChanged: updateLedgerType,
                            dailyLabel: l10n.dailyExpense,
                            joyLabel: l10n.joyExpense,
                          ),
                        ],
                      ),
                      if (_ledgerType == LedgerType.joy) ...[
                        const SizedBox(height: 12),
                        SatisfactionEmojiPicker(
                          value: _joyFullness,
                          onChanged: updateSatisfaction,
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

            SizedBox(height: sectionGap),

            // Card C: 备注 (note) — extracted from Card A's trailing so the
            // note has its own rounded card per Item 1 (260526-j98).
            if (widget.useV16Layout)
              _buildV16NoteCard(l10n)
            else
              _formCard(child: _buildNoteSection(l10n)),

            SizedBox(height: sectionGap),
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

/// Phase 52 (RECUX-03 / D-05/D-06/D-07): an immutable pending category
/// correction stashed when the user changes the category away from the
/// recognized-original one. The KEYWORD-table write is DEFERRED to confirmed
/// save and fires exactly once. [keyword] is `resolvedKeyword` verbatim
/// (write==read identity, 260526-pg6); it is guaranteed non-empty (an
/// empty/null keyword never produces a stash, so save writes NOTHING — D-07).
class _PendingCategoryCorrection {
  const _PendingCategoryCorrection({
    required this.keyword,
    required this.correctedCategoryId,
  });

  /// `resolvedKeyword` verbatim — the learning write key (== recognizer read
  /// key). Always non-empty by construction.
  final String keyword;

  /// The category id the user corrected to.
  final String correctedCategoryId;
}
