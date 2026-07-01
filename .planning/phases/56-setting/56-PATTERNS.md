# Phase 56: Setting 法务 + 赞助 + 日本合规 - Pattern Map

**Mapped:** 2026-07-01
**Files analyzed:** 8 new + 3 modified (13 assets/ARB grouped)
**Analogs found:** 8 / 8 (one genuinely-new mechanism flagged: `rootBundle`)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/features/settings/presentation/widgets/legal_sponsor_section.dart` (NEW) | widget (section) | request-response (nav/launch) | `about_section.dart` | exact |
| `lib/features/settings/presentation/screens/legal_doc_screen.dart` (NEW) | screen | file-I/O (asset load) | `set_pin_screen.dart` (Scaffold+Consumer shell) + Pattern 2 for `rootBundle` | role-match (asset load = new) |
| `lib/core/config/legal_urls.dart` (NEW) | config | constant | `lib/core/constants/feature_flags.dart` | role-match (const-only idiom) |
| `assets/legal/{privacy,terms,tokusho}_{ja,zh,en}.md` (9 NEW) | asset | file-I/O | `assets/satisfaction/` (only existing declared asset dir) | partial (content is new) |
| `pubspec.yaml` (MODIFY — add `assets/legal/` + `url_launcher`) | config | — | current `flutter.assets:` block (line 111-112) | exact |
| `test/architecture/legal_asset_parity_test.dart` (NEW) | test | file-existence loop | `test/architecture/arb_key_parity_test.dart` | role-match |
| `test/widget/features/settings/legal_sponsor_section_test.dart` (NEW) | test | widget | `test/widget/features/settings/security_section_test.dart` | exact |
| `test/widget/features/settings/legal_doc_screen_test.dart` (NEW) | test | widget + asset | same security_section_test harness + `createLocalizedWidget` | role-match |
| `lib/features/settings/presentation/screens/settings_screen.dart` (MODIFY) | screen | — | itself (insert before `AboutSection`) | exact |
| `lib/l10n/app_{ja,zh,en}.arb` (MODIFY — new short labels) | i18n | — | existing key style (app_ja.arb:528-543) | exact |

**Note:** `test/widget/features/settings/` is the real test path (NOT `test/features/settings/` as RESEARCH.md's test map wrote). Place both new widget tests under `test/widget/features/settings/`.

## Pattern Assignments

### `lib/features/settings/presentation/widgets/legal_sponsor_section.dart` (widget, request-response)

**Analog:** `lib/features/settings/presentation/widgets/about_section.dart` (full file, 46 lines — copy verbatim shape). Adjacency-only reference (DO NOT MODIFY): `security_section.dart`.

**Import + class shell** (about_section.dart:1-19) — copy exactly, add nav/launch imports:
```dart
import 'package:flutter/material.dart';
import '../../../../generated/app_localizations.dart';
// NEW for this section:
// import 'package:url_launcher/url_launcher.dart';
// import '../../../../core/config/legal_urls.dart';
// import '../screens/legal_doc_screen.dart';

class LegalSponsorSection extends StatelessWidget {   // sponsor row needs no ref → StatelessWidget OK
  const LegalSponsorSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).legalSponsorSectionTitle,   // NEW ARB key
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
```

**ListTile + nav pattern** (about_section.dart:20-31) — one ListTile per legal doc, push a `MaterialPageRoute`:
```dart
ListTile(
  leading: const Icon(Icons.privacy_tip),
  title: Text(S.of(context).privacyPolicy),   // existing key (app_ja.arb:536)
  onTap: () => Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => const LegalDocScreen(doc: LegalDoc.privacy))),
),
```

**License page reuse** (about_section.dart:32-42) — LEGAL-03, copy verbatim (this is the already-working call):
```dart
ListTile(
  leading: const Icon(Icons.description),
  title: Text(S.of(context).openSourceLicenses),   // existing key (app_ja.arb:540)
  onTap: () {
    showLicensePage(
      context: context,
      applicationName: S.of(context).appName,
      applicationVersion: '0.1.0',   // research suggests package_info_plus (already a dep) to kill drift
    );
  },
),
```

**Sponsor row (DONATE-02) — external browser, from RESEARCH Pattern 3.** Do NOT gate on `canLaunchUrl` (Android 11+ false-negative). No dialog (DONATE-03):
```dart
Future<void> _openSponsor(BuildContext context) async {
  final uri = Uri.parse(LegalUrls.donation);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) { /* neutral SnackBar; never crash/retry-loop */ }
}
```

---

### `lib/features/settings/presentation/screens/legal_doc_screen.dart` (screen, file-I/O)

**Analog (shell):** `lib/features/applock/presentation/screens/set_pin_screen.dart` — `ConsumerStatefulWidget` + `Scaffold(appBar:...)` idiom, doc-commented, `context.palette` theming. Use a `ConsumerWidget` (or stateful) so it can read `currentLocaleProvider`.

**GENUINELY NEW MECHANISM — `rootBundle.loadString` (RESEARCH Pattern 2).** The repo has ZERO existing `rootBundle` usage — there is no in-repo analog for asset-text loading; follow the research pattern exactly:
```dart
// locale read idiom is established: transaction_edit_screen.dart:181
//   ref.read(currentLocaleProvider).value ?? const Locale('ja')
final lang = ref.watch(currentLocaleProvider).value?.languageCode ?? 'ja';
final safeLang = const {'ja', 'zh', 'en'}.contains(lang) ? lang : 'ja'; // V12 whitelist guard — no path traversal
final text = await rootBundle.loadString('assets/legal/${doc.slug}_$safeLang.md');
// render: SelectableText(text) inside SingleChildScrollView, in a Scaffold(AppBar(title:...))
```
- `import 'package:flutter/services.dart';` for `rootBundle`.
- Wrap the async load in a `FutureBuilder` (loading spinner → `SelectableText`), mirroring settings_screen's `settingsAsync.when(loading: CircularProgressIndicator)` (settings_screen.dart:161).
- Define an enum `LegalDoc { privacy, terms, tokusho }` with a `String get slug` in this file (mirrors set_pin_screen.dart's in-file `enum _SetPinStep`).

---

### `lib/core/config/legal_urls.dart` (config, constant)

**Analog:** `lib/core/constants/feature_flags.dart` — top-level `const` + `library;` doc-comment idiom (note: analog lives in `core/constants/`; RESEARCH places new file in the NEW `core/config/` dir per D-04 — create the dir).

**Idiom to copy** (feature_flags.dart:1-14 = doc-commented compile-time consts). Use a private-constructor class holder (RESEARCH Code Example):
```dart
/// Placeholder external URLs. 上线前填真实值 (fill real values before launch).
class LegalUrls {
  LegalUrls._();
  static const String privacyPolicyHosted = 'https://example.com/homepocket/privacy'; // TODO 上线前填真实值
  static const String termsOfUseHosted    = 'https://example.com/homepocket/terms';   // TODO 上线前填真实值
  static const String donation            = 'https://example.com/homepocket/support'; // TODO 上线前填真实值 (DONATE-04)
}
```

---

### `test/architecture/legal_asset_parity_test.dart` (test, file-existence loop)

**Analog:** `test/architecture/arb_key_parity_test.dart` — `dart:io` `File(...).readAsStringSync()` map-loop structure. For assets use `.existsSync()` instead of parsing:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const _docs = ['privacy', 'terms', 'tokusho'];
const _langs = ['ja', 'zh', 'en'];

void main() {
  group('legal asset parity', () {
    test('all doc × locale assets exist', () {
      for (final doc in _docs) {
        for (final lang in _langs) {
          final path = 'assets/legal/${doc}_$lang.md';
          expect(File(path).existsSync(), isTrue,
              reason: 'missing legal asset $path');
        }
      }
    });
  });
}
```
Model the loop shape on arb_key_parity_test.dart:77-83 (`_loadArbFiles` File map) and :46-52 (nested `for` + `expect(...contains..., reason:)`).

---

### `test/widget/features/settings/legal_sponsor_section_test.dart` (test, widget)

**Analog:** `test/widget/features/settings/security_section_test.dart` (exact harness). Copy:
- `createLocalizedWidget(...)` from `../../../helpers/test_localizations.dart` (security_section_test.dart:12, 33-47) — wraps section in `Scaffold(body: SingleChildScrollView(child: ...))`, `locale: const Locale('ja')`, `overrides:`.
- `S l10nOf(WidgetTester)` helper via `S.of(tester.element(find.byType(LegalSponsorSection)))` (:50-51).
- For DONATE-02 use the `url_launcher` mock from RESEARCH §url_launcher test pattern: `class _MockLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform`, set `UrlLauncherPlatform.instance = _MockLauncher()` in `setUp`, assert `lastUrl == LegalUrls.donation` and `options.mode == PreferredLaunchMode.externalApplication`.

### `test/widget/features/settings/legal_doc_screen_test.dart` (test, widget + asset)

**Analog:** same `createLocalizedWidget` harness. `rootBundle` assets are available in widget tests (declared in pubspec). Pump `LegalDocScreen(doc: ...)` per locale, `pumpAndSettle`, assert `find.byType(SelectableText)` / expected copy (e.g. 特商法「請求時提供」string) is present.

---

### `lib/features/settings/presentation/screens/settings_screen.dart` (MODIFY)

**Insertion site — settings_screen.dart:152-158** (the tail of the `ListView.children`):
```dart
              KeyedSubtree(
                key: _securitySectionKey,
                child: SecuritySection(settings: settings),   // Phase 55 — DO NOT MODIFY
              ),
              const Divider(),
              // ★ INSERT HERE (before AboutSection), matching the const Divider() rhythm:
              // const LegalSponsorSection(),
              // const Divider(),
              const AboutSection(),
            ],
```
Add `import '../widgets/legal_sponsor_section.dart';` alongside the existing widget imports (settings_screen.dart:17-22). RESEARCH Open Question 1: decide whether `AboutSection`'s privacy/license tiles migrate into the new section — read `.planning/sketches/003-legal-sponsor/index.html` (tone-C) as tie-breaker.

---

### `lib/l10n/app_{ja,zh,en}.arb` (MODIFY — new short labels)

**Existing key style** (app_ja.arb:528-543) — every key gets a sibling `@key` metadata object with `description`. Add in ALL THREE files (LEGAL-06 ARB parity):
```json
  "legalSponsorSectionTitle": "法的情報・応援",
  "@legalSponsorSectionTitle": {
    "description": "Legal & sponsor settings group title"
  },
```
Reuse existing keys where possible: `privacyPolicy` (app_ja.arb:536), `openSourceLicenses` (:540), `appName` (:2). New keys needed: group title, terms-of-use label, 特商法 label, sponsor row label, doc-screen titles. `hardcoded_cjk_ui_scan` scans `lib/` Dart only — keep all Dart CJK in ARB (CJK inside `assets/legal/*.md` is safe).

## Shared Patterns

### i18n label access
**Source:** `about_section.dart` (every `Text(S.of(context).<key>)`)
**Apply to:** `legal_sponsor_section.dart`, `legal_doc_screen.dart` AppBar titles. Never hardcode CJK in Dart.

### Section render harness (tests)
**Source:** `test/widget/features/settings/security_section_test.dart:33-51` (`createLocalizedWidget` + `l10nOf`)
**Apply to:** both new widget tests.

### Config constant idiom
**Source:** `lib/core/constants/feature_flags.dart` (doc-commented compile-time const)
**Apply to:** `legal_urls.dart`.

### `.value ?? const Locale('ja')` locale read
**Source:** `transaction_edit_screen.dart:181`
**Apply to:** `legal_doc_screen.dart` asset-lang resolution.

### pubspec assets declaration
**Source:** `pubspec.yaml:111-112` (`assets:` currently lists only `- assets/satisfaction/`)
**Apply to:** add `- assets/legal/` under `flutter.assets:`; add `url_launcher: ^6.3.2` to `dependencies:` (near `package_info_plus: ^9.0.1` at pubspec.yaml:54).

## No Analog Found (use RESEARCH.md patterns instead)

| File / mechanism | Role | Data Flow | Reason |
|------------------|------|-----------|--------|
| `rootBundle.loadString` asset load in `legal_doc_screen.dart` | screen | file-I/O | Repo has ZERO existing `rootBundle` usage — first in codebase. Follow RESEARCH Pattern 2 verbatim; guard languageCode against `{ja,zh,en}` whitelist (V12). |
| `url_launcher` `launchUrl` external browser | plugin call | request-response | New dependency, no in-repo caller. Follow RESEARCH Pattern 3 (direct launch, no `canLaunchUrl` gate). |
| `assets/legal/*.md` legal prose (content) | asset | — | Content is authored fresh (D-01 trilingual drafts). No template; the 特商法 page uses 「請求時提供」型 (D-03). |
| `.planning/.../store-privacy-form-checklist.md` (D-05) | deliverable | — | Not app code; markdown deliverable, no code analog. |

## Metadata

**Analog search scope:** `lib/features/settings/`, `lib/core/`, `lib/l10n/`, `test/widget/features/settings/`, `test/architecture/`, `pubspec.yaml`
**Files scanned:** ~14
**Pattern extraction date:** 2026-07-01
</content>
</invoke>
