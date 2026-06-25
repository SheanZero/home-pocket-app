# v1.9 里程碑审计 + 重新启用识别置信度带

**日期:** 2026-06-25
**时间:** 09:14
**任务类型:** [架构决策|Bug修复]
**状态:** 已完成
**相关模块:** MOD-001 基础记账 / 语音录入识别 UX（Phase 52 RECUX-01）

---

## 任务概述

执行 `/gsd-complete-milestone` 前，按 GSD 预检要求先跑 `/gsd-audit-milestone v1.9`（v1.0–v1.8 每个里程碑都有审计，v1.9 缺失）。审计判定 `tech_debt`：20/20 需求满足、4 条跨阶段接缝全部 WIRED、4 条 E2E 流程逻辑层完整、无 blocker。唯一需要用户决策的项是 **T-01：语音识别置信度带 + 备选 chips 在生产环境被隐藏**。用户选择「先重新启用置信度带再关闭里程碑」（审计选项 B），随后实施并验证。

---

## 完成的工作

### 1. v1.9 里程碑审计（gsd-audit-milestone）

- 读取 4 个 phase 的 VERIFICATION.md：49(5/5)、50(4/4)、51(14/14)、52(5/5)，全部 passed。
- 3 源交叉引用需求覆盖（VERIFICATION × SUMMARY frontmatter × REQUIREMENTS 追溯表）：20/20 满足，0 orphan，0 unsatisfied → FAIL gate 未触发。发现 5 个 ID（MERCH-03/XVAL-02/LEDGER-01/02/VEN-02）在 plan SUMMARY frontmatter 漏标（记账瑕疵，非覆盖缺口）。
- 派发 `gsd-integration-checker` 子代理验证跨阶段接缝 + E2E 流程：全部 WIRED/COMPLETE，2 个 WARNING（均非 blocker）。
- 产出 `.planning/v1.9-MILESTONE-AUDIT.md`（status `tech_debt`），commit `2a4520d9`。

### 2. 关键事实核对：置信度带在生产是否渲染

- 集成检查器读代码认为 band 与 chips 都因 `showConfidenceBand || showAlternateChips`（默认均 false）而 dormant，并指 `52-UAT.md` 注释「band still renders」为 stale。
- 直接核对 `transaction_details_form.dart:1247` 渲染门 + docstring + 行内注释，确认集成检查器正确、UAT 注释已被一次「后续 follow-up」推翻：生产环境 band 与 chips **均不渲染**。
- 对照 `52-02-SUMMARY.md`（原始 Plan-02，commit `9cb884fc`）：原设计是 band+chips 仅以 `_band != null` 为门，`showConfidenceBand`/`showAlternateChips` 两个 flag 是后来的 follow-up 为隐藏而加。

### 3. 重新启用置信度带（T-01，commit f00b1487）

`lib/features/accounting/presentation/widgets/transaction_details_form.dart`：
- 渲染门从 `_band != null && (showConfidenceBand || showAlternateChips)` 还原为 `_band != null`；`ConfidenceBandIndicator` 无条件渲染（有 band 即显示）。
- 彻底移除 `showConfidenceBand` 构造参数 + 字段 + docstring（它只为隐藏 band 而存在）。
- 备选 chips 保留在 `showAlternateChips`（默认 false）之后——这是用户在 UAT test 2 真正下达的 cut，可逆。
- 更新行内注释说明新契约。

`test/.../transaction_details_form_correction_test.dart`：
- 「production default」用例改名 + 断言反转：band `findsOneWidget`（RECUX-01 生产可见），chips 仍 `findsNothing`。

### 4. 验证

- `flutter analyze`（改动文件）→ 0 issues。
- 定向：correction + confidence_band + anti_toxicity_phase52 + alternate_chips + voice mic golden = 42/42 pass（mic golden 未受影响，确认无 golden 回归）。
- 扩面：`test/widget/features/accounting/presentation/` + `test/unit/application/voice/` = **406/406 pass**。
- 无 golden 测试推送识别 band（band 仅在 `updateRecognition` 后渲染），故无需重基线。

### 5. 审计记录更新

`.planning/v1.9-MILESTONE-AUDIT.md` 追加 `## Update 2026-06-25` 区段：T-01/T-02 标记 resolved，RECUX-01 升级为 satisfied，残留 T-03/T-04/T-05 为文档/确认级，里程碑维持 `tech_debt`。

---

## 技术决策

- **还原而非翻 flag**：用户判断 band 本应上线、follow-up 过度隐藏，故最诚实的修法是「撤销 follow-up」——移除 `showConfidenceBand` 门、回到 `_band != null`，而不是把默认值翻成 true（后者会留一个语义错位的 `@visibleForTesting` flag）。
- **chips 与 band 解耦处理**：chips 是用户明确要的 cut（保留 flag、默认隐藏、可逆）；band 是误伤（彻底还原）。两者命运不同，分别处置。

### 代码变更统计
- 2 文件改动（1 source + 1 test）；净删除 `showConfidenceBand` flag（构造参数/字段/docstring/3 处门判断）。

---

## 遇到的问题与解决方案

### 问题 1: 集成检查器与 UAT 记录互相矛盾
**症状:** UAT（10/10 人工通过）说「band still renders」，集成检查器（静态读码）说 band dormant。
**原因:** UAT 之后有一次未记入 UAT 的 follow-up 把 band 也隐藏了；UAT 注释因此变 stale。
**解决方案:** 直接读 `transaction_details_form.dart` 渲染门 + docstring 实证，确认代码为准，再对照原始 Plan-02 SUMMARY 还原设计意图。

---

## 测试验证

- [x] 单元/widget 测试通过（406/406，定向 42/42）
- [x] flutter analyze 0 issues
- [ ] 设备人工视觉确认（建议关闭里程碑前在真机/模拟器上确认 band 的 daily-green / joy-pink 配色与位置）
- [x] 代码审查（自查；改动小且有回归测试覆盖）
- [x] 文档已更新（审计记录 Update 区段）

---

## Git 提交记录

```bash
2a4520d9 docs(v1.9): add milestone audit — tech_debt (20/20 reqs, seams wired, recognition UI dormant)
f00b1487 fix(voice): re-enable confidence band in production (RECUX-01)
```

---

## 后续工作

- [ ] T-03（确认）：`transaction_details_form.dart:899` 的旧 Phase-18 商家学习写入与 `:912` 的 Phase-52 KEYWORD 纠错写入在同一 save 同时触发——需用户确认是否双重学习（pre-v1.9，非本次回归）。
- [ ] T-04（流程）：49/51/52 的 Nyquist VALIDATION.md 为 draft（`nyquist_compliant: false`），可选 `/gsd-validate-phase`。
- [ ] T-05（记账）：5 个需求 ID 的 SUMMARY frontmatter 漏标，纯 cosmetic。
- [ ] 运行 `/gsd-complete-milestone v1.9` 归档里程碑。

---

## 参考资源

- `.planning/v1.9-MILESTONE-AUDIT.md`
- `.planning/phases/52-recognition-ux-english-voice/52-UAT.md`(tests 1–3)
- `.planning/phases/52-recognition-ux-english-voice/52-02-SUMMARY.md`(原始 Plan-02 契约)

---

**创建时间:** 2026-06-25 09:14
**作者:** Claude Opus 4.8
