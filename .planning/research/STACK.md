# Stack Research

**Domain:** Pre-launch capstone (onboarding + app-lock + donation link + in-app legal) for a Flutter local-first family accounting app — Japanese-market iOS/Android release
**Researched:** 2026-06-28
**Confidence:** HIGH

> **Headline:** This milestone needs **almost no new dependencies.** Onboarding persistence, biometric, PIN hashing, secure storage, OSS-license display, and the "about/version" surface are all satisfiable with packages **already in `pubspec.yaml`** or **Flutter built-ins**. The single genuinely-new dependency is **`url_launcher`** (donation link). Everything below is framed as "reuse vs. add" so the roadmap can default to reuse.

---

## Capability → Stack Decision (at a glance)

| New capability | Decision | Dependency action |
|----------------|----------|-------------------|
| First-run onboarding: persist UI-language / currency / voice-language | **Reuse** existing `SettingsRepository` (SharedPreferences-backed) — same store `LocaleNotifier` already reads/writes | none |
| Onboarding "completed" gate flag | **Reuse** `SettingsRepository` / SharedPreferences (add one bool key) | none |
| App-lock: Face ID / biometric | **Reuse** `local_auth ^3.0.1` (already wired via `biometric_service.dart`) | none |
| App-lock: PIN (NEW) | **Reuse** `crypto ^3.0.6` (PBKDF2/SHA-256 + salt) + `flutter_secure_storage ^10.2.0` (store hash+salt, never the PIN) | none |
| App-lock gate in boot flow | **Reuse** existing `AppInitializer` ordering + add a lock-gate widget before the main shell | none |
| Donation / sponsorship link | **Add** `url_launcher ^6.3.2` | **+1 dependency** |
| OSS / third-party license attribution | **Reuse** Flutter built-in `showLicensePage` / `LicenseRegistry` / `showAboutDialog` (+ existing `package_info_plus ^9.0.1` for version string) | none |
| Privacy Policy / Terms of Use (静的, in-app) | **Reuse** localized `S` (ARB) text in a static screen — NO markdown package | none |

---

## Recommended Stack

### Core Technologies (all already present — confirmed in `pubspec.yaml`)

| Technology | Version (in repo) | Purpose | Why it's the right tool here |
|------------|-------------------|---------|------------------------------|
| `local_auth` | `^3.0.1` | Face ID / Touch ID / Android biometric prompt | Already integrated in `lib/infrastructure/security/biometric_service.dart`; 3.x is the current major. Do NOT bump or re-wrap — extend the existing service. |
| `flutter_secure_storage` | `^10.2.0` | Keychain/Keystore-backed storage of the PIN **hash+salt** (and biometric/lock flags) | Already present, already holds Ed25519/master-key material. **Do NOT change its `accessibility` (`unlocked_this_device`)** — changing it bricks existing installs (documented project gotcha). |
| `crypto` | `^3.0.6` | PBKDF2/SHA-256 hashing of the PIN with a per-install random salt | Already present. PIN must be stored **hashed + salted**, never plaintext. Use a high iteration count (≥100k) so a 4–6 digit PIN isn't trivially brute-forced offline. (`cryptography ^2.7.0` is also available if Argon2/scrypt-style is preferred — see Alternatives.) |
| `shared_preferences` | `^2.3.4` | Persist UI-language, currency, voice-language, and the onboarding-complete flag | This is **already the backing store** for `SettingsRepository` (`lib/data/repositories/settings_repository_impl.dart`, keys `voice_language`, language, currency). Onboarding writes the same keys the rest of the app already reads — zero new persistence layer, zero migration. |
| `package_info_plus` | `^9.0.1` (pinned) | App name + version/build for the About / legal screen | Already present. **Leave the pin** — tied to the `file_picker`/`share_plus`/win32 trio. |
| `intl` / `flutter_localizations` + ARB (`S`) | `intl 0.20.2` (pinned) | All onboarding + legal + lock UI copy in ja/zh/en | Mandatory per project i18n rules — every new string goes through ARB ×3 + `flutter gen-l10n`. |

### Supporting Libraries

| Library | Version | Purpose | When to use |
|---------|---------|---------|-------------|
| `url_launcher` | **`^6.3.2`** (latest stable, pub.dev) | Open the donation/sponsorship URL in the external browser; optionally `mailto:`/legal-host links | **The one new dependency.** Use `launchUrl(uri, mode: LaunchMode.externalApplication)` for the donation link. |
| **Flutter built-ins** (no package) | SDK | OSS license attribution: `showLicensePage(...)`, `LicenseRegistry.addLicense(...)`, `showAboutDialog(...)` | `flutter_localizations` and most plugins auto-register their licenses into `LicenseRegistry`; `showLicensePage` renders the full, scrollable, localized list for free. This is the standard, store-acceptable OSS-attribution surface. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `flutter gen-l10n` | Generate `S` from ARB after adding onboarding/lock/legal strings | Run after every ARB edit; keep ja/zh/en key sets byte-identical (project gate). |
| `build_runner` | Regenerate `.g.dart` for any new `@riverpod` lock-state notifier / `@freezed` model | Required after adding e.g. an `AppLockNotifier` or onboarding-state provider. |

---

## Installation

```bash
# The ONLY new runtime dependency for this milestone:
flutter pub add url_launcher        # resolves to ^6.3.2

# Everything else is already in pubspec.yaml — nothing to install:
#   local_auth ^3.0.1, flutter_secure_storage ^10.2.0, crypto ^3.0.6,
#   cryptography ^2.7.0, shared_preferences ^2.3.4, package_info_plus ^9.0.1
```

**Native config that must accompany the work (no new pods/plugins, just plist/manifest):**

- **iOS `Info.plist` — `NSFaceIDUsageDescription`** (ja string): required by `local_auth` for Face ID. If biometric already shipped, this is likely present — verify it exists and is localized.
- **iOS `url_launcher` + https:** no `LSApplicationQueriesSchemes` entry needed for `https` links (only required when calling `canLaunchUrl` on custom schemes). Confirmed against pub.dev docs.
- **Android `url_launcher` + https:** Android 11+ package-visibility — add the standard `<queries>` `<intent>` for `android.intent.action.VIEW` + `https` in `AndroidManifest.xml` if you call `canLaunchUrl`. Launching directly with `launchUrl` for `https` generally works without it; add the query to be safe.
- **No Podfile changes** beyond the existing, sacrosanct `post_install` (`-lsqlite3` strip + `EXCLUDED_ARCHS` for ML Kit). `url_launcher_ios` needs none of that.

---

## Alternatives Considered

| Recommended | Alternative | When the alternative would make sense |
|-------------|-------------|----------------------------------------|
| `crypto` PBKDF2-SHA256 for PIN | `cryptography ^2.7.0` (Pbkdf2 / Argon2id) — **already in repo** | If you want a memory-hard KDF (Argon2id) for the PIN, `cryptography` is already a dependency and exposes it. Both are zero-new-dependency; PBKDF2 with high iterations is sufficient for a 4–6 digit PIN behind OS keychain. |
| SharedPreferences for UI prefs + onboarding flag | Encrypted Drift settings table / `flutter_secure_storage` | Use the encrypted path **only for the PIN hash** (sensitive). Language/currency/voice-language and the onboarding-done flag are **non-sensitive UI preferences** — putting them in SharedPreferences matches the existing `SettingsRepository` and avoids a needless schema-v23 migration. Don't over-encrypt non-secrets. |
| Built-in `showLicensePage` | `flutter_oss_licenses` (build-time generator) | Only if you need a **custom-styled** license screen or to include licenses the registry misses. For a standard compliant list, the built-in needs zero deps and auto-collects. Start built-in; escalate only if design demands. |
| Static localized `Text`/`SelectableText` for Privacy/Terms | `markdown_widget` / `flutter_markdown_plus` | Only if legal copy is authored in Markdown and you want rich rendering offline. Prefer plain localized text first (see "What NOT to Use" re: `flutter_markdown`). |
| In-app static legal screens | `url_launcher` to a hosted policy page | Hosting works, but **local-first/offline-first** ethos favors bundling the text in-app so it renders with no network. Use `url_launcher` for the *donation* link, not for must-always-work legal text. |

---

## What NOT to Use

| Avoid | Why | Use instead |
|-------|-----|-------------|
| Any IAP / payment SDK (`in_app_purchase`, RevenueCat, Stripe, `pay`, etc.) | App is **entirely free**; only a donation *link*. A payment SDK adds store-review burden, 特定商取引法 obligations, and contradicts the product. | `url_launcher` to an external sponsorship page. |
| `go_router` (or any router migration) | Project uses `Navigator` + `MaterialPageRoute` + `IndexedStack`. The onboarding gate and lock gate are **boot-time branch widgets**, not routes. Introducing a router is scope creep + risk. | Conditionally render onboarding/lock/shell from app root based on persisted flags (post-`AppInitializer`, pre-shell). |
| `sqlite3_flutter_libs` | Hard project ban — conflicts with `sqlcipher_flutter_libs`; enforced by import_guard + CI. | `sqlcipher_flutter_libs ^0.6.x` (already in place). |
| Changing `flutter_secure_storage` `accessibility` from `unlocked_this_device` | Bricks existing installs (master key unreadable → init-fail screen). Documented gotcha. | Keep current accessibility; store PIN hash with the **same** setting. |
| `flutter_markdown` (core package) | **Discontinued** by the Flutter team in 2025; no longer maintained. | Plain localized `Text`/`SelectableText` from ARB; or `flutter_markdown_plus`/`markdown_widget` only if rich rendering is truly needed. |
| A standalone PIN/biometric "lock screen" package (e.g. screen-lock plugins) | Adds a dependency that duplicates what `local_auth` + `flutter_secure_storage` + a custom widget already do, and rarely matches the ADR-019 palette / i18n. | Build the lock UI in-app; reuse `biometric_service` + a new salted-hash PIN check. |
| Bumping `file_picker` / `package_info_plus` / `share_plus` to satisfy anything | The trio is win32-pinned together; isolated bumps break `flutter pub get` or the iOS build. | Leave all three pinned; nothing in this milestone requires touching them. |

---

## Stack Patterns by Variant

**Onboarding language/currency/voice-language persistence:**
- Use the existing `SettingsRepository` keys (`language`, currency, `voice_language`). The onboarding screen just calls the same setters `LocaleNotifier.setLocale` / the currency + voice setters already use.
- Add ONE new key (e.g. `onboarding_completed: bool`). App root reads it after `AppInitializer.initialize()`: if false → onboarding; else → lock gate → main shell.

**PIN storage:**
- Generate a random per-install salt; store `{ pinHash, salt, iterations, biometricEnabled }` in `flutter_secure_storage`.
- Verify by re-deriving and constant-time comparing. Never log, never store the raw PIN, never put it in SharedPreferences.

**App-lock trigger:**
- Lock on cold launch and on resume-from-background (`AppLifecycleState.resumed` after `paused`). The lock gate is a widget wrapping the shell, not a route. Biometric first (`local_auth`), PIN as fallback / when biometric unavailable or skipped.

**OSS licenses:**
- Drive `showLicensePage` from a Settings → Legal entry; pass `applicationName`/`applicationVersion` from `package_info_plus`. Optionally `LicenseRegistry.addLicense` for any asset/font not auto-registered.

---

## Version Compatibility

| Package | Constraint / resolved | Notes |
|---------|-----------------------|-------|
| `url_launcher ^6.3.2` | Needs Dart ≥3.3 / Flutter ≥3.19 | Project is Dart `^3.10.8` — fine. |
| `url_launcher` → `url_launcher_windows` | **No win32 dependency** | `url_launcher_windows` 3.x depends only on `flutter` + `url_launcher_platform_interface` (verified on pub.dev). It is **already present transitively** in `pubspec.lock`. **Therefore `url_launcher` does NOT collide with the `file_picker`/`share_plus`/`package_info_plus` win32 pin** — the headline pin risk for this milestone is cleared. |
| `local_auth ^3.0.1` | Current major | Keep as-is; iOS needs `NSFaceIDUsageDescription`. |
| `flutter_secure_storage ^10.2.0` | Current major | Keep accessibility = `unlocked_this_device` (do not touch). |
| `crypto ^3.0.6` / `cryptography ^2.7.0` | Both present | Either KDF works for PIN; no version change needed. |

---

## Integration Points (for the roadmap)

- **`AppInitializer` (`lib/core/initialization/app_initializer.dart`):** unchanged order (KeyManager → Database → others). The onboarding gate and lock gate run **after** `initialize()` resolves and **before** the main `IndexedStack` shell — this is the app's first `onboarding gate`.
- **`SettingsRepository` (SharedPreferences):** single source for UI-language/currency/voice-language + new onboarding-complete flag. No new repository, no Drift migration (schema stays v22).
- **`flutter_secure_storage` (`secure_storage_service.dart`):** new home for PIN hash/salt + lock-enabled flags. Same instance/accessibility as today.
- **`biometric_service.dart`:** extend (don't replace) for the lock-on-launch/resume flow.
- **ARB / `S` (ja default / zh / en):** all onboarding, lock, donation, and legal copy added in three locales; legal long-form text (Privacy/Terms) bundled as localized strings so it renders offline.
- **Currency selector (v1.7):** reuse the existing JPY-first selector widget inside onboarding.
- **Settings screen:** new entries — App-lock toggle + PIN setup, Sponsorship link (`url_launcher`), Legal section (Privacy Policy / Terms / `showLicensePage`).

> **Content (not stack) note — 特定商取引法:** whether a donation *link* triggers Japan's Specified Commercial Transactions Act 表記 is a **legal/content decision, not a dependency.** If required, it's another localized static legal screen using the same in-app text pattern — no new package.

---

## Sources

- `pubspec.yaml` / `pubspec.lock` (repo) — confirmed already-present versions; `url_launcher_windows` already resolved transitively. HIGH
- pub.dev `url_launcher` — latest stable **6.3.2**, https needs no `LSApplicationQueriesSchemes`. HIGH
- pub.dev `url_launcher_windows` 3.1.5 — deps only `flutter` + `url_launcher_platform_interface` (no win32 → no pin conflict). HIGH
- `lib/data/repositories/settings_repository_impl.dart`, `lib/features/settings/.../state_locale.dart` — SharedPreferences-backed settings, the established persistence path for language/currency/voice-language. HIGH
- `lib/infrastructure/security/` (`biometric_service.dart`, `secure_storage_service.dart`) + `crypto`/`cryptography` deps — confirmed reuse path for biometric + salted-hash PIN. HIGH
- Flutter SDK — `showLicensePage` / `LicenseRegistry` / `showAboutDialog` built-in OSS attribution; `flutter_markdown` discontinued (2025). MEDIUM-HIGH
- CLAUDE.md — iOS pin constraints, secure_storage accessibility brick, no-go_router / no-sqlite3_flutter_libs rules. HIGH

---
*Stack research for: pre-launch onboarding + app-lock + donation + legal (Flutter, JP market)*
*Researched: 2026-06-28*
