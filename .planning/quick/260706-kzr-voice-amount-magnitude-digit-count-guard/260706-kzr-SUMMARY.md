---
quick_id: 260706-kzr
title: 语音金额「量级词↔位数」一致性守卫 — 千=乘数位数+3、万=乘数位数+4（zh/ja/en）
type: feature
status: complete
completed: 2026-07-06
duration: ~35min
tasks_completed: 3/3
subsystem: voice
tags: [voice, amount, itn, magnitude, zh, ja, en]
requires: [quick-260703 four-layer ITN defenses]
provides:
  - expectedDigitCountForAmount L1 pure function (zh/ja/en magnitude → digit count)
  - use-case magnitude arbitration (1b block) with candidate swap undo
  - mixin display arbitration generalized beyond the concat exception
key-files:
  created:
    - lib/application/voice/amount_magnitude_guard.dart
    - test/unit/application/voice/amount_magnitude_guard_test.dart
    - test/unit/application/voice/voice_amount_magnitude_test.dart
  modified:
    - lib/application/voice/parse_voice_input_use_case.dart
    - lib/features/voice/domain/models/voice_parse_result.dart (doc comment only)
    - lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart
    - test/architecture/hardcoded_cjk_ui_scan_test.dart (whitelist entry)
    - test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart
commits:
  - d55d1bc0 test(quick-260706-kzr) T1 RED — expectedDigitCountForAmount matrix
  - fd6ca815 feat(quick-260706-kzr) T1 GREEN — L1 pure function + CJK-scan whitelist
  - 7fd6b7b1 test(quick-260706-kzr) T2 RED — use-case arbitration
  - b4d1aab5 feat(quick-260706-kzr) T2 GREEN — 1b block + candidate swap
  - 88a055f0 test(quick-260706-kzr) T3 RED — mixin scenarios
  - 2b35e5fd feat(quick-260706-kzr) T3 GREEN — rawText-anchored display arbitration
---

# Quick Task 260706-kzr Summary

**One-liner:** 语音金额新增「量级词↔位数」守卫——「3千5百16元」锁定 4 位、「五万」锁定 5 位（zh/ja/en 三语），违位时按 1a候选→状态机重读→alternates 的阶梯采用真实 parse 值并把原读数 swap 进 `amountRepairCandidate` 作一键撤销，零新 ARB key、零 freezed 字段。

## What was built

### T1 — L1 纯函数 `expectedDigitCountForAmount`（d55d1bc0 → fd6ca815）
- `lib/application/voice/amount_magnitude_guard.dart`：顶层纯函数，扫描「(乘数run)(量级token)(低位残部)(货币后缀|串尾)」形态的金额表达式。千/仟/せん/ぜん/thousand → 乘数位数+3；万/萬/まん → +4。
- 乘数 1-999 限界（「千」作万乘数 parse 出 1000 超界 → 千万别 双保险免疫）；小数乘数（3.5千/三点五千）拒绝；zh 缺乘数一律 null，ja 缺乘数仅在货币锚定时缺省 1（千円→4，すみません 串尾不触发）。
- 万表达式先行占位——「一万二千円」的 千 是残部不是独立锚；多个锚定表达式期望互斥 → null（precision over recall）。
- en 分支完全隔离（不触 CJK 状态机，D-14 镜像）；`\bthousand\b` 排除 thousands；kana 乘数/残部经词典全 token 化校验（ごはん 类散文不吞）。
- 22 个测试用例全绿（13 正例 + 9 反例含 千万别/万一/成千上万/1万步/3.5千/99999元/冲突表达式）。

### T2 — use-case 量级仲裁 1b 块（7fd6b7b1 → b4d1aab5）
- `parse_voice_input_use_case.dart`：1a 之后、货币检测（现 1c）之前插入。期望 = primary ?? alternates 顺序首个非 null；仅当 `resolvedAmount` 位数违期望时按序尝试 ① 既有 `amountRepairCandidate` ② 状态机/en词 parser 重读 primary ③ 逐个 alternate 全管线 extractAmount——候选自身位数必须 == 期望才采用。
- 采用即 swap：`resolvedAmount ← 采用值`、`amountRepairCandidate ← 原读数`——既有 1A 通知自动变成「改回原值」撤销 affordance，零新 ARB、零新字段。
- 260703 1a confirmedByAlternate 静默采用一字未动；无量级锚话语行为逐字节回归（250046元 钉死测试）。
- `voice_parse_result.dart` 仅改 `amountRepairCandidate` doc 注释为双生产者泛化语义（未跑 build_runner，无 .freezed.dart 变更）。

### T3 — mixin 显示仲裁泛化 + 全量回归门（88a055f0 → 2b35e5fd）
- `voice_ptt_session_mixin.dart` `_fillFormFromTextInner`：concat 例外原判据不动，追加分支——`data.rawText` 锚定期望位数且 merged 违位、parsed 达位时 `amount = parsedAmount`；其余 merged 优先语义全部不变。
- 4 个 mixin 场景测试驱动真实 merger（2.5s 窗口 commit）：35016→3516 新路径专属证明（concat 探测器对该形状为 null）、53102→5312 回归钉、无锚 merged 优先、双方达位 merged 优先。
- 全量 `flutter test`：**3601 passed, exit 0**（未管道 tail）；`flutter analyze` 0 issues；零 golden 变化。

## must_haves.truths → 具名测试证明

| Truth | 测试 |
|---|---|
| 3千5百16→4位、五万→5位，违位绝不原样落表单 | `amount_magnitude_guard_test.dart` zh/ja/en 正例组 + `voice_ptt_session_mixin_test.dart` "merged 35016 loses to parsed 3516" |
| 53102元 + 五千三百一十二元 alternate → 表单 5312 | `voice_amount_magnitude_test.dart` "zh 53102元…→5312" + mixin "merged 53102 loses to parsed 5312" |
| 千万别/万一/成千上万/1万步/3号 不触发 | `amount_magnitude_guard_test.dart` "precision over recall" 组（含 上个月3号 正例锚定不受扰） |
| 无量级锚行为与 260703 逐字节一致 | `voice_amount_magnitude_test.dart` 250046元/三千五百元 回归钉 + mixin "anchor-free rawText keeps merged priority" + 既有 voice_amount_repair_test 全绿 |

## Deviations from Plan

**1. [Rule 1 - 计划测试向量越界] T2 ja 向量 100002000円 → 5000300円**
- **Found during:** T2 RED 设计
- **Issue:** 计划指定的「100002000円」(100,002,000) 超出 `_extractArabicAmount` 的 <10,000,000 clamp——primary 提取返回 null，量级仲裁的 `resolvedAmount != null` 前置条件永不成立，计划期望的 `amountRepairCandidate == 100002000` 不可能发生。
- **Fix:** 换用同形状且在界内的「5000300円」（五千三百 ITN 拆分 "5000"+"300"，tail 以 0 开头 → concat 探测器同样无法触发，仍只有来源③能修）+ alternate 「五千三百円」→ amount 5300、candidate 5000300。语义意图（零开头 tail 击败 concat 探测器 / swap 撤销锚）完整保留。
- **Files:** test/unit/application/voice/voice_amount_magnitude_test.dart（测试内注释注明）
- **Commit:** 7fd6b7b1

**2. [Rule 2 - 架构测试白名单] hardcoded_cjk_ui_scan whitelist 追加**
- **Found during:** T1 GREEN
- **Issue:** 新守卫文件含 CJK 词法数据（量级 token、数字字符类、kana 数词 key），会触发 hardcoded-CJK 架构扫描。
- **Fix:** 按既有 voice_text_parser.dart 先例把 `lib/application/voice/amount_magnitude_guard.dart` 加入 approvedWhitelist（NLP lexicon = 数据非 UI 文案，白名单是该测试的设计扩展点）。
- **Commit:** fd6ca815

**3. [计划内补强] T3 追加第 4 个场景（35016→3516 新路径专属证明）**
- 计划列出的 3 个 T3 场景中，53102 场景经既有 concat 例外已通过（非 RED）；为满足 TDD RED 门，仿照 T2 的做法追加一个 concat 探测器不可见形状（35016，无可用尾零 head）的场景作为真正的 RED 用例。计划 3 场景全部保留为回归钉。
- **Commit:** 88a055f0

## Verification gate

- [x] `flutter analyze` = 0 issues（每 task 后各跑一次）
- [x] 完整 `flutter test`：3601 passed, exit 0（重定向文件保留退出码，未管道 tail）
- [x] 零新 ARB key、零 .g.dart/.freezed.dart/lib/generated 变更（diff base..HEAD 核验）
- [x] 零 golden 变化（纯逻辑层）
- [x] TDD 门序：每 task test(RED) → feat(GREEN) 提交对齐

## Self-Check: PASSED

- lib/application/voice/amount_magnitude_guard.dart — FOUND
- test/unit/application/voice/amount_magnitude_guard_test.dart — FOUND
- test/unit/application/voice/voice_amount_magnitude_test.dart — FOUND
- Commits d55d1bc0 / fd6ca815 / 7fd6b7b1 / b4d1aab5 / 88a055f0 / 2b35e5fd — all in git log
