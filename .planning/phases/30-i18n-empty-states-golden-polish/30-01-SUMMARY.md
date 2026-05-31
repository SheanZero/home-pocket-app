---
phase: 30-i18n-empty-states-golden-polish
plan: "01"
subsystem: i18n
tags: [arb, localization, gen-l10n, parity, list-tab]
dependency_graph:
  requires: []
  provides:
    - "lib/l10n/app_ja.arb — 6 new list* keys + updated copies"
    - "lib/l10n/app_zh.arb — 6 new list* keys + updated copies"
    - "lib/l10n/app_en.arb — 6 new list* keys + updated copies"
    - "lib/generated/ (regenerated, gitignored) — S.listEmptyDay, S.listEmptyDayClear, S.listLoadError, S.listCalNavPrev, S.listCalNavNext, S.listCalNavCurrentMonth"
  affects:
    - "Wave 2 widget code (list_empty_state.dart, list_calendar_header.dart, list_screen.dart)"
tech_stack:
  added: []
  patterns:
    - "ARB key block extension after listEmptyFilteredClear, before @@locale"
    - "3-locale parity — all 3 ARB files must be edited together"
key_files:
  created: []
  modified:
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
decisions:
  - "D-04/D-06 locked copy used verbatim — no paraphrase"
  - "D-07: listMineOnly fixed to ja:自分のみ / zh:仅自己 / en:Mine only"
  - "D-09: 3-locale parity maintained — arb_key_parity_test passes"
  - "D-12: listLoadError added in all 3 locales"
  - "D-13: listCalNavPrev/Next/CurrentMonth added in all 3 locales"
  - "lib/generated/ is gitignored by project convention — not committed"
metrics:
  duration: "~10 minutes"
  completed: "2026-05-31"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 30 Plan 01: ARB i18n Key Additions + gen-l10n Summary

ARB key additions covering locked decisions D-04/D-06/D-07/D-09/D-12/D-13 — 6 new list* keys + 4 updated copy values across all 3 locale files, with flutter gen-l10n regeneration and arb_key_parity_test green.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add 6 new list* ARB keys + update 4 existing keys in all 3 locale files | 488c04ef | lib/l10n/app_{ja,zh,en}.arb |
| 2 | Run flutter gen-l10n and verify ARB parity + analyzer clean | (no commit — lib/generated/ gitignored) | lib/generated/ regenerated in-place |

## Changes Made

### Task 1: ARB key edits (3 files, 78 insertions, 6 deletions)

**Updated keys (in-place value changes):**

| Key | ja | zh | en |
|-----|-----|-----|-----|
| `listMineOnly` (D-07) | 自分のみ | 仅自己 | Mine only (unchanged) |
| `listEmptyMonth` (D-06) | この月にはまだ記録がありません | 本月还没有记录 | No records yet this month |
| `listEmptyFiltered` (D-06) | (unchanged) | (unchanged) | No records match your filters |
| `listEmptyFilteredClear` | (unchanged — already matched D-04 table) | (unchanged) | (unchanged) |

**New keys added (all 3 locales, with @-metadata):**

| Key | ja | zh | en |
|-----|-----|-----|-----|
| `listEmptyDay` (D-06) | この日の記録はありません | 这一天没有记录 | No records on this day |
| `listEmptyDayClear` (D-06) | 月全体を表示 | 显示整月 | Show full month |
| `listLoadError` (D-12) | データを読み込めません | 无法加载数据 | Unable to load data |
| `listCalNavPrev` (D-13) | 前の月 | 上个月 | Previous month |
| `listCalNavNext` (D-13) | 次の月 | 下个月 | Next month |
| `listCalNavCurrentMonth` (D-13) | 今月に戻る | 返回本月 | Return to current month |

### Task 2: flutter gen-l10n + verification

- `flutter gen-l10n` exited 0 with no warnings
- `arb_key_parity_test.dart` — ALL PASSED (2/2 tests)
- `flutter analyze lib/l10n/ lib/generated/ --no-fatal-infos` — 0 issues
- Full analyzer ran clean on our files; 4 pre-existing issues in build/ and category_selection_screen.dart are out of scope

## Verification Results

| Check | Result |
|-------|--------|
| `grep -c '"list[A-Z]' app_ja.arb` == 30 | PASS |
| `grep -c '"list[A-Z]' app_zh.arb` == 30 | PASS |
| `grep -c '"list[A-Z]' app_en.arb` == 30 | PASS |
| `flutter test test/architecture/arb_key_parity_test.dart` | PASS (2/2) |
| `grep 'listEmptyDay' lib/generated/app_localizations.dart` | FOUND |
| `flutter analyze lib/l10n/ lib/generated/ --no-fatal-infos` | 0 issues |

## Deviations from Plan

None — plan executed exactly as written.

**Note on Task 2 commit:** lib/generated/ is gitignored by project convention (see .gitignore line: `lib/generated/`). flutter gen-l10n successfully regenerated the files on disk for Wave 2 widget compilation. No commit was needed or possible for generated files.

## Known Stubs

None — this plan only modifies ARB key values and the generated Dart strings. No UI component stubs introduced.

## Threat Flags

None — this plan modifies only UI copy in JSON locale files and regenerates Dart string getters. No auth, session, crypto, or user input surface changes introduced.

## Self-Check: PASSED

- [x] lib/l10n/app_ja.arb modified — FOUND
- [x] lib/l10n/app_zh.arb modified — FOUND
- [x] lib/l10n/app_en.arb modified — FOUND
- [x] lib/generated/app_localizations.dart regenerated with listEmptyDay getter — FOUND
- [x] Commit 488c04ef exists — VERIFIED
- [x] arb_key_parity_test PASSES — VERIFIED
