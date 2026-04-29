# Phase 8 Smoke Test — User-Filled Checklist

**Created:** 2026-04-28
**Phase 8** — Codebase Cleanup Initiative exit verification
**Source of Truth:** `.planning/phases/08-re-audit-exit-verification/08-CONTEXT.md` D-06
**Closes:** ROADMAP.md success criterion 4 ("human smoke test confirms user-observable behavior is identical to the pre-refactor baseline")

> All items must be checked before Phase 8 closes. Each unchecked or failing item is a blocking finding — record it as a new entry in `.planning/audit/re-audit/issues.json` (category: `smoke_discrepancy`) and re-run `dart run scripts/reaudit_diff.dart` to verify the gate. Phase 8 cannot close until reaudit_diff exits 0 AND every box below is ticked.

## 1. Transaction CRUD on both ledgers

- [ ] Create transaction on **Survival ledger**: amount/date/category persisted; appears in transaction list
- [ ] Edit transaction on **Survival ledger**: amount/category change reflects in monthly report
- [ ] Delete transaction on **Survival ledger**: removed from transaction list AND monthly totals
- [ ] Create transaction on **Soul ledger**: amount/date/category persisted; appears in transaction list
- [ ] Edit transaction on **Soul ledger**: amount/category change reflects in monthly report
- [ ] Delete transaction on **Soul ledger**: removed from transaction list AND monthly totals

## 2. Ledger switch (Survival ↔ Soul)

- [ ] Switch from **Survival → Soul**: header theme changes (sky-blue → green), transaction list refreshes to Soul entries
- [ ] Switch from **Soul → Survival**: header theme changes back (green → sky-blue), transaction list refreshes to Survival entries
- [ ] Soul fullness card on home screen renders with localized title (no hardcoded CJK)

## 3. Monthly report screen with currency formatting

- [ ] Locale = **ja**: amounts render as `¥1,235` (JPY, no decimals, tabular figures aligned)
- [ ] Locale = **en**: amounts render as `$12.35` / `$1,235.00` (USD, 2 decimals, tabular figures aligned)
- [ ] Locale = **zh**: amounts render as `¥12.35` / `¥1,235.00` (CNY, 2 decimals, tabular figures aligned)
- [ ] Compact-display amounts (e.g., totals over 10000): `123万` in ja/zh; `$1.23M` in en
- [ ] Date headers render as `2026/04/28` (ja), `04/28/2026` (en), `2026年04月28日` (zh)

## 4. Settings: backup export + import

- [ ] **Export backup**: file produced; `Document/backups/<date>.aes-256-gcm` (or equivalent path) exists with size > 0
- [ ] **Import backup** on a fresh app install: transactions restore identically (counts + amounts + ledger assignment match the export source)

## 5. Family sync push + pull

- [ ] **Push**: device A creates a transaction; within sync interval (or on manual sync), device B receives the same transaction (matching id, amount, date, ledger)
- [ ] **Pull**: device B creates a transaction; within sync interval (or on manual sync), device A receives the same transaction (matching id, amount, date, ledger)

## 6. Voice input

- [ ] Voice input parses currency amount correctly (e.g., spoken "千二百三十五円" or "1235 yen" → form populates with `1235`)
- [ ] Voice input populates transaction form with the parsed amount + a sensible default date (today)

## 7. Language switch (ja → zh → en) with locale-specific formatting

- [ ] **ja**: All UI text in Japanese (no fallback English visible); amount `¥1,235` + date `2026/04/28`
- [ ] **zh**: All UI text in Simplified Chinese; amount `¥1,235.00` + date `2026年04月28日`
- [ ] **en**: All UI text in English; amount `$1,235.00` + date `04/28/2026`
- [ ] Round-trip ja → zh → en → ja produces no UI text drift (a string seen on first ja visit matches the same string on the second ja visit)

## 8. ARB-driven UI text spot-check on Phase-5-touched screens

- [ ] **Home screen**: all labels match the active locale (no hardcoded CJK on en, no hardcoded English on ja)
- [ ] **Analytics screen**: all labels match the active locale (titles, axis labels, summary card legends)
- [ ] **Settings screen**: all labels match the active locale (backup section, sync section, locale picker itself)
- [ ] **Transaction form**: all labels match the active locale (amount label, currency-symbol prefix, date picker labels, ledger-toggle labels)

---

## Sign-off

- [ ] **All checks pass** — Phase 8 close eligible.
- [ ] **Tester name:** ________________________________
- [ ] **Date:** ____________________________________
- [ ] **Build commit hash:** ________________________ (output of `git rev-parse HEAD` at the time of testing)
- [ ] **Build platform:** ___________________________ (e.g., `iOS Simulator iPhone 15 (iOS 17.4)` or `Android Pixel 7 (API 34)`)
- [ ] **Discrepancies found:** [None] / [Recorded as new findings in `.planning/audit/re-audit/issues.json`]
