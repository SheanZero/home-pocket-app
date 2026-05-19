# Phase 15: Custom Time Windows (HAPPY-V2-02) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-19T09:31:31Z
**Phase:** 15-Custom Time Windows (HAPPY-V2-02)
**Areas discussed:** Selector shape, Date boundary semantics, Metric coverage

---

## Selector Shape

### Question: Where should the time-window selector live?

| Option | Description | Selected |
|--------|-------------|----------|
| Replace AppBar month chip | Upgrade the existing right-side month chip into a unified window chip. | ✓ |
| AppBar chip + in-page segmented control | Keep the AppBar summary and add Week/Month/Quarter/Year/Custom controls at page top. | |
| In-page control only | Remove AppBar chip and place all controls above KPI content. | |

**User's choice:** Replace AppBar month chip.
**Notes:** Existing `MonthChipPicker` pattern remains the interaction anchor.

### Question: How should the bottom sheet be organized?

| Option | Description | Selected |
|--------|-------------|----------|
| Choose window type first | Top-level Week / Month / Quarter / Year / Custom, then type-specific chooser. | ✓ |
| One mixed preset list | List all presets such as this week, last month, this year, custom. | |
| Two-step modal | First choose type, then navigate to a second chooser. | |

**User's choice:** Choose window type first.
**Notes:** The bottom sheet should be structured and extensible.

### Question: How should custom ranges be selected?

| Option | Description | Selected |
|--------|-------------|----------|
| System date-range picker | Use Flutter/Material/system date range selection. | ✓ |
| In-sheet start/end input | Build two rows of date inputs inside the sheet. | |
| Conservative quick-range entry | Keep custom minimal and open an ordinary date picker. | |

**User's choice:** System date-range picker.
**Notes:** Avoid a custom calendar/input control in Phase 15.

### Question: When does the selection apply?

| Option | Description | Selected |
|--------|-------------|----------|
| Immediate apply | Preset selection applies and closes the sheet; custom applies after date confirmation. | ✓ |
| Apply button | User must explicitly tap an apply button. | |
| Preview then apply | Sheet previews summary before applying. | |

**User's choice:** Immediate apply.
**Notes:** Matches the existing month picker behavior.

---

## Date Boundary Semantics

### Question: What day starts a week?

| Option | Description | Selected |
|--------|-------------|----------|
| Locale default | ja/zh usually Monday; en may follow system/locale habit. | |
| Fixed Monday | Stable accounting/statistics week boundary for all locales. | ✓ |
| Fixed Sunday | US-style week boundary. | |

**User's choice:** Fixed Monday.
**Notes:** Stability is preferred over locale-dependent week starts.

### Question: Are start and end dates included?

| Option | Description | Selected |
|--------|-------------|----------|
| Inclusive start and end | `startDate 00:00:00` through `endDate 23:59:59`. | ✓ |
| Include start, exclude end | Half-open interval. | |
| Planner decides | Follow current DAO/use-case style. | |

**User's choice:** Inclusive start and end.
**Notes:** Matches current `timestamp <= endDate` query style.

### Question: How are future dates handled?

| Option | Description | Selected |
|--------|-------------|----------|
| Cap at today | Presets and custom picker cannot apply future dates. | ✓ |
| Allow future empty results | Future windows can be selected but return empty data. | |
| Natural periods may extend into future | This year can mean through Dec 31. | |

**User's choice:** Cap at today.
**Notes:** Analytics should show already-existing financial data, not future periods.

### Question: What happens when custom range exceeds 12 months?

| Option | Description | Selected |
|--------|-------------|----------|
| Reject after selection | Block apply and show localized error copy. | ✓ |
| Picker enforces max span | Date picker directly prevents invalid spans. | |
| Auto-crop to 12 months | Silently adjust the user's selected range. | |

**User's choice:** Reject after selection.
**Notes:** Do not silently alter a financial reporting range.

---

## Metric Coverage

### Question: Which cards follow the selected window?

| Option | Description | Selected |
|--------|-------------|----------|
| Joy-related metrics only | Joy KPI, satisfaction distribution, Best Joy, and future Joy breakdown follow the window. | |
| Current AnalyticsScreen cards | Existing AnalyticsScreen cards follow the window. | ✓ |
| Joy + category donut | Joy cards and category spending follow the window, with trend/largest expense staying monthly. | |

**User's choice:** Current AnalyticsScreen cards.
**Notes:** A later answer carved out the six-month trend as an explicit exception.

### Question: What happens to the six-month trend card?

| Option | Description | Selected |
|--------|-------------|----------|
| Convert to window trend | Week/custom show daily trend; quarter/year show monthly trend. | |
| Keep six-month trend | Rolling six-month trend remains unchanged. | ✓ |
| Hide for some windows | Only show trend for Month/Quarter/Year. | |

**User's choice:** Keep six-month trend.
**Notes:** The card remains a long-term background context card.

### Question: Does FamilyInsightCard follow the window?

| Option | Description | Selected |
|--------|-------------|----------|
| Follow the window | Family aggregate insight uses the active date range. | ✓ |
| Stay monthly | Family aggregate keeps month semantics. | |
| Hide outside month | Hide family card for non-month windows. | |

**User's choice:** Follow the window.
**Notes:** Aggregate-only; no member rankings or comparisons.

### Question: Does HomeHero/Home tab follow the window?

| Option | Description | Selected |
|--------|-------------|----------|
| Fully independent | Phase 15 affects only AnalyticsScreen; HomeHero stays current-month anchored. | ✓ |
| Pass window from Home to Analytics | HomeHero unchanged, but Analytics remembers last window via cross-tab state. | |
| HomeHero hint | Add a HomeHero prompt linking to selected window analytics. | |

**User's choice:** Fully independent.
**Notes:** Preserves ADR-016 HomeHero semantics.

---

## the agent's Discretion

- Exact selector class/file names.
- Exact Riverpod state model for the selected window.
- Exact localized labels, captions, and invalid-range wording.
- Exact provider invalidation structure, provided HomeHero/Home tab providers are not coupled to the AnalyticsScreen window.

## Deferred Ideas

- Window-granularity trend chart.
- Cross-period comparisons or delta UI.
- Persisting selected window across app restart.
- HomeHero awareness of AnalyticsScreen selected window.
- Family member breakdowns, rankings, comparisons, or target semantics.
