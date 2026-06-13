---
phase: 42-entry-ui-display-voice
plan: 05
subsystem: accounting-entry
tags: [currency, decimal-input, keypad, i18n, golden]
requires:
  - "currencyFractionDigitsFor (plan 42-02) — ISO 4217 minor-unit source"
  - "amount_input_controller_test.dart (plan 42-01 RED scaffold)"
provides:
  - "AmountInputController — pure-Dart immutable decimal-input state machine (CURR-05)"
  - "SmartKeyboard dot-gating branch (disabled blank 48dp tile for 0-decimal currencies, D-06)"
affects:
  - "manual_one_step_screen / amount_edit_bottom_sheet host wiring (deferred to plan 42-08)"
tech-stack:
  added: []
  patterns:
    - "Immutable transitions via pure static helpers + thin mutable handle"
    - "Truncate-not-round as string substring cut (D-08)"
    - "Disabled-tile gating preserves layout (no key collapse)"
key-files:
  created:
    - "lib/features/accounting/presentation/widgets/amount_input_controller.dart"
    - "test/features/accounting/presentation/widgets/smart_keyboard_dot_gating_test.dart"
    - "test/features/accounting/presentation/widgets/goldens/smart_keyboard_dot_gated_jpy_light.png"
    - "test/features/accounting/presentation/widgets/goldens/smart_keyboard_dot_gated_jpy_dark.png"
    - "test/features/accounting/presentation/widgets/goldens/smart_keyboard_dot_enabled_usd_light.png"
    - "test/features/accounting/presentation/widgets/goldens/smart_keyboard_dot_enabled_usd_dark.png"
  modified:
    - "lib/features/accounting/presentation/widgets/smart_keyboard.dart"
decisions:
  - "Controller methods are void+mutate-handle (test contract) but recompute text via pure static helpers — no in-place mutation, honoring CLAUDE.md immutability."
  - "decimals stays host-supplied (no number_formatter import) to avoid coupling; single-source intent documented in the controller doc comment."
  - "Disabled dot tile uses backgroundMuted @ 40% alpha so it reads as a non-key gap, not a tappable key."
metrics:
  duration: "~10 min"
  completed: "2026-06-13"
---

# Phase 42 Plan 05: Currency-Aware Decimal Input + Dot-Gated Keyboard Summary

Host-owned `AmountInputController` state machine for per-currency decimal entry (D-07 cap, D-08 truncate-not-round), plus D-06 dot-key gating on `SmartKeyboard` that disables the dot cell for 0-decimal currencies without shifting any key — JPY path stays byte-identical (CURR-04).

## What Was Built

### Task 1 — `AmountInputController` (commit `649f4376`)
- Pure-Dart class holding `{text, decimals}`. Transitions (`onDigit`, `onDot`, `onDoubleZero`, `onDelete`, `onCurrencyChange`) recompute `text` via pure static helpers; no in-place mutation.
- **D-07 cap:** `onDigit` ignores a digit past the currency minor unit (`"50.5"` + `"0"` → `"50.50"`; further digit no-op).
- **D-06 dot gating:** `onDot` is a no-op when `decimals == 0` (string never gains a `.`).
- **D-08 truncate-not-round:** `onCurrencyChange(newDecimals)` cuts the fractional substring (`"50.50"`→`"50"`, `"0.99"`→`"0"`, `"50.567"`→`"50.56"`), strips a lone trailing `.`, never `.round()`.
- Turns the 42-01 RED `amount_input_controller_test.dart` GREEN (6/6).

### Task 2 — Dot-gated `SmartKeyboard` (commit `5354cc26`)
- `_buildExtraRow` branches on `onDot == null`: renders a new `_DisabledKey` blank tile (same equal width + 48dp floor) instead of collapsing the cell (RESEARCH Q3 — collapsing shifts keys → mis-taps + golden churn).
- `onDot != null` branch unchanged → existing `smart_keyboard_*` goldens untouched (verified `git status` clean on that goldens dir), satisfying CURR-04.
- New `smart_keyboard_dot_gating_test.dart`: widget asserts (no `.` glyph + disabled tile present when gated; `.` present & callback fires when enabled; ≥48dp floor on iPhone-SE worst case) + golden pair JPY-gated / USD-enabled, light + dark. Baselines generated on macOS.

## Verification

- `amount_input_controller_test` — 6/6 GREEN.
- `smart_keyboard_dot_gating_test` — 7/7 GREEN (3 widget + 4 golden).
- Regression: existing `smart_keyboard_test` + `entry_widgets_dark_mode_test` — all GREEN; existing keyboard goldens unchanged.
- `flutter analyze` on all touched files — 0 issues.

## Threat Mitigations (from plan threat_model)

| Threat ID | Disposition | How addressed |
|-----------|-------------|---------------|
| T-42-10 (over-precision amount) | mitigate | `onDigit` D-07 cap; test `caps fractional length at 2`. |
| T-42-11 (rounding bug +1 yen) | mitigate | D-08 string truncation; tests `0.99→0`, `50.5→50`, `50.50→50`. |
| T-42-12 (functional dot on 0-decimal currency) | mitigate | `onDot:null` → disabled blank tile; 48dp asserted. |
| T-42-SC (pub installs) | accept | No package install. |

## Deviations from Plan

### [Rule 3 — Blocking-issue resolution] Controller surface reconciled with RED test
- **Found during:** Task 1.
- **Issue:** Plan `<behavior>` describes "immutable transitions returning new instances", but the 42-01 RED test (the binding contract) calls `void` methods that mutate the handle (`c.onDigit('7'); expect(c.text, ...)`).
- **Resolution:** Kept the test's mutable-handle surface, but implemented every transition as a pure static helper returning a freshly-derived string that the handle reassigns — no in-place mutation, satisfying CLAUDE.md immutability without breaking the locked test API. Documented in the class doc comment.
- **Files:** `amount_input_controller.dart`.

### [Note — key_link interpretation]
- Plan `key_links` expects a `Decimals|FractionDigits` link from the controller to `number_formatter.dart`. The controller deliberately does **not** import `number_formatter`; `decimals` is host-supplied (the host sources it from `currencyFractionDigitsFor`, plan 42-02). The single-source relationship is documented in the controller doc comment rather than realized as a direct import, to keep the pure-logic class decoupled. Host wiring lands in 42-08.

## Notes for Downstream (plan 42-08)
- Host must instantiate `AmountInputController(decimals: currencyFractionDigitsFor(code))` and call `onCurrencyChange(...)` when the currency key is tapped.
- Host must pass `onDot: decimals > 0 ? _onDot : null` to `SmartKeyboard` so the gating branch activates per-currency. Currency-KEY tap wiring is 42-08's responsibility (out of scope here).

## Self-Check: PASSED
All created files exist on disk; both task commits (`649f4376`, `5354cc26`) present in git history.
