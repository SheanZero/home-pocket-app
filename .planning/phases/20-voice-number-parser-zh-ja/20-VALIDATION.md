---
phase: 20
slug: voice-number-parser-zh-ja
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart SDK) + mocktail ^1.0.4 + fake_async ^1.3.3 |
| **Config file** | `test/dart_test.yaml` (existing); per-test fixture imports |
| **Quick run command** | `flutter test test/unit/infrastructure/voice/ test/unit/application/voice/` |
| **Full suite command** | `flutter test --coverage` |
| **Estimated runtime** | ~30s quick; ~3–4 min full suite |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/infrastructure/voice/ test/unit/application/voice/`
- **After every plan wave:** Run `flutter analyze && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green; per-file coverage ≥70% on new parser files; per-locale corpus ≥95%
- **Max feedback latency:** ~30 seconds (quick); ~4 minutes (full)

---

## Per-Task Verification Map

> Populated by `gsd-planner` from PLAN.md task IDs. Each task with `<automated>` predicates lands here.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _TBD by planner_ | | | VOICE-01 / VOICE-02 / VOICE-03 | — | N/A (local-only NLP) | unit | `flutter test ...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Per RESEARCH.md §Validation Architecture — 9 new test files + 2 updates:

- [ ] `test/unit/infrastructure/voice/chinese_numeral_state_machine_test.dart` — VOICE-01 zh anchor + token-scanner unit tests
- [ ] `test/unit/infrastructure/voice/japanese_numeral_state_machine_test.dart` — VOICE-01 ja anchor + token-scanner unit tests
- [ ] `test/unit/infrastructure/voice/japanese_numeral_dictionary_test.dart` — D-05 multi-reading + voicing/sokuon entry coverage
- [ ] `test/unit/infrastructure/voice/numeral_state_machine_normalize_test.dart` — D-07 mixed-input normalize() invariants
- [ ] `test/unit/application/voice/voice_chunk_merger_test.dart` — D-10 lexical gate + D-11 time gate + D-12 restart orchestration (fake_async)
- [ ] `test/unit/application/voice/voice_text_parser_test.dart` — UPDATE: retire `_extractKanjiAmount` cases; assert `extractAmount(text, locale)` routes to infrastructure
- [ ] `test/unit/infrastructure/speech/speech_recognition_service_test.dart` — UPDATE: `restartListen()` behavior (in-flight guard per Pitfall 3)
- [ ] `test/integration/voice/voice_corpus_zh_test.dart` — VOICE-03 zh ≥95% accuracy + 2 anchor cases as named `test()` blocks
- [ ] `test/integration/voice/voice_corpus_ja_test.dart` — VOICE-03 ja ≥95% accuracy + 3 anchor cases (incl. 一万二千 regression)
- [ ] `test/fixtures/voice_corpus_zh.dart` — Dart-literal corpus (~50 cases, 30/30/20/10/10 split per RESEARCH §Open Q4)
- [ ] `test/fixtures/voice_corpus_ja.dart` — Dart-literal corpus (~50 cases, same split)

*Wave 0 = test scaffolds + fixtures created before implementation tasks; each REQ traceable to at least one Wave 0 file.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Recognizer behavior on real iOS device for zh-CN / ja-JP partial→final fragmentation | VOICE-02 | speech_to_text plugin behavior is OS-side; mocks cover the merger contract but real-device drift is undetectable in unit tests | 1. Build to physical iPhone (zh+ja locales). 2. Speak "2千2百零4元" continuous → expect 2204 in `initialAmount`. 3. Speak "1千8百" → pause 1.5s → "4十元" → expect 1840 (not 1800+40). 4. Speak "せんはっぴゃく" → pause 1.5s → "よんじゅう円" → expect 1840. 5. Speak "1千8百" → pause 1.5s → "现金" → expect 1800 commit + non-numeric drop. |
| Recognizer behavior on real Android device | VOICE-02 | Same — Android STT differs from iOS in partial-result cadence | Same script as above on Android (zh+ja locales). |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (9 new + 2 updated test files + 2 fixture files)
- [ ] No watch-mode flags (no `flutter test --watch` in commands)
- [ ] Feedback latency < 30s for quick path
- [ ] Per-locale corpus accuracy reporter prints "zh: N/M (P%)" + "ja: N/M (P%)" in `tearDownAll`
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
