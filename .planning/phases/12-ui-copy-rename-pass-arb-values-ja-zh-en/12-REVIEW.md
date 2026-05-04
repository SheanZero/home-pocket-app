---
phase: 12-ui-copy-rename-pass-arb-values-ja-zh-en
reviewed: 2026-05-04T09:11:51Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/l10n/app_en.arb
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/generated/app_localizations.dart
  - lib/generated/app_localizations_en.dart
  - lib/generated/app_localizations_ja.dart
  - lib/generated/app_localizations_zh.dart
  - lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart
  - test/widget/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart
  - docs/arch/03-adr/ADR-015_Lexical_Hierarchy_v1_1.md
  - docs/arch/03-adr/ADR-000_INDEX.md
  - doc/worklog/20260504_1804_phase_12_ui_copy_rename_pass.md
findings:
  critical: 0
  warning: 6
  info: 0
  total: 6
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-05-04T09:11:51Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Reviewed the scoped ARB/localization files, generated localization outputs, picker widget, widget test, ADR-015, ADR index, and phase worklog. No blocker-level security, data-loss, or guaranteed runtime failure was found, but the submission leaves several correctness and maintainability defects: one reusable widget crash path, missing semantics for icon-only controls, stale copy in a generated localization API, misleading translator metadata, a Simplified Chinese typo, and inaccurate verification prose.

## Warnings

### WR-01: Picker can throw RangeError when reused with incomplete labels

**Severity:** WARNING
**File:** `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart:66`
**Issue:** `levelLabels[selectedIndex]` and `bottomLabels[0..2]` are indexed without length validation. The current caller passes five level labels and three bottom labels, but this is a public widget constructor; any future reuse, test fixture, or localization assembly mistake will crash the build at runtime with `RangeError`.
**Fix:**
```dart
  const SatisfactionEmojiPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.levelLabels,
    required this.bottomLabels,
  }) : assert(levelLabels.length == _faceValues.length),
       assert(bottomLabels.length == 3);
```

### WR-02: Icon-only tap targets are not exposed as semantic buttons

**Severity:** WARNING
**File:** `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart:80`
**Issue:** The five selectable controls are `GestureDetector` + `Icon` only. Screen readers and keyboard/assistive navigation do not get button role, selected state, label, or the 2/4/6/8/10 value mapping, so the picker is visually usable but not reliably accessible.
**Fix:**
```dart
return Semantics(
  button: true,
  selected: isSelected,
  label: levelLabels[index],
  value: '${_faceValues[index]}/10',
  child: GestureDetector(
    key: ValueKey('face_$index'),
    onTap: () => onChanged(_faceValues[index]),
    child: ...
  ),
);
```

### WR-03: Dead localization API still carries the old banned copy

**Severity:** WARNING
**File:** `lib/l10n/app_en.arb:643`
**Issue:** `homeSoulChargeStatus` still says `Soul Fullness ... Happiness ROI ...`; the ja/zh values at the same key also retain old register (`魂の充実度 ... 幸せROI`, `灵魂充盈度 ... 快乐ROI`). `rg` shows the key is not currently called outside generated localization files, but it remains a generated public localization API and directly contradicts ADR-015's accepted product-copy hierarchy if it is reused.
**Fix:** Either remove the dead key in the planned ARB GC pass, or rename its values now and regenerate:
```json
"homeSoulChargeStatus": "Joy Index {fullness}% · Joy per ¥ {roi}x"
```
Use matching ja/zh values such as `ときめき度 {fullness}% · ハピネス密度 {roi}x` and `悦己充盈 {fullness}% · 幸福密度 {roi}x`.

### WR-04: ARB translator metadata still describes the old terms

**Severity:** WARNING
**File:** `lib/l10n/app_en.arb:554`
**Issue:** Renamed values kept old `@...description` metadata such as `Soul fullness section title`, `Happiness ROI metric label`, `Soul ledger label`, and `Lowest satisfaction label`. These descriptions are emitted into `lib/generated/app_localizations.dart` comments and are translator context for future edits, so the source now tells contributors to preserve exactly the vocabulary ADR-015 is trying to replace.
**Fix:** Update the metadata descriptions for the renamed keys in all three ARB files, then run `flutter gen-l10n`. For example:
```json
"@homeSoulFullness": {
  "description": "Joy index / personal joy fullness section title"
},
"@homeHappinessROI": {
  "description": "Joy density metric label"
}
```

### WR-05: Simplified Chinese locale contains a Traditional character in product copy

**Severity:** WARNING
**File:** `lib/l10n/app_zh.arb:664`
**Issue:** `homeJoyIndexTooltip` says `小確幸数`, using Traditional `確` in the Simplified Chinese locale. ADR-015 standardizes zh family/wellbeing copy as `小确幸`, and the rest of `app_zh.arb` uses Simplified Chinese, so this is inconsistent user-facing copy.
**Fix:**
```json
"homeJoyIndexTooltip": "外环是 Joy/¥ 密度 · 中环是满足度均值 · 内环是小确幸数（满足度 ≥ 6 的次数）。"
```
Regenerate `lib/generated/app_localizations_zh.dart` afterward.

### WR-06: Worklog overstates the icon removal count

**Severity:** WARNING
**File:** `doc/worklog/20260504_1804_phase_12_ui_copy_rename_pass.md:72`
**Issue:** The worklog says `Negative-sentiment icon 移除: 4 个`, but the reviewed widget diff removed two icon entries: `sentiment_very_dissatisfied_outlined` and `sentiment_dissatisfied_outlined`. This makes the close-out evidence inaccurate.
**Fix:** Change the line to `Negative-sentiment icon 移除: 2 个` or clarify what the count represents if it is not counting widget icon constants.

---

_Reviewed: 2026-05-04T09:11:51Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
