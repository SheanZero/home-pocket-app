---
sketch: 003
name: legal-sponsor
question: "Complete Settings page integrating the existing 8 sections with v2.0 additions: App Lock expansion, expanded legal/compliance, and an external sponsor link."
winner: "C"
tags: [settings, legal, compliance, app-lock]
---

# Sketch 003: Complete Settings (v2)

## Design Question
Not a standalone legal block — the **full Settings page**, integrating what already exists with the
v2.0 launch additions. New/changed rows are tagged `新` in the mockup.

## Existing sections (from settings_screen.dart, kept in order)
Profile card · 外観 (Theme / Language / Week start) · 音声認識 (Recognition language) · 悦己の目標 ·
データ管理 (Export / Import / Delete all) · 家族共有 (Family sync / Sync now) · セキュリティ (Biometric / Notifications) ·
アプリについて (Version / Privacy Policy / OSS licenses).

## v2.0 additions (tagged 新)
- **App Lock expansion** (Security): master "アプリロック" toggle → Face ID/指紋 toggle + PIN コード row, with the
  note "両方設定すると Face ID が優先". Replaces the lone Biometric Lock switch.
- **Legal/compliance**: add **利用規約** + **特定商取引法に基づく表記** alongside Privacy Policy + OSS.
- **応援 / Sponsor**: external-browser "開発を応援する" row (↗ 外部), explicitly not IAP.

## How to View
open .planning/sketches/003-legal-sponsor/index.html

## Variants
- **A: 温柔抛茶感** — warm card groups, colored icons, sponsor in its own group.
- **B: 清爽极简** — iOS grouped list, no icons, uppercase headers; sponsor demoted to one ↗外部 row (most store-safe).
- **C: 混合** ★ **WINNER** — fewer/merged sections (一般 combines appearance+voice+joy; 法的情報・応援 one group).

## What to Look For
- Does the App Lock sub-row expansion read clearly (master + Face ID + PIN + priority note)?
- Section granularity: keep 8 separate (A/B) or merge into fewer (C)?
- Sponsor prominence vs store-review risk — own group (A) vs single row (B/C).
- Are the four legal entries scannable and Japanese-compliance-complete?
