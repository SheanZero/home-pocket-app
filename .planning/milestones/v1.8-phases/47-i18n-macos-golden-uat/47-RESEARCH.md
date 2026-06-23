# Phase 47: i18n + 反毒性扫描 + macOS golden 重基线 + 全量门禁 + UAT - Research

**Researched:** 2026-06-17
**Domain:** Flutter verification/wrap-up — i18n (ARB parity + gen-l10n), anti-toxicity widget sweeps, macOS golden authoring-from-zero, full-suite wave gating, on-device visual UAT, + 4 Phase-46 code-review warning fixes
**Confidence:** HIGH

## Summary

This is a **verification / wrap-up phase for milestone v1.8** — it adds NO new features, no new cards, no new data path, no schema migration, no fl_chart upgrade. It validates the round-5 B redesigned analytics page (5 always-visible cards + 1 group-only card) shipped in Phase 46 along four axes (GUARD-03 i18n, GUARD-02-wording/GUARD-03 anti-toxicity, GUARD-04 golden+gate, GUARD-05 UAT), and folds in 4 code-review warnings (WR-01..04) that must be fixed BEFORE the on-device UAT because the UAT happens in this phase and user-visible edge defects must be fixed first.

Because this is an existing, mature Flutter codebase, almost all "research" is **codebase pattern discovery, not external library lookup**. Every paradigm this phase needs already exists in-tree and was read directly: the anti-toxicity per-phase sweep (`anti_toxicity_phase16/17_test.dart`), the golden platform gate (`test/flutter_test_config.dart` + `BaselineExistenceGoldenComparator`), the per-card golden harness (`per_category_breakdown_card_golden_test.dart`), the ARB parity guard (`test/architecture/arb_key_parity_test.dart`), the shared L1-rollup single source (`category_l1_rollup.dart`), and the WR fix sites (donut card, joy use case, calendar refresh targets, registry). The single highest-value discovery: the **neutral "Other" ARB key the WR-02 rollup slice needs (`analyticsCategoryDonutOther`) already exists with full ja/zh/en parity and is already in use** — no new ARB key, no new anti-toxicity exposure.

**Primary recommendation:** Sequence the phase WR-fixes → ARB/anti-toxicity → golden authoring (macOS) → full-suite wave gate → on-device UAT. Reuse every existing paradigm verbatim (per-phase anti-toxicity file, per-card golden harness, existing rollup helpers, existing "Other" key). Do NOT relax the LOCKED `forbidden*` lists. Author all goldens on macOS only, pumping count-up `TweenAnimationBuilder` to settled end-state via `pumpAndSettle()`. Run the FULL `flutter test` suite (not a subset) as each wave's merge gate, and force-add (`git add -f`) the gitignored-yet-tracked `lib/generated/` after `flutter gen-l10n`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**WR 修复取舍 (Phase 46 评审遗留, 全部 UAT 前修):**
- **D-01:** 4 个 warning 全部折进 Phase 47，**在真机 UAT 之前修复**（不丢 backlog）。理由：UAT 在本阶段做，用户可见缺陷应先修，避免在 buggy-edge 卡上做视觉验收。
- **D-02 (WR-01 金额币种):** **删除** `AnalyticsCardContext.currencyCode` dead 字段（而非接线）。v1 唯一写入路径恒按日元入账、`amount` 列恒为 JPY、`Book.currency` 无非 JPY 设置入口——分类卡（donut/joy-spend/calendar/drill）显式 JPY-only，移除死接线以免暗示不存在的多币种 analytics 支持。
- **D-03 (WR-02 圆环对账):** 加一个中性「その他/其他/Other」rollup 切片，把 top-10 之外的长尾收进去。圆环**中心保留真·全类目总额**，slices + 图例 % 全部对账到真总额。当月 >10 个 L1 分类有支出时中心数与切片不再背离。「Other」措辞须中性、过反毒性扫描。
- **D-04 (WR-03 性能):** `GetJoyCategoryAmountsUseCase` **重构为单遍**按 L1 聚合，消除 O(n·k) 的 k-pass 重扫，并修正谎称「single pass」的 docstring。
- **D-05 (WR-04 刷新一致性):** `joyDayTransactionsProvider` 加入 `joyCalendarRefreshTargets`，下拉刷新时展开日的 inline 列表随热力 count 一并失效重算（消除残留已删行的状态不一致）。

**Golden 覆盖广度 (GUARD-04):**
- **D-06:** **全矩阵** ja/zh/en × light/dark per 新卡（≈ 5 卡 × 6 = 30+ master），延续 v1.5（77 master）/ v1.6（54 master）惯例。
- **D-07:** **per-card golden 为主**（与 46 的卡体系一致，diff 归因清晰、单卡改动不污染别卡）+ **1 张整页 `AnalyticsScreen` scroll smoke** golden 验证卡序。
- **D-08:** 除默认态外，额外覆盖：① 新 `CategoryDrillDownScreen` 只读列表；② 小确幸日历 inline 展开态（`_InlineDayPanel`，正是 WR-04 修复处）；③ group-mode `family_insight` 条件卡（GUARD-02 聚合面存续）；④ 各卡 empty/初始态。
- **D-09:** 所有 golden 仅在 **macOS** 基线（CI ubuntu 经 `test/flutter_test_config.dart` 走 `BaselineExistenceGoldenComparator`，非像素匹配）。count-up（`TweenAnimationBuilder`）golden 必须 pump 过动画到 settled 末态。固定样本数据复用 43-01 的 shared sample-data 以保 golden 确定性。

**真机 UAT (GUARD-05):**
- **D-10:** **全面核验清单**（逐项勾选）：5 卡渲染 + count-up 动效（donut 中心 + 悦己 header 两处锚点）+ 圆环整行下钻 + 日历 inline 展开 + WR-02/WR-04 修复可见 + 暗色 + 三语切换 + 组模式家庭卡。
- **D-11:** 主验证环境 = **真机 iOS + locale=ja**（app 默认 locale，真实字体/渲染/手势），zh/en 抽检。
- **D-12:** **UAT 失败项阻断 v1.8 里程碑收尾**——v1.8 是视觉重设计，UAT 是核心验收而非边角，失败项必须修复/重验才能关里程碑，**不走** acknowledged-deferred（区别于 v1.1/v1.5 的 human_needed 历史模式）。

**反毒性扫描覆盖 (GUARD-02 措辞层 + GUARD-03):**
- **D-13:** 新卡**复用 GATE-04 已锁定的 forbidden substring 列表**（phase16/17 范式里的 `forbiddenEn/Zh/...`，已覆盖 ranking/streak/cross-period/comparison/目标）；不为新文案新增禁词（已锁表足够）。⚠ 已锁表「relax 需 ADR 签署」，本决策是复用而非放松。
- **D-14:** 单个 **`anti_toxicity_phase47_test.dart`** 覆盖 5 张新卡 × 3 语 × 全状态（延续 phase16/17 per-phase 文件惯例），非 per-card 拆文件。
- **D-15:** **本阶段删除**孤儿 section-header ARB 键 `analyticsGroupHeaderTime/Distribution/Stories`（46-07 扁平化后零消费者）。删除 → `flutter gen-l10n` → **`git add -f`** 被 gitignore-yet-tracked 的 `lib/generated/` 生成 Dart（已知坑：executor 会漏 commit 生成文件，orchestrator 需复查）。GUARD-03 ARB 洁净度优先。

### Claude's Discretion
- 逐波（wave）拆分与门禁顺序由 planner 定（goal 要求「逐波门禁」用全量 `flutter test`）。
- WR 修复与验证工作的先后编排（建议 WR 修复 → ARB/反毒性 → golden 撰写 → 全量门禁 → 真机 UAT）由 planner 细化。
- 「Other」rollup 切片的具体配色/排序细节遵循既有 donut 调色与 ADR-019 调色板。

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. 性能优化超出 WR-03 单遍重构的部分仍属 v1 out-of-scope；多币种 analytics 子总额 = CUR-V2-02；收入/真实结余率 = INCOME-V2-01；fl_chart 2.x = TOOL-V2-01 已 N/A——均不在本阶段。
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GUARD-03 | i18n — ARB parity ja/zh/en for all new copy; `flutter gen-l10n` clean; 生存/灵魂 grep-ban green (ADR-017) | Parity is machine-enforced by `test/architecture/arb_key_parity_test.dart` (normal + metadata key-sets must match across all 3 locales). Phase 46 already has all 21 keys at parity (46-REVIEW "ARB trilingual parity PASS"). This phase's only ARB delta is **deleting** 3 orphan keys (`analyticsGroupHeaderTime/Distribution/Stories` — verified 0 non-generated consumers, 0 test references) symmetrically from all 3 ARB files, then `flutter gen-l10n` + `git add -f lib/generated/`. |
| GUARD-04 | macOS golden re-baseline for new/changed analytics surfaces (charts have ZERO golden coverage today — author from scratch on macOS, isolated from any library change); full `flutter test` as the per-wave gate | Golden platform gate already wired (`flutter_test_config.dart` + `BaselineExistenceGoldenComparator`). Per-card harness pattern proven (`per_category_breakdown_card_golden_test.dart`). Count-up determinism via `pumpAndSettle()` to settled end-state. Full-suite gate must include `home_screen_isolation_test.dart` + both anti-toxicity sweeps + 4 architecture scans (CJK / ARB parity / color-literal / stale-suppressions). |
| GUARD-05 | On-device visual UAT of the redesigned page | D-10 checklist + D-11 primary env (real iOS, locale=ja) + D-12 blocking semantics (no acknowledged-deferred). Manual-only by nature; this phase's automated work (WR fixes, goldens, sweeps) is what makes the UAT pass on first run. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| WR-01 dead-field removal (`currencyCode`) | Application/Presentation (registry + card constructors) | — | `AnalyticsCardContext` lives in presentation registry; the literal `'JPY'` formatting is in card widgets. JPY-only is a v1 data-layer truth (only writer hardcodes expense + JPY), so the fix is a presentation-layer dead-plumbing deletion, not a data change. |
| WR-02 "Other" rollup slice | Presentation (donut card) over Domain helper | Domain (`category_l1_rollup.dart`) | The truncation/divergence is purely a display transform in `_DonutHero.build`; the L1 rollup math stays in the locked domain helper. Add the long-tail "Other" bucket at the display layer; center stays true `monthly.totalExpenses`. |
| WR-03 single-pass L1 aggregation | Application (`GetJoyCategoryAmountsUseCase`) | Domain (`l1AncestorOf`) | The O(n·k) loop is in the use case; the fix is an in-use-case single-pass accumulate still routing through the domain `l1AncestorOf` rule (D-11 single source preserved). |
| WR-04 refresh-target union | Presentation (`joyCalendarRefreshTargets`) | — | Refresh targets are presentation-registry closures over `AnalyticsCardContext`; the day-keyed provider lives in `state_analytics`. |
| ARB parity + gen-l10n + force-add | i18n infra (`lib/l10n/*.arb` → `lib/generated/`) | Build tooling | ARB files are the source; `flutter gen-l10n` regenerates `lib/generated/` (gitignored-yet-tracked → needs `git add -f`). |
| Anti-toxicity sweep | Test (`test/widget/.../anti_toxicity_phase47_test.dart`) | — | Pure widget-test layer; pumps cards through `createLocalizedWidget`, asserts `findsNothing` on locked forbidden substrings. |
| Golden authoring | Test (`test/golden/*_golden_test.dart` + `goldens/*.png`) | — | macOS-baselined pixel comparison; off-macOS reduced to baseline-existence. |
| On-device UAT | Manual (real iOS device) | — | Human verification; not automatable. |

## Standard Stack

This phase introduces **zero new packages**. All work uses the already-pinned stack. Versions verified against `pubspec.yaml` + installed toolchain.

### Core (already present — verify, do not add)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.44.0 (stable) | Framework | `flutter --version` [VERIFIED: local toolchain] |
| Dart SDK | 3.12.0 (pin `^3.10.8` in pubspec) | Language | `flutter --version` [VERIFIED: local toolchain] |
| `flutter_test` | bundled with SDK | Widget + golden tests | `matchesGoldenFile`, `pumpAndSettle` [VERIFIED: in use across test/golden] |
| `flutter_riverpod` | 3.1+ (gen 4.x) | Provider overrides in tests | `ProviderScope` / `overrideWith` per-test harness [VERIFIED: anti_toxicity tests] |
| `fl_chart` | `^1.2.0` (PINNED — do NOT upgrade) | Donut PieChart + histogram rods | TOOL-V2-01 is N/A (2.x doesn't exist); GATE-04 affordance-verified [CITED: CLAUDE.md + REQUIREMENTS Out-of-Scope] |
| `flutter_localizations` / `intl 0.20.2` | pinned | gen-l10n + formatters | `intl` exact-pinned by flutter_localizations [CITED: CLAUDE.md pitfall 5] |

### Supporting (in-tree reusable assets — NOT packages)
| Asset | Path | Purpose | When to Use |
|-------|------|---------|-------------|
| `BaselineExistenceGoldenComparator` | `test/helpers/ci_golden_comparator.dart` | off-macOS golden gate | Already wired in `flutter_test_config.dart`; new goldens need NO extra config [VERIFIED: read] |
| `createLocalizedWidget` | `test/helpers/test_localizations.dart` | localized widget harness for sweeps | Every anti-toxicity sweep test [VERIFIED: used in phase16/17] |
| `category_l1_rollup.dart` | `lib/features/analytics/domain/` | `l1AncestorOf` + `rollupCategoryBreakdownsToL1` + `l1RollupFromTransactions` | WR-02 + WR-03 both route through this (D-11 single source) [VERIFIED: read] |
| `arb_key_parity_test.dart` | `test/architecture/` | GUARD-03 parity machine-check | Runs in full suite; deleting 3 orphan keys must stay symmetric or this fails [VERIFIED: read] |
| `analyticsCategoryDonutOther` ARB key | `lib/l10n/app_{en,ja,zh}.arb:2006` | neutral "Other"/"その他"/"其他" | **Reuse for WR-02** — already trilingual, already used by legacy `category_spend_donut_chart.dart:95` [VERIFIED: grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reuse `analyticsCategoryDonutOther` for WR-02 | New `analyticsDonutOtherRollup` key | New key = new ARB parity surface + new anti-toxicity exposure for zero benefit; the existing key is already neutral and trilingual. **Reuse.** |
| Single `anti_toxicity_phase47_test.dart` (D-14) | per-card sweep files | Per-phase file matches phase16/17 precedent; one file importing 5 cards is the locked convention. **Single file.** |
| Pump count-up to settled end-state (D-09) | golden of mid-animation frame | Mid-frame is non-deterministic → flaky goldens. `pumpAndSettle()` lands the `IntTween` at `end` value. **Settled.** |

**Installation:** None — `flutter pub get` already satisfied. No `npm`/`pip`/`cargo` equivalent; this is a Flutter app.

## Package Legitimacy Audit

> **N/A — this phase installs ZERO external packages.** It is a verification/wrap-up phase operating entirely on the existing pinned dependency set (`fl_chart ^1.2.0`, `flutter_riverpod`, `flutter_test`, `intl 0.20.2`). No new dependency is added, removed, or upgraded. The `package-legitimacy check` seam was therefore not run (no candidates). The `fl_chart 1.x→2.x` upgrade is explicitly OUT OF SCOPE and N/A (2.x does not exist).

## Architecture Patterns

### System Architecture Diagram

```
                    PHASE 47 VERIFICATION FLOW (per-wave, full-suite gated)
                    ─────────────────────────────────────────────────────

  [Phase 46 round-5 B page]
   5 cards + 1 group card
           │
           ▼
  ┌─────────────────────┐   WR fixes (D-01..05, BEFORE UAT)
  │  WAVE: WR fixes      │   • WR-01 delete AnalyticsCardContext.currencyCode + 'JPY' literals stay literal
  │  (code + unit tests) │   • WR-02 donut: add "Other" rollup slice; center = true totalExpenses; % off true total
  └──────────┬──────────┘   • WR-03 GetJoyCategoryAmountsUseCase → single-pass accumulate (fix docstring)
             │              • WR-04 joyCalendarRefreshTargets += joyDayTransactionsProvider(selected day)
             ▼
  ┌─────────────────────┐   GUARD-03
  │  WAVE: i18n / ARB    │   • delete 3 orphan keys (Time/Distribution/Stories) symmetric × 3 ARB
  │                      │   • flutter gen-l10n → git add -f lib/generated/
  └──────────┬──────────┘   • arb_key_parity_test green + 生存/灵魂 grep-ban green (ADR-017)
             ▼
  ┌─────────────────────┐   GUARD-02-wording + GUARD-03
  │  WAVE: anti-toxicity │   • anti_toxicity_phase47_test.dart imports 5 cards
  │                      │   • LOCKED forbiddenEn/Ja/Zh (phase16) — REUSE, never relax
  └──────────┬──────────┘   • 5 cards × 3 langs × all states → findsNothing
             ▼
  ┌─────────────────────┐   GUARD-04 (macOS ONLY)
  │  WAVE: golden author │   • per-card goldens (≈30+ master): 5 cards × ja/zh/en × light/dark
  │                      │   • + drill screen, calendar inline-expand, family_insight group, empty states
  │                      │   • + 1 AnalyticsScreen full-page scroll-smoke (card order)
  │                      │   • pumpAndSettle() → count-up at settled end-state
  └──────────┬──────────┘   • flutter test --update-goldens (macOS) → commit goldens/*.png
             ▼
  ┌─────────────────────┐   GUARD-04 gate (every wave merge)
  │  FULL flutter test   │   MUST include: home_screen_isolation_test + anti_toxicity_phase16 +
  │  (NOT a subset)      │   anti_toxicity_phase17 + anti_toxicity_phase47 + arb_key_parity +
  └──────────┬──────────┘   hardcoded_cjk_ui_scan + color_literal_scan + stale_suppressions_scan
             ▼
  ┌─────────────────────┐   GUARD-05 (manual, real iOS device, locale=ja)
  │  ON-DEVICE UAT       │   D-10 checklist; FAILURES BLOCK v1.8 closeout (D-12, no defer path)
  └─────────────────────┘
```

### Recommended Test/Source Structure
```
lib/features/analytics/presentation/
├── analytics_card_registry.dart                  # WR-01: delete currencyCode field + ctx assignment
└── widgets/cards/
    ├── category_donut_card.dart                  # WR-02: Other slice + true-total center + true-total %
    ├── joy_spend_card.dart                        # WR-01: 'JPY' literals stay literal (drop ctx field)
    ├── joy_calendar_card.dart                     # WR-04: joyCalendarRefreshTargets += joyDayTransactions
    └── satisfaction_histogram_card.dart           # WR-01: currencyCode arg removed from spec build
lib/application/analytics/
└── get_joy_category_amounts_use_case.dart        # WR-03: single-pass accumulate

test/widget/features/analytics/presentation/widgets/
└── anti_toxicity_phase47_test.dart               # NEW (D-14): 5 cards × 3 langs × states
test/golden/
├── category_donut_card_golden_test.dart          # NEW
├── joy_spend_card_golden_test.dart               # NEW
├── joy_calendar_card_golden_test.dart            # NEW (+ inline-expand state, D-08②)
├── satisfaction_histogram_card_golden_test.dart  # NEW
├── within_month_trend_card_golden_test.dart      # NEW
├── category_drill_down_screen_golden_test.dart   # NEW (D-08①)
├── family_insight_data_card_golden_test.dart     # NEW (D-08③)
├── analytics_screen_scroll_smoke_golden_test.dart# NEW (D-07 full-page card order)
└── goldens/*.png                                  # ≈30+ macOS-baselined masters
lib/l10n/
├── app_en.arb / app_ja.arb / app_zh.arb          # D-15: delete 3 orphan keys symmetrically
lib/generated/*.dart                               # regenerate → git add -f
```

### Pattern 1: Per-phase anti-toxicity sweep (D-13/D-14 — reuse verbatim)
**What:** One `anti_toxicity_phase47_test.dart` imports all 5 round-5 B cards, pumps each through `createLocalizedWidget` for `en/ja/zh × {empty, value, group-mode, inline-expand}`, and asserts the LOCKED forbidden substrings produce `findsNothing`.
**When to use:** Every new/changed analytics card surface.
**Example (paradigm from `anti_toxicity_phase16_test.dart`, verbatim-reusable):**
```dart
// Source: test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart
// LOCKED lists — REUSE the phase16 forbiddenEn/Ja/Zh (D-13). Relaxing needs ADR sign-off.
const forbiddenEn = <String>['better','worse','winner','loser','vs','versus',
  'compare','comparison','score','rank','ranking','wins','loses', /* … */];
const forbiddenZh = <String>['更好','更差','赢','输','胜','败','vs','对比','比较',
  '排名','分数','胜出','落败'];
const forbiddenJa = <String>['勝ち','負け','より良い','より悪い','比較','対決',
  'スコア','ランキング','勝つ','負ける'];

void _sweepForbiddenSubstrings({required Locale locale, required String card,
    required String state}) {
  for (final substring in _forbiddenFor(locale)) {
    expect(find.textContaining(substring, findRichText: true), findsNothing,
      reason: 'anti-toxicity violation — $card / ${locale.languageCode} / $state '
              '— "$substring" leaked. Revert ARB or extend list (needs ADR).');
  }
}
```
**Critical nuance (from phase16/17):** keep each state's `overrideWith` list LOCAL so a missing override throws loudly at runtime instead of silently passing the sweep (an unoverridden auto-dispose provider would otherwise mask coverage). Use `await tester.pumpAndSettle()` before sweeping.

### Pattern 2: Per-card golden harness (D-07 — reuse `per_category_breakdown_card_golden_test.dart`)
**What:** `@Tags(['golden'])` library, `ProviderScope(overrides:[...], child: MaterialApp(locale:..., theme:..., home: Scaffold(body: Center(child: SizedBox(w,h, child: SingleChildScrollView(card))))))`, `pumpAndSettle()`, then `expectLater(find.byType(Card), matchesGoldenFile('goldens/<name>.png'))`.
**When to use:** Every per-card golden (the bulk of the ≈30+ masters).
**Example:**
```dart
// Source: test/golden/per_category_breakdown_card_golden_test.dart
@Tags(['golden'])
library;
// ...
await tester.pumpWidget(_wrap(
  locale: const Locale('ja'),
  theme: ThemeData.dark(),                 // light + dark per UI-SPEC §Theme Mode Coverage
  overrides: [provider(...).overrideWith((_) async => Value(fixture, count))],
));
await tester.pumpAndSettle();              // settles TweenAnimationBuilder count-up to end value
await expectLater(find.byType(CategoryDonutCard),
  matchesGoldenFile('goldens/category_donut_card_dark_ja.png'));
```
**macOS-only baselining (D-09):** generate with `flutter test --update-goldens` on macOS, commit the `goldens/*.png`. The `BaselineExistenceGoldenComparator` (auto-wired in `flutter_test_config.dart`) makes CI/ubuntu assert only baseline existence — NEVER re-baseline on CI (0.05–5.9% font-AA diff is unavoidable cross-platform).

### Pattern 3: WR-02 "Other" rollup reconciliation (display-layer only)
**What:** In `_DonutHero.build`, after `rollupCategoryBreakdownsToL1(breakdowns, categoryMap, topN: 10)` produces ≤10 `rows`, compute `donutTotal = rows.fold(amount)` and, when `total (= monthly.totalExpenses) > donutTotal`, append a synthetic "Other" slice of `total - donutTotal`. Center count-up keeps `end: total` (true all-category total). Legend % divides by **true `total`**, not `donutTotal`.
**When to use:** WR-02 fix only.
**Reuse:** the neutral label is the EXISTING `S.of(context).analyticsCategoryDonutOther` ("Other"/"その他"/"其他") — already trilingual, already passes anti-toxicity. No new ARB key.
```dart
// WR-02 fix shape (display-layer)
final rows = rollupCategoryBreakdownsToL1(breakdowns, categoryMap, topN: 10);
final donutTotal = rows.fold<int>(0, (s, r) => s + r.amount);
final otherAmount = total - donutTotal;          // total == monthly.totalExpenses (true)
// PieChart sections: rows + (otherAmount > 0 ? Other slice : none)
// Legend rows: each percent = (amount / total * 100).round()  // ← true total, not donutTotal
// "Other" legend row is NON-tappable (no L1 to drill) and labelled analyticsCategoryDonutOther
```
**Constraint (D-03 / specifics):** the "Other" wording must stay neutral (no "the rest don't matter" framing) and must be exercised by `anti_toxicity_phase47_test.dart` in a >10-category fixture state.

### Pattern 4: WR-03 single-pass accumulate (D-04 — mirror the rollup helper)
**What:** Replace the distinct-L1-set-then-loop-`l1RollupFromTransactions`-per-L1 (O(n·k)) with one pass.
```dart
// Source recipe: 46-REVIEW.md §WR-03
final acc = <String, int>{};
for (final tx in expenseTxns) {
  final l1 = l1AncestorOf(tx.categoryId, categoryMap) ?? tx.categoryId;
  acc[l1] = (acc[l1] ?? 0) + tx.amount;
}
final buckets = [
  for (final e in acc.entries) if (e.value > 0)
    JoyCategoryAmount(categoryId: e.key, amount: e.value),
]..sort((a, b) => b.amount.compareTo(a.amount));
```
Still routes through `l1AncestorOf` (D-11 single source intact). **Fix the docstring** — the current "There is NO second rollup loop here" is false today and must accurately describe the single-pass accumulate.

### Pattern 5: WR-04 refresh-target union (D-05)
**What:** `joyCalendarRefreshTargets(ctx)` currently returns only `perDayJoyCountsProvider`. The expanded-day list is `joyDayTransactionsProvider(bookId, day, joyMetricVariant)`, but `day` is `_JoyCalendarBodyState._selectedDay` (local state, NOT in `AnalyticsCardContext`). The clean fix is the 46-REVIEW option (a): have `_InlineDayPanel`/`_JoyCalendarBodyState` invalidate its own `joyDayTransactionsProvider(selectedDay)` on the refresh signal, so a pull-to-refresh re-fetches the expanded day's rows alongside the count heatmap.
**Constraint:** must NOT add a `home/*` provider to the union (GUARD-01 / D-B3); `joyDayTransactionsProvider` is an analytics provider so the union ⊆ analytics holds. If the planner chooses option (b) (accept gap + document), that violates D-05's intent ("失效重算") — D-05 mandates the actual invalidation, so option (a) is required.

### Anti-Patterns to Avoid
- **Relaxing the LOCKED `forbidden*` lists** to make a sweep pass — requires ADR sign-off (D-13). If a new card's copy trips a forbidden substring, FIX THE COPY, don't shrink the list.
- **Re-baselining goldens on CI/ubuntu** — font-AA diff guarantees pixel mismatch; baselines are macOS-only (D-09).
- **Golden of a mid-animation frame** — non-deterministic; always `pumpAndSettle()` to the count-up's settled end value (D-09).
- **Wiring `currencyCode` instead of deleting it** (WR-01 D-02) — implies non-existent multi-currency analytics; v1 is JPY-only by data-layer truth.
- **Basing donut center on `donutTotal`** (the truncated sum) — that hides the long tail; center MUST stay `monthly.totalExpenses` (WR-02 D-03).
- **Running a SUBSET as the wave gate** — the gate MUST be the FULL `flutter test` (architecture/CJK/isolation/anti-toxicity all run; a scoped run misses them — see MEMORY Phase 38 gotcha).
- **`git add lib/generated/`** (without `-f`) after gen-l10n — the dir is gitignored-yet-tracked; plain add is rejected, leaving stale generated Dart in HEAD → analyze fails from a clean tree (MEMORY Phase 46 gotcha).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Off-macOS golden gating | Custom platform skip logic in each golden test | `flutter_test_config.dart` + `BaselineExistenceGoldenComparator` (already global) | Auto-applies to every test under `test/`; no per-test config |
| L1 category rollup | New aggregation in the card / use case | `category_l1_rollup.dart` (`l1AncestorOf`, `rollupCategoryBreakdownsToL1`) | D-11 single-source invariant — donut==drill math must not diverge |
| Neutral "Other" label | New ARB key | `analyticsCategoryDonutOther` (existing, trilingual, in-use) | Zero new parity/anti-toxicity surface |
| ARB parity checking | Manual diff of 3 ARB files | `arb_key_parity_test.dart` (in full suite) | Machine-enforces normal + metadata key-set equality across en/ja/zh |
| Localized widget test harness | Hand-built `MaterialApp` per test | `createLocalizedWidget` (test/helpers) | Used by all anti-toxicity sweeps; consistent delegates/locale |
| Hardcoded-CJK detection | Eyeballing card copy | `hardcoded_cjk_ui_scan_test.dart` (in full suite) | Catches any new CJK literal that should be ARB-keyed |

**Key insight:** This phase's value is in *reuse fidelity*, not new code. Every paradigm exists; the risk is divergence (a sweep that secretly passes because a provider wasn't overridden, a golden re-baselined on the wrong platform, an ARB key deleted from 2 of 3 files). The existing tests are designed to catch exactly these — so the full-suite wave gate is the safety net.

## Runtime State Inventory

> This phase is NOT a rename/refactor/migration phase. It is code-fix + test-authoring + i18n + UAT. However, the WR fixes and ARB deletion touch a few runtime-adjacent items, so the relevant categories are answered explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — no schema change (stays v20/v21 per CONTEXT), no Drift table touched, no datastore key renamed. The 3 deleted ARB keys are UI strings, not stored data. | None — verified by CONTEXT "停 v21" + no `tables/` edits in scope |
| Live service config | **None** — no external service, no n8n/Datadog/Tailscale; this is a local-first Flutter app and the work is in-repo code + tests | None — verified by project type |
| OS-registered state | **None** — no Task Scheduler / launchd / systemd; the UAT runs the app on a real iOS device but registers nothing | None |
| Secrets/env vars | **None** — no secret/env-var name touched; crypto/key-management untouched | None |
| Build artifacts | **`lib/generated/*.dart`** is regenerated by `flutter gen-l10n` after the ARB orphan-key deletion. It is **gitignored-yet-tracked**, so a plain `git add` is rejected — must `git add -f lib/generated/` or HEAD keeps stale generated Dart (analyze fails from clean tree). | `flutter gen-l10n` → `git add -f lib/generated/` (D-15); orchestrator must re-verify the generated files were committed (MEMORY Phase 46 gotcha) |

## Common Pitfalls

### Pitfall 1: Anti-toxicity sweep silently passes because a provider wasn't overridden
**What goes wrong:** A card under sweep reads an auto-dispose analytics provider that wasn't overridden; it throws/loads instead of rendering copy, so the forbidden-substring scan finds nothing — a false green.
**Why it happens:** Auto-dispose providers (the `@riverpod` default) have no real data in a bare test scope.
**How to avoid:** Keep each state's `overrideWith` list LOCAL and complete (phase16 pattern); a missing override should throw loudly, not silently pass. Render the *data* path (and empty path) explicitly. Assert the card actually rendered visible text (the phase16/17 helper joins all `Text` widgets — verify the blob is non-empty for value states).
**Warning signs:** A sweep test that passes even when you deliberately inject a forbidden word into the ARB.

### Pitfall 2: Golden flakiness from un-settled count-up animation
**What goes wrong:** `TweenAnimationBuilder<int>` count-up (donut center ~480ms, joy header) is mid-tween at pump time → golden captures a transient value → diff on every run.
**Why it happens:** `pumpWidget` doesn't advance the animation; the tween value depends on elapsed frames.
**How to avoid:** `await tester.pumpAndSettle()` before `expectLater` — it drains the animation to the `IntTween.end` value (D-09 settled end-state). Use deterministic fixture amounts.
**Warning signs:** Golden passes locally on second run but fails first run, or differs by a few digits in the center number.

### Pitfall 3: ARB orphan-key deletion breaks parity by touching only some files
**What goes wrong:** Deleting `analyticsGroupHeaderTime/Distribution/Stories` from `app_en.arb` but forgetting `app_ja.arb`/`app_zh.arb` (each has all 3 + metadata twins) → `arb_key_parity_test` fails (key-set mismatch).
**Why it happens:** Three separate files, plus `@`-metadata twins for some keys.
**How to avoid:** Delete each orphan key (and any `@`-metadata twin) from ALL three ARB files symmetrically, then `flutter gen-l10n`, then run `arb_key_parity_test`. Verified locations: `app_en.arb`/`app_ja.arb`/`app_zh.arb` lines ~1955–1957.
**Warning signs:** `arb_key_parity_test` red; or `flutter gen-l10n` warns about untranslated/extra messages.

### Pitfall 4: `git add lib/generated/` rejected → stale generated Dart in HEAD
**What goes wrong:** After `flutter gen-l10n` the regenerated `lib/generated/app_localizations*.dart` won't stage with a plain `git add` (gitignored-yet-tracked); the executor moves on, HEAD keeps the OLD generated Dart referencing the deleted keys → `flutter analyze` from a clean checkout fails.
**Why it happens:** `lib/generated/` is in `.gitignore` but the files are tracked (committed historically).
**How to avoid:** Always `git add -f lib/generated/` after gen-l10n. Orchestrator must re-verify these files are actually in the commit (MEMORY Phase 46 gotcha — this exact failure happened before).
**Warning signs:** `git status` shows `lib/generated/` modified-but-unstaged after a plain add; analyze fails on a fresh clone but passes locally.

### Pitfall 5: Wave gate runs a scoped subset and misses architecture/isolation regressions
**What goes wrong:** Running only the new/changed test files as the per-wave gate misses `home_screen_isolation_test`, the two pre-existing anti-toxicity sweeps, and the architecture/CJK scans — a regression in those ships silently.
**Why it happens:** Scoped runs feel faster.
**How to avoid:** The per-wave merge gate MUST be the FULL `flutter test` (CONTEXT + MEMORY Phase 38). Per-task commits may run a quick scoped subset, but the wave merge is full-suite.
**Warning signs:** A merged wave where `flutter test` (full) is red even though the wave's own tests were green.

### Pitfall 6: Parallel executors collide on shared test stubs / ARB keys
**What goes wrong:** Same-wave parallel executors both edit the ARB files or both add overlapping golden helper stubs → merge conflict or duplicate symbols (MEMORY Phase 38).
**Why it happens:** Golden/anti-toxicity work shares ARB + sample fixtures.
**How to avoid:** If the planner parallelizes within a wave, isolate ARB edits to ONE executor; union-resolve shared helper stubs at merge; run FULL `flutter test` post-merge (not scoped). Prefer keeping ARB deletion (D-15) and the anti-toxicity file in the same single-executor lane.
**Warning signs:** Post-merge analyze shows duplicate top-level declarations, or ARB key-set diverges.

## Code Examples

### Deleting orphan ARB keys + regenerate (GUARD-03, D-15)
```bash
# 1. Remove analyticsGroupHeaderTime / Distribution / Stories (+ any @-metadata twins)
#    from ALL THREE files symmetrically:
#    lib/l10n/app_en.arb, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb  (≈ lines 1955-1957)
# 2. Regenerate:
flutter gen-l10n
# 3. Stage the gitignored-yet-tracked generated dir (MANDATORY -f):
git add -f lib/generated/
# 4. Verify parity + clean gen:
flutter test test/architecture/arb_key_parity_test.dart
flutter analyze   # must be 0 issues from a clean tree
```

### Authoring goldens on macOS (GUARD-04, D-06..D-09)
```bash
# Author/refresh ALL goldens on macOS ONLY (never CI/ubuntu):
flutter test --update-goldens --tags golden
git add test/golden/goldens/*.png
# Then verify the full suite (gate):
flutter test
```

### Full per-wave gate (GUARD-04)
```bash
# The FULL suite — NOT a subset. Must include the named guardrails:
flutter test
#   includes: test/widget/features/home/.../home_screen_isolation_test.dart
#             test/widget/features/analytics/.../anti_toxicity_phase16_test.dart
#             test/widget/features/analytics/.../anti_toxicity_phase17_test.dart
#             test/widget/features/analytics/.../anti_toxicity_phase47_test.dart  (NEW)
#             test/architecture/arb_key_parity_test.dart
#             test/architecture/hardcoded_cjk_ui_scan_test.dart
#             test/architecture/color_literal_scan_test.dart
#             test/architecture/stale_suppressions_scan_test.dart
flutter analyze   # 0 issues
flutter test --coverage   # ≥80% (project rule)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Section-header analytics layout (Time/Distribution/Stories groups) | Flat 5-card narrative flow, NO section headers | Phase 46 (round-5 B, D-F2) | The 3 `analyticsGroupHeader*` ARB keys are orphaned → delete this phase (D-15) |
| Cards format with literal `'JPY'` + dead `currencyCode` plumbing | Literal `'JPY'` retained; dead `currencyCode` field DELETED (v1 is JPY-only) | This phase (WR-01/D-02) | No multi-currency illusion; honest JPY-only analytics |
| Donut center == truncated `donutTotal`; % off truncated set | Center == true `totalExpenses`; "Other" slice for long tail; % off true total | This phase (WR-02/D-03) | Slices + legend reconcile to displayed center under >10 L1 categories |
| `GetJoyCategoryAmountsUseCase` O(n·k) k-pass rescan (docstring lies "single pass") | Single-pass accumulate; honest docstring | This phase (WR-03/D-04) | Correct contract; routes through `l1AncestorOf` (D-11 intact) |
| Charts have ZERO golden coverage | ≈30+ macOS-baselined per-card goldens + 1 full-page scroll smoke | This phase (GUARD-04) | Regression detection for the redesigned analytics surfaces |

**Deprecated/outdated:**
- `analyticsGroupHeaderTime/Distribution/Stories` ARB keys — zero consumers since 46-07 flattening; delete (D-15). Verified: 0 non-generated lib references, 0 test references.
- `daily_vs_joy_card.dart` / `per_category_breakdown_card.dart` widget files — de-registered from the lineup in Phase 46 but RETAINED (they keep their own tests, including the still-running `anti_toxicity_phase16_test.dart` + their goldens). NOT in scope to delete this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "43-01 shared sample-data" referenced in CONTEXT D-09 is the **HTML-mock fictional family-month dataset** (`.planning/phases/43-html-design-gate-no-production-code/mocks/shared/sample-data.md`), NOT a reusable Dart test fixture — verified that file exists and describes a ¥248,600 family-month; no Dart `sampleData` symbol was found in `test/` or `lib/`. | Standard Stack / Pattern 2 | LOW — goldens need *deterministic* fixtures regardless; planner should author Dart fixtures (like `per_category_breakdown_card_golden_test.dart`'s `_fixtureFiveWithOther()`) seeded with the sample-data.md numbers for cross-mock visual fidelity. The numbers exist; only the Dart-fixture authoring is required. |
| A2 | Drift schema version: CLAUDE.md says v20 (Phase 36); CONTEXT says "停 v21". Either way **no migration in this phase** — the exact integer is irrelevant to Phase 47 (no schema touch). | Runtime State Inventory | NONE — no schema work in scope; the discrepancy doesn't affect any task. |
| A3 | WR-04 fix uses 46-REVIEW option (a) (panel self-invalidates its day-keyed provider on refresh), since D-05 mandates actual invalidation/recompute, not the documented-gap option (b). | Pattern 5 | LOW — if option (a) proves awkward, the planner may need a `checkpoint:human-verify` on the exact invalidation wiring, but D-05's intent is unambiguous (失效重算). |
| A4 | Light + dark golden coverage per card (D-06 "× light/dark") follows the existing `per_category_breakdown_card_golden_test.dart` convention of `ThemeData.light()`/`ThemeData.dark()`; the app's real palette is ADR-019 via `context.palette`, but the existing golden harness uses base ThemeData. Planner should decide whether to wrap goldens in the real app theme for palette fidelity. | Pattern 2 | MEDIUM — if goldens use bare `ThemeData.dark()` they won't capture ADR-019 palette regressions; consider wrapping in the production theme (`AppTheme`) for the analytics goldens to make them meaningful. Flag for planner. |

## Open Questions (RESOLVED)

1. **Golden theme fidelity (ADR-019 palette)** — RESOLVED: see UI-SPEC §Theme Fidelity (wrap production `AppTheme.light/.dark`); enforced in plan 47-05 (acceptance asserts bare `ThemeData` == 0).
   - What we know: existing card goldens use `ThemeData.light()/dark()`; the app resolves colors via `context.palette` (ADR-019 `AppPalette`).
   - What's unclear: whether new analytics goldens should wrap in the production `AppTheme` to capture palette regressions (the cards read `context.palette`).
   - Recommendation: wrap the new analytics goldens in the real app theme so the goldens actually exercise `AppPalette.light/.dark` — otherwise the goldens validate layout but not the v1.6 palette. (See A4.) Planner to confirm with how `home_hero_card_golden_test.dart` wraps theme.

2. **Exact "Other" slice color/sort (D-03 discretion)** — RESOLVED: see UI-SPEC §WR-02 Other slice (neutral swatch, sort-last, non-tappable, true-total center); carried into plan 47-01 Task 2.
   - What we know: D-03 leaves "Other" slice color/sort to existing donut palette + ADR-019.
   - What's unclear: whether "Other" sorts last (after the 10 L1 rows) and uses a muted/neutral swatch.
   - Recommendation: place "Other" last, use a neutral grey-ish swatch distinct from the daily→joy lerp gradient; non-tappable (no L1 to drill). Confirm against `category_spend_donut_chart.dart`'s existing Other handling.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | all build/test work | ✓ | 3.44.0 stable | — |
| Dart SDK | all | ✓ | 3.12.0 | — |
| macOS host | golden authoring/re-baseline (D-09) | ✓ (darwin 25.5.0) | — | NONE — goldens MUST be baselined on macOS; CI/ubuntu can only assert existence |
| Real iOS device | on-device UAT (GUARD-05, D-11) | ✗ (not verifiable from this env) | — | NONE per D-12 — UAT is blocking; an iOS simulator is a weaker substitute (no real font/gesture fidelity). The on-device run is a human/manual step. |
| `fl_chart ^1.2.0` | donut PieChart, histogram rods | ✓ (pinned in pubspec) | 1.2.0 | — |

**Missing dependencies with no fallback:**
- **Real iOS device for UAT** — the on-device UAT (GUARD-05/D-11) requires a physical iOS device with locale=ja; this is a manual human step and cannot be automated. D-12 makes failures blocking with no acknowledged-deferred path. The planner must terminate the phase with a `checkpoint:human-verify` UAT task gated on a physical device.

**Missing dependencies with fallback:**
- None for automated work — golden authoring requires macOS which IS the current host (darwin).

## Validation Architecture

> Nyquist validation enabled. This phase IS verification coverage, so the mapping below is exhaustive: every success criterion / GUARD requirement maps to a concrete, observable check.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter 3.44.0) + golden via `matchesGoldenFile` |
| Config file | `test/flutter_test_config.dart` (global golden platform gate — already present) |
| Quick run command | `flutter test test/widget/features/analytics/` (per-task) |
| Full suite command | `flutter test` (per-wave gate — FULL, never subset) |
| Golden author command | `flutter test --update-goldens --tags golden` (macOS only) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GUARD-03 | ARB key-set parity en/ja/zh (normal + metadata) | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ exists |
| GUARD-03 | `flutter gen-l10n` clean (no untranslated/extra) | build | `flutter gen-l10n && flutter analyze` | ✅ (toolchain) |
| GUARD-03 | 生存/灵魂 grep-ban green (ADR-017) | architecture | `flutter test` (terminology guard runs in suite) | ✅ exists |
| GUARD-03 | No hardcoded CJK in new UI | architecture | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ exists |
| GUARD-02-wording + GUARD-03 | 5 cards × 3 langs × all states → no forbidden substrings | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart` | ❌ Wave: NEW |
| GUARD-02 | density/joyPerYen single-expression (`grep density|joyPerYen lib/` == 0) | grep/architecture | runs in full `flutter test` | ✅ existing guard |
| GUARD-04 | per-card goldens (≈30+) render deterministically | golden | `flutter test --tags golden` (macOS exact; CI existence) | ❌ Wave: NEW masters |
| GUARD-04 | full-page card-order scroll smoke | golden | `flutter test test/golden/analytics_screen_scroll_smoke_golden_test.dart` | ❌ Wave: NEW |
| GUARD-04 | HomeHero isolation preserved | widget | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | ✅ exists |
| GUARD-04 | full-suite gate green every wave | suite | `flutter test` (full) | ✅ harness |
| WR-01 | `currencyCode` field deleted; registry compiles; cards JPY-literal | unit/widget | `flutter test test/widget/features/analytics/presentation/analytics_card_registry_test.dart` | ✅ exists (update) |
| WR-02 | center == true total; slices+legend reconcile under >10 L1 | unit/widget | new donut card test asserting `Σ(slices incl Other) == center` | ❌ Wave: NEW assertion |
| WR-03 | single-pass aggregation; correct per-L1 amounts | unit | `flutter test test/.../get_joy_category_amounts_use_case_test.dart` | ✅ exists (update) |
| WR-04 | pull-to-refresh re-fetches expanded day's list | widget | new test pumping calendar, expanding a day, invalidating, asserting re-fetch | ❌ Wave: NEW |
| GUARD-05 | on-device visual UAT (D-10 checklist) | manual | physical iOS device, locale=ja; D-10 itemized checklist | ❌ manual (checkpoint:human-verify) |

### Sampling Rate
- **Per task commit:** `flutter test test/widget/features/analytics/ <plus the touched file>` + `flutter analyze` (scoped quick run)
- **Per wave merge:** `flutter test` (FULL suite — includes isolation + all 3 anti-toxicity + 4 architecture scans) + `flutter analyze` (0 issues) + golden baselines committed (macOS)
- **Phase gate:** full suite green + `flutter test --coverage` ≥80% + on-device UAT checklist all-green BEFORE milestone closeout (D-12 blocking)

### Wave 0 Gaps
- [ ] `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase47_test.dart` — covers GUARD-02-wording/GUARD-03 (5 cards × 3 langs × states)
- [ ] `test/golden/{category_donut,joy_spend,joy_calendar,satisfaction_histogram,within_month_trend}_card_golden_test.dart` — per-card goldens (GUARD-04)
- [ ] `test/golden/category_drill_down_screen_golden_test.dart` — drill screen golden (D-08①)
- [ ] `test/golden/family_insight_data_card_golden_test.dart` — group-mode card golden (D-08③)
- [ ] `test/golden/analytics_screen_scroll_smoke_golden_test.dart` — full-page card-order smoke (D-07)
- [ ] `test/golden/goldens/*.png` — ≈30+ macOS baselines (author with `--update-goldens` on macOS)
- [ ] WR-02 reconciliation assertion test + WR-04 refresh test (new assertions on existing/new test files)
- [ ] Deterministic golden fixtures seeded from the 43-01 sample-data.md numbers (Dart fixtures; the data file is `.md`, not a Dart symbol — see A1)
- Framework install: none needed (`flutter_test` bundled).

## Security Domain

> `security_enforcement` not explicitly false in config; included for completeness. This phase is presentation-layer + test-authoring + i18n with NO new data path, NO new external input, NO crypto change.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | No session surface touched |
| V4 Access Control | no | No new access path; cards read the active book only (`bookIds` never widened — verified in use cases, threat T-46-02-01) |
| V5 Input Validation | no (no new input) | No new user input; UAT is read-only visual; "Other" slice is a derived display value, not input |
| V6 Cryptography | no | No crypto touched; SQLCipher/key-management untouched (no schema, no DB work) |
| V7 Error Handling/Logging | yes (carry-over) | Transaction contents never logged (threat T-46-02-02 / T-46-05-02 already enforced in the joy use cases — WR-03 single-pass refactor must preserve "only aggregate amount ints kept", no per-tx logging) |

### Known Threat Patterns for {Flutter local-first analytics}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Logging transaction contents during WR-03 refactor | Information Disclosure | Keep aggregate-only ints; no `print`/log of tx rows (existing `production_logging_privacy_test.dart` guards this in the full suite) |
| Widening `bookIds` beyond the active book in WR fixes | Information Disclosure / EoP | WR-03/WR-04 must NOT widen the book set (T-46-02-01 / T-46-05-01); single-pass refactor operates on the same `findByBookIds([bookId], joy)` result |
| Sample-data / golden fixtures leaking real financial data | Information Disclosure | Use FICTIONAL fixtures (43-01 sample-data is explicitly SIMULATED); never seed goldens from real user data (T-43-01) |

## Sources

### Primary (HIGH confidence — read directly from codebase this session)
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` — LOCKED forbidden lists + per-phase sweep paradigm
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart` — entry-source variant sweep
- `test/flutter_test_config.dart` + `test/helpers/ci_golden_comparator.dart` — golden platform gate
- `test/golden/per_category_breakdown_card_golden_test.dart` — per-card golden harness paradigm
- `test/architecture/arb_key_parity_test.dart` + `hardcoded_cjk_ui_scan_test.dart` — GUARD-03 guards
- `lib/features/analytics/presentation/analytics_card_registry.dart` — WR-01 currencyCode site + card lineup
- `lib/features/analytics/presentation/widgets/cards/category_donut_card.dart` — WR-01/WR-02 sites
- `lib/features/analytics/presentation/widgets/cards/joy_calendar_card.dart` + `state_analytics.dart` — WR-04 site + providers
- `lib/application/analytics/get_joy_category_amounts_use_case.dart` — WR-03 O(n·k) site
- `lib/features/analytics/domain/category_l1_rollup.dart` — D-11 single-source rollup helpers
- `lib/l10n/app_{en,ja,zh}.arb` — orphan keys (1955-1957) + existing `analyticsCategoryDonutOther` (2006)
- `.planning/phases/46-cards/46-REVIEW.md` — authoritative WR-01..04 fix recipes
- `.planning/phases/47-i18n-macos-golden-uat/47-CONTEXT.md` — 15 locked decisions
- `.planning/REQUIREMENTS.md` — GUARD-03/04/05 definitions
- `CLAUDE.md` + MEMORY.md — project conventions, golden CI platform gate, gitignored-generated gotcha, ADR-019 palette

### Secondary (MEDIUM confidence)
- `.planning/phases/43-html-design-gate-no-production-code/43-01-SUMMARY.md` — confirms sample-data.md is an HTML-mock `.md` dataset (A1)

### Tertiary (LOW confidence)
- None — no WebSearch needed; this is an in-tree verification phase with all paradigms present.

## Metadata

**Confidence breakdown:**
- WR fixes: HIGH — fix recipes are authoritative (46-REVIEW), all sites read directly, single-source helpers confirmed
- Anti-toxicity: HIGH — paradigm + LOCKED lists read verbatim; reuse-not-relax confirmed
- ARB / gen-l10n: HIGH — orphan keys confirmed 0 consumers, parity test read, existing "Other" key confirmed trilingual + in-use
- Golden authoring: HIGH (mechanism) / MEDIUM (theme fidelity — see A4/Open Q1)
- UAT: HIGH (process/blocking semantics from D-10..12) — manual by nature
- Wave gating: HIGH — full-suite requirement + parallel-collision hazards confirmed from MEMORY

**Research date:** 2026-06-17
**Valid until:** 2026-07-17 (stable — in-tree patterns; only Flutter/fl_chart point releases could shift, and both are pinned)
