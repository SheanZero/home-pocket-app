---
status: complete
phase: 52-recognition-ux-english-voice
source: [52-01-SUMMARY.md, 52-02-SUMMARY.md, 52-03-SUMMARY.md, 52-04-SUMMARY.md, 52-05-SUMMARY.md, 52-06-SUMMARY.md]
started: 2026-06-24T12:10:43Z
updated: 2026-06-24T12:42:00Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

[testing complete]

## Tests

### 1. Confidence Band Appears After Voice Recognition
expected: After finishing a voice entry, the transaction details form shows the suggested category with a qualitative confidence band beside it — a purely visual indicator (color intensity / border depth / dot fill), with NO number, %, score, or gauge. Accent color matches the ledger (green for 日常/Daily, pink/amber for 悦己/Joy).
result: pass

### 2. Alternate Category Chips Hidden (UAT-directed scope cut)
expected: Per user direction during UAT ("先隐藏掉这些chip"), the alternate-category chip row (≤3 suggested chips + the "More/もっと/其他" exit chip) is HIDDEN. After a voice recognition the form shows only the suggested category + qualitative confidence band; correcting the category is done via the category card's normal edit. Reversible — gated behind TransactionDetailsForm.showAlternateChips (default false).
result: pass
note: |
  Original test was "chips appear + More opens selector"; user decided during UAT they don't want the chips. Implemented a reversible hide: the chip subtree is gated on a @visibleForTesting showAlternateChips flag (default false in production); the confidence band still renders; the deferred category-correction contract (D-05/06/07) is preserved via the category-card → full-selector path (_applyCategorySelection). flutter analyze: 0 issues; full suite 3353/3353 green (added a default-hidden render test; retained chip-path tests opt back in with showAlternateChips: true). Working-tree change, commit pending.

### 3. Picking a Category Clears the Confidence Band
expected: After a voice recognition shows the confidence band, change the category via the category card (full selector). The chosen category applies and the confidence band disappears immediately — the recognition guess is no longer shown once you've made your own choice. (Chips hidden per test 2, so the category card is the correction path.)
result: pass

### 4. No Confidence Band on Manual Entry
expected: When you add a transaction manually (tap the add/FAB and fill the form by hand, not via voice), the form shows no confidence band (and no chips) — it looks like a normal manual-entry form.
result: pass

### 5. Category Correction Is Learned on Save (not on abandon)
expected: Voice-enter a transaction, correct its category (via the category card / full selector), then save. Next time you voice the same keyword, the app remembers your corrected category. But if you correct then abandon/reset (重置 / 连续记账 / back) without saving, nothing is learned — the next recognition is unchanged.
result: pass

### 6. English Category Recognition (capitalized STT)
expected: With the voice locale set to English, speak a category keyword like "coffee", "taxi", or "rent". Even though iOS speech-to-text capitalizes it ("Coffee"), the app resolves the correct category (cafe / transport / housing).
result: pass

### 7. English Merchant & Currency-Word Recognition
expected: Speaking an English/romaji merchant name resolves the matching Japanese merchant (via its English name/alias), and English currency words like "dollars", "euro", "pound" are recognized as the currency.
result: pass

### 8. English Number-Word Amounts
expected: Speak an amount in English words — "fifty dollars" parses as 50; "five fifty" (in a currency/$ context) parses as 5.50. A bare "fifty" with no money context is NOT force-guessed into a wrong amount.
result: pass

### 9. English Voice Works Regardless of App UI Language
expected: With the app UI language set to Japanese or Chinese but the voice locale English, English voice input still recognizes correctly — the voice locale is independent of the app's display language.
result: pass

### 10. No Gamification Text in Recognition UI (all 3 languages)
expected: Across English, Japanese, and Chinese, the recognition surface (band, chips, correction flow) never shows accuracy %, scores, streaks, badges, leaderboards, or any achievement-style wording — only the qualitative band and plain category labels.
result: pass

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
