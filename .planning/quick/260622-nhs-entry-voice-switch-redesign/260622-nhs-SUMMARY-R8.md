---
task: 260622-nhs
fix: R8
title: Voice panel — vertically center the central square + taller panel
type: refactor
scope: layout-only
predecessor: R7
branch: main
worktree: false
commit: 8685f019
gate:
  analyze: 0
  test: 3136 passed / 0 failed
  goldens: no re-baseline needed (no golden directly captures VoiceRecordPanel; the only *voice* golden — voice_input_screen_mic_button_idle.png — is unaffected)
  palette_only: true (no new raw hex)
  manual_one_step_screen_loc: 1020 (untouched by R8 — not in diff)
human_verify: pending
---

# 260622-nhs · FIX R8 — Voice panel: center the square, taller panel

## What changed (layout only)

Restructured `VoiceRecordPanel` (`lib/features/accounting/presentation/widgets/voice_listening_overlay.dart`)
so the dual-state central square is the panel's vertical centerpiece, and the
panel is taller — per the approved mock `mocks/entry-voice-square-button.html`
(356px panel, square centered within ~3px of the midpoint, both states equal
height).

- The panel body is now a fixed-height `SizedBox(height: 356)` (up from the
  prior intrinsic ~287/296dp).
- Inside it, a `Column` with two **equal-flex** `Expanded(flex: 1)` zones
  flanking the square:
  1. **TOP** zone — status row + transcript + waveform — `mainAxisAlignment:
     center` (group centered in the upper half).
  2. The `_CentralSquare` (content/logic unchanged) — a **sibling between** the
     two zones, so it lands at the panel's exact vertical center.
  3. **BOTTOM** zone — the 「点击重置重新录入」 hint (kept as the
     `Visibility(maintainSize)` reserved placeholder while listening) +
     「轻点空白处退出」 — `mainAxisAlignment: center` (group centered in the
     lower half).
- Equal 1:1 flex → square center = panel center.
- Container padding adjusted (`fromLTRB(18, 10, 18, 18)`) to balance the taller
  layout; the bottom-hint internal spacing moved from 4 to 8dp inside the
  centered zone.

## What did NOT change

- Dual-state square: listening/processing → grey `Icons.mic_none` passive /
  stopped → red `Icons.restore` tappable `onReset` (non-bubbling).
- Status line, pulsing dot, transcript, waveform (animated/static), both hints,
  inline-replaces-keypad with no scrim, `onReset`/`onExit` semantics.
- No session / parse / status / interaction logic touched.
- Hold path + `voice_input_screen` (`manual_one_step_screen_test.dart`) tests:
  zero assertion changes, all green.

## TDD

RED → GREEN on 4 new R8 panel tests in
`test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart`:

1. Two `Expanded` zones flank the square; the square is NOT nested inside either.
2. Square vertical center ≈ panel vertical center (≤6px tolerance; mock ≤3px).
3. Panel height ≥340dp (taller than the pre-R8 ~287/296dp — measured 296 at RED).
4. Both states (listening / stopped) stay equal height at the taller size
   (no jump on transition).

RED confirmed: square at 296dp, no Expanded zones, not centered. GREEN after
implementation. The 9 pre-existing panel tests stayed green throughout.

## Gate results

- `flutter analyze`: **0 issues**.
- `flutter test` (full): **3136 passed / 0 failed** — includes architecture
  tests and golden-tagged tests.
- Goldens: **no re-baseline needed**. No golden test pumps `VoiceRecordPanel`
  directly; the only `*voice*` golden (`voice_input_screen_mic_button_idle.png`)
  captures the idle mic button, not the panel, and was unaffected (full suite
  passed with golden tag).
- Palette-only: **true** — `grep` for raw hex in the modified widget = none;
  the square's colors are unchanged `AppPalette` tokens.
- `manual_one_step_screen.dart`: **1020 LOC, untouched** by R8 (not in the
  diff). The change lives entirely in the widget file + its test.

## Commit

`8685f019` — `refactor(260622-nhs): voice panel — center the square, taller panel, rebalance spacing`

Files: `voice_listening_overlay.dart`, `voice_listening_overlay_test.dart`
(349 insertions, 159 deletions — both reflowed by `dart format`).

## On-device verification (human · PENDING)

1. **Square vertically centered** — open the voice panel; the central square
   sits at the panel's vertical middle, with status/transcript/waveform above
   and the two hints below symmetrically distributed.
2. **Panel taller + both states equal height** — the panel is visibly taller
   than before; recording (listening) and stopped states are the same height,
   with no jump/reflow on the listening↔stopped transition.
