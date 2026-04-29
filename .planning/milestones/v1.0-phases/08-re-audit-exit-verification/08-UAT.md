---
status: complete
phase: 08-re-audit-exit-verification
source: 08-SMOKE-TEST.md
started: 2026-04-28T13:05:53Z
updated: 2026-04-28T13:08:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Transaction CRUD — Create on Survival ledger
expected: On the Survival ledger, create a new transaction with an amount, date, and category. Amount/date/category persist after save and the entry appears in the transaction list.
result: pass

### 2. Transaction CRUD — Edit on Survival ledger
expected: Edit an existing Survival ledger transaction's amount or category. The change reflects in the monthly report.
result: pass

### 3. Transaction CRUD — Delete on Survival ledger
expected: Delete a Survival ledger transaction. It is removed from the transaction list AND from monthly totals.
result: pass

### 4. Transaction CRUD — Create on Soul ledger
expected: On the Soul ledger, create a new transaction with an amount, date, and category. Amount/date/category persist after save and the entry appears in the transaction list.
result: pass

### 5. Transaction CRUD — Edit on Soul ledger
expected: Edit an existing Soul ledger transaction's amount or category. The change reflects in the monthly report.
result: pass

### 6. Transaction CRUD — Delete on Soul ledger
expected: Delete a Soul ledger transaction. It is removed from the transaction list AND from monthly totals.
result: pass

### 7. Ledger switch — Survival → Soul
expected: Switching from Survival to Soul causes the header theme to change (sky-blue → green) and the transaction list refreshes to show Soul entries.
result: pass

### 8. Ledger switch — Soul → Survival
expected: Switching from Soul to Survival causes the header theme to change back (green → sky-blue) and the transaction list refreshes to show Survival entries.
result: pass

### 9. Soul fullness card — localized title
expected: On the home screen, the Soul fullness card renders with a localized title (no hardcoded CJK text leaking into other locales).
result: pass

### 10. Monthly report — JPY formatting (ja locale)
expected: With locale = ja, amounts render as `¥1,235` — JPY symbol, no decimals, tabular figures aligned.
result: pass

### 11. Monthly report — USD formatting (en locale)
expected: With locale = en, amounts render as `$12.35` / `$1,235.00` — USD symbol, 2 decimals, tabular figures aligned.
result: pass

### 12. Monthly report — CNY formatting (zh locale)
expected: With locale = zh, amounts render as `¥12.35` / `¥1,235.00` — CNY (¥) symbol, 2 decimals, tabular figures aligned.
result: pass

### 13. Monthly report — compact display
expected: For totals over 10000, compact display shows `123万` in ja/zh and `$1.23M` in en.
result: pass

### 14. Monthly report — date headers per locale
expected: Date headers render as `2026/04/28` (ja), `04/28/2026` (en), `2026年04月28日` (zh).
result: pass

### 15. Settings — Export backup
expected: Triggering "Export backup" produces an encrypted file at `Document/backups/<date>.aes-256-gcm` (or equivalent path) with size > 0.
result: pass

### 16. Settings — Import backup on fresh install
expected: On a freshly installed app, importing a backup file restores transactions identically — counts, amounts, and ledger assignment all match the export source.
result: pass

### 17. Family sync — Push (A → B)
expected: Device A creates a transaction. Within the sync interval (or on manual sync), device B receives the same transaction (matching id, amount, date, ledger).
result: pass

### 18. Family sync — Pull (B → A)
expected: Device B creates a transaction. Within the sync interval (or on manual sync), device A receives the same transaction (matching id, amount, date, ledger).
result: pass

### 19. Voice input — currency parsing
expected: Speaking a currency amount (e.g., "千二百三十五円" or "1235 yen") causes the form to populate with the parsed numeric amount (e.g., `1235`).
result: pass

### 20. Voice input — form population
expected: Voice input populates the transaction form with the parsed amount AND a sensible default date (today).
result: pass

### 21. Language switch — ja
expected: With locale = ja, all UI text renders in Japanese (no English fallback visible). Amounts render as `¥1,235` and dates as `2026/04/28`.
result: pass

### 22. Language switch — zh
expected: With locale = zh, all UI text renders in Simplified Chinese. Amounts render as `¥1,235.00` and dates as `2026年04月28日`.
result: pass

### 23. Language switch — en
expected: With locale = en, all UI text renders in English. Amounts render as `$1,235.00` and dates as `04/28/2026`.
result: pass

### 24. Language switch — round-trip stability
expected: Round-trip ja → zh → en → ja produces no UI text drift. A string seen on the first ja visit matches the same string on the second ja visit.
result: pass

### 25. ARB UI spot-check — Home screen
expected: On the Home screen, all labels match the active locale (no hardcoded CJK on en, no hardcoded English on ja).
result: pass

### 26. ARB UI spot-check — Analytics screen
expected: On the Analytics screen, all labels match the active locale (titles, axis labels, summary card legends).
result: pass

### 27. ARB UI spot-check — Settings screen
expected: On the Settings screen, all labels match the active locale (backup section, sync section, locale picker itself).
result: pass

### 28. ARB UI spot-check — Transaction form
expected: On the Transaction form, all labels match the active locale (amount label, currency-symbol prefix, date picker labels, ledger-toggle labels).
result: pass

## Summary

total: 28
passed: 28
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
