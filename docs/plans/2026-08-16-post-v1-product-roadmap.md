# Happy Pocket post-1.0 product roadmap

**Status:** Proposed product direction  
**Published:** 2026-08-16  
**Planning horizon:** 14–18 months after v1.0
**Public summary:** `website/content/{ja,zh,en}/roadmap.md`

## Product intent

Happy Pocket should grow from a released local-first family ledger into a more
comfortable everyday companion without weakening its two defining boundaries:

1. household clarity must not erase personal space; and
2. convenience must not expose plaintext financial data or introduce
   behavioral tracking.

The next roadmap therefore prioritizes device fit and dependable reminders,
then gives curated Japanese store point information its own release before
storage-heavy collaboration features. Monetization remains voluntary and
separate from product capability.

## Assumptions

- “User tipping” means optional, consumable support paid to the app developer.
  It does not mean peer-to-peer payments between family members. A peer-to-peer
  transfer feature would require a separate payments, identity, fraud, and
  regulatory workstream.
- Dates below are planning windows, not public release promises. Store review,
  security findings, or migration risk may move a feature to a later release.
- iPhone remains supported throughout. iPad is an adaptive extension of the
  same Flutter product rather than a separate codebase.
- Attachments are private and local-first by default. Family attachment sync is
  a later protocol capability, not an implicit consequence of attaching a file.
- Japanese store point information is a maintained product dataset, not a
  one-off notification preset. Every published rule needs a source, applicable
  conditions, verification date, and expiry/review state.

## Priority order

| Priority | Capability | Why now |
| --- | --- | --- |
| P0 | iPad | Expands the existing product without introducing a new data or trust boundary. |
| P0 | Notifications | Improves routine value, but needs careful permission and privacy design. |
| P1 | Japan store point calendar | Requires a dedicated curation and update lifecycle, so it ships independently from generic notifications. |
| P1 | Attachments | High user value with substantial storage, backup, encryption, and sync cost. |
| P1 | Developer support | Low implementation coupling and can run in parallel, but must not block core value. |

## Release sequence

### v1.0.x — release baseline and delivery controls (0–4 weeks)

Goal: make the shipped baseline safe to extend.

- Resolve the tracked compatibility-baseline digest drift through review and
  verification; do not merely rewrite hashes.
- Establish feature flags and release telemetry that do not add behavioral
  analytics or financial-content logging.
- Write threat models for notification payloads, attachment storage, backup
  migration, and in-app purchase state.
- Confirm hosted Privacy, Terms, Support, and Tokusho information before store
  metadata is changed.
- Add the public roadmap page and use it as the user-facing source of planned
  direction. Keep implementation details in this document.

Exit gate:

- release compatibility contract is green;
- public legal/support destinations are valid; and
- each v1.1–v1.4 feature has a scoped architecture decision and test strategy.

### v1.1 — adaptive iPad experience (1–3 months)

Goal: make Happy Pocket feel native on iPad while preserving the existing
single-process security model.

- Change the iOS target device family from iPhone-only to universal.
- Adopt three adaptive navigation bands:
  - below 600 logical pixels: bottom navigation;
  - 600–839: navigation rail;
  - 840 and above: persistent navigation plus list/detail presentation where
    the workflow benefits.
- Verify portrait, landscape, Split View, Stage Manager resizing, keyboard
  navigation, mouse/trackpad targets, and text scaling.
- Add representative golden/widget widths and iPad integration coverage.
- Ship the first iPad version as a single-window experience. Defer multi-window
  scenes until provider ownership, database lifecycle, app lock, and route state
  are scene-safe.

Exit gate:

- all primary flows work at compact, medium, and expanded widths;
- no financial data remains visible after the app-lock boundary; and
- iPhone behavior and golden baselines remain stable.

### v1.2 — useful notifications and voluntary developer support (3–5 months)

Goal: help families remember important actions and provide a respectful way to
support continued development.

Notifications:

- Add local reminders for recurring/fixed expenses, backup freshness, and
  expiring invitations.
- Request notification permission in context, after the user enables a reminder
  or family event—not during first launch.
- Provide per-type toggles, quiet hours, and an in-app notification center so
  denied system permission does not remove important state.
- Add remote family-event notifications only for events such as invitation,
  approval, membership change, and encrypted sync availability/recovery.
- Keep push copy generic. Payloads must never contain amounts, notes, merchants,
  categories, account names, or other financial details. Unlock first, then
  fetch and decrypt.
- Implement iOS and Android runtime permission behavior separately and test
  denied, provisional, revoked, and resumed states.

Developer support:

- Offer small, medium, and large consumable in-app purchases.
- Use “support development” wording. Do not represent purchases as charitable
  donations.
- Do not attach feature unlocks, badges, virtual currency, rankings, or
  preferential support to a tip.
- Handle pending, cancelled, failed, restored, refunded, and duplicate delivery
  states idempotently.
- Prefer Apple In-App Purchase and Google Play Billing for consistent store and
  refund behavior.

Exit gate:

- notification privacy tests assert generic payloads;
- every notification type can be disabled independently;
- purchase delivery is idempotent and refund-safe; and
- the app remains fully useful without paying.

### v1.3 — Japan store point calendar (5–8 months)

Goal: organize reliable Japanese store point-multiplier information as a
maintained dataset, then let users follow the stores that matter to them.

Catalog and curation:

- Define a versioned store-point schema with canonical store/program name,
  Japanese aliases, eligible membership or payment method, multiplier/benefit,
  recurrence rule, geographic scope, exclusions, source URL, effective dates,
  last-verified date, and editorial status.
- Seed the catalog from official retailer, shopping-center, card, or payment
  program sources. Do not publish rules sourced only from search snippets,
  affiliate pages, social posts, or unverified community submissions.
- Build a review queue for new, changed, expiring, conflicting, and withdrawn
  rules. Preserve source evidence and change history so corrections can be
  audited and rolled back.
- Avoid store logos in the first version unless usage rights are confirmed;
  prefer canonical text names and neutral category labels.
- Publish a clear last-checked date and conditions. The app must not imply that
  a benefit is guaranteed at every branch or for every payment method.

App experience:

- Provide searchable store/program profiles and a calendar/list of upcoming
  point-up days in Japan time.
- Let users follow selected stores, choose same-day/one-day-before/custom-time
  reminders, and mute individual rules.
- Keep followed stores and reminder preferences encrypted on-device. Catalog
  update requests must not upload purchase history, transaction data, or the
  user's followed-store list.
- Support user-created local rules when a store is missing or a branch runs a
  local campaign. User rules remain distinct from the curated catalog and are
  never silently overwritten.
- Default lock-screen copy to a generic reminder. Showing a store name requires
  explicit notification-preview opt-in.
- Cache a signed, versioned catalog snapshot so browsing and scheduled reminders
  continue offline; reject invalid signatures and allow rollback to the last
  valid snapshot.

Exit gate:

- every published catalog rule has an allowed source, conditions, effective
  dates, and a recorded verification date;
- expired or withdrawn rules cannot continue scheduling notifications;
- recurrence tests cover monthly dates, weekdays, nth weekdays, campaign
  windows, Japan-time boundaries, device time-zone changes, and duplicate
  suppression;
- catalog signature, rollback, stale-data, and correction flows are tested; and
- store follows and reminders work without revealing user behavior to the
  catalog service.

### v1.4 — encrypted attachments and backup evolution (8–11 months)

Goal: let a transaction retain its evidence without turning file handling into
an accidental data leak.

Local attachment scope:

- Support JPEG, PNG, HEIC, and PDF initially.
- Suggested limits: five attachments per transaction and 10 MB per attachment;
  validate with actual backup size and low-storage testing before release.
- Store attachment metadata in a dedicated table rather than transaction rows.
- Derive a per-attachment key and encrypt file bytes with AES-256-GCM.
- Validate MIME type and decoded content, calculate integrity hashes, and use
  atomic writes.
- Generate encrypted or protected thumbnails and remove EXIF/GPS metadata when
  importing images.
- Include attachment cleanup in transaction deletion, account wipe, and app-lock
  privacy tests.

Backup and migration:

- Introduce a new HPB container version that explicitly declares attachment
  inclusion and integrity while continuing to read HPB v2 backups.
- Make export size visible before creation and fail safely when local storage is
  insufficient.
- Test interrupted write, corrupted file, wrong key, partial restore, and older
  backup compatibility.

Family sharing:

- Do not sync local paths or legacy photo hashes as attachment references.
- Design a separate end-to-end encrypted blob protocol with quotas, resumable
  transfer, integrity validation, tombstones, and device cleanup.
- Ship local/private attachments before shared attachments unless the blob
  protocol passes the same zero-knowledge review as record sync.

Exit gate:

- plaintext attachment bytes never appear in app storage, logs, backups, push
  payloads, or relay-visible metadata;
- older backups restore successfully; and
- attachment deletion is consistent across database, file store, thumbnails,
  and backup manifests.

### v1.5 — planning, portability, and family coordination (11–14 months)

Goal: deepen everyday retention after the four requested capabilities are
stable.

- Add CSV import/export with explicit mappings for common Japanese services such
  as Money Forward ME, Zaim, and PayPay exports where formats permit.
- Replace placeholder budget concepts with a durable budget model, daily
  guidance, and savings goals.
- Add payer/share fields, month-end settlement, recurring templates, and a clear
  family change log.
- Keep the Joy experience reflective: no streaks, rankings, financial ROI, or
  achievement events.

### v2.0 — intelligence, secure media sync, and sustainable operations (14–18 months)

Goal: add higher-cost capabilities only after the data model and platform
surface are ready.

- Move receipt OCR onto the attachment foundation and keep recognition results
  reviewable before saving.
- Graduate family attachment sync from experiment to supported encrypted
  protocol if quotas, recovery, and deletion semantics are proven.
- Consider a Family Plus subscription for ongoing hosted costs while preserving
  the useful free local-first product.
- Revisit bank integration only when provider availability, consent, operating
  cost, and privacy boundaries are acceptable in target markets.

## Cross-cutting requirements

### Security and privacy

- No notification, analytics, crash, purchase, or support event may include
  financial content.
- Encryption keys remain behind the established secure-storage/key-manager
  boundary.
- Attachment, notification, and purchase logs use opaque identifiers and
  redacted state only.
- Store catalog updates are content delivery, not behavioral analytics: requests
  must not contain followed stores, transaction history, or stable user IDs.
- New network services must be disclosed in Privacy and store metadata before
  release.

### Product and accessibility

- All copy ships in Japanese, Simplified Chinese, and English together.
- Every new flow supports text scaling, screen readers, keyboard focus where
  applicable, and minimum touch targets.
- “Support development” remains optional and visually secondary to product
  tasks.
- Notifications provide equivalent in-app state and never become the only way
  to learn about a family event.
- Store-point pages show provenance, applicable conditions, and freshness so a
  reminder is never presented as a guaranteed benefit.

### Delivery metrics

Use privacy-preserving, aggregate release measures rather than behavioral
tracking:

- crash-free sessions and startup failure rate;
- backup/restore success rate without file or content identifiers;
- notification scheduling/delivery state on-device;
- store catalog freshness, validation failures, and expired-rule cleanup without
  store-follow or user identifiers;
- attachment import/decrypt integrity failures; and
- purchase state-machine errors and unresolved pending transactions.

## Research basis

The ordering reflects the current codebase plus platform and market patterns:

- Apple App Review Guidelines: <https://developer.apple.com/app-store/review/guidelines/>
- Apple notification permission guidance: <https://developer.apple.com/documentation/UserNotifications/asking-permission-to-use-notifications>
- Android notification permission guidance: <https://developer.android.com/develop/ui/views/notifications/notification-permission>
- Apple iPad multitasking guidance: <https://developer.apple.com/design/human-interface-guidelines/multitasking>
- Flutter adaptive and responsive guidance: <https://docs.flutter.dev/ui/adaptive-responsive/general>
- Google Play payments policy overview: <https://support.google.com/googleplay/android-developer/answer/10281818>
- Money Forward ME: <https://moneyforward.com/me>
- Zaim: <https://zaim.net/>
- Actual Budget: <https://actualbudget.org/>

These links are inputs, not blanket endorsements. Store rules, APIs, and market
offerings must be rechecked during each release because they can change.
