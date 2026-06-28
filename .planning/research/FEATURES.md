# Feature Research

**Domain:** Pre-launch capstone features for a free, local-first, privacy-first family accounting app — Japanese market (iOS 14+/Android 7+). Scope: (a) first-run onboarding with mandatory locale/currency/voice-language setup, (b) app-lock (Face ID + PIN), (c) in-Settings donation/sponsorship link, (d) in-Settings legal section.
**Researched:** 2026-06-28
**Confidence:** MEDIUM-HIGH (UX patterns HIGH/well-established; Apple-policy + Japan-legal specifics MEDIUM and flagged for legal review)

> Scope note: This file covers ONLY the four new v2.0 features. Existing infra (i18n `currentLocaleProvider`/ARB ja·zh·en, v1.7 JPY-first currency selector, zh/ja/en voice locale routing, `biometric_service`/`secure_storage`/Ed25519/BIP39) is treated as a dependency, not re-researched.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Missing these = the app feels broken, unsafe, or gets rejected from the App Store.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Onboarding: device-locale-aware language pre-selection** | The very first screen must already be in the user's language; a Japanese user must not face a Chinese/English form | LOW | Detect device locale → pre-select ja/zh/en in `currentLocaleProvider`. "Mandatory" should feel like *confirm a sensible default*, not *fill a blank form* |
| **Onboarding: currency defaults to JPY** | Japanese-market app; JPY is the obvious default and already the v1.7 pinned currency | LOW | Reuse v1.7 selector logic; JPY pre-selected. Treat as confirm-not-configure |
| **Onboarding: re-entrant / can't get stuck** | If the app is killed mid-onboarding it must resume cleanly, never lock the user out of their own app | MEDIUM | Persist a single `onboarding_completed` flag; gate runs after `AppInitializer`, before main shell. Until the flag is set, re-show onboarding on next launch |
| **Onboarding: progress + back navigation** | Multi-step flows without progress/back feel like a trap | LOW | Step indicator + back button; final step is an explicit "始める/Start" |
| **App-lock: biometric-first with knowledge-factor fallback** | Standard iOS pattern — try Face ID/Touch ID automatically, fall back to a code the user knows | MEDIUM | PIN is the base credential; biometric is a convenience layer on top. Never biometric-only (a failed/changed face would lock the user out forever) |
| **App-lock: lock on cold launch when enabled** | A lock that doesn't trigger on a fresh launch is pointless | LOW | Gate the main shell behind the lock screen at boot when `appLockEnabled` |
| **App-lock: re-lock on resume from background** | Users expect a privacy lock to re-engage when they return to the app | MEDIUM | Lock when returning from background past a grace threshold (see UX params). This is the behavior people mean by "app lock" |
| **App-lock: failed-attempt feedback + escalating delay** | Silent failure or instant infinite retries feel broken/insecure | MEDIUM | Show remaining attempts; impose escalating cooldown after N failures. Do NOT wipe data by default (see anti-features) |
| **App-lock: settings toggle** | Users must be able to turn the lock on/off and change PIN later | LOW | Settings switch; enabling requires setting a PIN first |
| **Donation: single unobtrusive external link in Settings** | A free app may ask for support, but only quietly and only via an external browser per Apple policy | LOW | One row ("開発を支援" / "応援する") → `url_launcher` external browser. NOT IAP, NOT in-app webview |
| **Legal: Privacy Policy reachable in-app** | App Store **requires** a privacy policy URL for every app (even local-only); users + reviewers expect to find it in Settings | LOW-MEDIUM | Needs a publicly hosted URL regardless (App Store Connect field). In-app: link out and/or render bundled localized copy |
| **Legal: Terms of Use (利用規約)** | Standard Japanese-market expectation; defines the no-warranty/local-data relationship | LOW | Bundled localized screen or external link. If you supply none, Apple's standard EULA applies — but a Japanese 利用規約 is expected |
| **Legal: OSS license attribution** | MIT/BSD/Apache/etc. legally require attribution; a Flutter app shipping without it is non-compliant | LOW | Flutter's built-in `showLicensePage()` auto-aggregates all deps incl. transitive — near-zero cost, do not hand-maintain |
| **Legal: all of the above available in Japanese** | Japanese-market launch; ja is the default locale | LOW | Localize via ARB/bundled assets; license page is auto but its chrome should respect locale |

### Differentiators (Competitive Advantage)

Aligned with the app's core value: privacy, local-first, calm/non-coercive, family-friendly.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Onboarding: a genuine privacy/local-first intro (skippable)** | Most kakeibo apps push accounts/cloud; leading with "your data stays on this device, no account needed" is a real trust differentiator | LOW-MEDIUM | 2-4 calm intro slides; **skippable** (intro is skippable, *setup* is not). Reinforces the brand before the mandatory setup |
| **Onboarding: voice-input language confirmed, defaulted to UI language** | The app's voice entry is a signature feature; surfacing the voice locale at setup primes the killer feature | LOW | Default voice locale = chosen UI language (zh-CN/ja-JP/en-US); offer to confirm/override. Depends on existing voice routing |
| **App-lock: in-context, optional prompt during onboarding** | Offering the lock at first run (clearly skippable) drives adoption without nagging later | LOW-MEDIUM | "Skip" must be a first-class equal option, not a greyed-out afterthought. Enabling it = set PIN now, biometric opt-in |
| **App-lock: forgot-PIN recovery via existing BIP39 phrase** | Turns a dead-end ("forgot PIN = locked out / wiped") into graceful recovery, leveraging infra already built | MEDIUM | Decision needed: does the recovery phrase reset the PIN? Strongly recommended so a forgotten PIN never bricks local data |
| **Donation: warm, non-transactional framing (応援/支援)** | Japanese donation culture is reserved; "support the developer / cheer us on" lands better than "tip/投げ銭" | LOW | Copy choice, not engineering. One quiet line, no number suggestions, no guilt |
| **Legal: offline, bundled, localized legal screens** | A privacy-first offline app rendering its policy *without a network call* is on-brand and reviewer-friendly | MEDIUM | Bundle localized markdown; still keep the hosted URL for App Store Connect. Slightly more work than pure links |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **In-app IAP "tip jar" / paid tiers** | "Monetize the free app" | Apple's stance on pure *developer* donations via IAP is murky and review-risky; 30% cut; contradicts the "entirely free" promise; adds StoreKit complexity | External-browser link to Buy Me a Coffee / Ko-fi / GitHub Sponsors / PayPal.me only |
| **Gating any feature behind a donation** | "Incentivize donating" | Breaks the "entirely free, no forced payment" core promise; coercive; erodes trust | Donation is purely optional and grants nothing; never paywall |
| **Donation nag dialogs / interstitials / badges** | "More visibility = more donations" | Dark pattern; the opposite of the app's calm/non-coercive identity (ADR-012 spirit); annoys Japanese users especially | One static Settings row. No popups, no counters, no "you haven't donated" reminders |
| **Forced account / email capture at onboarding** | "Build a user list", "enable sync" | Directly contradicts local-first/no-account architecture; #1 onboarding drop-off cause; privacy red flag | No account. Onboarding collects only locale/currency/voice + optional lock |
| **Unskippable intro carousel / forced tutorial** | "Make sure they see our features" | Feels like a hostage screen; users want to reach the app | Intro slides skippable; only the 3 setup choices are mandatory (and pre-filled) |
| **Requesting mic/biometric/notification permissions up front during onboarding** | "Get permissions out of the way" | iOS best practice is in-context permission requests; pre-asking tanks grant rates and looks creepy | Request biometric only when the user opts into app-lock; request mic only on first voice use (already the case) |
| **App-lock that wipes data after N failures (default-on)** | "Bank-grade security" | A family expense app silently destroying local data is catastrophic and surprising; no cloud backup to restore from | Escalating cooldown only. If offered at all, "erase after N fails" must be explicit opt-in, off by default, with the BIP39 caveat spelled out |
| **Biometric-only app-lock (no PIN)** | "Face ID is enough" | Face/Touch changes, OS biometric lockout, or sensor failure = permanent lockout with no fallback | PIN is mandatory whenever lock is enabled; biometric layered on top |
| **Storing the PIN in plaintext / reversible** | "Simplest to implement" | Trivial extraction defeats the whole privacy posture | Store a salted KDF hash (or derive a key) in `secure_storage`; never the raw PIN |
| **Locking the whole app behind a blocking ToS-accept gate** | "Legal cover" | Heavy friction for a free local app; un-Japanese (利用規約 is browsable, not a wall) | Legal docs are *reachable* in Settings + linked at first run; no blocking modal |
| **Per-currency home base other than JPY at onboarding** | "Be international" | Out of v1.7 scope (JPY is the stored base); adds confusion at first run | Onboarding currency = entry-currency default only; base stays JPY (carried v1.7 decision) |

---

## Concrete UX Parameters (for the requirements writer — make these testable)

### (a) Onboarding flow
- **Step order:** ① (optional) intro slides → ② UI language (pre-selected from device locale) → ③ currency (JPY pre-selected) → ④ voice-input language (defaults to chosen UI language) → ⑤ optional app-lock prompt → ⑥ "Start". Language MUST come first so steps 3-6 render in the chosen language.
- **Skippable vs mandatory:** intro = skippable; steps ②③④ = mandatory but pre-filled (a single tap to confirm each, or a "use defaults" path); step ⑤ = skippable.
- **Persistence:** one boolean `onboarding_completed` (recommend `secure_storage` or app prefs); gate evaluated after `AppInitializer`, before main `IndexedStack` shell. Re-entrant if killed before the flag is set.
- **No account, no email, no upfront OS permission prompts.**
- **Open decision to spell out:** whether changing UI language mid-onboarding rebuilds the flow live (recommended) and whether there's a single "skip all setup → use device defaults" express path.

### (b) App-lock
- **Credentials:** PIN mandatory when lock enabled; biometric optional add-on. Fallback ordering: on a locked screen, **attempt biometric automatically first**; on biometric fail/cancel/unavailable → **PIN entry**. PIN is also the explicit "use passcode" fallback button.
- **PIN length:** recommend **6 digits** (matches iOS default, ~10⁶ space); 4-digit acceptable if simplicity preferred — pick one and fix it. Numeric.
- **PIN storage:** salted KDF hash (e.g. PBKDF2/Argon2 via existing crypto infra) in `secure_storage`. Never plaintext, never reversible.
- **Retry / lockout:** show remaining attempts; after **5** failed PIN attempts apply an **escalating cooldown** (e.g. 30s → 1m → 5m → 15m). **No data wipe** by default. Define exact thresholds as testable values.
- **Re-lock timing:** **always lock on cold launch** (when enabled). On **resume from background**, lock if backgrounded longer than a **grace threshold** — recommend a small set: *immediately / 1 min / 5 min*, default **immediately or 1 min** for a privacy app. Define default + whether it's user-configurable.
- **"Skip app-lock" meaning:** app-lock stays **OFF**; no PIN set; user can enable later in Settings. Enabling later = set PIN (mandatory) + optional biometric.
- **Forgot-PIN:** decision required — recommend **BIP39 recovery phrase resets the PIN** so a forgotten PIN never bricks local data. Alternative (no recovery) must be stated as an explicit, scary trade-off.
- **Scope clarification needed:** is the lock a **UI gate over the already-decrypted SQLCipher DB**, or tied to the DB key? Almost certainly a UI gate (DB is decrypted by `KeyManager` at boot). State this so the threat model is honest (UI gate ≠ at-rest protection; SQLCipher already provides that).
- **Biometric change handling:** if enrolled biometrics change (iOS invalidates), fall back to PIN (don't silently trust). Reuse `biometric_service` semantics.

### (c) Donation link
- **Presentation:** exactly one Settings row, calm copy ("開発を支援する" / "応援する" / "Support development"). No amounts, no frequency, no counters, no popups.
- **Mechanism:** `url_launcher` with `LaunchMode.externalApplication` (external browser, NOT SFSafariViewController/in-app webview, NOT IAP) → developer-owned/3rd-party donation page (Buy Me a Coffee / Ko-fi / GitHub Sponsors / PayPal.me).
- **Non-coercive invariants (testable):** grants no in-app benefit; never blocks any feature; never auto-prompts; appears only when the user navigates to Settings.

### (d) Legal section
- **Structure:** a single "About / 法的情報" group in Settings containing three rows: プライバシーポリシー, 利用規約, オープンソースライセンス. Three rows, not one merged screen — each is independently linkable/citable.
- **Privacy Policy:** publicly **hosted URL is mandatory** for App Store Connect regardless of in-app rendering. In-app: link out and/or render bundled localized copy.
- **Terms of Use:** bundled localized 利用規約 screen or external link. (Absent your own, Apple's standard EULA applies — but ship a Japanese 利用規約.)
- **OSS licenses:** Flutter built-in `showLicensePage()` — auto-aggregates incl. transitive deps. Set `applicationName`/`applicationVersion`/`applicationLegalese`. Do not hand-maintain.
- **No blocking accept-gate.** Reachable, not a wall.

---

## Japanese-Market Expectations (explicit callouts)

- **特定商取引法 (Act on Specified Commercial Transactions):** when money changes hands, a 「特定商取引法に基づく表記」 may be required. For donations routed through an **external platform** (Buy Me a Coffee/Ko-fi/etc.), that platform's own 特商法 表記 generally applies and the app links out — but **this is a legal-review flag, not a settled engineering fact.** If the project ever takes donations *directly*, 特商法 表記 + プライバシーポリシー placement rules (easy-to-find, linked from top + transaction page) become directly relevant. Recommend confirming with the chosen donation platform's policy and, if in doubt, adding a 特商法 表記 entry under the legal section. (Confidence: MEDIUM — verify before launch.)
- **利用規約 is a baseline expectation** in Japan, not optional polish.
- **プライバシーポリシー in Japanese** is both an App Store requirement (hosted URL) and a strong local expectation; for a local-first app it can honestly state "data stored only on device, no transmission."
- **Tone:** Japanese users respond poorly to aggressive monetization/nagging. The non-coercive donation framing (応援/支援) and the absence of nags are market-fit features, not just ethics.
- **Defaults:** ja locale + JPY are the obvious first-run defaults; treat onboarding as confirmation.

---

## Feature Dependencies

```
First-run onboarding
    ├──requires──> i18n (currentLocaleProvider, ARB ja/zh/en)        [EXISTS]
    ├──requires──> v1.7 currency selector                             [EXISTS]
    ├──requires──> voice locale routing (zh-CN/ja-JP/en-US)           [EXISTS]
    ├──requires──> onboarding gate slot (after AppInitializer,        [NEW — first time]
    │              before IndexedStack main shell)
    └──enhances/optionally-embeds──> App-lock prompt (step ⑤)

App-lock (Face ID + PIN)
    ├──requires──> biometric_service                                  [EXISTS]
    ├──requires──> secure_storage                                     [EXISTS]
    ├──requires──> PIN entry UI + salted-hash storage                 [NEW]
    ├──requires──> lifecycle observer (cold launch + resume gate)     [NEW]
    └──enhances──> BIP39 recovery phrase as forgot-PIN reset          [EXISTS infra, NEW wiring]

Donation link
    └──requires──> url_launcher external browser                      [LIKELY NEW dep]

Legal section
    ├── Privacy Policy ──requires──> hosted URL (App Store Connect)   [NEW, external/ops]
    ├── Terms of Use   ──requires──> bundled localized copy or link   [NEW content]
    └── OSS licenses   ──requires──> Flutter showLicensePage()        [BUILT-IN]

App-lock prompt in onboarding ──requires──> App-lock feature complete (ordering constraint)
```

### Dependency Notes
- **Onboarding needs its gate built before its steps:** the "evaluate `onboarding_completed` after `AppInitializer`, before main shell" slot is the app's first onboarding gate and is the structural prerequisite for all onboarding work.
- **App-lock must land before (or with) the onboarding app-lock prompt:** step ⑤ can't offer to enable a lock that doesn't exist. Sequence app-lock core → then wire the onboarding prompt.
- **Donation + Legal are independent leaves:** no dependency on onboarding/app-lock; can be built in parallel. Both are low-complexity.
- **PIN is the only genuinely new security primitive;** biometric, secure storage, and KDF infra already exist and should be reused (no custom crypto per CLAUDE.md).

---

## MVP Definition

### Launch With (v2.0 — these ARE the milestone)
- [ ] **Onboarding gate + mandatory locale/currency/voice setup** — required for a public first-run; defaults pre-filled (Japanese-market confirm-not-configure)
- [ ] **Skippable privacy/local-first intro** — trust differentiator, cheap
- [ ] **App-lock: PIN (mandatory base) + Face ID/Touch ID (optional), cold-launch + resume re-lock, escalating cooldown** — table stakes for a finance app holding family money data
- [ ] **App-lock onboarding prompt (skippable) + Settings toggle** — adoption without nagging
- [ ] **Donation: one external-browser link in Settings** — satisfies the "free + optional support" goal Apple-compliantly
- [ ] **Legal section: Privacy Policy + 利用規約 + OSS licenses, all localized** — App Store + Japanese-market compliance

### Add After Validation (v2.x)
- [ ] **Forgot-PIN → BIP39 recovery reset** — strongly recommended; if descoped at launch, document the "forgotten PIN" trade-off explicitly first
- [ ] **Configurable re-lock grace period (immediate/1m/5m)** — ship a sensible fixed default first, make it a setting later
- [ ] **特商法 表記 entry** — add if/when legal review says the donation path triggers it

### Future Consideration (v2+)
- [ ] **Opt-in "erase data after N failures"** — only with heavy warnings + BIP39 awareness; default off, likely never
- [ ] **Re-onboarding / change-defaults wizard** — defaults are already changeable in Settings, so low value

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Onboarding gate + mandatory setup (defaults pre-filled) | HIGH | MEDIUM | P1 |
| Skippable privacy intro | MEDIUM | LOW | P1 |
| App-lock PIN + biometric + re-lock + cooldown | HIGH | MEDIUM-HIGH | P1 |
| App-lock onboarding prompt + Settings toggle | MEDIUM | LOW | P1 |
| Donation external link | MEDIUM | LOW | P1 |
| Legal: Privacy / Terms / OSS licenses | HIGH (compliance) | LOW-MEDIUM | P1 |
| Forgot-PIN BIP39 recovery | MEDIUM | MEDIUM | P2 |
| Configurable re-lock grace | LOW | LOW | P2 |
| 特商法 表記 (if triggered) | LOW (legal) | LOW | P2 (gated by legal review) |
| Opt-in erase-after-N | LOW | MEDIUM | P3 |

**Priority key:** P1 = must have for launch · P2 = should have / fast-follow · P3 = future/likely-never.

## Competitor Feature Analysis

| Feature | Typical kakeibo / finance app | Privacy-first app norm | Our Approach |
|---------|------------------------------|------------------------|--------------|
| Onboarding | Push account/cloud signup, upsell premium | No account, local setup | Mandatory locale/currency/voice only, no account, skippable intro |
| App-lock | PIN/biometric gate, some wipe-on-fail | Biometric + PIN, escalating delay | PIN-base + biometric layer, cold+resume lock, cooldown (no default wipe), BIP39 recovery |
| Donation/monetization | IAP tiers, ads, premium paywall | External "support" link | One quiet external-browser link, zero gating, 応援 framing |
| Legal | Hosted PP/ToS links, license page | Bundled/offline legal | PP (hosted URL req'd) + ja 利用規約 + `showLicensePage()`, localized, no accept-wall |

## Sources

- [Apple App Review Guidelines (3.1.1 / 3.2.1 donations)](https://developer.apple.com/app-store/review/guidelines/) — donations via external Safari link, free apps collect funds outside app, IAP tip-jar discouraged for developer donations (MEDIUM confidence on exact current wording — verify at submission)
- [Apple Developer Forums — "Donate to Developer" on a free app](https://developer.apple.com/forums/thread/114186)
- [Medium — Buy Me a Coffee link vs Apple review experience](https://medium.com/@robert-baer/my-ongoing-battle-with-apple-over-a-buy-me-a-coffee-link-is-over-9c158df81c05)
- [Stripe — Notation based on Japan's Act on Specified Commercial Transactions (特定商取引法)](https://stripe.com/resources/more/specified-commercial-transactions-act-japan)
- [PAY.JP — 特定商取引法に基づく表記：寄付の記載例](https://help.pay.jp/ja/articles/3438270)
- [IT弁護士 中野秀俊 — アプリ/ECに必要な特定商取引法に基づく表記](https://it-bengosi.com/%E3%82%A2%E3%83%97%E3%83%AA%E9%96%8B%E7%99%BA%E3%81%AE%E6%B3%95%E5%BE%8B/ec-apuri/)
- [Apple Support — Lock or hide an app / re-auth on resume](https://support.apple.com/guide/iphone/lock-or-hide-or-an-app-iph00f208d05/ios)
- [Medium (Gaurav Harkhani) — Implementing App Lock in iOS (biometric + passcode fallback, lockout)](https://medium.com/@gauravharkhani01/implementing-app-lock-in-ios-everything-you-need-to-know-918d65dff9c0)
- [App Store Connect — Manage app privacy (privacy policy URL mandatory)](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Flutter LicensePage / showLicensePage (auto OSS attribution incl. transitive)](https://api.flutter.dev/flutter/material/LicensePage-class.html) · [code with andrea — Show licenses in Flutter](https://codewithandrea.com/tips/show-licenses-flutter-app/)
- Project context: `.planning/PROJECT.md` (v2.0 milestone scope), CLAUDE.md (existing i18n/currency/voice/biometric infra)

---
*Feature research for: pre-launch onboarding / app-lock / donation / legal — Japanese-market local-first family accounting app*
*Researched: 2026-06-28*
