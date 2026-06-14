---
status: complete
quick_id: 260614-goh
date: 2026-06-14
commit: 117aecd5
---

# Quick Task 260614-goh — Summary

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
