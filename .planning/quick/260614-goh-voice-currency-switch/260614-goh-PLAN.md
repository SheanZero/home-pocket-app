# Quick Task 260614-goh: 语音输入说外币时没有切换货币

**Date:** 2026-06-14
**Mode:** quick (--discuss)
**Status:** Complete

## Problem

语音记账说出外币名称时没有切到对应货币。复现确认根因：`美元` 其实已可识别
（有测试覆盖），真正缺的是用户口语里更自然的说法 —— `人民币` / `美金` 从不在
token 表里，且英语整体被 deferred。

## Decision (--discuss)

加入 `人民币/人民幣→CNY`、`美金→USD`，并把**所有 app 支持的货币**
（USD/EUR/CNY/HKD/GBP/KRW/TWD/AUD/CAD/SGD）扩展到 **zh / ja / en** 口语说法。
不改 `块/块钱`（D-08 锁定为 JPY-native，用户未勾选）。详见 260614-goh-CONTEXT.md。

## Tasks

1. **扩充 token 表** — `lib/shared/constants/voice_currency_suffixes.dart`
   - `all` + `tokenToIso` 覆盖 10 种外币 × zh/ja/en；英语小写存储。
   - `regexAlternation` 改为 longest-first 排序 + `RegExp.escape`（守住包含不变式）。
   - verify: 新增 corpus 用例全绿。
2. **大小写不敏感识别** — `lib/infrastructure/voice/numeral_state_machine.dart`
   - `detectCurrencyToken` 对 text/token 取 `toLowerCase`（CJK 恒等）。
3. **strip regex 大小写不敏感** — `parse_voice_input_use_case.dart` (2 处) +
   `voice_text_parser.dart` (1 处) 加 `caseSensitive: false`。
4. **测试** — `test/infrastructure/voice/currency_detection_test.dart` 新增 29 例
   （zh 口语 / ja 全集 / en / 包含与 leftmost / JPY-native 保持 null）。

## must_haves

- `一百人民币`(zh)→CNY, `五十美金`(zh)→USD
- 每个支持货币在 zh/ja/en 至少一条口语说法被识别
- `美元`(已工作) / 既有 corpus / 架构 CJK 扫描 / JPY 路径 不回归
