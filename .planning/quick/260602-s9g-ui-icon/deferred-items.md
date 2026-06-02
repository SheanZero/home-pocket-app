# Deferred Items — quick 260602-s9g

Out-of-scope discoveries found during execution. NOT fixed (pre-existing, unrelated to this task's changes).

## Pre-existing analyzer infos (out of scope)

- `lib/features/accounting/presentation/screens/category_selection_screen.dart:373` — `onReorder` deprecated (use `onReorderItem`). Present at base commit `21e5acb7`; not touched by this task.
- `lib/features/accounting/presentation/screens/category_selection_screen.dart:485` — same `onReorder` deprecation.

## Generated-package noise (not project source)

- `build/ios/SourcePackages/firebase_messaging-16.2.2/example/analysis_options.yaml:5` — `include_file_not_found` warning inside a downloaded SwiftPM package's example. Not project source; disappears on `flutter clean`.

These do not originate from the files modified by quick 260602-s9g (category_display_utils, home_hero_card, home_transaction_tile, home_screen, golden tests). The modified files report 0 analyzer issues.
