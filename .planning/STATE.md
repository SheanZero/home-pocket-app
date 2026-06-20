---
gsd_state_version: 1.0
milestone: v1.8
milestone_name: 统计页面重设计（实用化 × 悦己情感化） — ACTIVE
status: verifying
stopped_at: 47-06-PLAN.md complete — full-suite gate green + on-device D-10 UAT all 10 PASS (user-approved 2026-06-20); Phase 47 all 6 plans done, ready for verification
last_updated: "2026-06-20T05:13:06.191Z"
last_activity: 2026-06-20
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 20
  completed_plans: 20
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-14 after v1.7 milestone)

**Core value:** Family accounting app users can trust with sensitive financial data — local-first, end-to-end encrypted, dual-ledger system distinguishes 日常 (daily) spending from 悦己 (joy) spending so families can have honest money conversations
**Current focus:** Phase 47 — i18n-macos-golden-uat

## Current Position

Phase: 47
Plan: Not started
Status: 47-06 complete — full suite 3057/3057, analyze 0, cleaned coverage 80.48% (GUARD-04); on-device D-10 UAT all 10 items PASS, user-approved 2026-06-20 (GUARD-05). Phase verify/closeout owned by orchestrator.
Last activity: 2026-06-20

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260613-mgc | 修改外币编辑交互（头部金额点击弹现有键盘编辑；原币金额卡上移至分类卡前，仅留汇率+日元） | 2026-06-13 | 03a041d7 | [260613-mgc-foreign-currency-edit-ui](./quick/260613-mgc-foreign-currency-edit-ui/) |
| 260613-n5c | 外币编辑微调（汇率日期触发器显示实际日期2026/06/13；编辑页金额键盘保存键执行整条目保存） | 2026-06-13 | 08c87829 | [260613-n5c-fx-edit-date-and-save](./quick/260613-n5c-fx-edit-date-and-save/) |
| 260613-njf | 撤销改动2（键盘动作键恢复纯write-back，不再整条目保存）；编辑页外币键盘动作键文案「保存」→「确认」 | 2026-06-13 | 8b274e08 | [260613-njf-revert-keypad-save-confirm-label](./quick/260613-njf-revert-keypad-save-confirm-label/) |
| 260613-ohz | 货币选择器去除粗体三字码列（flag→symbol→name）；19个长尾币种名称支持zh/ja/en本地化 | 2026-06-13 | 72b2d788 | [260613-ohz-currency-picker-dedup-l10n](./quick/260613-ohz-currency-picker-dedup-l10n/) |
| 260613-ote | 长尾币种真实货币符号（NumberFormatter 新增 16 个：฿₹₱₫₽₺/Rp/RM/NZ$/R$/R/kr/MX$/zł；CHF/AED/SAR 保留三字码） | 2026-06-13 | e8ab6f82 | [260613-ote-longtail-currency-symbols](./quick/260613-ote-longtail-currency-symbols/) |
| 260613-ufn | 统一外币添加/编辑两屏的汇率卡片（同一 CurrencyLinkedEditFields：汇率可编辑/日元只读/汇率日期不可点击+staleness；移除添加页 ≈¥ 预览块；改日期 picker 自动重查汇率两屏一致，编辑跑 ADR-022 D-02/D-03） | 2026-06-13 | 182241bd | [260613-ufn-unify-foreign-currency-card](./quick/260613-ufn-unify-foreign-currency-card/) |
| 260613-wjx | 修复 Home 首页最近项编辑/删除后列表不刷新（onTap fire-and-forget → await pop 结果并 invalidateTransactionDependents，对齐 list_screen WR-03 契约；含回归测试） | 2026-06-13 | 72d52e15 | [260613-wjx-home-bug](./quick/260613-wjx-home-bug/) |
| 260613-wuv | 外币输入时汇率/换算改为卡片样式（与编辑页一致），滚动时仅金额输入区置顶；外币金额输入增加防抖缓冲避免实时计算闪频 | 2026-06-13 | d98f7e92 | [260613-wuv-fx-input-card-debounce](./quick/260613-wuv-fx-input-card-debounce/) |
| 260614-dx1 | 外币金额为整数时编辑/显示不再出现 .00（编辑页+键盘 formatMinorAsMajor；列表注释 formatCurrency trimWholeFraction；保留真实小数 12.50 与 JPY 整数路径） | 2026-06-14 | 3423d53e | [260614-dx1-fx-no-trailing-zeros](./quick/260614-dx1-fx-no-trailing-zeros/) |
| 260614-goh | 语音外币切换：①识别口语词（人民币/美金+全货币 zh/ja/en，大小写不敏感，regexAlternation longest-first）②修复头部药丸不切换（AmountDisplay 未传 currency→硬编码 JPY；新增 _displayCurrency，汇率成功才切外币、RateUnavailable 保持 JPY）（+32 用例） | 2026-06-14 | 117aecd5,d2b9df8e | [260614-goh-voice-currency-switch](./quick/260614-goh-voice-currency-switch/) |
| 260614-iww | 隐藏 OCR 记账入口（新增 kOcrEntryEnabled=false 编译期 flag，InputModeTabs 隐藏扫描页签 + navigateToEntryMode 短路；OCR 基础设施/屏幕零改动，翻转 flag 即恢复）+ 添加账目 FAB 点击=保存即 pop 返回 + 友好提示，长按=连续记账模式（停留清空表单 + 「继续记账」提示 + 退出键/退出提示）；ja/zh/en 三语温暖文案 | 2026-06-14 | 10236350,9c9b6068,45ed4332 | [260614-iww-ocr](./quick/260614-iww-ocr/) |

## Last Milestone Snapshot (v1.7)

- **Phases:** 3 (40-42), **Plans:** 20
- **Duration:** 2026-06-12 → 2026-06-13 execution; quick-task hardening through 2026-06-14
- **Audit Status at Close:** `tech_debt` — accepted (23/23 requirements, 3/3 phases verified, 6/6 seams, E2E complete; all four Phase 42 device UAT items passed; suite 2786/2786 green)
- **Outcome:** Foreign-currency ledger entry end to end; transaction-date historical-rate conversion (Frankfurter + fawazahmed0, encrypted Drift cache, offline fallback); JPY-converted booking amount with original currency/amount/rate as sync-safe fields; JPY-only path byte-unchanged; schema v20→v21
- **Tag:** `v1.7`, schema at v21

## Previous Milestone Snapshots

- **v1.6** (4 phases 36-39, 27 plans, `tech_debt`) — 购物清单 family shopping list; schema v19→v20
- **v1.5** (5 phases 31-35, 24 plans, `tech_debt`) — 文案与配色统一; ADR-019 "Sakura Mochi × Wakaba" palette
- **v1.4** (7 phases 24-30, 29 plans, `tech_debt`) — 列表功能 kakeibo-style List tab
- **v1.3** (6 phases 18-23, 47 plans, `tech_debt`) — 迭代帐本输入 single-screen voice entry
- **v1.2** (5 phases 13-17, 37 plans, `tech_debt`) — Happiness Metric Refresh (ADR-016, Σ joy_contribution)
- **v1.1** (4 phases 9-12, 40 plans, `known_debt`) — Happiness Metric & Display
- **v1.0** (8 phases 1-8, 48 plans, `passed`) — Codebase Cleanup Initiative

## Accumulated Context

### Roadmap Evolution

- v1.8 roadmap first written 2026-06-15 as 5 phases (43-47) following the research design-gate-first decomposition. Phase numbering continues from v1.7's Phase 42 (no reset).
- Phase 43 is a **standalone hard DESIGN GATE — NO production code** (user requirement "未获批前不进入开发"). Build phases (44-47) start only after the gate closes on user approval. The v1.6 (7→4) and v1.7 (6→3) consolidation precedents were considered; the build half (44-47) is kept at 4 phases because each carries a distinct, sequentially-dependent contract (data → shell → cards → validation) and the milestone is a full screen rebuild under tight ADR-012 invariants.

### v1.8 Roadmap Constraints (locked by research + PROJECT.md — every build phase carries these)

- **Design gate first (Phase 43):** no Dart/production code; deliver current-impl deep-research map (GATE-01), ≥3 HTML directions each with an ADR-012 self-audit table (GATE-02), discussion → ONE selected direction (GATE-03), new-ADR go/no-go + locked emotional-vocabulary list + fl_chart 1.2.0 affordance validation (GATE-04). Gate exit = user approval.
- **ADR-012 anti-gamification (permanent):** no streaks/badges/targets-as-achievement/cross-period-delta/leaderboards/public-sharing. Every new card joins the `anti_toxicity_*_test` forbidden-substring sweep (ja/zh/en × all states). The savings-rate/overview shows current-window only — `MonthlyReport.previousMonthComparison` stays unsurfaced on analytics.
- **ADR-016 §3 HomeHero isolation:** `home_screen_isolation_test.dart` stays green; analytics reads/invalidates NO `home/*` provider; no shared provider between Home and Analytics; single-Joy-expression (`grep density|joyPerYen lib/` == 0). JOY-01 ambient — must NOT become a progress/target ring (HomeHero owns the only target ring).
- **No income / no real savings-rate:** the only transaction writer hardcodes `expense`, so `totalIncome`==0 and savings-rate would be meaningless. Overview reframed expense-side only (total spend + 日常/悦己 split + top categories). Income capture deferred to INCOME-V2-01.
- **No chart-library bump:** fl_chart stays `^1.2.0` (no 2.x exists — TOOL-V2-01 retired as N/A). Adopt 1.2.0 native per-rod `label` (delete histogram `Stack` hack) + optional donut `cornerRadius`. No lib change bundled into the golden diff.
- **No Drift migration:** schema stays v21. Reuse-first — at most ONE new read-only drill-down path (`CategoryDrillDown` + `GetCategoryDrillDownUseCase` + `AnalyticsDao.getCategoryTransactions`, or reuse v1.4 `GetListTransactionsUseCase`). Budget-vs-actual excluded (the only ask carrying a migration → ANALYTICS-V2-03).
- **Provider rebuild storms:** canonicalize every window boundary via `DateBoundaries`/`TimeWindow` before it reaches a family key; analytics cards stay auto-dispose.
- **Golden + gate:** macOS-only golden re-baseline (chart goldens do not exist today — authored from scratch on macOS); FULL `flutter test` as the per-wave gate (not a scoped subset).

### v1.8 Open Design Questions (resolved in the Phase 43 GATE)

- Exact form of the 悦己 emotional surface (constrained by ADR-012 ambient-vs-discrete line; not yet picked).
- Whether a new ADR is needed (e.g. JOY-04 persisting user-authored reflection text → encryption/privacy implications).
- Customizable/reorderable dashboard yes/no (if yes: SharedPreferences-not-Drift, never family-sync) — currently OUT of scope (fixed layout) per REQUIREMENTS.md; revisit only if the gate elevates it.
- Income-capture reliability check (gates the overview block) — verify at the GATE or early Phase 44.

### Pending Todos

- Await user approval of the v1.8 roadmap, then run `/gsd-plan-phase 43` to begin the HTML 设计探索关卡.
- Phase 43 is a DESIGN GATE: produce HTML/Pencil mocks + decision docs ONLY; commit no Dart/production code. Gate exit = user approves exactly one direction.
- Phase 43 ADR work: if a direction grazes the ADR-012 boundary (e.g. JOY-04 persists text), check `ls docs/arch/03-adr/ADR-*.md` for the current max number before writing a new ADR (sequential, no gaps); current max is ADR-022.
- Phase 44 research flag (light): verify income-capture reliability and the `(book_id, category_id, timestamp)` index need before committing the drill-down path.
- Phase 47: re-baseline goldens on macOS only (CI is ubuntu; `flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS).

### Blockers / Concerns

No active blockers for v1.8. Pre-existing carried debt (unchanged):

- **v1.5 a11y UAT:** Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels — human_needed
- **v1.5 vocab residual:** `Book.survivalBalance`/`soulBalance` DB columns need future DB-migration phase before public release
- **v1.4 GAP-2:** LIST-02 `watchByBookIds` reactive stream is dead code; defer
- **v1.3 voice-flow polish backlog:** Phase 22 advisory WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03 on `voice_input_screen.dart`
- **MOD-005 OCR slot:** OCR ledger entry hidden behind reversible `kOcrEntryEnabled` flag (260614-iww); flip when MOD-005 writer lands

## Deferred Items

### Items acknowledged and deferred at v1.7 milestone close on 2026-06-14

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phases 40/41/42 VALIDATION.md draft + `nyquist_compliant: false`. Documentation-grade; underlying suite 2786/2786 green. Mirrors accepted v1.2–v1.6 pattern. To clear: `/gsd-validate-phase 40/41/42` | accept (documentation-grade) | v1.7 close |
| verification_flag | Phase 42 `42-VERIFICATION.md [human_needed]` flag never flipped — RESOLVED by `42-UAT.md` (2026-06-14, 4/4 pass, 0 issues) covering exactly the 4 flagged device items (D-02 dialog, D-03 toast, flag-emoji render, live-preview behavior) | resolved (flag stale) | v1.7 close |
| metadata_drift | `audit-open` reports 33 quick tasks as incomplete/unknown (SUMMARY.md lack `status: complete` frontmatter). All recorded in the Quick Tasks Completed table. Same cosmetic pattern as v1.5 (17) / v1.6 (38) | cosmetic, no functional gap | v1.7 close |
| voice_backlog | 260526-k92/l0o/n7b/pg6 voice-tab/active-learning follow-ups — genuinely incomplete; carried as the v1.3 VOICE-POLISH-V2 backlog | defer to VOICE-POLISH-V2 | v1.7 close |
| advisory | Pre-existing no-rehash-on-edit policy (ADR-021): editing an amount re-derives JPY but flows `currentHash` through `copyWith` unchanged. Intentional, not multi-currency-specific | accept (awareness only) | v1.7 close |
| ocr_slot | OCR ledger entry hidden behind reversible `kOcrEntryEnabled` compile-time flag (260614-iww); OCR infrastructure/screens untouched. Flip when MOD-005 writer lands | defer to MOD-005 | v1.7 close |

### Items acknowledged and deferred at v1.6 milestone close on 2026-06-12

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| nyquist_gap | Phases 37/38/39 VALIDATION.md draft + `nyquist_compliant: false`; Phase 36 validated/compliant. Documentation-grade, mirrors accepted v1.2–v1.5 pattern | accept (documentation-grade) | v1.6 close |
| review_advisory | 37-REVIEW advisories: WR-02 pushedCount telemetry; IN-01 `final dynamic ledgerType`; WR-05 jsonDecode without local try/catch | defer to v1.7+ cleanup | v1.6 close |
| uat_pending | 260609-ruu (shopping form redesign): automated suite green, status "Implemented — 待真机确认" | human_needed | v1.6 close |
| security_note | Shopping note plaintext on sync wire by design; accepted threat T-q260612-04 (inbound shopping delete ungated) | accept (recorded for security ledger) | v1.6 close |
| metadata_drift | `gsd-sdk audit-open` reports 38 quick tasks as `missing` status (SUMMARY.md lack `status: complete` frontmatter). All recorded Verified in Quick Tasks table | cosmetic, no functional gap | v1.6 close |
| audit_w1_w2 | v1.6 audit W1 + W2 **fixed at close** by 260612-daz — recorded for audit-trail completeness | resolved | v1.6 close |

### Items acknowledged and deferred at v1.5 milestone close on 2026-06-02

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| uat_gap | Phase 35 W1 on-device screen-reader announcement of localized ledger-chip labels | human_needed | v1.5 close |
| a11y_backlog | IN-02: 5 sort/filter/search/clear controls in `list_sort_filter_bar.dart` still use hardcoded English `Semantics(label:)` | defer to v1.6+ a11y/i18n pass | v1.5 close |
| vocab_residual | `Book.survivalBalance`/`soulBalance` live identifiers — needs a further DB migration; explicitly out-of-scope per Research A1/D-06 | defer to a future DB-migration phase | v1.5 close |
| nyquist_gap | Phases 31/32/34/35 VALIDATION.md draft + `nyquist_compliant: false`; Phase 33 approved/compliant | accept (documentation-grade) | v1.5 close |
| test_fidelity | `list_transaction_tile_golden_test.dart` tagText:'Survival' + locale not threaded to tile (WR-01). Test-fidelity only, not user-facing | accept | v1.5 close |

### Items acknowledged and deferred at v1.4 milestone close on 2026-05-31

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| dead_code | GAP-2: LIST-02 `TransactionDao.watchByBookIds` exists but has zero consumers — reactivity via manual `ref.invalidate` | defer to v1.5+ | v1.4 close |
| nyquist_gap | Phases 25/26/27/29/30 VALIDATION.md draft + `nyquist_compliant: false`; Phase 28 approved | accept (documentation-grade) | v1.4 close |

### Items acknowledged and deferred at earlier milestones

- v1.3 close: Phase 18/21 missing VALIDATION.md; Phase 19/20 draft; Phase 22 draft + `nyquist_compliant: true`; voice-polish WR-02/03/06/07/NEW-02/NEW-03 + IN-01/02/03; OCR slot reserved
- v1.2 close: Phase 13/17 missing VERIFICATION.md; 3 Nyquist drafts; `family_insight_card_test.dart` 6 failures from ARB drift
- v1.1 close: Phase 11 human UAT device/simulator verification
- v1.0 close: FUTURE-ARCH/TOOL/QA/DOC items (01..06); FUTURE-ARCH-04 `recoverFromSeed()` key-overwrite bug

## Session Continuity

Last session: 2026-06-20T05:01:26.828Z
Stopped at: 47-06-PLAN.md complete — full-suite gate green + on-device D-10 UAT all 10 PASS (user-approved 2026-06-20); Phase 47 all 6 plans done, ready for verification
Resume file: None

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| (v1.8 not yet started) | — | — | — |
| Phase 43 P01 | 6 min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P02 | 6min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P03 | 5min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P04 | 6min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P05 | 4min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P06 | 7min | 2 tasks | 3 files |
| Phase 43-html-design-gate-no-production-code P07 | 5min | 2 tasks | 4 files |
| Phase 44 P01 | 12min | 1 tasks | 3 files |
| Phase 44 P02 | 12min | 2 tasks | 6 files |
| Phase 44 P03 | 9min | 3 tasks | 8 files |
| Phase 45 P01 | 22min | 3 tasks | 6 files |
| Phase 45 P02 | 14min | 2 tasks | 3 files |
| Phase 45 P06 | 5 min | 1 tasks | 1 files |
| Phase 45 P03 | 3min | 2 tasks | 1 files |
| Phase 45 P04 | 7min | 2 tasks | 1 files |
| Phase 45 P05 | 18min | 1 tasks | 1 files |
| Phase 45 P07 | 11min | 2 tasks | 1 files |
| Phase 46 P46-01 | 40min | 2 tasks | 20 files |
| Phase 46 P46-03 | 7min | 2 tasks | 2 files |
| Phase 46 P46-06 | ~50min | 3 tasks | 14 files |
| Phase 46 P46-02 | ~5min | 2 tasks | 8 files |
| Phase 46 P46-04 | ~18min | 2 tasks | 8 files |
| Phase 46 P46-05 | ~30min | 2 tasks | 10 files |
| Phase 46 P46-07 | ~35min | 3 tasks | 10 files |
| Phase 47 P01 | 10min | 3 tasks | 9 files |
| Phase 47 P02 | 4min | 1 tasks | 1 files |
| Phase 47 P03 | 6min | 1 tasks | 7 files |
| Phase 47 P04 | 8min | 1 tasks | 1 files |
| Phase 47 P05 | 11min | 3 tasks | 56 files |
| Phase 47 P06 | 25min | 2 tasks | 4 files |

## Decisions

- [v1.8 roadmap]: Phase numbering continues from Phase 42 → v1.8 = Phases 43-47 (no reset).
- [v1.8 roadmap]: Phase 43 is a standalone hard DESIGN GATE with NO production code (user "未获批前不进入开发"); build phases 44-47 follow only after the gate closes on user approval.
- [v1.8 roadmap]: Build half kept at 4 sequentially-dependent phases (data → shell → cards → validation) rather than consolidated, because the full-screen rebuild under tight ADR-012/ADR-016 invariants benefits from a clean shell-before-cards contract and a dedicated macOS-golden/full-suite gate.
- [v1.8 roadmap]: Overview reframed expense-side only (no income path exists; savings-rate would be meaningless); real savings-rate → INCOME-V2-01.
- [v1.8 roadmap]: No Drift migration, no fl_chart bump, budget-vs-actual excluded — keeps v1.8 a pure presentation-layer rebuild.
- [Phase ?]: [43-01]: Design-gate Wave-0 — GATE-01 deep-map + shared sample-data + mock README authored; zero production code (only .md under .planning/)
- [Phase ?]: 43-02: M1 practical-led mock uses lr5b sakura joy hex (light #D98CA0 / dark #E89BB0) per plan Task 1, overriding ADR-019 base-table amber #E0A040
- [Phase ?]: 43-03: M2 균衡 mock weights 实用 (总览/donut/趋势) and 悦己 (值得卡/满足度直方图/故事条) equally at mid joy 浓度; dark joy = sakura #E89BB0 (consistent with M1); histogram is distribution-only, story strip single-narrative; ADR-012 self-audit PASS
- [Phase ?]: 43-04: M3 极简实用派 mock is the LOWEST joy 浓度 — clean practical skeleton + a single quiet 值得 card; D-03 LOW JOY-01 intensity rendered as visual weight only (small type/muted sakura/whitespace), semantics unchanged (absolute Σ, no ring); histogram/story/trend/family deliberately omitted; dark joy #E89BB0; ADR-012 self-audit PASS
- [Phase ?]: 43-05: M4 温暖反思派 mock inverts the joy-led IA — emotional core (值得卡 + kakeibo Q4 反思 prompt + 满足度直方图) leads, practical 支出总览 recedes to a compact secondary strip; D-03 MID JOY-01 intensity = visual weight only (38px/confident sakura/soft glow), absolute Σ semantics unchanged (no ring); PRIMARY showcase of the kakeibo Q4 STATIC read-only reflection prompt (one values-affirming question, accepts NO input → no JOY-04 persistence, D-06); 满足度 = distribution+descriptive (no 超过上月/目标 8+); dark joy #E89BB0; ADR-012 self-audit PASS
- [Phase 43]: 43-07: GATE-03 selected = round-5 B (M2-derived, NOT an original M1–M5 as-is) — user iterated from M2 base through rounds 2–5 and gave explicit approval (通过). D-11 reasoning: joy expressed descriptively (悦己花在哪 stacked bar + 满足度 distribution + 小确幸 calendar texture, celebrate-past, never goal-driven) / trend-on-top + sorted level-1 categories (practical) / joy side fully ambient (ADR-012-safe). GATE-04: (1) JOY-04 persistence ADR = NO-GO (D-06, static read-only → no persisted text → no encryption/ADR; v1.8 stays no-Drift); (2) NEW — expense-side 本月vs上月 trend (总支出/日常 tabs) is a documented user-approved ADR-012 §4 carve-out (matches home 支出趋势, neutral labels) → requires an ADR-012 `## Update` amendment BEFORE Phase 45 (do not edit ADR-012 in this phase); joy-side cross-period prohibition stays ABSOLUTE. Emotion wordlist locked with calm-warm additions, target/目标 scoped analytics-only (HomeHero monthly_joy_target ambient ring stays legal per ADR-016 §3). fl_chart 1.2.0 per-chart table: donut/histogram/trend lines ✅ native (histogram removes Stack hack); 悦己 horizontal stacked bar ⚠ + 小确幸 calendar heatmap ❌ flagged Phase 46 risk (custom Row-flex / GridView, no fl_chart); Sankey excluded. Gate-exit no-Dart condition EMPTY (zero .dart/pubspec/lib/test). Phase 43 design gate CLOSED.
- [Phase ?]: 43-06: M5 故事画报派 mock is the HIGHEST joy 浓度 (浓墨) — elevates best_joy_story_strip into a full editorial cover-story hero (pure-CSS warm imagery, NO external image), with a 悦己手记 narrative-recap digest and a high-intensity 值得 number; D-03 HIGH JOY-01 intensity = visual weight only (56px sakura→deep-rose gradient text, most prominent), absolute Σ semantics unchanged (no ring); story is narrative recap of EXISTING best-joy moment + already-spent joy categories, intro 「不排名次、不评高下」 — NEVER a 最棒分类 ranking / top-joy leaderboard (ADR-012 #6); practical 支出总览 compressed to minimal footer (expense-side only); kakeibo Q4 not shown (M4 owns it); dark joy #E89BB0; CSS badge→thumb to keep grep gate clean; heaviest-scrutiny ADR-012 self-audit PASS (Pitfall-1 seven signals all 否, zero ❌). All 5 mocks (M1–M5) now shipped.
- [Phase ?]: [44-01]: L1CategoryRollup is a plain immutable class (const ctor + value equality), NOT Freezed — keeps the shared L1-rollup helper genuinely domain-pure (no build_runner / .freezed.dart / Flutter import)
- [Phase ?]: [44-01]: the LOCKED helper category_l1_rollup.dart lives in the feature domain/ root governed by a DENY-ONLY import_guard.yaml (no allow block, per domain_import_rules_test.dart); domain→domain imports pass (no deny match, verified via custom_lint). Both rollup entrypoints route through ONE l1AncestorOf rule so donut==drill (D-11)
- [Phase 44]: [44-02]: TREND-01 implemented as extend-in-place (D-07/D-08) — MonthlyTrend +dailyTotal/+joyTotal and GetExpenseTrendUseCase's existing 6-month loop adds one per-month getLedgerTotals call (same window as getMonthlyTotals), NOT a new query/family/DAO. So ONE trend provider family can drive all three tabs (总支出/日常/悦己).
- [Phase 44]: [44-02]: in-loop getLedgerTotals chosen over a new getMonthlyLedgerTotals repo method (planner discretion per D-08/RESEARCH Flag C — both migration-free; in-loop adds zero repo surface). Zero-default daily/joy extraction copied from get_monthly_report_use_case.dart (Pitfall 1 — getLedgerTotals omits zero-spend ledger rows). No joy cross-period delta (D-09); schema stays v21 (D-13).
- [Phase ?]: 44-03: Category drill-down subtotal/count sourced from Plan 01 l1RollupFromTransactions (D-11 single source — drill header cannot drift from donut slice)
- [Phase ?]: 44-03: drill path reuses findByBookIds + Dart-side l1AncestorOf filter — zero new DAO/index/migration, schema stays v21 (D-04/D-05/D-06/D-13)
- [Phase 45]: 45-01: AnalyticsCardContext stub lives in analytics_card_registry.dart (Plan 03 fills the AnalyticsCardSpec registry list around it; no per-card duplication of the context class)
- [Phase 45]: 45-01: single-source <card>RefreshTargets(ctx) returns List<ProviderBase<Object?>> (ProviderBase from flutter_riverpod/misc.dart); multi-error-branch cards (KpiHero, SatisfactionHistogram) keep typed ref.watch byte-faithful and retry via targets[n] from the locally-built _ctx() list (D-B2 without losing static typing)
- [Phase ?]: 45-02: familyInsightRefreshTargets drops the direct shadow-books invalidate (D-B3 Option A); familyHappinessProvider re-reads it transitively, keeping the registry union home-free
- [Phase ?]: 45-02: FamilyInsightDataCard shadowBooksAsync prop widened to AsyncValue<List<Object>?> so the cards/ layer imports zero home-feature providers (ShadowBookInfo lives only in state_shadow_books); display behavior byte-identical (T-45-03 mitigation)
- [Phase ?]: Phase 45-06: D-D1 discharged — ADR-012 gains an append-only ## Update recording the expense-side 本月vs上月 §4 carve-out (GATE-04 + STATE.md §4); joy-side cross-period stays ABSOLUTELY forbidden; decision body / §🚫 list / 状态 header byte-unchanged (arch.md append-only)
- [Phase 45]: 45-03: analyticsCardRegistry is a spec-list (List<AnalyticsCardSpec>) — single source for render order (declaration==render, D-B1) AND _refresh union; cards stay dumb ConsumerWidgets
- [Phase 45]: 45-03: dailyVsJoyRefreshTargets is group-aware (family snapshot only behind if(ctx.isGroupMode)) though the spec is always-visible — preserves today's _refresh:314 group-mode invalidation (D-A1); distinct from the family PerCategory provider
- [Phase 45]: 45-03: FamilyInsightDataCard shadowBooks is a Plan-04 shell-injected display prop (null placeholder in registry build) — registry imports zero home/* providers (D-B3 file-wide gate)
- [Phase ?]: [45-04]: analytics_screen rewritten to a 176-LOC thin shell — build maps analyticsCardRegistry.where(isVisible) into a byte-faithful Column, _refresh derives the union from registry.expand(refreshTargets).toSet()+shellRefreshTargets (no hand-listed providers, no home/* invalidate); FamilyInsightDataCard shadowBooks injected via 'built is FamilyInsightDataCard' (reorder-safe); 7 inline _*Card classes deleted; ctor preserved
- [Phase ?]: Phase 45 A1/D-B3 Option A confirmed TRUE: dropping the direct shadowBooksProvider invalidate preserves group-mode family refresh via transitive familyHappinessProvider re-read (45-07)
- [Phase ?]: [46-01]: within-month per-day-cumulative trend = pure Dart transform over findByBookIds (2-month window); no new DAO/migration, schema v21. Joy modelled current-month-only via a model with NO previousMonthJoy field (joy cross-period unrepresentable — D-E1).
- [Phase ?]: [46-01] DEVIATION: 6-month TotalSixMonth registry spec + Time section header removed in 46-01 (not deferred to 46-07) because total_six_month_card/monthly_spend_trend_bar_chart hard-import deleted data symbols — data-only deletion cannot compile, must_have needs zero dangling refs (Pitfall 4). Registry now 9 specs; round-5 B card + re-order remain for 46-07.
- [Phase 46]: [46-03] JOY-03/JOY-04 marked Descoped (superseded by GATE-03 round-5 B) in REQUIREMENTS.md; ROADMAP.md gained a Phase 46 SC section listing the round-5 B 5-card lineup (D-A1/D-A2). Requirement IDs satisfied by ledger correction, not by code.
- [Phase 46]: [46-03] DEVIATION: ROADMAP.md had no existing Phase 46 Success-Criteria block (plan's :240-254/:249 line refs stale — file is 200 lines). Added a full Phase 46 section mirroring Phase 43/47 to carry SC #3 round-5 B lineup (Rule 3, faithful-to-intent).
- [Phase 46]: [46-06] Histogram REDES-02: the score-5 "5" annotation moved onto fl_chart 1.2.0 native BarChartRodLabel(show:true, text:l10n…, offset Offset(0,-4)); the Stack/Align/DecoratedBox overlay deleted. The widget ValueKey could NOT survive (canvas-painted label has no widget key) — test now asserts rod label text + only score-5 rod label.show==true (Rule 1).
- [Phase 46]: [46-06] Read-only drill = ListTransactionTile + new readOnly flag (reuse over a new tile variant); readOnly:true renders the shared _buildRow directly (no Dismissible, no tap, no chevron). List tab byte-identical (readOnly defaults false). Drill list kept time-desc (provider order, D-B2 discretion), showDate:true.
- [Phase 46]: [46-06] Donut legend categoryMap = new auto-dispose analyticsCategoriesMapProvider over categoryRepository.findAll() (no new DAO); empty-map fallback while loading. Legend = 10 L1 rows via rollupCategoryBreakdownsToL1 (D-11); ROW tap → Navigator.push CategoryDrillDownScreen (D-B1, not slice); center total TweenAnimationBuilder<int> count-up ~480ms (D-D2). cornerRadius:4.
- [Phase 46]: [46-06] DEVIATION (Rule 1): analytics_screen_test asserted the deleted CategorySpendDonutChart child; updated to find.byType(CategoryDonutCard) since the rebuilt card no longer renders the old chart widget. Full suite 2928/2928 green; analyze 0.
- [Phase 46]: [46-02] Two JOY-side data paths built as pure Dart transforms over findByBookIds(ledgerType: joy) — zero new DAO, zero migration, schema stays v21. JoyCategoryAmount (per-L1 joy AMOUNT, D-C2) rolls up through the SAME l1AncestorOf/l1RollupFromTransactions the donut uses (D-11 single source → joy segments are a strict subset of donut L1). PerDayJoyCount (per-day joy COUNT, D-C1) = Dart group-by-local-day count (笔数, not sum — Pitfall 3), chosen over a SQL ledger+COUNT DAO variant (no DAO surface, does not cross DRILL-01 scope lock — RESEARCH Flag 2). Both models are domain-pure plain immutable value classes (not Freezed).
- [Phase 46]: [46-02] joyCategoryAmounts (DateBoundaries window-normalized key) + perDayJoyCounts (month-anchored key) wired as @riverpod auto-dispose families alongside 46-01's trend provider (added-to, not clobbered); zero home/* (GUARD-01). 11/11 plan unit tests green; analyze 0; registry + home-isolation structural locks stay green.
- [Phase 46]: [46-02] DEVIATION (Rule 3): reworded doc-comment references to the bare token `getDailyTotals` (kept the rationale) so the plan's literal Pitfall-3 grep guard returns zero matches; the use case never called it.
- [Phase 46]: [46-04] First `LineChart` in `lib/`: `WithinMonthCumulativeLineChart` mirrors the donut fl_chart wiring (SizedBox(height:) + hidden grid/axes/touch). 本月 solid `isStrokeCapRound` + optional 上月 `dashArray [4,4]`; series color passed in by the card (`seriesColor`) so the chart stays palette-agnostic/tab-driven; 上月 ref = `Color.lerp(seriesColor, palette.card, 0.55)`.
- [Phase 46]: [46-04] D-E1 cross-period guard is STRUCTURAL not runtime: the 悦己 pill tab passes `previousMonth=null` and the model has no `previousMonthJoy` field, so a joy 上月 line is unrepresentable (Pitfall 2). Spend tabs (总支出/日常) pass the previous-month list → dual line + spend-only 本月/上月 legend gated behind non-empty previous.
- [Phase 46]: [46-04] Pill tabs are local `_TrendBody` StatefulWidget state (no StateProvider) — tab switch changes only the rendered series, never re-watches the trendAnchor-keyed provider (D-12 rebuild-storm guard). `withinMonthTrendRefreshTargets(ctx)` exported (categoryDonut shape) but card NOT registered — 46-07 owns the registry.
- [Phase 46]: [46-04] Added 4 new l10n keys across en/ja/zh (analyticsCardTitle/CaptionWithinMonthTrend + analyticsTrendSeriesThisMonth/LastMonth); tab labels reuse existing analyticsKpiTotalLabel/daily/joy. Phase 47 ARB-parity/anti-toxicity note: `analyticsTrendSeriesLastMonth` is the spend-side-only ADR-012 §4 exception, never reachable from the joy tab.
- [Phase 46]: [46-05] Both round-5 B joy cards #3/#4 built as CUSTOM non-fl_chart widgets (GATE-04 verified: zero fl_chart import in all 4 new files). 悦己花在哪 = `Row` of `Flexible(flex: amount)` segments (R-1) + single-column legend + local tap-highlight (D-C2 no drill) + 悦己 header `TweenAnimationBuilder` count-up (D-D2 anchor #2). 小确幸日历 = 7-col `GridView` (R-2), cell depth = continuous `Color.lerp(joyLight, joy, count/maxCount)` ambient (ADR-016 §5, explicitly NOT a streak), tap-day → INLINE `AnimatedSize` expand (D-C1, no sheet/route). Cards NOT registered (46-07 owns registry); refreshTargets exported in donut shape.
- [Phase 46]: [46-05] Calendar inline-expand data path = NEW `joyDayTransactionsProvider` (day-scoped `findByBookIds(ledgerType: joy)` over the tapped day's whole-day window, D-12 normalized, auto-dispose, zero home/*) — chosen over widening the count model so `perDayJoyCounts` stays count-only (D-C1); passes only active book + tapped day to findByBookIds (T-46-05-01). Inline list reuses `ListTransactionTile(readOnly: true)` (D-B3, no new variant). Joy-spend segment hues lerp WITHIN the joy family (joy→joyLight), not the donut's daily-green→joy cross-ledger ramp.
- [Phase 46]: [46-05] Added 7 new l10n keys across en/ja/zh (analyticsCardTitle/CaptionJoySpend, analyticsJoySpendHeaderLabel, analyticsJoySpendEmpty, analyticsCardTitle/CaptionJoyCalendar, analyticsJoyCalendarDayEmpty) — anti-toxicity clean (celebrate-past descriptive). Phase 47 should fold them into the anti_toxicity sweep. Full suite 2963/2963 green; analyze 0.
- [Phase 46]: [46-07] analyticsCardRegistry IS the round-5 B flat 5-card lineup (within_month_trend → category_donut → joy_spend → joy_calendar → satisfaction_histogram) + family_insight group-only conditional (D-F1/D-F2). The sectionHeaderKey field + the shell's section-header interleave + _sectionLabel were removed (flat Column of cards). Group mode now adds EXACTLY FamilyHappinessProvider to the _refresh union (only group-only spec).
- [Phase 46]: [46-07] Deleted best_joy_card/kpi_hero_card/largest_expense_card/analytics_screen_section_header (D-A3; total_six_month_card + monthly_spend_trend_bar_chart already gone in 46-01). De-registered daily_vs_joy_card + per_category_breakdown_card (widget FILES retained, keep own tests; their refreshTargets fns removed from the registry). bestJoyMomentProvider/largestMonthlyExpenseProvider providers RETAINED — bestJoyMomentProvider is a HomeHero consumer, not dead-card-unique.
- [Phase 46]: [46-07] Section-header ARB keys (analyticsGroupHeaderTime/Distribution/Stories) now orphaned (zero source consumers) — DEFERRED to Phase 47 ARB sweep (removal needs gen-l10n + force-add of gitignored generated files). JOY-01/JOY-02/REDES-03/GUARD-02 flipped to Complete now the round-5 B lineup is user-visible. Full suite 2971/2971 green; analyze 0.
- [Phase 46]: [46-07] The STATE.md 46-01 sequencing blocker was ALREADY RESOLVED by 46-01 (it deleted the trend presentation consumers alongside the data layer); 46-07 verified absence + completed the integration. Marked resolved.
- [Phase ?]: [Phase 47]: [47-02]: GetJoyCategoryAmountsUseCase refactored to a single-pass <String,int> accumulate keyed by l1AncestorOf (replaces the O(n·k) distinct-L1-set + per-L1 l1RollupFromTransactions loop); false 'There is NO second rollup loop here' docstring removed; D-11 single source intact; per-L1 amounts byte-identical (existing 6 unit tests green, unchanged); no findByBookIds widening; analyze 0 (WR-03/D-04, GUARD-04)
- [Phase 47]: [47-03]: Deleted 3 orphan section-header ARB keys (analyticsGroupHeaderTime/Distribution/Stories) symmetrically across en/ja/zh + regenerated lib/generated/ via gen-l10n + git add -f (Phase-46 gitignored-yet-tracked gotcha); analyticsCategoryDonutOther retained for 47-01 WR-02; parity green, analyze 0 (GUARD-03/D-15)
- [Phase 47]: [47-04]: Authored anti_toxicity_phase47_test.dart (D-14) — 36-case sweep over the 5 round-5 B cards × en/ja/zh × {value/empty/other/inline-expand/self-hide}; forbidden en/ja/zh lists copied VERBATIM from anti_toxicity_phase16 (D-13, never relaxed); WR-02 >10-L1 donut Other state exercised so analyticsCategoryDonutOther sweeps clean (D-03); per-state overrides LOCAL+complete + added _expectRenderedText/donut_legend_row_other/inline_panel coverage guards so a failed override can't trivialize the sweep (Pitfall 1); 36/36 green, analyze 0 (GUARD-02/GUARD-03). NOTE: gsd-tools CLI unavailable in this exec env — STATE.md/ROADMAP.md updated by hand.
- [Phase ?]: [47-05] Authored 8 golden tests + 48 macOS PNG baselines for round-5 B analytics (GUARD-04 closed); all wrap PRODUCTION AppTheme so context.palette resolves real ADR-019 — bare ThemeData validates layout but NOT palette. Scoped --update-goldens to the 8 new files (clean diff attribution). Off-macOS reduces to baseline-existence via flutter_test_config.
- [Phase ?]: [Phase 47]: 47-06: full flutter test gate 3057/3057 + analyze 0 + cleaned coverage 80.48% (GUARD-04); on-device D-10 visual UAT all 10 items PASS on physical iOS locale=ja, user-approved 2026-06-20 (GUARD-05, D-12 no defer path). Plan 6/6 — Phase 47 ready_for_verification.

## Operator Next Steps

- Review/approve the v1.8 roadmap, then run `/gsd-plan-phase 43` to begin the HTML 设计探索关卡 (Design Gate).

### Blockers

- ~~46-01 Task 2 sequencing conflict: plan deletes the 6-month trend DATA layer but reserves PRESENTATION consumers (total_six_month_card.dart, monthly_spend_trend_bar_chart.dart, registry spec + registry_test + 3 screen tests) for wave-3 46-07.~~ **RESOLVED (46-01 + 46-07):** 46-01 resolved it at the time by ALSO deleting total_six_month_card.dart + monthly_spend_trend_bar_chart.dart + the Time section header + their registry specs (registry → 9 specs) so the data-only deletion compiled. 46-07 then verified those two files were already absent (no re-delete) and completed the round-5 B integration: re-ordered the registry to the flat 5-card lineup, deleted the remaining 4 dead files (best_joy_card, kpi_hero_card, largest_expense_card, analytics_screen_section_header), and updated the registry/screen/anti-toxicity tests in lockstep. Zero dangling references; full suite 2971/2971 green. No active blockers.
