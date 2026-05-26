---
status: partial
phase: 19-manual-one-step-keypad-polish
source: [19-VERIFICATION.md]
started: 2026-05-23T08:30:00Z
updated: 2026-05-23T08:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Visual review of 6 SmartKeyboard golden baselines (already pre-approved during Plan 02)
expected: Open `test/widget/features/accounting/presentation/widgets/goldens/smart_keyboard_{ja,zh,en}_{light,dark}.png` and confirm — key separation visible (12dp row gap / 6dp column gap), Save button coral/salmon gradient distinct, dark-mode contrast clear, digit alignment good. CJK glyphs may render as placeholder boxes in headless screenshots (expected per RESEARCH §Pitfall 7, font-loading limitation).
result: [pending — pre-approved at checkpoint, awaiting final confirmation]

### 2. Physical iOS device keypad feel (KEYPAD-01 device-level UAT)
expected: Run `flutter run` on a real iPhone (SE or newer). Open ManualOneStepScreen via the "+" tile or fab. Confirm: (a) digit taps register reliably at thumb reach with no double-fires or misses, (b) keypad slides smoothly when merchant/note TextField gains focus, (c) KeyboardToolbar's Done button dismisses the soft keyboard back to the persistent SmartKeyboard, (d) Save button on the SmartKeyboard fires the persist path when amount > 0 + category picked, (e) dark mode keys remain visually discriminable.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
