# Phase 35: Close Vocab Leaks (W1 + W2) — Research

**Researched:** 2026-06-02
**Domain:** Flutter — i18n / Semantics a11y labels (W1) + Freezed model field rename (W2)
**Confidence:** HIGH — all claims verified by direct file inspection

---

## Summary

Phase 35 is a mechanical two-workstream vocabulary cleanup, the final task before closing the v1.5 「文案与配色統一」milestone. Both leaks were discovered by the milestone audit and are narrow, fully enumerated, and internally consistent.

**W1 (user-facing, highest priority):** Two hardcoded `Semantics(label: '...')` strings in `list_sort_filter_bar.dart` announce stale vocabulary ("Survival ledger" / "Soul ledger") to screen readers. The widget's visible chip labels are already correct via `l10n.listLedgerDaily` / `l10n.listLedgerJoy`. The fix is a 2-line change reusing (or adding) ARB keys — `context` and `l10n = S.of(context)` are already live in the same `build()` method.

**W2 (internal identifiers, mechanical):** Two Freezed model fields — `totalSoulTx` in `HappinessReport` and `totalGroupSoulTx` in `FamilyHappiness` — plus local variables, use-case bodies, provider helpers, widget consumers, all test fixtures, and unit/widget tests that reference these names. None are persisted to the DB or exposed as JSON keys. The rename target is `totalSoulTx` → `totalJoyTx` and `totalGroupSoulTx` → `totalGroupJoyTx`. After editing the two `.dart` source files, `build_runner` regenerates the two `.freezed.dart` files; then every consumer (5 non-generated lib files + 9 test files) must be updated.

**Primary recommendation:** Execute W1 first (2-line code change + optional ARB addition + `flutter gen-l10n`), then W2 (rename source fields → build_runner → update consumers + tests), verify with `grep -rn 'SoulTx' lib/` and `flutter analyze`.

---

## Project Constraints (from CLAUDE.md)

- All UI text via `S.of(context)` — never hardcode strings
- Update ALL 3 ARB files when adding translations, then run `flutter gen-l10n`
- Output class is `S`, generated in `lib/generated/`
- `flutter analyze` MUST be 0 issues before commit (zero warnings rule)
- Do not modify generated files (`.freezed.dart`) — regenerate via `build_runner`
- Always run `build_runner` after modifying `@freezed` classes
- Dart format required

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| W1: Semantics a11y labels | Presentation (list feature widget) | — | Labels are widget-layer concerns; l10n is already available at call site |
| W1: ARB key addition | i18n (l10n ARB files) | Presentation (consumes S.of) | Adding new localization strings is an i18n concern |
| W2: Freezed model field rename | Domain (analytics feature models) | Application (use-case consumers) | HappinessReport / FamilyHappiness live in `lib/features/analytics/domain/models/` |
| W2: Use-case body rename | Application (analytics use cases) | — | `get_happiness_report_use_case.dart` / `get_family_happiness_use_case.dart` in `lib/application/analytics/` |
| W2: Presentation consumers | Presentation (analytics feature) | — | `analytics_screen.dart`, `joy_headline_kpi_tile.dart`, `state_happiness.dart` |

---

## W1: Ground Truth — Semantics Labels

### Exact file and line numbers

**File:** `lib/features/list/presentation/widgets/list_sort_filter_bar.dart`

```dart
// Line 235–265: 日常 chip
Semantics(
  label: 'Survival ledger',           // ← LINE 236: stale + hardcoded
  selected: filter.ledgerType == LedgerType.daily,
  child: ActionChip(
    label: Text(
      l10n.listLedgerDaily,           // visible label already correct
      ...
    ),
    ...
  ),
),

// Line 268–298: ときめき chip
Semantics(
  label: 'Soul ledger',               // ← LINE 269: stale + hardcoded
  selected: filter.ledgerType == LedgerType.joy,
  child: ActionChip(
    label: Text(
      l10n.listLedgerJoy,             // visible label already correct
      ...
    ),
    ...
  ),
),
```

**Note:** Line 209–232 also has `Semantics(label: 'Show all ledgers', ...)` which is hardcoded but is NOT stale vocabulary (it was never part of the Survival/Soul rename). The audit scope covers only lines 236 and 269. The "Show all ledgers" chip is out of scope per the audit's W1 definition, but see Optional Extension below.

### Context / l10n availability at call sites

The widget is `ConsumerStatefulWidget`. The `build()` method begins:
```dart
@override
Widget build(BuildContext context) {   // LINE 124 — context available
  final palette = context.palette;
  final filter = ref.watch(listFilterProvider);
  final l10n = S.of(context);         // LINE 127 — l10n already live
  ...
```

`S.of(context)` is already assigned to `l10n` at the top of `build()`. Both Semantics calls are inside the `build()` tree. No additional plumbing is needed — `l10n` is directly usable.

---

## W1: ARB Keys — Analysis and Recommendation

### Existing keys (confirmed in all 3 ARBs)

| Key | ja | zh | en | Purpose |
|-----|----|----|----|---------| 
| `listLedgerAll` | すべて | 全部 | All | All-ledger chip visible label |
| `listLedgerDaily` | 日常 | 日常 | Daily | Daily chip visible label |
| `listLedgerJoy` | ときめき | 悦己 | Joy | Joy chip visible label |

No a11y-specific ARB keys exist yet (confirmed: grep for `listLedgerDailyA11y`, `listLedgerJoyA11y`, `a11yLabel` returns no results).

### Recommendation: REUSE existing keys

The existing `listLedgerDaily` / `listLedgerJoy` values are appropriate as screen-reader labels. The Japanese values "日常" and "ときめき" are the v1.5-canonical vocabulary, zh is "日常" / "悦己", en is "Daily" / "Joy". Screen readers announce chip labels alongside their selected state — the visible label text IS the correct a11y label.

**Fix (2-line change):**
```dart
// Line 236: was 'Survival ledger'
Semantics(
  label: l10n.listLedgerDaily,    // reuse existing key
  selected: filter.ledgerType == LedgerType.daily,
  ...
)

// Line 269: was 'Soul ledger'
Semantics(
  label: l10n.listLedgerJoy,     // reuse existing key
  selected: filter.ledgerType == LedgerType.joy,
  ...
)
```

**No new ARB keys needed. No `flutter gen-l10n` step required for this approach.** The generated `S` class already exposes `listLedgerDaily` and `listLedgerJoy`.

**Alternative (if planner wants more descriptive a11y labels):** Add `listLedgerDailySemantics` / `listLedgerJoySemantics` keys with values like "日常帳簿フィルター" / "ときめき帳簿フィルター". This is optional — the reuse approach is simpler and consistent with how the chip's visible label already communicates meaning. If added, all 3 ARBs must be updated and `flutter gen-l10n` run.

---

## W2: Ground Truth — totalSoulTx / totalGroupSoulTx

### Complete occurrence inventory

**`totalSoulTx` — lib/ non-generated files (6 occurrences in 3 files):**

| File | Lines | Type |
|------|-------|------|
| `lib/features/analytics/domain/models/happiness_report.dart` | 20 | Freezed `@freezed` model field definition — REQUIRES build_runner regen |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | 529 | Field access on `HappinessReport` instance |
| `lib/features/analytics/presentation/widgets/joy_headline_kpi_tile.dart` | 52, 78, 84 | Field access on `HappinessReport` instance (3 references) |
| `lib/application/analytics/get_happiness_report_use_case.dart` | 70, 72, 73, 78, 96, 97, 98, 99, 100, 101 | Local variable `totalSoulTx` + named constructor arg |

**`totalSoulTx` — doc comment only (not a code identifier):**

| File | Line | Status |
|------|------|--------|
| `lib/application/analytics/get_best_joy_moment_use_case.dart` | 10 | Doc comment only: `/// Returns Value(row, totalSoulTx) otherwise.` — update for clarity but NOT a compile error |

**`totalGroupSoulTx` — lib/ non-generated files (occurrences in 4 files):**

| File | Lines | Type |
|------|-------|------|
| `lib/features/analytics/domain/models/family_happiness.dart` | 19 | Freezed `@freezed` model field definition — REQUIRES build_runner regen |
| `lib/features/analytics/presentation/providers/state_happiness.dart` | 141 | Named constructor arg in `_emptyFamilyHappiness` helper |
| `lib/application/analytics/get_family_happiness_use_case.dart` | 37, 71, 77, 81, 100, 106, 107, 109 | Local variable `totalGroupSoulTx` + named constructor args |

### Generated files — do NOT edit manually

`lib/features/analytics/domain/models/happiness_report.freezed.dart` and
`lib/features/analytics/domain/models/family_happiness.freezed.dart` contain many references (confirmed). Both are pure Freezed (no JSON serialization — no `.g.dart` files for these two models). They are regenerated by `build_runner` after editing the source `.dart` files. Do not edit them directly.

### DB persistence check

`totalSoulTx` and `totalGroupSoulTx` are NOT in any Drift table definition or DAO. They are in-memory computed fields inside `HappinessReport` / `FamilyHappiness` model classes. Confirmed: no `@JsonKey`, no column annotation, no serialization. Renaming is safe with no DB migration.

### Rename targets

| Old | New | Rationale |
|-----|-----|-----------|
| `totalSoulTx` | `totalJoyTx` | Consistent with Soul→Joy vocabulary shift |
| `totalGroupSoulTx` | `totalGroupJoyTx` | Consistent; "group" prefix preserved |

### Test files requiring updates (confirmed by grep)

| File | References |
|------|-----------|
| `test/unit/features/analytics/domain/models/happiness_report_test.dart` | `totalSoulTx` (3 occurrences), `totalGroupSoulTx` (3 occurrences) |
| `test/unit/features/analytics/presentation/providers/repository_providers_test.dart` | `totalGroupSoulTx` (2 occurrences) |
| `test/unit/application/analytics/get_family_happiness_use_case_test.dart` | `totalGroupSoulTx` (3 occurrences) |
| `test/unit/application/analytics/get_happiness_report_use_case_test.dart` | `totalSoulTx` (1 occurrence) |
| `test/helpers/happiness_test_fixtures.dart` | `totalSoulTx` (4 occurrences), `totalGroupSoulTx` (2 occurrences) |
| `test/widget/features/analytics/presentation/widgets/joy_headline_kpi_tile_test.dart` | `totalSoulTx` (3 occurrences) |
| `test/widget/features/analytics/presentation/widgets/kpi_mini_hero_strip_test.dart` | `totalSoulTx` (1 occurrence) |
| `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` | `totalGroupSoulTx` (2 occurrences) |
| `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` | String `'totalSoulTx == 0'` in test name (1 occurrence — test description string, not a field access) |

**Total test file changes needed: 9 files**

---

## Architecture Patterns

### Standard Stack (no new packages needed)

This phase introduces zero new dependencies. All operations use:
- `S.of(context)` — existing l10n pattern (project standard)
- Freezed `@freezed` code generation — existing pattern
- `flutter pub run build_runner build --delete-conflicting-outputs` — existing regen command
- `dart format .` + `flutter analyze` — existing quality gates

### Recommended File Edit Sequence

**W1 (single file, no regen):**
1. Edit `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — replace lines 236 and 269
2. `dart format lib/features/list/presentation/widgets/list_sort_filter_bar.dart`
3. `flutter analyze` — verify 0 new issues

**W2 (source → regen → consumers → tests):**
1. Edit `lib/features/analytics/domain/models/happiness_report.dart` — rename field
2. Edit `lib/features/analytics/domain/models/family_happiness.dart` — rename field
3. `flutter pub run build_runner build --delete-conflicting-outputs` — regenerates both `.freezed.dart` files
4. Update all lib/ consumer files (analytics_screen.dart, joy_headline_kpi_tile.dart, state_happiness.dart, get_happiness_report_use_case.dart, get_family_happiness_use_case.dart)
5. Update doc comment in get_best_joy_moment_use_case.dart (line 10)
6. Update all 9 test files
7. `dart format .`
8. `flutter analyze` — verify 0 new issues
9. `flutter test` — verify 2281+ tests pass

### Rename Approach

Both identifiers are Dart field names and local variable names — NOT cross-language or cross-service. The safest approach is **Dart IDE rename (Serena `rename_symbol`)** for the Freezed model field (which cascades to all references in the same Dart scope), followed by manual update of the generated file path (which `build_runner` handles automatically).

**Alternative (reliable fallback):** Manual find-replace `totalSoulTx` → `totalJoyTx` and `totalGroupSoulTx` → `totalGroupJoyTx` across `lib/` and `test/`, being careful to:
- Skip `.freezed.dart` files (will be regenerated)
- Update doc comment in `get_best_joy_moment_use_case.dart:10` separately
- Update test description string in `home_hero_card_test.dart` separately (it is a string literal, not a field reference)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| i18n string | Hardcoded English string in Semantics | `S.of(context).listLedgerDaily` / `listLedgerJoy` |
| Freezed model update | Manual edit of `.freezed.dart` | `flutter pub run build_runner build --delete-conflicting-outputs` |

---

## Common Pitfalls

### Pitfall 1: Editing `.freezed.dart` directly
**What goes wrong:** Manual edits to `.freezed.dart` are overwritten on next `build_runner` run, creating a hard-to-debug inconsistency.
**Prevention:** Only edit the `@freezed` source file (`.dart`), then run `build_runner`.

### Pitfall 2: Missing build_runner after Freezed rename
**What goes wrong:** The source `.dart` field is renamed but the `.freezed.dart` generated file still exposes the old name — Dart analyzer reports "undefined getter" on the old name everywhere, or (if you forgot to rename the source too) on the new name.
**Prevention:** Always run `flutter pub run build_runner build --delete-conflicting-outputs` immediately after editing any `@freezed` class. Confirm both generated files are updated.

### Pitfall 3: Partial rename (missing test files)
**What goes wrong:** `flutter analyze` passes (lib/ is clean) but `flutter test` fails because test files still reference old field names.
**Prevention:** Run `grep -rn 'SoulTx' test/` after updating lib/ to catch remaining references before running the full suite.

### Pitfall 4: Skipping dart format before analyze
**What goes wrong:** Manual edits can leave style violations that `flutter analyze` surfaces as warnings, creating confusion about root cause.
**Prevention:** Run `dart format .` before `flutter analyze` every time.

### Pitfall 5: Test description string vs field access confusion
**What goes wrong:** `grep -rn 'totalSoulTx' test/` finds `'totalSoulTx == 0: ...'` in `home_hero_card_test.dart:354` — this is a string literal in a test description (`testWidgets('totalSoulTx == 0: ...')`) not a field access. Not a compile error but should be updated for consistency.
**Prevention:** Treat it as a doc update, not a compile fix. Rename to `'totalJoyTx == 0: ...'` in the test description string.

---

## Verification Gates

### W1 Verification

```bash
# Gate 1: No hardcoded stale Semantics strings remain
grep -rn "'Survival ledger'\|'Soul ledger'" lib/
# Expected: 0 results

# Gate 2: Semantics labels route through l10n (positive check)
grep -n "listLedgerDaily\|listLedgerJoy" lib/features/list/presentation/widgets/list_sort_filter_bar.dart
# Expected: lines 236 and 269 appear (replacing the hardcoded strings)

# Gate 3: No new analyzer issues
flutter analyze
# Expected: same pre-existing 4 infos, 0 new issues
```

### W2 Verification

```bash
# Gate 1: No SoulTx identifiers remain in lib/ (the capital-S pattern that evaded previous gates)
grep -rn "SoulTx" lib/
# Expected: 0 results (generated .freezed.dart files are regenerated and clean)

# Gate 2: Same check in test/
grep -rn "SoulTx" test/
# Expected: 0 results (all 9 test files updated)

# Gate 3: Doc comment in get_best_joy_moment_use_case.dart also clean
grep -n "totalSoulTx\|totalJoyTx" lib/application/analytics/get_best_joy_moment_use_case.dart
# Expected: line 10 shows "totalJoyTx" in the updated doc comment

# Gate 4: Build is clean
flutter analyze
# Expected: 0 new issues

# Gate 5: Full test suite passes
flutter test
# Expected: 2281+ tests green (was 2281/2281 at Phase 34 close)
```

### Post-W2 canonical grep that catches this class of leak in future

The `soul[A-Z]` gate used by Phase 31 missed this because the identifier was `totalSoulTx` (capital S, not a lowercase-preceded pattern). The correct comprehensive gate:

```bash
# Catches both soul[A-Z] pattern AND SoulTx/SoulLedger variants
grep -rEin "soul[A-Z]\|survival[A-Z]\|SoulTx\|SurvivalTx" lib/ --include="*.dart" \
  | grep -v "\.freezed\.dart\|\.g\.dart"
# Expected after Phase 35: 0 results
```

---

## Validation Architecture

**Framework:** Flutter test (already configured; `flutter test` runs full suite)

### Phase Requirements → Test Map

| Behavior | Test Type | Command | Coverage |
|----------|-----------|---------|----------|
| W1: Semantics labels route through l10n, no hardcoded strings | Static analysis | `grep -rn "'Survival ledger'\|'Soul ledger'" lib/` → 0 | Manual grep gate |
| W1: No analyze regressions | Static | `flutter analyze` → 0 new issues | Automated |
| W2: totalSoulTx renamed to totalJoyTx everywhere | Static | `grep -rn "SoulTx" lib/ test/` → 0 | Automated grep |
| W2: build_runner produces clean generated files | Static | `flutter analyze` → 0 errors | Automated |
| W2: All existing tests pass with renamed fields | Regression | `flutter test` → 2281+ green | Automated |
| W2: Freezed model fields accessible via new names | Unit | `flutter test test/unit/features/analytics/domain/models/happiness_report_test.dart` | Automated |

### Sampling Rate

- **Per plan commit:** `flutter analyze` (fast static gate)
- **Per workstream:** `flutter test test/unit/` + `flutter test test/widget/features/analytics/`
- **Phase gate (pre-verify):** `flutter test` full suite green

### Wave 0 Gaps

None — existing test infrastructure covers all phase requirements. No new test files need to be created. The tests exist; they will break (RED) until the rename is applied (GREEN).

---

## Environment Availability

Step 2.6: SKIPPED — this phase is code/config changes only (Dart edits + build_runner). No external services, CLIs beyond the project's standard Flutter toolchain, or network dependencies required.

---

## Runtime State Inventory

Step 2.5: NOT APPLICABLE — this is a vocabulary-cleanup rename, not a user-data rename. `totalSoulTx`/`totalGroupSoulTx` are in-memory computed fields only, never persisted to the DB, never used as map keys in serialized payloads. No DB migration, no stored data update, no OS-level registration involved.

---

## Optional Extension (flag — out of scope per audit)

The `Semantics(label: 'Show all ledgers', ...)` on line 210 is also a hardcoded English string (not a vocab problem — "all ledgers" was never renamed). It is an i18n correctness issue but was not flagged in W1. If the user wants it swept at the same time, the fix is the same pattern: replace with `l10n.listLedgerAll` (the existing ARB key returns "すべて"/"全部"/"All"). This is optional and should be raised as a checkbox item in the plan, not a required task.

Similarly, stale doc comments referencing `totalSoulTx` in `get_best_joy_moment_use_case.dart:10` (and any others in analytics files) are documentation-only — the audit accepted these as WR-03-style debt. Updating the doc comment on line 10 is part of the W2 mechanical rename for consistency, but sweeping other stale doc comments is out of scope.

---

## Assumptions Log

This table is empty — all claims in this research were verified by direct file inspection.

---

## Sources

### Primary (HIGH confidence — direct file inspection)

- `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — confirmed exact lines 236 and 269; confirmed `l10n = S.of(context)` at line 127
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — confirmed `listLedgerDaily` / `listLedgerJoy` values; confirmed no a11y-specific keys exist
- `lib/features/analytics/domain/models/happiness_report.dart` — confirmed `totalSoulTx` Freezed field at line 20
- `lib/features/analytics/domain/models/family_happiness.dart` — confirmed `totalGroupSoulTx` Freezed field at line 19
- `lib/features/analytics/domain/models/happiness_report.freezed.dart`, `family_happiness.freezed.dart` — confirmed generated (do not edit)
- All lib/ consumer files and test/ files — confirmed via `grep -rn "SoulTx"` returning exact file:line inventory
- `.planning/v1.5-MILESTONE-AUDIT.md` — authoritative scope definition (W1/W2/accepted_non_gaps)

### Secondary (MEDIUM confidence)

- CLAUDE.md project instructions — i18n rules, Freezed/build_runner conventions, zero-analyze-warnings policy

---

## Metadata

**Confidence breakdown:**
- W1 ground truth (file/lines/l10n availability): HIGH — confirmed by direct file read
- W1 ARB keys: HIGH — all 3 ARBs inspected directly
- W2 occurrence inventory: HIGH — exhaustive grep across lib/ and test/
- W2 DB safety (no persistence): HIGH — no Drift annotation found on these fields
- Rename approach (build_runner regen): HIGH — standard project pattern, confirmed in CLAUDE.md

**Research date:** 2026-06-02
**Valid until:** Stable (no external packages; pure internal rename)
