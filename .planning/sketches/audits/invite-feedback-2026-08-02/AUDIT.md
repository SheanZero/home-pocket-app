# Invite-code and error-feedback audit — 2026-08-02

## Outcome

The invitation flow had two separate product defects: the relay issued codes
for 24 hours while the app clipped the visible countdown to `999`, and a valid
owner in the creation flow was locally represented as `pending` even though
the regenerate use case only accepted `active`. The UI then exposed that
internal lifecycle mismatch as `Group is not active`.

The implementation now uses a 10-minute relay lifetime, permits an owner to
manage the invite during the valid `pending` creation step, refreshes a
recovered owner's stale invite, and routes transient failures through one warm,
localized feedback component.

## Evidence reviewed

- `01-invite-sharing.png`: owner invitation step displaying `999分钟内有效`.
- `02-regenerate-error.png`: regenerate action exposing the relay message in a
  visually dominant red banner.
- The complete Dart UI tree was searched for `SnackBar`, `SoftToast`, and the
  shared feedback helpers.
- No saved Product Design user context was available; the existing app palette,
  rounded cards, restrained green/pink accents, and supplied mockup were treated
  as the design source of truth.

## Journey health

1. Enter the owner invitation step — **repaired**. Existing owner state is
   reconciled and the invitation is refreshed instead of surfacing a conflict.
2. Read the code and lifetime — **repaired**. The server contract is 10 minutes;
   the remaining-time label continues to count down from the authoritative
   expiry.
3. Regenerate — **repaired**. A valid pending owner is allowed to regenerate.
4. Recover from failure — **repaired**. The user sees localized next-step copy;
   internal relay state and exception strings are not shown.

## Design findings and applied direction

| Priority | Finding | Applied change |
| --- | --- | --- |
| P0 | Raw server details were shown as user copy. | Invitation regeneration now uses friendly localized copy in Chinese, Japanese, and English. |
| P0 | The regenerate guard contradicted the creation lifecycle. | Owners may manage invitations in both `pending` and `active` states. |
| P1 | The red, full-width banner looked like a destructive system fault and competed with the task. | Replaced by a warm card surface with a subtle semantic border and restrained shadow. |
| P1 | The leading icon was too small to establish hierarchy. | Added a 44×44 tinted icon badge with a 24 px semantic icon. |
| P1 | Dismiss affordance and assistive announcement were weak. | Added a 44×44 dismiss target, tooltip, live-region semantics, and a descriptive semantic label. |
| P1 | One transient error still bypassed the shared component with a `SnackBar`. | Migrated the sponsor-link error and added an architecture test that rejects future transient-error SnackBars. |

The chosen style follows the mockup's visual language: dark warm-neutral cards,
large rounded corners, soft borders, and color used as a semantic accent rather
than as the entire surface. Success and error variants now share identical
geometry and hierarchy.

## System-wide feedback map

- **Transient errors and successes:** shared `showErrorFeedback` /
  `showSuccessFeedback` overlay backed by `SoftToast`.
- **Blocking, actionable connectivity problems:** the existing family-network
  dialog remains a modal because the user must choose cancel or retry.
- **Form validation:** remains beside the relevant field; moving it into a toast
  would weaken error-to-field association.
- **Persistent load failures:** remain in page/card error states with retry so
  the failure does not disappear before recovery.
- **Remaining SnackBars:** two informational/action affordances only (currency
  undo and voice-session notice); neither represents an error.

## Verification and evidence limits

- Structural widget tests cover card surface, icon badge, minimum targets, raw
  error suppression, and the sponsor migration.
- A dark-theme golden protects the shared feedback geometry.
- The architecture test protects the single transient-error entry point.
- The full serial Flutter suite passed 4,340 tests with 11 pre-existing skips;
  the relay server suite also passed.
- The actual 10-minute value depends on deploying the corresponding relay
  server change; an old server will continue to issue old-duration codes.
- No post-change physical-device capture was available in this audit, so final
  font rasterization and safe-area placement still benefit from one device UAT
  pass.
