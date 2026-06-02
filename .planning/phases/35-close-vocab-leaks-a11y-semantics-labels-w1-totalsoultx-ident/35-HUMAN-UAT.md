---
status: partial
phase: 35-close-vocab-leaks-a11y-semantics-labels-w1-totalsoultx-ident
source: [35-VERIFICATION.md]
started: 2026-06-02T01:25:00Z
updated: 2026-06-02T01:25:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Screen-reader announcement of localized ledger chip labels (W1)
expected: On a device/simulator with VoiceOver (iOS) or TalkBack (Android) enabled, open the List tab and tap/focus the ledger-filter chips. The screen reader announces the localized ledger names — '日常' / 'ときめき' (ja), '日常' / '悦己' (zh), or 'Daily' / 'Joy' (en) — and NOT the obsolete English 'Survival ledger' / 'Soul ledger' strings. (Code routes both Semantics labels through l10n.listLedgerDaily / l10n.listLedgerJoy — verified statically; no widget test asserts the Semantics.label values, so the live a11y-tree announcement needs device confirmation.)
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
