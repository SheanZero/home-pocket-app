# Deferred Items — quick 260602-u5x (Best Joy ticket fusion)

## Skipped polish (plan-sanctioned OPTIONAL)

### Punch-hole notches (撕口缺口)
- **What:** The design HTML shows two small card-colored circles (`.notch`) tucked
  at the top/bottom of the perforation line, reinforcing the "torn ticket stub"
  read. The plan marks these OPTIONAL ("implement only if clean").
- **Why deferred:** The dashed vertical perforation (`_DashedVLine`) already carries
  the ticket-tear read clearly in both light and dark goldens. Adding overflowing
  half-circle notches on a `ClipRRect`-clipped ticket needs either negative-margin
  overflow (clipped away by the rounding ClipRRect) or a custom clipper carving
  concave bites out of the body — neither is "clean" without a bespoke
  `CustomClipper` and risks visual noise at small sizes. Kept the layout simple;
  the accent bar + tinted body + dashed perforation already deliver the ticket
  aesthetic. Revisit only if a future polish pass wants the literal punch-holes.

## Pre-existing, out-of-scope (NOT introduced by this task)

These exist on the base commit (`12f8c7d0`) and live in files this task never
touched. Per the executor scope-boundary rule they are logged, not fixed.

- `lib/features/accounting/presentation/screens/category_selection_screen.dart:373,485`
  — `info • 'onReorder' is deprecated` (Flutter SDK deprecation after v3.41). Verified
  present at base commit (2 occurrences). Unrelated to Best Joy region.
- `build/ios/SourcePackages/firebase_messaging-16.2.2/...` — 2 analyzer notices in a
  generated CocoaPods/SwiftPM artifact dir (not project source); cleared by `flutter clean`.
