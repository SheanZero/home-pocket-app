---
phase: 22
slug: voice-one-step-integration-record-button-ux
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-25
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Sourced from `22-RESEARCH.md` §Validation Architecture (lines 996-1037).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter 3.44.0) + `mocktail ^1.x` (existing project dep) |
| **Config file** | `pubspec.yaml` (`dev_dependencies`) + `analysis_options.yaml` |
| **Quick run command** | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | quick ~10 s · full ~60 s |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` (quick, < 10 s)
- **After every plan wave:** Run `flutter test` (full suite, ~60 s)
- **Before `/gsd:verify-work`:** Full suite green + `flutter analyze` 0 issues + `flutter gen-l10n` clean
- **Max feedback latency:** 10 seconds (quick) · 60 seconds (wave gate)

---

## Per-Task Verification Map

> Plan IDs are TBD until the planner emits them; rows are anchored on requirement + behavior. Planner MUST cross-link each task to one of the rows below in `<acceptance_criteria>` or `<automated>`.

| Behavior | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|----------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Voice transcript fills form fields in-place; user can edit before saving (SC-1) | 1 | INPUT-02 | — | N/A | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -p "INPUT-02"` | ✅ Extend | ⬜ pending |
| Save path stamps `entry_source = 'voice'` (SC-2) | 2 | INPUT-02 | — | N/A | integration | `flutter test test/integration/features/accounting/voice_save_entry_source_test.dart` | ❌ NEW (W0) | ⬜ pending |
| Idle caption = `l10n.holdToRecord`; recording caption = `l10n.recording` (SC-3 caption) | 1 | REC-01 | — | N/A | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart -p "REC-01"` | ✅ Extend | ⬜ pending |
| Hold < 300 ms → no parse, no fill, `speechService.cancel()` called (SC-3 misfire) | 1 | REC-01 | — | Discard partial transcript on misfire (no parser invocation on noise) | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "misfire"` | ✅ Extend | ⬜ pending |
| Idle golden + recording-state `BoxDecoration` introspection (borderRadius ≈ 16 vs ≈ 36, red gradient) (SC-4 visual) | 2 | REC-02 | — | N/A | golden + widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` | ❌ NEW (W0) | ⬜ pending |
| `Stopwatch` around `setState → pump` < 100 ms (SC-4 timing) | 2 | REC-02 | — | N/A | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "100ms"` | ✅ Extend | ⬜ pending |
| Pre-filled amount=100; voice fills 5000 → form amount=5000 (D-08 overwrite) | 1 | INPUT-02 | — | N/A | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "D-08"` | ✅ Extend | ⬜ pending |
| Long-press start → tap merchant TextField → recording stops, no batch fill (D-09 focus interrupts) | 1 | INPUT-02 | — | N/A | widget | `flutter test test/widget/.../voice_input_screen_test.dart -p "D-09"` | ✅ Extend | ⬜ pending |
| `updateCategory` / `updateMerchant` / `updateNote` / `updateSatisfaction` mutate `TransactionDetailsFormState` correctly (D-07 + RESEARCH Open Q2 / B-1) | 0 | INPUT-02 | — | N/A | widget | `flutter test test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart -p "D-07"` | ✅ Extend | ⬜ pending |
| ARB parity: `holdToRecord` + `recording` × ja/zh/en exist; `tapToRecord` removed; `flutter gen-l10n` clean (SC-5) | 0 | REC-01, REC-02 | — | N/A | CLI + arch test | `flutter gen-l10n && flutter analyze` + `flutter test test/arch/arb_parity_test.dart` (if exists) | ✅ Existing | ⬜ pending |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` — NEW golden harness (idle-state only per D-12; recording state asserted via decoration introspection because mid-animation goldens flake)
- [ ] `test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden.png` — idle golden baseline (single locale × single theme; generated via `flutter test --update-goldens` on first run)
- [ ] `test/integration/features/accounting/voice_save_entry_source_test.dart` — NEW integration test for SC-2 (mirror `test/integration/features/accounting/manual_save_entry_source_test.dart:218-242` structure with `entrySource: EntrySource.voice`)
- [ ] `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` — extend with tests for the 4 new public methods (D-07 + Open Q2) `updateCategory`, `updateMerchant`, `updateNote`, `updateSatisfaction` before voice screen integration tests depend on them
- [ ] DELETE `test/widget/features/accounting/presentation/screens/voice_to_manual_one_step_screen_test.dart` (Phase 19 D-16 regression test) — the voice→manual push no longer exists; SC-2 integration test replaces its coverage
- [ ] Major rewrite of existing `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` — strip assertions on `VoiceRecognitionResultCard`/「認識結果」/「タップして録音」 and replace with hold-to-record + caption-swap + 100 ms + batch-fill + focus-interrupts assertions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Physical-touch → first frame perceived latency on real device | REC-02 (SC-4 timing) | Stopwatch test measures gesture-callback-to-build-completion ONLY; physical sensor latency (finger touch → Flutter gesture frame) is platform-dependent and outside the code's control. | On a release build of iOS (≥ iPhone 12) and Android (≥ Pixel 6), open `VoiceInputScreen`, touch and hold the mic button, observe that the button visibly enters the recording state within ~100 ms of finger contact. Repeat 5× per device; record any > 200 ms instances. |
| Real-world ja/zh recognizer end-to-end accuracy | INPUT-02 (SC-1) | Recognizer accuracy depends on device microphone + Apple/Google STT cloud quality; cannot be unit-tested with mocked services. | On a real device, open `VoiceInputScreen`, hold mic, say "1千8百4十元 星巴克" (zh) or「1840円 スターバックス」(ja), release, verify form fields auto-populate with amount=1840 and merchant set. Repeat for 3 utterances per locale. |
| Idle-state golden visual quality (anti-aliasing edges on 72 px container with borderRadius 36 vs true circle) | REC-02 (SC-4 visual) | Anti-aliasing rendering can differ subtly between `BoxShape.circle` and `borderRadius: 36` on a 72×72 box; visual review confirms acceptable parity. | Compare the new idle golden against a screenshot of today's pre-Phase-22 circle mic on the same device; confirm no perceptible aliasing degradation. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (golden harness + voice_save_entry_source_test + form widget D-07 extension including updateSatisfaction)
- [x] No watch-mode flags
- [x] Feedback latency < 10 s (quick) / < 60 s (wave gate)
- [x] `nyquist_compliant: true` set in frontmatter after planner cross-links every task

**Approval:** approved 2026-05-25
