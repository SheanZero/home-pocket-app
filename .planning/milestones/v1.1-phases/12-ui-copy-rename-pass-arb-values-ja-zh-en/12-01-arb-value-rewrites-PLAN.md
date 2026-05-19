---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
autonomous: true
requirements:
  - RENAME-01
  - RENAME-02
  - RENAME-03
  - RENAME-04
  - RENAME-06
  - RENAME-07
user_setup: []

must_haves:
  truths:
    - "Across en/ja/zh, soulLedger / survivalLedger / homeHappinessROI / homeSoulFullness ARB values exactly match D-02 locked strings (RENAME-01..04)"
    - "Across en/ja/zh, satisfactionBad / satisfactionSlightlyBad / satisfactionNormal / satisfactionGood / satisfactionVeryGood ARB values exactly match D-03 locked strings (5 picker level keys)"
    - "Across en/ja/zh, satisfactionExcellent ARB value exactly matches D-05 strings (Amazing! / 至福！/ 最爱！) — RENAME-07"
    - "ARB key parity test (test/architecture/arb_key_parity_test.dart) passes — zero key additions, zero key deletions across the three locales"
    - "flutter gen-l10n regenerates lib/generated/app_localizations*.dart with 0 warnings; flutter analyze on lib/ reports 0 issues"
    - "Translation audit evidence (Apple HIG ja, iOS Settings, PayPay/メルカリ/微信支付/支付宝 register notes) recorded in <plan_notes> below — D-06 binding"
  artifacts:
    - path: "lib/l10n/app_en.arb"
      provides: "Updated EN values for 10 keys"
      contains: '"Joy Ledger"'
    - path: "lib/l10n/app_ja.arb"
      provides: "Updated JP values (wellbeing kanji ladder)"
      contains: '"無難"'
    - path: "lib/l10n/app_zh.arb"
      provides: "Updated ZH values"
      contains: '"悦己账本"'
    - path: "lib/generated/app_localizations_ja.dart"
      provides: "Regenerated JP localizations from new ARB"
      contains: "無難"
  key_links:
    - from: "lib/l10n/app_{en,ja,zh}.arb"
      to: "lib/generated/app_localizations*.dart"
      via: "flutter gen-l10n"
      pattern: "S.of(context).soulLedger reads new value at runtime"
    - from: "lib/l10n/*.arb"
      to: "test/architecture/arb_key_parity_test.dart"
      via: "key set comparison"
      pattern: "normalKeys + metadataKeys must remain identical across en/ja/zh"
---

<objective>
Rewrite 10 ARB values per locked decisions D-02 (4 home/ledger keys), D-03 (5 picker level keys), and D-05/RENAME-07 (satisfactionExcellent) across all three locales (en / ja / zh). Keys are NEVER touched. Regenerate `lib/generated/app_localizations*.dart` via `flutter gen-l10n`. Verify the existing ARB-parity architecture test stays green and `flutter analyze` reports zero issues. Capture native-speaker register evidence (D-06) inline.

Purpose: Land the mechanical translation pass that resolves RENAME-01..04 plus the satisfaction-label refresh and the satisfactionExcellent register alignment in one atomic commit, so the picker swap (Plan 02), ADR-015 (Plan 04), and REQUIREMENTS amend (Plan 03) all build on a stable trilingual baseline.

Output: 3 ARB files updated, generated localizations regenerated, ARB-parity test green, register-audit evidence note logged in plan_notes/COMMIT message body.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md
@CLAUDE.md
@.claude/rules/coding-style.md

<interfaces>
<!-- Locked translation table (CONTEXT.md D-02 + D-03 + D-05) — executor must use these EXACT strings -->

D-02: home/ledger keys (4)
| key                | en (line 561/553/98/94)        | ja                          | zh             |
|--------------------|--------------------------------|-----------------------------|----------------|
| soulLedger         | Joy Ledger                     | ときめき帳                   | 悦己账本       |
| survivalLedger     | Daily Ledger                   | 日々の帳                     | 日常账本       |
| homeHappinessROI   | Joy per ¥                      | ハピネス密度                 | 幸福密度       |
| homeSoulFullness   | Joy Index                      | ときめき度                   | 悦己充盈       |

D-03: picker level keys (5)
| key                       | val | en       | ja     | zh   |
|---------------------------|-----|----------|--------|------|
| satisfactionBad           | 2   | Neutral  | 無難   | 平和 |
| satisfactionSlightlyBad   | 4   | OK       | 快適   | OK   |
| satisfactionNormal        | 6   | Good     | 順調   | 不错 |
| satisfactionGood          | 8   | Great    | 満足   | 满足 |
| satisfactionVeryGood      | 10  | Amazing  | 至福   | 最爱 |

D-05 / RENAME-07: bottom hint key (1)
| key                       | val      | en        | ja     | zh    |
|---------------------------|----------|-----------|--------|-------|
| satisfactionExcellent     | (peak)   | Amazing!  | 至福！ | 最爱！|

Current values (to be replaced — verified at planner read time):
- en line 94 survivalLedger="Survival Ledger" → "Daily Ledger"
- en line 98 soulLedger="Soul Ledger" → "Joy Ledger"
- en line 553 homeSoulFullness="Soul Fullness" → "Joy Index"
- en line 561 homeHappinessROI="Happiness ROI" → "Joy per ¥"
- en lines 870/874/878/882/886/890 satisfaction* → see D-03/D-05 table
- ja line 94 survivalLedger="生存帳簿" → "日々の帳"
- ja line 98 soulLedger="魂帳簿" → "ときめき帳"
- ja line 553 homeSoulFullness="魂の充実度" → "ときめき度"
- ja line 561 homeHappinessROI="幸せROI" → "ハピネス密度"
- ja line 870 satisfactionBad="不満" → "無難"
- ja line 874 satisfactionSlightlyBad="やや不満" → "快適"
- ja line 878 satisfactionNormal="普通" → "順調"
- ja line 882 satisfactionGood="良い" → "満足"
- ja line 886 satisfactionVeryGood="とても良い" → "至福"
- ja line 890 satisfactionExcellent="最高！" → "至福！"
- zh line 94 survivalLedger="生存账本" → "日常账本"
- zh line 98 soulLedger="灵魂账本" → "悦己账本"
- zh line 553 homeSoulFullness="灵魂充盈度" → "悦己充盈"
- zh line 561 homeHappinessROI="快乐 ROI" → "幸福密度"
- zh line 870 satisfactionBad="不满" → "平和"
- zh line 874 satisfactionSlightlyBad="稍有不满" → "OK"
- zh line 878 satisfactionNormal="一般" → "不错"
- zh line 882 satisfactionGood="良好" → "满足"
- zh line 886 satisfactionVeryGood="非常好" → "最爱"
- zh line 890 satisfactionExcellent="最好！" → "最爱！"

Note on @description metadata: per Claude's Discretion in CONTEXT.md, only update if generator/CI requires; default = leave description bodies untouched.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Translation audit evidence (D-06 binding)</name>
  <files>(read-only — no file edits in this task; evidence captured in plan_notes / commit body)</files>
  <read_first>
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md (D-06 register-audit binding + D-02/D-03/D-05 locked strings)
    - lib/l10n/app_ja.arb lines 90-105 (current ja survivalLedger / soulLedger to compare register)
    - lib/l10n/app_zh.arb lines 90-105 (current zh values to compare register)
  </read_first>
  <action>
    Conduct the lightweight register-audit step locked by D-06. Compare the locked Phase 12 ja/zh translations against precedent in major shipping product UIs:

    1. Apple HIG ja (developer.apple.com/jp/design/human-interface-guidelines/) — confirm 「無難 / 快適 / 順調 / 満足 / 至福」 are all attested register-appropriate vocabulary in Apple's ja UI guidance (not philosophical-only register).
    2. iOS 「設定」 app ja UI — confirm wellbeing-style kanji vocabulary (e.g., 「快適」 in iOS battery / 「順調」 in fitness contexts) is precedent for product copy.
    3. PayPay / メルカリ ja review-rating UIs — confirm star-scale labels use either 「とても良い」 / 「良い」 / 「普通」 / 「悪い」 OR analogous wellbeing kanji (no register collision with our chosen ladder).
    4. 微信支付 / 支付宝 zh review-rating UIs — confirm 「平和」 (or analogous neutral-positive zh) is register-appropriate for "中性 → no problems" anchor (NOT 「中性」 which is philosophical/physics-register).

    DO NOT block on lack of source-cited evidence — D-02/D-03/D-05 are LOCKED. The audit confirms NO contradiction. If a contradiction is discovered (e.g., 「無難」 carries strongly negative register in modern ja product UI based on attested examples), STOP and surface the conflict to the user; otherwise proceed.

    Record the audit outcome verbatim in the commit message body of Task 4 below (a 5-7 line "Register Audit (D-06)" paragraph). The audit is text-only; no file edits in this task.
  </action>
  <verify>
    <automated>echo "manual evidence step — verified by inclusion of 'Register Audit (D-06)' paragraph in Task 4 commit body"</automated>
  </verify>
  <acceptance_criteria>
    - Audit paragraph drafted (held in working memory or scratch file) with 4 bullet points: Apple HIG ja, iOS Settings ja, ja review-app, zh review-app
    - Each bullet states either "attested precedent supports" or "no contradiction found"
    - If ANY bullet finds a contradiction with D-02/D-03/D-05, the executor STOPS and surfaces to user before touching ARB files
  </acceptance_criteria>
  <done>Register-audit evidence drafted; no contradictions to locked decisions found; ready to proceed with ARB edits.</done>
</task>

<task type="auto">
  <name>Task 2: Rewrite 10 ARB values across en/ja/zh (atomic edit, keys untouched)</name>
  <files>lib/l10n/app_en.arb, lib/l10n/app_ja.arb, lib/l10n/app_zh.arb</files>
  <read_first>
    - lib/l10n/app_en.arb lines 88-110 + 548-570 + 865-895 (current values; line ranges to edit)
    - lib/l10n/app_ja.arb lines 88-110 + 548-570 + 865-895
    - lib/l10n/app_zh.arb lines 88-110 + 548-570 + 865-895
    - .planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-CONTEXT.md <interfaces> table above (locked strings)
  </read_first>
  <action>
    Apply 30 value edits (10 keys × 3 locales). Use Edit tool one key at a time per locale (NOT Write) to preserve metadata blocks and JSON formatting. Keys are NEVER renamed; only the value string after the colon is replaced.

    Per-file edits (use the EXACT current strings from interfaces table above as the old_string and EXACT new strings as new_string):

    **lib/l10n/app_en.arb** (6 value rewrites):
    - line 94: `"survivalLedger": "Survival Ledger",` → `"survivalLedger": "Daily Ledger",`
    - line 98: `"soulLedger": "Soul Ledger",` → `"soulLedger": "Joy Ledger",`
    - line 553: `"homeSoulFullness": "Soul Fullness",` → `"homeSoulFullness": "Joy Index",`
    - line 561: `"homeHappinessROI": "Happiness ROI",` → `"homeHappinessROI": "Joy per ¥",`
    - line 870: `"satisfactionBad": "Bad",` → `"satisfactionBad": "Neutral",`
    - line 874: `"satisfactionSlightlyBad": "Slightly bad",` → `"satisfactionSlightlyBad": "OK",`
    - line 878: `"satisfactionNormal": "Normal",` → `"satisfactionNormal": "Good",`
    - line 882: `"satisfactionGood": "Good",` → `"satisfactionGood": "Great",`
    - line 886: `"satisfactionVeryGood": "Very good",` → `"satisfactionVeryGood": "Amazing",`
    - line 890: `"satisfactionExcellent": "Excellent!",` → `"satisfactionExcellent": "Amazing!",`

    **lib/l10n/app_ja.arb** (10 value rewrites):
    - line 94: `"survivalLedger": "生存帳簿",` → `"survivalLedger": "日々の帳",`
    - line 98: `"soulLedger": "魂帳簿",` → `"soulLedger": "ときめき帳",`
    - line 553: `"homeSoulFullness": "魂の充実度",` → `"homeSoulFullness": "ときめき度",`
    - line 561: `"homeHappinessROI": "幸せROI",` → `"homeHappinessROI": "ハピネス密度",`
    - line 870: `"satisfactionBad": "不満",` → `"satisfactionBad": "無難",`
    - line 874: `"satisfactionSlightlyBad": "やや不満",` → `"satisfactionSlightlyBad": "快適",`
    - line 878: `"satisfactionNormal": "普通",` → `"satisfactionNormal": "順調",`
    - line 882: `"satisfactionGood": "良い",` → `"satisfactionGood": "満足",`
    - line 886: `"satisfactionVeryGood": "とても良い",` → `"satisfactionVeryGood": "至福",`
    - line 890: `"satisfactionExcellent": "最高！",` → `"satisfactionExcellent": "至福！",`

    **lib/l10n/app_zh.arb** (10 value rewrites):
    - line 94: `"survivalLedger": "生存账本",` → `"survivalLedger": "日常账本",`
    - line 98: `"soulLedger": "灵魂账本",` → `"soulLedger": "悦己账本",`
    - line 553: `"homeSoulFullness": "灵魂充盈度",` → `"homeSoulFullness": "悦己充盈",`
    - line 561: `"homeHappinessROI": "快乐 ROI",` → `"homeHappinessROI": "幸福密度",`
    - line 870: `"satisfactionBad": "不满",` → `"satisfactionBad": "平和",`
    - line 874: `"satisfactionSlightlyBad": "稍有不满",` → `"satisfactionSlightlyBad": "OK",`
    - line 878: `"satisfactionNormal": "一般",` → `"satisfactionNormal": "不错",`
    - line 882: `"satisfactionGood": "良好",` → `"satisfactionGood": "满足",`
    - line 886: `"satisfactionVeryGood": "非常好",` → `"satisfactionVeryGood": "最爱",`
    - line 890: `"satisfactionExcellent": "最好！",` → `"satisfactionExcellent": "最爱！",`

    DO NOT modify @{key} description blocks. DO NOT add or rename keys. DO NOT touch any other ARB key.

    The full-width Japanese exclamation mark "！" (U+FF01) and Chinese "！" must be preserved as full-width — DO NOT replace with ASCII "!" except for the EN value "Amazing!".
  </action>
  <verify>
    <automated>flutter test test/architecture/arb_key_parity_test.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c '"soulLedger": "Joy Ledger"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"soulLedger": "ときめき帳"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"soulLedger": "悦己账本"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"survivalLedger": "Daily Ledger"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"survivalLedger": "日々の帳"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"survivalLedger": "日常账本"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"homeHappinessROI": "Joy per ¥"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"homeHappinessROI": "ハピネス密度"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"homeHappinessROI": "幸福密度"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"homeSoulFullness": "Joy Index"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"homeSoulFullness": "ときめき度"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"homeSoulFullness": "悦己充盈"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionBad": "Neutral"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionBad": "無難"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionBad": "平和"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionSlightlyBad": "OK"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionSlightlyBad": "快適"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionSlightlyBad": "OK"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionNormal": "Good"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionNormal": "順調"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionNormal": "不错"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionGood": "Great"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionGood": "満足"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionGood": "满足"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionVeryGood": "Amazing"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionVeryGood": "至福"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionVeryGood": "最爱"' lib/l10n/app_zh.arb` returns 1
    - `grep -c '"satisfactionExcellent": "Amazing!"' lib/l10n/app_en.arb` returns 1
    - `grep -c '"satisfactionExcellent": "至福！"' lib/l10n/app_ja.arb` returns 1
    - `grep -c '"satisfactionExcellent": "最爱！"' lib/l10n/app_zh.arb` returns 1
    - Forbidden-string grep — `grep -E '"(soulLedger|survivalLedger|homeSoulFullness|homeHappinessROI|satisfactionBad|satisfactionSlightlyBad|satisfactionNormal|satisfactionGood|satisfactionVeryGood|satisfactionExcellent)": "(Soul Ledger|Survival Ledger|Soul Fullness|Happiness ROI|生存帳簿|魂帳簿|魂の充実度|幸せROI|生存账本|灵魂账本|灵魂充盈度|快乐 ROI|不満|やや不満|普通|良い|とても良い|最高！|不满|稍有不满|一般|良好|非常好|最好！|Bad|Slightly bad|Normal|Good|Very good|Excellent!)"' lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb` returns ZERO matches
    - `flutter test test/architecture/arb_key_parity_test.dart` passes (key parity preserved — zero key adds/deletes)
  </acceptance_criteria>
  <done>All 26 EN-grep checks pass for new values, all 30 forbidden-old-value greps return zero, ARB-parity test green.</done>
</task>

<task type="auto">
  <name>Task 3: Regenerate localizations and verify analyzer cleanliness</name>
  <files>lib/generated/app_localizations.dart, lib/generated/app_localizations_en.dart, lib/generated/app_localizations_ja.dart, lib/generated/app_localizations_zh.dart</files>
  <read_first>
    - l10n.yaml (verify output class S, output dir lib/generated, no config edits required)
    - lib/generated/app_localizations_ja.dart (current generated file head — confirm current strings before regen)
  </read_first>
  <action>
    Run `flutter gen-l10n` to regenerate the four localization files from the updated ARB sources. Confirm 0 warnings. Then run `flutter analyze lib/` to confirm 0 issues across the lib tree (new generated strings should not break any consumer; D-04 dead keys homeHappinessROI/homeSoulFullness retain Dart accessors regardless of consumer presence).

    DO NOT manually edit `lib/generated/*.dart` — these are generator output. If `flutter gen-l10n` produces warnings or errors, STOP and investigate the ARB syntax (likely a stray comma or quoting issue from Task 2).
  </action>
  <verify>
    <automated>flutter gen-l10n 2>&1 | tee /tmp/gen-l10n-out.txt; if grep -qiE '(warning|error)' /tmp/gen-l10n-out.txt; then echo FAIL_GEN; exit 1; fi; flutter analyze lib/ 2>&1 | tee /tmp/analyze-out.txt; if ! grep -q "No issues found" /tmp/analyze-out.txt; then echo FAIL_ANALYZE; exit 1; fi; echo PASS</automated>
  </verify>
  <acceptance_criteria>
    - `flutter gen-l10n` exit code 0; stdout/stderr contains zero "warning" or "error" tokens
    - `flutter analyze lib/` reports "No issues found" (0 issues)
    - `grep -c "ときめき帳" lib/generated/app_localizations_ja.dart` returns at least 1 (confirms ja regen propagated soulLedger value)
    - `grep -c "至福！" lib/generated/app_localizations_ja.dart` returns at least 1 (confirms ja regen propagated satisfactionExcellent)
    - `grep -c "悦己账本" lib/generated/app_localizations_zh.dart` returns at least 1 (confirms zh regen)
    - `grep -c "Joy Ledger" lib/generated/app_localizations_en.dart` returns at least 1 (confirms en regen)
  </acceptance_criteria>
  <done>flutter gen-l10n is clean, analyzer is clean, generated files contain the new translations.</done>
</task>

<task type="auto">
  <name>Task 4: Commit ARB rewrite + regen with register-audit evidence in commit body</name>
  <files>(git commit only — no further file edits)</files>
  <read_first>
    - .claude/rules/git-workflow.md (commit message format)
    - audit-evidence drafted in Task 1
  </read_first>
  <action>
    Stage the 3 ARB files + 4 generated localization files and create a single commit. Use this template:

    ```
    feat(12): rewrite 10 ARB values across en/ja/zh per Phase 12 D-02/D-03/D-05

    Values-only ARB rename pass for Phase 12 (RENAME-01..04 + RENAME-06 register
    review + RENAME-07 satisfactionExcellent). Keys are unchanged; ARB-parity
    architecture test stays green.

    Affected keys (10 × 3 locales = 30 value edits):
    - soulLedger / survivalLedger / homeHappinessROI / homeSoulFullness
    - satisfactionBad / satisfactionSlightlyBad / satisfactionNormal /
      satisfactionGood / satisfactionVeryGood / satisfactionExcellent

    Register Audit (D-06):
    - Apple HIG ja: <attested-precedent-or-no-contradiction>
    - iOS Settings ja: <attested-precedent-or-no-contradiction>
    - ja review-app (PayPay/メルカリ): <attested-precedent-or-no-contradiction>
    - zh review-app (微信支付/支付宝): <attested-precedent-or-no-contradiction>

    Tests:
    - test/architecture/arb_key_parity_test.dart: PASS (no key churn)
    - flutter gen-l10n: 0 warnings
    - flutter analyze lib/: 0 issues

    Refs: D-02, D-03, D-05, D-06; RENAME-01, RENAME-02, RENAME-03, RENAME-04,
    RENAME-06, RENAME-07
    ```

    Substitute the audit bullets with the actual findings from Task 1. Stage exactly: `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, plus the four `lib/generated/app_localizations*.dart` files modified by `flutter gen-l10n`. DO NOT use `git add -A`.
  </action>
  <verify>
    <automated>git log -1 --pretty=format:"%s%n%b" | grep -E "Phase 12 D-02/D-03/D-05" >/dev/null && git diff HEAD~1 --stat | grep -E "lib/l10n/app_(en|ja|zh)\.arb" | wc -l | grep -q 3 && echo PASS || echo FAIL</automated>
  </verify>
  <acceptance_criteria>
    - Commit subject begins with `feat(12):`
    - Commit body contains the literal string `Register Audit (D-06)` followed by 4 bullet lines
    - `git diff HEAD~1 --stat` shows the 3 ARB files + 4 generated files (no other files)
    - `git status` is clean after commit
  </acceptance_criteria>
  <done>One atomic commit on main containing the 30 ARB value edits + regenerated localizations + audit evidence in body.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| ARB → generated Dart | Translation strings flow from ARB files into generator output; no untrusted input. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-12-01 | Tampering | ARB key set drift | mitigate | `arb_key_parity_test.dart` is invoked in Task 2 verification — any accidental key add/delete fails the test. |
| T-12-02 | Information disclosure | None — translation strings are public-facing UI | accept | Strings are designed for end-user display; no PII or secret involved. |
| T-12-03 | Denial of service | Broken `flutter gen-l10n` from invalid JSON | mitigate | Task 3 gates on zero warnings; malformed ARB JSON fails the regenerate step before reaching `flutter analyze`. |
</threat_model>

<verification>
- All 26 grep-target hits return exactly 1 (Task 2 acceptance)
- All 30 forbidden-old-value greps return 0 (Task 2 acceptance)
- `flutter test test/architecture/arb_key_parity_test.dart` passes
- `flutter gen-l10n` produces 0 warnings; `flutter analyze lib/` reports "No issues found"
- Commit on `main` with subject `feat(12):` and `Register Audit (D-06)` block in body
</verification>

<success_criteria>
- 30 ARB value edits applied; 0 ARB key changes
- Generated localizations regenerated and analyzer-clean
- Register-audit evidence captured per D-06 in commit body
- ARB-parity architecture test green
</success_criteria>

<output>
After completion, create `.planning/phases/12-ui-copy-rename-pass-arb-values-ja-zh-en/12-01-SUMMARY.md` summarizing:
- The 30 value edits (link to commit hash)
- Register-audit findings (4 bullets verbatim from commit body)
- Confirmation that arb_key_parity_test.dart + flutter gen-l10n + flutter analyze are all green
- Any deviations from D-02/D-03/D-05 (must be empty per locked decisions)
</output>
