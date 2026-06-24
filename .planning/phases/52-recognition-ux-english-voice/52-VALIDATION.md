---
phase: 52
slug: recognition-ux-english-voice
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-24
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart SDK) |
| **Config file** | `test/flutter_test_config.dart` (golden platform gate) |
| **Quick run command** | `flutter test test/<changed_area>/` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~120 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/<changed_area>/`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-01-01 | 01 | 1 | RECUX-01/02 | T-52-01 | VPR carries band/alternates/conflict; no raw transcript logged | unit | `flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart` | ❌ W0 (extend) | ⬜ pending |
| 52-01-02 | 01 | 1 | VEN-01 | T-52-02 | en residual lowercased only for en locale; zh/ja byte-unchanged | unit | `flutter analyze lib/application/voice/parse_voice_input_use_case.dart` | ✅ | ⬜ pending |
| 52-01-03 | 01 | 1 | RECUX-01/VEN-01 | T-52-01/02 | write==read holds for en (both lowercase) | unit | `flutter test test/unit/application/voice/parse_voice_input_use_case_test.dart` | ❌ W0 | ⬜ pending |
| 52-02-01 | 02 | 2 | RECUX-01 | T-52-04 | band pure-visual, a11y-only, no number/% (ADR-012) | widget | `flutter test test/widget/features/accounting/presentation/widgets/confidence_band_indicator_test.dart` | ❌ W0 | ⬜ pending |
| 52-02-02 | 02 | 2 | RECUX-02 | T-52-03 | ≤3 chips + exit chip; tap fires onSelect | widget | `flutter test test/widget/features/accounting/presentation/widgets/alternate_category_chips_test.dart` | ❌ W0 | ⬜ pending |
| 52-02-03 | 02 | 2 | RECUX-01/05 | T-52-03 | resolve-on-final render; clear-on-select; manual no-affordance; ARB parity | widget+arch | `flutter gen-l10n && flutter analyze lib/features/accounting/presentation/widgets/transaction_details_form.dart` | ⚠️ extend | ⬜ pending |
| 52-03-01 | 03 | 3 | RECUX-03 | T-52-05/06 | defer-to-save; write==read; null→no write; never merchant table | widget | `flutter analyze lib/features/accounting/presentation/widgets/transaction_details_form.dart` | ⚠️ partial | ⬜ pending |
| 52-03-02 | 03 | 3 | RECUX-03 | T-52-06 | chip+selector both count; null skip; merchant table never written | widget | `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_correction_test.dart` | ❌ W0 | ⬜ pending |
| 52-04-01 | 04 | 2 | VEN-01 (pitfall 5) | T-52-08 | every zh/ja L2 gets lowercase en seed; categoryId integrity | unit | `flutter test test/unit/shared/constants/default_synonyms_categoryid_test.dart test/unit/shared/constants/default_synonyms_speakable_coverage_test.dart` | ✅ (gate) | ⬜ pending |
| 52-04-02 | 04 | 2 | VEN-01 (pitfall 5) | T-52-09 | en/romaji/EN category+merchant+currency-word match | unit | `flutter test test/unit/application/voice/recognition/category_recognizer_test.dart test/unit/application/voice/recognition/merchant_recognizer_test.dart` | ⚠️ extend | ⬜ pending |
| 52-05-01 | 05 | 2 | VEN-02 (pitfall 7) | T-52-10 | bounded en number-word parser; X.50 idiom money-ctx; clamp | unit | `flutter test test/unit/application/voice/voice_text_parser_english_number_test.dart` | ❌ W0 | ⬜ pending |
| 52-05-02 | 05 | 2 | VEN-02 (pitfall 7) | T-52-11 | "fifty dollars"→50+USD; English NEVER enters CJK numeral path | unit | `flutter test test/unit/application/voice/voice_text_parser_isolation_test.dart` | ❌ W0 | ⬜ pending |
| 52-05-03 | 05 | 2 | VEN-02 (D-15) | T-52-11 | voice locale decoupled (en→en-US under ja UI); localeId e2e | unit | `flutter test test/unit/application/voice/voice_text_parser_isolation_test.dart` | ❌ W0 | ⬜ pending |
| 52-06-01 | 06 | 4 | RECUX-04 (pitfall 8) | T-52-13 | anti-toxicity sweep, COMPLETE banned list, ja/zh/en × states | widget | `flutter test test/widget/features/accounting/presentation/widgets/anti_toxicity_phase52_test.dart` | ❌ W0 | ⬜ pending |
| 52-06-02 | 06 | 4 | RECUX-05 (pitfall 9) | T-52-14 | ARB parity (equal counts/no orphans); merchant not in ARB; gen-l10n clean; macOS golden | arch | `flutter gen-l10n && flutter test test/architecture/arb_key_parity_test.dart` | ✅ extend | ⬜ pending |
| 52-06-03 | 06 | 4 | RECUX-04/05 | — | full-suite gate (analyze 0 + full test green) | full | `flutter analyze && flutter test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Populated by the planner from RESEARCH.md `## Validation Architecture` (pitfalls 5/7/8/9/10 → named regression tests/invariants).*

---

## Wave 0 Requirements

- [ ] `build_runner build --delete-conflicting-outputs` after the VPR Freezed field addition (52-01) — regenerate `voice_parse_result.freezed.dart` before any consumer compiles.
- [ ] `confidence_band_indicator_test.dart` + `alternate_category_chips_test.dart` (52-02) — band/chips render tests (after the UI-SPEC visual is implemented).
- [ ] `transaction_details_form_correction_test.dart` (52-03) — defer-to-save / chip-path / null-keyword / no-merchant-table.
- [ ] `voice_text_parser_english_number_test.dart` + `voice_text_parser_isolation_test.dart` (52-05) — en number-word + X.50 idiom + English-never-CJK isolation + voice-locale decoupling.
- [ ] `anti_toxicity_phase52_test.dart` (52-06) — new-UI sweep, COMPLETE banned list, ja/zh/en × all states.
- [ ] extend `category_recognizer_test.dart` / `merchant_recognizer_test.dart` with en cases (52-04); extend `parse_voice_input_use_case_test.dart` (52-01); extend `arb_key_parity_test.dart` (52-06, or confirm auto-cover).

*Existing infrastructure (arb_key_parity, default_synonyms coverage tests, flutter_test_config golden gate, anti_toxicity phase47 pattern) covers the gate scaffolding; the above are net-new test files/extensions.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| On-device band/chips visual fidelity (intensity, daily/joy color, layout) against the approved UI-SPEC | RECUX-01/02 | Pixel/interaction fidelity on a real device is not pixel-asserted by widget tests (goldens cover layout, not subjective design feel) | Run a voice entry on device; confirm band intensity + chip layout match 52-UI-SPEC; confirm band clears on selection |
| On-device en-US STT amount/category recognition (live STT) | VEN-01/02 | Live en-US STT is device-dependent; tests drive the parser directly, not the live recognizer | On an en-US device, speak "fifty dollars" / "coffee" and confirm amount+category fill correctly |
| Screen-reader announcement of the a11y band Semantics label | RECUX-01 | TalkBack/VoiceOver announcement is a real-device a11y check (carried-over class from v1.5 a11y UAT) | Enable a screen reader; focus the band; confirm the suggested-category label is announced in the active app locale |

*Parser-level VEN behavior IS automated (unit tests against the parser); only LIVE STT + subjective visual/a11y fidelity are manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
