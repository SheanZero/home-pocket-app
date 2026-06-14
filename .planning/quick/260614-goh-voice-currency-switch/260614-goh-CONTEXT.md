# Quick Task 260614-goh: 语音输入说美元和人民币时没有切换货币 - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Task Boundary

语音输入记账时，说出外币名称没有切换到对应货币。复现确认：
- `美元` → USD **已可识别**（有测试覆盖 `currency_detection_test.dart`）
- `人民币` / `人民幣` → **完全不识别**（不在 token 列表，仅 bare `元` 在 zh→CNY）
- `美金`（美元口语）→ **不识别**
- `块` / `块钱` → 命中但映射为 JPY-native（不换汇）

根因：`lib/shared/constants/voice_currency_suffixes.dart` 的 token 表只覆盖了
部分书面词，缺口语词 + 缺多语言（英语完全 deferred to v2）。
</domain>

<decisions>
## Implementation Decisions

### 识别词扩充（用户选择）
- ✅ 加入 `人民币` / `人民幣` → CNY
- ✅ 加入 `美金` → USD
- ✅ **现有支持的所有货币都要支持 日文 / 中文 / 英语 的口语说法**
- ❌ 不改 `块` / `块钱`（用户未勾选；D-08 锁定为 JPY-native）— 保持现状，文档记录为已知限制

### 货币范围（来自 currency_selector_sheet 的 supported set）
JPY(native) + USD / EUR / CNY / HKD / GBP / KRW / TWD / AUD / CAD / SGD

### 技术约束
- `NumeralStateMachineBase.detectCurrencyToken` 用 `text.indexOf`（大小写敏感）
  → 英文 token 需大小写不敏感：detection 内对 text/token 取 `toLowerCase`
  （CJK 的 toLowerCase 为恒等，安全）。
- amount 抽取 suffix 分支已是 `caseSensitive: false`；keyword/merchant
  剥离的两处 regex 也补 `caseSensitive: false`，保持一致。
- `all` 必须保持「长 token 在前」不变式：所有含 `元` 的复合词（人民元/港元/
  韩元/台元/新加坡元…）排在 bare `元` 前；所有含 `ドル` 的复合词排在 bare
  `ドル` 前；英语 `X dollar` 多词排在 bare `dollar` 前。
- detection 偏好 explicit-foreign + leftmost，已能正确处理 `カナダドル ⊃ ドル`
  / `australian dollar ⊃ dollar` 这类包含关系。
- JPY-native（円/日元/えん/yen/japanese yen/jpy）不进 `tokenToIso` →
  resolve 为 null（不换汇），保持 Pitfall 1（JPY 路径不变）。

### Claude's Discretion
- 英语 token 避开高碰撞裸词：KRW 用 `korean won`/`korea won`（不加裸 `won`）；
  区域美元一律用多词 `X dollar`；3 字母 ISO 码（usd/cad…）不加入（口语不会念）。
</decisions>

<specifics>
## Specific Ideas

复现脚本结论（已验证）：
```
INPUT="人民币" matched=[]            ← bug
INPUT="美金"   matched=[]            ← bug
INPUT="美元"   matched=[美元, 元]→USD ← 已工作
INPUT="五十块" matched=[块]→null(JPY) ← 不在本次范围
```
</specifics>

<canonical_refs>
## Canonical References

- `lib/shared/constants/voice_currency_suffixes.dart`（token 表 — 单一来源）
- `lib/infrastructure/voice/numeral_state_machine.dart`（detectCurrencyToken）
- `lib/application/voice/parse_voice_input_use_case.dart`（_detectCurrency / _extractKeyword）
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`（_pushVoiceForeignTriple 换汇换货币）
- `test/infrastructure/voice/currency_detection_test.dart`（corpus 测试）
- D-08（locked）：bare `元` zh→CNY / ja→JPY-native；`块` JPY-native
</canonical_refs>
