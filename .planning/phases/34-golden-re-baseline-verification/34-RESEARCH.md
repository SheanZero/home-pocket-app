# Phase 34: Golden Re-baseline & Verification — Research

**Researched:** 2026-06-01
**Domain:** Flutter native golden testing, palette re-baseline, dark-mode coverage expansion, static-analysis audit
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Close the 7-file dark coverage gap. Add dark variants to the 7 light-only golden test files so all 12 golden test files cover both light and dark.
- **D-01b:** New dark variants match light's per-locale coverage (not the existing ja-only convention). Where a light golden is per-locale, its dark counterpart is also per-locale.
- **D-02:** Per-golden diff review before committing the re-baseline. Run the suite without `--update-goldens` first so `failures/` generates `isolatedDiff`/`maskedDiff`/before-after PNGs. Each delta must be attributable to (a) ADR-018 palette change, (b) D-04 decorative re-hue tokens, or (c) D-05 teal→gold hero gradient.
- **D-02b:** Claude judges autonomously, no human UAT checkpoint. Claude reads the diff PNGs, classifies each, and decides whether to `--update-goldens`. No human gate for diffs classified as pure-palette.
- **D-03a:** Comprehensive audit beyond the two ROADMAP greps. Sweep for old-palette hex literals outside `lib/core/theme/`, and extend the terminology + hex sweep into `test/` and `docs/`. Legitimate palette hex LIVES in `lib/core/theme/` — the literal grep excludes that dir.
- **D-03b:** Attempt `.pen` sync via Pencil MCP — best-effort. If MCP cannot persist, mark reconciliation as deferred. Does NOT block milestone close. ADR-018 remains authoritative.
- **D-04:** Non-palette deltas halt and report — never silent-update. Any delta not attributable to palette/D-04/D-05 must be surfaced as a Phase-33 defect for user adjudication. Not auto-updated.

### Claude's Discretion

- Golden device sizes, truncation tolerances, and the exact wrapper used to add dark variants (reuse the `ThemeMode.dark` loop pattern already in `daily_vs_joy_card_golden_test.dart`).
- The exact list of retired hex values to grep for in the D-03a broad sweep.
- Sequencing: regenerate → review → audit ordering, and how to batch the diff review.
- Coverage-gate handling (≥70% global must stay green) — mechanical.

### Deferred Ideas (OUT OF SCOPE)

- Broader new dark-golden coverage for screens that have NO golden today.
- Authoritative `.pen`↔ADR-018 reconciliation (deferred if MCP cannot persist).
- Migrating off native goldens to `golden_toolkit`/`alchemist`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COLOR-04 | Golden/visual baselines regenerated to the new palette and passing; diffs confirmed as intended (palette change is the only visual delta); full test suite green | Sections: Standard Stack, Architecture Patterns, Golden Re-baseline Workflow, Validation Architecture |
</phase_requirements>

---

## Summary

Phase 33 completed the full `ThemeExtension<AppPalette>` migration (ADR-018 Teal Clarity palette) and app-wide dark-mode rollout. Every widget that reads `context.palette.*` now renders teal colors instead of the old coral/blue/green identity. As a direct consequence, all 50 of the 52 committed master golden PNGs are currently mismatching — this is expected and is exactly what Phase 34 exists to close.

The re-baseline is a four-part operation: (1) diff-review pass to classify each of the 50 failing goldens as palette-delta (→ auto-update) or regression (→ halt and report); (2) add dark variants to the 7 light-only golden test files (D-01/D-01b), which will generate 27 new PNGs; (3) run `--update-goldens` on all auto-approved goldens so the full suite goes green; (4) a comprehensive audit sweep (D-03a) confirming zero stale vocabulary or color-literal debt outside `lib/core/theme/`. The 2 orphaned `summary_cards_*.png` master files have no test and are not failing — they need separate handling.

**Primary recommendation:** Execute in sequence: diff-classify all 50 existing failures → auto-update palette-only deltas → add 7 dark test variants and generate 27 new PNGs → run full audit → verify `flutter test` 0 failures + `flutter analyze` 0 issues + coverage ≥70%.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Golden master PNG storage | `test/golden/goldens/` and sibling `goldens/` dirs | — | Native comparator writes next to test file by relative path |
| Diff artifact generation | `test/*/failures/` (auto, read-only during review) | — | Flutter test framework writes 4 PNGs per mismatch automatically |
| Color token resolution | `lib/core/theme/app_palette.dart` (ThemeExtension) | `AppPaletteContext.palette` fallback | All widget color reads go through `context.palette` |
| Golden test harness | `flutter_test` native `matchesGoldenFile` | — | No `golden_toolkit`/`alchemist` — confirmed by code |
| Audit greps | shell grep (no code change unless stale hit) | — | Scans lib/, test/, docs/ for retired hex and vocabulary |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_test` (SDK) | bundled | Native `matchesGoldenFile` comparator, `failures/` artifact generation | Already in use; no new dep needed |
| `flutter_riverpod` | (project pin) | ProviderScope + overrides in golden test wrappers | Required by ConsumerWidget-based widgets under test |
| `flutter_localizations` | SDK | Localization delegates in every test `_wrap` | All tested widgets read from `S.of(context)` |

No new packages are required for this phase. [VERIFIED: existing pubspec.yaml and all 12 golden test files confirmed]

### Package Legitimacy Audit

> No new external packages are installed in this phase.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
┌────────────────────────────────────────────────────────┐
│                 Phase 34 Re-baseline Flow              │
├────────────────────────────────────────────────────────┤
│  flutter test test/golden/ (NO --update-goldens)       │
│         │                                              │
│         ▼                                              │
│  test/golden/failures/  (4 PNGs per mismatch)          │
│  *_masterImage.png  ← old coral baseline               │
│  *_testImage.png    ← new teal render                  │
│  *_isolatedDiff.png ← pixel diff highlighted           │
│  *_maskedDiff.png   ← diff within tolerance mask       │
│         │                                              │
│         ▼                                              │
│  D-02 Attribution Decision                             │
│  ┌──────────────────────────────┐                      │
│  │ pure palette / D-04 / D-05?  │──YES──► auto-update  │
│  │                              │                      │
│  │ layout shift / contrast err? │──YES──► HALT+REPORT  │
│  └──────────────────────────────┘                      │
│         │ auto-update                                  │
│         ▼                                              │
│  flutter test <file> --update-goldens                  │
│  (selective per golden, NOT bulk --update-goldens)     │
│         │                                              │
│         ▼                                              │
│  D-01/D-01b: Edit 7 light-only test files              │
│  Add themeMode param + dark loop → 27 new PNGs         │
│  flutter test <file> --update-goldens (first-run)      │
│         │                                              │
│         ▼                                              │
│  flutter test (full suite, no --update-goldens)        │
│  ► 0 golden failures + 0 non-golden failures           │
│         │                                              │
│         ▼                                              │
│  D-03a Audit greps (lib/ test/ docs/)                  │
│  D-03b .pen best-effort sync                           │
│         │                                              │
│         ▼                                              │
│  flutter analyze 0 issues + coverage ≥70%             │
└────────────────────────────────────────────────────────┘
```

### Golden File Inventory

**VERIFIED from live filesystem:**

| Test File | Location | Current Master PNGs | Failing? | Dark? |
|-----------|----------|---------------------|----------|-------|
| `amount_display_golden_test.dart` | `test/golden/` | `_cny`, `_jpy`, `_usd` (3) | YES (3) | Light only |
| `daily_vs_joy_card_golden_test.dart` | `test/golden/` | `_light_ja`, `_dark_ja`, `_group_light_ja`, `_group_dark_ja` (4) | YES (4) | Both |
| `home_hero_card_golden_test.dart` | `test/golden/` | 8 files (all `_ja`) | YES (all) | Mixed (1 dark `_family_dark_ja`) |
| `list_calendar_header_golden_test.dart` | `test/golden/` | `_en`, `_ja`, `_zh` (3) | YES (3) | Light only |
| `list_category_filter_sheet_golden_test.dart` | `test/golden/` | `_en`, `_ja`, `_zh` (3) | YES (3) | Light only |
| `list_day_group_header_golden_test.dart` | `test/golden/` | `_en`, `_ja`, `_zh` (3) | YES (3) | Light only |
| `list_empty_state_golden_test.dart` | `test/golden/` | 9 files ({variant}_{locale}) | YES (9) | Light only |
| `list_sort_filter_bar_golden_test.dart` | `test/golden/` | `_en`, `_ja`, `_zh` (3) | YES (3) | Light only |
| `list_transaction_tile_golden_test.dart` | `test/golden/` | `_en`, `_ja`, `_zh` (3) | YES (3) | Light only |
| `per_category_breakdown_card_golden_test.dart` | `test/golden/` | `_light_ja`, `_dark_ja`, `_group_light_ja` (3) | YES (3) | Both |
| `smart_keyboard_golden_test.dart` | `test/widget/…/widgets/` | 6 files ({locale}_{mode}) | YES (6) | Both |
| `voice_input_screen_mic_button_golden_test.dart` | `test/widget/…/screens/` | `_idle` (1) | YES (1) | Light only |

**Orphaned masters (no test file):** `summary_cards_en.png`, `summary_cards_ja.png` — referenced in a comment in `home_hero_card_golden_test.dart` as a prior file pattern, no actual test exists. Planner should add a task to delete these.

**Total currently failing: 50** (43 in `test/golden/failures/` + 6 SmartKeyboard + 1 voice_input_screen)
**Total master PNGs: 52** (45 `test/golden/goldens/` + 6 SmartKeyboard + 1 voice_input, including 2 orphaned)

### Re-baseline Workflow

**Step 1 — Classification run (no `--update-goldens`):**

```bash
# Run only golden test files to populate failures/
flutter test test/golden/ --plain-name "" 2>&1 | tee /tmp/golden_run_1.log

# Run widget golden tests separately (different directory)
flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart 2>&1 | tee -a /tmp/golden_run_1.log
flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart 2>&1 | tee -a /tmp/golden_run_1.log
```

**Step 2 — Per-golden selective update (after diff attribution):**

```bash
# Selective update: one file at a time (D-02b: per-golden, not bulk)
flutter test test/golden/amount_display_golden_test.dart --update-goldens
flutter test test/golden/daily_vs_joy_card_golden_test.dart --update-goldens
# ... per file, only after attribution confirms palette-only delta

# Full file bulk (only AFTER confirming all goldens in that file are palette-only):
flutter test test/golden/ --update-goldens
# WARNING: Do NOT use this until every file in the dir is confirmed palette-only
```

**Step 3 — Targeting a single golden within a file:**
The native harness does not support single-test `--update-goldens` without running the full file. Use `--plain-name` to run a specific test group:

```bash
# Run and update only 'solo light ja' test in daily_vs_joy_card
flutter test test/golden/daily_vs_joy_card_golden_test.dart \
  --update-goldens --plain-name "solo light ja"
```

**Step 4 — Dark variant first-time generation:**
When a dark variant test is added to a file and no master PNG exists, `--update-goldens` creates the PNG (not a diff failure, a "first-time create" path):

```bash
# After editing the test file to add dark variants:
flutter test test/golden/list_day_group_header_golden_test.dart --update-goldens
# This creates the NEW dark PNGs for the first time (no prior master exists)
```

### Dark Variant Addition Pattern (D-01)

**Exemplar:** `test/golden/daily_vs_joy_card_golden_test.dart` [VERIFIED: lines 46-98, 100-146]

The canonical `_wrap` function signature for a dark-capable test:

```dart
// Source: test/golden/daily_vs_joy_card_golden_test.dart (lines 46-98)
Widget _wrap({
  required bool isGroupMode,
  required ThemeMode themeMode,   // ← ADD this parameter
  double width = 360,
  double height = 360,
}) {
  return MaterialApp(
    // ...
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,          // ← ADD both theme + darkTheme + themeMode
    // ...
  );
}
```

**Note on `ThemeData.light()` vs `AppTheme.light`:**
Current exemplars (`daily_vs_joy_card`, `home_hero_card`, `smart_keyboard`) all use `ThemeData.light()/dark()` (NOT `AppTheme.light/dark`). This still delivers the correct ADR-018 teal palette because `AppPaletteContext.palette` has a brightness-aware fallback:

```dart
// Source: lib/core/theme/app_palette.dart (lines 612-616)
AppPalette get palette =>
    Theme.of(this).extension<AppPalette>() ??
    (Theme.of(this).brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light);
```

`ThemeData.light()` has no `AppPalette` extension registered, so `extension<AppPalette>()` returns null → fallback reads `AppPalette.light` (teal). This is why all 50 existing tests are currently FAILING against the old coral masters — the widget renders teal but the master shows coral. The pattern is consistent and correct for this phase.

**Concrete dark variant addition (per D-01b: per-locale):**

For `list_day_group_header_golden_test.dart` [VERIFIED lines 22-38], the `_wrap` currently takes only `locale`. To add dark:

```dart
// BEFORE (light-only):
Widget _wrap({required Locale locale, required Widget child}) {
  return MaterialApp(
    theme: ThemeData.light(),
    // ...
  );
}

// AFTER (dark-capable — copy _wrap parameter pattern from daily_vs_joy_card):
Widget _wrap({
  required Locale locale,
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,    // ← new param, default light
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),            // ← add
    themeMode: themeMode,                  // ← add
    // ...
  );
}

// THEN in main() for each locale, add a dark variant:
testWidgets('locale ja dark', (tester) async {
  await tester.pumpWidget(
    _wrap(
      locale: const Locale('ja'),
      themeMode: ThemeMode.dark,            // ← dark
      child: ListDayGroupHeader(date: _date, locale: const Locale('ja')),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(ListDayGroupHeader),
    matchesGoldenFile('goldens/list_day_group_header_dark_ja.png'), // ← new PNG path
  );
});
```

**Special-case wrappers requiring ProviderScope overrides:**
Some of the 7 light-only files use ProviderScope + provider overrides. The dark parameter threads through without affecting the override pattern:

- `list_sort_filter_bar_golden_test.dart`: ProviderScope with `currentLocaleProvider` override — add `ThemeMode` param to `_wrap`, pass through to `MaterialApp`
- `list_category_filter_sheet_golden_test.dart`: ProviderScope with `categoryRepositoryProvider` + `currentLocaleProvider` — same pattern
- `list_calendar_header_golden_test.dart`: ProviderScope with `listFilterProvider`, `calendarDailyTotalsProvider`, `activeGroupProvider`, `weekStartDayProvider` overrides — same pattern (themeMode param threads through, no conflict with overrides)
- `list_empty_state_golden_test.dart`: ProviderScope with no overrides — simplest case
- `list_transaction_tile_golden_test.dart`: ProviderScope with no overrides; uses `AppPalette.light.*` directly in fixture parameters — for dark variants, these should use `AppPalette.dark.*` values

**D-01b: Per-locale dark file naming convention:**
Follow existing dark golden naming in the project:

| Pattern in existing dark goldens | Example |
|----------------------------------|---------|
| `{widget}_{mode}_{locale}.png` | `daily_vs_joy_card_dark_ja.png` |
| `{widget}_{locale}_{mode}.png` | — (not used) |

Use `{widget}_dark_{locale}.png` to match `daily_vs_joy_card_dark_ja.png` pattern.

**Expected new dark PNGs (27 total):**

| File | New dark PNGs |
|------|---------------|
| `list_day_group_header` | `_dark_en`, `_dark_ja`, `_dark_zh` |
| `amount_display` | `_cny_dark`, `_jpy_dark`, `_usd_dark` |
| `list_sort_filter_bar` | `_dark_en`, `_dark_ja`, `_dark_zh` |
| `list_category_filter_sheet` | `_dark_en`, `_dark_ja`, `_dark_zh` |
| `list_calendar_header` | `_dark_en`, `_dark_ja`, `_dark_zh` |
| `list_transaction_tile` | `_dark_en`, `_dark_ja`, `_dark_zh` |
| `list_empty_state` | `_{variant}_dark_{locale}` × 9 |

### Diff Attribution Reference (D-02)

The three categories of INTENDED delta:

| Category | Root Cause | Visible Effect | Source |
|----------|-----------|----------------|--------|
| ADR-018 palette | Primary accent `#E85A4F` → `#0E9AA7`, daily `#5A9CC8` → `#1C7A86`, joy `#47B88A` → `#F0A81E` | ALL colored elements changed hue | ADR-018 hex table |
| D-04 decorative re-hue | Avatar gradients (`#FFD4CC` teal family), member gradients (`#3D2525` → teal-dark family) | Avatar/member background gradients | `AppPalette.light/dark` static const values |
| D-05 hero gradient | `_joyTargetStartColor #47B88A` → `daily #1C7A86`, `_joyTargetEndColor #D9A441` → `joy #F0A81E` | Target ring in HomeHeroCard changes from green-gold to teal-gold | `33-CONTEXT.md D-05` |

**Failure categories that trigger HALT (D-04):**

| Category | Examples | Action |
|----------|----------|--------|
| Layout shift | Element moved/resized, text overflows | HALT — report as Phase-33 regression |
| Wrong dark color | Dark screen using light token (inadequate contrast) | HALT — report as Phase-33 regression |
| Missing element | Widget completely absent in testImage | HALT — investigate build/provider issue |
| Non-palette color | Color changed but NOT from the old palette set | HALT — check if from D-04/D-05; if not, report |

### Recommended Project Structure (additions for this phase)

No new directories. All new golden PNGs go into existing `test/golden/goldens/` directory.

### Anti-Patterns to Avoid

- **Bulk `flutter test test/golden/ --update-goldens` without prior diff review:** Bypasses D-02 and silently accepts any regression. NEVER do this as first step.
- **Using `--update-goldens` on a test file that has a suspected regression:** Will bake the regression into the master. Always classify diffs first.
- **Adding dark variants with `ThemeMode.system`:** System mode depends on the host OS setting — non-deterministic on CI. Always use `ThemeMode.dark` explicitly.
- **Not deleting `summary_cards_*.png` orphans:** They will never regenerate (no test), and they mislead future auditors about coverage.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Golden diff visualization | Custom diff renderer | Read `failures/` `*_isolatedDiff.png` and `*_maskedDiff.png` | Already generated by Flutter test framework |
| Dark mode pixel comparison | Manual theme inspection | `ThemeMode.dark` + `matchesGoldenFile` | The native comparator detects pixel deltas automatically |
| Hex value scanning | Custom regex scanner | `grep -rn` (POSIX) | Works across all files; no tool overhead |

---

## Old-Palette Hex Inventory for D-03a Audit

[VERIFIED: derived from `docs/design/flutter_color_mapping.dart` — the pre-ADR-018 color mapping file committed to the repo]

**Retired hex values to grep for OUTSIDE `lib/core/theme/`:**

```bash
# Primary old-palette hex (core coral + dual-ledger):
grep -rn "E85A4F\|5A9CC8\|47B88A" lib/ test/ docs/ \
  --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"

# Extended old-palette (olive/terracotta/shared from WaModernLight):
grep -rn "8A9178\|D4845A\|F08070\|FFF0E0\|F0DCC8\|D4B89A\|C8E6D5\|F0FAF4" \
  lib/ test/ docs/ \
  --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"

# Old dark backgrounds (WaModernDark):
grep -rn "1A1D27\|252836\|353845\|1E2130\|6B6E7A" \
  lib/ test/ docs/ \
  --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"
```

**Known current stale hits (discovered in research — D-03a will find these):**

| File | Hex | Context | Action |
|------|-----|---------|--------|
| `test/widget/features/accounting/presentation/widgets/transaction_details_form_test.dart` | `#E85A4F` | `Category.color` string field in fixture — this is test DATA, not a `Color(0x...)` literal | Review: if rendered as widget color, update; if pure data field string, acceptable |
| `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart` | `#E85A4F` | `Category.color` string field in fixture | Same as above |
| `test/widget/features/accounting/presentation/screens/manual_one_step_screen_test.dart` | `#E85A4F` | `Category.color` string field | Same as above |
| `test/widget/features/home/presentation/widgets/home_transaction_tile_test.dart` | `Color(0xFF5A9CC8)`, `Color(0xFF47B88A)` | `tagTextColor`/`joyGreen` constant passed as widget param | **Stale** — should be updated to `AppPalette.light.daily`/`.joy` |
| `test/widget/features/list/list_transaction_tile_test.dart` | `Color(0xFF5A9CC8)` | `tagTextColor`, `categoryColor` params | **Stale** — should be updated to `AppPalette.light.daily` |
| `test/widget/features/list/list_category_filter_sheet_test.dart` | `#E85A4F` | `Category.color` string field | Data field, not Color literal |
| `test/integration/entry_path_stamping_test.dart` | `#47B88A` | `Category.color` string field | Data field |
| `test/integration/features/accounting/manual_save_entry_source_test.dart` | `#47B88A` | `Category.color` string field | Data field |
| `docs/design/README.md` | `#E85A4F`, `#5A9CC8`, `#47B88A` | Historical color table — documents the old palette | **Stale doc** — update to ADR-018 palette |
| `docs/design/design-tokens.json` | Many old hex values | Pre-migration token file | **Stale doc** — update or annotate as superseded by ADR-018 |
| `docs/design/flutter_color_mapping.dart` | All old hex values | Pre-migration mapping reference | **Stale doc** — update or annotate as superseded |
| `docs/design/design-system.md` | Many old hex values | Pre-migration design system doc | **Stale doc** — update or annotate |
| `docs/design/screen-inventory.md` | Old hex in color table | Pre-migration inventory | **Stale doc** — update or annotate |

**Classification distinction for audit:**
- `Category.color` is a database-backed string field (`'#E85A4F'`). It does NOT drive UI color rendering directly — `CategoryService` maps category IDs to icon/color through `CategoryLocaleService`, which uses ARB-mapped category names, not the stored hex string. These string literals in test fixtures are fixture data, not color literals. D-03a ROADMAP grep (`Color(0x`) will NOT catch them. The broader D-03a sweep may surface them; the planner should confirm they are inert before discarding.
- `Color(0xFF5A9CC8)` in test files IS a `Color` constructor literal and SHOULD be updated per D-03a.

---

## Common Pitfalls

### Pitfall 1: Bulk `--update-goldens` before diff review

**What goes wrong:** All 50+ diffing goldens are updated in one shot, baking any Phase-33 regressions (layout shifts, contrast failures) into the new masters. The golden's purpose — catching regressions — is destroyed for those files.
**Why it happens:** The `flutter test --update-goldens` command runs on all matched tests unconditionally.
**How to avoid:** D-02 mandates classification first. Run without `--update-goldens`, inspect `failures/` PNGs, then update selectively per file.
**Warning signs:** Running `flutter test test/golden/ --update-goldens` as the first command of the phase.

### Pitfall 2: Golden non-determinism from `DateTime.now()`

**What goes wrong:** A widget calls `DateTime.now()` during build; the golden looks different depending on time of day, day of week, or CI schedule. The test passes locally but fails on CI.
**Why it happens:** `isToday` decoration in `list_calendar_header.dart` line 142.
**How to avoid:** `list_calendar_header_golden_test.dart` already has the determinism fix (D-03): it overrides `listFilterProvider` to `_FixedListFilter()` pinned to January 2025 (always in the past relative to CI running 2026+). Dark variants MUST reuse the same `_FixedListFilter()` override. Do not remove this override when adding dark variants.
**Warning signs:** The `_masterImage.png` looks correct but CI output `_testImage.png` shows a different day highlighted.

### Pitfall 3: Dark theme test without `darkTheme` parameter

**What goes wrong:** `MaterialApp` is given `themeMode: ThemeMode.dark` but no `darkTheme:` — it silently falls back to the light theme. The golden appears to render correctly in light colors, and the test passes green, but it's not actually testing dark mode.
**Why it happens:** `MaterialApp.darkTheme` is optional; omitting it with `ThemeMode.dark` = silent fallback.
**How to avoid:** Always provide BOTH `theme: ThemeData.light()` AND `darkTheme: ThemeData.dark()` alongside `themeMode: themeMode`. The `daily_vs_joy_card` exemplar has both.
**Warning signs:** Dark golden looks identical to light golden in every pixel.

### Pitfall 4: `list_transaction_tile` fixture uses `AppPalette.light.*` — dark variant needs `AppPalette.dark.*`

**What goes wrong:** `list_transaction_tile_golden_test.dart` passes `tagBgColor: AppPalette.light.dailyLight`, `tagTextColor: AppPalette.light.daily`, `categoryColor: AppPalette.light.daily` as hardcoded constructor params [VERIFIED lines 69-72]. In dark mode the widget is wrapped in a dark `MaterialApp` but these fixture-injected color values remain light — the tile renders dark background with light-palette tag colors, which is incorrect and will NOT match what production renders.
**Why it happens:** The tile accepts explicit color parameters, bypassing `context.palette` resolution for those tokens.
**How to avoid:** The dark variant of `list_transaction_tile` should pass `AppPalette.dark.dailyLight`, `AppPalette.dark.daily` etc. as the corresponding constructor parameters.
**Warning signs:** Dark golden shows a dark card background but light-teal/light-gold tag colors (high contrast, looks "wrong").

### Pitfall 5: `per_category_breakdown_card` dark test uses `ThemeData.dark()` directly, not `themeMode`

**What goes wrong:** The dark test in `per_category_breakdown_card_golden_test.dart` passes `theme: ThemeData.dark()` to `_wrap`, which sets `theme:` (not `darkTheme:`) to the dark data. This works because `MaterialApp.theme` IS the theme regardless of brightness, but it's inconsistent with the `themeMode: ThemeMode.dark` pattern. The inconsistency means the `_wrap` function signature differs between this file and others.
**Why it matters:** When adding dark variants to the 7 light-only files, use the `themeMode` pattern (from `daily_vs_joy_card`) not the `theme: ThemeData.dark()` pattern (from `per_category_breakdown_card`) for consistency.
**Warning signs:** Dark test functions with `theme: ThemeData.dark()` parameter directly rather than `themeMode: ThemeMode.dark`.

### Pitfall 6: `voice_input_screen_mic_button` golden is light-only by design (not a gap)

**What goes wrong:** Treating the voice_input golden as a gap requiring a dark variant.
**Why it happens:** Its docstring explicitly says single theme (light) is sufficient for the mic button gradient/shape — the recording decoration (dark vs light) is tested by decoration introspection in `voice_input_screen_test.dart`, not by golden.
**How to avoid:** `voice_input_screen_mic_button_golden_test.dart` is NOT in the D-01 list of 7 files needing dark variants. Only the 7 listed files get dark variants.

### Pitfall 7: `amount_display` golden test does NOT use `themeMode` — light-only by widget design

**What goes wrong:** `amount_display_golden_test.dart` uses a `_wrap` that only accepts `locale`, no `ThemeMode` [VERIFIED lines 12-27]. `AmountDisplay` widget renders with `AppTextStyles.amountLarge/Medium/Small` which use `tabularFigures` — the color is likely applied via `context.palette.dailyText` or similar.
**Why it matters:** When adding dark variants to `amount_display`, verify whether `AmountDisplay` actually reads `context.palette` at all. If it renders a fixed color regardless of theme, the dark golden will be identical to the light golden — which may be correct (pure typography widget). Investigate before adding dark variants.
**Warning signs:** `amount_display` dark and light goldens are pixel-identical.

### Pitfall 8: `summary_cards_*.png` are orphaned — no test exists

**What goes wrong:** The two PNG files `goldens/summary_cards_en.png` and `goldens/summary_cards_ja.png` exist in `test/golden/goldens/` but there is no `summary_cards_golden_test.dart` anywhere in the project [VERIFIED]. They are NOT failing because there is no test to generate a mismatch.
**Why it happened:** The original `summary_cards_golden_test.dart` was likely deleted (or superseded by `home_hero_card_golden_test.dart`) but the PNG masters were not cleaned up.
**How to avoid:** Delete both PNGs. They will never be regenerated by any test and mislead coverage audits.
**Warning signs:** `ls test/golden/goldens/ | wc -l` returns 45 but only 43 tests exist — the 2 difference are the orphans.

---

## Runtime State Inventory

> This is a greenfield-within-brownfield re-baseline phase (no rename/migration/refactor of stored data). Omitted.

---

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK bundled) |
| Config file | none — `flutter test` CLI is the runner |
| Golden run command (classification) | `flutter test test/golden/ && flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart && flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` |
| Golden update command (selective) | `flutter test <file> --update-goldens` |
| Full suite (non-golden) | `flutter test --exclude-tags golden` |
| Full suite (all) | `flutter test` |
| Analyze | `flutter analyze` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COLOR-04 | All goldens regenerated, 0 mismatches | golden | `flutter test test/golden/` (all 10 files) | ✅ |
| COLOR-04 | SmartKeyboard goldens green | golden | `flutter test test/widget/features/accounting/presentation/widgets/smart_keyboard_golden_test.dart` | ✅ |
| COLOR-04 | Voice input golden green | golden | `flutter test test/widget/features/accounting/presentation/screens/voice_input_screen_mic_button_golden_test.dart` | ✅ |
| COLOR-04 | New dark goldens for 7 light-only files | golden | `flutter test test/golden/ --update-goldens` (after editing 7 files) | ❌ Wave 0: edit 7 test files |
| COLOR-04 | Diff confirms palette-only delta | manual review | Read `failures/*_isolatedDiff.png` and `*_maskedDiff.png` | ✅ (generated on mismatch) |
| COLOR-04 | No stale ARB vocabulary | grep | `grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb` = 0 | ✅ |
| COLOR-04 | No raw hex literals in feature code | grep | `grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/` = 0 | ✅ |
| COLOR-04 | Full suite green | unit + integration | `flutter test --exclude-tags golden` | ✅ |
| COLOR-04 | Analyzer clean | static analysis | `flutter analyze` | ✅ |
| COLOR-04 | Coverage ≥70% | coverage | `flutter test --coverage` + lcov summary | ✅ |

### Success-Criteria Greps (ROADMAP verbatim)

```bash
# Success Criterion 2 — vocabulary audit
grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' lib/l10n/*.arb
# Expected output: (empty)

# Success Criterion 2 — color literal audit  
grep -rn 'Color(0x\|Color(0X' lib/features/ lib/application/ lib/shared/
# Expected output: (empty)

# Success Criterion 3 — static analysis
flutter analyze
# Expected: 0 issues

# Success Criterion 3 — coverage
flutter test --coverage
# Expected: ≥70% global line coverage
```

### D-03a Comprehensive Audit Commands

```bash
# Old-palette hex literals (outside lib/core/theme/):
grep -rn "E85A4F\|5A9CC8\|47B88A\|8A9178\|D4845A\|F08070" \
  lib/ test/ docs/ \
  --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"

# Extended old hex (dark backgrounds, terracotta tints):
grep -rn "1A1D27\|252836\|353845\|1E2130\|6B6E7A\|3D2525\|5A3535\|1E3028" \
  lib/ test/ docs/ \
  --include="*.dart" --include="*.json" --include="*.md" \
  --exclude-dir="lib/core/theme"

# Stale vocabulary in test/ and docs/ (not just lib/l10n/):
grep -rn '生存\|灵魂\|魂\|ソウル\|Survival\|Soul' test/ docs/
```

### Sampling Rate

- **Per task commit:** Run the specific golden file(s) touched + `flutter analyze`
- **Per wave merge:** `flutter test` (full suite including goldens) + coverage check
- **Phase gate:** Full suite green, `flutter analyze` 0 issues, coverage ≥70%, both success-criteria greps return empty, before `/gsd-verify-work`

### Wave 0 Gaps

The following test infrastructure changes are required before implementation tasks can proceed:

- [ ] Edit 7 light-only golden test files to add `themeMode` parameter to `_wrap`:
  - `test/golden/list_day_group_header_golden_test.dart`
  - `test/golden/amount_display_golden_test.dart`
  - `test/golden/list_sort_filter_bar_golden_test.dart`
  - `test/golden/list_category_filter_sheet_golden_test.dart`
  - `test/golden/list_calendar_header_golden_test.dart`
  - `test/golden/list_transaction_tile_golden_test.dart`
  - `test/golden/list_empty_state_golden_test.dart`
- [ ] For `list_transaction_tile`: update dark variant fixture to use `AppPalette.dark.*` params
- [ ] Delete orphaned `test/golden/goldens/summary_cards_en.png` and `summary_cards_ja.png`
- [ ] Verify `amount_display` widget reads `context.palette` (decide if dark variant makes visual difference before adding it)

---

## Project Constraints (from CLAUDE.md)

| Directive | Enforcement |
|-----------|-------------|
| `flutter analyze` 0 issues before commit | Hard gate — run after any test file edit |
| `flutter test --coverage` ≥80% (CLAUDE.md); ≥70% (CONTEXT.md phase gate) | Phase gate is ≥70%; project standard is ≥80% |
| Run `build_runner` after modifying `@riverpod`/`@freezed`/Drift/ARB — AUDIT-10 | This phase does NOT touch generated files; no `build_runner` run needed |
| Don't modify `.g.dart`/`.freezed.dart` | No generated files touched in this phase |
| `sqlcipher_flutter_libs` only, NOT `sqlite3_flutter_libs` | No new packages added in this phase |
| All UI text via `S.of(context)` — never hardcode strings | Golden test fixtures may use fixture strings; not impacted |
| No `@riverpod` changes in this phase | Confirmed: no provider changes needed |

**Coverage threshold conflict:** CLAUDE.md states ≥80%; CONTEXT.md and ROADMAP Phase 34 success criterion states ≥70%. The phase-specific ≥70% gate applies as the immediate milestone bar. The planner should note this discrepancy — passing ≥70% closes COLOR-04, but the project standard of ≥80% remains a future obligation (FUTURE-TOOL-03).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter` CLI | All test/analyze commands | ✓ | confirmed (project in active development) | — |
| `flutter test --update-goldens` | Re-baseline | ✓ | bundled with flutter | — |
| `grep` POSIX | D-03a audit | ✓ | macOS built-in | — |
| `git` | Phase commit | ✓ | (git repo confirmed) | — |
| Pencil MCP | D-03b `.pen` sync | Known-constrained | Cannot flush to disk | Mark as deferred (D-03b) |

**Missing dependencies with no fallback:** none

**Missing dependencies with fallback:**
- Pencil MCP flush (D-03b): MCP can read `.pen` but cannot persist writes to disk. Fallback is to skip `.pen` update and mark as deferred in phase close notes.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static const `AppColors`/`AppColorsDark` + `AppThemeColors` context extension | `ThemeExtension<AppPalette>` with `context.palette.*` | Phase 33 (2026-06-01) | All goldens now failing against old coral-based masters |
| Old `app_colors.dart` shim (deleted by Plan 33-07) | Only `lib/core/theme/app_palette.dart` remains | Phase 33 | No `AppColors.` refs anywhere in lib/ |
| Coral `#E85A4F` primary | Teal `#0E9AA7` primary | Phase 33 | Every colored element changed hue |
| Green-gold hero gradient (`#47B88A`→`#D9A441`) | Teal-gold hero gradient (`#1C7A86`→`#F0A81E`) | Phase 33 D-05 | `home_hero_card` golden will show gradient delta |
| 5 of 12 golden files had dark variants | 12 of 12 golden files have dark variants | Phase 34 (this phase) | +27 new golden PNGs |

**Deprecated/outdated:**

- `AppColors` / `AppColorsDark` classes: DELETED by Plan 33-07. Any grep for `AppColors.` in `lib/` should return 0. [VERIFIED: 33-07-PLAN.md confirms deletion]
- `app_theme_colors.dart`: DELETED by Plan 33-07. `context.wm*` getter pattern is gone.
- Old `summary_cards_golden_test.dart`: deleted at some point in project history. The 2 orphaned PNGs are the only remnant.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All 50 failures are attributable to palette change (none are Phase-33 regressions) | Architecture Patterns | If any are real regressions, D-04 halt protocol applies — extra investigation work, but designed for |
| A2 | `ThemeData.light()/dark()` with `AppPaletteContext.palette` fallback delivers correct ADR-018 colors in golden tests (no need to migrate test `_wrap` functions to `AppTheme.light/dark`) | Dark Variant Addition Pattern | If some widget reads `Theme.of(ctx).extension<AppPalette>()` WITHOUT the null-fallback pattern, it would return null and crash under `ThemeData.light()`. Risk is low — confirmed fallback in `app_palette.dart` line 612 |
| A3 | `amount_display` renders a dark-visible difference (worth adding dark variant) | Pitfall 7 | If the widget renders no color that changes with theme, dark variants are identical pixel-for-pixel — they would still be valid but uninformative goldens |
| A4 | The `Category.color` string field occurrences in test fixtures (`'#E85A4F'`) are pure data not rendered as `Color()` — they do not affect visual output | D-03a Audit section | If `CategoryLocaleService` or any widget path renders this string as a color, there would be a stale visual in test fixture renders |

---

## Open Questions

1. **`amount_display` dark variant visibility**
   - What we know: `AmountDisplay` uses `AppTextStyles.amountLarge` etc. These styles read `color` from the calling context or are plain `TextStyle` with no color.
   - What's unclear: Does `AmountDisplay` pass any `context.palette.*` color to the amount text, or is the text color set externally?
   - Recommendation: Before adding dark variants, grep `lib/features/accounting/presentation/widgets/amount_display.dart` for `context.palette`. If zero hits, the widget is color-agnostic (dark variant = same as light) — still add for completeness per D-01b, but expect identical output.

2. **Coverage delta from +27 new dark golden PNGs**
   - What we know: New golden tests call `pumpAndSettle` + `expectLater` on existing widgets. They exercise the same widget code paths as light variants but via `ThemeMode.dark`.
   - What's unclear: Whether the dark `context.palette.*` code paths in the 7 newly-dark-covered widgets are currently uncovered (would increase coverage) or already covered by existing unit/widget tests.
   - Recommendation: Run coverage after adding dark variants and compare to baseline. If coverage improves past 70%, the gate is met with margin.

3. **`home_hero_card` single-mode tests are light-only (8 tests, 0 dark variants for single mode)**
   - What we know: `home_hero_card_golden_test.dart` has 8 tests; only `family_dark_ja` is dark. Single-mode (5 variants), thin (1), all-neutral (1) are light-only — but `home_hero_card` is NOT in the D-01 list of 7 files to fix.
   - What's unclear: Is this intentional exclusion or an oversight in the D-01 list?
   - Recommendation: CONTEXT.md D-01 explicitly lists 7 files. `home_hero_card` is not in the list. The planner should confirm this is correct scoping. Do NOT add dark variants to `home_hero_card` single-mode tests without user confirmation.

---

## Sources

### Primary (HIGH confidence)

- `test/golden/daily_vs_joy_card_golden_test.dart` — canonical dark variant wrapper pattern (lines 46-98)
- `lib/core/theme/app_palette.dart` — ThemeExtension definition, `AppPaletteContext.palette` fallback (lines 612-616)
- `lib/core/theme/app_theme.dart` — `AppTheme.light/dark` ThemeData with `extensions: const [AppPalette.light/dark]`
- `docs/arch/03-adr/ADR-018_Palette_Selection_v1_5.md` — locked ADR-018 hex table (light + dark)
- `.planning/phases/34-golden-re-baseline-verification/34-CONTEXT.md` — all D-01 through D-04 decisions
- `.planning/ROADMAP.md` §"Phase 34" — 3 success criteria + canonical grep commands
- All 12 golden test files — verified actual file contents for wrapper patterns, locales, PNG naming

### Secondary (MEDIUM confidence)

- `.planning/phases/33-color-token-system-consolidation/33-CONTEXT.md` — intended delta categories (D-04 decorative re-hue, D-05 hero gradient)
- `docs/design/flutter_color_mapping.dart` — complete old-palette hex inventory for D-03a
- Live `test/golden/failures/` directory — confirmed 43 currently failing goldens in `test/golden/`, plus 6 SmartKeyboard + 1 voice_input

### Tertiary (LOW confidence)

- Inferred `summary_cards` orphan status from absence of test file + comment reference in `home_hero_card_golden_test.dart:21`

---

## Metadata

**Confidence breakdown:**
- Golden harness workflow: HIGH — verified from all 12 test files and live `failures/` directory
- Dark variant pattern: HIGH — derived from 3 working exemplars in codebase
- D-03a audit inventory: HIGH — derived from committed `flutter_color_mapping.dart` and live grep results
- Pitfalls: HIGH — derived directly from reading test file contents
- Coverage gate: MEDIUM — 70% threshold from CONTEXT.md is phase-specific; project standard (CLAUDE.md) is 80%

**Research date:** 2026-06-01
**Valid until:** 2026-07-01 (stable Flutter test framework; golden infra does not change)
