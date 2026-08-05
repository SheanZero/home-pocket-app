---
title: "Privacy by architecture"
description: "How Home Pocket stores financial data, which limited connections it makes, and what it does not collect."
translationKey: "privacy"
eyebrow: "PRIVACY BY ARCHITECTURE"
---

## Your data starts on your device

Plaintext transactions, amounts, categories, notes, photos, and other financial data are stored on your device. Encryption keys are managed there too, so neither the developer nor the family-sync relay can read the contents of your finances.

Home Pocket is not a ledger that assumes your data belongs in a vendor cloud. Its local-first design lets you keep recording and reviewing even when the network is unreliable.

## Four layers of protection

1. **Database** — SQLCipher / AES-256
2. **Sensitive fields** — ChaCha20-Poly1305
3. **Photos and files** — AES-256-GCM
4. **Family sync in transit** — TLS and end-to-end encryption

You can also protect the app with Face ID, Touch ID, fingerprint authentication, or a PIN.

## No ads or behavioral tracking

Home Pocket displays no advertising and embeds no third-party advertising or analytics SDK. Financial data is never used for ad targeting or user profiling.

## Family sync includes only what you choose

Records you choose to share are end-to-end encrypted on the sending device, then temporarily stored and forwarded by a relay as encrypted messages. The relay does not hold the decryption keys. Personal-ledger records are not part of family sync and remain on your device.

Delivery requires operational metadata such as device IDs, public keys, display names, and group or membership state. It does not include plaintext financial data. The formal privacy policy will disclose encrypted-message retention and operational logging in detail.

## We disclose the connections that do exist

Home Pocket is not a zero-network app. It connects to retrieve exchange rates for multi-currency features, registers a push token only when notifications are enabled, and communicates between family devices for encrypted sync. No personal or financial data is sent when exchange rates are retrieved.

Receipt photos are currently kept only on the device where they were recorded. They are not included in family sync or encrypted backup files.

## Open to inspection

The implementation is published under the Apache 2.0 license. You can inspect the actual code—not only the privacy claims—on [GitHub](https://github.com/SheanZero/home-pocket-app).

> This page describes the current implementation of a product preparing for public release. The formal privacy policy will be published after legal review and before store launch.
