---
phase: 33
slug: color-token-system-consolidation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `33-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (bundled with Flutter SDK) |
| **Config file** | none — `flutter test` auto-discovers `test/` |
| **Quick run command** | `flutter analyze` (0 issues required) |
| **Full suite command** | `flutter test --exclude-tags golden` |
| **Grep gate command** | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` (must return 0) |
| **Estimated runtime** | ~60s (analyze) / ~2–4 min (test suite, golden excluded) |

> **Phase 33 golden caveat:** golden tests WILL fail during this phase (palette changes). Run with `--exclude-tags golden`. Golden re-baseline is Phase 34 (COLOR-04), out of scope here.

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze` (mandatory, must be 0 issues)
- **After every plan wave:** Run `flutter analyze` + the COLOR-01 grep gate (must return 0 after W2 completes)
- **Before `/gsd-verify-work`:** `flutter test --exclude-tags golden` must be green; COLOR-01 grep gate returns 0; build_runner clean-diff
- **Max feedback latency:** ~60 seconds (analyze)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-WAVE0 | 00 | 0 | COLOR-01/03 + THEME-V2-02 | — | N/A | unit/arch | `flutter test test/architecture/color_literal_scan_test.dart test/core/theme/app_palette_test.dart test/widget/theme_dark_mode_coverage_test.dart` | ❌ W0 | ⬜ pending |
| COLOR-01 | — | per-wave | COLOR-01 | — | N/A | grep gate | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` returns 0 | ✅ | ⬜ pending |
| COLOR-02 | — | phase gate | COLOR-02 | — | N/A | golden (deferred) | `flutter test test/golden/` (Phase 34 — skip in P33) | ✅ | ⬜ deferred |
| COLOR-03 | — | post-W2 | COLOR-03 | — | N/A | analyze + grep | `flutter analyze` (0) + `grep -rn '_joyTargetStartColor\|_joyTargetEndColor' lib/` returns 0 | ✅ | ⬜ pending |
| THEME-V2-02 | — | dark wave | THEME-V2-02 (absorbed) | — | N/A | widget | `flutter test test/widget/theme_dark_mode_coverage_test.dart` | ❌ W0 | ⬜ pending |
| analyze gate | — | every commit | success-crit #4 | — | N/A | static | `flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/architecture/color_literal_scan_test.dart` — architecture test running the COLOR-01 grep gate as a test case (mirror existing `stale_suppressions_scan_test.dart` pattern if present)
- [ ] `test/core/theme/app_palette_test.dart` — `AppPalette` unit test: (a) `.light`/`.dark` non-null; (b) `copyWith` returns new instance; (c) `lerp(t=0.0)` returns original; (d) key ADR-018 hex values match expected literals
- [ ] `test/widget/theme_dark_mode_coverage_test.dart` — pumps a representative set of screens under `ThemeMode.dark` and asserts no exceptions / `AppPalette` resolves

*Note: the three Wave 0 tests are RED until their implementation tasks land — expected.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Correct 日常/悦己 accent on every surface looks right | COLOR-02 | Visual correctness pre-golden-rebaseline | Run app in light + dark; spot-check home hero, ledger lists, analytics, profile, family_sync |
| Dark-mode legibility / contrast | THEME-V2-02 | WCAG amount-text contrast is visual | Toggle dark mode on each of the 15 newly-adapted screens; confirm amount text uses `*Text` variants |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (`flutter analyze` runs every commit)
- [ ] Wave 0 covers all MISSING references (3 test files above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
