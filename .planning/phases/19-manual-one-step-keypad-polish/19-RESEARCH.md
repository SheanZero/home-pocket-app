# Phase 19: Manual One-Step + Keypad Polish — Research

**Researched:** 2026-05-23
**Domain:** Flutter UI consolidation + custom keypad polish + soft-keyboard coexistence
**Confidence:** HIGH (codebase verified) / MEDIUM (Flutter idiom decisions)

## Summary

Phase 19 is a pure Flutter UI-polish phase: collapse the manual entry two-screen flow into one `ManualOneStepScreen`, refactor `TransactionDetailsForm` to externalize amount editing, polish `SmartKeyboard` for responsive height with a 48dp safety floor, and add a handwritten `KeyboardToolbar` to handle soft-keyboard coexistence. Zero new pub.dev dependencies, no Drift schema migration, no new ADR.

All 24 design decisions (D-01..D-24) are locked by CONTEXT.md and UI-SPEC.md is approved. The research surface reduces to **technical landmine validation**: (1) the responsive-height formula in D-06 mathematically violates the 48dp floor on iPhone SE — planner MUST add `max(48, computed)` clamping (D-20 reserves this), (2) the `Scaffold(resizeToAvoidBottomInset: false)` + manual padding + `AnimatedSlide` interaction has a documented jitter risk that requires a specific ordering, (3) externalizing amount from `TransactionDetailsForm` breaks Phase 18's `_editAmount()` bottom sheet — `TransactionEditScreen` and `OcrReviewScreen` must each pick up that responsibility, (4) Phase 18 left **two test files** that exercise `TransactionConfirmScreen`/`TransactionEntryScreen` and **two characterization tests** which will all break on delete.

**Primary recommendation:** Treat D-20 as required, not discretionary (40% screen on iPhone SE → 34.56dp per key, below the 48dp floor); use a `LayoutBuilder` + `math.max(48.0, computedKeyHeight)` pattern. Adopt the standard FocusNode-per-TextField + `addListener` pattern for `_isTextFieldFocused` (driving `AnimatedSlide`); avoid `FocusScope.onFocusChange` because it fires for any descendant focus change including Material's own internal nodes (button focus, etc.). Plan a single migration commit per affected test file rather than re-targeting tests piecemeal.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Single-screen layout + Save button placement (Area 1)
- **D-01:** ManualOneStepScreen owns amount state + AmountDisplay + persistent SmartKeyboard; embeds TransactionDetailsForm for the non-amount fields. The form widget is REFACTORED to NOT render or edit amount internally — amount is pushed in via a new `updateAmount(int)` public method on `TransactionDetailsFormState`.
- **D-02:** Save button replaces the existing "Next" gradient button in `SmartKeyboard`'s action row (5th row). No separate full-width bottom CTA.
- **D-03:** Details section ordering top-to-bottom: LedgerTypeSelector toggle → DetailInfoCard (date row + category row as two-column-ish chips) → merchant TextField → note TextField → SatisfactionEmojiPicker (only when `_ledgerType == LedgerType.soul`).
- **D-04:** `EntryModeSwitcher` (Manual/OCR/Voice tabs) stays at the top of `ManualOneStepScreen`, unchanged from `TransactionEntryScreen`. Phase 22 will revisit when voice one-step screen lands.
- **D-05:** SmartKeyboard slide-out transition uses `AnimatedSlide` with `offset: Offset(0, _showSmartKeypad ? 0 : 1)`, `duration: 220ms`, `curve: Curves.easeInOut`.

#### Keypad polish — touch target + visual hierarchy (Area 2)
- **D-06:** Responsive keyboard height — total keypad takes ~40% of screen height (`MediaQuery.of(context).size.height * 0.40`), evenly distributed across 5 rows (4 digit + 1 action). Single key height = (total - row padding - safe area bottom) / 5. Floor: 48dp (iOS 44pt / Material 48dp safety).
- **D-07:** Row spacing increased from 8dp → 12dp (between digit rows); column spacing from 4dp → 6dp (between keys within a row). Background fill (`backgroundMuted`) is preserved.
- **D-08:** Action row keys (⌫ / ¥JPY / Save) use the same responsive height as digit keys — no special-cased 50dp.
- **D-09:** Golden tests for SmartKeyboard live in a NEW file `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`. Six images: {ja, zh, en} × {light, dark}, isolated SmartKeyboard (not whole screen).

#### Persistent keypad vs system soft keyboard (Area 3)
- **D-10:** `_amountFocused` is a local bool on `ManualOneStepScreen` state. Default `true` on mount. AmountDisplay tap = `_amountFocused = true` + `FocusManager.instance.primaryFocus?.unfocus()`. TextField tap (merchant/note) = `_amountFocused = false` (driven by `FocusScope` listener on the screen).
- **D-11:** When `_isTextFieldFocused == true` (soft keyboard up), a floating `KeyboardToolbar` (44dp tall, `Positioned(bottom: viewInsets.bottom, ...)` in a `Stack`) appears with left "Done" + right "记账" / Save buttons.
- **D-12:** KeyboardToolbar is a handwritten widget (Stack + Positioned + MediaQuery.viewInsets), no `keyboard_actions` or other pub package.
- **D-13:** `Scaffold(resizeToAvoidBottomInset: false)` on ManualOneStepScreen. The scrollable details section uses `Padding(bottom: max(viewInsets.bottom, smartKeypadAnimatedHeight))` to ensure content stays scrollable above whichever keyboard is currently shown.

#### Embedding + legacy disposition + field affordances (Area 4)
- **D-14:** TransactionDetailsForm refactor — externalize amount. Form widget no longer renders AmountDisplay or the internal amount-editing bottom sheet. New public method `void updateAmount(int amount)` on `TransactionDetailsFormState` lets hosts push amount state in. Form's internal `_amount` is still used at `submit()` time; host MUST keep it in sync.
- **D-15:** `TransactionEntryScreen` is deleted in Phase 19. All callers (router, main shell `+` button, demo data routes) repoint to `ManualOneStepScreen`. File `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` + its test file are removed.
- **D-16:** `voice_input_screen.dart:352` is repointed to push `ManualOneStepScreen` instead of `TransactionConfirmScreen`. All voice push parameters pass through unchanged.
- **D-17:** `TransactionConfirmScreen` is deleted in Phase 19.
- **D-18:** Field affordances unchanged from current TransactionConfirmScreen / TransactionDetailsForm patterns (category navigation, date picker, ledger toggle, satisfaction picker, merchant + note inline TextFields).

### Claude's Discretion
- **D-19:** AnimatedSlide curve and duration (220ms / Curves.easeInOut) — planner may tune within ±50ms / similar curves without re-asking.
- **D-20:** Exact responsive percentage (~40% of screen) — actual percentage may need iteration. If 40% on iPhone SE yields per-key < 48dp safety floor, the planner may bump to 42-45% to maintain the floor. **(Research finding: ~50% is required on iPhone SE; see Common Pitfall §1 below.)**
- **D-21:** KeyboardToolbar visual design (44dp height, "Done" left + "Save" right) — exact font weight, padding, gradient choice for the small Save button left to planner discretion.
- **D-22:** `done` ARB key reuse — if `S.of(context).done` exists, reuse it. **Verified: `done` does NOT exist in any of the three ARB files. Planner MUST add `keyboardToolbarDone` × 3 locales.**
- **D-23:** Backspace key (⌫) visual size — stays same-as-digit-keys (D-08).
- **D-24:** Where to put `_initializeDefaultCategory` logic — port verbatim from TransactionEntryScreen:52-82 into ManualOneStepScreen.

### Deferred Ideas (OUT OF SCOPE)
- Voice one-step integration (INPUT-02) — Phase 22.
- Record button UX (REC-01/REC-02) — Phase 22.
- Voice number parser (VOICE-01/02/03) — Phase 20.
- Voice category resolver level-2 enforcement (VOICE-04/05/06) — Phase 21.
- MOD-005 OCR writer landing — v1.4+.
- TransactionEditScreen UX redesign (stays tap-amount-to-open-sheet).
- OcrReviewScreen UX redesign (same; only takes D-14 spillover).
- Sound/haptic feedback, custom key arrangements, long-press behaviors, persistent-keypad toggle, field reordering, drag-to-dismiss keyboard.
- English voice input.
- Replacing SmartKeyboard with native system numpad.
- HomeHero ring changes (ADR-016 §3 isolation invariant).
- New gamification surfaces (ADR-012).
- Hash chain re-derivation on edit.
- Delete affordance / dirty-state confirmation / undo-after-save.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| KEYPAD-01 | User can tap each amount-input digit key with the intended digit registering ≥95% of taps; key height/touch-target meets platform minimum (iOS HIG 44pt / Material 48dp) and visual hierarchy makes adjacent keys discriminable at thumb reach | §Standard Stack (responsive sizing); §Common Pitfall 1 (iPhone SE math); §Code Examples (LayoutBuilder + max(48, _) clamp); §Validation Architecture (widget test asserts RenderBox.size.height ≥ 48) |
| INPUT-01 | User can complete a manual ledger entry on a single screen — amount, category, note, merchant, date, ledger type all editable inline without a "下一步" navigation | §Architectural Responsibility Map (host/form split); §Architecture Patterns (embeddable form + persistent keyboard); §Code Examples (GlobalKey/submit pattern, AnimatedSlide); §Validation Architecture (`expect(find.text(l10n.next), findsNothing)`) |
</phase_requirements>

## Architectural Responsibility Map

Phase 19 is a pure Flutter mobile-client phase. There is no API/server/CDN/DB tier work. Every capability lives in the Flutter presentation layer or the existing application layer.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Amount state ownership (digit input handlers, parsing, clamping) | Flutter Client (Screen `ManualOneStepScreen`) | — | Host owns the keypad UX per D-01; amount is screen-local until save |
| Field state (category, date, ledger, merchant, note, satisfaction) | Flutter Client (Widget `TransactionDetailsForm`) | — | Form widget is the canonical state-of-form per Phase 18 D-01; D-14 limits the carve-out to amount only |
| Persistent on-screen keypad (digit/dot/double-zero/delete/save) | Flutter Client (Widget `SmartKeyboard`) | — | Existing widget; refactored for responsive height + Save label |
| Soft-keyboard coexistence (toolbar, focus state) | Flutter Client (Screen + new Widget `KeyboardToolbar`) | — | Handwritten Stack/Positioned per D-12; no platform-channel work |
| Save persistence (CreateTransactionUseCase invocation) | Flutter Client (Widget `TransactionDetailsForm.submit()`) | Application layer (use case in `lib/application/`) | Form widget delegates to the existing Phase 18 use case path; no new application code in Phase 19 |
| Voice push → ManualOneStepScreen with pre-filled params | Flutter Client (Screen `VoiceInputScreen` line 352) | — | One-line `MaterialPageRoute.builder` change |
| Category default seeding (L1[0] + L2[0]) | Flutter Client (Screen initState; `categoryRepositoryProvider`) | Data layer (repo `findActive()`) | Port verbatim from `transaction_entry_screen.dart:52-82` per D-24 |
| Golden-test image regression | Flutter Test (`test/widget/.../smart_keyboard_golden_test.dart`) | — | Isolated widget pump; existing `matchesGoldenFile` infrastructure |
| ARB additions (`keyboardToolbarDone` × 3 locales) | Flutter Client (`lib/l10n/app_{ja,zh,en}.arb` + `flutter gen-l10n`) | — | Existing i18n stack; no new tooling |

**Tier-correctness sanity check (for planner):** No capability in this phase should be placed in `lib/data/` (no new tables/DAOs), `lib/infrastructure/` (no new platform/crypto/ML), or `lib/application/` (no new use cases — only consumes existing `createTransactionUseCaseProvider`). Every file Phase 19 touches lives under `lib/features/accounting/presentation/` OR `lib/l10n/` OR `test/`.

## Standard Stack

Phase 19 introduces **zero new pub.dev dependencies** [VERIFIED: pubspec.yaml grep, D-12 binding]. The stack below is the existing project stack consumed by Phase 19 surfaces.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter` (SDK) | sdk: ^3.10.8 | UI framework — Material 3, AnimatedSlide, FocusScope, Stack, Positioned, MediaQuery | Project foundation [VERIFIED: pubspec.yaml:7] |
| `flutter_riverpod` | ^3.1.0 | State management — `ConsumerStatefulWidget`, `ref.read/watch` for repo/use-case providers | Project standard per ARCH-004 [VERIFIED: pubspec.yaml:19] |
| `freezed_annotation` | ^3.0.0 | Sealed unions — already used by `TransactionDetailsFormConfig.$new/.edit`; Phase 19 does NOT extend the union | Project standard [VERIFIED: pubspec.yaml:23] |
| `flutter_localizations` (SDK) | — | ARB-driven i18n; `S.of(context)` codegen via `flutter gen-l10n` | Project standard; pinned to `intl: 0.20.2` [VERIFIED: pubspec.yaml:18] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` (SDK) | — | Widget tests, `matchesGoldenFile`, `tester.binding.setSurfaceSize` | All Phase 19 tests; existing infrastructure [VERIFIED: pubspec.yaml dev_dependencies] |
| `mocktail` | ^1.0.4 | Mock `TransactionRepository`, `CategoryRepository`, `CreateTransactionUseCase` for the SC-4 widget test | Existing test convention — `_MockTransactionRepository extends Mock` pattern is used in `test/unit/features/accounting/presentation/providers/use_case_providers_characterization_test.dart` [VERIFIED: grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Handwritten `KeyboardToolbar` (D-12 binding) | `keyboard_actions` pub package | REJECTED per D-12 + CLAUDE.md dependency-pin rule. `keyboard_actions` pulls transitive deps that fight the locked `win32` trio (`file_picker 11.0.2` / `package_info_plus 9.0.1` / `share_plus 12.0.2`). Handwritten version is ~30 lines. |
| Vanilla `flutter_test.matchesGoldenFile` (existing pattern) | `alchemist` pub package (multi-platform golden harness) | REJECTED per D-09 + UI-SPEC. Project already uses vanilla `matchesGoldenFile` in 4 existing files (`test/golden/{amount_display,soul_vs_survival_card,per_category_breakdown_card,home_hero_card}_golden_test.dart`). Consistency wins; no new dep. [VERIFIED: codebase grep] |
| Riverpod state for `_amount` / `_amountFocused` | `StatefulWidget` local state | REJECTED per ARCH-004 + D-10. Form state is screen-local UI concern; no provider needed. Mirrors the Phase 18 form widget's own pattern. |
| `AnimatedPositioned` for keyboard slide | `AnimatedSlide` (D-05 binding) | `AnimatedSlide` is lighter and uses transforms (GPU-fast); no layout re-compute. `AnimatedPositioned` would force the parent Stack to re-layout each frame. |
| Native system numpad | Custom `SmartKeyboard` | REJECTED — Phase 19 OOS line: "Replacing SmartKeyboard with the native system numpad — current keyboard is intentional design; only height/spacing are polished." |

**Installation:** No new packages. Verify `pubspec.yaml` is unchanged by running:
```bash
git diff pubspec.yaml pubspec.lock
# Should produce no output after Phase 19 lands.
```

**Version verification (already-installed packages, recorded for reference):**
```bash
flutter pub deps --json | jq '.packages[] | select(.name | IN("flutter_riverpod", "freezed_annotation", "mocktail")) | {name, version}'
```
All three packages already in `pubspec.lock`; no version bump needed in Phase 19.

## Package Legitimacy Audit

Phase 19 installs **zero new packages**. The audit table below is a placeholder for the planner to confirm the binding holds during plan generation.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| _(none added — D-12 binding)_ | — | — | — | — | — | N/A |

**Packages removed due to slopcheck [SLOP] verdict:** none (none considered).
**Packages flagged as suspicious [SUS]:** none.
**Planner action:** verify `git diff pubspec.yaml pubspec.lock` is empty before phase close.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────┐
   User tap "+"     │                                         │
   in main shell    │  ManualOneStepScreen                    │
   ───────────────▶ │  (ConsumerStatefulWidget)               │
                    │                                         │
                    │  State (screen-local):                  │
                    │    _amount: String                      │
                    │    _amountFocused: bool (default true)  │
                    │    _isTextFieldFocused: bool            │
                    │    _selectedCategory, _selectedDate     │
                    │    (defaults seeded from                │
                    │     categoryRepositoryProvider          │
                    │     in initState per D-24)              │
                    │                                         │
                    │  ┌──────────────────────────────────┐   │
                    │  │ AppBar (title: addTransaction)   │   │
                    │  ├──────────────────────────────────┤   │
                    │  │ EntryModeSwitcher (manual)       │   │
                    │  ├──────────────────────────────────┤   │
                    │  │ AmountDisplay                    │◀──┼── host-owned (D-14)
                    │  │   onTap: _amountFocused = true   │   │   tap unfocuses any TextField,
                    │  │           + unfocus()            │   │   slides SmartKeyboard back in
                    │  ├──────────────────────────────────┤   │
                    │  │ SingleChildScrollView            │   │
                    │  │   padding.bottom = max(          │   │
                    │  │     viewInsets.bottom,           │   │
                    │  │     smartKeypadAnimatedHeight)   │   │
                    │  │                                  │   │
                    │  │   TransactionDetailsForm         │◀──┼── embedded; GlobalKey
                    │  │     (config: .$new(...))         │   │   <TransactionDetailsFormState>
                    │  │     internal _amount kept in     │   │
                    │  │     sync via host calling        │   │
                    │  │     formKey.currentState!        │   │
                    │  │       .updateAmount(int)         │   │
                    │  │                                  │   │
                    │  │     renders (per D-03 order):    │   │
                    │  │       LedgerTypeSelector         │   │
                    │  │       DetailInfoCard             │   │
                    │  │         (date + category rows)   │   │
                    │  │       Merchant TextField         │◀──┼── focus → _isTextFieldFocused=true
                    │  │       Note TextField             │◀──┼── focus → _isTextFieldFocused=true
                    │  │       SatisfactionEmojiPicker    │   │
                    │  │         (soul only)              │   │
                    │  ├──────────────────────────────────┤   │
                    │  │ AnimatedSlide                    │   │
                    │  │   offset.dy = _showSmartKeypad   │   │
                    │  │     ? 0 : 1                      │   │
                    │  │   duration: 220ms                │   │
                    │  │   curve: easeInOut               │   │
                    │  │                                  │   │
                    │  │   SmartKeyboard (refactored)     │   │
                    │  │     height = max(48,             │   │
                    │  │       (h*0.40-padding)/5)        │   │ ◀── §Common Pitfall 1:
                    │  │     onNext: → formKey...submit() │   │     0.40 violates floor on
                    │  │     nextLabel: l10n.record       │   │     iPhone SE; clamp required
                    │  └──────────────────────────────────┘   │
                    │                                         │
                    │  KeyboardToolbar (in Stack, NEW widget) │
                    │   visible when viewInsets.bottom > 0    │
                    │   Positioned(bottom: viewInsets.bottom) │
                    │   ┌──────────────────────────────────┐  │
                    │   │ [Done]              [Record]     │  │
                    │   │   ↓                   ↓          │  │
                    │   │ unfocus()       formKey.submit() │  │
                    │   └──────────────────────────────────┘  │
                    │                                         │
                    └──────────────┬──────────────────────────┘
                                   │
                                   │ formKey.currentState!.submit()
                                   ▼
                    ┌──────────────────────────────────────┐
                    │ CreateTransactionUseCase             │  ← Phase 18 use case;
                    │ (via createTransactionUseCaseProvider│    no change in Phase 19
                    │  in repository_providers.dart)       │
                    └──────────────┬───────────────────────┘
                                   │ Result<Transaction>
                                   ▼
                    ┌──────────────────────────────────────┐
                    │ Drift TransactionDao.insert(...)     │  ← entry_source='manual'
                    │   atomic single statement            │     stamped by use case
                    └──────────────────────────────────────┘

   Voice path:
   VoiceInputScreen line 352 changes target:
     OLD: MaterialPageRoute(builder: (_) => TransactionConfirmScreen(...))
     NEW: MaterialPageRoute(builder: (_) => ManualOneStepScreen(...))
   All voice push params (bookId, amount, category, parentCategory, date,
   initialMerchant, initialSatisfaction, voiceKeyword, entrySource: voice)
   pass through unchanged.
```

### Recommended Project Structure
```
lib/
├── features/accounting/presentation/
│   ├── screens/
│   │   ├── manual_one_step_screen.dart       # NEW — load-bearing artifact
│   │   ├── transaction_edit_screen.dart      # REFACTORED — host now renders AmountDisplay (D-14 spillover)
│   │   ├── ocr_review_screen.dart            # REFACTORED — same spillover as edit
│   │   ├── transaction_entry_screen.dart     # DELETED (D-15)
│   │   ├── transaction_confirm_screen.dart   # DELETED (D-17)
│   │   └── voice_input_screen.dart           # ONE-LINE EDIT @ line 352 (D-16)
│   ├── widgets/
│   │   ├── transaction_details_form.dart     # REFACTORED — externalize amount, add updateAmount(int) (D-14)
│   │   ├── smart_keyboard.dart               # REFACTORED — responsive height + spacing + Save label
│   │   ├── keyboard_toolbar.dart             # NEW — handwritten 44dp Stack/Positioned (D-11/D-12)
│   │   └── amount_display.dart               # REUSED verbatim (host renders it)
│   └── navigation/
│       └── entry_mode_navigation_config.dart # ONE-LINE EDIT @ line 24 (D-15)
├── features/home/presentation/
│   └── screens/main_shell_screen.dart        # ONE-LINE EDIT @ line 128 (D-15)
├── l10n/
│   ├── app_ja.arb                            # +1 key: keyboardToolbarDone (D-22)
│   ├── app_zh.arb                            # +1 key
│   └── app_en.arb                            # +1 key
test/widget/features/accounting/presentation/
├── screens/
│   ├── manual_one_step_screen_test.dart      # NEW (SC-1, SC-2, SC-4, focus state machine)
│   ├── voice_to_manual_one_step_screen_test.dart  # NEW (D-16 regression)
│   ├── transaction_entry_screen_test.dart    # DELETED
│   └── transaction_confirm_screen_merchant_learning_test.dart # DELETED or re-target
└── widgets/
    ├── smart_keyboard_test.dart              # EXTEND — height computation assertion
    └── smart_keyboard_golden_test.dart       # NEW (SC-3, 6 images)
test/unit/features/accounting/presentation/screens/
├── transaction_entry_screen_characterization_test.dart  # DELETED
└── transaction_confirm_screen_characterization_test.dart # DELETED
```

### Pattern 1: Embeddable form + host-owned chrome (Phase 18 D-01, EXTENDED in Phase 19 D-14)
**What:** A `StatefulWidget` form (no Scaffold/AppBar/CTA) embedded via `GlobalKey<State>` so the host can call `.submit()` and pre-mutate state from the outside. Phase 19 extends this pattern: amount editing leaves the widget and the host pushes amount changes in via `updateAmount(int)`.

**When to use:** Whenever multiple host screens need the same form body but different chrome and different field-editing affordances. (Phase 19 manual → persistent keypad; Phase 18 edit/OCR → tap-to-open-sheet.)

**Example (host calls new public method):**
```dart
// In ManualOneStepScreen — digit handler updates host's _amount AND pushes to form.
void _onDigit(String digit) {
  setState(() => _amount += digit);
  final parsed = int.tryParse(_amount) ?? 0;
  _formKey.currentState?.updateAmount(parsed);
}

// In TransactionDetailsFormState — new public method (Phase 19 D-14):
/// Host-pushed amount update. Host owns the editing UX; form keeps
/// internal _amount in sync for save-time validation.
void updateAmount(int amount) {
  if (!mounted) return;
  setState(() => _amount = amount);
}
```
[VERIFIED: Phase 18 GlobalKey<TransactionDetailsFormState> pattern at `transaction_confirm_screen.dart:55`; CONTEXT.md D-14]

### Pattern 2: AnimatedSlide for off-screen widget transitions
**What:** Animate a child widget vertically by a multiple of its own height via `Offset(0, n)` (n=1 means "one full height down" = fully off-screen). GPU-friendly because it's a transform, not a layout change.

**When to use:** Persistent overlays/keyboards that need to slide in/out without altering the layout tree.

**Example:**
```dart
AnimatedSlide(
  offset: Offset(0, _showSmartKeypad ? 0 : 1),
  duration: const Duration(milliseconds: 220), // D-05 / D-19
  curve: Curves.easeInOut,                     // D-05 / D-19
  child: SmartKeyboard(/* ... */),
)
```
[CITED: api.flutter.dev AnimatedSlide; matches CONTEXT.md D-05]

### Pattern 3: FocusNode listener per TextField (recommended over FocusScope.onFocusChange)
**What:** Attach a dedicated `FocusNode` to each TextField, call `addListener` in `initState`, dispose in `dispose`. Update `_isTextFieldFocused` from `hasFocus`.

**When to use:** When the host screen needs to react specifically to user-text-input focus and NOT to incidental focus changes (e.g., Material InkWell focus, system focus indicators).

**Why preferred over `FocusScope.onFocusChange`:** `FocusScope.onFocusChange` fires for **any** descendant focus change, including focusable Material widgets (buttons, list tiles) and Flutter's own internal focus management. Filtering "is the currently-focused thing a TextField?" via the scope API requires walking the focus tree. Per-TextField FocusNodes are explicit and testable.

**Example:**
```dart
class _ManualOneStepScreenState extends ConsumerState<ManualOneStepScreen> {
  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;
  bool _isTextFieldFocused = false;

  @override
  void initState() {
    super.initState();
    _merchantFocus = FocusNode()..addListener(_handleFocus);
    _noteFocus = FocusNode()..addListener(_handleFocus);
    _initializeDefaultCategory(); // D-24 — port from TransactionEntryScreen:52-82
  }

  void _handleFocus() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    if (hasTextFocus == _isTextFieldFocused) return; // avoid redundant setState
    setState(() {
      _isTextFieldFocused = hasTextFocus;
      if (hasTextFocus) _amountFocused = false;
    });
  }

  @override
  void dispose() {
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }
}
```
**LANDMINE:** The merchant + note TextFields live INSIDE the `TransactionDetailsForm` widget today (`_buildStoreAndMemoSection` at lines 500-614). The host can't directly attach FocusNodes to them. Two options:
1. **Pass FocusNodes down into the form widget via config** — requires extending `TransactionDetailsFormConfig.$new` to accept `merchantFocusNode` / `noteFocusNode` optional parameters. Cleaner contract; minor breaking change to the config Freezed class (planner must regenerate). 
2. **Use `Focus.of(context).hasFocus` polling** via a top-level `Focus` widget wrapping the form — works but pollutes the focus tree.

**Recommendation:** Option 1. Add optional FocusNode params to `.$new` config; Phase 18 hosts pass `null`; ManualOneStepScreen passes its FocusNodes. The form widget threads them into the existing `_storeController` / `_memoController` TextFields. This keeps the focus state machine local to the screen, where it belongs. [CITED: docs.flutter.dev/cookbook/forms/focus]

### Pattern 4: Stack + Positioned for floating widget riding on soft keyboard
**What:** A `Stack` child positioned via `Positioned(bottom: MediaQuery.of(context).viewInsets.bottom)`. As the soft keyboard slides up/down, `viewInsets.bottom` animates with it — the positioned child rides along.

**When to use:** Toolbar attached to the top edge of the soft keyboard. Industry-standard iOS pattern (`UIBarButtonItem` in inputAccessoryView).

**Example:**
```dart
// In ManualOneStepScreen.build:
return Scaffold(
  resizeToAvoidBottomInset: false, // D-13
  body: Stack(
    children: [
      // ... main content ...
      // Toolbar — only visible when soft keyboard is up
      if (_isTextFieldFocused)
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          child: KeyboardToolbar(
            onDone: () => FocusManager.instance.primaryFocus?.unfocus(),
            onSave: _save,
            isSubmitting: _isSubmitting,
          ),
        ),
    ],
  ),
);
```
[CITED: api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html]

### Anti-Patterns to Avoid
- **`Scaffold.persistentFooterButtons` for the KeyboardToolbar.** They don't react to `viewInsets.bottom` and won't ride above the soft keyboard. Use `Stack + Positioned` per D-11.
- **Polling `MediaQuery.viewInsets.bottom > 0` to set `_isTextFieldFocused`.** The soft keyboard can be visible with NO TextField focused (e.g., after orientation change). Always derive from FocusNode state.
- **Calling `setState` inside the FocusNode listener without an equality check.** Listener fires on focus AND blur; without the `if (hasTextFocus == _isTextFieldFocused) return;` guard you get redundant rebuilds during the soft-keyboard animation, which compounds the jitter risk (Pitfall §2).
- **Using `AnimatedPositioned` for the KeyboardToolbar.** The soft keyboard's own slide already animates `viewInsets.bottom`; adding `AnimatedPositioned` would double-animate.
- **Letting Flutter's default `resizeToAvoidBottomInset: true` fight `AnimatedSlide`.** D-13 explicitly disables the default; if planner forgets, both the body resize AND the AnimatedSlide animate simultaneously, producing the documented jitter [CITED: flutter/flutter#89914].
- **Re-rendering the `AmountDisplay` inside `TransactionDetailsForm` after D-14.** The form widget MUST stop rendering `AmountDisplay` and `DetailInfoRow(label: l10n.amount, onTap: _editAmount, ...)` — both at lines 631-640 today. Failing to remove these creates a double-render in the manual screen.
- **Using `GlobalKey<State>` instead of `GlobalKey<TransactionDetailsFormState>`.** The host needs to call public methods (`submit`, `updateAmount`); only the typed-state GlobalKey exposes them.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom focus-tree observer | A walker that descends `FocusScope.of(context)` | Per-TextField `FocusNode().addListener(...)` | Material widgets register their own focusable nodes; tree walks return false positives. Per-node listeners are O(1) and explicit. |
| Custom slide animation curve | Cubic curve from scratch | `Curves.easeInOut` (D-05) or `Curves.fastOutSlowIn` (Material entrance) | Both are constant `Curve` instances; visually equivalent for 220ms transitions. |
| Custom soft-keyboard detection | iOS/Android channel handlers | `MediaQuery.of(context).viewInsets.bottom > 0` | Flutter exposes this synchronously; no native code needed. |
| Custom golden-test harness | Manual `pumpAndSettle` + screenshot | `flutter_test`'s `matchesGoldenFile` (existing project usage) | 4 existing golden tests in `test/golden/` already use this; consistency wins. |
| Custom locale wrapper | Build a `LocaleData` provider | The existing `S.delegate` + `MaterialApp(locale: ...)` from `test/golden/soul_vs_survival_card_golden_test.dart:62-71` pattern | Phase 19 golden test should clone this wrapper. |
| Custom keyboard-accessory bar | A pub.dev package like `keyboard_actions` | Handwritten `Stack + Positioned + MediaQuery.viewInsets` per D-12 | Bound by dependency-pin rule (CLAUDE.md). ~30 lines of code. |
| Tabular figures override | Set `FontFeature.tabularFigures()` inline per text widget | `AppTextStyles.amountLarge` (already encoded; line 151) OR `AppTextStyles.labelMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()])` | UI-SPEC mandates digit glyphs use tabular figures; the constant exists. |
| Repository default category logic | Re-derive L1[0]+L2[0] in widget | Port `_initializeDefaultCategory()` verbatim per D-24 (lines 52-82 of `transaction_entry_screen.dart`) | Already battle-tested; verbatim port reduces regression surface. |

**Key insight:** Phase 19 is a **flow consolidation**, not a feature build. The instinct to "improve while refactoring" is the largest regression risk. Every locked decision (D-01..D-24) was reached after explicit consideration of alternatives; planner should treat them as inputs, not options.

## Runtime State Inventory

Phase 19 is partially a **refactor + delete** phase (deletes `TransactionEntryScreen` and `TransactionConfirmScreen`), so the inventory matters.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 19 changes no Drift schema (verified against CONTEXT.md "No Drift schema migration" line + `no schema bump` carry from Phase 18). `transactions.entry_source` column already takes `'manual'` from Phase 17. | None |
| Live service config | None — no n8n, Datadog, Tailscale, Cloudflare or similar external services. Project is a local-first Flutter app. | None |
| OS-registered state | None — no Windows Task Scheduler, pm2, launchd, systemd. iOS/Android app via Xcode/Gradle build only. | None |
| Secrets/env vars | None — no `.env`, no secret rename. SOPS not in this project. | None |
| Build artifacts / installed packages | **Stale generated files after `TransactionDetailsFormConfig` Freezed changes IF the planner adds FocusNode fields to `.$new` (Pattern 3 Option 1).** `transaction_details_form_config.freezed.dart` and `.g.dart` would be regenerated by `flutter pub run build_runner build --delete-conflicting-outputs`. AUDIT-10 CI guardrail catches stale committed files. | Run `flutter pub run build_runner build --delete-conflicting-outputs` after Freezed/Riverpod changes. Plan must include this step. |

**Test-file deletions (technical state, not runtime state):**
The following tests reference the deleted screens and will fail or be unreachable code after Phase 19:
- `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart` — DELETE (whole-file).
- `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart` — RE-TARGET to `ManualOneStepScreen` (the merchant-learning hook still exists inside `TransactionDetailsForm` per Phase 18 D-09; the test just needs a different host). 
- `test/unit/features/accounting/presentation/screens/transaction_entry_screen_characterization_test.dart` — DELETE (whole-file). Characterization tests are pre-refactor snapshots; they have served their purpose.
- `test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart` — DELETE (whole-file). Same rationale.

Total Phase 18-era test files referencing `TransactionConfirmScreen` or `TransactionEntryScreen`: **17 matches across 4-5 files** [VERIFIED: `grep -rn TransactionEntryScreen\|TransactionConfirmScreen test/ | wc -l`].

**Worklog:** Per `.claude/rules/worklog.md`, Phase 19 close requires `doc/worklog/YYYYMMDD_HHMM_*.md` entry. (Not runtime state, but state the planner must remember.)

## Common Pitfalls

### Pitfall 1 (CRITICAL): D-06's 40% screen height violates the 48dp floor on iPhone SE
**What goes wrong:** The CONTEXT.md formula `(MediaQuery.size.height × 0.40 − rowGaps − safeArea.bottom) / 5` computes to **34.56 dp per key** on iPhone SE (height 667pt) — below both the iOS HIG 44pt minimum and the Material 48dp minimum. SC-2 is a binding contract; failing it fails the phase.

**Why it happens:** The 40% heuristic was picked for "approximately 2/5 screen" feel on common-case iPhone 14/15 (844pt), where it yields ~60dp per key. The math wasn't checked against the smallest supported screen.

**The math (recorded for the planner):**

| Device | Screen height | Total keypad (40%) | After row gaps (4 × 12 = 48) | After safe-area (~34) | Per key (÷5) | Passes 48dp? |
|--------|---------------|---------------------|------------------------------|----------------------|--------------|--------------|
| iPhone SE 4.7" | 667 pt | 266.8 | 218.8 | 184.8 | **36.96 dp** | ❌ FAILS |
| iPhone 14 6.1" | 844 pt | 337.6 | 289.6 | 255.6 | 51.12 dp | ✅ pass |
| iPhone 14 Pro Max 6.7" | 932 pt | 372.8 | 324.8 | 290.8 | 58.16 dp | ✅ pass |

(Note: the table in CONTEXT.md uses slightly different gap accounting — 60dp not 48dp for "row padding" — but both numbers fail the 48dp floor on iPhone SE.)

**To hit 48dp on iPhone SE, the percentage must be ≥ ~50.1%:** `(5×48 + 48 + 34) / 667 = 322/667 ≈ 0.483`. So either:
- Bump the percentage from 40% to 50% (D-20 authorizes 42-45% within reason; the planner needs to extend that to ~50% on small screens — surface this in the plan as an explicit decision).
- Apply a `math.max(48.0, computedKeyHeight)` clamp, accepting that on iPhone SE the keypad will be > 40% of screen height (which is fine — saying "40% of screen" was always an approximation for visual feel, not a hard contract).

**How to avoid:** Use a `LayoutBuilder` + `math.max(48.0, ...)` clamp pattern. The clamp is the safer choice because it self-adjusts as Apple ships new devices; the planner shouldn't have to update a constant per screen size.

**Warning signs:** Widget test `RenderBox.size.height ≥ 48` fails on a `tester.binding.setSurfaceSize(const Size(375, 667))` surface (iPhone SE viewport). If the planner only tests against `Size(390, 844)` per UI-SPEC, this is missed.

**Recommended widget-test surfaces:** `Size(375, 667)` (iPhone SE) AND `Size(390, 844)` (iPhone 14 baseline) AND `Size(428, 926)` (Pro Max). Three asserts; all keys must satisfy ≥48dp on each.

[VERIFIED: math reproducible; CONTEXT.md D-20 reserves discretion for the bump]

### Pitfall 2 (HIGH): AnimatedSlide jitter vs `viewInsets.bottom` animation when both change simultaneously
**What goes wrong:** When the user taps a merchant/note TextField, three animations start at once:
1. Soft keyboard slides up (animates `MediaQuery.viewInsets.bottom` 0 → keyboard-height over ~250ms).
2. `AnimatedSlide` slides SmartKeyboard off-screen (offset.dy 0 → 1 over 220ms).
3. The scrollable details section's `Padding(bottom: max(viewInsets.bottom, smartKeypadAnimatedHeight))` recomputes every frame.

If the `max(...)` term oscillates (e.g., 0ms: SmartKeyboard height wins; 110ms: SmartKeyboard halfway off-screen — its height drops; viewInsets.bottom now wins), the content scrolls up, then down, then up — visible jitter.

**Why it happens:** `AnimatedSlide` does not change the widget's reported size — the `Offset.translate` is a render-time transform. So the host's `smartKeypadAnimatedHeight` (if computed as "where is the keypad now") would NOT shrink during the animation. The keyboard's reported size stays constant; only its position changes. This is GOOD — it means the `max()` term doesn't oscillate.

**BUT** if the planner accidentally computes `smartKeypadAnimatedHeight` from `RenderBox.localToGlobal(...).dy` (which DOES change during AnimatedSlide), oscillation appears.

**How to avoid:** Compute `smartKeypadAnimatedHeight` as a **static value** derived from `MediaQuery.size.height * 0.40` (with floor clamp from Pitfall 1) plus padding. Never observe it via RenderBox lookup. The padding stays at the static height throughout the keyboard transition; `viewInsets.bottom` overtakes it once the soft keyboard is above the SmartKeyboard footprint.

**Warning signs:** A second visible scroll motion right after a TextField tap, or content briefly clipped behind the SmartKeyboard during the transition. Manual UAT on a real device catches this; widget tests do not (`tester.pumpAndSettle` skips intermediate frames).

[CITED: flutter/flutter#89914 — `SystemUiMode.edgeToEdge bottom viewInset jumps when keyboard is opening`; flutter/flutter#97609 — `SafeArea maintainBottomViewPadding is not respected when keyboard viewInsets are animated`. Both confirm jitter is a real risk class when viewInsets and a host animation are stacked.]

### Pitfall 3 (HIGH): Externalizing amount breaks Phase 18's `_editAmount()` integration in TransactionEditScreen + OcrReviewScreen
**What goes wrong:** Phase 18's `transaction_details_form.dart:182-286` defines `_editAmount()` which opens a modal bottom sheet with SmartKeyboard for tap-to-edit-amount. This is invoked from `DetailInfoRow(label: l10n.amount, onTap: _editAmount)` at line 631-640. After D-14 deletes both the row and the function from the form widget, `TransactionEditScreen` and `OcrReviewScreen` lose their amount-editing affordance.

**Why it happens:** D-14's framing ("ManualOneStepScreen uses persistent keypad; the other two hosts use tap-to-sheet") implies "the other two hosts pick up the sheet logic." But the sheet code currently lives in the form widget; transplanting it is non-trivial because:
- The sheet manages its own `editStr` local state (StatefulBuilder).
- On confirm, it calls `setState(() => _amount = parsed.round())` — which targets the form's `_amount`, not the host's.
- After externalization, that `setState` needs to call `formKey.currentState!.updateAmount(parsed.round())` instead.

**How to avoid:** Plan a **new shared widget `AmountEditBottomSheet`** in `lib/features/accounting/presentation/widgets/amount_edit_bottom_sheet.dart` that:
- Accepts `initialAmount: int` and `onConfirm: ValueChanged<int>` parameters.
- Owns its `editStr` state internally (StatefulBuilder pattern from current `_editAmount`).
- Renders the SmartKeyboard with `onNext: () => onConfirm(parsedAmount); Navigator.pop(context);`.
- Both `TransactionEditScreen` and `OcrReviewScreen` show it via `showModalBottomSheet` on AmountDisplay tap, and feed the result to `formKey.currentState!.updateAmount(int)`.

This is **one extra widget** but it (a) DRYs the sheet logic across two hosts, (b) keeps the form widget pure (no embedded amount-editing UI), and (c) makes the sheet testable in isolation. The alternative — duplicating the StatefulBuilder block in both host screens — fails CLAUDE.md "many small files" preference and accumulates the same code in two places.

**Test invalidation:** Existing Phase 18 tests for `TransactionEditScreen` and `OcrReviewScreen` may not exercise the amount-editing sheet. Planner should:
1. Audit `test/widget/features/accounting/presentation/screens/transaction_edit_screen_test.dart` and `ocr_review_screen_test.dart` (if they exist) for amount-editing assertions.
2. Add or update tests for the AmountEditBottomSheet host integration.

[VERIFIED: `transaction_details_form.dart:182-286` _editAmount() method; D-14 explicit invariant "Only ManualOneStepScreen uses the persistent SmartKeyboard pattern"]

### Pitfall 4 (MEDIUM): The 17 test references across deleted screens need surgical handling
**What goes wrong:** Phase 18 added characterization tests (snapshot tests of pre-refactor behavior) for both `TransactionEntryScreen` and `TransactionConfirmScreen`. Phase 19 deletes both screens. The characterization tests will fail to compile (class not found) before they fail to assert.

**Why it happens:** Characterization tests are normally deleted alongside the refactored code once their useful life is over — they exist to prove "the new code preserves the old behavior" and become dead weight once the refactor is shipped. They were not designed to outlive the original screen.

**Files affected:**
- `test/unit/features/accounting/presentation/screens/transaction_entry_screen_characterization_test.dart` — DELETE (no behavior left to characterize).
- `test/unit/features/accounting/presentation/screens/transaction_confirm_screen_characterization_test.dart` — DELETE.
- `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart` — DELETE.
- `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart` — RE-TARGET to `ManualOneStepScreen`. The merchant-learning hook is in the form widget's `_editCategory` voice-keyword branch (still present per Phase 18 D-09); the test mounts a host with `voiceKeyword` and verifies the learning callback fires on category change. Just swap `TransactionConfirmScreen` for `ManualOneStepScreen` in the pump.

**How to avoid:** Plan the deletes as one atomic commit ("delete screens + their characterization tests"); plan the re-target as a separate commit so the diff is readable. Don't ship a commit that has compile errors in tests.

[VERIFIED: file inventory via grep; test contents inspected at sample lines]

### Pitfall 5 (MEDIUM): `_initializeDefaultCategory` async + initState landmines
**What goes wrong:** Porting `_initializeDefaultCategory()` verbatim per D-24 means async category resolution starts in `initState`. If the user taps a digit BEFORE the async resolver completes, the `_selectedCategory` is still `null` when `submit()` runs validation — the user sees `pleaseSelectCategory` error after entering a valid amount, despite "the screen looking ready."

**Why it happens:** `initState` cannot be async; `_initializeDefaultCategory()` runs as a fire-and-forget Future. On a slow first launch (cold DB), the round-trip can take 100-300ms. The current `TransactionEntryScreen` accepts this; user perception is "ok, it's loading" — but in the one-step flow there's no intermediate screen, so the user can race the resolver.

**How to avoid:** Three options, planner picks:
1. **Accept the race; show a non-blocking toast.** If submit runs with `_selectedCategory == null`, show "Loading defaults — try again in a moment" toast. Lowest-effort; not great UX.
2. **Disable the Save button until `_selectedCategory != null`.** SmartKeyboard's Save key has a disabled-state mode (would need to add). Aligns with form validation UX.
3. **Pre-warm via FutureBuilder.** Wrap the entire body in a FutureBuilder of `_initializeDefaultCategory()`; show a skeleton/spinner until categories resolve. Most polished; adds 100-300ms first-paint latency.

**Recommendation:** Option 2 — disable Save until category present. Cleanest fix; matches the "no submit if invalid" pattern already enforced by `submit()` validation.

**Warning signs:** First-launch widget test that taps digits + Save immediately fails with `pleaseSelectCategory` toast. Solution: pumpAndSettle before tapping Save in the test.

[VERIFIED: Phase 18 form widget exhibits same behavior; CONTEXT.md D-24 ports the existing pattern verbatim]

### Pitfall 6 (MEDIUM): The `next` ARB key remains in ARB files but must not render in the manual flow
**What goes wrong:** UI-SPEC Copywriting Contract says `next` is not deleted from ARB (other flows may use it). SC-1 enforces "no Next/下一步 button in the manual path." If the planner forgets to change `SmartKeyboard`'s `nextLabel` parameter (currently defaults to `'Next'` per line 22), the rendered tree contains the string `Next` and SC-1's `expect(find.text(l10n.next), findsNothing)` fails.

**Why it happens:** `SmartKeyboard`'s `nextLabel` parameter defaults to the literal `'Next'` (not an ARB key). Even if `transaction_confirm_screen.dart:276` passes `S.of(context).record`, `transaction_entry_screen.dart:338` passes `l10n.next` directly. After D-15 deletes that caller, the default still says `'Next'`.

**How to avoid:** Change `SmartKeyboard`'s constructor parameter to be required (no default) OR change the default to `'Save'`. Plan should rename `nextLabel` → `actionLabel` so future flows that aren't conceptually "Next" don't carry the misleading parameter name; the UI-SPEC already implies `record` as the canonical save verb.

**Warning signs:** SC-1 widget test fails on the `findsNothing` assertion. Easy to catch in test but tedious to debug if the test is loose ("found 1 widget with text 'Next'" — the test prints the offending widget tree).

[VERIFIED: `smart_keyboard.dart:22` default `nextLabel: 'Next'`; `transaction_entry_screen.dart:338` passes `l10n.next`; `transaction_confirm_screen.dart:276` passes `S.of(context).record`]

### Pitfall 7 (LOW): Golden test font baseline mismatch on CI
**What goes wrong:** Golden tests pumped on a developer Mac may render slightly different from CI (Linux) due to font rendering differences. The 6 SmartKeyboard goldens × {ja, zh, en} include Japanese (Outfit + Noto Sans JP fallback) and Chinese glyphs (Outfit + Noto Sans SC fallback). If CI doesn't have the same fallback chain, the goldens fail on first CI run.

**Why it happens:** Flutter golden tests load fonts from `pubspec.yaml` `fonts:` entries. Both `Outfit` (primary) and `DM Sans` (nav) are listed per UI-SPEC. CJK fallbacks come from the OS, which differs between Mac and Linux.

**How to avoid:**
- Existing project goldens (`amount_display_jpy.png`, `soul_vs_survival_card_light_ja.png`, etc.) already work on CI — this means the CJK fallback chain works.
- Use the same `_wrap()` pattern as `test/golden/amount_display_golden_test.dart` (verified working).
- Run goldens locally with `--update-goldens` first; commit the baselines; CI verifies. If CI shows a 1-pixel diff, accept the new baseline.

**Warning signs:** `Pixel test failed, 0.2% of 86400 pixels differ` on first PR — usually a font-rendering nit, not a real regression.

**Recommendation:** Plan a "regenerate baselines on local Mac, commit, push, observe CI" rhythm. If first CI run fails, regenerate on CI via the existing project workflow. (Manual UAT is required for SC-3 baseline approval anyway — see Validation Architecture below.)

[VERIFIED: 4 existing golden test files in `test/golden/`; `_wrap` pattern documented in `amount_display_golden_test.dart:9-24`]

## Code Examples

### Example 1: ManualOneStepScreen skeleton (composition only — fields elided)
```dart
// Source: composed from CONTEXT.md D-01..D-13 + transaction_entry_screen.dart:27-344 (port pattern)
// File: lib/features/accounting/presentation/screens/manual_one_step_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/category.dart';
import '../../domain/models/entry_source.dart';
import '../../domain/models/transaction_details_form_config.dart';
import '../widgets/amount_display.dart';
import '../widgets/entry_mode_switcher.dart';
import '../widgets/input_mode_tabs.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/smart_keyboard.dart';
import '../widgets/transaction_details_form.dart';

class ManualOneStepScreen extends ConsumerStatefulWidget {
  const ManualOneStepScreen({
    super.key,
    required this.bookId,
    this.initialAmount,
    this.initialCategory,
    this.initialParentCategory,
    this.initialDate,
    this.initialMerchant,
    this.initialSatisfaction,
    this.voiceKeyword,
    this.entrySource = EntrySource.manual,
  });

  final String bookId;
  final int? initialAmount;
  final Category? initialCategory;
  final Category? initialParentCategory;
  final DateTime? initialDate;
  final String? initialMerchant;
  final int? initialSatisfaction;
  final String? voiceKeyword;
  final EntrySource entrySource;

  @override
  ConsumerState<ManualOneStepScreen> createState() =>
      _ManualOneStepScreenState();
}

class _ManualOneStepScreenState extends ConsumerState<ManualOneStepScreen> {
  final _formKey = GlobalKey<TransactionDetailsFormState>();
  late final FocusNode _merchantFocus;
  late final FocusNode _noteFocus;

  String _amount = '';
  bool _amountFocused = true; // D-10 default
  bool _isTextFieldFocused = false;
  bool _isSubmitting = false;

  bool get _showSmartKeypad => _amountFocused && !_isTextFieldFocused;

  @override
  void initState() {
    super.initState();
    _merchantFocus = FocusNode()..addListener(_handleFocusChange);
    _noteFocus = FocusNode()..addListener(_handleFocusChange);
    if (widget.initialAmount != null) {
      _amount = widget.initialAmount.toString();
    }
  }

  void _handleFocusChange() {
    final hasTextFocus = _merchantFocus.hasFocus || _noteFocus.hasFocus;
    if (hasTextFocus == _isTextFieldFocused) return;
    setState(() {
      _isTextFieldFocused = hasTextFocus;
      if (hasTextFocus) _amountFocused = false;
    });
  }

  @override
  void dispose() {
    _merchantFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _onAmountTap() {
    FocusManager.instance.primaryFocus?.unfocus(); // D-10
    setState(() => _amountFocused = true);
  }

  void _onDigit(String digit) {
    // Port digit-input handlers verbatim from transaction_entry_screen.dart:84-129
    setState(() => _amount += digit);
    final parsed = int.tryParse(_amount) ?? 0;
    _formKey.currentState?.updateAmount(parsed); // D-14
  }

  Future<void> _save() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final result = await _formKey.currentState!.submit();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) => Navigator.of(context).popUntil((r) => r.isFirst),
      validationError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
      persistError: (msg) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg))),
    );
  }

  double _computeSmartKeypadHeight(BuildContext context) {
    // §Pitfall 1 — clamp to 48dp floor.
    final mq = MediaQuery.of(context);
    final total = mq.size.height * 0.40;
    final rowGaps = 4 * 12.0; // 4 inter-row gaps
    final safeAreaBottom = mq.padding.bottom;
    final perKey = (total - rowGaps - safeAreaBottom) / 5;
    final clampedPerKey = math.max(48.0, perKey);
    return clampedPerKey * 5 + rowGaps + safeAreaBottom;
  }

  @override
  Widget build(BuildContext context) {
    final smartKeypadHeight = _computeSmartKeypadHeight(context);
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final scrollPaddingBottom = math.max(viewInsetsBottom, smartKeypadHeight);

    return Scaffold(
      resizeToAvoidBottomInset: false, // D-13
      body: Stack(
        children: [
          Column(
            children: [
              // AppBar, EntryModeSwitcher, AmountDisplay(onTap: _onAmountTap),
              // Expanded scrollable holding TransactionDetailsForm with
              //   bottom padding = scrollPaddingBottom,
              // AnimatedSlide wrapping SmartKeyboard.
              // — omitted for brevity; reuse patterns from existing screens.
            ],
          ),
          if (_isTextFieldFocused)
            Positioned(
              left: 0,
              right: 0,
              bottom: viewInsetsBottom,
              child: KeyboardToolbar(
                onDone: () =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onSave: _save,
                isSubmitting: _isSubmitting,
              ),
            ),
        ],
      ),
    );
  }
}
```

### Example 2: TransactionDetailsForm.updateAmount (D-14 — externalize amount)
```dart
// File edit: lib/features/accounting/presentation/widgets/transaction_details_form.dart
//
// REMOVE: _editAmount() method (lines 182-286).
// REMOVE: DetailInfoRow with onTap: _editAmount at lines 631-640.
// ADD: public method on TransactionDetailsFormState:

/// Host-pushed amount update — Phase 19 D-14.
///
/// Hosts that own the amount-editing UX (ManualOneStepScreen's persistent
/// SmartKeyboard, TransactionEditScreen / OcrReviewScreen's modal bottom
/// sheet) call this whenever the user mutates the amount. The form widget
/// keeps the value internally for save-time validation in [submit].
void updateAmount(int amount) {
  if (!mounted) return;
  if (amount == _amount) return; // skip redundant setState
  setState(() => _amount = amount);
}
```

### Example 3: KeyboardToolbar widget (handwritten, ~50 lines per D-12)
```dart
// Source: composed from CONTEXT.md D-11, D-12, D-21 + UI-SPEC Color/Typography tokens.
// File: lib/features/accounting/presentation/widgets/keyboard_toolbar.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

class KeyboardToolbar extends StatelessWidget {
  const KeyboardToolbar({
    super.key,
    required this.onDone,
    required this.onSave,
    required this.isSubmitting,
  });

  final VoidCallback onDone;
  final VoidCallback onSave;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColorsDark.card : AppColors.card,
      elevation: 8,
      child: Container(
        height: 44, // D-11 / UI-SPEC keyboardToolbar.height
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColorsDark.borderDefault
                  : AppColors.borderDefault,
            ),
          ),
        ),
        child: Row(
          children: [
            // Left: Done (text button)
            Expanded(
              child: InkWell(
                onTap: onDone,
                child: Center(
                  child: Text(
                    l10n.keyboardToolbarDone, // NEW ARB key (D-22)
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColorsDark.textSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // Right: Record (small coral gradient)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.actionGradientStart,
                        AppColors.actionGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isSubmitting ? null : onSave,
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Text(
                          l10n.record,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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
```

### Example 4: SmartKeyboard responsive height + Save label (refactor sketch)
```dart
// File edit: lib/features/accounting/presentation/widgets/smart_keyboard.dart
//
// CHANGES:
// 1. Rename `nextLabel` parameter → `actionLabel` (and document its purpose).
// 2. Default value: 'Save' (or REQUIRED — no default — to force callers to provide ARB key).
// 3. Wrap the build() in LayoutBuilder; compute per-key height with clamp.
// 4. Remove hardcoded `height: 50` literals at lines 145, 260, 329 (action row, currency, gradient).
// 5. Remove hardcoded `height: 48` literal at line 198 (_DigitKey).
// 6. Both row spacing (line 57, 59, 61, 63) and column spacing (line 78, 99, 109, 118, 139, 156, 168)
//    change: row 8→12 (D-07), column 4→6 (D-07).

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return LayoutBuilder(
    builder: (context, constraints) {
      final mq = MediaQuery.of(context);
      final available = mq.size.height * 0.40 - mq.padding.bottom - (4 * 12.0);
      final rawKeyHeight = available / 5;
      final keyHeight = math.max(48.0, rawKeyHeight); // §Pitfall 1

      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColorsDark.card : AppColors.card,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? AppColorsDark.borderDefault
                  : AppColors.borderDefault,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + mq.padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DigitRow(keys: const ['1', '2', '3'], height: keyHeight,
                onTap: onDigit, isDark: isDark),
            const SizedBox(height: 12), // D-07
            _DigitRow(keys: const ['4', '5', '6'], height: keyHeight,
                onTap: onDigit, isDark: isDark),
            const SizedBox(height: 12),
            _DigitRow(keys: const ['7', '8', '9'], height: keyHeight,
                onTap: onDigit, isDark: isDark),
            const SizedBox(height: 12),
            _ExtraRow(height: keyHeight, onDigit: onDigit, onDoubleZero: onDoubleZero,
                onDot: onDot, isDark: isDark),
            const SizedBox(height: 12),
            _ActionRow(height: keyHeight, onDelete: onDelete, onSave: onNext,
                actionLabel: actionLabel, /* ... */),
          ],
        ),
      );
    },
  );
}
```

### Example 5: Voice repoint (D-16, one-line change)
```dart
// File edit: lib/features/accounting/presentation/screens/voice_input_screen.dart
// Line 352-353 change ONLY the builder target; all push params unchanged.

// BEFORE:
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TransactionConfirmScreen(
      bookId: widget.bookId,
      amount: result.amount ?? 0,
      // ...
    ),
  ),
);

// AFTER:
await Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ManualOneStepScreen(
      bookId: widget.bookId,
      initialAmount: result.amount ?? 0,
      // Note constructor params for ManualOneStepScreen use "initial" prefix
      // (per ManualOneStepScreen example skeleton above).
      // ...
    ),
  ),
);
```

### Example 6: Golden test wrapper (mirror existing pattern)
```dart
// File: test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart
// (Note: matches D-09 location; alternatively test/golden/ — planner picks based on
//  whether project prefers grouping goldens by feature or by test type.)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/smart_keyboard.dart';
import 'package:home_pocket/generated/app_localizations.dart';

Widget _wrap({
  required Locale locale,
  required ThemeMode themeMode,
  required Widget child,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: 390, child: child),
      ),
    ),
  );
}

void main() {
  for (final locale in const [Locale('ja'), Locale('zh'), Locale('en')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'SmartKeyboard — ${locale.languageCode} / ${mode.name}',
        (tester) async {
          tester.binding.setSurfaceSize(const Size(390, 844));
          await tester.pumpWidget(_wrap(
            locale: locale,
            themeMode: mode,
            child: SmartKeyboard(
              onDigit: (_) {},
              onDelete: () {},
              onNext: () {},
              onDoubleZero: () {},
              onDot: () {},
              actionLabel: 'Record', // would normally read from S in app
            ),
          ));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(SmartKeyboard),
            matchesGoldenFile(
              'goldens/smart_keyboard_${locale.languageCode}_${mode.name}.png',
            ),
          );
        },
      );
    }
  }
}
```

[CITED: `test/golden/amount_display_golden_test.dart`, `test/golden/soul_vs_survival_card_golden_test.dart` — both use the same `_wrap` pattern]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed-height numeric keypad (48-50dp per key) | Responsive height with platform-min floor clamp | Phase 19 (this phase) | Better thumb reach on large phones; preserved usability on small phones via `math.max(48, _)` clamp |
| Two-screen manual entry (Entry → Confirm) | Single-screen entry with persistent keypad + soft-keyboard coexistence | Phase 19 (this phase) | Faster entry path; consolidates 3 hosts into 1 form widget (Phase 18 foundation, Phase 19 collapse) |
| Form widget owns amount editing (Phase 18 D-01) | Host owns amount editing (Phase 19 D-14) | Phase 19 (this phase) | Each host picks its UX (persistent keypad vs modal sheet); form widget stays pure |
| `nextLabel: 'Next'` parameter on SmartKeyboard (literal default) | `actionLabel: l10n.record` (no literal default; ARB-driven) | Phase 19 (this phase) | SC-1 compliance — no "Next" string in manual flow |

**Deprecated/outdated (effective after Phase 19 lands):**
- `TransactionEntryScreen` — replaced by `ManualOneStepScreen` (D-15 delete).
- `TransactionConfirmScreen` — replaced by `ManualOneStepScreen` (D-17 delete) for manual; voice flow repointed (D-16).
- `TransactionDetailsForm._editAmount()` — externalized to host screens via new `AmountEditBottomSheet` (Pitfall §3 recommendation) or per-host sheet code.
- `SmartKeyboard.nextLabel` parameter naming — recommend rename to `actionLabel` (Pitfall §6).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | iPhone SE safe-area bottom is ~34pt | §Pitfall 1 math | If actual safe-area is larger, per-key height drops further (worse for floor compliance — clamp still saves it). Smaller safe-area means slightly more headroom (no harm). [ASSUMED — based on standard iPhone SE 2nd-gen 4.7" home-button device] |
| A2 | `AnimatedSlide` does NOT change reported widget size — only render-time transform | §Pitfall 2 mitigation | If wrong, the `max(viewInsets.bottom, smartKeypadAnimatedHeight)` oscillates and jitter is unavoidable without RenderBox observation. [ASSUMED — based on Flutter slide animation idiom; verify via test before locking pattern] |
| A3 | `FocusScope.onFocusChange` fires for non-TextField focus changes | §Pattern 3 rationale | If wrong, the per-FocusNode pattern is overkill but harmless. [ASSUMED — based on Material widget docs; verify if planner wants to use FocusScope] |
| A4 | iOS-only voice push site uses `Navigator.push` — no GoRouter/auto_route | §Example 5 | If GoRouter is in use, the repoint needs to update a route definition instead of a builder. [VERIFIED: no `go_router` in pubspec.yaml; `Navigator.push` direct usage in `voice_input_screen.dart:351`] |
| A5 | Phase 18 `TransactionDetailsFormConfig.$new` Freezed class can absorb new optional FocusNode params without breaking existing call sites | §Pattern 3 Option 1 | Freezed sealed unions don't tolerate adding fields to one variant gracefully — every `.when()` callsite must be updated. [ASSUMED — but only ~3 callsites exist: `transaction_edit_screen.dart`, `ocr_review_screen.dart`, the new `manual_one_step_screen.dart` itself; all in scope of Phase 19 edits anyway. Verify by inspecting compile errors after the regen.] |
| A6 | Existing project goldens work on CI without custom font setup | §Pitfall 7 | If wrong, Phase 19's 6 new goldens need bundled font workaround. [VERIFIED via inspection — 4 existing golden test files; project must have working CI golden setup or those tests would be failing] |

## Open Questions

1. **Should `AmountEditBottomSheet` be a new shared widget OR should each host duplicate the sheet code?**
   - What we know: D-14 says ManualOneStepScreen uses persistent keypad; TransactionEditScreen and OcrReviewScreen use tap-to-sheet. The current sheet code lives in `TransactionDetailsForm._editAmount` (lines 182-286).
   - What's unclear: Whether the planner has discretion to extract a new shared widget or must duplicate the sheet code per-host.
   - Recommendation: Extract into `AmountEditBottomSheet` widget. Aligns with CLAUDE.md "many small files" and DRYs the SmartKeyboard sheet between two hosts. Costs one new file; saves duplicated logic.

2. **How are `merchant` and `note` FocusNodes plumbed into `TransactionDetailsForm`?**
   - What we know: The TextFields are inside the form widget today; the host (ManualOneStepScreen) needs to observe their focus for `_isTextFieldFocused`.
   - What's unclear: Whether `TransactionDetailsFormConfig.$new` should accept optional `merchantFocusNode` / `noteFocusNode`, or whether the form widget should expose a `Stream<bool>` / `ValueListenable<bool>` for "any TextField focused."
   - Recommendation: Option A — add optional FocusNode params to the `.$new` config. Simpler than a stream; testable; existing Phase 18 hosts pass `null` and behavior is unchanged for them.

3. **Should the planner extract `_initializeDefaultCategory()` into a shared helper or port verbatim?**
   - What we know: D-24 says "port verbatim from TransactionEntryScreen:52-82 ... Planner may extract into a shared helper if it materially simplifies, but otherwise verbatim is fine."
   - What's unclear: How many other screens default categories this way (likely just one — `transaction_entry_screen.dart` itself, which gets deleted).
   - Recommendation: Port verbatim into ManualOneStepScreen. No reuse opportunity if the only caller is deleted. Future phases that need this logic (Phase 22 voice one-step?) can extract then.

4. **Does CI run goldens automatically, or are they a manual gate?**
   - What we know: 4 existing golden test files exist in `test/golden/`. There's no obvious `--update-goldens` skip in CI based on `.planning/STATE.md` accumulated debt (which mentions "28 golden diffs pending human re-baseline" for quick task 260522-fj5 → suggests goldens DO run on CI and DO fail PRs).
   - What's unclear: Whether the planner should expect the first PR to fail on font rendering or whether the project's CI environment matches local Mac rendering.
   - Recommendation: Plan to run `flutter test --update-goldens test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` locally, commit baselines, push, observe CI. If CI fails, regenerate on CI runner and commit. Manual UAT per SC-3 also required (human approves the visual).

5. **Where do the new tests go — `test/widget/features/accounting/presentation/widgets/` (per D-09 spec) or `test/golden/` (existing project convention)?**
   - What we know: D-09 explicitly specifies `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart`. But all 4 existing project goldens live in `test/golden/` (flat directory).
   - What's unclear: D-09's location is locked, but the project's convention is different.
   - Recommendation: Honor D-09 — it's an explicit locked decision. Note the inconsistency with the project's `test/golden/` convention as a future tidy-up.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Build, test, gen-l10n, build_runner | ✓ | ^3.10.8 (from pubspec env) | — |
| `flutter_test` | All Phase 19 widget/unit tests | ✓ | SDK | — |
| `mocktail` | Mock repositories in `manual_one_step_screen_test.dart` and `voice_to_manual_one_step_screen_test.dart` | ✓ | ^1.0.4 | — |
| `build_runner` | Freezed regen if FocusNode params added to config (per Pattern 3 Option 1) | ✓ | ^2.4.14 | — |
| Font files (`Outfit`, `DM Sans`) | Golden tests rendering | ✓ | declared in pubspec `fonts:` per UI-SPEC | — |
| Xcode (iOS build) | iOS device/simulator UAT for SC-2 (touch target on real iPhone SE / 14 / Pro Max) | (developer machine) | depends on dev machine | Use multiple test surface sizes in widget tests if no physical device available |
| Drift / SQLCipher | DAO integration test for SC-4 (entry_source == 'manual') | ✓ | `drift ^2.25.0` + `sqlcipher_flutter_libs ^0.6.7` | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

All Phase 19 work is doable on the existing local + CI environment with no new tooling.

## Validation Architecture

> Phase 19 has nyquist_validation enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) |
| Config file | none — Flutter convention (`test/` dir auto-discovered) |
| Quick run command | `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` |
| Full suite command | `flutter test` |
| Golden update command | `flutter test --update-goldens test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` |
| Code-gen command | `flutter pub run build_runner build --delete-conflicting-outputs` |
| ARB regen command | `flutter gen-l10n` |
| Analyzer | `flutter analyze` (must be 0 issues per CLAUDE.md) |

### Phase Requirements → Test Map

| Req ID | SC | Behavior | Test Type | Automated Command | File Exists? |
|--------|----|----------|-----------|-------------------|-------------|
| INPUT-01 | SC-1 | No "下一步" / "Next" button in manual flow; all six field surfaces visible | widget | `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` (specific test: `SC-1 — no Next button, all six fields render`) | ❌ Wave 0 (NEW test file) |
| INPUT-01 | SC-1 | Save flow renders inline without intermediate route push | widget | same file, test: `tap save → no Navigator.push to confirm screen` | ❌ Wave 0 |
| KEYPAD-01 | SC-2 | Every SmartKeyboard digit/action/save key rendered height ≥ 48dp on iPhone SE viewport | widget | same file, test: `each key height ≥ 48 at Size(375, 667)` AND at `Size(390, 844)` AND at `Size(428, 926)` | ❌ Wave 0 |
| KEYPAD-01 | SC-3 | Adjacent keypad keys visually discriminable across {ja,zh,en} × {light,dark} = 6 baselines | golden | `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` | ❌ Wave 0 (NEW test file) |
| INPUT-01 | SC-4 | Saved manual entry produces Transaction with `entry_source = 'manual'` | widget (mock repo) | `manual_one_step_screen_test.dart` test: `save → CreateTransactionParams.entrySource == EntrySource.manual` | ❌ Wave 0 |
| INPUT-01 | SC-4 (DAO) | DAO-level: `entry_source` round-trips as 'manual' on insert | integration | re-run existing `test/integration/.../transaction_dao_entry_source_test.dart` (Phase 17) — should still pass; no new test required if existing tests cover the manual literal | ✅ (existing from Phase 17) |
| KEYPAD-01 / INPUT-01 | SC-5 | All Phase 19 UI strings via `S.of(context)`; ARB parity across ja/zh/en; `flutter gen-l10n` clean | architecture | re-run existing `test/architecture/arb_key_parity_test.dart` after adding `keyboardToolbarDone` | ✅ (existing) |
| KEYPAD-01 / INPUT-01 | SC-5 | `flutter analyze` 0 issues | static | `flutter analyze` | ✅ (existing CI) |
| INPUT-01 (D-16) | regression | Voice push to ManualOneStepScreen pre-fills amount/category/merchant/satisfaction/voiceKeyword | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` | ❌ Wave 0 (NEW test file) |
| INPUT-01 (D-16) | regression | Voice save produces Transaction with `entry_source = 'voice'` | widget (mock repo) | same file, test: `voice save → entrySource == EntrySource.voice` | ❌ Wave 0 |
| INPUT-01 (D-16) | regression | Voice category correction (`recordCategoryCorrectionUseCaseProvider`) fires when user changes category in ManualOneStepScreen with `voiceKeyword` set | widget | re-target existing `transaction_confirm_screen_merchant_learning_test.dart` to use ManualOneStepScreen host | ✅ (existing test; needs RE-TARGET) |
| Focus state machine | screen interaction | tap merchant TextField → `AnimatedSlide.offset.dy == 1.0` (keypad off-screen); tap AmountDisplay → `offset.dy == 0` (keypad back); tap toolbar "Done" → soft keyboard dismisses, keypad returns; tap toolbar "Save" → submit handler runs | widget | `manual_one_step_screen_test.dart` test: `focus state machine` | ❌ Wave 0 |
| KEYPAD-01 (resp. height) | regression | `smart_keyboard_test.dart` extends with: `MediaQuery(size: Size(375, 667))` → per-key ≥ 48dp (Pitfall §1) | widget | `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` | ⚠️ EXTEND (verify if exists; create if not) |

### Sampling Rate

- **Per task commit:** `flutter test test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` (the two screen+keypad widget tests, ~15s).
- **Per wave merge:** `flutter test` (full suite + goldens, ~3-5 min).
- **Phase gate:** Full suite green + `flutter analyze` 0 issues + `flutter gen-l10n` clean + `flutter pub run build_runner build --delete-conflicting-outputs` produces zero git diff + manual UAT on iPhone SE simulator (SC-3 baseline approval, SC-2 thumb-reach feel).

### Wave 0 Gaps

- [ ] `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` — NEW. Covers SC-1 (no Next button + 6 fields), SC-2 (per-key ≥ 48dp on 3 viewport sizes), SC-4 (`entry_source == manual` via mock repo), focus state machine (AnimatedSlide offset transitions, KeyboardToolbar visibility, Done/Save handlers).
- [ ] `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` — NEW. Covers D-16 regression: voice push pre-fills + voice save produces `entry_source == voice`.
- [ ] `test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` — NEW. Covers SC-3: 6 golden images {ja, zh, en} × {light, dark}.
- [ ] `test/widget/features/accounting/presentation/widgets/smart_keyboard_test.dart` — EXTEND (or create if doesn't exist). Covers per-key height computation at multiple viewport sizes.
- [ ] `test/widget/features/accounting/presentation/widgets/keyboard_toolbar_test.dart` — NEW (recommended, not strictly required by SCs). Covers KeyboardToolbar visibility gating on `viewInsets.bottom > 0`, Done/Save button taps fire correct callbacks.
- [ ] Re-target `test/widget/features/accounting/presentation/screens/transaction_confirm_screen_merchant_learning_test.dart` to use ManualOneStepScreen host (D-16 voice correction regression).
- [ ] Delete `test/widget/features/accounting/presentation/screens/transaction_entry_screen_test.dart`.
- [ ] Delete `test/unit/features/accounting/presentation/screens/transaction_{entry,confirm}_screen_characterization_test.dart`.
- [ ] Framework install: none required — `flutter_test` + `mocktail` already in dev_dependencies.

### Manual UAT (required for SC-3 baseline approval)

SC-3 golden tests provide the **regression net** but a human must approve the initial baseline images. Steps:
1. Run `flutter test --update-goldens test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` locally.
2. Visually inspect the 6 generated PNGs in `test/widget/features/accounting/presentation/widgets/goldens/` — confirm:
   - Digit keys clearly distinguishable from adjacent keys (D-07 6dp/12dp gap is visible).
   - Save button (coral gradient) is visually dominant (the primary CTA per UI-SPEC).
   - Backspace key (⌫) matches digit-key fill (D-08 peer relationship).
   - Locale-specific glyphs render correctly (e.g., the `record` button text in ja/zh/en).
3. Commit baselines, push, observe CI pass.

SC-2 manual verification: pump on actual iPhone SE simulator + iPhone 14 simulator + iPhone 14 Pro Max simulator; tap each digit with thumb (use Simulator → Device → Touch Cursor); confirm no missed taps. Widget test does the rendered-height assertion but cannot validate actual thumb hit rate.

## Security Domain

> `security_enforcement` not explicitly set in `.planning/config.json` — treat as enabled. Domain analysis below.

Phase 19 is a UI-polish + flow-consolidation phase. It does NOT:
- Add new persistence (no Drift schema changes).
- Add new network endpoints.
- Add new authentication/authorization surfaces.
- Add new cryptographic operations.
- Touch hash chain / SQLCipher / key management.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — no auth surface in Phase 19 |
| V3 Session Management | no | n/a — no session state |
| V4 Access Control | no | n/a — no permission changes |
| V5 Input Validation | yes (light) | Existing `submit()` validation (`amount > 0`, `category != null`) is preserved verbatim from Phase 18's form widget; merchant + note are free-text TextFields with existing length/sanitization (no new fields added) |
| V6 Cryptography | no | Hash chain frozen on edit (Phase 18 D-08) is unchanged; `CreateTransactionUseCase` invocation path is unchanged |

### Known Threat Patterns for Flutter mobile UI stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sensitive data in screenshot (e.g., golden test PNG might capture real amounts) | Information Disclosure | Goldens pump synthetic `Size(390, 844)` widget in isolation with NO real Transaction data — only the keypad widget is captured. Verified: SmartKeyboard has no PII surface. |
| Tap injection via accessibility / a11y framework | Tampering | Existing Flutter Material widgets handle this; KeyboardToolbar uses standard `InkWell` |
| Locale-injection in ARB strings | Tampering | Existing `S.delegate` validates ARB at codegen time; new `keyboardToolbarDone` strings are static |
| TextField input → SQL injection via merchant/note | Tampering | Existing `TransactionDao` uses Drift compile-time-checked queries (parameterized); no new fields |

**No security review required for Phase 19 beyond the standard `flutter analyze` + existing CI gates.** No new cryptographic surface, no new persistence, no new attack surface.

## Sources

### Primary (HIGH confidence — codebase / official docs)
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` (full read) — port pattern for digit handlers + `_initializeDefaultCategory`
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` (full read) — submit() pattern + save handler reference
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart` (full read) — D-14 refactor target; `_editAmount` location confirmed
- `lib/features/accounting/presentation/widgets/smart_keyboard.dart` (full read) — refactor target; height literals at lines 145, 198, 260, 329; spacing literals at lines 78, 99, 109, 118, 139, 156, 168
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:340-368` — line 352 push site confirmed
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` (full read) — Phase 18 spillover host
- `lib/features/accounting/presentation/screens/ocr_review_screen.dart` (full read) — Phase 18 spillover host
- `lib/features/accounting/presentation/navigation/entry_mode_navigation_config.dart` (full read) — manual route registration at line 24
- `lib/features/home/presentation/screens/main_shell_screen.dart:115-140` — main shell + button push site at line 128
- `lib/l10n/app_{ja,zh,en}.arb` grep for `done`, `record`, `save`, `next`, `keyboardToolbarDone`, `addTransaction`, `amountMustBeGreaterThanZero`, `pleaseSelectCategory`, `expenseDetail` — confirmed `done` absent, `record` present, `next` present (but ARB key retained per UI-SPEC)
- `pubspec.yaml` (full read first 80 lines) — confirmed no `keyboard_actions`, no `alchemist`, no `golden_toolkit`; `mocktail: ^1.0.4` present
- `test/golden/amount_display_golden_test.dart` (full read) — `_wrap` pattern template for Phase 19 goldens
- `test/golden/soul_vs_survival_card_golden_test.dart:62-71` — ProviderScope + MaterialApp + locale + themeMode wrapper pattern
- `.planning/phases/19-manual-one-step-keypad-polish/19-CONTEXT.md` (full read) — 24 D-XX decisions
- `.planning/phases/19-manual-one-step-keypad-polish/19-UI-SPEC.md` (full read) — visual design contract
- `.planning/phases/18-shared-details-form-foundation/18-CONTEXT.md` (full read) — form widget contract
- `.planning/REQUIREMENTS.md` (full read) — KEYPAD-01, INPUT-01
- `.planning/ROADMAP.md` (full read) — 5 Success Criteria for Phase 19
- `.planning/STATE.md` (full read) — Phase 18 complete, ready for Phase 19
- `CLAUDE.md` — Riverpod 3 imports, dependency pins, Amount Display Style, i18n rules

### Secondary (MEDIUM confidence — verified against codebase or multiple sources)
- [Flutter Focus and text fields cookbook](https://docs.flutter.dev/cookbook/forms/focus) — FocusNode + addListener pattern
- [Flutter focus system docs](https://docs.flutter.dev/ui/interactivity/focus) — FocusScope vs FocusNode tradeoffs
- [Flutter resizeToAvoidBottomInset API](https://api.flutter.dev/flutter/material/Scaffold/resizeToAvoidBottomInset.html) — confirms manual `viewInsets.bottom` padding is the documented alternative

### Tertiary (LOW confidence — single source / WebSearch only)
- [flutter/flutter#89914](https://github.com/flutter/flutter/issues/89914) — `SystemUiMode.edgeToEdge bottom viewInset jumps when keyboard is opening` — confirms jitter risk class but exact reproduction varies by Flutter version
- [flutter/flutter#97609](https://github.com/flutter/flutter/issues/97609) — `SafeArea maintainBottomViewPadding not respected when keyboard viewInsets are animated` — related but not identical to Phase 19's setup
- [customized_keyboard pub package readme](https://pub.dev/packages/customized_keyboard) — referenced for "industry pattern" framing; NOT used as a dep per D-12

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — pubspec verified, no new deps, existing widget patterns inspected
- Architecture (responsibility map): HIGH — Phase 18 D-01 + Phase 19 D-14 explicitly carve responsibilities
- Pitfalls: HIGH (Pitfalls 1, 3, 4, 5, 6 — all reproducible from code/CONTEXT.md) / MEDIUM (Pitfalls 2, 7 — Flutter jitter behavior + golden CI behavior depend on Flutter version + CI setup, but pattern is documented)
- Validation: HIGH — every Success Criterion mapped to a specific automated assertion shape

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 (30 days; UI-spec frozen, Flutter SDK stable, no upstream dep changes anticipated)

---

## Project Constraints (from CLAUDE.md)

| Constraint | Phase 19 compliance |
|------------|----------------------|
| 5-layer Clean Architecture + Thin Feature rule | ✓ All Phase 19 files live in `lib/features/accounting/presentation/` (widgets + screens). Zero `application/`, `infrastructure/`, `data/tables/`, `data/daos/` adds. |
| Riverpod 3 import boundaries (no `legacy.dart` use for new code) | ✓ `ConsumerStatefulWidget` + `ref.read/watch` from `flutter_riverpod/flutter_riverpod.dart` only |
| Drift TableIndex syntax (TableIndex + `{#col}`) | n/a — no Drift changes |
| 4-Layer Encryption / crypto rules | n/a — no crypto changes |
| `intl: 0.20.2` pin | ✓ — no version bump |
| `sqlcipher_flutter_libs` (NOT `sqlite3_flutter_libs`) | ✓ — no Drift dep changes |
| iOS Podfile `-l"sqlite3"` strip + EXCLUDED_ARCHS | ✓ — no Podfile changes |
| `file_picker 11.0.2` / `package_info_plus 9.0.1` / `share_plus 12.0.2` trio | ✓ — no pubspec changes |
| `AppTextStyles.amountLarge/Medium/Small` for monetary values (tabular figures) | ✓ — `AmountDisplay` uses `amountLarge`; SmartKeyboard digit glyphs use `amountLarge.copyWith(fontSize: 20)` (already in current code); UI-SPEC mandates tabular figures on keypad |
| Widget Parameter Pattern (nullable + provider fallback) | ✓ — `ManualOneStepScreen` constructor uses nullable initial params with defaults seeded in `initState` (D-24 pattern) |
| i18n: All UI text via `S.of(context)`; ARB parity ja/zh/en; `flutter gen-l10n` clean | ✓ — adds 1 new ARB key in all 3 locales (`keyboardToolbarDone`) per D-22; `record` reused for save buttons |
| Code-gen rules (run `build_runner` after `@freezed` / `@riverpod` changes) | ✓ — only if planner picks Pattern 3 Option 1 (add FocusNode fields to `TransactionDetailsFormConfig.$new`), which is a Freezed regen |
| Zero analyzer warnings before commit | ✓ — `flutter analyze` 0 issues enforced at phase gate |
| File size targets (<800 lines, aim 400-600) | ✓ — `ManualOneStepScreen` estimated 400-500 lines; `KeyboardToolbar` ~50 lines; `AmountEditBottomSheet` (recommended) ~120 lines; SmartKeyboard refactor stays under existing 345-line footprint |
| Tests: ≥70% per-file coverage, TDD workflow | ✓ — 4 new test files + 2 file modifications; coverage achievable |
| ADR-012 (no gamification) / ADR-014 (soul unipolar) / ADR-016 (HomeHero isolation) | ✓ — Phase 19 touches no HomeHero, no streaks/achievements, no satisfaction scale changes |
| Common Pitfall #4 (immutability via copyWith) | ✓ — no mutation; form widget uses `setState` with new values; Freezed classes use `copyWith` |
| `worklog.md` (close requires `doc/worklog/YYYYMMDD_HHMM_*.md`) | ✓ — planner must include worklog entry as last plan |

---

*Phase: 19 — Manual One-Step + Keypad Polish*
*Research completed: 2026-05-23 by gsd-researcher*
*Source-of-truth: CONTEXT.md (24 locked decisions) + UI-SPEC.md (approved visual contract) + REQUIREMENTS.md (KEYPAD-01, INPUT-01) + ROADMAP.md (5 SCs)*
