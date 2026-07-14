# Home v12 — UX & Accessibility Audit

**Scope:** Personal light, lower Home content, family light, and personal dark states in the
whole-app HTML design center.

## Evidence

1. `01-personal-home-top.jpg` — Personal Home: header, monthly summary, Joy rings, favorite ticket.
2. `02-personal-home-lower.jpg` — Personal Home: invite promotion, recent transactions, bottom nav.
3. `03-family-home-top.jpg` — Family Home: shared summary and family Joy presentation.
4. `04-personal-home-dark.jpg` — Personal Home: dark-theme hierarchy and contrast.

## Strengths

- Monthly spending is the clear first read, followed by ledger split and Joy context.
- Daily, Joy, and family semantics remain visually distinct without becoming a multicolor card wall.
- Personal, family, and dark states preserve the same layout and navigation rhythm.
- The monthly-favorite ticket gives Joy spending a memorable but restrained visual identity.

## Highest-Impact Recommendations

1. **Reduce the amount of meaning carried by the three rings.** Keep target progress for Joy;
   show satisfaction as `8.2 / 10`, and keep small wins as a plain count. A progress arc without a
   denominator makes the count look like a target or achievement system.
2. **Bring daily activity higher.** The large family invitation pushes recent transactions below
   the initial viewport. Keep the required order, but compress the invite into a one-row banner or
   reduce the ring and vertical spacing so the first transaction becomes visible sooner.
3. **Make the Hero action explicit.** The whole Hero is clickable but has no visual cue. Add a
   quiet `查看本月分析` / chevron affordance, or restrict navigation to an obvious sub-region.
4. **Fix the family metric label.** The family heading says `家族の小確幸`, while the central value
   and legend say family Joy. Rename the heading to the accepted family Joy wording so one section
   does not name two different primary metrics.
5. **Raise the accessibility floor.** Current supporting type reaches 7–9px; month and mode targets
   are 35px and 27px high. Use at least 11–12px supporting text and 44px touch targets. The Hero has
   `role=button` but Enter does not activate it, and the Japanese page exposes a Chinese ring
   `aria-label`; use a native button or keyboard handler and localized value-rich semantics.

## Secondary Polish

- Expand `−8%` to `先月同期比 −8%` so the comparison is understandable without inference.
- Add `今日` / `昨日` to recent transactions; removing amount signs makes date context more useful.
- Recheck muted green and pink contrast in dark mode with automated contrast tests and text scaling.

## Evidence Limits

This audit can confirm visual hierarchy, prototype DOM semantics, target dimensions, and the failed
Enter-key interaction. It cannot claim production Flutter accessibility or WCAG compliance without
device text scaling, screen-reader, focus-order, and measured contrast tests in the real app.
