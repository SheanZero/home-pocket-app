# Screen Inventory — Pencil Design File

**Source:** untitled.pen
**Date:** 2026-04-02
**Total Screens:** 26 (4 Home + 12 previous + 10 new screens)

---

## Home Screen — 4 States

| Screen | Theme | Mode | Node ID | Size | Description |
|--------|-------|------|---------|------|-------------|
| Home (Light + Group) | Light | Family | `Psivj` | 402 x 1015 | Original — month picker, family badge, overview card, ledger comparison (3 books), soul fullness, group bar, transactions with person tags, pill nav + FAB |
| Home (Dark + Group) | Dark | Family | `7tgtB` | 402 x 1015 | Dark theme — same structure, dark cards (#252836), light text (#F0F0F2), tinted tag backgrounds |
| Home (Light + Solo) | Light | Personal | `LP8mE` | 402 x 894 | Personal mode — no family badge, no group bar, 2 ledgers only (no shared), transaction tags show ledger type (生/灵) |
| Home (Dark + Solo) | Dark | Personal | `rwQy7` | 402 x 894 | Dark personal — combines dark theme + solo mode changes |

---

## Transaction List Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| TX List (Light) | Light | `qX8xt` | Title "取引一覧", search bar, filter chips (すべて/支出/収入), date-grouped transaction rows with ledger tags, pill nav (tab 2 active) + FAB |
| TX List (Dark) | Dark | `r2HVL` | Same structure with dark theme colors |

---

## Transaction Form Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| TX Form (Light) | Light | `aeOgj` | Back arrow + "新しい取引", amount input, expense/income toggle, category chips (色分け: survival blue, soul green), note input, save button |
| TX Form (Dark) | Dark | `2qyx2` | Same structure with dark theme colors |

---

## Category Selection Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Category (Light) | Light | `wmi2j` | Close X + "カテゴリ選択", search bar, expandable L1 groups with icons (食費 expanded with L2 chips), collapsed groups (交通費, 通信費, 趣味・娯楽, 教育・学習, 美容・健康, 住居費) |
| Category (Dark) | Dark | `8OAVq` | Same structure with dark theme colors, dark tinted icon backgrounds |

---

## Analytics Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Analytics (Light) | Light | `4seLQ` | Title "分析" + month picker pill, summary cards (総支出/総収入), ledger ratio bar (生存75%/灵魂25%), category breakdown horizontal bars, budget progress bars, pill nav (tab 3 active) + FAB |
| Analytics (Dark) | Dark | `KG9lL` | Same structure with dark theme colors |

---

## Settings Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Settings (Light) | Light | `r2WI6` | Back arrow + "設定", grouped sections: 外観 (テーマ/言語), 音声 (音声入力), データ管理 (バックアップ/復元/CSV), 家族同期 (グループ管理/ペアリング), セキュリティ (生体認証 toggle/リカバリーキー), アプリについて (バージョン/利用規約) |
| Settings (Dark) | Dark | `0LlSL` | Same structure with dark theme colors, moon icon for theme |

---

## Group Management Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Group Mgmt (Light) | Light | `Cajjd` | Back arrow + "グループ管理" + sync status badge, pairing info card, invite code with copy/regenerate, member list with avatars (太/花/翔) and roles, leave/deactivate button |
| Group Mgmt (Dark) | Dark | `yHFZ5` | Same structure with dark theme colors |

---

## Canvas Layout

Screens are arranged in a grid on the canvas:

```
Row 1 (y: 40) — Home Screens
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │Light│    │Dark │    │Light│    │Dark │
   │Group│    │Group│    │Solo │    │Solo │
   └────┘    └────┘    └────┘    └────┘
   Psivj     7tgtB     LP8mE     rwQy7

Row 2 (y: 1200) — Transaction List + Form
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │TXLst│    │TXLst│    │TXFrm│    │TXFrm│
   │Light│    │Dark │    │Light│    │Dark │
   └────┘    └────┘    └────┘    └────┘
   qX8xt     r2HVL     aeOgj     2qyx2

Row 3 (y: 2600) — Category Selection + Analytics
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │ Cat │    │ Cat │    │ Ana │    │ Ana │
   │Light│    │Dark │    │Light│    │Dark │
   └────┘    └────┘    └────┘    └────┘
   wmi2j     8OAVq     4seLQ     KG9lL

Row 4 (y: 4000) — Settings + Group Management
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │ Set │    │ Set │    │ Grp │    │ Grp │
   │Light│    │Dark │    │Light│    │Dark │
   └────┘    └────┘    └────┘    └────┘
   r2WI6     0LlSL     Cajjd     yHFZ5

Row 5 (y: 5400) — Transaction Entry + Confirm
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │Entry│    │Entry│    │Conf │    │Conf │
   │Light│    │Dark │    │Light│    │Dark │
   └────┘    └────┘    └────┘    └────┘
   DMSqr     EYNG7     W42Il     7Oadu

Row 6 (y: 6800) — OCR Scanner + Voice Input
x: 1836      2298      2760      3222
   ┌────┐    ┌────┐    ┌────┐    ┌────┐
   │ OCR │    │ OCR │    │Voice│    │Voice│
   │Light│    │Dark │    │Light│    │Dark │
   └────┘    └────┘    └────┘    └────┘
   l0iHB     B0P03     xCgGK     rTsvh

Row 7 (y: 8200) — Dual Ledger
x: 1836      2298
   ┌────┐    ┌────┐
   │Dual │    │Dual │
   │Light│    │Dark │
   └────┘    └────┘
   rcFBs     8rQCo
```

---

## Transaction Entry Screen (Smart Keyboard) — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| TX Entry (Light) | Light | `DMSqr` | Close X + "記帳", mode tabs (手動/OCR/音声), JPY badge, large amount display ¥3,480, date+category selector chips, 4x3 numpad + delete/0/次へ |
| TX Entry (Dark) | Dark | `EYNG7` | Same structure with dark theme colors |

---

## Transaction Confirm Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| TX Confirm (Light) | Light | `W42Il` | Back "戻る" + "支出詳細", detail card (金額/分類/日付/店舗/メモ), ledger type selector (生存/灵魂), photo button, 記録する save button |
| TX Confirm (Dark) | Dark | `7Oadu` | Same structure with dark theme colors |

---

## OCR Scanner Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| OCR (Light) | Light | `l0iHB` | Dark camera UI (#1A2530), "レシート撮影", mode tabs (OCR active), viewfinder frame with scan icon, status pill, gallery/shutter/flash controls |
| OCR (Dark) | Dark | `B0P03` | Deeper dark (#0F1620), same structure with reduced opacity elements |

---

## Voice Input Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Voice (Light) | Light | `xCgGK` | Close X + "記帳", mode tabs (音声 active), transcript card with parsed chips (¥1,200/食費/松屋), waveform bars, recording mic button, 次へ button |
| Voice (Dark) | Dark | `rTsvh` | Same structure with dark tinted chips and dark theme |

---

## Dual Ledger Screen — 2 States

| Screen | Theme | Node ID | Description |
|--------|-------|---------|-------------|
| Dual Ledger (Light) | Light | `rcFBs` | Back + "帳本", tab bar (生存帳本/灵魂帳本), date-grouped survival transactions with blue amounts |
| Dual Ledger (Dark) | Dark | `8rQCo` | Same structure with dark theme colors |

---

## Screen Flow

```
App Launch
    │
    ├── Home (Solo/Group) ─── [FAB +] ──→ TransactionEntryScreen (SmartKeyboard)
    │       │                                    │
    │       │                              [カテゴリ] → CategorySelectionScreen
    │       │                              [次へ] → TransactionConfirmScreen
    │       │                                        └── [記録する] → Save → Pop
    │       │
    │       ├── [一覧 tab] → TransactionListScreen
    │       │       └── [tab] → DualLedgerScreen (生存/灵魂)
    │       ├── [分析 tab] → AnalyticsScreen
    │       └── [設定 icon] → SettingsScreen
    │               │
    │               ├── [グループ管理] → GroupManagementScreen
    │               └── [ペアリング] → PairingScreen (TBD)
    │
    ├── TransactionEntryScreen
    │       ├── [手動] → SmartKeyboard (default)
    │       ├── [OCR] → OcrScannerScreen
    │       └── [音声] → VoiceInputScreen
    │
    └── Home (Group) ─── same as Solo + family features
            │
            └── [Group Bar] → GroupManagementScreen
```

---

## Design Token Verification

### Light Theme Colors (consistent across all screens)
| Element | Property | Value |
|---------|----------|-------|
| Screen background | fill | `#FCFBF9` |
| Card surface | fill | `#FFFFFF` |
| Card border | stroke | `#EFEFEF` |
| Primary text | fill | `#1E2432` |
| Secondary text | fill | `#ABABAB` |
| Inactive icon | fill | `#C4C4C4` |
| Section divider | fill | `#F5F4F2` |
| Inner divider | fill | `#F0F0F0` |
| Coral accent | fill | `#E85A4F` |
| Survival blue | fill | `#5A9CC8` |
| Soul green | fill | `#47B88A` |
| Olive | fill | `#8A9178` |

### Dark Theme Colors (consistent across all screens)
| Element | Property | Value |
|---------|----------|-------|
| Screen background | fill | `#1A1D27` |
| Card surface | fill | `#252836` |
| Card border | stroke | `#353845` |
| Primary text | fill | `#F0F0F2` |
| Secondary text | fill | `#6B6E7A` |
| Tag blue tint | fill | `#1E2D3D` |
| Tag green tint | fill | `#1E3028` |
| Coral accent | fill | `#E85A4F` |
