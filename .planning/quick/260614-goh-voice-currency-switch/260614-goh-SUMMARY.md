---
status: complete
quick_id: 260614-goh
date: 2026-06-14
commit: 117aecd5,d2b9df8e
---

# Quick Task 260614-goh — Summary

> **更新 (commit `d2b9df8e`)**：真机复现发现第一处修复（识别词）必要但不充分 ——
> 即使识别成功、表单/落库已切到 USD/CNY，**头部货币药丸仍显示 ¥ JPY**，用户看到的
> 「货币没有切换」其实是这个显示 bug。根因：`voice_input_screen` 调用
> `AmountDisplay(amount: …)` 时**没传 currency**，药丸硬编码默认 JPY。
> 修复：新增 `_displayCurrency`，仅当 `_pushVoiceForeignTriple` 真正推送完整
> triple（汇率解析成功）时切到外币 ISO，并把 symbol+label 传给 `AmountDisplay`。
> `RateUnavailable` 时保持 JPY，确保药丸与落库的 JPY-native 行一致（不出现
> 药丸 USD / 实存 JPY 的静默错配）。+3 widget 测试（USD/CNY 切换、RateUnavailable 保持 JPY）。
> 在线（有汇率）即可端到端生效；这正是真机复现时缺失的一环。

## What changed

语音记账现在能识别用户口语里自然说出的外币名，并切换货币。

**根因复现**：`美元` 早已能识别（有测试），用户真正说的 `人民币` / `美金` 从不在
token 表里 → `detectedCurrency=null` → 表单不换币。英语此前整体 deferred。

**修复**（提交 `117aecd5`）：
- `voice_currency_suffixes.dart`：`all` + `tokenToIso` 扩展到 10 种外币
  （USD/EUR/CNY/HKD/GBP/KRW/TWD/AUD/CAD/SGD）× **zh/ja/en** 口语形。
  英语 token 小写存储；新增 `_longestFirst`，`regexAlternation` 改为
  longest-first 排序 + `RegExp.escape`，守住「长 token 先匹配」不变式。
- `numeral_state_machine.dart`：`detectCurrencyToken` 对 haystack/token 取
  `toLowerCase`（CJK 恒等）→ 英语 STT 大小写（"Dollars"）也能命中；仍返回
  原始大小写 token 供 `tokenToIso` 查表。
- `parse_voice_input_use_case.dart`(2 处) + `voice_text_parser.dart`(1 处)：
  keyword/merchant 剥离 regex 加 `caseSensitive: false`，与 amount regex 一致。

**未改**（用户未勾选，D-08 锁定）：`块`/`块钱` 仍按 JPY-native 处理；bare `元`
仍按 locale 解析（zh→CNY / ja→JPY）。记为已知限制。

## Tests

`test/infrastructure/voice/currency_detection_test.dart` +29 用例：
zh 口语（人民币/美金/港元/澳币/加币/韩元/台币/新加坡元）、ja 全集（米ドル/人民元/
カナダドル/オーストラリアドル/韓国ウォン/台湾ドル/シンガポールドル）、en（dollars/
euros/pounds/yuan/各区域 dollar/korean won）、包含与 leftmost、英语大小写、
JPY-native 保持 null。

## Verification

- `currency_detection_test.dart`: **51/51 green**（先 RED 29 失败 → GREEN）
- voice 套件 `test/infrastructure/voice/` + `test/unit/application/voice/` +
  voice_input_screen_foreign_save: **178/178 green**
- `test/architecture/`（含 hardcoded_cjk_ui_scan）: **47/47 green**
- `flutter analyze`（4 改动文件）: **0 issues**

## Follow-ups (optional)

- `块/块钱` 在 zh locale 视为 CNY（目前 JPY-native）—— 需要时另开 task，涉及 D-08。
- 英语「拼写数字」("fifty dollars") 不解析金额（STT 通常回传数字，影响极小）。
