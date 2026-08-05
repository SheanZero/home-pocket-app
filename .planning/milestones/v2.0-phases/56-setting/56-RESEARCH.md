# Phase 56: Setting 法务 + 赞助 + 日本合规（上线关卡） - Research

**Researched:** 2026-07-01
**Domain:** Flutter Settings UI · external-link launching (`url_launcher`) · bundled per-locale legal assets · JP store-compliance deliverables
**Confidence:** HIGH (all HOW-level unknowns resolved against the live codebase; only external legal sign-off is out of scope by design)

## Summary

This is an integration phase, not a greenfield one. Almost every mechanism the phase needs already exists in the repo and only needs to be composed: the Settings screen is a `ListView` of `*Section` widgets separated by `Divider`s (`settings_screen.dart`), `showLicensePage` is **already wired and working** in `about_section.dart`, the i18n pipeline (`S.of(context)` + ARB ja/zh/en + gen-l10n) is mature, and `package_info_plus` is already a dependency (though currently unused). The single genuinely new runtime dependency is `url_launcher`, and the single genuinely new mechanism is loading long-form legal text from **bundled per-locale assets** (the repo has zero existing `rootBundle` usage — this is a first).

The two highest-risk technical questions both resolve favorably. (1) `url_launcher` 6.3.2's Windows federated implementation (`url_launcher_windows` 3.1.5) depends only on `flutter` + `url_launcher_platform_interface` — it has **no `win32` dependency** — so it cannot collide with the pinned `file_picker`/`package_info_plus`/`share_plus` win32 trio. (2) For plain `https://` links launched with `LaunchMode.externalApplication`, iOS treats `http`/`https` as pre-allowlisted schemes (no `LSApplicationQueriesSchemes` change needed), and the only Android 11+ subtlety is that `canLaunchUrl` returns false without a `<queries>` entry — which we sidestep by launching directly with a try/catch rather than gating on `canLaunchUrl`.

**Primary recommendation:** Add `url_launcher` (^6.3.2). Build one new `LegalSponsorSection` widget inserted just before `AboutSection`, with each legal document as a **separate `MaterialPageRoute` screen** that renders **plain-text** (not markdown — no renderer dep, and legal prose does not need it) loaded from `assets/legal/{doc}_{ja,zh,en}.md` keyed off `currentLocaleProvider`. Centralize all placeholder URLs in a new `lib/core/config/legal_urls.dart`. Add an asset-parity existence test modeled on `arb_key_parity_test.dart`. Deliver the store-privacy-form checklist as a `.planning/` markdown file, not app code.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Settings section UI (`法的情報・応援` group) | Presentation (`features/settings/presentation/widgets/`) | — | Pure UI composition of ListTiles, mirrors existing `*_section.dart` |
| Legal detail screens (privacy/terms/特商法) | Presentation (`features/settings/presentation/screens/`) | — | Full-screen scroll views pushed via `MaterialPageRoute` |
| Long-form legal text | Bundled assets (`assets/legal/`) | Presentation loads via `rootBundle` | D-02: keep long text out of ARB to avoid bloat/diff-noise |
| Short labels (group title, row titles, buttons) | i18n (`lib/l10n/*.arb` + `S.of(context)`) | — | LEGAL-06: ARB parity + CJK scan coverage for UI chrome |
| External sponsor link launch | Presentation calls `url_launcher` (infra-ish plugin) | iOS/Android native config | DONATE-02: external browser, never WebView/IAP |
| OSS license aggregation | Flutter SDK built-in (`showLicensePage`) | — | LEGAL-03: zero manual maintenance, already working |
| Placeholder URLs (hosted privacy/terms, donation) | Config constant (`lib/core/config/`) | — | D-04: one source of truth, "上线前填真实值" |
| Store privacy form | `.planning/` markdown deliverable | — | D-05: not app code |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `url_launcher` | `^6.3.2` | Open sponsor URL in external browser (DONATE-02) | [VERIFIED: pub.dev] flutter.dev-published, canonical Flutter link launcher; only supported way to hit external browser without WebView |
| `showLicensePage` / `LicenseRegistry` | Flutter SDK (built-in) | OSS license aggregation (LEGAL-03) | [VERIFIED: codebase] Already called in `about_section.dart:36-41`; zero deps |
| `package_info_plus` | `^9.0.1` (already in pubspec) | App name/version for `showLicensePage` (optional reuse) | [VERIFIED: codebase] In pubspec, currently unused; replaces hardcoded `'0.1.0'` |
| `rootBundle.loadString` | Flutter SDK (`flutter/services.dart`) | Load per-locale legal assets (D-02) | [VERIFIED: Flutter docs] Standard asset-text loading; no third-party dep |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter/services.dart` `rootBundle` | SDK | Async asset string load | In the legal detail screen's `FutureBuilder` / init load |
| `url_launcher_platform_interface` | transitive (`^2.2.0`) | Mock surface for launch tests | Only in tests — swap `UrlLauncherPlatform.instance` with a mock |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain-text asset rendering | `flutter_markdown` | Adds a dependency (and `markdown`) for prose that does not need rich formatting; **not recommended** — legal text renders fine as `SelectableText` in a scroll view. If headings/links become mandatory later, revisit. |
| Separate `MaterialPageRoute` screens per doc | Inline `ExpansionTile` in the section | Long legal prose inside an expander bloats the settings scroll and hurts readability; separate screens match `showLicensePage`'s own full-screen model. **Screens recommended.** |
| `canLaunchUrl` guard then `launchUrl` | Direct `launchUrl` in try/catch | `canLaunchUrl` returns false on Android 11+ for https without a `<queries>` entry — a well-known false-negative. For https, launch directly and handle the thrown `PlatformException`. |

**Installation:**
```bash
flutter pub add url_launcher
# then, because this repo generates code:
flutter pub run build_runner build --delete-conflicting-outputs   # (no codegen impact from url_launcher, but keep the ritual)
```

**Version verification (performed this session):**
- `url_launcher` latest = **6.3.2** [VERIFIED: pub.dev, flutter.dev publisher]. SDK need (Flutter ≥3.22 / Dart ≥3.4) is satisfied by this repo's `sdk: ^3.10.8`.
- `url_launcher_windows` = **3.1.5**, dependencies = `flutter` + `url_launcher_platform_interface ^2.2.0` only — **no `win32`** [VERIFIED: pub.dev]. This is the load-bearing finding for the win32-trio pin: url_launcher is safe to add.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `url_launcher` | pub.dev | mature (6.x line, years) | very high (flutter.dev core plugin) | github.com/flutter/packages | OK | Approved |
| `package_info_plus` | pub.dev | mature | very high | github.com/fluttercommunity/plus_plugins | OK | Already in pubspec (no new install) |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*Both packages are first-party Flutter ecosystem plugins (flutter.dev / fluttercommunity verified publishers). No slopsquat risk. `url_launcher` was discovered from the phase requirement text and confirmed on pub.dev under the official `flutter.dev` publisher.*

## Architecture Patterns

### System Architecture Diagram

```
Settings ListView (settings_screen.dart)
  ├── ProfileSectionCard
  ├── AppearanceSection
  ├── VoiceSection
  ├── JoyTargetSection
  ├── DataManagementSection
  ├── FamilySyncSettingsSection
  ├── SecuritySection (Phase 55 — DO NOT MODIFY)
  ├── ★ LegalSponsorSection (法的情報・応援)  ← NEW, insert here
  │     ├── ListTile プライバシーポリシー ─push→ LegalDocScreen(doc: privacy) ─┐
  │     ├── ListTile 利用規約           ─push→ LegalDocScreen(doc: terms)   ─┤
  │     ├── ListTile 特商法に基づく表記  ─push→ LegalDocScreen(doc: tokusho) ─┤
  │     │                                                                     ▼
  │     │                                        rootBundle.loadString(
  │     │                                          'assets/legal/{doc}_{lang}.md')
  │     │                                          lang = currentLocaleProvider.value
  │     │                                                   .languageCode  (ja|zh|en, ?? 'ja')
  │     │                                          → SelectableText in scroll view
  │     │
  │     ├── ListTile オープンソースライセンス ─→ showLicensePage(...)  (built-in, reuse)
  │     └── ListTile 開発を応援する ──→ launchUrl(
  │             LegalUrls.donation,             LaunchMode.externalApplication)
  │             (lib/core/config/legal_urls.dart)  → EXTERNAL BROWSER (never WebView/IAP)
  └── About(version/appName; privacy+license tiles migrate INTO the new section)

.planning/ deliverable (NOT app code):
  store-privacy-form-checklist.md  (Apple Nutrition Labels | Google Data Safety)
```

File-to-implementation mapping lives in the Component Responsibilities below, not the diagram.

### Recommended Project Structure
```
lib/
├── core/
│   └── config/
│       └── legal_urls.dart          # NEW — placeholder hosted + donation URLs (D-04)
├── features/settings/presentation/
│   ├── widgets/
│   │   └── legal_sponsor_section.dart   # NEW — the 法的情報・応援 group (model on about_section.dart)
│   └── screens/
│       └── legal_doc_screen.dart        # NEW — generic per-doc reader (privacy/terms/tokusho)
assets/
└── legal/                               # NEW asset dir (declare in pubspec flutter.assets)
    ├── privacy_ja.md   privacy_zh.md   privacy_en.md
    ├── terms_ja.md     terms_zh.md     terms_en.md
    └── tokusho_ja.md   tokusho_zh.md   tokusho_en.md
.planning/phases/56-setting/
└── store-privacy-form-checklist.md      # NEW .planning deliverable (D-05, LEGAL-05)
```

### Pattern 1: Section widget (copy `about_section.dart`)
**What:** A `StatelessWidget` returning a `Column` with a bold padded title `Text` then a list of `ListTile`s.
**When to use:** The new `LegalSponsorSection`.
**Example:**
```dart
// Source: lib/features/settings/presentation/widgets/about_section.dart (existing, verbatim shape)
class LegalSponsorSection extends StatelessWidget {
  const LegalSponsorSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(S.of(context).legalSponsorSectionTitle,   // NEW ARB key
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: Text(S.of(context).privacyPolicy),             // existing ARB key
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const LegalDocScreen(doc: LegalDoc.privacy))),
        ),
        // ... terms, tokusho, licenses (showLicensePage), sponsor row
      ],
    );
  }
}
```
Insert into `settings_screen.dart` children list **before** `const AboutSection()` (with the surrounding `const Divider()` matching the existing rhythm).

### Pattern 2: Locale-keyed asset load
**What:** Resolve the current language to `{ja,zh,en}` then `rootBundle.loadString`.
```dart
// Source: currentLocaleProvider is lib/.../providers/state_locale.g.dart (AsyncValue<Locale>)
final lang = ref.watch(currentLocaleProvider).value?.languageCode ?? 'ja';
final safeLang = const {'ja', 'zh', 'en'}.contains(lang) ? lang : 'ja';
final text = await rootBundle.loadString('assets/legal/${doc.slug}_$safeLang.md');
// render: SelectableText(text) inside SingleChildScrollView + Scaffold(AppBar)
```
`.value ?? const Locale('ja')` is the established read idiom (see `transaction_edit_screen.dart:181`). Guard the languageCode against the whitelist so an unexpected system locale never throws a missing-asset error.

### Pattern 3: External-browser launch (DONATE-02)
```dart
// Source: url_launcher README (flutter/packages)
Future<void> _openSponsor() async {
  final uri = Uri.parse(LegalUrls.donation);
  // Do NOT gate on canLaunchUrl for https (Android 11+ false-negative without <queries>).
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) { /* show a neutral SnackBar; never crash, never retry-loop */ }
}
```

### Anti-Patterns to Avoid
- **WebView / in-app browser for the sponsor link** — DONATE-02 forbids it; Apple review also treats in-app donation flows as IAP-triggering. Always `LaunchMode.externalApplication`.
- **Repeated popups / paywall nudges** — DONATE-03: one neutral, optional, non-transactional row. No dialogs, no interstitials.
- **Long legal prose in ARB** — D-02 forbids; bloats ARB and floods diffs. Assets only for long text.
- **Hardcoding the version string** — `about_section.dart` currently hardcodes `'0.1.0'`; prefer `package_info_plus` (already a dep) so it never drifts.
- **Editing `security_section.dart`** — Phase 55, explicitly frozen; only an adjacency reference.
- **Publishing operator home address/phone in 特商法 page** — D-03: 「請求時提供」型 only, placeholder email.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OSS license list | Manual license file/registry | `showLicensePage` (already wired) | Auto-aggregates every dependency's LICENSE via `LicenseRegistry`; zero maintenance (LEGAL-03) |
| Opening an external URL | Custom platform channel / WebView | `url_launcher` `launchUrl` | Canonical, handles iOS/Android intent quirks |
| App version display | Hardcoded string | `package_info_plus` `PackageInfo.fromPlatform()` | Already in pubspec; single source of truth |
| Markdown rendering | Add `flutter_markdown` | Plain `SelectableText` in a scroll view | Legal prose needs no rich formatting; avoids a new dependency |

**Key insight:** The only thing this phase genuinely *builds* is content (trilingual legal drafts) + composition (one section, one reader screen, one config file). Every mechanism is either already in the repo or a first-party plugin.

## Runtime State Inventory

> Not a rename/refactor/migration phase. This phase is additive (new files, new assets, one dependency). No stored data, live-service config, OS-registered state, secrets, or build artifacts carry an old identifier that needs migrating.
>
> **Verified:** No new persisted fields expected — legal/sponsor content is static; `AppSettings` (SharedPreferences, not Drift — see memory `settings-persisted-via-sharedprefs-not-drift`) is untouched; **schemaVersion stays 22** (no Drift migration). If any toggle were ever added it would mirror `biometricLockEnabled` in prefs, but none is anticipated.

## Common Pitfalls

### Pitfall 1: `canLaunchUrl` false-negative on Android 11+
**What goes wrong:** Guarding the sponsor launch with `if (await canLaunchUrl(uri))` silently no-ops on Android 11+ (API 30) because package visibility hides browser intents unless `<queries>` is declared.
**Why it happens:** Android 11 package-visibility restrictions; `canLaunchUrl` inspects installed handlers.
**How to avoid:** For https, skip `canLaunchUrl`; call `launchUrl(..., externalApplication)` directly and handle a false return / `PlatformException`. (Optionally add an `<queries>` VIEW+https intent to `AndroidManifest.xml` if `canLaunchUrl` is ever needed, but it is not needed here.)
**Warning signs:** Sponsor row appears to do nothing on a physical Android 11+ device while working in the emulator/older API.

### Pitfall 2: Missing asset for a locale → runtime throw
**What goes wrong:** `rootBundle.loadString` throws if `assets/legal/{doc}_{lang}.md` is absent (e.g. only ja+en shipped).
**Why it happens:** Assets are not compile-checked; a forgotten `zh` file surfaces only at runtime.
**How to avoid:** The **asset-parity existence gate** (Wave 0) asserting all 3 locales × all 3 docs exist; plus the languageCode whitelist guard defaulting to `ja`.
**Warning signs:** Blank/error legal screen in one language only.

### Pitfall 3: Forgetting to declare the asset directory in pubspec
**What goes wrong:** Files exist on disk but `rootBundle` can't find them.
**Why it happens:** `pubspec.yaml` `flutter.assets:` currently lists only `assets/satisfaction/`. New dirs must be added.
**How to avoid:** Add `- assets/legal/` under `flutter.assets:`.
**Warning signs:** `Unable to load asset` at runtime for every legal doc.

### Pitfall 4: Section gate passes on scoped tests but fails FULL suite
**What goes wrong:** New short labels break `hardcoded_cjk_ui_scan` / `arb_key_parity` architecture tests, which a scoped `flutter test test/features/settings/...` run does not execute.
**Why it happens:** Architecture tests live in `test/architecture/` (see memory `main-dart-boot-provider-...`: per-wave/section gate must run FULL `flutter test`).
**How to avoid:** Run the FULL `flutter test` suite before declaring done. Note: `hardcoded_cjk_ui_scan` scans **`lib/` only** (`Directory('lib')`), so CJK inside `assets/legal/*.md` is safe; but any CJK **string literal in Dart** (e.g. an accidental inline default) will trip it — keep all Dart CJK in ARB.

### Pitfall 5: iOS `LSApplicationQueriesSchemes` misconception
**What goes wrong:** Adding `https` to `LSApplicationQueriesSchemes` "to be safe" — unnecessary, and touching Info.plist risks the iOS build.
**Why it happens:** README wording implies all schemes need declaring.
**How to avoid:** `http`/`https` are in iOS's default allowlist; **no Info.plist change is needed for https**. Leave Info.plist alone (it already carries only `NSFaceIDUsageDescription` from Phase 55). Do not touch the Podfile `post_install` (CLAUDE.md).

## Code Examples

### Reuse the already-working license page (LEGAL-03)
```dart
// Source: lib/features/settings/presentation/widgets/about_section.dart:36-41 (existing)
showLicensePage(
  context: context,
  applicationName: S.of(context).appName,
  applicationVersion: packageInfo.version,   // was hardcoded '0.1.0' — reuse package_info_plus
);
```

### Config constant (D-04)
```dart
// lib/core/config/legal_urls.dart  (NEW)
/// Placeholder external URLs. 上线前填真实值 (fill real values before launch).
class LegalUrls {
  LegalUrls._();
  // App Store Connect mandates a hosted privacy URL (LEGAL-01) — placeholder:
  static const String privacyPolicyHosted = 'https://example.com/homepocket/privacy'; // TODO 上线前填真实值
  static const String termsOfUseHosted    = 'https://example.com/homepocket/terms';   // TODO 上线前填真实值
  // Donation platform (FANBOX / OFUSE) — DONATE-04 placeholder:
  static const String donation            = 'https://example.com/homepocket/support'; // TODO 上线前填真实值
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Privacy/terms text hardcoded in-widget or ARB | Bundled per-locale asset files | This phase (D-02) | First `rootBundle` usage in repo; needs asset-parity gate |
| `about_section` privacy tile = dead `// TODO` | Real navigation to a legal reader screen | This phase | Wire the existing stubbed `onTap` (about_section.dart:28-30) |
| Version hardcoded `'0.1.0'` | `package_info_plus` (already a dep) | This phase (optional) | Removes drift risk |

**Deprecated/outdated:**
- `about_section.dart`'s `// TODO: Navigate to privacy policy` — replace by moving the privacy + license tiles into the new `LegalSponsorSection` (or have both point at the new screens). Decide whether `AboutSection` keeps only version/appName.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | iOS treats `http`/`https` as pre-allowlisted, so no `LSApplicationQueriesSchemes` entry is needed for the sponsor launch | Common Pitfalls / Standard Stack | LOW — if wrong, sponsor link no-ops on iOS; caught by on-device UAT. Well-established Flutter behavior. |
| A2 | Plain-text `SelectableText` rendering is acceptable for legal prose (no markdown renderer) | Alternatives / Don't Hand-Roll | LOW — if stakeholders want headings/links, add `flutter_markdown` later; content is authored as plain paragraphs either way. Marked Claude's-discretion in CONTEXT. |
| A3 | No new persisted setting is required (all content static) | Runtime State Inventory | LOW — if a toggle emerges, it mirrors `biometricLockEnabled` in prefs, no Drift migration. |
| A4 | Detail docs render best as separate `MaterialPageRoute` screens (vs inline expanders) | Architecture Patterns | LOW — pure UX choice, CONTEXT marks it Claude's-discretion; reversible. |

## Open Questions (RESOLVED)

1. **Does `AboutSection` survive, or do its tiles fully migrate into `LegalSponsorSection`?**
   - What we know: `AboutSection` today holds version + privacy(TODO) + license(working). The new group owns privacy/terms/tokusho/license/sponsor.
   - What's unclear: Whether to keep a slim `AboutSection` (version/appName only) or fold everything in.
   - Recommendation: Keep `AboutSection` for version/appName; move privacy + license into `LegalSponsorSection` (or point both at the new screens). Planner decides; either is a small, reversible edit. Phase 53 tone-C design (`.planning/sketches/003-legal-sponsor/index.html`) is the tie-breaker — read it.
   - **RESOLVED (56-05):** slim `AboutSection` to version-only; its privacy + license tiles migrate into `LegalSponsorSection` (no duplicate rows). Matches tone-C `アプリについて` = version only.

2. **Donation platform: FANBOX vs OFUSE (URL shape only).**
   - What we know: URL is a placeholder (DONATE-04, D-04).
   - What's unclear: Which platform — irrelevant to code (any https).
   - Recommendation: Placeholder constant now; real value 上线前. No code impact.
   - **RESOLVED (D-04):** placeholder `LegalUrls.donation` constant only; platform choice is 上线前 and has zero code impact (any https launches identically).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `url_launcher` | DONATE-02 external browser | ✗ (to add) | ^6.3.2 | none — required; `flutter pub add url_launcher` |
| `package_info_plus` | version in `showLicensePage` (optional) | ✓ (in pubspec) | ^9.0.1 | hardcoded string (current state) |
| `showLicensePage` | LEGAL-03 | ✓ (SDK) | — | — |
| `rootBundle` | D-02 asset load | ✓ (SDK) | — | — |
| iOS toolchain (Info.plist/Podfile) | build | ✓ | — | **No Info.plist/Podfile change needed for https** (A1) |

**Missing dependencies with no fallback:** `url_launcher` (must be installed).
**Missing dependencies with fallback:** none blocking.

## Validation Architecture

> Nyquist validation is ON (no `workflow.nyquist_validation:false` in config).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + architecture tests under `test/architecture/` |
| Config file | none custom (standard flutter test) |
| Quick run command | `flutter test test/features/settings/` |
| Full suite command | `flutter test` (MUST run before section gate — architecture tests) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LEGAL-01 | Privacy screen loads ja/zh/en asset, renders text | widget | `flutter test test/features/settings/legal_doc_screen_test.dart` | ❌ Wave 0 |
| LEGAL-02 | Terms screen loads + renders | widget | same file | ❌ Wave 0 |
| LEGAL-03 | License tile invokes `showLicensePage` | widget (finds `LicensePage`/route) | `flutter test test/features/settings/legal_sponsor_section_test.dart` | ❌ Wave 0 |
| LEGAL-04 | 特商法 screen loads + renders (「請求時提供」copy present) | widget | `legal_doc_screen_test.dart` | ❌ Wave 0 |
| LEGAL-06 | ARB parity for new short labels | architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ (extend coverage automatically) |
| LEGAL-06 | No hardcoded CJK in new Dart | architecture | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ |
| LEGAL-06 | **Asset trilingual existence gate** (3 docs × ja/zh/en all present) | architecture | `flutter test test/architecture/legal_asset_parity_test.dart` | ❌ Wave 0 (model on `arb_key_parity_test.dart`) |
| DONATE-01/03 | Sponsor row renders, neutral copy, no dialog | widget | `legal_sponsor_section_test.dart` | ❌ Wave 0 |
| DONATE-02 | Tapping sponsor calls `launchUrl` with `externalApplication` | widget + mock | mock `UrlLauncherPlatform.instance`, assert `launch` params | ❌ Wave 0 |
| DONATE-04 | URL sourced from `LegalUrls.donation` constant | unit/widget | assert launched uri == `LegalUrls.donation` | ❌ Wave 0 |
| LEGAL-05 | Store privacy checklist truthful (v1.7 fx call reflected) | manual/doc review | `.planning/.../store-privacy-form-checklist.md` review | ❌ Wave 0 (deliverable) |

### Sampling Rate
- **Per task commit:** `flutter test test/features/settings/ test/architecture/legal_asset_parity_test.dart`
- **Per wave merge / section gate:** FULL `flutter test` (architecture tests: `hardcoded_cjk_ui_scan`, `arb_key_parity`, new asset-parity). Never pipe through `tail` (masks exit code — memory `main-dart-boot-provider-...`).
- **Phase gate:** Full suite green + `flutter analyze` 0 issues before `/gsd-verify-work`.

### `url_launcher` test pattern
```dart
// Mock the platform interface; no real browser needed in tests.
class _MockLauncher extends Fake with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  LaunchOptions? lastOptions; String? lastUrl;
  @override Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url; lastOptions = options; return true;
  }
  @override Future<bool> canLaunch(String url) async => true;
}
// setUp: UrlLauncherPlatform.instance = _MockLauncher();
// assert: mock.lastUrl == LegalUrls.donation && options.mode == PreferredLaunchMode.externalApplication
```

### Wave 0 Gaps
- [ ] `test/architecture/legal_asset_parity_test.dart` — asserts all `assets/legal/{privacy,terms,tokusho}_{ja,zh,en}.md` exist (File-existence loop; model on `arb_key_parity_test.dart`'s `File(...).existsSync()` structure). Covers LEGAL-06.
- [ ] `test/features/settings/legal_sponsor_section_test.dart` — section render, sponsor `launchUrl` mock, license page invocation. Covers DONATE-01/02/03/04, LEGAL-03.
- [ ] `test/features/settings/legal_doc_screen_test.dart` — asset load + render per locale, `TestWidgetsFlutterBinding` + `rootBundle` (assets available in test via pubspec). Covers LEGAL-01/02/04.
- [ ] Extend/rely on existing `arb_key_parity_test.dart` + `hardcoded_cjk_ui_scan_test.dart` (no edit needed; they auto-cover new keys/files).

### Manual-UAT-only (cannot automate)
- External browser actually opens the sponsor URL on a physical iOS + Android device (`LaunchMode.externalApplication`) — on-device UAT.
- Actual App Store Connect / Play Console submission round-trip (store-review margin) — deferred to launch.

### Deferred to legal (not machine-checkable)
- Legal accuracy / adequacy of the trilingual drafts — 上线前由日本法务复核 (per D-01, CONTEXT).
- 特商法 applicability and whether full 表記 is required — LEGAL-V2-01.

## Security Domain

> `security_enforcement` not disabled → included. This phase is low-risk (external link + static content), but three checks apply.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes (mild) | Sponsor URL is a compile-time constant, not user input — no injection surface. Guard languageCode against `{ja,zh,en}` whitelist before asset path interpolation. |
| V6 Cryptography | no | No crypto in scope; no secrets added. |
| V12 Files/Resources | yes | Asset paths are constructed from a whitelisted enum + whitelisted lang — no path traversal from untrusted input. |
| V14 Config | yes | Placeholder URLs are non-secret and belong in source (`legal_urls.dart`); real URLs are public too — no secret-management concern. |

### Known Threat Patterns for Flutter external-link
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious deep-link / arbitrary URL launch | Tampering | URL is a hardcoded constant, never user-supplied; `externalApplication` hands off to the OS browser (no in-app credential surface) |
| Path traversal via locale string | Tampering | Whitelist `languageCode` to `{ja,zh,en}`, default `ja`, before interpolating into asset path |
| Privacy misstatement in store form | Repudiation/compliance | LEGAL-05 checklist must reflect the **real** v1.7 exchange-rate outbound call — non-reflexive "collects nothing" (CONTEXT §specifics) |

## Sources

### Primary (HIGH confidence)
- Codebase (grepped/read this session): `settings_screen.dart`, `about_section.dart`, `arb_key_parity_test.dart`, `hardcoded_cjk_ui_scan_test.dart`, `feature_flags.dart`, `state_locale.dart`, `pubspec.yaml`, `ios/Runner/Info.plist`, `app_palette.dart`
- pub.dev — `url_launcher` 6.3.2 (flutter.dev publisher), `url_launcher_windows` 3.1.5 dependency list (no win32)

### Secondary (MEDIUM confidence)
- url_launcher README (flutter/packages) — iOS/Android scheme configuration wording

### Tertiary (LOW confidence)
- iOS default https allowlist behavior (A1) — established community knowledge; verify on-device

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every mechanism verified in-repo or on pub.dev; win32 non-conflict confirmed.
- Architecture: HIGH — new widgets mirror existing `*_section.dart` patterns exactly.
- Pitfalls: HIGH — asset/gate/CJK-scan behavior read directly from the test sources.
- iOS/Android launch config: MEDIUM — https-allowlist claim (A1) needs on-device confirmation; low risk.

**Research date:** 2026-07-01
**Valid until:** 2026-07-31 (stable Flutter plugin surface; url_launcher 6.x is long-lived)
</content>
</invoke>
