---
phase: quick-260613-ohz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/accounting/presentation/widgets/currency_selector_sheet.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
  - test/golden/goldens/currency_selector_sheet_ja.png
  - test/golden/goldens/currency_selector_sheet_zh.png
  - test/golden/goldens/currency_selector_sheet_en.png
  - test/golden/goldens/currency_selector_sheet_dark_ja.png
  - test/golden/goldens/currency_selector_sheet_dark_zh.png
  - test/golden/goldens/currency_selector_sheet_dark_en.png
autonomous: true
requirements: [QUICK-260613-ohz]

must_haves:
  truths:
    - "Each currency row renders as flag → grey symbol/code → name; the bold ISO-code column is gone"
    - "All 19 long-tail currencies show a localized name in zh and ja (not English) when the locale is zh/ja"
    - "English locale still shows English names; englishName remains the final fallback for any unmapped code"
    - "flutter analyze reports 0 issues and the full flutter test suite passes"
  artifacts:
    - path: "lib/features/accounting/presentation/widgets/currency_selector_sheet.dart"
      provides: "Row without bold ISO-code cell; name resolver covering all 30 codes"
      contains: "_localizedCommonZoneName"
    - path: "lib/l10n/app_zh.arb"
      provides: "19 new currencyName* keys (Chf..Pln) in zh"
      contains: "currencyNameChf"
    - path: "lib/l10n/app_ja.arb"
      provides: "19 new currencyName* keys (Chf..Pln) in ja"
      contains: "currencyNameChf"
    - path: "lib/l10n/app_en.arb"
      provides: "19 new currencyName* keys (Chf..Pln) in en"
      contains: "currencyNameChf"
  key_links:
    - from: "currency_selector_sheet.dart"
      to: "S.currencyNameChf ... S.currencyNamePln"
      via: "switch in name resolver"
      pattern: "currencyName(Chf|Thb|Inr|Pln)"
---

<objective>
Two focused changes to the currency picker bottom sheet (`CurrencySelectorSheet`):

1. **Remove the bold ISO-code column.** Every row currently renders `flag → grey symbol(width 40) → bold ISO code(width 44) → name`. Delete the bold ISO-code cell (and its leading 8dp spacer) so each row becomes `flag → grey symbol/code → name`. The grey symbol cell already falls back to the ISO code for currencies without a distinct glyph, so long-tail rows still display their code.

2. **Localize all 19 long-tail currency names for zh/ja (en too).** Today only the 11 common-zone currencies are localized via ARB; the 19 long-tail entries show English only. Add `currencyNameChf … currencyNamePln` keys to all three ARB files and extend the name resolver to cover them. `englishName` stays as the final fallback.

Purpose: cleaner row layout (no redundant code column) and a fully localized currency list.
Output: edited widget + 3 ARB files + regenerated l10n + re-baselined goldens.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md
@lib/features/accounting/presentation/widgets/currency_selector_sheet.dart

Project rules in scope (already loaded via CLAUDE.md):
- i18n: all UI text via `S.of(context)`; update ALL 3 ARB files then run `flutter gen-l10n`; never hand-edit `lib/generated/*`.
- AppTextStyles / palette: no hardcoded styles or colors; no hardcoded strings.
- Golden gotcha: goldens are macOS-baselined; re-baseline ONLY on macOS (`flutter test --update-goldens`). CI (ubuntu) uses BaselineExistenceGoldenComparator.

Verified facts from reading the code:
- Row build is `_CurrencyRow.build` (lines 360-429). Delete the `SizedBox(width: 44)` ISO-code cell at lines 397-409 AND the preceding `const SizedBox(width: 8)` at line 410. Leave the flag cell (28), the 4dp spacer, the grey symbol cell (40), the 4dp spacer, the name `Expanded`, and the selected-state check icon untouched. Do NOT change the `isSelected` accent logic, `showFlag`, the row `ValueKey('currency-row-<code>')`, or symbol derivation.
- `symbol` = `NumberFormatter.formatCurrency(0, code, locale).replaceAll(RegExp(r'[\d.,\s]'), '')` — already falls back to the ISO code for symbol-less currencies (lines 364-366). Keep as-is.
- Long-tail list `_fullIsoList` (lines 68-88): CHF, THB, INR, IDR, MYR, PHP, VND, NZD, BRL, RUB, ZAR, SEK, NOK, DKK, MXN, TRY, AED, SAR, PLN (19 codes).
- Name resolver `_localizedCommonZoneName(S s, String code)` (lines 92-119) switches the 11 common codes → `s.currencyNameXxx`, default → null. `_CurrencyRow` uses `localizedName ?? entry.englishName` (line 363) so a null still falls back.
- `_matches` (lines 187-194) already resolves the localized name for search; no change needed — search just gets better.
- ARB key style (verified at app_ja.arb:2517+): key `currencyNameJpy`, immediately followed by `@currencyNameJpy` with a single `"description"` field. Existing descriptions read `"Localized currency name for XXX (Phase 42-06)"`. Mirror this style; tag the new ones `(quick 260613-ohz)`.
- Existing common-zone keys live around app_{ja,zh,en}.arb lines 2517-2560. Insert the 19 new keys right after `currencyNameCad` (line 2557-2560 in ja), before `conversionPreviewRateRow` (line 2561), in all three files, keeping JSON valid.
- The widget test `manual_one_step_foreign_triple_test.dart` selects USD via `find.byKey(const ValueKey('currency-row-USD'))` (line 201), NOT `find.text('USD')`. Removing the code column does NOT break it — the row key is preserved. No change required there; the full-suite run in Task 3 confirms.

Localized names to use (en / zh / ja):
- CHF: Swiss Franc / 瑞士法郎 / スイス・フラン
- THB: Thai Baht / 泰铢 / タイ・バーツ
- INR: Indian Rupee / 印度卢比 / インド・ルピー
- IDR: Indonesian Rupiah / 印尼盾 / インドネシア・ルピア
- MYR: Malaysian Ringgit / 马来西亚林吉特 / マレーシア・リンギット
- PHP: Philippine Peso / 菲律宾比索 / フィリピン・ペソ
- VND: Vietnamese Dong / 越南盾 / ベトナム・ドン
- NZD: New Zealand Dollar / 新西兰元 / ニュージーランド・ドル
- BRL: Brazilian Real / 巴西雷亚尔 / ブラジル・レアル
- RUB: Russian Ruble / 俄罗斯卢布 / ロシア・ルーブル
- ZAR: South African Rand / 南非兰特 / 南アフリカ・ランド
- SEK: Swedish Krona / 瑞典克朗 / スウェーデン・クローナ
- NOK: Norwegian Krone / 挪威克朗 / ノルウェー・クローネ
- DKK: Danish Krone / 丹麦克朗 / デンマーク・クローネ
- MXN: Mexican Peso / 墨西哥比索 / メキシコ・ペソ
- TRY: Turkish Lira / 土耳其里拉 / トルコ・リラ
- AED: UAE Dirham / 阿联酋迪拉姆 / UAE ディルハム
- SAR: Saudi Riyal / 沙特里亚尔 / サウジ・リヤル
- PLN: Polish Zloty / 波兰兹罗提 / ポーランド・ズウォティ
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add 19 long-tail currency name keys to all three ARB files</name>
  <files>lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb</files>
  <action>In each of the three ARB files, insert 19 new keys immediately after the existing `currencyNameCad` entry (and its `@currencyNameCad` block) and before `conversionPreviewRateRow`. Keys, in this order: currencyNameChf, currencyNameThb, currencyNameInr, currencyNameIdr, currencyNameMyr, currencyNamePhp, currencyNameVnd, currencyNameNzd, currencyNameBrl, currencyNameRub, currencyNameZar, currencyNameSek, currencyNameNok, currencyNameDkk, currencyNameMxn, currencyNameTry, currencyNameAed, currencyNameSar, currencyNamePln. Use the per-locale name strings listed in the context block (en values in app_en.arb, zh in app_zh.arb, ja in app_ja.arb). Mirror the existing style exactly: each key followed by its `@`-metadata block with a single `"description"` field reading `"Localized currency name for XXX (quick 260613-ohz)"`. Keep the JSON valid (commas, no trailing comma before the next existing key). Do NOT touch any other keys. These three files MUST stay in sync (identical key set).</action>
  <verify>
    <automated>for f in ja zh en; do python3 -c "import json,sys; json.load(open('lib/l10n/app_'+'$f'+'.arb'))" || exit 1; done; for f in ja zh en; do test "$(grep -c '"currencyName\(Chf\|Thb\|Inr\|Idr\|Myr\|Php\|Vnd\|Nzd\|Brl\|Rub\|Zar\|Sek\|Nok\|Dkk\|Mxn\|Try\|Aed\|Sar\|Pln\)"' lib/l10n/app_$f.arb)" = "19" || { echo "FAIL $f"; exit 1; }; done; echo OK</automated>
  </verify>
  <done>All three ARB files parse as valid JSON and each contains exactly the 19 new currencyName* keys with locale-appropriate values and `@`-metadata in the established style.</done>
</task>

<task type="auto">
  <name>Task 2: Remove bold ISO-code column and extend name resolver, then run gen-l10n</name>
  <files>lib/features/accounting/presentation/widgets/currency_selector_sheet.dart</files>
  <action>Two edits in `currency_selector_sheet.dart`, then regenerate l10n.

  (a) Remove the bold ISO-code column: in `_CurrencyRow.build`, delete the `SizedBox(width: 44)` cell that wraps `Text(entry.code, ...)` with `FontWeight.w700` (the ~lines 397-409 block labelled `// ISO code`) AND delete the immediately preceding `const SizedBox(width: 8)` (line 410) so no stray spacing remains before the name. Leave everything else in the Row untouched: flag cell (width 28), the 4dp spacer, grey symbol cell (width 40), the 4dp spacer, the name `Expanded`, and the trailing selected check icon. Do not alter `isSelected` accent coloring, `showFlag`, the row `ValueKey`, or the `symbol`/`name` derivation. Update the `_CurrencyRow` doc comment (line 342) and the class-level row-format comment (line 130) to describe the new layout `flag + symbol/code + name` (drop the separate "ISO code" mention).

  (b) Extend `_localizedCommonZoneName` to cover the 19 long-tail codes: add 19 new `case` arms (CHF→`s.currencyNameChf`, THB→`s.currencyNameThb`, … PLN→`s.currencyNamePln`) alongside the existing 11, keeping the `default: return null;` so any future unmapped code still falls back to `englishName` via `localizedName ?? entry.englishName`. Optionally rename nothing — the function name can stay; just broaden its coverage. Update its doc comment (lines 90-91) to say it now resolves both common-zone and long-tail names from ARB.

  Then run code generation: `flutter gen-l10n` (regenerates `lib/generated/app_localizations*.dart`). Do NOT hand-edit generated files.</action>
  <verify>
    <automated>flutter gen-l10n && grep -q 'String get currencyNameChf' lib/generated/app_localizations.dart && grep -q 'String get currencyNamePln' lib/generated/app_localizations.dart && test "$(grep -c 'FontWeight.w700' lib/features/accounting/presentation/widgets/currency_selector_sheet.dart)" = "0" && grep -c 'currencyName\(Chf\|Pln\)' lib/features/accounting/presentation/widgets/currency_selector_sheet.dart && flutter analyze lib/features/accounting/presentation/widgets/currency_selector_sheet.dart</automated>
  </verify>
  <done>The bold w700 ISO-code cell and its 8dp spacer are gone (no `FontWeight.w700` remains in the file); the resolver has all 30 cases (11 common + 19 long-tail); `flutter gen-l10n` produced getters `currencyNameChf`..`currencyNamePln`; analyze on the file reports 0 issues.</done>
</task>

<task type="auto">
  <name>Task 3: Re-baseline goldens, full analyze + test</name>
  <files>test/golden/goldens/currency_selector_sheet_ja.png, test/golden/goldens/currency_selector_sheet_zh.png, test/golden/goldens/currency_selector_sheet_en.png, test/golden/goldens/currency_selector_sheet_dark_ja.png, test/golden/goldens/currency_selector_sheet_dark_zh.png, test/golden/goldens/currency_selector_sheet_dark_en.png</files>
  <action>The row layout (column removed) and zh/ja long-tail names changed, so the 6 `currency_selector_sheet_*` golden baselines must be regenerated. On macOS ONLY (per project gotcha — CI ubuntu uses BaselineExistenceGoldenComparator and cannot pixel-match): run `flutter test --update-goldens test/golden/currency_selector_sheet_golden_test.dart` to rewrite the 6 PNG baselines. Then verify the golden test passes against the new baselines, run `flutter analyze` on the whole project (must be 0 issues), and run the full `flutter test` suite (the architecture/scan tests and `manual_one_step_foreign_triple_test.dart` run here — the latter selects USD by row key so it must still pass). If `manual_one_step_foreign_triple_test.dart` fails because of the column removal (it should not — it uses `find.byKey('currency-row-USD')`, not `find.text('USD')`), update the failing assertion to target the row key, symbol, or localized name — never weaken it to a no-op. Do not modify goldens on a non-macOS host.</action>
  <verify>
    <automated>flutter test test/golden/currency_selector_sheet_golden_test.dart && flutter analyze && flutter test</automated>
  </verify>
  <done>The 6 currency-selector goldens are re-baselined and pass; `flutter analyze` reports 0 issues; the full `flutter test` suite is green (including the foreign-triple widget test and architecture/i18n scan tests).</done>
</task>

</tasks>

<verification>
- `_CurrencyRow.build` no longer contains a `FontWeight.w700` ISO-code cell; row = flag → grey symbol/code → name.
- All 3 ARB files contain the 19 new keys (identical key set) and parse as valid JSON.
- `_localizedCommonZoneName` returns non-null for all 30 codes (11 common + 19 long-tail); `default` still returns null for safety.
- zh/ja long-tail rows show localized names; en shows English; unmapped codes fall back to `englishName`.
- `flutter gen-l10n` ran; generated getters exist; generated files not hand-edited.
- 6 currency-selector goldens re-baselined on macOS; `flutter analyze` 0 issues; full `flutter test` green.
</verification>

<success_criteria>
- Bold ISO-code column removed with no leftover spacing; symbol column and selected-state behavior unchanged.
- All 19 long-tail currencies localized in zh/ja/en via ARB; englishName retained as fallback.
- ARB three-file sync maintained; no hardcoded strings; generated l10n regenerated.
- analyze 0 issues; full test suite passes; goldens updated on macOS only.
</success_criteria>

<output>
Create `.planning/quick/260613-ohz-currency-picker-dedup-l10n/260613-ohz-SUMMARY.md` when done.
</output>
