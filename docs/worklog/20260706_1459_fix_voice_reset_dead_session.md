# 修复语音面板重置按钮死会话点击无效（quick-260706-kax）

**日期:** 2026-07-06
**时间:** 14:59
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** 语音记账（voice PTT session / VoiceRecordPanel）

---

## 任务概述

用户截图报告：添加账目页语音面板显示「停止聆听」+ 红色重置方块（「点击重置重新录入」），点击红色方块完全无反应。本任务先做根因诊断，再经 GSD quick 流水线（planner + worktree executor）TDD 修复。

---

## 完成的工作

### 1. 根因诊断

**Q1 弹层是什么：** 不是错误弹窗——是 260622-nhs 设计的 one-shot 语音会话停止态。识别器在一句话出 final（或 3s 静音）后自然停止，内联面板（`VoiceRecordPanel`，替换数字键盘位置）切到「停止聆听」+ 红色重置方块。属正常设计。

**Q2 点击为何无效（BUG 1，主因）：** `voice_ptt_session_mixin.dart` `resetPttSessionAndRestart()` 入口守卫 `if (!_continuousActive || !mounted) return;`。当会话死于 `onError` 的 fatal 分支（除 `error_no_match`/`error_speech_timeout` 外的任何错误，iOS 上典型是 final 出结果后识别任务收尾报的 `error_retry`/1101 类噪声），该分支把 `_continuousActive=false`，但宿主 `manual_one_step_screen` 的 `_voiceModalOpen` 只在用户点空白处时才关闭——面板于是停留在停止态死状态，每次点重置都被守卫静默早退：转录不清、状态不变、麦克风不重启。

**同族隐患：**
- BUG 2：`resetPttSessionAndRestart` 无重入守卫（`_restarting` 置位但入口不检查），cancel→start 窗口内连点两下 → 并发双 startListening → speech_to_text 插件假死。
- BUG 3：「点击重置重新录入」提示文字被 `Transform.translate(0,-34)` 上移贴近按钮，视觉像按钮标签，但命中后冒泡到面板根 GestureDetector → 误触 onExit（退出面板）而非 onReset。

### 2. 修复内容

- **mixin（`voice_ptt_session_mixin.dart`）**：入口守卫改为 `if (_restarting || !mounted) return;`（修 BUG 2 重入）；清 buffer 的 setState 块显式 `_continuousActive = true`（死会话复活——红色重置按钮永远兑现「重新录入」，且必须在 startListening 前置位，否则恢复后 `_onResult` 的 continuous fill 分支不工作）；belt-and-braces：`!pttSpeechService.isAvailable` 时先幂等 `initialize`，失败回退 stopped、不做乐观 listening 翻转。
- **widget（`voice_listening_overlay.dart`）**：caption 变 reset 命中区，嵌套为 Transform.translate → Visibility → GestureDetector(onReset) → Text（planner 修正了 orchestrator 原始设计：`maintainSize` 代理盒的 bounds-check 会挡住外包 GestureDetector 方案；`RenderTransform.hitTest` 跳过自身 bounds check 逆映射命中点，GestureDetector 必须在 Visibility 内侧，listening 态由 IgnorePointer 保持穿透到面板退出）。

### 3. 代码变更统计

4 文件，+327/-17：
- `lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart`（+36 行区域）
- `lib/features/accounting/presentation/widgets/voice_listening_overlay.dart`（+54 行区域）
- `test/unit/features/accounting/presentation/screens/voice_ptt_session_mixin_test.dart`（+207）
- `test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart`（+47）

---

## 遇到的问题与解决方案

### 问题 1: worktree base drift 复发
**症状:** 首个 executor 的 worktree 从过期 ref `21ae703a` fork（落后 3 提交，缺 pre-dispatch plan commit），base 守卫 fail-closed `exit 42`。
**原因:** 本地 main 未推送，`origin/main` 停在旧提交，`isolation="worktree"` 从 origin/HEAD fork（项目 memory 已知 gotcha）。
**解决方案:** `git update-ref refs/remotes/origin/main <main tip>` 重指本地 ref（下次 fetch/push 自动复原）后重派 executor，干净通过。

### 问题 2: worktree cleanup 被未跟踪 SUMMARY.md 挡住
**症状:** `worktree.cleanup-wave` 报 `worktree_dirty`。
**解决方案:** 先 `cp` SUMMARY.md 到主仓库、`cmp` 校验一致后删除 worktree 副本，重跑 cleanup 成功 merge+remove。

---

## 测试验证

- [x] TDD 先红后绿（每个 RED 按 plan 预测失败后才 GREEN）
- [x] 新增测试：VRESET-01 死会话重置恢复、VRESET-02 重入单 start、VRESET-03 caption tap=reset 非 exit、belt-and-braces 失败回退 stopped
- [x] `flutter analyze` 0 issues（executor + orchestrator 双跑）
- [x] full `flutter test` 3570/3570 通过（executor 直连运行，未 pipe；合并后树 hash 与被测 tip 一致，证据可转移）
- [x] 0 golden 变化（纯 hit-test/守卫改动）
- [ ] 设备端 UAT：真机复现「停止聆听后点重置」路径待用户确认

---

## Git 提交记录

```
28f70d77 test: failing VRESET tests for dead-session voice reset (quick-260706-kax)
f04e2cf7 fix: voice reset revives dead session + reentrancy guard (quick-260706-kax)
0c66d520 test: failing VRESET-03 caption hit-target test (quick-260706-kax)
c6aae5ff fix: make 点击重置重新录入 caption a reset hit-target (quick-260706-kax)
bc699d9c chore: merge executor worktree
55df03ff docs(260706-kax): pre-dispatch plan
```

---

## 后续工作

- [ ] 真机 UAT：复现 fatal error 场景（长时间使用语音后点重置）确认恢复生效
- [ ] 可选跟进：fatal error 时给面板一个可视化「会话已中断」提示（当前仅 toast，用户易错过）

---

## 参考资源

- `.planning/quick/260706-kax-fix-voice-reset-button-dead-session-no-o/`（PLAN/SUMMARY）
- 项目 memory：voice-entry-ios-recognition-gotchas（260622-nhs 假死背景）、gsd-worktree-base-drift

---

**创建时间:** 2026-07-06 14:59
**作者:** Claude (Fable 5)
