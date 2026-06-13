# Phase 42: 输入与展示 + 语音 (Entry UI + Display + Voice) - Research

**Researched:** 2026-06-13
**Domain:** Flutter UI extension (multi-currency entry/display/voice) on a fully-landed P40 data + P41 rate-service foundation
**Confidence:** HIGH (codebase-verified integration points; ADRs are authoritative; one package decision is MEDIUM pending install verification)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01 .. D-13)

**Currency selector layout (CURR-01/02)**
- **D-01:** One row = flag emoji + currency symbol + ISO code + localized name (e.g. `🇺🇸 $ USD 美元`). Search matches code OR name. Name localizes via `currentLocaleProvider`. Fallback for no-1:1-country currencies (EUR/XAF/XCD) = generic region flag/placeholder; emoji cross-platform render risk must be golden-verified.
- **D-02:** "More" expands to full ISO 4217 list + live search. Default sheet shows common zone (JPY always first + USD/EUR/CNY/HKD/GBP, re-ordered by recent use).

**Conversion preview panel (DISP-01)**
- **D-03:** Preview = JPY main row (`≈ ¥7,415`) + rate sub-row (`USD 1 = ¥148.30 · {date}`). Same wording as detail/edit.
- **D-04:** Loading = in-place dim/skeleton at the preview row. No jump, no keyboard occlusion. ~3s budget (P41 D-04).
- **D-05:** Stale/fallback rate → warning-color (`#C98A00`) small label below preview. Triggers: `RateResult.fallback` OR `fetched.actualDate ≠ transaction date`. Non-blocking, informational.

**Decimal input gating (CURR-05)**
- **D-06:** JPY/KRW (0-decimal) → dot key hidden / replaced. Preserve 48dp floor + layout stability.
- **D-07:** Foreign currency decimals capped at the currency's ISO 4217 minor unit (USD/EUR/CNY = 2; JPY/KRW = 0).
- **D-08:** Switching to a 0-decimal currency **truncates** (NOT rounds) existing decimals: `50.50 → 50`. Switching to a fewer-decimal currency truncates/keeps to target digits.
- **D-09:** Stored JPY `amount` always integer via single site `convertToJpy()` (ADR-020 `.round()`; user confirmed — do not change ADR-020).

**Detail/edit linked editing (DISP-04 / governed by ADR-022 D-01)**
- **D-10:** Two-input / one-derived model (ADR-022 D-01 ratified; "three-field bidirectional" wording VOID). Editable = original amount + rate; **JPY read-only derived** via `convertToJpy()`, never directly assigned. "原币是事实，日元是结果". **MUST NOT implement three-field bidirectional editing** (circular-dependency risk).
- **D-11:** Rate input field always visible + editable (not collapsed). Three rows persist: original / rate (editable) / JPY (read-only).
- **D-12:** Read-only JPY recalculates live on every original/rate change.
- **D-13 (inherited from ADR-022, locked):** Manual-override + date change → two-choice dialog (keep manual rate / re-fetch for new date, no default). No-override + date change causing JPY >1% change → non-blocking toast + Undo (5s window), auto-recalc saved immediately.

### Claude's Discretion
- **Voice currency confirmation UX (VOICE-CUR-01/02/03):** surface/highlight detected currency on shared `transaction_details_form`, editable before save. zh: 美元/欧元/英镑/港币/澳元/加元; ja: ドル/ユーロ/ポンド/香港ドル/豪ドル. Bare `元` keeps JPY-terminator behavior; bare `ドル` defaults USD. `元`/`円` ambiguity: zh=CNY, ja=JPY. English deferred to v2.
- **Mandatory manual-rate UI (inherits P41 D-08):** new currency + offline + empty cache → `RateResult.unavailable` → UI requires manual rate before save. Entry shape / timing / preview integration = implementation detail. Manual path always available; save never network-blocked.
- **List foreign-row annotation format (DISP-02):** exact typography of `USD 50.00` sub-annotation. JPY rows unchanged.
- **ISO 4217 list data source:** package vs embedded table — researcher/planner decides (see Open Question 1).
- **Decimal-input state machine design** (no precedent; design carefully).
- **Preview loading/warning copy + ARB key naming** (ja/zh/en all three).

### Deferred Ideas (OUT OF SCOPE)
- Flag emoji cross-platform deep-dive (switch to SVG/symbol only if golden/device shows unacceptable divergence — fallback path noted in Open Question 2).
- English voice currency parsing (VOICE-EN-V2-01 → v2).
- Shopping-list `estimatedPrice` multi-currency (PROJECT.md excludes).
- Advanced manual-rate validity checks (range sanity) — keep P40/P41 base validation only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CURR-01 | Currency selector on entry screen without leaving the screen | New `CurrencySelectorSheet` opened from existing `SmartKeyboard` currency key (`smart_keyboard.dart:286` `_CurrencyKey`). |
| CURR-02 | Search by code/name; JPY first; common zone re-ordered by recent use | Selector sheet data = `intl currencyFractionDigits` keys + ARB localized names; session "recent use" state lives in a Riverpod provider. |
| CURR-03 | Confirm/apply selected currency back to entry | Selector returns ISO code → host state → `SmartKeyboard.currencyLabel/currencySymbol` props (already parameterized). |
| CURR-04 | **JPY path untouched (regression protection)** | When `currency=='JPY'`: NO rate fetch, NO preview, NO list annotation, NO dot-gating change. Byte-identical JPY goldens. Hard invariant. |
| CURR-05 | Per-currency decimal-input gating | `SmartKeyboard.onDot?` nullable hook + new amount-input state machine (Open Question 3). |
| DISP-01 | Live JPY conversion preview | New preview panel consuming `appGetExchangeRateUseCaseProvider` + `RateResult`; computes via `convertToJpy()`. |
| DISP-02 | Foreign-row small annotation in list | Extend `list_transaction_tile.dart` (`taggedTx.transaction.originalCurrency` reachable; `formattedAmount` passed in). |
| DISP-03 | Detail/edit full view of currency fields | `TransactionDetailsForm.edit` host (seed = full `Transaction` carrying the triple). |
| DISP-04 | Linked editing — **two-input/one-derived per ADR-022 D-01** | See "Conflict Resolution" + edit-host design below. |
| VOICE-CUR-01 | Detect currency from zh/ja voice | Extend `voice_currency_suffixes.dart` + both numeral state machines + parse result + use case (Open Question 4). |
| VOICE-CUR-02 | Surface detected currency for confirmation | `VoiceParseResult.detectedCurrency` → `TransactionDetailsForm` → triggers rate-fetch. |
| VOICE-CUR-03 | Edit detected currency before save | Same `CurrencySelectorSheet` reachable from the form. |
</phase_requirements>

## Summary

Phase 42 is a **pure presentation/input layer** on top of a foundation that is more complete than the roadmap implies. The data layer (`CreateTransactionUseCase` with full triple support + partial-triple validation + internal `convertToJpy()`) and the rate-service layer (`GetExchangeRateUseCase` returning `RateResultWithSignal` — already carrying the ADR-022 D-02 *dialog* and D-03 *toast* signals pre-computed) are landed and wired (`appGetExchangeRateUseCaseProvider`). This means Phase 42 does **not** invent the conversion math, the rate priority chain, or the staleness/override signal logic — it *consumes* them and renders the UI.

The single most important correctness point is the **ADR-022 conflict**: ROADMAP wording ("three-field bidirectional") is VOID; the implementation is two editable inputs (original amount + rate) and one read-only derived JPY. The single most important regression risk is **CURR-04** (JPY byte-identical goldens). The single biggest novel build is the **decimal-input state machine** (no precedent in the codebase).

One real plumbing gap was found that the planner must schedule: **`UpdateTransactionParams` does NOT carry the currency triple** (unlike `CreateTransactionParams`, which already does). The edit host cannot persist edited original-amount/rate until `UpdateTransactionParams` + `UpdateTransactionUseCase` are extended. This is an application-layer touch (not data/rate-service), consistent with the phase boundary.

**Primary recommendation:** Use `intl 0.20.2`'s built-in `currencyFractionDigits` map (already a dependency) as the authoritative ISO 4217 minor-unit source; source localized currency *names* from the project's own ARB files (not a package); keep flag emoji + region fallback as the default flag strategy (golden-verified) with `country_flags` (SVG) as the documented escape hatch. Build a small pure-Dart `AmountInputController` state machine for D-06/D-07/D-08. Extend the existing voice files rather than rebuilding.

## Conflict Resolution: ADR-022 supersedes ROADMAP "three-field bidirectional"

**This is the planner's #1 watch item — do not regress to roadmap wording.**

| Source | Wording | Authority |
|--------|---------|-----------|
| ROADMAP.md P42 Goal + SC-4 | "bidirectional three-field linked editing / editing any one recalculates the others" | **VOID** (superseded) |
| CONTEXT.md D-10 | Two-input / one-derived | Authoritative |
| ADR-022 D-01 (✅ accepted, append-only) | `originalAmount` + `appliedRate` editable; `amount` (JPY) read-only derived via `convertToJpy()`, never assigned | **Canonical** [CITED: ADR-022 lines 109-126] |

Why bidirectional is rejected (ADR-022 lines 37-55): a fixed derived relationship `amount = (originalAmount × rate).round()` means "edit JPY directly" creates a circular dependency (原币 ← 日元÷汇率, 汇率 ← 日元÷原币) and a UI update loop. The mental model is **"原币是事实，日元是结果"** (original amount is the fact, JPY is the result).

**Implementation contract for the edit host:**
- Two `TextEditingController`-backed inputs: original amount, rate.
- JPY row is a read-only `Text` widget recomputed on every input change via `convertToJpy()` (the SAME single site used by preview + list, guaranteeing identical figures — UI-SPEC Hard Invariant #4).
- No listener writes back into the JPY value as an input. There is exactly one data-flow direction.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Currency selection UI (sheet, search, recent-use) | Presentation (`features/accounting/presentation`) | — | Pure UI + session state; no business rule. |
| Decimal-input gating state machine | Presentation (host-owned controller) | — | Input UX concern; mirrors existing host-owns-amount pattern (P19 D-14). |
| JPY conversion (preview / list / edit) | Shared util (`convertToJpy()`) | — | Single-site invariant (ADR-020). Presentation calls it; never re-implements. |
| Rate fetch + priority chain + staleness/override signals | Application (`GetExchangeRateUseCase`) | Infrastructure (`ExchangeRateCacheService`) | Already landed (P41). Presentation only `ref.watch`-consumes. |
| ISO 4217 minor-unit decimals | Infrastructure (`intl` data) via `NumberFormatter`/`subunitToUnitFor` | — | Authoritative data already in dependency tree. |
| Localized currency names (ja/zh/en) | Presentation i18n (ARB / `S.of(context)`) | — | Project i18n convention; no package supplies ja/zh names. |
| Persist edited triple | Application (`Update`/`CreateTransactionUseCase`) | Data (repo) | Edit host calls use case; **`UpdateTransactionParams` must be extended** (gap). |
| Voice currency detection | Infrastructure (`voice_currency_suffixes` + numeral machines) → Application (`ParseVoiceInputUseCase`) | Presentation (form confirmation) | Detection is parsing logic; confirmation is UI. |

## Standard Stack

### Core (already in tree — verified)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `intl` | 0.20.2 (pinned) | ISO 4217 minor-unit decimals via `currencyFractionDigits` map + `NumberFormat.currency` | [VERIFIED: pub-cache] Already the formatter dependency; pinned by `flutter_localizations` (CLAUDE.md). Carries the full per-currency fraction map (e.g. BHD=3, JOD=3, KWD=3, JPY=0). No new dependency needed for decimals. |
| `flutter_riverpod` | 3.1+ | Selector/preview/edit state; recent-use session state | [CITED: CLAUDE.md] Project standard. Use `ref.listen` for toast/dialog side-effects (see Pitfall 4). |
| `freezed` | (project) | `VoiceParseResult.detectedCurrency` field add | [CITED: CLAUDE.md] Existing model is `@freezed`; add nullable field + run build_runner. |

### Supporting (recommended new package — single candidate, optional)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `country_flags` | 4.1.2 | SVG flag rendering (`jovial_svg`) — identical across iOS/Android | ONLY as the documented escape hatch if emoji-flag goldens/device test show unacceptable divergence (Deferred Idea). Default ships with emoji + fallback; do NOT add unless emoji path fails verification. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `intl` fraction map + ARB names | `currency_picker` 2.0.22 | [VERIFIED: pub.dev] Clean deps (`collection` + flutter SDK only — **no win32**, safe vs pinned trio); 17k downloads/30d, 150/160 score. BUT its names are **English-only** — would still need ARB for ja/zh, and it duplicates the decimals data `intl` already has. Net: adds a dependency for a built-in `SearchAnchor` we'd likely restyle anyway. **Not recommended** unless the planner wants its prebuilt search UI. |
| Embedded ISO 4217 table | Hand-rolled `Map<String,CurrencyMeta>` | Avoids any package but duplicates `intl`'s authoritative decimals map and risks drift. Use `intl` for decimals; embed ONLY the small localized-name table in ARB. |
| Flag emoji | Pure currency-symbol chips (no flags) | Eliminates all cross-platform render risk but loses the D-01 scannability. Keep emoji per D-01; symbol-only is the last-resort fallback. |

**Installation:** No mandatory new package. If the planner elects the SVG escape hatch later:
```bash
flutter pub add country_flags   # only if emoji goldens fail — verify iOS build after
```
**Verify before any add:** `flutter build ios --debug --no-codesign` must still pass (CLAUDE.md win32-trio discipline). `country_flags` env is `sdk >=3.0.0` and deps are `collection` + `jovial_svg` — no win32 conflict, but confirm at install time.

## Package Legitimacy Audit

> This phase installs NO mandatory new package — the recommended stack is entirely already-in-tree (`intl`, `flutter_riverpod`, `freezed`). The audit covers the two optional candidates the planner may consider.

| Package | Registry | Age | Downloads (30d) | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------------|-------------|---------|-------------|
| `intl` | pub.dev | mature (Dart team) | — (transitive of flutter_localizations) | github.com/dart-lang/i18n | OK | Approved (already pinned 0.20.2) |
| `country_flags` | pub.dev | 4.x line | 117,398 | github.com/arturograu/country_flags | OK | Approved as documented escape hatch only — gate behind `checkpoint:human-verify` + iOS build verify before install |
| `currency_picker` | pub.dev | 2.0.22 | 17,239 | github.com/Daniel-Ioannou/flutter_currency_picker | OK | Not recommended (English-only names); if planner adopts, gate behind `checkpoint:human-verify` |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*Package names above were discovered via WebSearch/pub.dev API and registry-verified, but per provenance rules any actual `flutter pub add` of `country_flags`/`currency_picker` should be gated behind a `checkpoint:human-verify` task (the pub legitimacy seam was unavailable for the `pub` ecosystem this session — `[ASSUMED]` legitimacy for the two optional packages).*

## Existing-Code Integration Map (extend vs new)

> All paths verified by reading the files this session.

| File | Action | What changes | Notes |
|------|--------|--------------|-------|
| `lib/features/accounting/presentation/widgets/smart_keyboard.dart` | **Extend** | `_CurrencyKey` becomes tappable (currently display-only — line 184 comment "display only, no tap action") → opens selector; `onDot` nullable hook drives D-06 gating (when null, render replacement key preserving 48dp). | `keyHeight` math already floors at 48 (line 59). Replacement-key layout must keep the action row 3-equal-width structure. |
| `lib/features/accounting/presentation/screens/manual_one_step_screen.dart` | **Extend** | Host owns currency state + amount string. Current `_onDigit/_onDot/_onDoubleZero` (lines 212-250) cap decimals at 4 unconditionally — replace with currency-aware state machine (Open Q3). Add preview panel below `AmountDisplay` (after line 407). On currency change, truncate `_amount` per D-08. Pass triple into form. | Host-owns-amount is the established pattern (P19 D-14). `_amount` is a `String`; preview reads it + currency + rate. |
| `lib/features/accounting/presentation/widgets/transaction_details_form.dart` | **Extend** | `.edit` host: add original-amount + rate inputs + read-only JPY row (D-10/D-11/D-12). `submit()` (line 425) must pass triple into `Create`/`UpdateTransactionParams`. Add `updateCurrency`/`updateRate` imperative methods mirroring `updateAmount` (line 223). Voice confirmation surfaces `detectedCurrency` here. | The form is the 4-host shared form. `.edit` seed is the full `Transaction` → `seed.originalCurrency/originalAmount/appliedRate` already available. |
| `lib/application/accounting/update_transaction_use_case.dart` | **Extend (GAP)** | `UpdateTransactionParams` has NO currency fields (lines 26-51). Add `originalCurrency/originalAmount/appliedRate` (pass-through or coalesce — planner decides per EDIT-02). `execute()` must recompute `amount` via `convertToJpy()` when triple present, validate partial-triple, and re-save. **Hash chain NOT recomputed** (ADR-021 — currency fields excluded; existing behavior at line 65 already skips rehash). | This is the one real plumbing gap. `CreateTransactionParams` already has the triple + validation (verified lines 30-142). Mirror that logic. |
| `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` | **Extend** | Currently amount edits go through `AmountEditBottomSheet` modal (line 105). For foreign rows the original-amount edit + rate edit live inside the form's `.edit` host instead. Wire ADR-022 D-02 dialog + D-03 toast off the `RateSignal` returned by the rate use case. | `_save()` (line 56) delegates to `form.submit()`. The D-02 dialog / D-03 toast are triggered when a date change re-fetches. |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | **Extend** | Add small secondary annotation (`USD 50.00`) for foreign rows. `taggedTx.transaction.originalCurrency` reachable; `formattedAmount` (JPY) already passed in (line 68). JPY rows: NO change (CURR-04). | Annotation = `NumberFormatter.formatCurrency(originalAmount/subunit, originalCurrency, locale)`. Place near amount block (lines 222-229). |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` | **Extend** | `_getCurrencyDecimals` (lines 83-91) hardcodes only JPY/KRW=0. Replace the `default: 2` with `intl`'s `currencyFractionDigits` lookup so e.g. BHD=3 is correct. `_getCurrencySymbol` already covers common symbols + ISO-code fallback (lines 54-81) — extend as needed but ISO fallback is acceptable. | Route `subunitToUnitFor()` (`currency_conversion.dart:70`) through the same `intl` map so decimals + subunit stay consistent (its own comment invites this). |
| `lib/shared/utils/currency_conversion.dart` | **Extend (minor)** | `subunitToUnitFor` (line 70) hardcodes JPY/KRW=1 else 100. Use `pow(10, intl fraction digits)` for correctness on 3-decimal currencies (BHD/JOD/KWD). `convertToJpy()` itself UNCHANGED. | Keeps the single-parse-site invariant intact. |
| `lib/infrastructure/voice/{japanese,chinese}_numeral_state_machine.dart` | **Extend** | Add currency-token detection alongside numeral parsing. ja `_skipPattern` (line 66) currently skips `¥￥円えんyen` — extend to detect (not just skip) ドル/ユーロ/ポンド etc. zh machine silently drops non-numeral runes (line 94) — add currency-suffix detection before drop. | Return the detected currency separately; do not pollute the integer amount result. |
| `lib/shared/constants/voice_currency_suffixes.dart` | **Extend** | Add a code-mapping table: zh 美元→USD, 欧元→EUR, 英镑→GBP, 港币→HKD, 澳元→AUD, 加元→CAD; ja ドル→USD, ユーロ→EUR, ポンド→GBP, 香港ドル→HKD, 豪ドル→AUD. Keep `all` ordering (longest-first) invariant. | `元`/`円` ambiguity resolved by `localeId`: zh→CNY, ja→JPY (D-08, locked). Bare `ドル`→USD. |
| `lib/features/accounting/domain/models/voice_parse_result.dart` | **Extend** | Add `String? detectedCurrency`. Run build_runner. | `@freezed`; null = JPY-native (preserves existing behavior). |
| `lib/application/voice/parse_voice_input_use_case.dart` | **Extend** | Plumb `detectedCurrency` from the numeral machine through to `VoiceParseResult`. `_extractKeyword` (line 132) already strips currency suffixes via `VoiceCurrencySuffixes.all` — extend the alternation so new tokens are stripped from keywords too. | Keep merchant/category resolution untouched. |

**New widgets to create:**
- `CurrencySelectorSheet` (`features/accounting/presentation/widgets/`) — D-01/D-02.
- JPY conversion preview panel (`features/accounting/presentation/widgets/`) — DISP-01/D-03/D-04/D-05.
- `AmountInputController` (host-side pure-Dart state machine) — CURR-05/D-06/D-07/D-08.
- `ChangeRateConfirmationDialog` (ADR-022 D-02) + JPY-changed undo toast (ADR-022 D-03 — likely reuses `feedback_toast.dart` `actionLabel`/`onAction`, verified present at lines 41-42).
- Recent-use currency Riverpod provider (session-scoped; resets to JPY on restart per UI-SPEC).

## Architecture Patterns

### System Architecture Diagram

```
                     ┌──────────────────────────────────────────────┐
   user taps         │  SmartKeyboard.currencyKey  ──tap──►          │
   currency key ────►│  CurrencySelectorSheet (JPY first, search,    │
                     │   recent-use, full ISO via "more")            │
                     └───────────────┬──────────────────────────────┘
                                     │ returns ISO code
                                     ▼
   digit/dot ──► AmountInputController (D-06 gate dot, D-07 cap decimals,
   keypad           D-08 truncate on currency switch) ──► _amount string
                                     │
                                     ▼  (currency != JPY)
                     appGetExchangeRateUseCaseProvider.execute(
                        GetExchangeRateParams{currency, date, previousRate?})
                                     │ Future<RateResultWithSignal>
                     ┌───────────────┴───────────────┐
                     ▼                                ▼
              RateResult (rate string)          RateSignal? (D-02 dialog /
                     │                            D-03 toast — already computed
                     ▼                            by the use case)
   convertToJpy(originalMinorUnits, rate, subunitToUnit)  ──single site──►
                     │
        ┌────────────┼─────────────────────┬────────────────────────┐
        ▼            ▼                      ▼                        ▼
   Preview panel   List tile           Edit host JPY row        persisted
   ≈ ¥7,415 +      (USD 50.00          (read-only derived)      amount (int)
   rate sub-row    annotation)                                  via Create/Update
   + staleness                                                  TransactionParams
   warning (D-05)

   VOICE WAVE (parallel):
   recognized text ─► numeral state machine (detects amount + currency token)
                   ─► ParseVoiceInputUseCase ─► VoiceParseResult{amount, detectedCurrency}
                   ─► TransactionDetailsForm (surfaces currency, editable)
                   ─► triggers the same rate-fetch flow above
```

### Pattern 1: Consume the rate use case via `ref.watch` + `ref.listen` split
**What:** `ref.watch(appGetExchangeRateUseCaseProvider)` to get the use case; call `.execute()` in a `FutureProvider`/`AsyncNotifier` keyed on (currency, date, amount). Render `RateResult` in the preview. Handle `RateSignal` (dialog/toast) via `ref.listen`, NOT `ref.watch`.
**When to use:** preview panel + edit host.
**Example:**
```dart
// Source: get_exchange_rate_use_case.dart (verified) — the use case already
// returns RateResultWithSignal with D-02 dialog / D-03 toast pre-computed.
final result = await ref
    .read(appGetExchangeRateUseCaseProvider)
    .execute(GetExchangeRateParams(
      currency: currency,
      date: txDate,
      previousRate: previousRate,            // drives D-03 toast threshold
      wasManualOverride: wasManualOverride,  // drives D-02 dialog
    ));
// result.result -> render preview / read-only JPY
// result.signal -> RateSignalDialog | RateSignalToast | null  (surface via ref.listen)
```

### Pattern 2: Single conversion site everywhere
**What:** preview, list annotation, and edit read-only JPY all call `convertToJpy(originalMinorUnits:, appliedRate:, subunitToUnit:)`.
**Why:** ADR-020 / UI-SPEC Invariant #4 — guarantees the three surfaces show identical figures, and matches the value `CreateTransactionUseCase` persists (it calls the same function internally, verified at line 140).

### Pattern 3: Host-owns-amount, form-syncs (existing P19 D-14 pattern)
**What:** The screen host owns the amount string + currency; the form keeps a synced copy for save-time validation via imperative `updateAmount()`/(new) `updateCurrency()`/`updateRate()`.
**When:** all entry surfaces. Mirror the existing `_formKey.currentState?.updateAmount(parsed)` calls in `manual_one_step_screen.dart`.

### Anti-Patterns to Avoid
- **Three-field bidirectional editing** — VOID per ADR-022 D-01 (circular dependency). Edit = 2 inputs + 1 derived.
- **Inline `double.parse(appliedRate) * amount`** — forbidden (ADR-020 line 153). Always go through `convertToJpy()`.
- **Adding currency fields to the hash formula** — forbidden (ADR-021). `UpdateTransactionUseCase` must NOT rehash on currency edit.
- **`ref.watch` for the D-02 dialog / D-03 toast** — these are side-effects; use `ref.listen` (CLAUDE.md Riverpod-3 note: "Side-effect listeners belong in `ref.listen`, not `ref.watch`").
- **Rounding decimals on currency switch** — D-08 mandates **truncation** (`50.50 → 50`, not `51`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ISO 4217 minor-unit decimals | Custom decimals map | `intl` `currencyFractionDigits` (already in tree) | Authoritative, maintained, covers 3-decimal currencies (BHD/JOD/KWD) you'd otherwise miss. |
| JPY conversion math | New conversion in UI | `convertToJpy()` | Single-site invariant; matches persisted value exactly. |
| Rate priority / staleness / override detection | Re-derive in UI | `GetExchangeRateUseCase` (P41) | Already returns `RateResult` variants + `RateSignal`. UI only renders. |
| D-02 dialog / D-03 toast threshold logic | Recompute >1% in UI | `RateSignalDialog`/`RateSignalToast` from the use case | Use case already computes the threshold (verified `_maybeToast`, line 141). |
| Undo toast with action button | New SnackBar widget | `feedback_toast.dart` `showSuccessFeedback(actionLabel:, onAction:)` | Already supports inline action + duration (verified; used for "退出记账"). |
| Number-word parsing | New parser | Extend existing `{ja,zh}_numeral_state_machine.dart` | Mature, tested (P21+ corpus). Only add currency-token detection. |

**Key insight:** Phase 42 is overwhelmingly a wiring/rendering phase. The hard logic already exists and is tested. The genuinely new pure-logic piece is the decimal-input state machine (Open Q3). Resist re-deriving rate/conversion logic in the UI.

## Open Technical Questions — Recommendations

### Q1. ISO 4217 currency data source → **Recommendation: hybrid (`intl` for decimals + ARB for names), no new package**

- **Decimals/minor units:** Use `intl 0.20.2`'s `currencyFractionDigits` map (verified present at `number_symbols_data.dart:5219`; e.g. `"BHD":3,"JOD":3,"KWD":3`, JPY=0). It is authoritative and already a dependency. Route both `NumberFormatter._getCurrencyDecimals` and `currency_conversion.subunitToUnitFor` through it. [VERIFIED: pub-cache `intl-0.20.2`]
- **Symbols:** `NumberFormatter._getCurrencySymbol` already has common ones + ISO-code fallback (verified). Acceptable as-is; extend opportunistically.
- **Localized names (美元/ドル):** NO package supplies ja/zh currency names (`currency_picker` is English-only; `intl` gives symbols/decimals, not localized display names for the set we need). Source these from the project's own **ARB files** (consistent with i18n discipline, golden-friendly, no dependency). Embed a `Map<isoCode, l10nKey>` and resolve via `S.of(context)`. Scope: the common zone (JPY/USD/EUR/CNY/HKD/GBP/KRW/TWD/SGD/AUD/CAD) needs names; the long-tail "more" list can fall back to ISO code + English name without ja/zh until requested.
- **Why not `currency_picker`:** clean deps (no win32 risk), but it duplicates the decimals `intl` already has and gives English-only names — net negative unless the planner specifically wants its prebuilt search sheet.

### Q2. Flag emoji cross-platform strategy → **Recommendation: emoji + region fallback default; `country_flags` (SVG) as documented escape hatch**

- Default per D-01: Unicode regional-indicator flag emoji (`🇺🇸`) + a fallback for no-1:1-country currencies (`🇪🇺` for EUR; neutral placeholder like 🏳️ or a generic currency glyph for XAF/XCD).
- **Known risk:** iOS renders true flag glyphs; many Android builds render two-letter boxes (`US`) because the system emoji font lacks flag sequences. This is a real, documented divergence. [ASSUMED — training knowledge; verify on a real Android device during execution]
- **Golden implication:** flag glyphs render via the host font and will differ macOS-baseline vs device. Recommend the selector-row goldens **mask/exclude the flag cell** (or render flags off in golden mode) so the row layout is verified without coupling to font-emoji pixels. The existing `BaselineExistenceGoldenComparator` (off-macOS) already tolerates font-AA diffs; flag emoji are a stronger divergence and should be isolated.
- **Escape hatch (Deferred Idea):** if device testing shows broken Android flags, swap to `country_flags 4.1.2` (SVG via `jovial_svg`, renders identically everywhere). Gate the add behind `checkpoint:human-verify` + iOS build verify. Do NOT add pre-emptively.

### Q3. Decimal-input state machine → **Recommendation: host-owned pure-Dart `AmountInputController`**

Design as a small immutable-state controller the host drives (mirrors existing host-owns-amount pattern). State = `{ digits: String, decimals: int (the active currency's minor unit) }`.

Transitions:
- **onDigit(d):** if a `.` is present and fractional length already == `decimals` → ignore (D-07 cap). Else append.
- **onDot():** only callable when `decimals > 0`. For `decimals==0` currencies the host passes `onDot: null` to `SmartKeyboard` (D-06) so the dot key is hidden/replaced. (Hook already nullable, verified `smart_keyboard.dart:36,149`.)
- **onCurrencyChange(newDecimals):** **truncate** existing fractional part to `newDecimals` digits (D-08: `50.50`→`50` for 0-decimal; `50.567`→`50.56` if target is 2). NEVER round. Strip a trailing lone `.` when truncating to 0.
- Existing host code (`manual_one_step_screen.dart:212-250`) hardcodes a 4-decimal cap and an unconditional dot — replace with this controller.

**48dp / D-06 layout note (NON-NEGOTIABLE):** when the dot key is removed for 0-decimal currencies, the action/extra row must keep 48dp and equal-width structure. Cleanest: keep the `_buildExtraRow` `00 / 0 / .` grid but render the dot cell as a disabled/blank 48dp tile (or a benign duplicate like a second backspace) rather than collapsing the row — collapsing shifts every other key and risks mis-taps + golden churn. Decide the replacement glyph in planning; preserve geometry.

### Q4. Voice currency vocabulary extension → **Recommendation: detect token → ISO code in the numeral machines; carry on `VoiceParseResult`**

- Extend `voice_currency_suffixes.dart` with a `Map<token, isoCode>` (zh: 美元→USD, 欧元→EUR, 英镑→GBP, 港币→HKD, 澳元→AUD, 加元→CAD; ja: ドル→USD, ユーロ→EUR, ポンド→GBP, 香港ドル→HKD, 豪ドル→AUD). Keep longest-first ordering (香港ドル before ドル; 日元 before 元 — existing invariant at lines 26-36).
- In each numeral machine, detect the currency token (today ja skips `ドル` as a skip-char at line 66; zh drops it silently). Return detected currency alongside the integer amount.
- Bare-token defaults (locked): bare `元` → JPY-terminator (zh=CNY when localeId=zh, ja=JPY); bare `円` → JPY; bare `ドル` → USD.
- `ParseVoiceInputUseCase.execute` plumbs `detectedCurrency` into `VoiceParseResult` (new nullable field). `_extractKeyword` must also strip the new tokens (extend the `VoiceCurrencySuffixes.all` alternation) so `5美元` doesn't leave `美元` in the keyword.
- Form surfaces `detectedCurrency` (editable) and triggers the normal rate-fetch flow (VOICE-CUR-02/03).
- **English deferred** — do NOT add ドル/dollar English tokens this phase.

## Common Pitfalls

### Pitfall 1: CURR-04 JPY-path regression (HIGH severity)
**What goes wrong:** Adding currency state to shared widgets accidentally changes JPY entry/list/detail rendering → JPY goldens break.
**Why:** The selector key, preview panel, and dot-gating all touch screens JPY uses.
**How to avoid:** Guard every new surface on `currency != 'JPY'`. JPY: no rate fetch, no preview panel mounted, no list annotation, no dot-key change. Keep a JPY-only golden set that must stay **byte-identical**.
**Warning signs:** any JPY golden diff; a rate-fetch firing when currency is JPY.

### Pitfall 2: `UpdateTransactionParams` missing currency triple (correctness gap)
**What goes wrong:** Edit host edits original amount/rate but the update use case silently keeps the old JPY `amount` (or drops the triple) — edited foreign rows don't persist correctly.
**Why:** `UpdateTransactionParams` (verified lines 26-51) has no currency fields; only `CreateTransactionParams` does.
**How to avoid:** Extend `UpdateTransactionParams` + `execute()` to accept the triple, recompute `amount` via `convertToJpy()`, run the same partial-triple validation `CreateTransactionUseCase` uses (lines 101-142), and re-save without rehash (ADR-021). Add a unit test asserting an edited USD row's JPY is recomputed.
**Warning signs:** edit-then-reopen shows stale JPY; partial-triple sneaks through.

### Pitfall 3: Decimal truncation rounding bug (D-08)
**What goes wrong:** Using `.round()`/`num` conversion when switching to a 0-decimal currency turns `50.50` into `51` instead of `50`.
**Why:** Instinct is to round money.
**How to avoid:** Truncate as a **string operation** (cut the fractional substring), not arithmetic. `50.50` → strip `.50` → `50`. Test boundary: `0.99`→`0`, `50.5`→`50`, `50.567`→`50.56` (2-decimal target).
**Warning signs:** any +1 yen on currency switch.

### Pitfall 4: Riverpod 3 side-effect via `ref.watch` (rebuild loop / missed toast)
**What goes wrong:** Surfacing the D-02 dialog / D-03 toast from `ref.watch` causes rebuild storms or fires on every rebuild.
**Why:** CLAUDE.md Riverpod-3 note: watch-driven side-effects were dropped/changed in v3.
**How to avoid:** Use `ref.listen(rateNotifierProvider, (prev, next) { surface signal })` for dialog/toast; `ref.watch` only for the rendered `RateResult`. Also: async test pattern — use `waitForFirstValue` / `ProviderContainer.test()` (CLAUDE.md), not bare `await container.read(provider.future)` on auto-dispose providers.
**Warning signs:** toast appears twice; dialog re-opens on unrelated rebuild; `Bad state: disposed during loading` in tests.

### Pitfall 5: Preview panel jump / keyboard occlusion (D-04)
**What goes wrong:** Loading→loaded swaps a spinner for text of different height → layout jumps; or the panel overlaps the SmartKeyboard.
**Why:** Naive `if (loading) Spinner() else Text()`.
**How to avoid:** Fixed-height in-place skeleton at the preview row (same height as the loaded state). Panel sits in the scroll area above the keyboard (mirror `manual_one_step_screen` layout where SmartKeyboard is after the Expanded).
**Warning signs:** vertical jitter on rate arrival; keyboard covering the preview.

### Pitfall 6: Voice keyword corruption from new currency tokens
**What goes wrong:** `5美元的咖啡` → amount/currency parsed but `美元` left in the category keyword → wrong category match.
**Why:** `_extractKeyword` strips only the tokens in `VoiceCurrencySuffixes.all`.
**How to avoid:** Add every new token to `all` (longest-first) so the existing strip regex removes it (mirrors the WR-07 fix rationale in the file header).
**Warning signs:** category resolver receives `美元`/`ドル` fragments.

## Runtime State Inventory

> Phase 42 is greenfield UI on existing data — no rename/migration. But two state-persistence notes matter:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None new. Triple columns already exist (P40 v21). Edit writes via use case. | None — edit path reuses existing columns. |
| Live service config | None. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None (rate APIs are keyless per P41). | None. |
| Build artifacts | `freezed` regen required after adding `VoiceParseResult.detectedCurrency` → run `build_runner`. | code edit + `flutter pub run build_runner build --delete-conflicting-outputs`. |
| Session state | "Recent-use currency" + "last-used foreign currency = session default, resets to JPY on restart" (UI-SPEC) — **intentionally NOT persisted**. | Hold in a non-persisted Riverpod provider; do NOT write to Drift/secure storage. |

## Validation Architecture

> Nyquist validation is ENABLED (`config.json workflow.nyquist_validation: true`, verified).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `golden_toolkit`-style goldens (project convention) |
| Config file | `flutter_test_config.dart` (swaps `BaselineExistenceGoldenComparator` off-macOS — MEMORY.md) |
| Quick run command | `flutter test test/<targeted_path>` |
| Full suite command | `flutter test` (MUST run full suite per-wave-merge — scoped tests miss architecture tests like `hardcoded_cjk_ui_scan`, per MEMORY Phase 38) |
| Test scope helper | `test/helpers/test_provider_scope.dart` (`waitForFirstValue`, `ProviderContainer.test()`) — verified present |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SC-5 / CURR-05 | USD 50 @ 148.30 → `amount=7415`, `original_currency='USD'` (integration smoke) | integration | `flutter test test/application/accounting/create_transaction_currency_test.dart` | ❌ Wave 0 |
| CURR-04 | JPY entry/list/detail goldens byte-identical | golden | `flutter test test/golden/` (JPY subset) | partial (existing JPY goldens — must stay green) |
| CURR-05 / D-08 | decimal truncation on currency switch (`50.50→50`, `50.567→50.56`) | unit | `flutter test test/.../amount_input_controller_test.dart` | ❌ Wave 0 |
| D-06 | dot key hidden/replaced for JPY/KRW, 48dp preserved | golden + widget | `flutter test test/.../smart_keyboard_dot_gating_test.dart` | ❌ Wave 0 |
| DISP-01/D-05 | preview renders rate sub-row + staleness warning for fallback/actualDate≠txDate | golden + widget | `flutter test test/.../conversion_preview_test.dart` | ❌ Wave 0 |
| DISP-02 | foreign list row shows `USD 50.00`; JPY row unchanged | golden | `flutter test test/golden/list_transaction_tile_*` | ❌ Wave 0 (foreign variant) |
| DISP-04/D-10 | edit host: JPY read-only derived recalcs on original/rate change; no bidirectional loop | widget | `flutter test test/.../edit_currency_linked_test.dart` | ❌ Wave 0 |
| D-13/ADR-022 D-02 | manual-override + date change → two-choice dialog | widget | same edit test file | ❌ Wave 0 |
| D-13/ADR-022 D-03 | no-override + >1% JPY change → non-blocking toast + undo restores old rate | widget | same edit test file | ❌ Wave 0 |
| Update plumbing | edited foreign row recomputes JPY + persists triple, no rehash | unit | `flutter test test/application/accounting/update_transaction_currency_test.dart` | ❌ Wave 0 |
| VOICE-CUR-01/02 | per-currency × per-locale corpus ≥5 cases each (zh: 美元/欧元/英镑/港币/澳元/加元; ja: ドル/ユーロ/ポンド/香港ドル/豪ドル); bare 元/円/ドル defaults | unit | `flutter test test/infrastructure/voice/currency_detection_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `flutter test test/<area>` for the touched files.
- **Per wave merge:** FULL `flutter test` (architecture/CJK scan tests are not scoped — MEMORY Phase 38).
- **Phase gate:** full suite green before `/gsd-verify-work`; JPY goldens byte-identical; new goldens macOS-baselined.

### Wave 0 Gaps
- [ ] `test/application/accounting/create_transaction_currency_test.dart` — SC-5 USD 50@148.30→7415 integration smoke.
- [ ] `test/application/accounting/update_transaction_currency_test.dart` — edited triple recompute + no-rehash.
- [ ] `test/.../amount_input_controller_test.dart` — D-07 cap + D-08 truncation boundaries.
- [ ] `test/infrastructure/voice/currency_detection_test.dart` — per-currency×per-locale corpus + bare-token defaults + 元/円 ambiguity.
- [ ] `test/.../edit_currency_linked_test.dart` — ADR-022 D-01/D-02/D-03.
- [ ] New goldens (macOS): `CurrencySelectorSheet`, preview panel (loading/loaded/fallback/weekend states), edit three-row, foreign list row, dot-gated keyboard (JPY vs USD).
- [ ] Flag-cell golden isolation strategy (mask flags) — see Q2.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `NumberFormatter._getCurrencyDecimals` hardcoded JPY/KRW=0, else 2 | Route through `intl currencyFractionDigits` | Phase 42 | Correct 3-decimal currencies (BHD/JOD/KWD). |
| Roadmap "three-field bidirectional" | ADR-022 two-input/one-derived | 2026-06-12 (ADR-022) | Implementation MUST follow ADR-022. |
| `original_amount` described as TEXT in ADR-021 body | INTEGER minor units (ADR-021 Update 2026-06-12) | P40 review WR-09 | Voice/UI must build INTEGER minor units, not decimal strings. |

**Deprecated/outdated:**
- ROADMAP P42 SC-4 "editing any one recalculates the others" — VOID (ADR-022 D-01).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Android system emoji font lacks flag-sequence glyphs (renders `US` boxes) on many builds | Q2 | If flags render fine on target Androids, the golden flag-masking is unnecessary caution (low risk — masking is safe either way). |
| A2 | `country_flags` / `currency_picker` legitimacy (pub seam unavailable for `pub` ecosystem this session) | Package Audit | Registry-verified + clean deps, but gate any actual add behind `checkpoint:human-verify`. Both are optional/non-default. |
| A3 | Localized ja/zh currency names belong in ARB (no package supplies them) | Q1 | If a maintained ja/zh currency-name package is later found, could reduce ARB volume — low risk, ARB is the safe default. |
| A4 | `feedback_toast.dart` `actionLabel`/`onAction` suffices for the D-03 undo toast | Don't Hand-Roll | Verified present; if the 5s-window + undo semantics need more, a thin wrapper may be needed (low risk). |

## Open Questions

1. **Recent-use ordering algorithm for the common zone (CURR-02):** "re-ordered by recent use" — LRU within the session? Recommendation: simple session LRU list (non-persisted), JPY pinned first regardless. Planner to confirm whether JPY participates in reordering (UI-SPEC says JPY always first → it does not reorder).
2. **"More" long-tail localized names:** ja/zh names for all ~150 ISO codes is heavy ARB volume. Recommendation: localize only the common zone; long-tail shows ISO code + English name. Confirm acceptable scope with planner.
3. **Dot-key replacement glyph (D-06):** what occupies the dot cell for 0-decimal currencies (blank disabled tile vs functional key)? Recommendation: disabled blank 48dp tile to preserve geometry; planner finalizes.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `intl` (currencyFractionDigits) | Q1 decimals | ✓ | 0.20.2 (pinned) | — |
| `flutter_riverpod` | state/listeners | ✓ | 3.1+ | — |
| `freezed` toolchain | `detectedCurrency` field | ✓ | project | — |
| Rate APIs (Frankfurter / fawazahmed0) | preview live fetch | ✓ (P41, keyless) | — | cache-first → fallback → manual (P41 chain) |
| `country_flags` (optional) | Q2 SVG escape hatch | ✗ (not installed) | 4.1.2 (would add) | emoji + region fallback (default — no install) |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `country_flags` (default emoji path needs no install).

## Sources

### Primary (HIGH confidence)
- Codebase files read this session: `smart_keyboard.dart`, `transaction_details_form.dart`, `manual_one_step_screen.dart`, `transaction_edit_screen.dart`, `list_transaction_tile.dart`, `number_formatter.dart`, `currency_conversion.dart`, `rate_result.dart`, `get_exchange_rate_use_case.dart`, `create_transaction_use_case.dart`, `update_transaction_use_case.dart`, voice files, `voice_parse_result.dart`.
- ADR-020 / ADR-021 / ADR-022 (accepted, append-only).
- `42-CONTEXT.md`, `42-UI-SPEC.md` (approved).
- `intl-0.20.2/lib/number_symbols_data.dart` `currencyFractionDigits` map (pub-cache, verified).

### Secondary (MEDIUM confidence)
- pub.dev API for `currency_picker` (2.0.22, deps), `country_flags` (4.1.2, 117k dl/30d), scores.
- intl `NumberFormat.currency` docs (api.flutter.dev).

### Tertiary (LOW confidence)
- Android flag-emoji rendering divergence (training knowledge — verify on device).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `intl` map verified in pub-cache; no mandatory new package.
- Integration map: HIGH — every file read and line-referenced this session.
- Edit/ADR-022 model: HIGH — ADR is canonical and unambiguous.
- Decimal state machine: MEDIUM — design recommended, no precedent (as CONTEXT flagged).
- Flag strategy: MEDIUM — emoji default sound; Android divergence is `[ASSUMED]`, device-verify.
- Voice extension: HIGH — existing machines understood; extension scoped.

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable — internal codebase + pinned deps; the only external moving part is rate APIs, owned by P41).

## Sources (web)

- [intl NumberFormat.currency - Flutter API](https://api.flutter.dev/flutter/package-intl_intl/NumberFormat/NumberFormat.currency.html)
- [ISO 4217 - Wikipedia](https://en.wikipedia.org/wiki/ISO_4217)
