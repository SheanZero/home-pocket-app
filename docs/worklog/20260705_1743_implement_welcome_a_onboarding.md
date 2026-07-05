# Welcome A オンボーディング重皮肤（claude.ai/design 导入实现）

**日期:** 2026-07-05
**时间:** 17:43
**任务类型:** 功能开发（UI 重设计）
**状态:** 已完成（设备端视觉 UAT 待用户确认）
**相关模块:** onboarding（GSD quick task 260705-ks0）

---

## 任务概述

通过 claude_design MCP（DesignSync）从 claude.ai/design 项目「App欢迎页面设计」导入 `Welcome A.dc.html`（案A・静，4 屏 × light/dark 共 8 帧），把现有 onboarding UI 重皮肤为该设计。走 `/gsd-quick` 流程：gsd-planner 出计划 → gsd-executor 在隔离 worktree 中 TDD 执行 → orchestrator 合并收尾。

---

## 完成的工作

### 1. 主要变更

- **设计导入**：DesignSync `get_file` 拉取 70KB 设计源，落盘提交至 `.planning/quick/260705-ks0-implement-welcome-a-screen-from-claude-a/design/Welcome-A.dc.html`（executor worktree 可继承）。
- **Task 1 — 动画基建**（`fcd4b726`）：新增 `lib/features/onboarding/presentation/widgets/onboarding_float_decor.dart`（`FloatyLoop` 上下浮动 + `DriftPetal` 花瓣飘旋装饰组件），带 `OnboardingFloatDecor.animationsEnabled` 静态 kill-switch，接入 `test/flutter_test_config.dart` 全局关闭——否则无限循环 ticker 会挂死 4 个既有 `pumpAndSettle` 测试（含 main_characterization_smoke_test）。
- **Task 2 — 3 页 intro PageView**（RED `00f56de7` → GREEN `a017b9b3`）：`onboarding_intro_screen.dart` 由单屏重建为设计 01–03 三页横向 PageView（ようこそ／プライバシー／記録の悦び），圆点页指示器（active 20px 长条）、右上スキップ、joy pill 徽章、盾牌+3 特性卡（端末内に保存／E2E暗号化／改ざん防止）、满足度图标行（sat1–5，sat4 高亮圈——复用既有 `assets/satisfaction/*.svg`）、次へ×2→はじめる；スキップ与はじめる均走原单一 `onContinue` 回调。
- **Task 3 — settings 重皮肤为设计 04**（RED `c25530e8` → GREEN `7e73b95b`）：头像+相机徽章（映射到既有 `AvatarPickerScreen`，无新拍照功能）、内联姓名输入、表示言語 4 段选择器（日本語/中文/English/自動，带 ValueKey）、通貨単位/音声入力言語 chip 行、主按钮「この設定ではじめる」。全部 D-04/07/08/09/14 状态逻辑、provider 接线、`onConfirmed` 合约原样保留。
- **i18n**：15 个新 ARB key ×3 locale（ja 逐字取自设计稿）+ 对称删除 9 个 0 引用孤儿 `onboardingIntro*` key + `flutter gen-l10n` + `git add -f lib/generated`（Phase 46 教训）。
- **合约不变式**：`onboarding_flow_screen.dart` 与 `onboarding_lock_entry_screen.dart` 与 base 字节级一致（`git diff` 验证）——HI-01 boot gate、PopScope、`onboarding_complete` 最后写入语义全部不动。

### 2. 技术决策

- **palette 零新增 token**：设计 CSS 自定义属性全数映射到既有 `AppPalette`（`--accentLight`→`accentPrimaryLight`、`--joyBorder`→`joyFullnessBorder` 等，多为 hex 精确一致）；禁止从 HTML 抄 hex，`color_literal_scan_test` 为强制门。
- **页内圆点指示器与 D-12 不冲突**：D-12 的「无 flow 级进度条」针对 intro→settings→lock 整体流程；设计稿的 3 点指示器只覆盖 intro 内部分页，属用户通过设计稿的新决定。
- **状态栏（9:41/wifi/电池）为设计稿 mock chrome**，不实现。
- **偏差 2 条**（executor 按 Rule 1/3 记录于 SUMMARY）：`NumberFormatter.currencySymbol` 公开包装（通货 chip 需要）；语言段按钮加 `ValueKey`（测试宿主 en locale 下「English」文本 finder 与音声行值撞车）。

### 3. 代码变更统计

- 17 文件，+1866 / −712（5 个原子提交，fast-forward 合并入 main）
- 新增 2 文件：`onboarding_float_decor.dart`、`onboarding_float_decor_test.dart`

---

## 遇到的问题与解决方案

### 问题 1: DesignSync 认证缺失
**症状:** `DesignSync needs a claude.ai login`（400）。
**解决方案:** 用户执行 `/login` + `/design-login` 后重试成功。

### 问题 2: worktree base drift（已知 gotcha 复现）
**症状:** 第一次 dispatch 的 executor 在 `worktree_branch_check` fail-closed 退出——worktree fork 自 `00e11f89`（远端 origin/HEAD，停在 6/25，落后本地 main 10 天）。
**原因:** 本地 main 未推送，harness 从 stale `origin/HEAD` 创建 worktree（memory: gsd-worktree-base-drift）。
**解决方案:** `git update-ref refs/remotes/origin/main $(git rev-parse main)`（origin/HEAD 为 symbolic ref 自动跟随）后重新 dispatch；guard 机制按设计零改动拦截，无脏状态。

### 问题 3: 执行中途 session 用量限额
**症状:** executor 跑到 Task 2 GREEN 半程被「session limit · resets 5:10pm」打断。
**解决方案:** worktree 与已提交进度（Task 1 + Task 2 RED）完好；限额重置后 SendMessage 恢复同一 agent（上下文完整），从未提交的工作树改动处干净续跑至完成。

---

## 测试验证

- [x] `flutter analyze` — 0 issues
- [x] FULL `flutter test` — 3566/3566 通过，exit 0（未管道截断）
- [x] 架构门全绿：arb_key_parity / hardcoded_cjk_ui_scan / color_literal_scan / main_characterization_smoke
- [x] flow host + lock-entry 字节级不变（WELA-03）
- [ ] 设备端视觉 UAT（light/dark 双主题、动画观感）——待用户确认

---

## Git 提交记录

```
fcd4b726 feat(quick-260705-ks0): add onboarding float/petal decor widgets with test kill-switch
00f56de7 test(quick-260705-ks0): add failing tests for 3-page Welcome A intro PageView
a017b9b3 feat(quick-260705-ks0): rebuild onboarding intro as 3-page Welcome A PageView
c25530e8 test(quick-260705-ks0): add failing tests for design-04 settings re-skin
7e73b95b feat(quick-260705-ks0): re-skin onboarding settings to Welcome A design 04
（另有 docs 提交：a86f9f3a 计划、c32abcf0 设计源、本次收尾 docs 提交）
```

---

## 后续工作

- [ ] 设备端 UAT：真机跑通 onboarding 全流程（3 页滑动/スキップ/设置表单/锁设置），确认 light/dark 视觉与动画
- [ ] 若 UAT 通过可考虑推送 main（本地已领先远端 16+ 提交；origin/main 本地 ref 已被 repoint 作 worktree workaround，push 后自然一致）

---

## 参考资源

- 设计源: `.planning/quick/260705-ks0-implement-welcome-a-screen-from-claude-a/design/Welcome-A.dc.html`
- 计划/总结: 同目录 `260705-ks0-PLAN.md` / `260705-ks0-SUMMARY.md`
- claude.ai/design 项目: 「App欢迎页面设计」(3232306b-b080-4cdf-a672-0455dcb2f410)

---

**创建时间:** 2026-07-05 17:43
**作者:** Claude (Fable 5) — GSD quick orchestrator
