// lib/features/accounting/presentation/screens/manual_one_step_currency.dart
//
// quick-260707-kfb A2: the currency / foreign-triple segment of
// `_ManualOneStepScreenState`, moved out of `manual_one_step_screen.dart` as a
// same-library `part` — no renames, no visibility promotion, a byte-faithful
// move. Covers the foreign-triple push, the rate-string extraction, the passive
// rate-signal sink, the form-date change, the manual-rate edit, and the
// currency selection sheet.
//
// ONE sanctioned rewrite (mirrors the `manual_one_step_voice_wiring.dart`
// precedent): the moved `setState(...)` calls became `_rebuild(...)` (whose body
// is exactly `if (mounted) setState(apply)`), because `setState` is `@protected`
// and cannot be called from an extension.

part of 'manual_one_step_screen.dart';

extension _ManualOneStepCurrency on _ManualOneStepScreenState {
  /// Resolve the current rate (cache-first via the preview's keyed provider) and
  /// push the converted JPY amount + foreign triple into the form. The rate
  /// figure used here is the SAME one the preview renders (single conversion
  /// site, ADR-020) — guaranteeing preview == persisted.
  Future<void> _pushForeignTriple() async {
    final minorUnits = _originalMinorUnits;
    final currency = _currency;
    final date = _selectedDate;
    if (minorUnits <= 0) {
      _formKey.currentState?.updateAmount(0);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: null,
        originalAmount: null,
        appliedRate: null,
      );
      return;
    }
    // Quick 260613-ufn (D-1): a user-edited (manual-override) rate wins over the
    // auto-resolved one. validateAppliedRate gates a malformed override out so
    // we never persist garbage; an invalid override falls through to the
    // auto-resolved rate (the card surfaces its own inline error).
    final manualRate = _manualForeignRate;
    if (manualRate != null && validateAppliedRate(manualRate) == null) {
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: manualRate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      _formKey.currentState?.updateAmount(jpy);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: manualRate,
      );
      return;
    }

    final args = ConversionPreviewArgs(currency: currency, date: date);
    try {
      final withSignal = await ref.read(conversionRateProvider(args).future);
      // Bail if the user changed currency/amount/date while awaiting.
      // WR-01: `date` is captured before the await; a date change mid-fetch
      // would otherwise persist an OLD-date rate against the NEW-date timestamp
      // (undetectable post-persist — the triple is excluded from the hash chain,
      // ADR-021). The date guard makes the stale-date push impossible.
      if (!mounted ||
          foreignPushIsStale(
            capturedCurrency: currency,
            currentCurrency: _currency,
            capturedMinorUnits: minorUnits,
            currentMinorUnits: _originalMinorUnits,
            capturedDate: date,
            currentDate: _selectedDate,
          )) {
        return;
      }
      final rate = _rateStringOf(withSignal.result);
      if (rate == null) {
        // RateUnavailable — no rate to persist yet. Withhold the triple; the
        // preview surfaces the mandatory-rate prompt.
        //
        // WR-02: a PRIOR successful push may have left `_amount = someJpy`.
        // Clearing only the triple here would leave that stale JPY as a
        // JPY-native row, so a Save in this window persists a stale converted
        // amount. Reset the form amount to 0 FIRST so the create use case
        // rejects the save (amount <= 0) instead. When the user later supplies
        // a manual rate the normal push (mandatory-manual-rate, P41 D-08)
        // re-computes the JPY amount.
        _formKey.currentState?.updateAmount(0);
        _formKey.currentState?.updateCurrencyTriple(
          originalCurrency: null,
          originalAmount: null,
          appliedRate: null,
        );
        return;
      }
      final jpy = convertToJpy(
        originalMinorUnits: minorUnits,
        appliedRate: rate,
        subunitToUnit: subunitToUnitFor(currency),
      );
      _formKey.currentState?.updateAmount(jpy);
      _formKey.currentState?.updateCurrencyTriple(
        originalCurrency: currency,
        originalAmount: minorUnits,
        appliedRate: rate,
      );
    } catch (_) {
      // Rate fetch failed unexpectedly — leave the triple withheld; the preview
      // renders the mandatory-rate prompt and the save guard blocks an empty
      // amount. (Network failure degrades to a fallback rate upstream.)
    }
  }

  /// Rate string for any rate-bearing [RateResult] variant; null for
  /// [RateUnavailable].
  String? _rateStringOf(RateResult r) => switch (r) {
    RateFetched(:final rate) => rate,
    RateCached(:final rate) => rate,
    RateFallback(:final rate) => rate,
    RateManual(:final rate) => rate,
    RateUnavailable() => null,
  };

  /// Passive sink for the preview's ADR-022 rate signals (D-02 dialog / D-03
  /// toast). During FRESH entry there is no `previousRate` — the entry flow
  /// does not carry a prior applied rate — so the use case never emits these
  /// signals on this screen (verified: the panel's args omit previousRate /
  /// wasManualOverride, the two inputs that gate signal emission). The full
  /// dialog/toast UX (ADR-022 D-02/D-03) belongs to the EDIT host (42-09),
  /// where a prior rate exists to diff against. This callback is the documented
  /// 42-08 boundary; it intentionally no-ops so signals can never block keypad
  /// entry. Kept non-null so the panel's `ref.listen` has a sink.
  void _onRateSignal(RateSignal signal) {
    // No-op on the entry screen (see doc comment). 42-09 wires the real UX.
  }

  /// Quick 260613-ufn (D-4): the form's date picker changed the transaction
  /// date. Update the screen's `_selectedDate` so the keyed
  /// `conversionRateProvider(currency,date)` re-resolves the rate for the
  /// new date and the unified card's 汇率/日元/汇率日期/staleness all update. A
  /// date change supersedes any manual override (the override was keyed to the
  /// previous date's rate), then re-pushes the freshly-resolved triple.
  void _onFormDateChanged(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized ==
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)) {
      return;
    }
    _rebuild(() {
      _selectedDate = normalized;
      _manualForeignRate = null;
    });
    if (_isForeign) {
      _pushForeignTriple();
    }
  }

  /// Quick 260613-ufn (D-1): the user hand-edited the 汇率 row in the unified
  /// card. Record the override so `_pushForeignTriple` persists the edited rate
  /// (manual override) and immediately push the recomputed triple. The card's
  /// own derived JPY row already reflects the edit (single convertToJpy site).
  void _onForeignRateEdited(CurrencyLinkedEditValue value) {
    _rebuild(() => _manualForeignRate = value.appliedRate);
    _pushForeignTriple();
  }

  // ── Currency selection (CURR-01/03/05) ──

  /// CURR-01: open the currency selector without leaving the entry screen.
  void _onCurrencyTap() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencySelectorSheet(
        selectedCode: _currency,
        onSelect: _onCurrencySelected,
      ),
    );
    _rebuild(() => _amountFocused = true);
  }

  /// Apply a selected currency: truncate the amount per the new minor unit
  /// (D-08), gate the dot key (D-06), feed recent-use (CURR-03), and re-sync the
  /// converted JPY + triple. Selecting JPY clears the triple (CURR-04).
  void _onCurrencySelected(String code) {
    final newCode = code.toUpperCase();
    final newDecimals = currencyFractionDigitsFor(newCode);
    // CURR-03: record the foreign selection for the LRU (JPY is ignored inside).
    ref.read(recentCurrencyProvider.notifier).recordUse(newCode);
    _rebuild(() {
      _currency = newCode;
      // D-08: truncate-not-round to the new minor unit; adopts the new cap.
      _controller.onCurrencyChange(newDecimals);
      _amount = _controller.text;
      // Quick 260613-ufn: a currency change supersedes any manual rate override
      // (the override was keyed to the previous currency's rate).
      _manualForeignRate = null;
    });
    _syncAmountToForm();
  }
}
