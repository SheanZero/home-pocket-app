---
status: testing
phase: 42-entry-ui-display-voice
source: [42-VERIFICATION.md]
started: 2026-06-13T14:30:00Z
updated: 2026-06-13T14:30:00Z
---

## Current Test

number: 1
name: Edit-screen date change for a foreign row — D-02 dialog path
expected: |
  Open a saved foreign (e.g. USD) transaction in edit mode whose rate is a manual
  override, change the transaction date → a two-choice ChangeRateConfirmationDialog
  appears (keep manual / re-fetch, NO default). Choosing re-fetch updates the rate
  from the REAL rate service (commit 3b59c127, no longer a stub) and recomputes the
  read-only JPY.
awaiting: user response

## Tests

### 1. Edit-screen date change for a foreign row — D-02 dialog path
expected: Manual-override foreign row + date change → two-choice dialog (keep manual / re-fetch), NO default; re-fetch uses the real rate service and recomputes read-only JPY.
result: [pending]

### 2. Edit-screen date change for a foreign row — D-03 toast path
expected: Foreign row WITHOUT manual override + date change moving JPY >1% → non-blocking toast with Undo (5s) restoring the old rate, using the REAL re-fetched rate.
result: [pending]

### 3. Flag-emoji rendering in CurrencySelectorSheet on real iOS + Android
expected: 🇺🇸 / 🇪🇺 / 🇨🇳 etc. render as recognizable flags (not tofu boxes) on both iOS and Android; EUR / no-1:1-country region fallbacks look acceptable. (Goldens mask flags, so this is device-only.)
result: [pending]

### 4. Live conversion preview visual/temporal behavior during foreign entry
expected: Preview appears below the amount, updates on every keypad tap / currency change / date change; loading is an in-place skeleton (no jump, no keyboard occlusion); stale/fallback rate shows an amber warning label.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
