---
quick_id: 260518-v4v
description: Home polish round 2 — Variant A Best Joy redesign + recent-tx soul color/layout fix + analytics spacing precise re-measure
gathered: 2026-05-18
status: locked_for_planning
mode: quick-validate
follows: 260518-pf5
---

# Quick Task 260518-v4v: 首页打磨 Round 2 — Context

> **Locked round 2.** Round 1 (260518-pf5) shipped 7 items; user manual UI verification flagged 3 items needing rework. This task addresses those 3 items only.
> Items 3 + 4 + 9b remain in ADR-016 (Proposed) — still OUT OF SCOPE.

<domain>
## Task Boundary

After round 1 manual UI check (2026-05-18 user feedback):
- ✅ PASS: split bar, hero spacing, family-invite zh i18n
- ❌ FAIL: Best Joy strip (题字太小 + 整体布局需要重新设计) → resolved by **Variant A from Pencil mock**
- ❌ FAIL: recent transactions (类目还是红色 + 满意度位置造成上下金额错位)
- ❌ FAIL: analytics top spacing (still larger than home's month-selector → 本月支出 gap)

</domain>

<decisions>
## Locked Scope — 3 Items

### Item 2-v2 — Best Joy strip redesign per Variant A (Pencil mock)

**Pencil design source:** `/Users/xinz/Documents/new.pen` node `n6VVd` ("VariantA Card")

**Card structure (top → bottom, all in HomeHeroCard width = ~390px):**

```
┌──────────────────────────────────────────────┐
│  本月最愛               [pill ❤ 最愛]        │  ← Row 1: title left + satisfaction tier pill right
│                                              │
│  ¥ 4,200                                     │  ← Row 2: hero amount (¥ separator + number)
│                                              │
│  スターバックス 渋谷店      12/10 ・木曜     │  ← Row 3: merchant left + date right
└──────────────────────────────────────────────┘
```

**Card container:**
- bg `#FFFDF8` (current cream — keep existing token if defined; if not, introduce as `AppColors.surfaceCream` matching ADR-015 palette)
- border 1px `#F2E4C9` gold
- corner radius 22
- padding 18 all sides
- vertical layout, gap 14

**Row 1 — title + satisfaction pill:**
- Title text "本月最愛" (ja) / "本月最爱" (zh) / "Best of the Month" (en) — already exists as `homeBestJoyTitle` ARB key (confirm; if not present, add)
- Title style: `AppTextStyles.titleMedium` (~16px) with `FontWeight.w800` — current `_buildBestJoyStrip` uses `overline` (11px) which is the bug. Use heaviest title token available; if `AppTextStyles` doesn't have w800, add or use Inter w800 directly with a code comment justifying deviation from token scale
- Pill: rounded 999, padding (4, 8), bg `#FFF1F1` light pink, contents: emoji icon (size 16, color `#D45F65` rose) + tier label (font 11, w800, `#D45F65`)
- Emoji icon: re-use `_satisfactionIcon()` mapping from `home_screen.dart` lines 304–312 (per ADR-014 unipolar positive scale) — for a "best" row the satisfaction is almost always 10 → `Icons.favorite_border`; lower satisfaction levels show their corresponding `Icons.sentiment_*` icon
- Tier label: derive from satisfaction value → ARB key. Per ADR-014 mapping table:
  - val 10 → ja「最愛」zh「最爱」en「Amazing」 (ARB key `satisfactionLabelAmazing` or per Phase 12 final name — VERIFY in `app_*.arb`)
  - val 8 → 「満足 / 满足 / Great」
  - val 6 → 「不錯 / 不错 / Good」
  - val 4 → 「OK」
  - val 2 → 「中性 / 中性 / Neutral」
- **No `/10` suffix on the pill** (user explicit: "不用标记 10")

**Row 2 — hero amount:**
- Layout: horizontal, `alignItems: end`, gap 6
- `¥` symbol: font 20, w700, color `AppColors.soul` (#47B88A)
- Amount number: font 32, w800, color `AppColors.soul`, `letterSpacing: -0.5`, **`FontFeature.tabularFigures()` MANDATORY** (CLAUDE.md)
- The "¥" prefix uses the currency symbol from the book's locale; this widget should accept currency code as a param (NOT hardcoded `¥` — fix the WR-01 issue surfaced in pf5 review at the same time, since we're rewriting the function anyway). Use `FormatterService` or equivalent
- **Subtlety:** for non-JPY books (USD, CNY, EUR, GBP) the symbol char changes ($, ¥, €, £). The hero treatment (symbol smaller than number) still works

**Row 3 — merchant + date:**
- Layout: horizontal, justify space-between, alignItems center
- Merchant: font 13, w600, `#52625A` (or `AppColors.textSecondary` if defined)
- Date: font 11, w600, `#B39A71` (or `AppColors.textMutedGold`)
- Date format: per locale (ja `12/10 ・木曜` / zh `12/10 周四` / en `12/10 Thu`) — use existing `DateFormatter` from `lib/infrastructure/i18n/formatters/date_formatter.dart`

**REMOVE:**
- Current `_buildBestJoyStrip()` tag-line (overline) row
- Current divider + footer italic quote (Variant A in mock had these; user explicitly said "不用 footer 一句话")

**Empty state (`_bestJoyEmpty`):**
- Keep simple: when no soul tx with satisfaction > 2, show the same card frame with placeholder text "今月の『最愛』はまだ" / "本月还没有「最爱」" / "No favorite this month yet"
- No pill, no amount, no merchant — just the title + a single muted line

### Item 5-v2 — Recent transactions color + satisfaction placement

**User feedback:** "类目显示还是红色，需要和金额一起设置为 split bar中悦己颜色，同时满意度位置不好看，让上下金额错位了"

**Two parts:**

**5a — Soul row color:**
- Soul-ledger rows should use **soul brand color** (`AppColors.soul` = `#47B88A`) for BOTH the category/merchant text AND the amount text
- Survival rows: keep current `context.wmTextPrimary` (neutral)
- This **reverses** pf5's "unify everything to neutral" decision per explicit user request — they want soul rows visually distinct via brand color, not by red (which was the original bug) and not gray (which was pf5's overcorrection)
- Implementation: `home_transaction_tile.dart` accepts a `ledgerColor` (or similar) param; `home_screen.dart` passes `AppColors.soul` for soul rows, `context.wmTextPrimary` for survival rows

**5b — Satisfaction icon position:**
- Current pf5 placement (inline next to amount) causes baseline misalignment — soul rows render taller, breaking the vertical rhythm of the recent-tx list
- New placement: keep icon visible for soul rows, but **don't break the amount line's baseline**. Options (planner picks):
  - (a) Icon under the amount on a second line — but this also breaks row height parity. ❌
  - (b) Icon to the LEFT of the merchant (column 1 area), small enough not to disrupt — could work, but pulls focus away from amount.
  - (c) **Recommended:** icon as a small overlay in the merchant-text row (one of the existing lines), NOT in the amount row. e.g. inline-right of the category text where the satisfaction emoji becomes "tagged onto" the category, not the amount.
  - (d) Icon as a tiny pill below the amount (right column), 14×14 size, but visually disconnected from amount baseline — needs careful spacing.

Planner: investigate `home_transaction_tile.dart` current layout, propose ONE specific placement, ensure all rows (soul + survival) maintain identical height when rendered side-by-side. **Acceptance criteria:** screenshot test or manual diff — soul rows and survival rows must have the same total height.

### Item 6-v2 — Analytics top spacing precise re-measure

**User feedback:** "统计页和中标题和本月支出块的间隔还是比首页月度选择和本月支出外框距离要大"

**Reference measurement (home screen — the truth):**
- Find the home page "月度选择 / month selector" widget AND the "本月支出 / Monthly expense block (HomeHeroCard or its first inner block)"
- Measure the vertical gap between the bottom of the month selector AND the top of the expense block visual frame
- This is the **target gap** that the analytics screen must match

**Current analytics state:**
- pf5 changed `analytics_screen.dart:83` to `EdgeInsets.fromLTRB(16, 16, 16, 24)` — but user says it's still LARGER than home
- This means either:
  - The home gap is < 16px (planner must MEASURE, not assume)
  - There's additional spacing somewhere (AppBar bottom padding, Scaffold default, another wrapping Padding/SizedBox)

**Required investigation:**
1. Inspect `home_screen.dart` widget tree from the month-selector to the first hero block — record every Padding / SizedBox / margin contributing to that gap
2. Inspect `analytics_screen.dart` AppBar → first KPI block — record every contributor
3. Diff. The analytics side has at LEAST one extra contributor. Find and remove/equalize.
4. **Acceptance criteria:** the gap (in pixels) between home's month-selector-bottom and home-hero-card-top MUST equal the gap between analytics's AppBar-title-bottom and first-KPI-top, ±2px tolerance.

Do NOT just guess another number. Measure both sides.

### Claude's Discretion
- **Tests:** Best Joy strip widget likely has tests in `test/widget/.../home_hero_card_test.dart`. Update or rewrite assertions for the new layout. Goldens will need regeneration.
- **Build_runner:** No annotations touched unless something requires it.
- **Color tokens:** if `AppColors.surfaceCream` / `textMutedGold` etc. don't exist, the planner decides whether to add them to the theme (preferred for consistency with the Pencil mock's design language) or use raw color literals as a localized exception (with a comment).
- **i18n:** if `satisfactionLabel*` ARB keys (Amazing/Great/Good/OK/Neutral) don't exist in current ARBs, add them — ADR-014 said Phase 12 was supposed to rename them but verify they're actually there.

</decisions>

<out_of_scope>
## ❌ 明确不在 v4v scope 内

| Item | 原因 | 去处 |
|---|---|---|
| 3 — Joy 公式改为 sum | ADR-013 lock | ADR-016 |
| 4 — 满意度圆环视觉重设 | 同 item 3 一致 | ADR-016 |
| 9b — 设计规范文档 | 需要 1+9a 落地后写 | ADR-016 决议后单独 phase |
| WR-02 — `_memberInitial` deviceId hack | 预存问题，不在 5 项内 | follow-up quick or v2 |
| Bucket B 任何工作 | 等 ADR-016 决议 | — |

</out_of_scope>

<canonical_refs>
## Canonical References

- Pencil mock: `/Users/xinz/Documents/new.pen` node `n6VVd`
- `CLAUDE.md` — Amount Display Style, i18n rules, build_runner triggers
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — emoji ↔ value mapping
- `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` — register rules
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — what we're NOT doing
- `.planning/quick/260518-pf5-home-polish-typography-spacing-ledger-ba/260518-pf5-SUMMARY.md` — round 1 baseline
- `lib/features/home/presentation/widgets/home_hero_card.dart` (item 2-v2)
- `lib/features/home/presentation/screens/home_screen.dart` + `lib/features/home/presentation/widgets/home_transaction_tile.dart` (item 5-v2)
- `lib/features/analytics/presentation/screens/analytics_screen.dart` + `lib/features/home/presentation/screens/home_screen.dart` (item 6-v2 — must compare BOTH)
- `lib/infrastructure/i18n/formatters/date_formatter.dart` + `number_formatter.dart` (item 2-v2 amount/date formatting)

</canonical_refs>
