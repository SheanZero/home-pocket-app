---
quick_id: 260518-pf5
description: Home polish — typography spacing, ledger bar visuals, recent-tx style, family-invite zh i18n, analytics title alignment
gathered: 2026-05-18
status: locked_for_planning
mode: quick-validate
---

# Quick Task 260518-pf5: 首页打磨 + Bucket A — Context

> **Locked by user prior to planning. Planner MUST honor this scope and not expand it.**
> Items 3, 4, 9-second-half were carved out into ADR-016 (Joy Metric Visualization Redesign — Proposed) and are explicitly OUT OF SCOPE for this quick task.

<domain>
## Task Boundary

This task implements **Bucket A** of the user's 2026-05-18 home page review. Bucket B (Joy formula + ring redesign + style guideline doc) was deferred to ADR-016 for product discussion.

</domain>

<decisions>
## Locked Scope — 7 Items

### Item 1 — 整体字号 + 间距调整 (HomeHeroCard)
- 本月支出 / 总金额 / 上月支出 视觉挤在一起 → 整体字号放大，行/段间距重新分配，标题与正文要有清晰的视觉层级
- 「本月最爱」标题字号要和「本月支出」标题字号一致（当前本月最爱字号过小，难以识别）
- 改动范围：`lib/features/home/presentation/widgets/home_hero_card.dart` 的 `_hero()` 区域和 `_buildBestJoyStrip()` 标题部分
- **不引入新颜色 token**（颜色系统已锁，见 v1.1 PROJECT.md）

### Item 2 — 双账本 bar
- (a) 标题里"账本"两字去掉：「悦己账本」→「悦己」、「日常账本」→「日常」（注意 i18n：ja/zh/en 三个 ARB 文件都要改对应 key，**不是**改 widget 里的 hardcoded 中文）
- (b) 当同时有悦己+日常分段时，"日常"段当前用灰色填充 → 改成日常账本对应的主题色（参考 PROJECT.md / theme tokens：日常/survival = `#5A9CC8`）
- 找到该 bar widget（可能在 `home_hero_card.dart` 或独立 widget），改填充逻辑

### Item 5 — 去掉"已评分"部分
- 用户反馈"已评分"显示无用，应整段移除
- 需要 grep 找出"已评分"或 `rated` 相关 UI 字符串/widget 的位置
- 同时清理对应 ARB key（若三语都有）和上游 provider 引用（如果该值只被这一处消费）
- **不要**只 hide UI 而留下 dead provider — 一并清理

### Item 6 — 本月最爱 (Best Joy strip) 视觉微调
- 中间文字（商家名等）当前 `fontWeight: w600/bold` → 改成 `w400/normal`
- 金额 + 满意度字号放大（保留 `FontFeature.tabularFigures()` per CLAUDE.md amount display rule）
- 不动 layout / 不动颜色 / 不动 emoji

### Item 7 — 家族招待部分 zh i18n 缺失
- 用户切到 zh locale，但「家族招待」相关 UI 仍显示日文
- 找出该 widget 在 `family/` 或 `accounting/` 下的位置 → 把 hardcoded ja string 改成 `S.of(context).xxx` → 补全 ARB key 到所有三语
- 必须改 ja + zh + en 三个 ARB 文件后跑 `flutter gen-l10n`
- 不限定具体哪几个 string — 由 executor 在该 widget 内全面排查并补齐

### Item 8 — 最近交易（Recent transactions）多项调整
- (a) 金额前的减号 `-` 去掉（"支出"已经通过其他视觉信号传达，再加减号是冗余/误导）
- (b) 悦己账本（soul）的交易行当前显示红色 → 改成统一配色（不要按生存/悦己分色；最近交易列表的金额配色统一）
- (c) 在每一行追加显示该交易的满意度（仅对 soul 交易；survival 交易没有 satisfaction 字段）
  - 推荐用 emoji + 数字或 emoji-only（参考 `satisfaction_emoji_picker.dart` 的 emoji mapping per ADR-014 unipolar positive scale）

### Item 9a — 统计页（AnalyticsScreen）大标题→正文间距对齐主页
- 当前 AnalyticsScreen 顶部大标题与下方正文之间的留白 ≠ 主页"本月" / "总支出"那一组的留白
- 把统计页大标题区域的 vertical spacing 改成与 HomeHeroCard 主标题区域**一致**的数值（要么提取共享常量，要么直接复用现有间距常量）
- **不**新增 design system 文档（item 9b 留给 ADR-016 / Bucket B）

### Claude's Discretion
- **测试策略：** 改的是 UI 层，单元测试覆盖有限。如果某一项已有 widget test，executor 应更新而非删；如果没有，不强制新增。Manual UI verification 写进 SUMMARY.md。
- **commit 颗粒度：** 推荐每个 item 一个 atomic commit（7 个 fix commits + 1 个 docs commit）。如果两项耦合度极高（例如 item 1 与 item 6 都改 HomeHeroCard），可以合并。
- **build_runner：** 改 ARB → `flutter gen-l10n` 而非 build_runner。若改任何 `@riverpod` / `@freezed` 注解代码（item 5 清理 provider 时可能涉及）→ 跑 `flutter pub run build_runner build --delete-conflicting-outputs`。

</decisions>

<out_of_scope>
## ❌ 明确不在本 quick task 范围内

| Item | 原因 | 去处 |
|---|---|---|
| 3 — Joy 公式改为 sum | 撞 ADR-013 锁定 | ADR-016 |
| 4 — 满意度圆环视觉重设 | 与 item 3 同一问题空间 | ADR-016 |
| 9b — 写入项目设计规范文档 | 依赖 item 1 + 9a 落地后再总结 | 留到 ADR-016 决议后单独起 phase |
| 任何 streak / badge / "成就感"语言 | ADR-012 Forbidden Features | 永久禁 |

Executor / planner 在 plan / execute 阶段如果发现自己即将动这些内容 → 停下来标记为 deviation，不要静默实现。

</out_of_scope>

<specifics>
## Specific Implementation Hints (待 planner 验证，非强制)

- 主页 HomeHeroCard 字号建议：用 `AppTextStyles` 现有的 `amountLarge / amountMedium / amountSmall` 体系（CLAUDE.md "Amount Display Style" 节）做对齐，不引入散落的 `TextStyle(fontSize: ...)`
- 日常/悦己色 token 位置：可能在 `lib/core/theme/` 下，对照 PROJECT.md 颜色记录：survival=#5A9CC8, soul=#47B88A
- "本月最爱" 当前实现：`home_hero_card.dart _buildBestJoyStrip()`（per Phase 10 spec）
- 最近交易满意度显示：参考 `satisfaction_emoji_picker.dart` 的 `{2,4,6,8,10} → emoji` mapping（ADR-014）
- "家族招待"可能的 widget 位置：`lib/features/family/presentation/widgets/` 或 `lib/features/accounting/presentation/widgets/`（待 executor 定位）

</specifics>

<canonical_refs>
## Canonical References

- `CLAUDE.md` — i18n rules、Amount Display Style、Widget Parameter Pattern
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` — 硬约束
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — emoji ↔ value mapping (item 8c 满意度显示需要)
- `docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md` — 词汇层级，item 2 改 ARB 时要遵守
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` — 本 quick task **不**触碰的内容的去处
- `.planning/PROJECT.md` — color tokens (#8AB8DA primary, #47B88A soul, #5A9CC8 survival)
- `lib/core/theme/app_text_styles.dart` — typography tokens

</canonical_refs>
