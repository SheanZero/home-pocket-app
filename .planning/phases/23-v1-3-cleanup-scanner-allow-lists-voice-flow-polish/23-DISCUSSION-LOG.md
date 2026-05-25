# Phase 23: v1.3 cleanup — scanner allow-lists + voice flow polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 23-v1-3-cleanup-scanner-allow-lists-voice-flow-polish
**Areas discussed:** Phase scope, Voice flow polish, Phase 21 INFO polish

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Phase scope selection | Lock what gets folded in vs deferred to v1.4 | ✓ |
| Voice flow polish approach | Address WR-NEW-01..03, IN-01..03, WR-01..07 in voice_input_screen.dart | ✓ |
| Phase 21 INFO polish (IN-01..06) | 6 advisory items from 21-REVIEW.md | ✓ |
| Doc reconciliation + Nyquist | REQUIREMENTS.md checkboxes + SUMMARY frontmatter + VALIDATION retrofits | |

---

## Phase scope

### Q1 — Primary intent for Phase 23

| Option | Description | Selected |
|--------|-------------|----------|
| Tight cleanup, ship v1.3 | WR-NEW-01..03 + Phase 21 IN-03 only; skip rest | |
| Full voice-flow polish | All voice WR/IN items + Phase 21 IN-01..06 | ✓ |
| Correctness-only, defer cosmetics | Voice correctness bugs + Phase 21 IN-03 + IN-06; skip cosmetic items | |

**User's choice:** Full voice-flow polish
**Notes:** Captured as D-01. Note this intent was later qualified by selective deferrals in subsequent voice-polish questions.

### Q2 — Title accuracy (scanner allow-lists already cleared)

| Option | Description | Selected |
|--------|-------------|----------|
| Rename phase, drop scanner mention | Update ROADMAP.md to reflect actual scope | |
| Keep title, note in CONTEXT | Leave ROADMAP as-is; CONTEXT.md notes scanner cleared | ✓ |
| Keep title, verify allow-list is current | Defensive re-check of allow-list coverage | |

**User's choice:** Keep title, note in CONTEXT
**Notes:** Captured as D-02. Scanner work was cleared in Phase 21 commits `117be50` + `a570dfc` per STATE.md.

### Q3 — Carried human UATs scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fold all into Phase 23 UAT | Phase 23 owns running carried device UATs | ✓ |
| Run only WR-NEW-01 device check | Only the notListening intra-session check | |
| Accept all at v1.3 close | Code-only Phase 23; UATs as documentation-grade debt | |
| You decide | Pick based on WR-NEW-01 fix approach | |

**User's choice:** Fold all into Phase 23 UAT
**Notes:** Captured as D-03. Covers Phase 19 keypad-feel + 6-golden, Phase 20 VOICE-02 8-anchor, Phase 22 4 device UATs.

### Q4 — Doc reconciliation scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into Phase 23 (recommended) | 10 checkbox flips + 7 frontmatter backfills in this phase | ✓ |
| Quick task, separate commits | /gsd-quick task before complete-milestone | |
| Defer to /gsd:complete-milestone v1.3 | Handled by archive step | |

**User's choice:** Fold into Phase 23
**Notes:** Captured as D-04 + D-17. Suggested ordering: code-polish → doc reconciliation → device UAT.

---

## Voice flow polish

### Q1 — WR-NEW-01 fix approach (_onStatus 'notListening' premature commit risk)

| Option | Description | Selected |
|--------|-------------|----------|
| Restrict G-01 to status=='done' only | Drop 'notListening' from commit predicate | |
| Keep both; add intra-session guard | Heuristic guard on partial-result timing | ✓ |
| Keep both; rely on device UAT to validate | Status quo + verification only | |
| You decide | Pick based on plugin docs | |

**User's choice:** Keep both; add intra-session heuristic guard
**Notes:** Captured as D-05 + D-19. N-threshold default ceiling 800 ms; researcher to anchor against `speech_to_text` plugin partial-result cadence.

### Q2 — WR-NEW-02 + WR-NEW-03 (commit-path race + double-parse)

| Option | Description | Selected |
|--------|-------------|----------|
| Fix together: _committedRecently flag + reuse _parseResult | Both via commit-path refactor | |
| Fix WR-NEW-02 only, defer WR-NEW-03 | Toast race fix only | |
| Fix WR-NEW-03 only, defer WR-NEW-02 | Double-parse fix only | |
| Defer both | Phase 23 does NOT touch commit path | ✓ |

**User's choice:** Defer both
**Notes:** Captured as D-06. The commit path was just stabilized in Phase 22 G-01/G-02 closures — rewriting would re-risk that work. Logged as deferred ideas.

### Q3 — IN-02 (832-line screen extraction)

| Option | Description | Selected |
|--------|-------------|----------|
| Extract _onStatus/_onError to mixin | VoiceRecognitionEventHandlerMixin on State | ✓ |
| Extract _extractVoiceKeyword + parse helpers | Pure-function helpers in lib/application/voice/ | |
| Accept overage with inline rationale | Top-of-file comment, no code change | |
| Defer | Skip entirely | |

**User's choice:** Extract _onStatus/_onError to mixin
**Notes:** Captured as D-10. ~50 LOC moves; gesture handlers stay in screen. Should drop screen below 800-line cap.

### Q4 — Remaining standing WR/IN selection (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| WR-01: voiceLocaleId cold-start race | Await provider before allowing first long-press | ✓ |
| WR-04: popUntil pre-celebration | Defer pop until SoulCelebrationOverlay onCompleted | ✓ |
| WR-07: addListener leak | Hoist closure to named local function | ✓ |
| IN-03: G-02 test localized assert | Add find.text(l10n.voiceRecognitionErrorAudio) | ✓ |

**User's choice:** ALL four
**Notes:** Captured as D-07, D-08, D-09, D-11. WR-02, WR-03, WR-06, IN-01 NOT mentioned → deferred to v1.4+ per universal-mode rule.

---

## Phase 21 INFO polish

### Q1 — Which IN items to fold in (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| IN-01 + IN-05 (constant dedup) | _epoch + _otherIdOverrides shared constants | ✓ |
| IN-03 (min-length substring guard) | length < 3 → null in MerchantDatabase | ✓ |
| IN-04 (seed order enforcement) | Sanity check OR SeedAllUseCase | ✓ |
| IN-06 (その他/其他 seed + corpus) | Expand seed coverage for override path | ✓ |

**User's choice:** ALL four selected (IN-02 NOT selected → deferred per D-16)
**Notes:** Captured as D-12, D-13, D-14, D-15. IN-02 (SeedSpec signature change) defers to v1.4+.

### Q2 — IN-04 fix shape

| Option | Description | Selected |
|--------|-------------|----------|
| Sanity check in execute() (lighter) | findById assertion at top of SeedVoiceSynonymsUseCase | |
| SeedAllUseCase wrapper (structural) | New use case owns both calls in order | ✓ |
| Both | Belt-and-braces | |

**User's choice:** SeedAllUseCase wrapper (structural)
**Notes:** Captured as D-14. main.dart collapses to one call.

### Q3 — IN-06 seed scope (locales)

| Option | Description | Selected |
|--------|-------------|----------|
| zh+ja only (その他 + 其他) | Per Phase 21 REVIEW recommendation | |
| zh+ja+en (その他 + 其他 + 'other') | Seed all three locales as v1.4 hedge | ✓ |
| zh+ja + ARB localization | ARB-key-driven seed | |

**User's choice:** zh+ja+en (その他 + 其他 + 'other')
**Notes:** Captured as D-15. en corpus skeleton file may be new — single test case only, do not expand en corpus coverage.

---

## Claude's Discretion

Captured as D-18, D-19, D-20 in CONTEXT.md:
- Plan ordering within Phase 23 (researcher + planner decide dependency graph)
- N-threshold value for WR-NEW-01 intra-session guard (researcher anchors to plugin docs; default ceiling 800 ms)
- Test strategy across the bundle (extend existing test files unless natural file boundary)

## Deferred Ideas

All deferred items moved to CONTEXT.md `<deferred>` section. Summary:
- WR-NEW-02, WR-NEW-03 (commit-path; v1.4+)
- WR-02, WR-03, WR-06 (standing voice WRs; cosmetic/test-only)
- IN-01 voice (retry affordance)
- IN-02 Phase 21 (SeedSpec signature)
- MOD-005 OCR writer
- English voice quality (only one en corpus hedge case added in D-15)
- VALIDATION.md Nyquist retrofits for Phase 18-22 (documentation-grade)
- All v1.2/v1.3 carry-over items (FAMILY-V2, FUTURE-DOC, fl_chart, FUTURE-ARCH-04, etc.)
