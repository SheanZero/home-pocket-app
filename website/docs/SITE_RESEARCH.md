# Happy Pocket website research

Research date: 2026-08-05

Scope: Japanese household-accounting services, relationship-oriented family finance, and popular Japanese independent apps with a warm editorial identity.

## Japanese market patterns

| Reference | What its site communicates first | Useful structural lesson |
| --- | --- | --- |
| [OsidOri](https://www.osidori.co/) | A couple can see shared household money while retaining a private space | Lead with the emotional family benefit, then make the sharing boundary explicit and easy to understand |
| [Money Forward ME](https://moneyforward.com/me) | Broad day-to-day convenience and an immediately recognizable product | Real interface evidence should make the promise credible, but it should not overwhelm the human story |
| [Zaim](https://zaim.net/) | Familiar Japanese household-accounting language, practical benefits, security, and substantial help content | Use a clear sequence, calm proof, and a real FAQ rather than a dense feature wall |
| [muute](https://muute.jp/) | Emotional self-reflection presented as a quiet, safe personal habit | Soft editorial typography, generous whitespace, and non-judgmental copy can make data feel humane |
| [Inventy](https://www.inventy-app.com/) | An ordinary family problem shown through a warm everyday story | Lifestyle photography should show the life being supported, not a staged technology demo |

The most relevant Japanese independent-app pattern is restraint: one clear idea, a small number of confident sections, tactile imagery, and enough empty space for the user to feel unhurried. Finance products add a second requirement—concrete proof about where data lives and what family members can see.

## Product truth used in the redesign

- Spending is not treated as a failure. Everyday necessities and personally meaningful Joy records are both part of a good life.
- Recording supports reflection, not competition. There are no streaks, leaderboards, celebration triggers, or achievement badges.
- Plaintext financial data and encryption keys are held on-device.
- Only records chosen for the family ledger enter family sync, and they are end-to-end encrypted on the sending device.
- Personal-ledger records stay out of family sync.
- There are no advertising or behavioral-analytics SDKs.
- Store release is still in preparation, so the website exposes both platform entry points while labeling the listing status honestly.

## Final information architecture

1. A concise homepage with the warm family-life hero, both store entry points, and five clear paths into the rest of the site.
2. A philosophy page for the Everyday/Joy model and the non-judgmental idea behind recording spending.
3. A features page for the dual ledger, Joy reflection, input methods, and real light/dark iOS Simulator evidence.
4. A family page for shared-versus-personal boundaries, member management, and selective E2EE sync.
5. A dedicated privacy architecture page for storage, encryption, external connections, and source-code inspection.
6. A dedicated FAQ page for release status, supported devices, sharing boundaries, and advertising policy.
7. Shared Japanese/English navigation, download calls to action, footer, mobile menu, metadata, and 404 treatment across every route.

## Visual system

- Warm paper `#F5F0E7`, near-white card `#FFFDF8`, leaf green `#456B59`, and sakura rose `#C75F7C`.
- Japanese Mincho-style display typography with a clean system sans-serif for body text and controls.
- Two generated, text-free lifestyle photographs: a family dining-table scene and a quiet mug-and-flowers still life.
- First-party iOS Simulator screenshots remain the only product UI images.
- Screenshots stay in normal document flow. There are no rotated phones, absolute-positioned screenshots, or decorative layers that can cover copy.
- Responsive breakpoints preserve the same reading order and remove all horizontal overflow at phone, tablet, and desktop widths.

## Routes

- `/ja/` — Japanese landing page
- `/en/` — English landing page
- `/ja/philosophy/` and `/en/philosophy/` — product philosophy
- `/ja/features/` and `/en/features/` — everyday product features
- `/ja/family/` and `/en/family/` — family sharing and boundaries
- `/ja/privacy/` — Japanese privacy architecture overview
- `/en/privacy/` — English privacy architecture overview
- `/ja/faq/` and `/en/faq/` — release and usage questions

Hugo’s native multilingual content and translation system provide localized metadata, canonical URLs, alternate-language links, navigation, content, and store-status copy.
