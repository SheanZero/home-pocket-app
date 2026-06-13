---
phase: quick-260613-ote
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/infrastructure/i18n/formatters/number_formatter.dart
  - test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
autonomous: true
requirements: [QUICK-260613-OTE]
must_haves:
  truths:
    - "长尾币种在 NumberFormatter._getCurrencySymbol 返回真实货币符号（THB→฿, INR→₹, ₱/₫/₽/₺ 等），而非回退三字码"
    - "无通用字形的币种（CHF/AED/SAR）仍以三字码作为约定符号（它们本就用 code 当符号）"
    - "货币选择器红框 grey 列因此显示真实符号（cell 经由 NumberFormatter.formatCurrency(0,...) 提取符号）"
    - "改动只在单一来源 NumberFormatter._getCurrencySymbol；amount 显示全 app 一致受益"
    - "flutter analyze 0；flutter test 全绿；受影响 golden（含 6 个 currency-selector golden）在 macOS 重基线"
  artifacts:
    - path: "lib/infrastructure/i18n/formatters/number_formatter.dart"
      provides: "_getCurrencySymbol 为长尾币种新增真实符号 case"
  key_links:
    - from: "currency_selector_sheet _CurrencyRow symbol cell"
      to: "NumberFormatter.formatCurrency"
      via: "formatCurrency(0, code, locale) 去数字后即符号"
      pattern: "_getCurrencySymbol"
---

<objective>
不常用（长尾）币种在货币选择器红框那一列（grey symbol cell）目前显示的是三字码（CHF/THB/INR…），因为 `NumberFormatter._getCurrencySymbol` 对未列出的币种 `default` 回退为 ISO code。用户要求该列显示**真实货币符号**。

修复点选在唯一来源 `NumberFormatter._getCurrencySymbol`（CLAUDE.md：所有货币经 NumberFormatter，单一来源），这样选择器符号列与全 app 金额显示同时一致受益（如 THB 金额显示 `฿100` 而非 `THB 100`）。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@lib/infrastructure/i18n/formatters/number_formatter.dart
@lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
@test/unit/infrastructure/i18n/formatters/number_formatter_test.dart
@test/golden/currency_selector_sheet_golden_test.dart
</context>

<design_notes>
1. 现状：`_getCurrencySymbol`（number_formatter.dart:57-84）switch 覆盖 JPY/CNY/KRW/USD/EUR/GBP/HKD/AUD/CAD/TWD/SGD（$ 家族用 D-06 消歧 HK$/A$/C$/NT$/S$），`default: return currencyCode;`（D-07 ISO 兜底）。

2. 新增长尾币种符号（权威表，仅在存在公认符号时覆盖；$ 家族沿用 D-06 两字母+$ 消歧风格）：
   - THB → ฿ (U+0E3F)
   - INR → ₹ (U+20B9)
   - IDR → Rp
   - MYR → RM
   - PHP → ₱ (U+20B1)
   - VND → ₫ (U+20AB)
   - NZD → NZ$ (D-06 风格)
   - BRL → R$
   - RUB → ₽ (U+20BD)
   - ZAR → R
   - SEK → kr
   - NOK → kr
   - DKK → kr
   - MXN → MX$ (D-06 风格)
   - TRY → ₺ (U+20BA)
   - PLN → zł
   保持 `default` 兜底不变 —— **CHF / AED / SAR 不新增 case**，继续走 default 返回三字码（它们的约定"符号"就是 code，无通用单字形）。Dart 源码请用 Unicode 转义写非 ASCII 符号（与现有 `'¥'` 风格一致），注释标出可读符号。

3. 注意 SEK/NOK/DKK 三者符号都是 'kr'：选择器里已无 code 列（quick 260613-ohz 已删），靠 旗帜 + 本地化名称（スウェーデン・クローナ 等）区分，可接受。

4. decimals 由 `currencyFractionDigitsFor` 独立解析，不受本次符号改动影响。

5. 选择器符号提取链路：`_CurrencyRow` 用 `NumberFormatter.formatCurrency(0, code, locale).replaceAll(RegExp(r'[\d.,\s]'), '')`。新符号经 NumberFormat.currency 作前缀 → formatCurrency(0,'THB')→`฿0`→去数字→`฿`；`MX$0`→`MX$`；`zł0`→`zł`；`kr0`→`kr`，均正确（replaceAll 去数字/点/逗号/空格，保留字母与符号）。无需改 currency_selector_sheet.dart。

6. 规范：单一来源修改；i18n；不手改生成物；无硬编码（符号集中在该 switch）。
</design_notes>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: NumberFormatter 长尾币种符号 + 单测</name>
  <files>lib/infrastructure/i18n/formatters/number_formatter.dart, test/unit/infrastructure/i18n/formatters/number_formatter_test.dart</files>
  <action>
1) `number_formatter.dart` `_getCurrencySymbol` switch 在现有 case 后、`default` 前新增 design_notes #2 列出的 16 个 case（THB/INR/IDR/MYR/PHP/VND/NZD/BRL/RUB/ZAR/SEK/NOK/DKK/MXN/TRY/PLN），符号用 `\uXXXX` 转义书写（如 THB `'฿'`、INR `'₹'`、PHP `'₱'`、VND `'₫'`、RUB `'₽'`、TRY `'₺'`、PLN `'zł'`），ASCII 的直接写（Rp/RM/NZ\$/R\$/R/kr/MX\$）。`default` 兜底保留（CHF/AED/SAR 不加 case）。
2) `number_formatter_test.dart`：先看现有断言风格（可能已断 default 返回 code）。为新增币种补充断言：`formatCurrency`/`_getCurrencySymbol` 对 THB→含 ฿、INR→含 ₹ 等的预期；并保留/调整任何原本断言这些币种回退 code 的用例（改为新符号契约，不弱化）。CHF/AED/SAR 仍断言回退 code。
  </action>
  <verify>
    <automated>flutter test test/unit/infrastructure/i18n/formatters/number_formatter_test.dart test/unit/application/i18n/formatter_service_test.dart</automated>
  </verify>
  <done>长尾币种返回真实符号；CHF/AED/SAR 仍返回 code；单测绿。</done>
</task>

<task type="auto">
  <name>Task 2: 全量验证 + 受影响 golden 重基线</name>
  <files>test/golden/currency_selector_sheet_golden_test.dart</files>
  <action>
1) `flutter analyze`（0 issues）。
2) `flutter test` 全量。货币选择器 6 个 golden 现在符号列显示真实符号 → 在 **macOS** 重基线（`flutter test --update-goldens test/golden/currency_selector_sheet_golden_test.dart`），重基线前确认 diff 仅为符号列变化（THB→฿ 等），不要盲目更新无关 golden。若其它 golden/widget 测试因这些币种金额显示变化而失败，核对 diff 属预期符号变更后一并 macOS 重基线；非预期失败则停下报告。
3) 再跑一次全量 `flutter test` 确认全绿（含架构测试 hardcoded_cjk_ui_scan）。
  </action>
  <verify>
    <automated>flutter analyze && flutter test</automated>
  </verify>
  <done>analyze 0；flutter test 全绿；受影响 golden 已 macOS 重基线且 diff 仅为符号变更。</done>
</task>

</tasks>

<verification>
- 货币选择器长尾行红框列显示真实符号（฿ ₹ ₱ ₫ ₽ ₺ Rp RM NZ$ R$ R kr MX$ zł），CHF/AED/SAR 显示三字码。
- 全 app 这些币种金额显示一致采用新符号。
- flutter analyze 0；flutter test 全绿；golden macOS 重基线。
</verification>

<success_criteria>
- 长尾币种获得真实货币符号（单一来源 NumberFormatter）。
- 无公认字形者（CHF/AED/SAR）保留 code 兜底。
- 全量 test + analyze 通过；受影响 golden 重基线。
</success_criteria>

<output>
Create `.planning/quick/260613-ote-longtail-currency-symbols/260613-ote-SUMMARY.md` when done
</output>
