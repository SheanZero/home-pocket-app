# 53-01 — Onboarding / 首启引导 QA（DESIGN-01 批准就绪记录）

**Phase:** 53-html（HTML 设计关卡 · 零生产代码）
**Plan:** 53-01
**写于:** 2026-06-29
**性质:** 设计稿 QA 出口记录。对**已选定**的首启引导设计稿做 DESIGN-01 逐元素核对，供 53-04 关卡向用户提交正式确认。一次性设计产物，**无生产代码**。

| 项 | 值 |
|---|---|
| **设计面** | Onboarding / 首启引导（welcome → 基础设置 gate） |
| **选定设计稿** | sketch 001 · `.planning/sketches/001-onboarding-gate/index.html` |
| **选定 tone** | A · 温柔抛茶感（★ 选定；暖色问候 + 大圆角；介绍页讲价值，设置页只露默认值） |
| **覆盖需求** | DESIGN-01 — 欢迎/首启引导流程的 HTML 设计稿产出并经用户确认（含 app 介绍 + UI语言/币种/语音语言三步设置） |
| **流程** | ①介绍页 → ②基础设置（只显默认值 · 変更弹窗 · 提示可后改） |
| **QA 结果** | **PASS（finalized，零编辑）** — 选定 tone-A 已满足 DESIGN-01 全部元素，无需补任何 HTML |

---

## DESIGN-01 逐元素核对（tone A · 温柔抛茶感）

证据均取自 `.planning/sketches/001-onboarding-gate/index.html` 的「A · 温柔抛茶感 ★ 选定」块（第 48–98 行），CJK 串可 grep。

| # | DESIGN-01 元素 | 状态 | 设计稿证据（原文 CJK 串） |
|---|---|---|---|
| 1 | app 介绍 — 隐私 / 端末内暗号化 | ✓ PRESENT | `すべて端末内・暗号化` / `クラウド送信なし。あなたのデータはあなたのもの。` |
| 2 | app 介绍 — 本地优先 / 双账本 | ✓ PRESENT | `日常と悦己、ふたつの帳簿` / `必要な支出と、自分を満たす支出を分けて見る。` |
| 3 | app 介绍 — 语音记录卖点 | ✓ PRESENT | `声でサッと記録` / `「ランチ 800円」と話すだけ。` |
| 4 | 介绍页 start CTA | ✓ PRESENT | `はじめる`（btn-primary） |
| 5 | 三步设置 ① 表示言語（UI语言，默认 日本語） | ✓ PRESENT | `表示言語` → 默认值 `日本語` + `変更` |
| 6 | 三步设置 ② 通貨（记账币种，默认 日本円 ¥） | ✓ PRESENT | `通貨` → 默认值 `日本円 ¥` + `変更` |
| 7 | 三步设置 ③ 音声入力の言語（语音输入语言，默认 日本語） | ✓ PRESENT | `音声入力の言語` → 默认值 `日本語` + `変更` |
| 8 | 変更 on-demand picker（按需弹窗，非一次性填表） | ✓ PRESENT | 每行 `変更` 触发 bottom-sheet（`通貨を選択`：JPY/CNY/USD/EUR 单选 + `決定`） |
| 9 | change-later 提示（可后改） | ✓ PRESENT | `⚙️ これらはあとで「設定」からいつでも変更できます。` |
| 10 | 「只显默认值」第一启动哲学（default-only） | ✓ PRESENT | `おすすめの初期設定です。` + 三行只露默认值，确认按钮 `この設定で始める` |

**核对结论:** 10/10 元素 PRESENT。选定 tone-A 已完整表达 DESIGN-01 的「app 介绍 + UI语言/币种/语音语言三步设置」，且实现为「介绍价值 → 仅默认值 + 按需変更弹窗 + 可后改提示」的两步首启模式。**未应用任何 HTML 编辑**（设计稿本已满足，符合 plan 的零编辑预期）；tones B/C 未触碰。

---

## 下游（Phase 54 实现）继承的约束

本批准设计稿隐含以下硬约束，Phase 54「欢迎/首启引导」实现须遵循（对齐 ROADMAP Phase 54 success criteria + ONBOARD-01..07）：

- **两步首启**：①整体介绍（隐私 / 本地优先 / 双账本 / 语音卖点，介绍部分可跳过）→ ②基础设置（只显默认值，按需 変更）。
- **写穿既有 provider，不新建**：
  - UI语言 → 既有 `localeProvider`（确认后 MaterialApp 即时切换）。
  - 记账币种 → 写入既有 `Book.currency`，**复用 v1.7 货币选择器**，默认 JPY。
  - 语音输入语言 → 写入既有语音 locale 设置，默认 = 所选 UI 语言。
- **gate 判定时机**：在 `AppInitializer` settle 之后、主 shell 之前（`_buildHome()` branch 3）判定，绝不与 init 竞态。
- **`onboarding_complete` 一次性落最后**：仅在用户显式完成引导时落，**绝不从 `currency≠null` 反推**（幂等：完成后再启动直接进主 shell）。
- **可返回 + 进度 + re-entrant**：引导可返回上一步、显示进度、无法卡死。
- **末尾可跳过的应用锁入口**：引导末尾提供可明确跳过的「设置应用锁」入口；跳过后锁保持关闭（衔接 Phase 55）。
- **三语 ARB**：新增引导文案 ja/zh/en 齐全，过 parity + 硬编码 CJK 扫描（实现期约束，本设计关卡不产出 ARB）。

---

## DESIGN-04 零生产代码 gate-exit

本设计面产物仅 `.md` / `.html`，全部位于 `.planning/` 下：

- `.planning/sketches/001-onboarding-gate/index.html`（选定稿，本 plan 未编辑）
- `.planning/phases/53-html/53-01-onboarding-qa.md`（本 QA 记录）

无任何 `.dart` / `pubspec.yaml|lock` / `lib/` / `test/` / ARB 改动。gate 条件 `git diff --name-only | grep -E '\.dart$|pubspec\.(yaml|lock)|/lib/|/test/'` 返回空（DESIGN-04 硬条件满足）。

---

## 待用户确认

> 本记录为 DESIGN-01 的批准就绪 QA。最终关卡批准在 **53-04**（gate closure）汇总三块设计面后由用户一次性给出「approved / 通过」。
