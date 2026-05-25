---
phase: 23
slug: v1-3-cleanup-scanner-allow-lists-voice-flow-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (flutter_test 0.0.0 from SDK) |
| **Config file** | `analysis_options.yaml`, `pubspec.yaml` |
| **Quick run command** | `flutter test --reporter compact <path>` (targeted file) |
| **Full suite command** | `flutter test` |
| **Coverage command** | `flutter test --coverage` (≥80% gate per CLAUDE.md) |
| **Static analysis** | `flutter analyze` (MUST be 0 issues) |
| **Estimated runtime** | ~120 seconds full suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test file>` (1–10 s feedback)
- **After every plan wave:** Run `flutter analyze && flutter test` (~2 min)
- **Before `/gsd:verify-work`:** Full suite green + analyzer 0 issues + coverage ≥80%
- **Max feedback latency:** 10 s for targeted tests, 120 s for full suite

---

## Per-Task Verification Map

(Filled by gsd-planner once plans exist. Skeleton rows below — one per decision D-NN.)

| Decision | Plan / Wave | Test Type | Automated Command | Anchor Scenario |
|----------|-------------|-----------|-------------------|-----------------|
| D-05 (WR-NEW-01 intra-session guard) | TBD | widget | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | `_onStatus('notListening')` with `lastFinalAt = now - 100ms` AND `_pressStart != null` → assert no commit; with `now - 2000ms` → assert commit fires |
| D-07 (WR-01 cold-start race) | TBD | widget | same file | Mount with `voiceLocaleIdProvider` AsyncValue.loading + immediate long-press → assert `_startRecording` NOT called; after provider resolves → second long-press commits |
| D-08 (WR-04 popUntil deferral) | TBD | widget | same file | Soul-ledger save → `SoulCelebrationOverlay` in tree AND no pop; overlay `onDismissed` fires → pop fires. Survival-ledger save → pop fires immediately |
| D-09 (WR-07 listener leak) | TBD | widget/unit | leak test file TBD per Q2 | Dispose-then-assert `hasListeners == false` (or `addListener` mock) |
| D-10 (IN-02 mixin extraction) | TBD | widget | same file | Existing G-01 + G-02 tests pass against mixed-in handlers; optional per-mixin unit test |
| D-11 (G-02 localized assert) | TBD | widget | `voice_input_screen_test.dart:946-1004` | `expect(find.text(l10n.voiceRecognitionErrorAudio), findsOneWidget)` before existing SoftToast assertion |
| D-12 (constant dedup) | TBD | architecture | `flutter test test/architecture/` | Existing `category_other_l2_invariant_test.dart` continues to pass with new import path |
| D-13 (substring length guard) | TBD | unit | `flutter test test/unit/infrastructure/ml/merchant_database_test.dart` | `findMerchant('a')` → null; `findMerchant('ab')` → null; `findMerchant('mac')` → McDonald entry |
| D-14 (SeedAllUseCase ordering) | TBD | unit | `flutter test test/unit/application/seed/seed_all_use_case_test.dart` (NEW) | Mock completion timestamps: categories' completion < synonyms' start |
| D-15 (`その他/其他/other` seed) | TBD | integration | `flutter test test/integration/voice/` | `voice_corpus_zh_test.dart` `'其他'` → `cat_other_other`; `voice_corpus_ja_test.dart` `'その他'` → same; new `voice_corpus_en_test.dart` `'other'` → same |
| D-04 (REQUIREMENTS.md flips) | TBD | manual diff | n/a (doc-only) | grep confirms `[x]` lines for INPUT-03/04, EDIT-01/02, VOICE-01..06 |
| D-04 (SUMMARY frontmatter) | TBD | manual diff | n/a (doc-only) | grep confirms `requirements-completed:` keys in Phase 18 SUMMARY 18-02/04/06/07/08 + Phase 19 SUMMARY 19-03/05 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — populated by execute-phase*

---

## Wave 0 Requirements

- [ ] `lib/application/seed/seed_all_use_case.dart` — new use case for D-14 (planner schedules)
- [ ] `lib/application/seed/seed_providers.dart` — provider wiring (planner schedules)
- [ ] `lib/shared/constants/category_other_id_overrides.dart` — extracted constants for D-12 IN-05
- [ ] `test/unit/application/seed/seed_all_use_case_test.dart` — ordering assertion test
- [ ] `test/integration/voice/voice_corpus_en_test.dart` — single-case `'other'` skeleton for D-15

*Existing infrastructure covers all other phase requirements (widget tests, architecture tests, merchant DB tests, voice corpus tests already exist).*

---

## Manual-Only Verifications

Carried device UATs per CONTEXT.md D-03 — physical-device required, cannot be automated in flutter_test:

| Behavior | Source | Why Manual | Test Instructions |
|----------|--------|------------|-------------------|
| Phase 22 Test #1 — physical-touch <100 ms latency | `22-HUMAN-UAT.md` | Touch hardware latency | Long-press the mic button on a physical iOS + Android device; observe perceived delay < 100 ms (no spinner, immediate haptic) |
| Phase 22 Test #2 — real-world ja/zh recognizer accuracy | `22-HUMAN-UAT.md` | Live speech recognition | Speak the 8-anchor utterances (Phase 20 VOICE-02) into a quiet room mic on physical iOS + Android; assert each parses to the expected amount |
| Phase 22 Test #3 — idle-state golden anti-aliasing parity | `22-HUMAN-UAT.md` | GPU rasterizer-dependent visuals | Capture screenshots from physical iOS + Android idle voice screen; diff against `test/golden/voice_idle_state.png` |
| Phase 22 Test #4 — `_onStatus('notListening')` intermediate behavior | `22-HUMAN-UAT.md` | Real recognizer intra-session emit timing | On physical iOS + Android: long-press, speak short utterance, pause briefly, speak more, release — assert no premature commit during the pause |
| Phase 20 VOICE-02 8-anchor (zh) | `20-08-SUMMARY.md` | Live recognition | zh utterances: `2204 continuous`, `1840 intra-pause merge`, `1800 false-merge regression` |
| Phase 20 VOICE-02 8-anchor (ja) | `20-08-SUMMARY.md` | Live recognition | ja utterances: `にせんにひゃくよん→2204`, `せんはっぴゃく+よんじゅう円→1840`, `一万二千→12000` |
| Phase 20 VOICE-02 sanity | `20-08-SUMMARY.md` | Visual + nav state | Record button stays lit during recording; ManualOneStepScreen carries `initialAmount` correctly |
| Phase 19 keypad-feel | Phase 19 HUMAN-UAT | Tactile / haptic | Manual keypad press feel on physical device |
| Phase 19 6-golden visual baseline | Phase 19 HUMAN-UAT | Golden image comparison | Capture 6 reference goldens and visually diff |

**Per CONTEXT.md specifics:** Phase 23 device UAT may accept deferral — if a hard regression is found (e.g., WR-NEW-01 guard still allows premature commit on Android), the regression can be re-deferred to v1.4 per Phase 11/13/17 precedent. The phase passes if (a) code polish lands, (b) doc reconciliation lands, (c) device session ran and produced a result.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (gsd-planner to enforce)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (new use-case, providers, constants, test files)
- [ ] No watch-mode flags in commands
- [ ] Feedback latency < 10 s for targeted tests
- [ ] `flutter analyze` 0 issues post-phase
- [ ] Coverage ≥80% per CLAUDE.md
- [ ] `nyquist_compliant: true` set in frontmatter once planner populates the per-task map

**Approval:** pending
