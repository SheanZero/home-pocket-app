# Phase 56: Setting 法务 + 赞助 + 日本合规 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-01
**Phase:** 56-setting
**Areas discussed:** 法务正文, 承载机制, 特商法呈现, 占位与商店表单

---

## 法务正文（隐私政策 / 利用規約 / 特商法三语正文）

| Option | Description | Selected |
|--------|-------------|----------|
| 占位骨架 + 结构，正文上线前填 | 只写三语结构化占位，最低风险 | |
| 写完整草稿三语正文 | 直接起草可上线的完整三语正文，基于真实数据行为 | ✓ |
| 隐私政策写实，規約/特商法占位 | 折中：仅隐私政策写实 | |

**User's choice:** 写完整草稿三语正文
**Notes:** 仍标注上线前日本法务复核，但本 phase 产出实际草稿内容。

---

## 长文本承载机制

| Option | Description | Selected |
|--------|-------------|----------|
| Bundled per-locale assets (ja/zh/en 文件) | 每语一个 asset 文件按 locale 加载；REQUIREMENTS LEGAL-06 已暗示 | ✓ |
| ARB 长字符串 | 复用既有 i18n 管线，但 ARB 臃肿 + diff 噪声大 | |

**User's choice:** Bundled per-locale assets
**Notes:** 需新增「三语文件都存在」存在性门；短标签仍走 ARB。

---

## 特商法（LEGAL-04）运营者信息呈现

| Option | Description | Selected |
|--------|-------------|----------|
| 「请求时提供」型 | 仅列可请求联系方式，不公开住址/电话；个人开发者隐私友好 | ✓ |
| 完整表記全字段占位 | 列全字段占位，更接近完整表記但字段敏感 | |

**User's choice:** 「请求时提供」型
**Notes:** 完整表記已列为 v2 (LEGAL-V2-01)。联系邮箱占位上线前填。

---

## 托管 URL 占位 + 赞助 URL 占位 + 商店隐私表单 (LEGAL-05)

| Option | Description | Selected |
|--------|-------------|----------|
| URL 集中常量占位 + 商店表单出 Markdown 清单 | URL 集中到 config 常量文件；商店表单出 .planning/ Markdown 清单 | ✓ |
| URL 内联各页，商店表单不在本 phase 范围 | URL 散落各页；商店表单移出交付物 | |

**User's choice:** URL 集中常量占位 + 商店表单出 Markdown 清单
**Notes:** 商店表单口径与 v1.7 汇率出站调用一致。

---

## Claude's Discretion

- 新 `法的情報・応援` 分组 widget 拆分方式、asset 文件格式、详情页排版实现。
- OSS 页用 Flutter 内置 `showLicensePage`（LEGAL-03 已锁）。

## Deferred Ideas

- LEGAL-V2-01 完整特商法全表記 — v2。
- 真实托管/赞助 URL + 运营者联系方式 — 上线前填。
- LOCK-V2-05 ② 主页首帧懒加载 — Phase 55 遗留，v2。
