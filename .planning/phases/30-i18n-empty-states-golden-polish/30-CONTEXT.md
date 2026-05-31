# Phase 30: i18n + Empty States + Golden Polish - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Final polish + QA pass that closes out milestone v1.4 列表功能. The list feature is functionally complete (Phases 24–29); this phase delivers:

1. **i18n completeness** — every list-tab string served via `S.of(context)`, the one known English leak (`listMineOnly`) localized, list-tab hardcoded strings audited+fixed, 3-locale key parity preserved.
2. **Empty-state polish** — refined trilingual copy + a new day-filter-specific empty state.
3. **Golden baselines** — locked on the list-tab widgets, deterministic in CI.
4. **CI green gate** — `flutter analyze` 0, `custom_lint` 0, clean `build_runner` diff, coverage ≥70%.

**Fixed scope (not in this phase):** no new list capabilities, no behavioral changes to filtering/sorting/sync. Discussion clarified HOW to finish what's scoped, never new features.

</domain>

<decisions>
## Implementation Decisions

### Golden Baselines
- **D-01:** Lock golden baselines for **all 6 list-tab widgets**: `list_transaction_tile`, `list_day_group_header`, `list_sort_filter_bar`, `list_empty_state`, `list_calendar_header`, `list_category_filter_sheet`.
- **D-02:** Coverage per widget = **all 3 locales (ja/zh/en), light theme**. (Precedent: `amount_display_golden_test.dart` already does 3-locale; this is the i18n phase so cross-language layout/overflow verification is the point.) No dark-theme goldens this phase.
- **D-03:** Goldens **hard-fail CI**, paired with determinism investment so they don't flake: pin fonts + `textScaleFactor`, disable animations, and **freeze `table_calendar` to a fixed reference date** (the calendar header is the highest flake risk — there is already a `test/golden/failures/` dir of flaky home_hero diffs). Stabilize, don't loosen with a pixel-tolerance threshold.

### Empty States (3-state design — replaces current binary `isFilterActive`)
- **D-04:** Three render states with distinct copy + icons:

  | State | Trigger | Icon | ja | zh | en |
  |---|---|---|---|---|---|
  | No-data | Month has no entries, no filters | `receipt_long_outlined` | この月にはまだ記録がありません | 本月还没有记录 | No records yet this month |
  | Day-empty | **Only** a calendar day-filter active | `event_busy_outlined` | この日の記録はありません | 这一天没有记录 | No records on this day |
  | Filtered | Any ledger/category/search/member filter active (with or without a day filter) | `search_off_outlined` | 条件に合う記録が見つかりません | 没有符合条件的记录 | No records match your filters |

- **D-05:** Branching logic — **only** day-filter active → day-empty message + a "show full month" action that clears *just* the day filter. Any *other* filter active (regardless of day) → filtered message + "clear filters" action that clears *all*. Nothing active → no-data, no action.
- **D-06:** Copy refinement: no-data line uses "まだ / 还 / yet" to signal a fresh month, not a dead end. Existing keys `listEmptyMonth` / `listEmptyFiltered` / `listEmptyFilteredClear` updated to the table copy; **2 new keys** added: `listEmptyDay` + `listEmptyDayClear` (×3 locales).

### Untranslated Copy / i18n Audit
- **D-07:** `listMineOnly` (currently English "Mine only" in all 3 locale files) → **ja: 自分のみ · zh: 仅自己 · en: Mine only**.
- **D-08:** Hardcoded-string sweep scope = **fix only within `lib/features/list/`**. Additionally run an app-wide grep and **document** every leak found elsewhere as a deferred inventory (do NOT fix outside the list tab — keeps the phase boundary clean). See Deferred Ideas.
- **D-09:** Preserve exact 3-locale key parity (currently 1199 each) — every key added/renamed must land in all of `app_ja.arb`, `app_zh.arb`, `app_en.arb`, then `flutter gen-l10n` with no warnings.

### CI Gate
- **D-10:** Coverage gate = **≥70%** — the Phase 30 roadmap SC#4 governs over the 80% global CLAUDE.md default for this polish phase (mostly goldens + ARB keys, not heavy logic).
- **D-11:** Full green gate before phase close: `flutter analyze` 0 issues, `dart run custom_lint --no-fatal-infos` 0 errors, `build_runner` diff clean, coverage ≥70%.

### Claude's Discretion
- Exact golden test file organization (one file per widget vs grouped), fixture construction, and the determinism harness mechanics — follow existing `test/golden/*.dart` conventions.
- Mechanical ARB key insertion order and `@`-metadata formatting.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/ROADMAP.md` — Phase 30 entry: goal + 4 success criteria (LIST-03; coverage ≥70%).
- `.planning/REQUIREMENTS.md` — LIST-03 (clear empty state for month + filters); i18n line (~20–25 ARB keys, `S.of(context)`, DateFormatter, NumberFormatter).

### i18n Infrastructure
- `docs/arch/04-basic/BASIC-003_I18N_Infrastructure.md` — i18n architecture spec; `S` class, `DateFormatter`, `NumberFormatter`, locale rules.
- `CLAUDE.md` §i18n Rules — `S.of(context)` mandate, update all 3 ARB files + `flutter gen-l10n`, JPY/USD formatting, date/compact-number formats.
- `l10n.yaml` — output class `S`, output dir `lib/generated`.
- `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/l10n/app_en.arb` — the three locale files (1199 keys each; ~25 `list*` keys already present at lines ~2107–2205 of ja).

### Existing Code (this phase modifies)
- `lib/features/list/presentation/widgets/list_empty_state.dart` — current 2-state widget (`isFilterActive`); to be reworked into the 3-state design (D-04/D-05).
- `lib/features/list/presentation/screens/list_screen.dart:121` — empty-state mount point (passes `isFilterActive: anyFilterActive`).
- `lib/features/list/presentation/widgets/` — the 6 widgets needing goldens.

### Golden Precedent
- `test/golden/amount_display_golden_test.dart` — 3-locale (ja/en/zh) golden pattern to follow for D-02.
- `test/golden/per_category_breakdown_card_golden_test.dart` — `ProviderScope` + `MaterialApp` wrap + `S.supportedLocales` harness pattern.
- `test/golden/failures/` — existing flaky home_hero diffs; evidence motivating the D-03 determinism work.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`list_empty_state.dart`** already exists and already handles no-data vs filtered with `S.of(context)` + a `clearAll()` action — SC#2/SC#3 are largely satisfied structurally. This phase *extends* it to 3 states, not builds from scratch.
- **~25 `list*` ARB keys** already exist in all 3 locales — the "~20–25 keys" estimate in REQUIREMENTS is mostly already met. Real i18n work is the audit + the `listMineOnly` fix + 2 new empty-state keys, not bulk key creation.
- **`AppColors` / `AppTextStyles` / `NumberFormatter` / `DateFormatter`** — already used by list widgets; goldens must render through these (no hardcoded hex/styles).
- **3-locale golden harness** already proven in `amount_display_golden_test.dart` — copy its `S.supportedLocales` + per-locale `_wrap` structure.

### Established Patterns
- ARB key parity is exact (1199/1199/1199) — the project already maintains 3-way parity; the planner must keep it.
- Golden tests wrap widgets in `ProviderScope(overrides:...) + MaterialApp(localizationsDelegates, supportedLocales: S.supportedLocales, locale: Locale(...))`.
- `clearAll()` lives on `listFilterProvider.notifier` (`state_list_filter.dart`); a day-only-clear action (D-05) needs a narrower clear path — check whether the notifier already exposes day-filter clearing or needs a method.

### Integration Points
- `list_calendar_header.dart` wraps `table_calendar` — the golden determinism work (D-03 fixed reference date) concentrates here.
- New `listEmptyDay` / `listEmptyDayClear` keys flow into `list_empty_state.dart` and require `flutter gen-l10n` regeneration.

</code_context>

<specifics>
## Specific Ideas

- Empty-state copy is **locked verbatim** to the D-04 table (user approved as proposed, no changes). Downstream agents use that exact trilingual wording — do not paraphrase.
- "Show full month" (day-empty action) and "clear filters" (filtered action) are semantically different clears: day-empty clears only the day filter; filtered clears all. Don't collapse them.

</specifics>

<deferred>
## Deferred Ideas

- **App-wide hardcoded-string inventory (D-08):** the sweep will likely surface hardcoded strings outside `lib/features/list/`. These are documented as an inventory in this phase but **fixed in a future i18n-cleanup phase**, not here. Capture findings (file:line + string) in the phase's deliverables for roadmap backlog.
- **Dark-theme goldens:** explicitly out of scope this phase (D-02 is light-only). A future visual-QA phase could add dark-theme golden coverage for the list tab.

</deferred>

---

*Phase: 30-i18n-empty-states-golden-polish*
*Context gathered: 2026-05-31*
