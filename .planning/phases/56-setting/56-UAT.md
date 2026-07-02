---
status: complete
phase: 56-setting
source: [56-01-SUMMARY.md, 56-02-SUMMARY.md, 56-03-SUMMARY.md, 56-04-SUMMARY.md, 56-05-SUMMARY.md, 56-06-SUMMARY.md]
started: 2026-07-01T11:19:30Z
updated: 2026-07-02T00:05:00Z
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
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
