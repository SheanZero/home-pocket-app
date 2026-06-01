---
phase: 34
slug: golden-re-baseline-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-01
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `34-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK bundled) |
| **Config file** | none — `flutter test` CLI is the runner |
| **Quick run command** | `flutter test <touched_golden_file>` + `flutter analyze` |
| **Full suite command** | `flutter test` |
| **Golden update (selective)** | `flutter test <file> --update-goldens` |
| **Non-golden suite** | `flutter test --exclude-tags golden` |
| **Coverage** | `flutter test --coverage` (lcov global ≥70%) |
| **Estimated runtime** | full suite ~minutes (315 `*_test.dart`); per-golden seconds |

---

## Sampling Rate

- **After every task commit:** Run the specific golden file(s) touched + `flutter analyze`
- **After every plan wave:** `flutter test` (full suite incl. goldens) + coverage check
- **Before `/gsd-verify-work`:** Full suite green, `flutter analyze` 0 issues, coverage ≥70%, BOTH success-criteria greps empty
- **Max feedback latency:** per-golden seconds; full-suite minutes

---

## Per-Task Verification Map

| Behavior | Requirement | Test Type | Automated Command | File Exists |
|----------|-------------|-----------|-------------------|-------------|
| 7 light-only files gain `themeMode` param + dark variants | COLOR-04 | golden (Wave 0) | edit file → `flutter test <file> --update-goldens` | ❌ W0: edit 7 files |
| Orphaned `summary_cards_{en,ja}.png` removed | COLOR-04 | file-absence | `test ! -e test/golden/goldens/summary_cards_en.png` | ❌ W0: delete |
| All goldens regenerated, 0 mismatches | COLOR-04 | golden | `flutter test test/golden/` + 2 widget golden files | ✅ |
| Diff confirms palette-only delta (intended = ADR-018 + decorative re-hue + hero gradient) | COLOR-04 | manual review (D-02) | Read `test/golden/failures/*_isolatedDiff.png` / `*_maskedDiff.png` | ✅ (auto-gen on mismatch) |
| Suspected non-palette delta → halt & report (D-04) | COLOR-04 | manual adjudication | classify diff; do NOT `--update-goldens`; surface as Phase-33 defect | ✅ |
| No stale ARB vocabulary | COLOR-04 | grep | `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` = 0 | ✅ |
| No raw hex literals in feature code | COLOR-04 | grep | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` = 0 | ✅ |
| D-03a broad old-hex sweep (outside core/theme) | COLOR-04 | grep | old-palette hex grep over `lib/ test/ docs/` excl. `lib/core/theme` | ✅ |
| Full non-golden suite green | COLOR-04 | unit + integration | `flutter test --exclude-tags golden` | ✅ |
| Analyzer clean | COLOR-04 | static analysis | `flutter analyze` → 0 issues | ✅ |
| Coverage ≥70% global | COLOR-04 | coverage | `flutter test --coverage` + lcov summary | ✅ |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Success-Criteria Greps (ROADMAP verbatim — phase gate)

```bash
# SC2 — vocabulary audit (expect empty)
grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb
# SC2 — color literal audit (expect empty)
grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/
# SC3 — static analysis (expect 0 issues)
flutter analyze
# SC3 — coverage (expect ≥70% global)
flutter test --coverage
```

---

## D-03a Comprehensive Audit (beyond the two standard greps)

```bash
# Old-palette hex outside lib/core/theme/ (coral/blue/green/olive/terracotta set)
grep -rn "E85A4F\|5A9CC8\|47B88A\|8A9178\|D4845A\|F08070" \
  lib/ test/ docs/ --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"
# Stale vocabulary swept into test/ and docs/
grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' test/ docs/
```

⚠ Legit palette hex LIVES in `lib/core/theme/` by design (Phase 33 D-03) — the literal grep deliberately excludes it. Known D-03a hits to remediate (from research): `docs/design/*.md` + `design-tokens.json` + `flutter_color_mapping.dart`; stale `Color(0xFF5A9CC8)` / `Color(0xFF47B88A)` in `test/.../home_transaction_tile_test.dart` and `list_transaction_tile_test.dart`. `Category.color: '#E85A4F'` string fixtures are data fields (inert) — verify, don't blindly rewrite.

---

## Wave 0 Requirements

- [ ] Edit 7 light-only golden test files — add `themeMode` param to `_wrap` + dark `testWidgets` blocks (per-locale, D-01b):
      `list_day_group_header`, `amount_display`, `list_sort_filter_bar`, `list_category_filter_sheet`, `list_calendar_header`, `list_transaction_tile`, `list_empty_state`
- [ ] `list_transaction_tile` dark variant: use `AppPalette.dark.*` constructor params (NOT `.light.*` — hardcoded fixture pitfall)
- [ ] Delete orphaned `test/golden/goldens/summary_cards_en.png` + `summary_cards_ja.png`
- [ ] Confirm `amount_display` reads `context.palette` before adding a dark variant (else light==dark, valid but uninformative)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Per-golden diff attribution (D-02) | COLOR-04 | Visual judgment of PNG deltas; not machine-assertable | Run golden suite WITHOUT `--update-goldens`; read `failures/*_isolatedDiff.png` + `*_maskedDiff.png`; classify each as palette/decorative/hero (→ update) or suspected regression (→ halt & report per D-04) |
| `.pen` ↔ ADR-018 sync (D-03b) | COLOR-04 | Pencil MCP cannot flush to disk in this env (project memory) | Best-effort via Pencil MCP; if no persist, mark deferred — NON-BLOCKING for milestone close |

---

## Validation Sign-Off

- [ ] All re-baseline tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the 7-file dark-variant edits + orphan deletion
- [ ] No watch-mode flags
- [ ] Both success-criteria greps return empty at phase gate
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
