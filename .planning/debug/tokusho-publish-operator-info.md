---
status: diagnosed
trigger: "UAT Test 4 (56-UAT.md): user requests 特商法 notice PUBLISH operator name/address/phone directly (full 表記型) instead of current 請求時提供 (disclose-on-request) approach. 将 经营者姓名 / 地址 / 电话 公开."
created: 2026-07-02T00:10:00Z
updated: 2026-07-02T00:25:00Z
---

## Current Focus

hypothesis: The 請求時提供 approach is encoded across (a) the three tokusho asset drafts (ja/zh/en) which state operator info is disclosed on request + only show a support email, and (b) a LOCKED decision D-03 in 56-CONTEXT.md that a downstream planner would need to supersede. A test/gate may assert absence of address/phone.
test: Read all three tokusho assets, 56-CONTEXT D-03, 56-02/56-06 SUMMARYs, and grep test tree for legal_asset_parity + phone/address absence assertions.
expecting: Confirm exact wording + exact files, identify whether any gate blocks a published address/phone, and enumerate 上线前 real-data placeholders.
next_action: Read 56-02-SUMMARY, 56-06-SUMMARY, all 3 tokusho assets, STATE.md; grep test tree.

## Symptoms

expected: The 特商法 notice publishes the operator's name, address, and phone number directly in-page (full 表記型 / 完全表記).
actual: Current trilingual tokusho drafts use 請求時提供 型 — operator info disclosed only on request; page shows only a placeholder support email, no home address or phone. Deliberate locked decision (56-CONTEXT D-03).
errors: None — content/compliance-approach reversal, not a runtime error.
reproduction: Test 4 in 56-UAT.md — user response "将 经营者姓名 / 地址 / 电话 公开".
started: Discovered during UAT 2026-07-01.

## Eliminated

(none yet)

## Evidence

- timestamp: 2026-07-02T00:10:00Z
  checked: 56-UAT.md Test 4
  found: expected text explicitly describes 請求時提供 style ("operator name/address/phone disclosed on request, only a placeholder support email shown, and NO home address or phone number published"). result=issue, severity=major, reported "将 经营者姓名 / 地址 / 电话 公开". Gap block: truth "特商法 notice publishes operator name/address/phone directly (full 表記型), not 請求時提供" status=failed.
  implication: UAT gap already frames the reversal target (full 表記型). D-03 is cited as the source of current behavior.

- timestamp: 2026-07-02T00:10:00Z
  checked: 56-CONTEXT.md D-03 + deferred
  found: D-03 "採用「请求时提供」型 —— 页面声明「运营者信息可应请求提供」+ 一个联系邮箱（占位，上线前填），不公开个人住址/电话。完整表記（运营者全字段）已列为 v2（LEGAL-V2-01），本 phase 不做。" Deferred lists LEGAL-V2-01 (完整特商法全表記, 运营者全字段) and 真实运营者联系方式 as 上线前 user-filled.
  implication: The reversal = pull LEGAL-V2-01 forward from v2 into a gap-closure, superseding locked D-03. Real operator fields are 上线前 placeholders user must supply.

## Evidence (cont.)

- timestamp: 2026-07-02T00:20:00Z
  checked: assets/legal/tokusho_{ja,zh,en}.md — the 請求時提供 wording
  found: Each file's "販売事業者・運営者 / 销售事业者·运营者 / Seller / Operator" section states operator name/address/phone are disclosed ON REQUEST and deliberately withholds address+phone. ja line 19 "運営者情報（氏名・住所・電話番号）は、ご請求があれば遅滞なく開示します。個人開発者のプライバシー保護のため、本ページでは住所・電話番号を公開しておりません。" zh line 19 mirrors it. en lines 17-19 "Operator information (name, address, telephone number) will be disclosed without delay upon request. To protect the privacy of an individual developer, the address and telephone number are not published on this page." All three publish only placeholder `support@example.com` (§連絡先/联系方式/Contact) + a v2-deferral preamble + a draft-marker footer restating 請求時提供型.
  implication: These 3 asset files are the concrete content to rewrite into full 表記 (publish 事業者名/所在地/電話番号/責任者). Placeholder support email is the only currently-published contact.

- timestamp: 2026-07-02T00:22:00Z
  checked: test tree for gates that would break on a published address/phone
  found: (a) NO test asserts ABSENCE of address/phone/〒/+81 — the only such check was a ONE-TIME manual grep documented in 56-02-SUMMARY.md line 70 (verification prose, not a live test). Test-tree greps for 〒/+81/phone matched only unrelated family_sync deviceName fixtures. (b) LIVE gate that DOES assert current copy: test/widget/features/settings/legal_doc_screen_test.dart:64-70 — test 'tokusho (ja) renders 請求 (請求時提供 copy — LEGAL-04 / D-03)' asserts bodyText contains '請求'. A full-表記 rewrite that drops the 請求 wording FAILS this test; its very intent is now inverted. (c) test/architecture/legal_asset_parity_test.dart enforces `## section-header count matches across all 3 locales of the same doc` (lines 69-92) — restructuring tokusho sections is allowed but MUST stay parallel across ja/zh/en or the parity gate fails. It does not block publishing per se.
  implication: Planner must update legal_doc_screen_test.dart:64-70 (assert published operator fields instead of 請求), keep the ## count identical across the 3 locales, and knows NO absence-gate blocks a published phone/address.

- timestamp: 2026-07-02T00:24:00Z
  checked: 56-04 rendering path + ARB + store-privacy checklist 口径 impact
  found: LegalDocScreen (56-04) renders the asset verbatim as SelectableText — content lives entirely in the 3 asset files; no rendering-code or ARB change needed (tokushoNotice label + LegalDoc.tokusho enum unchanged). 56-store-privacy-form-checklist.md 口径 is about DATA FLOWS (F1 on-device, F2 fx fetch, F3 FCM token, F4 P2P, F5 no ads) — operator identity/contact is NOT a data-flow item, so publishing operator name/address/phone does NOT change the store-privacy F1-F5 口径 (only the "support email" placeholder is shared and stays a 上线前 fill-in).
  implication: Change is asset-content-only + one widget-test update; store-privacy checklist and privacy/terms drafts are unaffected.

## Resolution

root_cause: |
  The 請求時提供 (disclose-on-request) behavior is a DELIBERATE, INTENTIONALLY-LOCKED design
  decision — NOT a bug. It is encoded in two coupled layers:
  (1) CONTENT: the three trilingual drafts assets/legal/tokusho_{ja,zh,en}.md, whose
      "Seller/Operator" section states operator name/address/phone are disclosed only on
      request and explicitly withholds address+phone, publishing only a placeholder
      support@example.com. Authored by plan 56-02 (commit 28a79b0a).
  (2) DECISION: 56-CONTEXT.md D-03 ("採用「请求时提供」型 … 不公开个人住址/电话") locks this
      approach, with full 表記 explicitly DEFERRED to v2 as LEGAL-V2-01 (56-CONTEXT deferred
      list + tokusho preamble in all 3 assets). 56-02-SUMMARY.md and 56-06-SUMMARY.md re-lock
      the 口径. D-03 passed the phase's §13a decision-coverage gate (STATE.md: D-01..D-05
      covered) so it is a first-class locked phase decision.
  Reversing to full 表記型 therefore means (a) rewriting the 3 asset drafts, (b) SUPERSEDING a
  locked decision D-03 by pulling deferred LEGAL-V2-01 forward, and (c) updating the one live
  content-gate test that asserts the 請求 copy. No runtime error exists — UAT Test 4 behaves
  exactly as designed; the user is requesting a compliance-approach reversal.
fix: (n/a - diagnose only, goal=find_root_cause_only)
verification: (n/a)
files_changed: []
real_data_placeholders_needed_before_launch:
  - operator legal name (real 事業者/運営者 氏名 — cannot be invented)
  - published address (real 所在地 — currently withheld by design)
  - published phone number (real 電話番号 — currently withheld by design)
  - support@example.com -> real support email (already a 上线前 placeholder)
