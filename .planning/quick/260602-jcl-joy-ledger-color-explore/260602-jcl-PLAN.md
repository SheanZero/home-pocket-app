---
quick_id: 260602-jcl
slug: joy-ledger-color-explore
date: 2026-06-02
mode: quick (design exploration — no auto-commit of palette change)
---

# 悦己(Joy) ledger identity 色の代替探索

## 背景

ユーザー所感:「本月最爱(Best Joy strip) と 悦己 vs 日常 の **黄色系(gold #F0A81E)が good-looking でない**。
悦己の配色としてより適した色を探したい。」

現状 (ADR-018 "Teal Clarity", live):
- 日常 Daily: teal `#1C7A86` / text `#145E68`（cool anchor）
- **悦己 Joy: gold `#F0A81E` / text `#9A6500`（= 不満の対象）**
- Joy 色は `joy / joyText / joyLight / joyFullnessBorder / satisfactionPillRose / textMutedGold` + Best Joy strip 全体に波及。

制約:
- 赤は `error` 専用（D-01 解除後も赤は予約）。
- teal アンカーと対で映えること。
- `joyText` は白カード(#FFFFFF)上で WCAG AA ≥4.5:1（パレット契約）。

## アプローチ

hz0 と同じ理由（産物は設計稿でありコードではない / Pencil 落盤不可 / executor は MCP 剥離）で
**gsd-planner→executor チェーンを使わず**、自前で HTML 設計稿を作り候補を視覚提示する。

`docs/design/joy-color-explore.html`:
- 現状 gold を参照列に、teal と対で映える Joy 候補を複数（warm 系 / cool-pop 系）並べる。
- 各候補: swatch+hex（joy/joyText/joyLight）、悦己 pill、金額テキスト(¥1,235) + **live WCAG 比**、
  Best Joy strip カード、日常 pill との横並び比較。light/dark 両対応。
- ブラウザ実測 + 0 console error。

## 落とし込み（選定後・別タスク）

選定色 → `app_palette.dart` の joy 系トークン(light+dark) 更新 → golden re-baseline → ADR-018 に Update 追記。
本タスクでは **コードは変更しない**（探索のみ）。
