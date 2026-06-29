---
sketch: 001
name: onboarding-gate
question: "First-run = intro page → basic-settings page that shows only defaults, with a picker modal on demand and a 'change later in Settings' hint."
winner: "A"
tags: [onboarding, gate, i18n]
---

# Sketch 001: Onboarding Gate (v2)

## Design Question
Two-step first run: **Page 1** introduces the app (value prop), **Page 2** shows the basic settings
as **default values only** (language=日本語, currency=JPY, voice=日本語). Each row has a 変更 link that
opens a picker modal; a hint says everything is changeable later in Settings. How should this flow feel?

## How to View
open .planning/sketches/001-onboarding-gate/index.html

## Flow (per tone)
1. **Intro page** — sakura/icon hero + 3 value bullets (端末内暗号化 / 日常×悦己二帳簿 / 音声記録) + はじめる.
2. **Basic settings** — default-only rows with 変更 link + "あとで設定で変更できます" hint + start button.
3. **変更 modal** — bottom-sheet picker (only shown when the user actually wants to change a default).

## Variants
- **A: 温柔抛茶感** ★ **WINNER** — warm gradient intro, rounded default-value cards, sakura bottom-sheet.
- **B: 清爽极简** — system-native white, tight rows, plain picker. Fastest path.
- **C: 混合** — warm intro (emotional first impression) + calm settings card + dot pager.

## What to Look For
- Is "show defaults only, change-on-demand" calmer than forcing three explicit pickers up front?
- Does the intro page earn its slot, or should first-run jump straight to defaults?
- Bottom-sheet vs native list for the 変更 picker.
