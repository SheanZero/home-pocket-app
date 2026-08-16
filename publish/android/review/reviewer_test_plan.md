# Happy Pocket — Google Play reviewer test plan

## Access

- No account or remote sign-in is required.
- On first launch, choose a language and create the local profile requested by the onboarding flow.
- App Lock is optional. If enabled during review, the reviewer creates the local PIN; there is no developer-provided password.
- Most functionality is available on one device. Family sync requires a second installation and an invite code generated inside the app.
- There is no subscription or paywall in this release.

## Core one-device path

1. Complete onboarding with synthetic information.
2. Add one Daily transaction and one Joy transaction.
3. Open the transaction list and edit, then delete, a synthetic transaction.
4. Open the monthly analytics/category views and confirm the synthetic entries appear.
5. Add a private shopping item, mark it complete, and remove it.
6. Export an encrypted backup, then open the restore screen. Do not use real financial data.
7. Open Settings → Privacy/Terms/Support and verify the public pages load.
8. Optionally enable App Lock with a temporary local PIN, background the app, return, unlock, and then disable the lock.

## Optional two-device family-sync path

1. On device A, create a family group and generate an invite code.
2. On device B, join with the code and submit the request.
3. On device A, approve device B.
4. Create a family-shared transaction and public shopping item on device A.
5. Confirm both items arrive on device B.
6. Create a private shopping item and a private-ledger record; confirm they do not appear on device B.
7. Complete a public shopping item on device B and confirm the state returns to device A.

## Permissions and network behavior

- Microphone permission is requested only when voice input is used.
- Voice recognition prefers on-device processing. Cloud fallback is user-controlled in Settings.
- The first public release does not request notification permission or register an FCM token.
- Exchange-rate requests contain currency/date parameters but not transaction amounts, notes, names, or device IDs.
- Family-shared content is end-to-end encrypted before it reaches the relay; the relay handles delivery metadata and cannot decrypt financial content.

## Review notes

- Use synthetic data only.
- Receipt photos stay on the device where they were recorded and are not synced.
- Personal ledgers and private shopping items never enter family sync.
- If the two-device path is not available to the reviewer, the complete local accounting flow remains reviewable without credentials.
- Support contact: `support@napu.co.jp`.
