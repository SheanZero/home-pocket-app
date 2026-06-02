---
status: complete
quick_id: 260602-jcl
date: 2026-06-02
---

# Summary — 悦己(Joy) ledger identity 色の代替探索

## 要求

ユーザー:「本月最爱(Best Joy strip) と 悦己 vs 日常 の **黄色系(gold #F0A81E)が good-looking でない**。
悦己の配色としてより適した色を探したい。」

## 確定した問題範囲

- 「本月最爱」= `homeBestJoy*` / Best Joy strip。その色は **`joy` トークン**に乗る（`best_joy_story_strip.dart`:34/37/46）。
- 不満の対象 = **悦己 ledger identity 色 `joy: #F0A81E`（gold）**。`joy/joyText/joyLight/joyFullnessBorder/
  satisfactionPillRose/textMutedGold` + Best Joy strip 全体に波及（`app_palette.dart`）。
- 悦己充盈環(happiness rings)は別パレット（hz0 で青瓷/薰衣草/奶油黄に確定済み）→ 今回の対象外。
- 制約: 赤は error 専用 / teal #1C7A86 と対で映える / `joyText` は白カード上 WCAG AA ≥4.5:1。

## 成果物

**`docs/design/joy-color-explore.html`** — ブラウザ自己完結の配色探索稿。
現状 gold を参照列に、teal と対で映える Joy 候補 6 種を並べ、各候補で実際の波及面を再現:
- swatch+hex（joy/joyText/joyLight）／悦己 pill × 日常(teal) pill 横並び／金額 ¥1,235 + **live WCAG 比**／
  「本月最爱」ストリップカード。light/dark トグル。

| 候補 | joy(light) | joyText | 性格 | AA(light) | AA(dark) |
|---|---|---|---|---|---|
| Gold 金（現状/参照） | #F0A81E | #9A6500 | warm pop・大衆寄り | 5.3 ✓ | 9.3 ✓ |
| **Terracotta 赤陶** | #D9734E | #A6492A | teal 定番相方・大人の暖色 | 5.8 ✓ | 6.0 ✓ |
| Coral 珊瑚 | #F2785C | #B43E2A | 明るい暖色・赤寄り注意 | 5.7 ✓ | 7.8 ✓ |
| Tangerine 杏橙 | #F2944A | #9E4E15 | はっきりオレンジ＝脱黄色 | 5.5 ✓ | 6.5 ✓ |
| Magenta 玫红 | #D6457F | #A82C63 | 最も祝祭的・冷暖強対比 | 6.5 ✓ | 5.4 ✓ |
| **Orchid 蘭紫** | #8B6FE0 | #5B3DB0 | teal 補色・wellness/self-care | 7.7 ✓ | 5.1 ✓ |
| Plum 莓紫 | #A14E9B | #7E3577 | 上品ベリー・小面で沈む | 7.9 ✓ | 4.5 ✓ |

全候補 light/dark とも joyText が AA ≥4.5:1 を満たすことを live 計測で確認。

## 推奨

- **最安全な"映える暖色" → テラコッタ/赤陶**：teal の古典的相方、黄より大人の高級感。
- **"脱・黄色"を最も強く → 蘭紫/Orchid**：teal 補色寄りで対比最大、wellness/self-care 感が悦己テーマ直結。
- **最も華やか → 玫红/Magenta**（error 赤との距離に留意）。

## 検証（evidence）

- chrome-devtools (file://) 実測、light + dark 両レンダリング正常、**0 console error**。
- スクショ: `_joy_light.png` / `_joy_dark.png`（全 7 列・両モード確認用、入库後削除可）。

## gsd-quick 標準フローからの逸脱

- **gsd-planner→executor 子代理チェーンを未使用。** hz0(260602-hz0) と同理由: 産物が設計稿でコードでない /
  Pencil 落盤不可(D-03b) / executor は MCP 剥離(claude-code#13898)。HTML/SVG 交付で可検証+持久+入库を担保。

## Follow-ups（未実施・選定後の別タスク）

- 色決定 → `app_palette.dart` の joy 系トークン(light+dark: joy/joyText/joyLight/joyFullnessBorder/
  satisfactionPillRose 等) 更新 → golden re-baseline → ADR-018 に `## Update` 追記。
- 本タスクでは **コード未変更**（探索のみ）。
