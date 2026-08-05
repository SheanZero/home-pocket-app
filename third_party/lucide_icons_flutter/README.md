# Static Lucide subset

This local package preserves the `package:lucide_icons_flutter/lucide_icons.dart`
API used by Happy Pocket while omitting upstream's six unused variable-weight
font assets. It contains only the static `lucide.ttf` source font and the 37
static codepoints currently referenced by the application and tests.

Source: `lucide_icons_flutter` 3.1.15, https://github.com/vqh2602/lucide-flutter-main

The copied font and adapted icon declarations are distributed under the upstream
MIT license in [LICENSE](LICENSE). Update this subset only after reviewing the
upstream source, license, and every `LucideIcons.*` reference in this repository.

Validate the subset with:

```sh
dart run scripts/verify_lucide_assets.dart
dart run scripts/verify_lucide_assets.dart \
  --asset-root=build/app/intermediates/flutter/release/flutter_assets \
  --expect-tree-shaken
```

The second command is for a completed AOT release build. A profile/debug asset
bundle can retain the full static font, but it must never contain a
`LucideVariable-*` asset.
