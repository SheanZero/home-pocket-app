# Voice Date Parsing Fix Design

**Date:** 2026-02-22
**Status:** Approved

## Problem

Voice text parser `extractDate()` fails on 3 patterns:

1. **"上个月15号"** → returns Jan 22 (wrong). Should be Jan 15.
   - `_extractRelativeDate` matches "上个月" and returns today's day in last month.
2. **"15号"** → returns null (no date). Should be Feb 15.
   - No pattern handles bare day numbers without a month.
3. **"这个月10号"** → returns null (no date). Should be Feb 10.
   - "这个月" not recognized; bare "10号" not handled.

## Design

### New priority order in `extractDate()`

```
1. Relative keywords (昨日, yesterday, 前天) — unchanged
2. N ago patterns (3天前, 2 weeks ago) — unchanged
3. NEW: Composite "month ref + day" (上个月15号, 今月10日)
4. NEW: Bare day only (15号, 10日, the 15th) → current month
5. Absolute M月D日, M/D — unchanged
```

### Fix: `_extractRelativeDate` last-month guard

"Last month" keywords must NOT match when immediately followed by `\d{1,2}[日号號]`. This lets the input fall through to the composite matcher.

### New: `_extractCompositeMonthDay()`

Matches relative month keyword + specific day number. Supports last month and this month in ja/zh/en.

### New: `_extractBareDay()`

Matches standalone `D号`, `D日`, `the Dth`. Always assumes current month.

### Files

- `lib/application/voice/voice_text_parser.dart`
- `test/unit/application/voice/voice_text_parser_test.dart`
