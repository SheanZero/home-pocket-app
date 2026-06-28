# Pitfalls Research

**Domain:** Pre-launch capstone for a shipped local-first encrypted Flutter family-accounting app — adding first-run onboarding, Face ID + PIN app-lock, donation link, and Japanese-market legal/license surfaces
**Researched:** 2026-06-28
**Confidence:** MEDIUM-HIGH (integration/security pitfalls HIGH — grounded in this codebase + project memory; store-policy/legal pitfalls MEDIUM — policies shift and final legal sign-off needs a JP lawyer)

> Scope discipline: every pitfall below is about **adding these four features to THIS app** (ordered `AppInitializer` boot, `flutter_secure_storage` 10.x at `unlocked_this_device`, IndexedStack shell, no go_router, strict ARB ja/zh/en parity + hardcoded-CJK scan, shipped JPY/voice/sync paths). Generic "remember to test" advice is omitted.

---

## Critical Pitfalls

### Pitfall 1: Changing keychain accessibility while adding PIN/biometric storage → bricks every existing install

**What goes wrong:**
The app-lock work touches `secure_storage_service.dart` to store a new PIN hash and lock settings. It is extremely tempting to "harden" the new secret with a stricter accessibility class (e.g. `first_unlock_this_device` or `whenPasscodeSetThisDeviceOnly`), or to set per-item `IOSOptions(accessibility:)` on the PIN write. On `flutter_secure_storage ^10.2.0` (darwin 0.3.1), `kSecAttrAccessible` is injected into the **read** query (`baseQuery`, no accessibility-agnostic fallback). Any item written under one accessibility becomes unreadable once the read query asks for a different one → `errSecItemNotFound` → `read()` returns null.

**Why it happens:**
Accessibility looks like a per-call security knob; nothing at compile time warns that it silently changes read semantics. 9.x did not behave this way, so prior intuition is wrong.

**How to avoid:**
- Keep the existing storage at `unlocked_this_device`. The new PIN hash must be written with the **same** `IOSOptions`/`AndroidOptions` as the master key — do not pass a custom accessibility.
- If a stricter class is ever genuinely required, it needs an explicit read-under-old → rewrite-under-new keychain migration step, gated and tested on a populated install. Default answer for v2.0: **do not change it.**
- Add a regression guard: a test asserting the secure-storage options object used for PIN is the shared one (not a fresh `IOSOptions(accessibility: …)`).

**Warning signs:**
On a device with existing data, app boots to the generic 初期化失敗 / 初始化失败 screen after the update; `hasMasterKey()` returns false though data exists; the `masterKeyMissingWithData` data-loss guard trips.

**Phase to address:** App-lock / PIN-storage phase (first phase that writes a new secret). Project memory: `flutter-secure-storage-accessibility-read-filter`, quick 260610-ss7.

---

### Pitfall 2: PIN stored in plaintext / fast hash / no lockout → trivially brute-forceable

**What goes wrong:**
A 4–6 digit PIN has only 10^4–10^6 possibilities. Storing it as plaintext, or as a single SHA-256, or in SharedPreferences, means a device-backup/jailbreak/file-dump extraction cracks it in milliseconds. Equally bad: no retry limit, so an attacker (or a curious family member) can guess unlimited times in the UI.

**Why it happens:**
"It's just a local convenience lock" framing; the master key already encrypts the DB, so the PIN feels low-stakes. But the PIN is also the biometric fallback that gates DB access, so it is a real auth boundary.

**How to avoid:**
- Never store the PIN itself. Store a salted, slow KDF digest: reuse the project's existing crypto infra (HKDF/PBKDF2 already present via SQLCipher/key_manager) or a memory-hard KDF; per-install random salt; the digest lives in `flutter_secure_storage` at the shared accessibility (Pitfall 1), **not** SharedPreferences/Drift.
- Enforce a retry counter persisted in secure storage (not in-memory — survives app kill): exponential backoff after N failures (e.g. 5 → cooldown), and a hard lockout that forces biometric or a longer wait. Counter must be cleared only on a correct unlock.
- Constant-time comparison of digests.
- Decide and document: does PIN lockout ever wipe data? For a privacy app the answer is usually **no auto-wipe** (data-loss risk), so make lockout time-based, not destructive.

**Warning signs:**
PIN value greppable in a DB/prefs dump; unlock screen accepts unlimited attempts; retry counter resets on app relaunch.

**Phase to address:** App-lock / PIN-storage phase.

---

### Pitfall 3: Onboarding gate races `AppInitializer` → "first-run" shows on every launch, or shows before keys exist

**What goes wrong:**
The first-run gate must read/write persisted "onboarding completed" + the chosen UI-language / currency / voice-language. If the gate renders before `AppInitializer` finishes (KeyManager → Database → others), then: (a) the "completed" flag read returns null/default → onboarding re-appears every launch (idempotency break), or (b) the gate tries to persist the currency/voice choice into encrypted storage before the DB/keys are ready → write fails or silently no-ops, or (c) two async paths both decide routing and the shell flickers between onboarding and main.

**Why it happens:**
This is the app's **first** onboarding gate; routing has always been "boot → main shell." Developers wire the gate as just another widget and let it read providers that aren't hydrated yet. There is no go_router redirect layer to centralize the decision.

**How to avoid:**
- Make the onboarding decision a **derived state of a completed `AppInitializer`**, not a parallel async. Compute `needsOnboarding` only after init resolves; the root chooses {OnboardingFlow | MainShell} from a single settled source, mirroring the existing `UncontrolledProviderScope` + error-fallback pattern.
- Persist the "completed" flag where it survives reinstall-vs-update correctly and is readable at boot — and decide explicitly whether it lives with the encrypted settings (only readable post-init) or in a boot-safe store. If it must be read to decide the very first frame, it cannot depend on the DB being open; keep the gate flag in a store that's available right after KeyManager, and persist the *content* choices (currency/voice) into the normal settings once the DB is up.
- Idempotency: write the completed flag exactly once, on explicit "finish," inside a single transaction/await; never infer completion from "currency is non-null."
- The chosen UI language must flow through the existing `currentLocaleProvider` and the voice language through the existing zh-CN/ja-JP/en-US route — do not introduce a second source of truth.

**Warning signs:**
Onboarding reappears after force-quit; first-run choices not reflected until a second launch; brief flash of main shell before onboarding (or vice-versa); writes during onboarding throw "database not open."

**Phase to address:** Onboarding-gate phase. (PROJECT.md explicitly calls out: gate must be判定 after `AppInitializer`, before main shell.)

---

### Pitfall 4: App-lock doesn't re-lock on resume, and contents leak in the app switcher / screenshots

**What goes wrong:**
Lock-on-launch is implemented, but lock-on-resume (returning from background) is forgotten or mis-timed, so anyone who picks up an unlocked-then-backgrounded phone sees the ledger. Separately, the iOS app-switcher snapshot and Android recents thumbnail capture the last frame (full of financial data) and persist it unencrypted; screenshots of sensitive screens are allowed by default.

**Why it happens:**
`AppLifecycleState` handling is subtle: `inactive` fires for transient interruptions (notification shade, Face ID sheet, control center) — re-locking on every `inactive` makes biometric unlock loop forever (the biometric prompt itself backgrounds the app). The switcher snapshot is an OS behavior most devs never see in testing.

**How to avoid:**
- Re-lock on `paused`/resume, not naively on `inactive`. Use a grace policy (immediate, or a short configurable timeout) and explicitly **suppress re-lock while a biometric prompt is in flight** to avoid the unlock loop.
- Obscure contents when backgrounded: cover the top route with an opaque shield on `inactive`/`paused` (so the switcher snapshot shows the shield, not data). On Android, consider `FLAG_SECURE` for lock/sensitive screens (also blocks screenshots) — but verify it doesn't break the existing screens or golden/device QA.
- The lock screen lives **above** the IndexedStack shell as an overlay/root gate, not as a tab — so all tabs are covered and tab state (keepAlive) is preserved underneath.
- Skippable + Settings toggle: when disabled, the lifecycle observer must fully no-op (no shield, no prompt) so non-lock users see zero regression.

**Warning signs:**
Backgrounding then reopening shows data without a prompt; biometric prompt triggers an endless re-lock loop; recents/switcher thumbnail shows account balances; screenshot of a sensitive screen succeeds where it shouldn't.

**Phase to address:** App-lock phase (resume/lifecycle + switcher-privacy is its own slice).

---

### Pitfall 5: Biometric availability / enrollment / lockout edge cases with no PIN fallback → users locked out

**What goes wrong:**
Code assumes Face ID/fingerprint is always present and enrolled. Reality: no biometric hardware, hardware present but nothing enrolled, biometrics changed (iOS invalidates), OS-level biometric lockout after too many failures (`PlatformException` `LockedOut`/`PermanentlyLockedOut`), permission denied, or user just cancels. If the only path into the app is biometric and any of these occur, the user is bricked out of their own data. Conversely, enabling app-lock when neither biometric nor PIN is actually set up creates a lock with no key.

**Why it happens:**
`local_auth` happy-path demos ignore the error taxonomy; testing happens on a device with Face ID enrolled and working.

**How to avoid:**
- PIN is the **guaranteed fallback** and must always be offerable when biometric fails/unavailable. The enable-lock flow must require a PIN to be set first; biometric is an accelerator on top, never the sole factor.
- Handle the full `local_auth` error set explicitly: `notAvailable`, `notEnrolled`, `lockedOut`, `permanentlyLockedOut`, `passcodeNotSet`, user-cancel → each routes to the PIN screen with an appropriate message (localized, all 3 languages).
- Check `canCheckBiometrics` + `getAvailableBiometrics` at enable-time and at each unlock; degrade gracefully (hide the Face button when unavailable).
- Decide recovery-of-last-resort: if a user forgets the PIN and biometric is unavailable, what happens? For a no-backend privacy app, document that the only recovery is the existing BIP39 recovery-kit / reinstall — and make sure the onboarding/lock copy doesn't promise a recovery you don't have.

**Warning signs:**
QA only on a Face-ID-enrolled phone; `local_auth` call wrapped in a bare try/catch that swallows the error; "enable lock" succeeds with no PIN set; no UI path from a failed Face ID to PIN entry.

**Phase to address:** App-lock phase. Reuses existing `biometric_service.dart`; PIN fallback is the new surface.

---

### Pitfall 6: New screens ship untranslated strings / break ARB parity or trip the hardcoded-CJK scan

**What goes wrong:**
Onboarding, lock, PIN, donation, and the entire legal/license surface introduce a large batch of new copy — and legal text is the worst offender because devs paste a long プライバシーポリシー / 利用規約 as a hardcoded Japanese string. That instantly fails the hardcoded-CJK-UI architecture scan and the ARB ja/zh/en byte-parity gate, blocking the whole suite. Also common: adding keys to `app_ja.arb` only, forgetting `flutter gen-l10n`, or forgetting `git add -f lib/generated/`.

**Why it happens:**
Legal/onboarding copy is long and feels "static," so it doesn't feel like UI strings. The CJK scan and parity gates are strict supersets (project history: phases 46/47/52 repeatedly hit ARB-parity and orphan-key issues).

**How to avoid:**
- Every visible string (including long-form legal body text) goes through `S.of(context)` / ARB, all three locales updated together, then `flutter gen-l10n`, then `git add -f lib/generated/`. Run the hardcoded-CJK scan + full `flutter test` locally before declaring done.
- For long legal documents, decide the storage strategy deliberately: either ARB entries (parity-checked, but bulky) or bundled per-locale asset files (`assets/legal/{ja,zh,en}/*.md`) loaded by locale — the latter keeps ARB clean **but** then needs its own "all three locales present" gate so it doesn't bypass the parity discipline. Pick one and add the matching gate.
- Add the new screens' keys as a strict superset check, matching the existing trilingual parity gate (byte-equal key sets per locale, as v1.9 phase 52 enforced).

**Warning signs:**
`hardcoded_cjk_ui_scan` test failure; ARB key-count mismatch across locales; `flutter analyze` clean but generated l10n uncommitted; legal text only readable in Japanese.

**Phase to address:** Every UI-bearing phase, but most acutely the legal/license phase (largest copy volume). Make trilingual parity a success criterion of each.

---

### Pitfall 7: Donation link rejected by App Store / Google Play, or solicits money without 特商法 disclosure

**What goes wrong:**
A naive "Donate" button that (a) opens an **in-app WebView** to a payment page, or (b) looks like it's selling a digital good/premium, or (c) uses wording implying you get something, risks rejection under Apple Guideline 3.1.1 / 3.1.3 and Google Play's Payments policy. Historically Google has rejected apps merely for linking to donation pages, and external-payment-link programs were **US-only**. Separately, soliciting money from Japanese users can trigger 特定商取引法 (特商法) 表記 obligations (an app providing services online is treated as 通信販売), and the absence of プライバシーポリシー/利用規約 fails both store review and APPI expectations.

**Why it happens:**
Donation rules are genuinely murky and differ Apple-vs-Google and by region; devs copy a "Buy me a coffee" pattern that worked for someone else in a different market/year.

**How to avoid (concrete, conservative path for a free JP app):**
- **Open the donation page in the external browser** (`url_launcher` with `LaunchMode.externalApplication`), never an in-app WebView, and never via IAP. A genuine donation to the developer of a free app, opened externally, is the lowest-rejection path on both stores.
- **Neutral, non-transactional wording**: frame as 開発を応援 / サポート (support development), not "購入/購読/unlock". The donor receives nothing in-app, so it isn't digital-content sale (avoids Apple 3.1.1's IAP requirement).
- **Japan tailwind, but don't over-rely:** Japan's スマホ新法 (スマートフォンソフトウェア競争促進法, fully in force 2025-12-18) now *requires* Apple/Google to permit in-app external-payment links in Japan and caps their fee — so an external link is now legally backed in JP. Still, the **app must pass store review**: keep it a real donation, externally opened, plainly described. Treat the new law as removing the link prohibition, not as a guarantee of approval.
- **特商法 表記:** because you solicit money and run an online service, prepare a 特定商取引法に基づく表記 surface (運営者氏名/連絡先/任意性の明示 that it's a voluntary donation with no goods in return). For an individual developer, evaluate the "on-request disclosure" / platform-substitution options with a JP-savvy advisor. Make donation voluntariness explicit in copy.
- Have a fallback plan if rejected: be ready to soften wording or, worst case, gate the link behind an external Settings entry, since rejection is a real possibility.

**Warning signs:**
Donation opens in-app WebView; copy implies a reward/unlock; no 特商法 page despite money solicitation; relying on a US-only external-links entitlement for a JP release.

**Phase to address:** Donation phase + Legal/compliance phase (the 特商法 surface is legal, the link mechanics are donation). Verify with an actual TestFlight/internal-track review submission, not just self-assessment.

---

### Pitfall 8: Store privacy forms / OSS license attribution missing → review rejection or license violation

**What goes wrong:**
Two distinct gaps both block launch: (1) Apple Privacy Nutrition Labels and Google Play Data Safety form filled out wrong (or "no data collected" claimed while the exchange-rate API call or any analytics actually leaves the device), and missing/placeholder Privacy Policy URL — both are hard review blockers. (2) OSS attribution: Flutter apps pull dozens of MIT/BSD/Apache-2.0 packages whose licenses **must** be reproduced; shipping without a license-attribution screen violates those licenses and Apple/Google expectations.

**Why it happens:**
The app is local-first and "collects no data," so devs reflexively answer "no data" — but v1.7 added an outbound exchange-rate API (date+currency on the wire, no user data, but it *is* a network call) and any crash/diagnostic path matters too. OSS attribution is an afterthought because nothing breaks at build time.

**How to avoid:**
- Fill Apple's App Privacy + Google Data Safety **truthfully and consistently** with the written Privacy Policy: declare the exchange-rate network call's nature (no PII, request only), local-only encrypted storage, P2P sync (data stays between user devices, E2EE), no third-party analytics/ads (if true). Inconsistency between the form and the policy text is itself a rejection cause.
- Generate OSS attributions programmatically so they're complete and current: Flutter's built-in `showLicensePage` / `LicenseRegistry` covers registered licenses; surface it from Settings ("OSS ライセンス"). Verify it actually enumerates the real dependency set (including native pods where applicable) — don't hand-maintain a stale list.
- Privacy Policy + Terms of Use (利用規約) must exist as in-app readable surfaces **and** as hosted URLs for the store listings (stores require a reachable Privacy Policy URL). Keep both in sync, all three languages.
- APPI: even "we store everything locally and collect nothing centrally" must be stated affirmatively in the policy (purpose, retention, no third-party provision, contact). Local-first is a *strong* privacy story — say it precisely rather than leaving it implied.

**Warning signs:**
Privacy form says "no data" while code makes network calls; Privacy Policy URL is a placeholder/404; license screen hand-written; Terms only in Japanese; store listing rejected for "missing privacy details."

**Phase to address:** Legal/compliance phase. Verification = a dry-run store submission + a diff between the privacy form answers and the policy text + a check that `showLicensePage` lists the real `pubspec` deps.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store PIN in SharedPreferences / Drift instead of secure storage | Less plumbing | Extractable secret; security-review reject | Never |
| Single fast hash (SHA-256) for PIN, no salt/lockout | Quick to code | Brute-force in ms on dump | Never |
| Custom `IOSOptions(accessibility:)` on the new PIN write | Feels "more secure" | Bricks existing installs (Pitfall 1) | Never |
| Re-lock on `AppLifecycleState.inactive` | One-liner | Biometric prompt → infinite re-lock loop | Never |
| Hardcode long legal copy as Japanese strings | Skip ARB churn | Fails CJK scan + parity gate; untranslated | Never |
| Donation via in-app WebView | One screen, no app-switch | Store-rejection risk | Never |
| Hand-maintained OSS license list | Looks done | Incomplete/stale → license violation | Never (use `LicenseRegistry`) |
| Infer onboarding-complete from "currency != null" | Avoids a flag write | Idempotency break, re-shows onboarding | Never |
| Biometric-only lock, defer PIN | Ship lock sooner | Users locked out on biometric edge cases | Only behind a flag, before any release |
| Hosting legal docs only in-app (no URL) | One surface | Store listing needs a reachable URL | Never for store submission |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `flutter_secure_storage` 10.x | Per-item accessibility for new PIN secret | Reuse the shared `unlocked_this_device` options object; no per-call accessibility |
| `local_auth` | Assume enrolled biometric; swallow errors | Handle full error taxonomy → PIN fallback; check availability at enable + each unlock |
| `AppInitializer` ordering | Onboarding/lock reads providers pre-init | Derive routing from settled init; persist content choices only after DB open |
| IndexedStack shell (no go_router) | Lock screen as a tab; onboarding as a route push | Lock = root overlay above the shell; onboarding = root branch chosen once |
| `flutter gen-l10n` + `lib/generated/` (gitignored-tracked) | Forget regen or `git add -f` | Regen + force-add generated Dart; full test before done |
| Exchange-rate network call (v1.7) | Declare "no data collected" on store forms | Disclose the outbound request truthfully; keep form ↔ policy consistent |
| `url_launcher` for donation | `LaunchMode.platformDefault`/in-app WebView | `LaunchMode.externalApplication` to real browser |
| `showLicensePage` / `LicenseRegistry` | Hand-written attribution list | Surface the registry; verify it enumerates real deps |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Slow KDF on PIN run on UI thread | Unlock screen janks/freezes on every attempt | Run KDF off the main isolate (`compute`); tune cost so unlock is <~300ms but still slow vs brute-force | Immediately on lower-end Android 7 devices |
| Re-evaluating biometric availability on every frame/build | Stutter on lock screen | Resolve availability once per lock session, cache | At lock-screen mount |
| Loading full legal Markdown into a single Text widget | Slow first paint on the legal screen | Lazy/scrollable rendering; keep policy reasonable | Long policies on old devices |

(Scale is per-device, single-user — no server fan-out; classic throughput traps don't apply.)

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Changing keychain accessibility | Existing installs brick; master key unreadable | Keep `unlocked_this_device`; migrate only via read-old→write-new |
| Plaintext / fast-hashed PIN | Offline brute-force from a dump | Salted slow KDF in secure storage; constant-time compare |
| No PIN retry limit / in-memory counter | Unlimited guessing; resets on relaunch | Persisted retry counter + backoff/lockout, cleared only on success |
| No re-lock on resume | Shoulder-surf / unattended phone reads ledger | Re-lock on `paused`/resume, suppress during biometric prompt |
| App-switcher snapshot / screenshots of data | Financial data leaks to OS thumbnail / screenshot | Shield overlay on `inactive`; consider `FLAG_SECURE` on Android |
| Logging PIN / biometric state / secrets | Sensitive data in logs | Never log secrets (existing crypto rule); audit new lock code |
| Lock that wipes data on failed PIN | Catastrophic data loss for a no-backup user | Time-based lockout, no destructive wipe |
| Privacy form contradicts actual network behavior | Store rejection + APPI/trust damage | Reconcile form ↔ policy ↔ code (exchange-rate call) |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Mandatory onboarding too long before first value | Abandonment on first launch | Keep required steps to the three必填 (UI lang / currency / voice lang); defer the rest, allow skip on lock |
| No way to change onboarding choices later | User stuck with a wrong first pick | All three choices editable in Settings (reuse existing selectors) |
| Biometric failure dead-ends with no PIN path | User locked out of own data | Always surface "PINで解除" on biometric failure |
| Lock prompt fires during legitimate interruptions | Annoying repeated prompts | Grace timeout; don't lock on transient `inactive` |
| Donation framed as paywall/reward | Feels like the "free" promise broke | Voluntary, no-reward, 応援 framing; never blocks features |
| Legal screens only in Japanese | zh/en users can't read terms they accept | Trilingual legal surfaces |
| First-run forces language before user can read it | Confusion if device locale unexpected | Default to device locale, let user change on the same screen |

---

## "Looks Done But Isn't" Checklist

- [ ] **PIN storage:** Often missing salted slow-KDF + persisted lockout — verify a DB/prefs dump shows no PIN and reuses shared keychain accessibility.
- [ ] **App-lock resume:** Often missing re-lock on `paused` + switcher shield — verify backgrounding then reopening prompts, and the recents thumbnail shows no data.
- [ ] **Biometric fallback:** Often missing the full `local_auth` error→PIN routing — verify on a device with biometrics *unenrolled* and after triggering OS lockout.
- [ ] **Onboarding idempotency:** Often missing the once-only completed flag — verify force-quit mid-onboarding and after-completion both behave; choices persist on first launch.
- [ ] **Onboarding vs init:** Verify no write happens before DB open and no flash between shell/onboarding.
- [ ] **i18n:** Often missing one locale or `gen-l10n`/`git add -f` — verify ARB parity gate + hardcoded-CJK scan + full `flutter test` green.
- [ ] **Donation:** Often missing external-browser launch + neutral wording — verify it opens the system browser and reads as voluntary support.
- [ ] **Store privacy forms:** Often inconsistent with the exchange-rate network call — verify Apple/Google forms match the written policy and the code.
- [ ] **OSS attribution:** Often a stale hand list — verify `showLicensePage` enumerates the actual `pubspec` deps.
- [ ] **Legal URLs:** Often only in-app — verify a hosted Privacy Policy URL exists for both store listings.
- [ ] **No regression:** Verify shipped JPY entry, zh/ja/en voice, and P2P sync paths are byte-unchanged (lock disabled = full no-op).

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Shipped a keychain-accessibility change (bricked installs) | HIGH | Hotfix reverting to `unlocked_this_device`; if data already lost, only BIP39 recovery-kit/reinstall — communicate clearly. (Prevention is the only real cure.) |
| PIN stored weakly already shipped | MEDIUM | Re-mint: on next unlock, re-hash under salted KDF and overwrite; invalidate old entry; force re-set if needed |
| Re-lock infinite loop on biometric | LOW | Add the "suppress re-lock while biometric in flight" guard; gate on `paused` not `inactive` |
| Donation link rejected by review | MEDIUM | Switch to external browser + neutral wording; if still rejected, move link to an external Settings entry or remove for the JP launch build |
| Privacy form/policy mismatch flagged | LOW–MEDIUM | Correct the form to match code+policy; resubmit |
| Incomplete OSS attribution discovered | LOW | Swap hand list for `LicenseRegistry`/`showLicensePage`; rebuild |
| Onboarding re-shows every launch | LOW | Fix the completed-flag write to a boot-readable store; add idempotency test |

---

## Pitfall-to-Phase Mapping

> Milestone continues from v1.9 Phase 52 → this milestone starts at **Phase 53** (numbering not reset). Exact phase boundaries are the roadmap's call; mapping below is by feature slice.

| Pitfall | Prevention Phase (slice) | Verification |
|---------|--------------------------|--------------|
| 1. Keychain accessibility brick | App-lock / PIN-storage | Test asserts shared options object; manual update test on a populated install boots OK |
| 2. Weak PIN / no lockout | App-lock / PIN-storage | Dump shows no PIN; salted-KDF + persisted backoff unit tests; constant-time compare |
| 3. Onboarding races init / idempotency | Onboarding-gate (design-gate first) | Routing derives from settled init; force-quit + re-launch tests; first-run choices persist |
| 4. No re-lock on resume / switcher leak | App-lock (lifecycle slice) | Background→reopen prompts; switcher shield verified; biometric no-loop |
| 5. Biometric edge cases / PIN fallback | App-lock | Unenrolled-device + OS-lockout manual tests route to PIN |
| 6. i18n parity / CJK scan on new screens | Every UI phase (esp. Legal) | ARB parity gate + hardcoded-CJK scan + full `flutter test` green |
| 7. Donation rejection / 特商法 | Donation + Legal/compliance | External-browser launch verified; 特商法 surface present; TestFlight/internal review pass |
| 8. Privacy forms / OSS / Privacy Policy / Terms | Legal/compliance | Form↔policy↔code reconciliation; `showLicensePage` enumerates deps; hosted URLs reachable; trilingual |

**Suggested ordering rationale:** Onboarding-gate uses the v1.8/Phase-43 HTML-design-gate-first pattern (no production code until the design is approved), so it can start early in parallel with research. App-lock is the highest-risk integration (keychain + lifecycle + biometric) and should be its own phase with security review. Legal/compliance + donation are launch gates — schedule them so there's slack for a real store-review round-trip before the target release date, since donation/privacy rejections are the most likely external blocker.

---

## Sources

- Apple App Review Guidelines (3.1.1 / 3.1.3, external-link updates): https://developer.apple.com/app-store/review/guidelines/ ; https://9to5mac.com/2025/05/01/apple-app-store-guidelines-external-links/ ; https://appleinsider.com/articles/25/05/02/apples-app-store-guidelines-updated-to-reflect-court-order-over-external-purchases — external-payment-link entitlement is US-storefront; global restriction otherwise (MEDIUM, policy shifts)
- Google Play donations/external-links: https://news.ycombinator.com/item?id=26761594 ; https://github.com/streetcomplete/StreetComplete/issues/3768 ; external-content-links program (US): https://support.google.com/googleplay/android-developer/answer/16470497 (MEDIUM)
- Japan スマホ新法 (スマートフォンソフトウェア競争促進法, in force 2025-12-18; Apple/Google designated; external payment links permitted, fees capped): https://www.jftc.go.jp/msca/ ; https://www.businesslawyers.jp/articles/1422 ; https://www.gmo-pg.com/blog/articles/article-0176/ (MEDIUM-HIGH for the legal change; review-approval still required)
- 特定商取引法 表記 for online-service/individual operators: https://it-bengosi.com/ ; https://www.no-trouble.caa.go.jp/privacypolicy/ (MEDIUM — confirm with JP legal advisor)
- APPI / Privacy Policy (Personal Information Protection Commission): https://www.ppc.go.jp/personalinfo/faq/APPI_QA/ (MEDIUM)
- Project memory `flutter-secure-storage-accessibility-read-filter` (quick 260610-ss7) — keychain accessibility immutability (HIGH, codebase-grounded)
- This repo: `CLAUDE.md` (security/i18n/iOS build rules, `AppInitializer` order), `.planning/PROJECT.md` (v2.0 scope, gate-after-init constraint), v1.9 phase-52 ARB-parity discipline (HIGH)

---
*Pitfalls research for: pre-launch onboarding + app-lock + legal/donation surfaces on a local-first encrypted Flutter app, Japan market*
*Researched: 2026-06-28*
