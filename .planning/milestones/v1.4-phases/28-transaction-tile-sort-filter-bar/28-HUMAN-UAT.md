---
status: passed
phase: 28-transaction-tile-sort-filter-bar
source: [28-VERIFICATION.md, 28-07-PLAN.md]
started: 2026-05-30T21:15:00Z
updated: 2026-05-30T21:25:00Z
---

## Current Test

[complete — user approved all checks 2026-05-30]

## Tests

### 1. SC#1 — tile fields (LIST-01)
expected: Rows show ledger-color tag badge (blue 生存 / green 魂), category name in ledger color, formatted amount with tabular (aligned) figures, and time HH:mm on the right.
result: passed

### 2. SC#1 — day-group headers
expected: A date header (e.g. "2026年5月30日(金)" in ja) appears above each day's rows.
result: passed

### 3. SC#1 — amount alignment
expected: Digit positions align across rows (tabular, not proportional).
result: passed

### 4. SC#2 — tap-to-edit (ROW-01)
expected: Tapping a row opens TransactionEditScreen pre-populated with that transaction.
result: passed

### 5. SC#2 — reactive update after edit
expected: After editing a field and saving, the list (and calendar header totals) update automatically with no manual refresh.
result: passed

### 6. SC#3 — swipe background (ROW-02)
expected: Swiping a row left reveals a red background with a trash icon.
result: passed

### 7. SC#3 — confirm dialog
expected: Releasing the swipe shows an AlertDialog titled "削除しますか？" with cancel/delete buttons.
result: passed

### 8. SC#3 — cancel delete
expected: Tapping "キャンセル" snaps the row back; nothing is deleted.
result: passed

### 9. SC#3 — confirm delete + calendar refresh
expected: Confirming "削除" removes the row, shows a "削除しました" SnackBar, AND the calendar header monthly total updates immediately (CR-01 fix).
result: passed

### 10. SC#4 — sort label (SORT-01..04)
expected: Sort chip shows the active field name (e.g. "更新日時"), never a generic "Sort".
result: passed

### 11. SC#4 — sort popup menu
expected: Tapping the sort chip opens a menu with Date / Edit time / Amount and a checkmark on the active field.
result: passed

### 12. SC#4 — change sort field
expected: Selecting "金額" updates the chip label and re-orders the list.
result: passed

### 13. SC#4 — toggle direction
expected: Tapping the direction arrow flips up/down and re-orders the list.
result: passed

### 14. SC#5 — ledger filter on (FILTER-01..04)
expected: Tapping "生存" filters to Survival entries; the chip becomes active (blue border/bg).
result: passed

### 15. SC#5 — ledger filter off
expected: Tapping "生存" again clears the filter back to All.
result: passed

### 16. SC#5 — open category sheet
expected: Tapping "カテゴリ" opens the CategoryFilterSheet modal with L1/L2 hierarchy + checkboxes.
result: passed

### 17. SC#5 — apply category filter
expected: Selecting a few L2 categories and tapping "適用" filters the list; the chip shows "カテゴリ (N)".
result: passed

### 18. SC#5 — search
expected: Tapping the search icon expands a text field; typing filters the list.
result: passed

### 19. SC#5 — clear chip
expected: The "クリア" chip appears when any filter is active; tapping it resets all filters.
result: passed

### 20. Empty state — no data
expected: A month with no transactions shows the empty-state icon + placeholder text (not a blank screen).
result: passed

### 21. Empty state — filtered-empty
expected: A filter matching no results shows the filtered-empty state with a "フィルターをクリア" button that clears filters when tapped.
result: passed

## Summary

total: 21
passed: 21
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

## Notes

- Automated gate already PASSED: `flutter analyze` clean, Phase 28 list suite 74/74 green, both architecture scanners green, `flutter build ios --debug --no-codesign` succeeded.
- Pre-existing (NOT Phase 28): 11 HomeHeroCard test failures (7 golden + 4 widget). Phase 28's only non-list change is purely-additive l10n; HomeHeroCard code is untouched. Phase 30 owns golden baselines. Confirm Home tab has no *visual* regression during UAT (check 5/9 calendar refresh), but these test failures are out of scope for Phase 28 sign-off.
- Code review (28-REVIEW.md): 1 Critical + 3 Warnings fixed (commit 234bf9f); 4 Info items deferred (currencyCode→Phase 29, redundant day filter, unused watch(), category chip border).
