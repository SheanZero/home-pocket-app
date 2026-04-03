# Design Documentation

## Overview

Home Pocket (まもる家計簿) design system using the **Wa-Modern (和モダン)** style — Japanese zen meets Swiss precision.

## Files

| File | Description |
|------|-------------|
| [design-system.md](design-system.md) | Complete design system: colors, typography, spacing, components, layout patterns |
| [design-tokens.json](design-tokens.json) | Machine-readable design tokens for tooling integration |
| [screen-inventory.md](screen-inventory.md) | All screen designs with Pencil node IDs, state comparison, and canvas layout |
| [flutter-color-mapping.dart](flutter-color-mapping.dart) | Flutter-ready color constants for implementation |

## Source File

All designs are in `untitled.pen`. Open with Pencil editor.

## 4-State System

Every screen exists in 4 states:

| | Light | Dark |
|--|-------|------|
| **Solo** | Personal mode, clean | Personal mode, dark theme |
| **Group** | Family mode with shared features | Family mode, dark theme |

## Quick Reference

- **Font:** Outfit (geometric sans-serif)
- **Accent:** `#E85A4F` (coral-red)
- **Survival Ledger:** `#5A9CC8` (blue)
- **Soul Ledger:** `#47B88A` (green)
- **Shared Ledger:** `#D4845A` (orange, group mode only)
- **Light Background:** `#FCFBF9` (warm ivory)
- **Dark Background:** `#1A1D27`
- **Light Card:** `#FFFFFF`, border `#EFEFEF`
- **Dark Card:** `#252836`, border `#353845`

## Color Palette

```
Light                    Dark
#FCFBF9 bg-primary       #1A1D27 bg-primary
#FFFFFF bg-card           #252836 bg-card
#EFEFEF border            #353845 border
#1E2432 text-primary      #F0F0F2 text-primary
#ABABAB text-secondary    #6B6E7A text-secondary
#E85A4F accent            #E85A4F accent (unchanged)
#5A9CC8 survival          #5A9CC8 survival (unchanged)
#47B88A soul              #47B88A soul (unchanged)
```
