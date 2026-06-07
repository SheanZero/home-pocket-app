# 锁定 textScaler=1.0 + 首页头部微调

**日期:** 2026-06-07
**时间:** 13:45
**任务类型:** Bug修复 / UI调整
**状态:** 已完成
**相关模块:** 全局主题 (core/theme) + 首页 (home)

---

## 任务概述

260604-fyd（大字体钳制 1.2）的后续。用户在真机上看后提出两点：
1. 字体放大比例锁在 1.0，先不放大。
2. 首页头部：左箭头更靠左、与月份间距收紧；月份去黑体、字号和标题一致；布局顺序不变。

---

## 完成的工作

### 1. 锁定 textScaler 为 1.0（commit 1332b381）
- `lib/core/theme/text_scale_clamp.dart`：常量 `kMaxTextScaleFactor=1.2` → 重命名
  `kLockedTextScaleFactor=1.0`；`clampTextScaling` 改为 `MediaQuery.withClampedTextScaling`
  同时锁 `minScaleFactor` 与 `maxScaleFactor` 为 1.0（完全忽略系统字号，双向钳到 1.0）。
- `main.dart` 无需改（仍用 `builder: clampTextScaling`）。
- 测试 `text_scale_clamp_test.dart` 重写：3.0×→1.0、0.5×→1.0、null child 不抛、常量=1.0（4/4 绿）。

### 2. 首页头部微调（commit aadc9f80）
- `lib/features/home/presentation/widgets/hero_header.dart`：
  - 上一月箭头：`alignment: Alignment.centerLeft` + `visualDensity: compact` +
    `constraints minWidth 28→20` → 箭头贴内容左缘(x=28)，去掉居中缩进；箭头与月份间
    距改 `SizedBox(width: 4)`。
  - 月份标签：`AppTextStyles.headlineMedium`(24/w700 黑体) →
    `AppTextStyles.titleMedium`(15) `.copyWith(fontWeight: FontWeight.w500)`（去黑体，
    与 App 标题字号一致）。布局顺序保持不变。
- 产出 `header-before-after.html`/`.png` 改前改后对比（目视确认）。

---

## 测试验证

- [x] `text_scale_clamp_test.dart` 4/4 绿；analyze 0
- [x] `hero_header_test.dart` + `home_header_test.dart` 13/13 绿（无 golden 覆盖头部）；analyze 0
- [x] 改前改后对比图目视确认

---

## Git 提交记录

```bash
1332b381 fix(260607): lock textScaler to 1.0 — ignore system font-size for now
aadc9f80 fix(260607): tighten home header — prev chevron flush-left, lighter title-size month
```

---

## 后续工作

- [ ] 真机复验头部观感 + 大字体确认不再放大
- [ ] 如需进一步调整月份字号/字重（如更细 w400 或更大 16px），一行即可改

---

**创建时间:** 2026-06-07 13:45
**作者:** Claude Opus 4.8
