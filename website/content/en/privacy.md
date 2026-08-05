---
title: "Privacy by architecture"
description: "How Happy Pocket stores financial data, which limited connections it makes, and what it does not collect."
translationKey: "privacy"
eyebrow: "PRIVACY BY ARCHITECTURE"
---

## Your data starts on your device

Plaintext transactions, amounts, categories, notes, photos, and other financial data are stored on your device. Encryption keys are managed there too, so neither the developer nor the family-sync relay can read the contents of your finances.

Happy Pocket is not a ledger that assumes your data belongs in a vendor cloud. Its local-first design lets you keep recording and reviewing even when the network is unreliable.

## Four layers of protection

1. **Database** — SQLCipher / AES-256
2. **Sensitive fields** — ChaCha20-Poly1305
3. **Photos and files** — AES-256-GCM
4. **Family sync in transit** — TLS and end-to-end encryption

You can also protect the app with Face ID, Touch ID, fingerprint authentication, or a PIN.

## No ads or behavioral tracking

Happy Pocket displays no advertising and embeds no third-party advertising or analytics SDK. Financial data is never used for ad targeting or user profiling.

## Family sync includes only what you choose

Records you choose to share are end-to-end encrypted on the sending device, then temporarily stored and forwarded by a relay as encrypted messages. The relay does not hold the decryption keys. Personal-ledger records are not part of family sync and remain on your device.

Each encrypted message expires seven days after creation. A receipt acknowledgement deletes the corresponding message from the online database; unacknowledged messages are removed by an hourly cleanup after expiry, normally within about one hour. Rotating database backups use a standard 14-day retention period.

Delivery and abuse prevention require operational metadata such as device IDs, public keys, display names, group and membership state, and push tokens. This metadata does not contain plaintext financial data. Application logs do not intentionally record request bodies, encrypted message bodies, keys, signatures, or push tokens. Before launch, database bind-parameter logging must be disabled and the operator must set a verified log-retention and deletion schedule.

## We disclose the connections that do exist

Happy Pocket is not a zero-network app. It connects to retrieve exchange rates for multi-currency features, registers a push token only when notifications are enabled, and communicates between family devices for encrypted sync. No personal or financial data is sent when exchange rates are retrieved.

Receipt photos are currently kept only on the device where they were recorded. They are not included in family sync or encrypted backup files.

## Open to inspection

The implementation is published under the Apache 2.0 license. You can inspect the actual code—not only the privacy claims—on [GitHub](https://github.com/SheanZero/home-pocket-app).

> This page describes the current implementation of a product preparing for public release. The formal privacy policy will be published after legal review and before store launch.
