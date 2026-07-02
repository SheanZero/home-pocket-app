---
status: diagnosed
phase: 56-setting
source: [56-01-SUMMARY.md, 56-02-SUMMARY.md, 56-03-SUMMARY.md, 56-04-SUMMARY.md, 56-05-SUMMARY.md, 56-06-SUMMARY.md]
started: 2026-07-01T11:19:30Z
updated: 2026-07-02T00:20:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Legal & Support section appears in Settings
expected: In Settings, a 法的情報・応援 (Legal & Support) group appears just before the About section, containing 5 rows — privacy policy, Terms of Use, 特商法 notice, OSS licenses, and Support Development (with a steel-blue external-link icon on the sponsor row).
result: pass

### 2. Read the Privacy Policy offline
expected: Tap the privacy-policy row. A full-screen reader opens (AppBar titled Privacy Policy) showing the full policy in your current language, scrollable and text-selectable. It describes on-device / zero-knowledge storage and truthfully names the only outbound flows (exchange-rate fetch; FCM push token when notifications are on) — not a blanket "collects nothing". No network needed to read it.
result: pass

### 3. Read the Terms of Use offline
expected: Tap the 利用規約 / Terms of Use row. A reader opens showing the terms — scope/acceptance, license, free-of-charge with no in-app purchase, voluntary donation (no obligation, no feature gating), disclaimer, and governing law (Japan). Scrollable and selectable.
result: pass

### 4. Read the 特商法 (Commercial Transaction) notice
expected: Tap the 特定商取引法に基づく表記 row. A reader opens showing the 特商法 notice in 請求時提供 style — operator name/address/phone disclosed on request, only a placeholder support email shown, and NO home address or phone number published. Japanese text reads as natural Japanese (no stray Chinese-only vocabulary).
result: issue
reported: "将 经营者姓名 / 地址 / 电话 公开"
severity: major

### 5. Open-source licenses page
expected: Tap the OSS-licenses row. The standard Flutter license page opens, listing the app's packages and their licenses.
result: pass

### 6. Support Development opens external browser
expected: Tap 開発を応援する / Support Development. Your device's external browser (not an in-app WebView, not a payment/IAP dialog, no popup) opens to the sponsor URL. Note: the URL is still a placeholder (example.com/homepocket/support), so the page itself won't be real yet — what matters is that it leaves the app to an external browser. If the browser can't open, a single neutral message appears ("Couldn't open the browser" / ブラウザを開けませんでした) with no crash.
result: pass

### 7. Legal documents follow the app language
expected: Change the app language (e.g. ja → zh → en) in Settings, then reopen any legal document (privacy / terms / 特商法). The document text renders in the newly selected language. An unsupported/edge locale falls back to Japanese without crashing.
result: pass

### 8. About section slimmed to version only
expected: The アプリについて / About section now shows only the app version. The privacy-policy and license entries are NOT duplicated there anymore — they live only in the new Legal & Support group above.
result: pass

## Summary

total: 8
passed: 7
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "特商法 notice publishes the operator's name, address, and phone number directly (full 表記型), not 請求時提供 (disclose-on-request)"
  status: failed
  reason: "User reported: 将 经营者姓名 / 地址 / 电话 公开 — wants operator name/address/phone published directly in the 特商法 notice instead of the current 請求時提供 型 (D-03)"
  severity: major
  test: 4
  root_cause: "Not a bug — Test 4 behaves exactly as built. The 請求時提供 (disclose-on-request) approach is a deliberate, gate-covered LOCKED decision (56-CONTEXT D-03), encoded in two coupled layers: (1) content in the three trilingual tokusho asset drafts, and (2) D-03 itself which explicitly defers full 表記 to v2 (LEGAL-V2-01). User is requesting a compliance-approach reversal to full 表記型 (完全表記). Rendering needs no code change (LegalDocScreen renders assets verbatim); this is asset-content + one test-intent update + a superseding-decision record."
  artifacts:
    - path: "assets/legal/tokusho_ja.md"
      issue: "Line ~19 states 運営者情報（氏名・住所・電話番号）は請求時に開示 / 本ページでは住所・電話番号を公開しておりません; only support@example.com published. Operator/Contact sections must be rewritten to full 表記 (事業者名/所在地/電話番号/運営責任者); drop the '公開しておりません' sentence + v2-deferral framing."
    - path: "assets/legal/tokusho_zh.md"
      issue: "Mirrors ja 請求時提供 wording (line ~19). Same reversal (销售事业者·运营者 / 联系方式); keep ## section-header count identical to ja/en (parity gate)."
    - path: "assets/legal/tokusho_en.md"
      issue: "Mirrors ja 請求時提供 wording (lines ~17-19). Same reversal (Seller/Operator / Contact); keep ## section-header count identical to ja/zh."
    - path: "test/widget/features/settings/legal_doc_screen_test.dart"
      issue: "Lines 64-70: test 'tokusho (ja) renders 請求' asserts bodyText contains '請求' (D-03 intent). A full-表記 rewrite dropping the 請求 wording fails this; assertion + test name/intent must flip to check published operator fields."
    - path: ".planning/phases/56-setting/56-CONTEXT.md"
      issue: "D-03 is a locked, §13a-gate-covered decision. Reversal must be recorded as a NEW superseding decision (append-only convention), not a silent edit; pull LEGAL-V2-01 forward from 'deferred'."
    - path: "test/architecture/legal_asset_parity_test.dart"
      issue: "No change required, but its section-count parity constraint (identical ## count across 3 locales) governs how the rewrite must be structured."
  missing:
    - "Rewrite tokusho_{ja,zh,en}.md Operator/Contact sections to publish 事業者名 / 所在地 / 電話番号 / 運営責任者 directly, keeping ## section-header count identical across all three locales."
    - "Update legal_doc_screen_test.dart:64-70 so the tokusho content assertion checks published operator fields instead of '請求'."
    - "Record a NEW superseding decision reversing D-03 in 56-CONTEXT.md (append-only); move LEGAL-V2-01 out of 'deferred'."
    - "上线前 real-data placeholders the USER must supply (cannot be invented): operator legal name, published address, published phone, real support email (replace support@example.com). Mark as [上线前填真实值] in D-01/D-04 style; keep the pre-launch Japanese-legal-review marker — a published individual-developer address/phone is exactly the privacy trade-off D-03 avoided."
  debug_session: ".planning/debug/tokusho-publish-operator-info.md"
