---
quick_id: 260529-e5f
description: 把生存支出和灵魂支出选项放在用途标题的右侧，适当调整高度
date: 2026-05-29
status: complete
commit: f86e8fc
---

# Quick Task 260529-e5f — Summary

## What changed

Card B of `TransactionDetailsForm` (用途 / Purpose section) previously stacked
the title above the `LedgerTypeSelector` pills (生存支出 / 灵魂支出) with a 12dp
vertical gap. Moved the pills onto the **same row, to the right of the title**.

- `transaction_details_form.dart` (Card B): `[Text, SizedBox(12), LedgerTypeSelector]`
  → `Row(mainAxisAlignment: spaceBetween)` with `Flexible(Text(title))` on the
  left and `LedgerTypeSelector` on the right. `Flexible` lets a long localized
  title ellipsise instead of overflowing. Soul `SatisfactionEmojiPicker` block
  below is unchanged.
- `ledger_type_selector.dart`: outer `Row` gains `mainAxisSize: MainAxisSize.min`
  so the selector can sit as a non-flex child inside the new horizontal layout
  without unbounded-width errors.

Net effect: Card B is shorter; the soul satisfaction picker and the following
备注 card gain vertical room (visible in the re-baselined screen golden — Card C
now peeks into view).

### Follow-up (visual check) — commit 8d6a479

Pills were too large beside the title. Shrunk for hierarchy/consistency:

- Label `titleMedium` (15/w600) → `titleSmall` (14/w600) — one notch under the
  用途 title, same weight.
- Chip padding `vertical 10→8`, `horizontal 16→14`; icon `16→15`.

Net: lower, tighter pills consistent with the 用途 heading. Golden re-baselined.

## Scope

Shared widget → applies consistently to all 4 hosts (manual / voice / edit /
OCR review).

## Verification

- `flutter analyze` (touched files): **0 issues**
- `dart format`: clean
- Widget tests (form + voice screen + home tap-to-edit + dark-mode + smoke):
  **54 passed**
- Golden: `voice_input_screen_mic_button_idle.png` re-baselined. This golden's
  finder (`voice-mic-button`) has no enclosing RepaintBoundary, so it captures
  the **whole screen**, not just the mic — confirmed the diff was solely the
  intended Card B relayout (pills moved beside title), then updated via
  `--update-goldens`. Re-run passes.
- Visual: device/simulator check pending (owner).

## Notes / follow-ups

- No ARB changes (`expenseClassification` already → 用途/用途/Purpose).
- Possible overflow on very narrow screens (≤320pt) if both pills + title
  exceed the row width; `Flexible` protects the title but pills keep intrinsic
  width. Not observed at 390pt. Revisit only if a small-device report surfaces.
</content>
