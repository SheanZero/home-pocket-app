---
phase: quick-260613-ote
plan: 01
subsystem: i18n / number-formatting
tags: [i18n, currency, number-formatter, long-tail]
status: complete
requires:
  - "NumberFormatter._getCurrencySymbol single-source symbol switch (existing)"
provides:
  - "Real currency symbols for 16 long-tail currencies via single source"
affects:
  - "Currency selector grey symbol column (long-tail rows)"
  - "App-wide amount display for these currencies"
tech-stack:
  added: []
  patterns:
    - "Single-source currency symbol resolution (NumberFormatter._getCurrencySymbol)"
    - "Non-ASCII glyphs written as \\uXXXX escapes with readable trailing comment"
key-files:
  created: []
  modified:
    - lib/infrastructure/i18n/formatters/number_formatter.dart
    - test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
decisions:
  - "16 long-tail currencies get real glyphs; CHF/AED/SAR keep ISO-code fallback (no common single glyph — their convention IS the code)"
  - "$-family long-tail (NZD→NZ$, MXN→MX$, BRL→R$) follow existing D-06 two-letter+$ disambiguation style"
  - "SEK/NOK/DKK all return 'kr' — selector disambiguates by flag + localized name (no code column since 260613-ohz)"
  - "No golden re-baseline needed: changed long-tail currencies sit below the 600px visible fold in the selector sheet, so the 6 currency-selector goldens produced zero pixel diff"
metrics:
  duration: ~10min
  completed: 2026-06-13
---

# Quick Task 260613-ote: 长尾币种真实货币符号 Summary

为 16 个长尾币种在唯一来源 `NumberFormatter._getCurrencySymbol` 补充真实货币符号（THB→฿, INR→₹, ₱/₫/₽/₺ 等），货币选择器红框 grey 符号列与全 app 金额显示同时一致受益；CHF/AED/SAR 因无通用字形保留三字码兜底。

## What Was Built

### Task 1 — NumberFormatter 长尾币种符号 + 单测 (TDD)
- **RED** (commit `2d5ae4ba`): 16 个长尾币种断言真实符号 + `isNot(contains(code))`；CHF/AED/SAR 断言仍回退三字码。运行 → 16 个新符号用例红，CHF/AED/SAR 已绿（走 default）。
- **GREEN** (commit `e8ab6f82`): `_getCurrencySymbol` switch 在现有 case 后、`default` 前新增 16 个 case：
  - 非 ASCII 用 `\uXXXX` 转义（匹配现有 `'¥'` 风格，readable 符号在行尾注释）：THB `฿`(฿) / INR `₹`(₹) / PHP `₱`(₱) / VND `₫`(₫) / RUB `₽`(₽) / TRY `₺`(₺) / PLN `zł`(zł)
  - ASCII 直写：IDR `Rp` / MYR `RM` / NZD `NZ$` / BRL `R$` / ZAR `R` / SEK·NOK·DKK `kr` / MXN `MX$`
  - CHF/AED/SAR **不加 case**，继续走 `default` 返回 ISO code（注释说明原因）。
- 单测：`flutter test number_formatter_test.dart formatter_service_test.dart` → 55/55 绿。

### Task 2 — 全量验证 + golden 核对
- `flutter analyze` → **No issues found**（0）。
- `flutter test`（全量，含架构测试 hardcoded_cjk_ui_scan）→ **2838/2838 All tests passed**。
- 6 个 currency-selector golden 单独运行 → 全绿，**无 baseline 文件变更**。长尾币种的符号变化落在选择器 600px 可视折叠之下，未进入 golden 像素 → 无 diff，按约束未盲目 `--update-goldens`。

## Deviations from Plan

None — plan executed exactly as written.

Task 2 预期"受影响 golden 需 macOS 重基线"，实际核对后 6 个 currency-selector golden 零 diff（变更币种在可视折叠之外），符合约束"重基线前确认 diff 仅为符号变化，不盲目更新无关 golden"——因此无 golden 提交，Task 2 为纯验证步骤无代码变更。

## Verification Evidence

- `flutter analyze`: `No issues found! (ran in 3.3s)`
- `flutter test` (full): `All tests passed!` (2838 passed)
- `flutter test test/golden/currency_selector_sheet_golden_test.dart`: 6/6 passed, no baseline change
- `git status --short` (goldens): `no golden file changes`

## Commits

- `2d5ae4ba` test: add failing tests for long-tail currency symbols (260613-ote)
- `e8ab6f82` feat: add real symbols for 16 long-tail currencies (260613-ote)

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/infrastructure/i18n/formatters/number_formatter.dart
- FOUND: test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
- FOUND commit: 2d5ae4ba (RED test)
- FOUND commit: e8ab6f82 (GREEN impl)
