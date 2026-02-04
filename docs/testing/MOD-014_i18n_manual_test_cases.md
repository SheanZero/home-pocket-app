# MOD-014 Internationalization (i18n) Manual Test Cases

**Module:** MOD-014 Internationalization
**Test Type:** Manual Testing
**Version:** 1.0
**Created:** 2026-02-04
**Test Environment:** iOS 14+, Android 7+ (API 24+)

---

## Test Preparation

### Prerequisites
- Device/emulator with iOS 14+ or Android 7+ (API 24+)
- App installed and launched
- Access to I18n Test screen via "I18n Test" button on home page

### Test Data
- Date: 2026年2月4日 (February 4, 2026)
- DateTime: 2026年2月4日 14:30 (February 4, 2026, 2:30 PM)
- Number: 1,234,567.89
- Amount: ¥1,234.56 (JPY), $1,234.56 (USD), ¥1,234.56 (CNY)

---

## Test Case 1: Runtime Locale Switching

**Test ID:** I18N-TC-001
**Priority:** P0 (Critical)
**Objective:** Verify runtime locale switching works without app restart

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Launch app and tap "I18n Test" button | I18n Test screen opens | ☐ |
| 2 | Observe initial locale (default: Japanese) | Current Locale shows "ja" | ☐ |
| 3 | Tap "English" button | Button turns blue, all text updates to English immediately | ☐ |
| 4 | Observe Current Locale | Current Locale shows "en" | ☐ |
| 5 | Tap "中文" button | Button turns blue, all text updates to Chinese immediately | ☐ |
| 6 | Observe Current Locale | Current Locale shows "zh" | ☐ |
| 7 | Tap "日本語" button | Button turns blue, all text updates to Japanese immediately | ☐ |
| 8 | Observe Current Locale | Current Locale shows "ja" | ☐ |

### Expected Behavior
- No app restart required
- All UI updates instantly (<100ms)
- Active locale button highlighted in blue
- Inactive locale buttons shown in grey

### Test Data Validation
- ✅ All translations display correctly
- ✅ No untranslated strings (no English fallback in ja/zh)
- ✅ No layout overflow or text truncation

---

## Test Case 2: Core UI Translations

**Test ID:** I18N-TC-002
**Priority:** P0 (Critical)
**Objective:** Verify all core UI translation strings exist and display correctly

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Switch to Japanese (ja) | All 15 core UI strings display in Japanese | ☐ |
| 2 | Verify "App Name" | Shows "Home Pocket" | ☐ |
| 3 | Verify "Home" | Shows "ホーム" | ☐ |
| 4 | Verify "Survival Ledger" | Shows "生存帳簿" | ☐ |
| 5 | Verify "Soul Ledger" | Shows "魂の帳簿" | ☐ |
| 6 | Switch to English (en) | All strings display in English | ☐ |
| 7 | Verify "Home" | Shows "Home" | ☐ |
| 8 | Verify "Survival Ledger" | Shows "Survival Ledger" | ☐ |
| 9 | Switch to Chinese (zh) | All strings display in Chinese | ☐ |
| 10 | Verify "Home" | Shows "首页" | ☐ |
| 11 | Verify "Survival Ledger" | Shows "生存账本" | ☐ |

### Validation Checklist
- ☐ All 15 strings present in all 3 locales
- ☐ No empty translations
- ☐ Correct character encoding (no �� characters)
- ☐ Appropriate terminology for each locale

---

## Test Case 3: Navigation Menu Translations

**Test ID:** I18N-TC-003
**Priority:** P1 (High)
**Objective:** Verify navigation menu translation strings

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Navigation Menu Translations" section | Section visible with 15 items | ☐ |
| 2 | Switch to Japanese | All navigation items in Japanese | ☐ |
| 3 | Verify "Dashboard" | Shows "ダッシュボード" | ☐ |
| 4 | Verify "Security" | Shows "セキュリティ" | ☐ |
| 5 | Switch to English | All navigation items in English | ☐ |
| 6 | Verify "Dashboard" | Shows "Dashboard" | ☐ |
| 7 | Verify "Security" | Shows "Security" | ☐ |
| 8 | Switch to Chinese | All navigation items in Chinese | ☐ |
| 9 | Verify "Dashboard" | Shows "仪表盘" | ☐ |
| 10 | Verify "Security" | Shows "安全" | ☐ |

### Validation Points
- ☐ 15 navigation strings present
- ☐ Consistent with actual navigation items
- ☐ Terminology appropriate for financial app

---

## Test Case 4: Category Name Translations

**Test ID:** I18N-TC-004
**Priority:** P0 (Critical)
**Objective:** Verify 20 expense category translations

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Category Name Translations" | Section shows 20 categories | ☐ |
| 2 | Switch to Japanese | All categories in Japanese | ☐ |
| 3 | Verify "Food" | Shows "食費" | ☐ |
| 4 | Verify "Housing" | Shows "住居費" | ☐ |
| 5 | Verify "Entertainment" | Shows "娯楽費" | ☐ |
| 6 | Switch to English | All categories in English | ☐ |
| 7 | Verify "Food" | Shows "Food" | ☐ |
| 8 | Verify "Housing" | Shows "Housing" | ☐ |
| 9 | Switch to Chinese | All categories in Chinese | ☐ |
| 10 | Verify "Food" | Shows "食品" | ☐ |
| 11 | Verify "Housing" | Shows "住房" | ☐ |

### Category List (20 items)
- ☐ Food / Housing / Transport / Utilities
- ☐ Healthcare / Education / Clothing / Insurance
- ☐ Taxes / Other / Entertainment / Hobbies
- ☐ Self-Improvement / Travel / Dining Out / Cafe
- ☐ Gifts / Beauty / Fitness / Books

---

## Test Case 5: Error Messages

**Test ID:** I18N-TC-005
**Priority:** P0 (Critical)
**Objective:** Verify error message translations

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Error Messages" section | 11 error types displayed | ☐ |
| 2 | Switch to Japanese | All errors in Japanese | ☐ |
| 3 | Verify "Network Error" | Shows "ネットワークエラーが発生しました" | ☐ |
| 4 | Verify "Invalid Amount" | Shows "金額が無効です" | ☐ |
| 5 | Switch to English | All errors in English | ☐ |
| 6 | Verify "Network Error" | Shows "Network error occurred" | ☐ |
| 7 | Verify "Invalid Amount" | Shows "Invalid amount" | ☐ |
| 8 | Switch to Chinese | All errors in Chinese | ☐ |
| 9 | Verify "Network Error" | Shows "网络错误" | ☐ |
| 10 | Verify "Invalid Amount" | Shows "金额无效" | ☐ |

### Error Types to Verify
- ☐ Network / Unknown / Invalid Amount
- ☐ Required Field / Invalid Date
- ☐ Database Write / Database Read
- ☐ Encryption / Sync / Biometric / Permission

---

## Test Case 6: Parameterized Strings

**Test ID:** I18N-TC-006
**Priority:** P0 (Critical)
**Objective:** Verify parameterized error messages with dynamic values

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Parameterized Strings" | Shows 2 examples with placeholders | ☐ |
| 2 | Switch to Japanese | Min: "0.01以上の金額を入力してください" | ☐ |
| 3 | Verify Max Amount | Max: "999999.99以下の金額を入力してください" | ☐ |
| 4 | Switch to English | Min: "Amount must be at least 0.01" | ☐ |
| 5 | Verify Max Amount | Max: "Amount must not exceed 999999.99" | ☐ |
| 6 | Switch to Chinese | Min: "金额必须至少为 0.01" | ☐ |
| 7 | Verify Max Amount | Max: "金额不能超过 999999.99" | ☐ |

### Validation Points
- ☐ Numeric values correctly inserted
- ☐ Decimal precision preserved (0.01, 999999.99)
- ☐ Correct grammatical structure for each locale
- ☐ No placeholder artifacts like "{min}" or "{max}"

---

## Test Case 7: UI Action Strings

**Test ID:** I18N-TC-007
**Priority:** P1 (High)
**Objective:** Verify UI action button/label translations

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "UI Action Strings" | 12 action labels displayed | ☐ |
| 2 | Switch to Japanese | All in Japanese (確認, 再試行, 検索, etc.) | ☐ |
| 3 | Switch to English | All in English (Confirm, Retry, Search, etc.) | ☐ |
| 4 | Switch to Chinese | All in Chinese (确认, 重试, 搜索, etc.) | ☐ |

### Action Labels to Verify
- ☐ Confirm / Retry / Search / Filter
- ☐ Sort / Refresh / Close / OK
- ☐ Yes / No / Loading / No Data

---

## Test Case 8: Success Messages

**Test ID:** I18N-TC-008
**Priority:** P2 (Medium)
**Objective:** Verify success feedback messages

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Success Messages" | 3 success types shown | ☐ |
| 2 | Switch to Japanese | Shows: 保存しました / 削除しました / 同期が完了しました | ☐ |
| 3 | Switch to English | Shows: Saved successfully / Deleted successfully / Synced successfully | ☐ |
| 4 | Switch to Chinese | Shows: 保存成功 / 删除成功 / 同步成功 | ☐ |

---

## Test Case 9: Time Labels

**Test ID:** I18N-TC-009
**Priority:** P2 (Medium)
**Objective:** Verify time-related label translations

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Time Labels" | 2 time labels shown | ☐ |
| 2 | Switch to Japanese | Shows: 今日 / 昨日 | ☐ |
| 3 | Switch to English | Shows: Today / Yesterday | ☐ |
| 4 | Switch to Chinese | Shows: 今天 / 昨天 | ☐ |

---

## Test Case 10: Date Formatting

**Test ID:** I18N-TC-010
**Priority:** P0 (Critical)
**Objective:** Verify locale-aware date formatting

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Date Formatting" section | 5 format examples shown | ☐ |
| 2 | Switch to Japanese | formatDate: "2026/02/04" | ☐ |
| 3 | Verify DateTime | formatDateTime: "2026/02/04 14:30" (24-hour) | ☐ |
| 4 | Verify Relative Today | formatRelative: "今日" | ☐ |
| 5 | Verify Relative Yesterday | formatRelative: "昨日" | ☐ |
| 6 | Verify Month-Year | formatMonthYear: "2026年2月" | ☐ |
| 7 | Switch to English | formatDate: "02/04/2026" | ☐ |
| 8 | Verify DateTime | formatDateTime: "02/04/2026 2:30 PM" (12-hour AM/PM) | ☐ |
| 9 | Verify Relative Today | formatRelative: "Today" | ☐ |
| 10 | Verify Relative Yesterday | formatRelative: "Yesterday" | ☐ |
| 11 | Verify Month-Year | formatMonthYear: "February 2026" | ☐ |
| 12 | Switch to Chinese | formatDate: "2026年02月04日" | ☐ |
| 13 | Verify DateTime | formatDateTime: "2026年02月04日 14:30" (24-hour) | ☐ |
| 14 | Verify Relative Today | formatRelative: "今天" | ☐ |
| 15 | Verify Relative Yesterday | formatRelative: "昨天" | ☐ |

### Format Rules
- **Japanese:** YYYY/MM/DD, 24-hour time
- **English:** MM/DD/YYYY, 12-hour AM/PM
- **Chinese:** YYYY年MM月DD日, 24-hour time

---

## Test Case 11: Number Formatting

**Test ID:** I18N-TC-011
**Priority:** P0 (Critical)
**Objective:** Verify locale-aware number formatting

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Number Formatting" | 3 examples displayed | ☐ |
| 2 | Switch to Japanese | Number: "1,234,567.89" | ☐ |
| 3 | Verify Percentage | Shows: "12.34%" | ☐ |
| 4 | Verify Compact | Shows: "123万" (man unit for 1,234,567) | ☐ |
| 5 | Switch to English | Number: "1,234,567.89" | ☐ |
| 6 | Verify Percentage | Shows: "12.34%" | ☐ |
| 7 | Verify Compact | Shows: "1.23M" (million unit) | ☐ |
| 8 | Switch to Chinese | Number: "1,234,567.89" | ☐ |
| 9 | Verify Percentage | Shows: "12.34%" | ☐ |
| 10 | Verify Compact | Shows: "123万" (wan unit) | ☐ |

### Format Rules
- **All locales:** Comma thousand separator
- **Japanese/Chinese:** Use 万 (10,000) for large numbers
- **English:** Use K/M/B (thousand/million/billion)

---

## Test Case 12: Currency Formatting

**Test ID:** I18N-TC-012
**Priority:** P0 (Critical)
**Objective:** Verify multi-currency formatting with locale awareness

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Scroll to "Currency Formatting" | 5 currency examples | ☐ |
| 2 | Switch to Japanese | JPY: "¥1,235" (no decimals) | ☐ |
| 3 | Verify USD | Shows: "$1,234.56" (2 decimals) | ☐ |
| 4 | Verify CNY | Shows: "¥1,234.56" (2 decimals) | ☐ |
| 5 | Verify EUR | Shows: "€1,234.56" | ☐ |
| 6 | Verify GBP | Shows: "£1,234.56" | ☐ |
| 7 | Switch to English | All currencies maintain same format | ☐ |
| 8 | Switch to Chinese | All currencies maintain same format | ☐ |

### Currency Rules
- **JPY:** ¥ symbol, 0 decimal places
- **USD:** $ symbol, 2 decimal places
- **CNY:** ¥ symbol, 2 decimal places
- **EUR:** € symbol, 2 decimal places
- **GBP:** £ symbol, 2 decimal places

---

## Test Case 13: Layout Stability

**Test ID:** I18N-TC-013
**Priority:** P1 (High)
**Objective:** Verify UI layout remains stable across locale switches

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Switch to Japanese | No text overflow or truncation | ☐ |
| 2 | Scroll through all sections | All content visible and readable | ☐ |
| 3 | Switch to English | No layout shift or broken formatting | ☐ |
| 4 | Switch to Chinese | No text overflow or truncation | ☐ |
| 5 | Rapidly switch locales 5 times | No UI freeze or crash | ☐ |

### Validation Points
- ☐ No text truncation with "..."
- ☐ No text overflow outside containers
- ☐ Button labels fully visible
- ☐ Card layouts maintain consistent spacing
- ☐ No horizontal scrolling required

---

## Test Case 14: Performance

**Test ID:** I18N-TC-014
**Priority:** P2 (Medium)
**Objective:** Verify acceptable performance during locale switching

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Tap Japanese button | UI updates in < 100ms (instant feel) | ☐ |
| 2 | Tap English button | UI updates in < 100ms | ☐ |
| 3 | Tap Chinese button | UI updates in < 100ms | ☐ |
| 4 | Rapidly switch locales 10 times | No performance degradation | ☐ |
| 5 | Check memory usage | No significant memory leak | ☐ |

### Performance Metrics
- ☐ Locale switch latency: < 100ms
- ☐ No visible frame drops (60 FPS maintained)
- ☐ Memory increase < 5MB after 50 switches

---

## Test Case 15: Translation Coverage

**Test ID:** I18N-TC-015
**Priority:** P0 (Critical)
**Objective:** Verify comprehensive translation coverage

### Test Steps

| Step | Action | Expected Result | Pass/Fail |
|------|--------|-----------------|-----------|
| 1 | Count Core UI section | 15 translation strings | ☐ |
| 2 | Count Navigation section | 15 translation strings | ☐ |
| 3 | Count Category section | 20 translation strings | ☐ |
| 4 | Count Error section | 11 translation strings | ☐ |
| 5 | Count UI Actions section | 12 translation strings | ☐ |
| 6 | Count Success section | 3 translation strings | ☐ |
| 7 | Count Time Labels section | 2 translation strings | ☐ |
| 8 | Calculate total | Total: 78 translation strings | ☐ |

### Coverage Requirements
- ☐ All 78 strings present in ja/en/zh
- ☐ No missing translations
- ☐ No fallback to English in non-English locales

---

## Regression Testing

### Quick Smoke Test (5 minutes)

For rapid validation after code changes:

1. ☐ Launch app → Tap "I18n Test"
2. ☐ Switch to English → Verify 3 random strings
3. ☐ Switch to Chinese → Verify 3 random strings
4. ☐ Check date format (2026/02/04 vs 02/04/2026 vs 2026年02月04日)
5. ☐ Check compact number (123万 vs 1.23M)
6. ☐ Check currency (¥1,235 JPY with 0 decimals)
7. ☐ Verify no crashes or layout issues

---

## Bug Reporting Template

### Bug Report Format

**Bug ID:** I18N-BUG-XXX
**Test Case:** I18N-TC-XXX
**Priority:** P0/P1/P2
**Status:** Open/In Progress/Fixed

**Description:**
[Brief description of the issue]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Locale:** ja / en / zh
**Device:** iOS/Android
**App Version:** 1.0.0
**Screenshots:** [Attach if applicable]

---

## Test Execution Summary

**Test Date:** ___________
**Tester:** ___________
**Build Version:** ___________
**Device/Emulator:** ___________

### Results

| Test Case ID | Test Case Name | Result | Notes |
|--------------|----------------|--------|-------|
| I18N-TC-001 | Runtime Locale Switching | ☐ Pass ☐ Fail | |
| I18N-TC-002 | Core UI Translations | ☐ Pass ☐ Fail | |
| I18N-TC-003 | Navigation Menu Translations | ☐ Pass ☐ Fail | |
| I18N-TC-004 | Category Name Translations | ☐ Pass ☐ Fail | |
| I18N-TC-005 | Error Messages | ☐ Pass ☐ Fail | |
| I18N-TC-006 | Parameterized Strings | ☐ Pass ☐ Fail | |
| I18N-TC-007 | UI Action Strings | ☐ Pass ☐ Fail | |
| I18N-TC-008 | Success Messages | ☐ Pass ☐ Fail | |
| I18N-TC-009 | Time Labels | ☐ Pass ☐ Fail | |
| I18N-TC-010 | Date Formatting | ☐ Pass ☐ Fail | |
| I18N-TC-011 | Number Formatting | ☐ Pass ☐ Fail | |
| I18N-TC-012 | Currency Formatting | ☐ Pass ☐ Fail | |
| I18N-TC-013 | Layout Stability | ☐ Pass ☐ Fail | |
| I18N-TC-014 | Performance | ☐ Pass ☐ Fail | |
| I18N-TC-015 | Translation Coverage | ☐ Pass ☐ Fail | |

### Summary
- **Total Test Cases:** 15
- **Passed:** _____ / 15
- **Failed:** _____ / 15
- **Pass Rate:** _____%

### Critical Issues Found
[List any P0 issues that block release]

### Recommendations
[Next steps or improvements needed]

---

**Sign-off:**

**Tester:** _________________ **Date:** _________
**Reviewer:** _________________ **Date:** _________
**Release Manager:** _________________ **Date:** _________
