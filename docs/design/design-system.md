# Home Pocket Design System — Wa-Modern (和モダン)

**Version:** 2.0
**Date:** 2026-04-01
**Style:** Wa-Modern — Japanese zen meets Swiss precision
**Source:** untitled.pen (Pencil)

---

## 1. Design Philosophy

Warm ivory canvas with intentional restraint. Generous whitespace (Ma/間) creates breathing room. Single accent color (coral-red) used with purpose. Whisper-thin borders define surfaces without visual weight. Outfit geometric sans-serif delivers consistent hierarchy through weight variation.

### Key Principles
- **Ma (間):** 16px section gaps for breathing room within content
- **Single Accent Discipline:** Coral-red (#E85A4F) as THE accent
- **Whisper-Thin Borders:** 1px #EFEFEF strokes, no heavy shadows
- **Geometric Consistency:** Outfit font family only, weight-driven hierarchy
- **Dual Ledger Color Code:** Blue (#5A9CC8) = Survival, Green (#47B88A) = Soul
- **4-State System:** Light/Dark × Solo/Group for all screens

---

## 2. Color System

### 2.1 Light Theme

#### Core Backgrounds
| Token | Hex | Usage |
|-------|-----|-------|
| `bg-primary` | `#FCFBF9` | Page background (warm ivory) |
| `bg-card` | `#FFFFFF` | Card surface |
| `bg-muted` | `#F5F4F2` | Section divider lines |
| `bg-subtle` | `#FCFBF9` | Nested card backgrounds (last month) |
| `bg-divider` | `#F0F0F0` | Inner-card divider lines |

#### Text Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `text-primary` | `#1E2432` | Headlines, primary content, amounts |
| `text-secondary` | `#ABABAB` | Labels, subtitles, divider section labels |
| `text-tertiary` | `#C4C4C4` | Inactive nav icons/text, chevrons |

#### Border Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `border-default` | `#EFEFEF` | Card strokes (1px inside) |
| `border-divider` | `#F5F4F2` | Section divider lines |
| `border-list` | `#E8E8E8` | Transaction list container stroke |
| `border-input-active` | `#E85A4F` | Active input border (2px) |

#### Accent Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `accent-primary` | `#E85A4F` | Coral-red — CTAs, active tab, soul highlights, family badge |
| `accent-primary-light` | `#FEF5F4` | Coral tinted background (family badge, satisfaction card) |
| `accent-primary-border` | `#F5D5D2` | Coral tinted border (satisfaction card) |
| `accent-gradient-start` | `#F08070` | FAB gradient start |
| `accent-gradient-end` | `#E85A4F` | FAB gradient end |
| `accent-survival` | `#5A9CC8` | Blue — survival ledger amounts, tags |
| `accent-survival-light` | `#E8F0F8` | Blue tinted background (survival tags) |
| `accent-soul` | `#47B88A` | Green — soul ledger titles, tags |
| `accent-soul-light` | `#E5F5ED` | Green tinted background (soul tags) |
| `accent-olive` | `#8A9178` | Olive — positive trends, ROI values |
| `accent-olive-light` | `#F0FAF4` | Olive tinted background (trend badge, ROI card) |
| `accent-olive-border` | `#C8E6D5` | Olive tinted border (ROI card) |

#### Shared Ledger Colors (Group Mode)
| Token | Hex | Usage |
|-------|-----|-------|
| `shared-primary` | `#D4845A` | Orange — shared ledger amounts, tags |
| `shared-light` | `#FFF0E0` | Orange tinted background (shared tags) |
| `shared-border` | `#F0DCC8` | Orange tinted border (shared ledger card) |
| `shared-chevron` | `#D4B89A` | Shared ledger chevron |

### 2.2 Dark Theme

#### Core Backgrounds
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-bg-primary` | `#1A1D27` | Page background |
| `dark-bg-card` | `#252836` | Card surface |
| `dark-bg-muted` | `#353845` | Dividers, borders |
| `dark-bg-subtle` | `#1E2130` | Nested card backgrounds (last month) |

#### Text Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-text-primary` | `#F0F0F2` | Headlines, primary content, amounts |
| `dark-text-secondary` | `#6B6E7A` | Labels, subtitles, inactive elements |

#### Border Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-border-default` | `#353845` | Card strokes, dividers |

#### Dark Tag Tints (Tinted dark backgrounds for colored tags)
| Token | Hex | Source Color |
|-------|-----|-------------|
| `dark-tag-blue` | `#1E2D3D` | Survival blue tint |
| `dark-tag-green` | `#1E3028` | Soul green tint |
| `dark-tag-orange` | `#3D2D1E` | Shared orange tint |
| `dark-tag-olive` | `#2D3028` | Olive tint |

#### Dark Card Tints (Soul Fullness section)
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-soul-satisfaction-bg` | `#3D2525` | Satisfaction tile |
| `dark-soul-satisfaction-border` | `#5A3535` | Satisfaction tile border |
| `dark-soul-roi-bg` | `#1E3028` | ROI tile |
| `dark-soul-roi-border` | `#2D4D3A` | ROI tile border |

#### Dark Shared Ledger
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-shared-border` | `#4D3D2D` | Shared ledger card border |

#### Dark Family Badge
| Token | Hex | Usage |
|-------|-----|-------|
| `dark-family-badge-bg` | `#3D2525` | Family badge dark background |

---

## 3. Typography

### Font Family
- **Primary:** Outfit (geometric sans-serif)
- **Fallback:** system-ui, sans-serif
- **Tab Labels:** DM Sans (bottom nav only)

### Type Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `headline-lg` | 30px | 700 | 0.9 | Total amount display |
| `headline-md` | 24px | 700 | — | Month picker title |
| `headline-sm` | 18px | 700 | — | Soul spending amount |
| `title-lg` | 16px | 700 | — | Ledger amounts |
| `title-md` | 15px | 600 | — | Section titles (最近の取引) |
| `title-sm` | 14px | 600 | — | Card titles, group name |
| `body-lg` | 13px | 600-700 | — | Transaction amounts, row labels |
| `body-md` | 12px | 500 | — | Transaction names, body text |
| `body-sm` | 11px | 500-600 | — | Labels, badges, ledger titles, divider labels |
| `caption` | 10px | 500 | — | Small labels, tab labels |
| `overline` | 9px | 400-600 | — | Sub-text (先月 ¥198,000), nav labels |
| `micro` | 8px | 400-700 | — | Tag text (私/共有/生/灵), micro labels |

### Font Weights
| Weight | Value | Usage |
|--------|-------|-------|
| Bold | 700 | Amounts, month title, tag text, active labels |
| Semibold | 600 | Section titles, card titles, nav active label |
| Medium | 500 | Body text, labels, descriptions, badges |
| Regular | 400 | Sub-text, quotes, micro labels |

### Letter Spacing
| Style | Value | Usage |
|-------|-------|-------|
| Divider labels | 2px | Section divider labels (今月の支出, 帳 本) |

---

## 4. Spacing System

### Gap Scale
| Token | Value | Usage |
|-------|-------|-------|
| `gap-xs` | 2px | Title + subtitle pairs (ledger info) |
| `gap-sm` | 4px | Badge internal, divider section |
| `gap-md` | 6px | Month wrap, tag + title pairs, ledger rows |
| `gap-base` | 8px | Ledger row internal, soul metrics, transaction row internal |
| `gap-lg` | 10px | Group bar left items |
| `gap-xl` | 12px | Soul card internal, transactions section, nav gap |
| `gap-2xl` | 16px | Overview card internal, main content sections |

### Padding Scale
| Token | Value | Usage |
|-------|-------|-------|
| `pad-screen` | 28px | Content wrapper horizontal padding |
| `pad-content-top` | 4px | Content wrapper top padding |
| `pad-card-lg` | 18px | Overview card |
| `pad-card-md` | 16px | Soul card, group bar |
| `pad-card-sm` | [10, 14] | Ledger rows |
| `pad-row` | [10, 14] | Transaction rows |
| `pad-badge` | [4, 10] | Family badge, trend badge |
| `pad-tag` | [1, 6] | Small person/ledger tags |
| `pad-metric` | [6, 30] | Soul metric tiles |
| `pad-status` | [16, 28, 0, 28] | Status bar |
| `pad-nav` | [16, 21, 21, 21] | Bottom nav |
| `pad-nav-pill` | [0, 12] | Nav pill inner |
| `pad-tab` | [8, 14] | Tab items |

---

## 5. Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-tag` | 3px | Small person/ledger tags |
| `radius-badge` | 8px | Family mode badge |
| `radius-inner` | 12px | Ledger rows, last month, transaction list, avatars, soul metrics |
| `radius-card` | 14px | Overview card, soul card, group bar, nav tab active |
| `radius-nav` | 32px | Bottom nav pill |
| `radius-fab` | 31px | FAB button |
| `radius-pill` | 999px | Trend badge |

---

## 6. Shadows

| Token | Value | Usage |
|-------|-------|-------|
| `shadow-nav` | 0 4px 20px `#00000008` | Bottom nav pill (light) |
| `shadow-nav-dark` | 0 4px 20px `#00000020` | Bottom nav pill (dark) |
| `shadow-fab` | 0 4px 14px `#E85A4F35` | FAB button glow |

---

## 7. Icons

### Icon Libraries
- **Lucide** — All UI icons (outlined, 1.5px stroke)

### Standard Sizes
| Size | Usage |
|------|-------|
| 24px | FAB plus icon |
| 22px | Settings icon |
| 20px | Nav tab icons, chevron-down |
| 18px | Group bar users icon |
| 16px | Status bar icons (signal/wifi/battery), group chevron |
| 14px | Calendar, trend, soul metric icons, chevron-right |
| 13px | Ledger row chevrons |
| 12px | Family badge users icon |

### Icon Names Used
| Icon | lucide name | Usage |
|------|-------------|-------|
| Home | `house` | Nav tab |
| List | `list` | Nav tab |
| Chart | `chart-no-axes-column` | Nav tab |
| Todo | `square-check-big` | Nav tab |
| Plus | `plus` | FAB |
| Settings | `settings` | Header |
| Calendar | `calendar` | Last month row |
| Chevron Right | `chevron-right` | Row navigation |
| Chevron Down | `chevron-down` | Month picker |
| Trending Down | `trending-down` | Trend badge |
| Users | `users` | Family badge, group bar |
| Flame | `flame` | Satisfaction metric |
| Zap | `zap` | ROI metric |
| Signal | `signal` | Status bar |
| Wifi | `wifi` | Status bar |
| Battery | `battery-full` | Status bar |

### Icon Color States
| State | Light | Dark |
|-------|-------|------|
| Active | `#E85A4F` | `#E85A4F` |
| Default | `#1E2432` | `#F0F0F2` |
| Inactive | `#ABABAB` | `#6B6E7A` |
| Disabled | `#C4C4C4` | `#6B6E7A` |
| On accent | `#FFFFFF` | `#FFFFFF` |

---

## 8. Component Patterns

### 8.1 Cards
- Background: `#FFFFFF` (light) / `#252836` (dark)
- Border: 1px `#EFEFEF` (light) / `#353845` (dark), align inside
- Radius: 14px
- Padding: 16-18px
- No shadows (border-defined)

### 8.2 Overview Card
- Padding: 18px
- Gap: 16px (vertical stack)
- Amount: 30px 700 `#1E2432` / `#F0F0F2`
- Trend Badge: pill radius 999, padding [4,10], bg `#F0FAF4` / `#1E3028`
- Last Month Row: bg `#FCFBF9` / `#1E2130`, radius 12, padding [10,0]

### 8.3 Ledger Comparison Rows
- Container gap: 6px vertical
- Row: radius 12, padding [10,14], gap 8
- Tag: radius 3, padding [1,6]
  - Group mode: shows person initial (太/花/翔)
  - Solo mode: shows ledger type (生/灵)
- Title: 11px 600
- Subtitle: 9px 400 `#ABABAB` / `#6B6E7A`
- Amount: 16px 700, colored per ledger
- Chevron: 13px, `#C4C4C4` / `#6B6E7A`

#### Ledger Color Mapping
| Ledger | Tag Text | Tag BG (Light) | Tag BG (Dark) | Amount Color |
|--------|----------|----------------|---------------|-------------|
| 生存帳本 (Survival) | `#5A9CC8` | `#E8F0F8` | `#1E2D3D` | `#5A9CC8` |
| 灵魂帳本 (Soul) | `#47B88A` | `#E5F5ED` | `#1E3028` | `#47B88A` |
| 花の帳本 (Shared) | `#D4845A` | `#FFF0E0` | `#3D2D1E` | `#D4845A` |

### 8.4 Soul Fullness Card
- Card: radius 14, padding 16, gap 12
- Title row: 13px 600, space_between with chevron
- Metrics row: 2 tiles, gap 8, fill_container each
  - Satisfaction: bg `#FEF5F4` / `#3D2525`, border `#F5D5D2` / `#5A3535`, radius 12
  - ROI: bg `#F0FAF4` / `#1E3028`, border `#C8E6D5` / `#2D4D3A`, radius 12
  - Padding: [6, 30]
- Divider: 1px `#F0F0F0` / `#353845`
- Spending row: space_between, label 10px 500, amount 18px 700 blue

### 8.5 Group Bar (Family Mode Only)
- Radius: 14, padding [12,16], space_between
- Left: users icon (18px coral) + group name (14px 600)
- Center: overlapping avatars (gap -6)
- Right: chevron (16px #C4C4C4)
- **Hidden in solo mode**

### 8.6 Family Mode Badge (Group Mode Only)
- Radius: 8, padding [4,10], gap 4
- Background: `#FEF5F4` / `#3D2525`
- Icon: users 12px coral, text: 11px 500 coral
- Content: "家族モード"
- **Hidden in solo mode**

### 8.7 Member Avatar
- Size: 24x24
- Radius: 12 (circle)
- Stroke: 2px outside, white (light) / card bg (dark)
- Initial: 11px 600 white
- Colors assigned per member:
  - Member 1 (太): `#5A9CC8`
  - Member 2 (花): `#E85A4F`
  - Member 3 (翔): `#8A9178`
- Overlap: gap -6px

### 8.8 Transaction List
- Container: radius 12, clip true, border `#E8E8E8` / `#353845`
- Row: padding [10,14], gap 8
- Tag: radius 3, padding [1,6], person initial or ledger type
- Divider: 1px `#F0F0F0` / `#353845`
- Name: 12px 500
- Category: 10px 400, colored per ledger (soul categories in coral)
- Amount: 13px 700

### 8.9 Bottom Navigation
- Layout: Floating pill + independent FAB, gap 12
- Wrapper padding: [16, 21, 21, 21]
- Pill: h62, radius 32, space_around, padding [0,12]
  - Fill: `#FFFFFF` / `#252836`
  - Border: 1px `#EFEFEF` / `#353845`
  - Shadow: 0 4px 20px `#00000008` / `#00000020`
- Active tab: radius 14, coral fill (#E85A4F), white icon + text
  - Layout: vertical, gap 4, padding [8,14]
  - Icon: 20px white, Text: DM Sans 9px 600 white
- Inactive tab: transparent bg, `#C4C4C4` / `#6B6E7A` icon + text
  - Icon: 20px, Text: DM Sans 9px 500
- FAB: 62x62, radius 31
  - Gradient: linear 180deg, `#F08070` → `#E85A4F`
  - Shadow: 0 4px 14px `#E85A4F35`
  - Icon: plus 24px white

### 8.10 Section Divider
- Layout: horizontal, align end, space_between
- Label: 11px 500 `#ABABAB` / `#6B6E7A`, letter-spacing 2px
- Line: fill_container, 1px `#F5F4F2` / `#353845`

### 8.11 Status Bar
- Height: 54px
- Padding: [16, 28, 0, 28]
- Left: time (15px 600)
- Right: signal + wifi + battery (16px each, gap 6)

---

## 9. Screen States

### 4-State System

Every screen exists in 4 states based on theme and sync mode:

| State | Theme | Sync Mode | Key Differences |
|-------|-------|-----------|-----------------|
| Light + Group | Light | Family | Family badge, group bar, shared ledger, person tags |
| Dark + Group | Dark | Family | Same as above with dark theme |
| Light + Solo | Light | Personal | No family badge, no group bar, no shared ledger, ledger-type tags |
| Dark + Solo | Dark | Personal | Same as above with dark theme |

### Group Mode Additions
- **Header:** Family badge (家族モード) between month picker and settings
- **Ledger:** Third row for shared ledger (花の帳本) with orange theme
- **Group Bar:** Family name + overlapping member avatars
- **Transaction Tags:** Show person initials (太/花/翔) with member colors

### Solo Mode Differences
- **Header:** No family badge — just month picker + settings
- **Ledger:** Only 2 rows (生存帳本 + 灵魂帳本), no "私" tags needed
- **No Group Bar:** Section removed entirely
- **Transaction Tags:** Show ledger type (生/灵) instead of person names
- **Height:** ~120px shorter due to removed elements

---

## 10. Screen Layout

### Standard Screen Structure
```
Frame (402 x fit_content, clip: true, fill: bg-primary)
├── Status Bar (h: 54, pad: [16, 28, 0, 28])
├── Content Wrapper (fill_container, pad: [4, 28], gap: 16, vertical)
│   ├── Header (space_between)
│   │   ├── Month Wrap (month text + chevron-down)
│   │   ├── [Group only] Family Badge
│   │   └── Settings Icon
│   ├── Divider "今月の支出"
│   ├── Overview Card (radius 14, pad 18, gap 16)
│   │   ├── Amount + Trend Badge
│   │   └── Last Month Row
│   ├── Divider "帳 本"
│   ├── Ledger Comparison (gap 6, vertical)
│   │   ├── 生存帳本 Row (blue)
│   │   ├── 灵魂帳本 Row (green)
│   │   └── [Group only] 花の帳本 Row (orange)
│   ├── Soul Fullness Card (radius 14, pad 16, gap 12)
│   │   ├── Title + Chevron
│   │   ├── Metrics (satisfaction + ROI)
│   │   ├── Divider
│   │   └── Recent Soul Spending
│   ├── [Group only] Group Bar (radius 14, pad [12,16])
│   └── Transactions Section (gap 12)
│       ├── Header (title + すべて見る)
│       └── Transaction List (clip, radius 12, vertical)
│           ├── Row 1 (tag + info + amount)
│           ├── Divider
│           ├── Row 2
│           ├── Divider
│           └── Row 3
└── Bottom Nav (pad: [16, 21, 21, 21], gap: 12)
    ├── Pill (h: 62, radius: 32)
    └── FAB (62x62, radius: 31)
```

### Screen Dimensions
| Metric | Value |
|--------|-------|
| Screen width | 402px |
| Group mode height | ~1015px |
| Solo mode height | ~894px |
| Content padding (horizontal) | 28px |
| Content padding (top) | 4px |
| Section gap | 16px |

---

## 11. Animation Guidelines (for implementation)

| Interaction | Duration | Easing |
|-------------|----------|--------|
| Tab switch | 200ms | ease-out |
| Card expand/collapse | 250ms | ease-in-out |
| Button press | 100ms | ease-out |
| Page transition | 300ms | ease-in-out |
| FAB press | 150ms | spring |
| Theme toggle | 200ms | ease-in-out |
